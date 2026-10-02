import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createApp } from '../src/app.js';
import { createMemberSessions } from '../src/auth/member_session.js';
import { IdentityError } from '../src/auth/identity_verifier.js';

function fixture({ providerIdentity } = {}) {
  const members = new Map([
    ['google:alice', { id: 7, login_provider: 'google', provider_user_id: 'alice' }],
    ['kakao:bob', { id: 8, login_provider: 'kakao', provider_user_id: 'bob' }],
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
    assert.match(body.sessionToken, /^[A-Za-z0-9_-]{43}$/); assert.equal(body.expiresInSeconds, 900); assert.equal(memberSessions.size(), 1);
    assert.equal((await remove(base, body.sessionToken)).status, 204); assert.deepEqual(deleted, [7]); assert.equal(memberSessions.size(), 0);
    assert.equal((await remove(base, body.sessionToken)).status, 401); });
});

test('unknown identity cannot delete another member and logout revokes session', async () => {
  const { app, deleted } = fixture();
  await withServer(app, async base => { const { body } = await login(base, 'google', 'mallory'); assert.equal((await remove(base, body.sessionToken)).status, 404); assert.deepEqual(deleted, []);
    const bob = (await login(base, 'kakao', 'bob')).body; const logout = await fetch(`${base}/v1/auth/provider/session`, { method: 'DELETE', headers: { 'X-Onaria-Member-Session': bob.sessionToken } });
    assert.equal(logout.status, 204); assert.equal((await remove(base, bob.sessionToken)).status, 401); assert.deepEqual(deleted, []); });
});

test('provider/session boundary fails closed and never accepts old AI identity header', async () => {
  const { app, deleted } = fixture({ providerIdentity: async () => { throw new IdentityError(); } });
  await withServer(app, async base => { assert.equal((await remove(base, null)).status, 401);
    assert.equal((await fetch(`${base}/v1/account`, { method: 'DELETE', headers: { 'X-Soul-Identity-Token': 'legacy' } })).status, 401);
    const { response } = await login(base, 'google', 'bad'); assert.equal(response.status, 401); assert.deepEqual(deleted, []); });
});
