import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import { IdentityError } from './identity_verifier.js';

const digest = value => createHash('sha256').update(value).digest();
export function createMemberSessions({ ttlMs = 15 * 60_000, maxSessions = 5000, now = () => Date.now() } = {}) {
  if (!Number.isSafeInteger(ttlMs) || ttlMs < 60_000 || ttlMs > 24 * 60 * 60_000
    || !Number.isSafeInteger(maxSessions) || maxSessions < 1 || maxSessions > 100_000) throw new IdentityError(503);
  const sessions = new Map();
  function prune() {
    const time = now();
    for (const [key, value] of sessions) if (value.expires <= time) sessions.delete(key);
    while (sessions.size >= maxSessions) sessions.delete(sessions.keys().next().value);
  }
  return {
    issue(identity) {
      if (!identity || !['google', 'kakao', 'naver'].includes(identity.provider)
        || typeof identity.providerUserId !== 'string' || !identity.providerUserId) throw new IdentityError();
      prune();
      const token = randomBytes(32).toString('base64url');
      sessions.set(digest(token).toString('hex'), Object.freeze({ ...identity, expires: now() + ttlMs }));
      return Object.freeze({ token, expiresInSeconds: Math.floor(ttlMs / 1000) });
    },
    verify(token) {
      if (typeof token !== 'string' || token.length !== 43 || !/^[A-Za-z0-9_-]+$/.test(token)) throw new IdentityError();
      const key = digest(token).toString('hex'); const session = sessions.get(key);
      if (!session || session.expires <= now()) { sessions.delete(key); throw new IdentityError(); }
      return Object.freeze({ provider: session.provider, providerUserId: session.providerUserId });
    },
    revoke(token) {
      if (typeof token !== 'string' || token.length !== 43 || !/^[A-Za-z0-9_-]+$/.test(token)) return false;
      const candidate = digest(token); let matched = null;
      for (const key of sessions.keys()) {
        const stored = Buffer.from(key, 'hex');
        if (stored.length === candidate.length && timingSafeEqual(stored, candidate)) { matched = key; break; }
      }
      return matched ? sessions.delete(matched) : false;
    },
    size() { prune(); return sessions.size; },
  };
}
