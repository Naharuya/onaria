import { createIdentityVerifier, IdentityError } from './identity_verifier.js';

const NAVER_PROFILE_URL = 'https://openapi.naver.com/v1/nid/me';

function normalized(provider, providerUserId) {
  if (!['google', 'kakao', 'naver'].includes(provider)
    || typeof providerUserId !== 'string' || !providerUserId || providerUserId.length > 200) throw new IdentityError();
  return Object.freeze({ provider, providerUserId });
}

export function createOidcProviderVerifier({ provider, issuer, audience, jwksUrl, jwks, fetchImpl, now } = {}) {
  if (!['google', 'kakao'].includes(provider)) throw new IdentityError(503);
  const verifyJwt = createIdentityVerifier({ issuer, audience, jwksUrl, jwks, algorithms: ['RS256'], fetchImpl, now });
  return async (idToken, { nonce } = {}) => {
    const identity = await verifyJwt(idToken);
    if (provider === 'kakao') {
      if (typeof nonce !== 'string' || nonce.length < 16 || nonce.length > 128 || identity.nonce !== nonce) throw new IdentityError();
    }
    return normalized(provider, identity.subject);
  };
}

export function createNaverProviderVerifier({ fetchImpl = globalThis.fetch } = {}) {
  return async accessToken => {
    if (typeof accessToken !== 'string' || accessToken.length < 16 || accessToken.length > 4096
      || !/^[A-Za-z0-9._~+\/-]+$/.test(accessToken)) throw new IdentityError();
    let response;
    try {
      response = await fetchImpl(NAVER_PROFILE_URL, {
        method: 'GET', redirect: 'manual', headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/json' },
      });
      if (response.status !== 200 || response.redirected
        || Number(response.headers.get('content-length') ?? 0) > 32768) throw new IdentityError();
      const body = await response.json();
      if (body?.resultcode !== '00' || typeof body?.response?.id !== 'string') throw new IdentityError();
      return normalized('naver', body.response.id);
    } catch (error) {
      if (error instanceof IdentityError) throw error;
      throw new IdentityError();
    } finally {
      try { await response?.body?.cancel(); } catch { /* best effort */ }
    }
  };
}

export function createProviderIdentityVerifier({ google, kakao, naver, fetchImpl, now } = {}) {
  const verifiers = {
    google: google ? createOidcProviderVerifier({ provider: 'google', ...google, fetchImpl, now }) : null,
    kakao: kakao ? createOidcProviderVerifier({ provider: 'kakao', ...kakao, fetchImpl, now }) : null,
    naver: naver ? createNaverProviderVerifier({ fetchImpl }) : null,
  };
  return async ({ provider, credential, nonce } = {}) => {
    if (!Object.hasOwn(verifiers, provider) || !verifiers[provider]) throw new IdentityError(503);
    return verifiers[provider](credential, { nonce });
  };
}

export function createRuntimeProviderIdentity({ env = process.env, fetchImpl = globalThis.fetch, now } = {}) {
  const googleClientId = env.ONARIA_GOOGLE_CLIENT_ID?.trim();
  const kakaoClientId = env.ONARIA_KAKAO_CLIENT_ID?.trim();
  const google = googleClientId ? {
    issuer: 'https://accounts.google.com', audience: googleClientId,
    jwksUrl: 'https://www.googleapis.com/oauth2/v3/certs',
  } : null;
  const kakao = kakaoClientId ? {
    issuer: 'https://kauth.kakao.com', audience: kakaoClientId,
    jwksUrl: 'https://kauth.kakao.com/.well-known/jwks.json',
  } : null;
  return createProviderIdentityVerifier({ google, kakao, naver: env.ONARIA_NAVER_ENABLED === 'true' ? {} : null, fetchImpl, now });
}
