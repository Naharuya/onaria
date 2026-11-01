import { randomBytes } from 'node:crypto';
import express from 'express';
import { createIdentityVerifier, IdentityError } from './identity_verifier.js';

const prefix = 'apple_android.';
const callbackPath = '/v1/auth/apple/android/callback';
const safeId = /^[A-Za-z0-9_-]{43}$/;
const ttl = 5 * 60 * 1000;

// Short-lived state and opaque proofs live only in this process. Restarting
// invalidates pending logins without changing any existing member session.
export function createAppleAndroidAuth({ serviceId = '', redirectUri = '', verify,
  now = Date.now, random = () => randomBytes(32).toString('base64url'), capacity = 500, onFailure = () => {} } = {}) {
  const reject = reason => {
    try { onFailure(reason); } catch { /* Diagnostics never change authentication. */ }
    const error = new IdentityError();
    error.appleAndroidReason = reason;
    return error;
  };

  const pending = new Map();
  const proofs = new Map();
  let redirect;
  try { redirect = new URL(redirectUri); } catch { /* disabled until configured */ }
  const ready = Boolean(serviceId && /^[A-Za-z0-9.-]{3,256}$/.test(serviceId)
    && redirect?.protocol === 'https:' && !redirect.username && !redirect.password
    && !redirect.search && !redirect.hash && redirect.pathname === callbackPath && verify);
  const sweep = () => {
    for (const store of [pending, proofs]) {
      for (const [key, value] of store) if (value.expires <= now()) store.delete(key);
    }
  };
  const requireReady = () => { if (!ready) throw new IdentityError(503); };
  const intent = fields => `intent://callback?${new URLSearchParams(fields)}#Intent;package=com.onaria.app;scheme=signinwithapple;end`;
  const api = {
    challenge() {
      requireReady(); sweep();
      if (pending.size + proofs.size >= capacity) throw new IdentityError(503);
      const state = random(); const nonce = random();
      pending.set(state, { nonce, expires: now() + ttl });
      return { state, nonce, clientId: serviceId, redirectUri: redirect.href };
    },
    async callback(body) {
      requireReady();
      if (!body || typeof body.state !== 'string' || !safeId.test(body.state)) throw reject('state_invalid');
      const original = pending.get(body.state);
      const expired = original && original.expires <= now();
      sweep();
      const challenge = pending.get(body.state);
      if (!challenge) throw reject(expired ? 'state_expired' : 'state_unknown');
      pending.delete(body.state); // callbacks are one-use, including failures
      if (body.error === 'access_denied') return intent({ state: body.state, error: 'access_denied' });
      if (typeof body.id_token !== 'string' || typeof body.code !== 'string'
        || !body.code || body.code.length > 4096 || body.error) throw new IdentityError();
      const identity = await verify(body.id_token, challenge.nonce);
      if (!identity || identity.provider !== 'apple' || typeof identity.providerUserId !== 'string'
        || !identity.providerUserId || identity.providerUserId.length > 200) throw new IdentityError();
      const proof = prefix + random();
      proofs.set(proof, { authorizationCode: body.code, credential: body.id_token, identity: Object.freeze({ provider: 'apple', providerUserId: identity.providerUserId }), expires: now() + ttl });
      // Do not place the Apple JWT, authorization code, email or name in an
      // Android intent URL. The SDK returns this temporary proof as id_token.
      return intent({ state: body.state, id_token: proof, code: proof });
    },
    resolve(proof) {
      requireReady(); sweep();
      if (typeof proof !== 'string' || !proof.startsWith(prefix) || !safeId.test(proof.slice(prefix.length))) throw new IdentityError();
      const stored = proofs.get(proof);
      if (!stored) throw new IdentityError();
      return stored.identity;
    },
    consumeGrant(proof) {
      api.resolve(proof);
      const stored = proofs.get(proof);
      proofs.delete(proof);
      return { authorizationCode: stored.authorizationCode, credential: stored.credential };
    },
    router() {
      const router = express.Router();
      router.use((_req, res, next) => { res.set({ 'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer' }); next(); });
      router.post('/challenge', (_req, res, next) => {
        try { res.json(api.challenge()); } catch (error) { next(error); }
      });
      router.post('/callback', express.urlencoded({ extended: false, limit: '16kb', parameterLimit: 8 }), async (req, res, next) => {
        try { res.redirect(303, await api.callback(req.body)); } catch (error) {
          if (error instanceof IdentityError && error.appleAndroidReason) {
            const expired = error.appleAndroidReason === 'state_expired';
            res.status(error.status || 401).type('html').send('<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Apple 인증 다시 시작</title><body><main><h1>' + (expired ? '인증 확인 시간이 지났어요' : 'Apple 인증 요청을 확인하지 못했어요') + '</h1><p>이 창을 닫고 ONARIA 앱에서 Apple 로그인을 다시 시작해 주세요.</p><p>인증은 완료되지 않았으며 이 응답으로 새 회원은 생성되지 않았어요.</p></main></body></html>');
            return;
          }
          next(error);
        }
      });
      return router;
    },
  };
  return api;
}

export function createRuntimeAppleAndroidAuth({ env = process.env, fetchImpl = globalThis.fetch, logger = console } = {}) {
  const serviceId = env.ONARIA_APPLE_SERVICE_ID?.trim() || '';
  return createAppleAndroidAuth({ serviceId,
    onFailure: reason => logger.warn?.('apple_android_rejected', { reason }),
    redirectUri: env.ONARIA_APPLE_REDIRECT_URI?.trim() || `https://api.onaria.ai.kr${callbackPath}`,
    verify: serviceId ? async (token, nonce) => {
      const verify = createIdentityVerifier({ issuer: 'https://appleid.apple.com', audience: serviceId,
        jwksUrl: 'https://appleid.apple.com/auth/keys', maxTokenAgeSeconds: 86400,
        requiredClaims: { nonce }, fetchImpl });
      const identity = await verify(token);
      return { provider: 'apple', providerUserId: identity.subject };
    } : null,
  });
}

export function withAppleAndroidProofs(nativeVerifier, appleAndroidAuth) {
  return async input => input?.provider === 'apple' && typeof input.credential === 'string'
    && input.credential.startsWith(prefix) ? appleAndroidAuth.resolve(input.credential) : nativeVerifier(input);
}
