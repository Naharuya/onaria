import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createApp } from '../src/app.js';

async function fixture(run) {
  const creates = [], verifications = [], sessions = [];
  const app = createApp({
    generate: async () => { throw Error('no model calls'); },
    memberStore: {
      findByProviderIdentity: () => null,
      create(value) {
        creates.push(value);
        return { id: 1, name: value.name, phone: value.phone, church_name: value.churchName,
          login_provider: value.loginProvider, created_at: 'fixture' };
      },
    },
    providerIdentity: async value => {
      verifications.push(value);
      return { provider: 'google', providerUserId: 'verified-fixture-subject' };
    },
    memberSessions: { issue(value) { sessions.push(value); return { token: 'fixture-session', expiresInSeconds: 60 }; } },
    logger: { error() {} },
  });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const send = (route, data) => fetch(`http://127.0.0.1:${server.address().port}${route}`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(data),
  });
  try { await run({ send, creates, verifications, sessions }); }
  finally { await new Promise(resolve => server.close(resolve)); }
}
const profile = { name: 'fixture', phone: null, churchName: '', termsAccepted: true, privacyAccepted: true, adultConfirmed: true };

test('legacy signup rejects every unverified social provider before storing an identity', async () => fixture(async ({ send, creates, verifications, sessions }) => {
  for (const loginProvider of ['apple', 'google', 'naver', 'kakao']) {
    for (const identity of [{}, { providerUserId: 'unverified-fixture-subject' }]) {
      const response = await send('/v1/auth/signup', { ...profile, loginProvider, ...identity });
      assert.equal(response.status, 400, loginProvider);
      assert.ok(!(await response.text()).includes('unverified-fixture-subject'));
    }
  }
  assert.equal(creates.length, 0);
  assert.equal(verifications.length, 0);
  assert.equal(sessions.length, 0);
}));

test('legacy signup rejects identity fields even with phone provider and permits the plain phone contract', async () => fixture(async ({ send, creates, verifications, sessions }) => {
  for (const providerUserId of ['unverified-fixture-subject', '', null]) {
    assert.equal((await send('/v1/auth/signup', { ...profile, loginProvider: 'phone', providerUserId })).status, 400);
  }
  assert.equal(creates.length, 0);
  assert.equal((await send('/v1/auth/signup', { ...profile, phone: '01012345678' })).status, 201);
  assert.equal(creates.length, 1);
  assert.equal(creates[0].loginProvider, 'phone');
  assert.equal(creates[0].providerUserId, undefined);
  assert.equal(verifications.length, 0);
  assert.equal(sessions.length, 0);
}));

test('verified provider signup derives identity only from the verifier and ignores spoofed legacy fields', async () => fixture(async ({ send, creates, verifications, sessions }) => {
  const response = await send('/v1/auth/provider/signup', { ...profile, provider: 'google', credential: 'fixture-credential',
    loginProvider: 'apple', providerUserId: 'unverified-fixture-subject' });
  assert.equal(response.status, 201);
  assert.deepEqual(verifications, [{ provider: 'google', credential: 'fixture-credential' }]);
  assert.equal(creates.length, 1);
  assert.equal(creates[0].loginProvider, 'google');
  assert.equal(creates[0].providerUserId, 'verified-fixture-subject');
  assert.deepEqual(sessions, [{ provider: 'google', providerUserId: 'verified-fixture-subject' }]);
}));
