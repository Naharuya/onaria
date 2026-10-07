import { readFileSync } from 'node:fs';
import { importPKCS8, SignJWT } from 'jose';
import { IdentityError } from './identity_verifier.js';

// Credentials exist only in this request. Never persist or log Apple grants.
export function createAppleRevocation({ clientId, teamId, keyId, privateKey, redirectUri, verify, fetchImpl = globalThis.fetch, now = () => new Date() } = {}) {
  return async ({ authorizationCode, credential, providerUserId } = {}) => {
    if (!clientId || !teamId || !keyId || !privateKey || !verify) throw new IdentityError(503);
    if (typeof authorizationCode !== 'string' || !authorizationCode || authorizationCode.length > 4096
      || typeof credential !== 'string' || !credential || credential.length > 8192) throw new IdentityError();
    const identity = await verify({ provider: 'apple', credential });
    if (identity.provider !== 'apple' || identity.providerUserId !== providerUserId) throw new IdentityError();
    try {
      const issuedAt = Math.floor(now().getTime() / 1000);
      const signingKey = await importPKCS8(privateKey, 'ES256');
      const clientSecret = await new SignJWT({}).setProtectedHeader({ alg: 'ES256', kid: keyId })
        .setIssuer(teamId).setSubject(clientId).setAudience('https://appleid.apple.com')
        .setIssuedAt(issuedAt).setExpirationTime(issuedAt + 300).sign(signingKey);
      const request = async (path, fields) => {
        const response = await fetchImpl(`https://appleid.apple.com/auth/${path}`, {
          method: 'POST', redirect: 'error', signal: AbortSignal.timeout(10000),
          headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({ client_id: clientId, client_secret: clientSecret, ...fields }),
        });
        if (response.status !== 200 || response.redirected || Number(response.headers.get('content-length') ?? 0) > 32768) {
          try { await response.body?.cancel(); } catch { /* best effort */ }
          throw new IdentityError(503);
        }
        return response;
      };
      const exchange = await request('token', { grant_type: 'authorization_code', code: authorizationCode, ...(redirectUri ? { redirect_uri: redirectUri } : {}) });
      const tokens = await exchange.json();
      if (typeof tokens.refresh_token !== 'string' || !tokens.refresh_token || tokens.refresh_token.length > 8192
        || typeof tokens.id_token !== 'string') throw new IdentityError(503);
      // Bind the code's grant as well as the supplied identity proof to this member.
      const grantIdentity = await verify({ provider: 'apple', credential: tokens.id_token });
      if (grantIdentity.provider !== 'apple' || grantIdentity.providerUserId !== providerUserId) throw new IdentityError();
      const revoked = await request('revoke', { token: tokens.refresh_token, token_type_hint: 'refresh_token' });
      try { await revoked.body?.cancel(); } catch { /* best effort */ }
    } catch (error) {
      if (error instanceof IdentityError) throw error;
      throw new IdentityError(503);
    }
  };
}

export function createRuntimeAppleRevocation({ env = process.env, verify, androidAuth, androidVerify, fetchImpl, now } = {}) {
  let privateKey;
  // A server-local file path only: no private key in mobile assets or repository.
  try { if (env.ONARIA_APPLE_PRIVATE_KEY_PATH) privateKey = readFileSync(env.ONARIA_APPLE_PRIVATE_KEY_PATH, 'utf8'); } catch { /* fail closed */ }
  const native = createAppleRevocation({ clientId: env.ONARIA_APPLE_CLIENT_ID?.trim(), teamId: env.ONARIA_APPLE_TEAM_ID?.trim(),
    keyId: env.ONARIA_APPLE_KEY_ID?.trim(), privateKey, verify, fetchImpl, now });
  const android = createAppleRevocation({ clientId: env.ONARIA_APPLE_SERVICE_ID?.trim(), teamId: env.ONARIA_APPLE_TEAM_ID?.trim(),
    keyId: env.ONARIA_APPLE_KEY_ID?.trim(), privateKey, redirectUri: env.ONARIA_APPLE_REDIRECT_URI?.trim() || 'https://api.onaria.ai.kr/v1/auth/apple/android/callback', verify: androidVerify, fetchImpl, now });
  return async request => {
    if (request?.credential?.startsWith('apple_android.')) {
      if (!androidAuth || request.authorizationCode !== request.credential) throw new IdentityError();
      return android({ ...request, ...androidAuth.consumeGrant(request.credential) });
    }
    return native(request);
  };
}
