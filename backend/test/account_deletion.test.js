import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createApp } from '../src/app.js';
import { createMemberSessions } from '../src/auth/member_session.js';
import { IdentityError } from '../src/auth/identity_verifier.js';
import { createNaverProviderVerifier } from '../src/auth/provider_identity.js';

function fixture({ providerIdentity } = {}) {
  const members = new Map([
    ['google:alice', { id: 7, login_provider: 'google', provider_user_id: 'alice' }],
    ['kakao:bob', { id: 8, login_provider: 'kakao', provider_user_id: 'bob' }],
    ['naver:nora', { id: 9, login_provider: 'naver', provider_user_id: 'nora' }],
  ]);
  const deleted = []; const memberSessions = createMemberSessions();
  const memberStore = {
    getAdminOverview: () => ({ total: members.size, recent: [] }),
    findByProviderIdentity(provider, providerUserId) { return members.get(`${provider}:${providerUserId}`) ?? null; },
    deleteById(id) { const entry = [...members.entries()].find(([, member]) => member.id === id); if (!entry) return false;
      members.delete(entry[0]); deleted.push(id); return true; },
  };
  const app = createApp({ generate: Object.assign(async () => ({}), { mode: 'test' }), memberStore,
    providerIdentity: providerIdentity ?? (async ({ provider, credential }) => ({ provider, providerUserId: credential })),
    memberSessions, identity: { required: false, verify: null }, logger: { error() {} } });
  return { app, deleted, memberSessions };
}
async function withServer(app, action) { const server = app.listen(0, '127.0.0.1'); await new Promise(r => server.once('listening', r));
  try { await action(`http://127.0.0.1:${server.address().port}`); } finally { await new Promise(r => server.close(r)); } }
async function login(base, provider, credential) { const response = await fetch(`${base}/v1/auth/provider/session`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ provider, credential }) });
  return { response, body: response.status === 201 ? await response.json() : null }; }
const remove = (base, token) => fetch(`${base}/v1/account`, { method: 'DELETE', headers: token ? { 'X-Onaria-Member-Session': token } : {} });

test('provider login issues opaque session and deletes only verified own member', async () => {
  const { app, deleted, memberSessions } = fixture();
  await withServer(app, async base => { const { response, body } = await login(base, 'google', 'alice'); assert.equal(response.status, 201);
    assert.match(body.sessionToken, /^[A-Za-z0-9_-]{43}$/); assert.equal(body.expiresInSeconds, 30 * 24 * 60 * 60); assert.equal(memberSessions.size(), 1);
    assert.equal((await remove(base, body.sessionToken)).status, 204); assert.deepEqual(deleted, [7]); assert.equal(memberSessions.size(), 0);
    assert.equal((await remove(base, body.sessionToken)).status, 401); });
});

test('unknown identity cannot obtain a member session and logout revokes a valid session', async () => {
  const { app, deleted } = fixture();
  await withServer(app, async base => {
    const unknown = await login(base, 'google', 'mallory');
    assert.equal(unknown.response.status, 404);
    assert.equal(unknown.body, null);
    assert.deepEqual(deleted, []);
    const bob = (await login(base, 'kakao', 'bob')).body;
    const logout = await fetch(`${base}/v1/auth/provider/session`, {
      method: 'DELETE',
      headers: { 'X-Onaria-Member-Session': bob.sessionToken },
    });
    assert.equal(logout.status, 204);
    assert.equal((await remove(base, bob.sessionToken)).status, 401);
    assert.deepEqual(deleted, []);
  });
});

test('Naver logout then fresh padded credential relogin preserves existing member', async () => {
  const credentials = [];
  const verify = createNaverProviderVerifier({ fetchImpl: async (_url, options) => {
    credentials.push(options.headers.Authorization);
    return new Response(JSON.stringify({ resultcode: '00', response: { id: 'nora' } }), { status: 200 });
  } });
  const { app, deleted, memberSessions } = fixture({ providerIdentity: ({ credential }) => verify(credential) });
  await withServer(app, async base => {
    const first = await login(base, 'naver', 'first-fixture-credential');
    assert.equal(first.response.status, 201);
    const logout = await fetch(`${base}/v1/auth/provider/session`, {
      method: 'DELETE', headers: { 'X-Onaria-Member-Session': first.body.sessionToken },
    });
    assert.equal(logout.status, 204);
    assert.throws(() => memberSessions.verify(first.body.sessionToken), IdentityError);
    const second = await login(base, 'naver', 'fresh-fixture-credential==');
    assert.equal(second.response.status, 201);
    assert.notEqual(second.body.sessionToken, first.body.sessionToken);
    assert.deepEqual(memberSessions.verify(second.body.sessionToken), { provider: 'naver', providerUserId: 'nora' });
    assert.deepEqual(credentials, ['Bearer first-fixture-credential', 'Bearer fresh-fixture-credential==']);
    assert.deepEqual(deleted, []);
  });
});

test('provider/session boundary fails closed and never accepts old AI identity header', async () => {
  const { app, deleted } = fixture({ providerIdentity: async () => { throw new IdentityError(); } });
  await withServer(app, async base => { assert.equal((await remove(base, null)).status, 401);
    assert.equal((await fetch(`${base}/v1/account`, { method: 'DELETE', headers: { 'X-Soul-Identity-Token': 'legacy' } })).status, 401);
    const { response } = await login(base, 'google', 'bad'); assert.equal(response.status, 401); assert.deepEqual(deleted, []); });
});

test('authenticated member can link a second verified provider without creating a duplicate member', async () => {
  const identities = new Map([
    ['apple:owner', { id: 11, name: '연결회원', phone: '01011112222', church_name: '테스트교회', login_provider: 'apple', created_at: '2026-10-06' }],
  ]);
  const memberSessions = createMemberSessions();
  const memberStore = {
    getAdminOverview: () => ({ total: 1, recent: [] }),
    findByProviderIdentity(provider, providerUserId) {
      return identities.get(`${provider}:${providerUserId}`) ?? null;
    },
    attachIdentity(memberId, provider, providerUserId) {
      const member = identities.get('apple:owner');
      if (!member || member.id !== memberId) return null;
      identities.set(`${provider}:${providerUserId}`, member);
      return member;
    },
    create() { throw new Error('must not create duplicate member'); },
  };
  const app = createApp({
    generate: Object.assign(async () => ({}), { mode: 'test' }),
    memberStore,
    providerIdentity: async ({ provider, credential }) => ({ provider, providerUserId: credential }),
    memberSessions,
    identity: { required: false, verify: null },
    logger: { error() {} },
  });

  await withServer(app, async base => {
    const appleSession = memberSessions.issue({ provider: 'apple', providerUserId: 'owner' });
    const response = await fetch(`${base}/v1/auth/provider/signup`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'X-Onaria-Member-Session': appleSession.token,
      },
      body: JSON.stringify({ provider: 'kakao', credential: 'kakao-owner' }),
    });
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.member.id, 11);
    assert.equal(body.linked, true);
    assert.equal(identities.get('kakao:kakao-owner').id, 11);
    assert.equal(memberSessions.verify(body.sessionToken).provider, 'kakao');
    assert.throws(() => memberSessions.verify(appleSession.token));
  });
});

test('account overview exposes providers and current provider; unlink blocks current provider', async () => {
  const identities = new Map([
    ['apple:owner', { id: 21, name: '계정관리회원', phone: '01099991111', church_name: '', login_provider: 'apple', created_at: '2026-10-06' }],
    ['google:g-owner', { id: 21, name: '계정관리회원', phone: '01099991111', church_name: '', login_provider: 'apple', created_at: '2026-10-06' }],
  ]);
  const memberSessions = createMemberSessions();
  const memberStore = {
    getAdminOverview: () => ({ total: 1, recent: [] }),
    findByProviderIdentity(provider, providerUserId) { return identities.get(`${provider}:${providerUserId}`) ?? null; },
    listIdentities: () => ['apple', 'google'],
    detachIdentity(_memberId, provider) { identities.delete(`${provider}:g-owner`); return true; },
  };
  const app = createApp({ generate: Object.assign(async () => ({}), { mode: 'test' }), memberStore,
    providerIdentity: async ({ provider, credential }) => ({ provider, providerUserId: credential }), memberSessions,
    identity: { required: false, verify: null }, logger: { error() {} } });
  await withServer(app, async base => {
    const apple = memberSessions.issue({ provider: 'apple', providerUserId: 'owner' });
    const overview = await fetch(`${base}/v1/account`, { headers: { 'X-Onaria-Member-Session': apple.token } });
    assert.equal(overview.status, 200);
    const body = await overview.json();
    assert.deepEqual(body.providers, ['apple', 'google']);
    assert.equal(body.currentProvider, 'apple');
    const current = await fetch(`${base}/v1/account/providers/apple`, { method: 'DELETE', headers: { 'X-Onaria-Member-Session': apple.token } });
    assert.equal(current.status, 409);
    const other = await fetch(`${base}/v1/account/providers/google`, { method: 'DELETE', headers: { 'X-Onaria-Member-Session': apple.token } });
    assert.equal(other.status, 204);
  });
});
