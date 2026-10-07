import assert from 'node:assert/strict';
import { test } from 'node:test';
import { generateKeyPair, exportPKCS8, jwtVerify, exportJWK, createLocalJWKSet } from 'jose';
import { createAppleRevocation } from '../src/auth/apple_revocation.js';
import { createMemberSessions } from '../src/auth/member_session.js';

async function fixture() {
  const keys = await generateKeyPair('ES256', { extractable: true });
  const jwk = await exportJWK(keys.publicKey); jwk.kid = 'test-key';
  const calls = [];
  const verify = async ({ credential }) => ({ provider: 'apple', providerUserId: credential === 'wrong' ? 'other-member' : 'member' });
  const revoke = createAppleRevocation({ clientId: 'com.test.app', teamId: 'test-team', keyId: 'test-key',
    privateKey: await exportPKCS8(keys.privateKey), verify,
    fetchImpl: async (url, options) => {
      const fields = options.body;
      const secret = await jwtVerify(fields.get('client_secret'), createLocalJWKSet({ keys: [jwk] }), {
        issuer: 'test-team', subject: 'com.test.app', audience: 'https://appleid.apple.com', algorithms: ['ES256'],
      });
      assert.equal(secret.payload.exp - secret.payload.iat, 300);
      assert.equal(options.redirect, 'error');
      calls.push({ url, fields });
      return new Response(url.endsWith('/token') ? JSON.stringify({ refresh_token: 'ephemeral-refresh', id_token: 'fresh' }) : '', { status: 200 });
    },
  });
  return { revoke, calls };
}
test('fresh Apple code is exchanged, independently bound and revoked without persistence', async () => {
  const { revoke, calls } = await fixture();
  await revoke({ authorizationCode: 'fresh-code', credential: 'fresh', providerUserId: 'member' });
  assert.equal(calls.length, 2);
  assert.equal(calls[0].fields.get('grant_type'), 'authorization_code');
  assert.equal(calls[1].url, 'https://appleid.apple.com/auth/revoke');
  assert.equal(calls[1].fields.get('token_type_hint'), 'refresh_token');
});
test('wrong Apple account never calls Apple exchange or revoke', async () => {
  const { revoke, calls } = await fixture();
  await assert.rejects(revoke({ authorizationCode: 'code', credential: 'wrong', providerUserId: 'member' }), { status: 401 });
  assert.equal(calls.length, 0);
});
test('missing signing configuration safely rejects without leaking details', async () => {
  await assert.rejects(createAppleRevocation()({}), { status: 503 });
});
test('failed exchange grant binding does not revoke the other account', async () => {
  const keys = await generateKeyPair('ES256', { extractable: true });
  const calls = [];
  const revoke = createAppleRevocation({ clientId: 'test', teamId: 'team', keyId: 'key', privateKey: await exportPKCS8(keys.privateKey),
    verify: async ({ credential }) => ({ provider: 'apple', providerUserId: credential === 'wrong' ? 'other' : 'member' }),
    fetchImpl: async url => { calls.push(url); return new Response(JSON.stringify({ refresh_token: 'refresh', id_token: 'wrong' })); },
  });
  await assert.rejects(revoke({ authorizationCode: 'code', credential: 'fresh', providerUserId: 'member' }), { status: 401 });
  assert.equal(calls.length, 1);
});
for (const filename of [undefined, ':memory:']) test(`identity session revocation clears all matching sessions (${filename ?? 'map'})`, () => {
  const sessions = createMemberSessions({ filename });
  const identity = { provider: 'apple', providerUserId: 'member' };
  const first = sessions.issue(identity), second = sessions.issue(identity);
  const other = sessions.issue({ provider: 'apple', providerUserId: 'other' });
  sessions.revokeIdentity(identity);
  assert.throws(() => sessions.verify(first.token));
  assert.throws(() => sessions.verify(second.token));
  assert.equal(sessions.verify(other.token).providerUserId, 'other');
  sessions.close();
});

test('Apple revocation failure preserves member and sessions; success deletes only target member and all linked sessions', async t => {
  const { createApp } = await import('../src/app.js');
  const sessions = createMemberSessions();
  const identities = [{ provider: 'apple', providerUserId: 'member' }, { provider: 'naver', providerUserId: 'linked' }];
  let deleted = false, fail = true;
  const store = {
    findByProviderIdentity: () => deleted ? null : ({ id: 42 }),
    listIdentities: () => ['apple', 'naver'], listIdentityDetails: () => identities,
    deleteById: id => { assert.equal(id, 42); deleted = true; return true; },
  };
  const apple = sessions.issue(identities[0]), linked = sessions.issue(identities[1]);
  const unrelated = sessions.issue({ provider: 'apple', providerUserId: 'unrelated' });
  const app = createApp({ generate: async () => ({}), memberStore: store, memberSessions: sessions,
    appleRevocation: async proof => {
      assert.equal(proof.providerUserId, 'member');
      assert.equal(proof.authorizationCode, 'code');
      if (fail) { const { IdentityError } = await import('../src/auth/identity_verifier.js'); throw new IdentityError(503); }
    }, logger: { error() {} },
  });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const remove = () => fetch(`http://127.0.0.1:${server.address().port}/v1/account`, {
    method: 'DELETE', headers: { 'content-type': 'application/json', 'x-onaria-member-session': apple.token },
    body: JSON.stringify({ appleAuthorizationCode: 'code', appleCredential: 'credential' }),
  });
  assert.equal((await remove()).status, 503);
  assert.equal(deleted, false); assert.doesNotThrow(() => sessions.verify(linked.token));
  fail = false;
  assert.equal((await remove()).status, 204);
  assert.equal(deleted, true); assert.throws(() => sessions.verify(linked.token));
  assert.throws(() => sessions.verify(apple.token)); assert.doesNotThrow(() => sessions.verify(unrelated.token));
});
