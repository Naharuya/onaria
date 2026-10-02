import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createMemberSessions } from '../src/auth/member_session.js';

test('member session stores only hashed opaque token and verified provider identity', () => {
  let time = 1000; const sessions = createMemberSessions({ ttlMs: 60_000, now: () => time });
  const issued = sessions.issue({ provider: 'google', providerUserId: 'sub-1' });
  assert.match(issued.token, /^[A-Za-z0-9_-]{43}$/); assert.equal(issued.expiresInSeconds, 60);
  assert.deepEqual(sessions.verify(issued.token), { provider: 'google', providerUserId: 'sub-1' });
  assert.equal(sessions.size(), 1);
  time += 60_001; assert.throws(() => sessions.verify(issued.token), /회원 인증/); assert.equal(sessions.size(), 0);
});

test('member session rejects forged identity and supports revocation', () => {
  const sessions = createMemberSessions();
  assert.throws(() => sessions.issue({ provider: 'phone', providerUserId: 'x' }), /회원 인증/);
  const { token } = sessions.issue({ provider: 'naver', providerUserId: 'n-1' });
  assert.equal(sessions.revoke(token), true); assert.throws(() => sessions.verify(token), /회원 인증/);
  assert.equal(sessions.revoke(token), false); assert.equal(sessions.revoke('bad'), false);
});
