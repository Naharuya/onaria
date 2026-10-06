import { createIdentityVerifier, IdentityError } from './identity_verifier.js';

const NAVER_PROFILE_URL = 'https://openapi.naver.com/v1/nid/me';

function normalized(provider, providerUserId) {
  if (!['apple', 'google', 'kakao', 'naver'].includes(provider)
    || typeof providerUserId !== 'string' || !providerUserId || providerUserId.length > 200) throw new IdentityError();
  return Object.freeze({ provider, providerUserId });
}

export function createOidcProviderVerifier({ provider, issuer, audience, jwksUrl, jwks, fetchImpl, now, onFailure } = {}) {
  if (!['apple', 'google', 'kakao'].includes(provider)) throw new IdentityError(503);
  const verifyJwt = createIdentityVerifier({ issuer, audience, jwksUrl, jwks, algorithms: ['RS256'], fetchImpl, now, onFailure });
  return async idToken => {
    const identity = await verifyJwt(idToken);
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

export function createProviderIdentityVerifier({ apple, google, kakao, naver, fetchImpl, now, logger = console } = {}) {
  const verifiers = {
    apple: apple ? createOidcProviderVerifier({ provider: 'apple', ...apple, fetchImpl, now, onFailure: reason => logger.warn?.('provider_identity_rejected', { provider: 'apple', reason }) }) : null,
    google: google ? createOidcProviderVerifier({ provider: 'google', ...google, fetchImpl, now, onFailure: reason => logger.warn?.('provider_identity_rejected', { provider: 'google', reason }) }) : null,
    kakao: kakao ? createOidcProviderVerifier({ provider: 'kakao', ...kakao, fetchImpl, now, onFailure: reason => logger.warn?.('provider_identity_rejected', { provider: 'kakao', reason }) }) : null,
    naver: naver ? createNaverProviderVerifier({ fetchImpl }) : null,
  };
  return async ({ provider, credential } = {}) => {
    if (!Object.hasOwn(verifiers, provider) || !verifiers[provider]) throw new IdentityError(503);
    return verifiers[provider](credential);
  };
}

export function createRuntimeProviderIdentity({ env = process.env, fetchImpl = globalThis.fetch, now, logger = console } = {}) {
  const appleClientId = env.ONARIA_APPLE_CLIENT_ID?.trim();
  const googleClientId = env.ONARIA_GOOGLE_CLIENT_ID?.trim();
  const kakaoClientId = env.ONARIA_KAKAO_CLIENT_ID?.trim();
  const apple = appleClientId ? {
    issuer: 'https://appleid.apple.com', audience: appleClientId,
    jwksUrl: 'https://appleid.apple.com/auth/keys',
  } : null;
  const google = googleClientId ? {
    issuer: 'https://accounts.google.com', audience: googleClientId,
    jwksUrl: 'https://www.googleapis.com/oauth2/v3/certs',
  } : null;
  const kakao = kakaoClientId ? {
    issuer: 'https://kauth.kakao.com', audience: kakaoClientId,
    jwksUrl: 'https://kauth.kakao.com/.well-known/jwks.json',
  } : null;
  return createProviderIdentityVerifier({ apple, google, kakao, naver: env.ONARIA_NAVER_ENABLED === 'true' ? {} : null, fetchImpl, now, logger });
}
