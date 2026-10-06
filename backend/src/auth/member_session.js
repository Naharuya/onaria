import fs from 'node:fs';
import path from 'node:path';
import { createHash, randomBytes } from 'node:crypto';
import Database from 'better-sqlite3';
import { IdentityError } from './identity_verifier.js';

const digestHex = value => createHash('sha256').update(value).digest('hex');
const allowedProviders = new Set(['apple', 'google', 'kakao', 'naver']);

export function createMemberSessions({ ttlMs = 15 * 60_000, maxSessions = 5000, now = () => Date.now(), filename } = {}) {
  if (!Number.isSafeInteger(ttlMs) || ttlMs < 60_000 || ttlMs > 24 * 60 * 60_000
    || !Number.isSafeInteger(maxSessions) || maxSessions < 1 || maxSessions > 100_000) throw new IdentityError(503);

  if (!filename) {
    const sessions = new Map();
    function prune() {
      const time = now();
      for (const [key, value] of sessions) if (value.expires <= time) sessions.delete(key);
      while (sessions.size >= maxSessions) sessions.delete(sessions.keys().next().value);
    }
    return {
      issue(identity) {
        validateIdentity(identity); prune();
        const token = randomBytes(32).toString('base64url');
        sessions.set(digestHex(token), Object.freeze({ ...identity, expires: now() + ttlMs }));
        return Object.freeze({ token, expiresInSeconds: Math.floor(ttlMs / 1000) });
      },
      verify(token) {
        validateToken(token);
        const key = digestHex(token); const session = sessions.get(key);
        if (!session || session.expires <= now()) { sessions.delete(key); throw new IdentityError(); }
        return Object.freeze({ provider: session.provider, providerUserId: session.providerUserId });
      },
      revoke(token) {
        if (!validToken(token)) return false;
        return sessions.delete(digestHex(token));
      },
      size() { prune(); return sessions.size; },
      close() {},
    };
  }

  fs.mkdirSync(path.dirname(filename), { recursive: true });
  const db = new Database(filename);
  db.pragma('journal_mode = WAL');
  db.exec(`
    CREATE TABLE IF NOT EXISTS member_sessions (
      token_hash TEXT PRIMARY KEY,
      provider TEXT NOT NULL,
      provider_user_id TEXT NOT NULL,
      expires_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS member_sessions_expires_at ON member_sessions(expires_at);
  `);
  const insert = db.prepare(`INSERT INTO member_sessions (token_hash, provider, provider_user_id, expires_at, created_at)
    VALUES (?, ?, ?, ?, ?)`);
  const select = db.prepare('SELECT provider, provider_user_id, expires_at FROM member_sessions WHERE token_hash = ?');
  const remove = db.prepare('DELETE FROM member_sessions WHERE token_hash = ?');
  const removeExpired = db.prepare('DELETE FROM member_sessions WHERE expires_at <= ?');
  const count = db.prepare('SELECT COUNT(*) AS count FROM member_sessions');
  const trimOldest = db.prepare(`DELETE FROM member_sessions WHERE token_hash IN (
    SELECT token_hash FROM member_sessions ORDER BY created_at ASC LIMIT ?
  )`);
  function prune() {
    removeExpired.run(now());
    const overflow = count.get().count - maxSessions + 1;
    if (overflow > 0) trimOldest.run(overflow);
  }
  return {
    issue(identity) {
      validateIdentity(identity); prune();
      const token = randomBytes(32).toString('base64url');
      insert.run(digestHex(token), identity.provider, identity.providerUserId, now() + ttlMs, now());
      return Object.freeze({ token, expiresInSeconds: Math.floor(ttlMs / 1000) });
    },
    verify(token) {
      validateToken(token);
      const key = digestHex(token); const session = select.get(key);
      if (!session || session.expires_at <= now()) { remove.run(key); throw new IdentityError(); }
      return Object.freeze({ provider: session.provider, providerUserId: session.provider_user_id });
    },
    revoke(token) {
      if (!validToken(token)) return false;
      return remove.run(digestHex(token)).changes === 1;
    },
    size() { prune(); return count.get().count; },
    close() { db.close(); },
  };
}

function validateIdentity(identity) {
  if (!identity || !allowedProviders.has(identity.provider)
    || typeof identity.providerUserId !== 'string' || !identity.providerUserId) throw new IdentityError();
}
function validToken(token) {
  return typeof token === 'string' && token.length === 43 && /^[A-Za-z0-9_-]+$/.test(token);
}
function validateToken(token) {
  if (!validToken(token)) throw new IdentityError();
}
