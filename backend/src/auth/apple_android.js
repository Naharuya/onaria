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
  now = Date.now, random = () => randomBytes(32).toString('base64url'), capacity = 500 } = {}) {
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
      requireReady(); sweep();
      if (!body || typeof body.state !== 'string' || !safeId.test(body.state)) throw new IdentityError();
      const challenge = pending.get(body.state);
      if (!challenge) throw new IdentityError();
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
        try { res.redirect(303, await api.callback(req.body)); } catch (error) { next(error); }
      });
      return router;
    },
  };
  return api;
}

export function createRuntimeAppleAndroidAuth({ env = process.env, fetchImpl = globalThis.fetch } = {}) {
  const serviceId = env.ONARIA_APPLE_SERVICE_ID?.trim() || '';
  return createAppleAndroidAuth({ serviceId,
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
