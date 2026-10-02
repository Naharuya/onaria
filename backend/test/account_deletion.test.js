import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createApp } from '../src/app.js';

function fixture({ verify } = {}) {
  const members = new Map([
    ['google:alice', { id: 7, login_provider: 'google', provider_user_id: 'alice' }],
    ['kakao:bob', { id: 8, login_provider: 'kakao', provider_user_id: 'bob' }],
  ]);
  const deleted = [];
  const memberStore = {
    getAdminOverview: () => ({ total: members.size, recent: [] }),
    findByProviderIdentity(provider, providerUserId) {
      return members.get(`${provider}:${providerUserId}`) ?? null;
    },
    deleteById(id) {
      const entry = [...members.entries()].find(([, member]) => member.id === id);
      if (!entry) return false;
      members.delete(entry[0]);
      deleted.push(id);
      return true;
    },
  };
  const app = createApp({ generate: Object.assign(async () => ({}), { mode: 'test' }), memberStore,
    identity: { required: false, verify: verify ?? null }, logger: { error() {} } });
  return { app, deleted };
}

async function withServer(app, action) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try { await action(`http://127.0.0.1:${server.address().port}`); }
  finally { await new Promise(resolve => server.close(resolve)); }
}

const remove = (baseUrl, token) => fetch(`${baseUrl}/v1/account`, {
  method: 'DELETE', headers: token ? { 'X-Soul-Identity-Token': token } : {},
});

test('account deletion is closed without verified provider identity', async () => {
  for (const verify of [null, async () => ({ userId: 'ai-only', plan: 'free' }), async () => ({ provider: 'phone', providerUserId: '01012345678' })]) {
    const { app, deleted } = fixture({ verify });
    await withServer(app, async baseUrl => {
      assert.equal((await remove(baseUrl, verify ? 'token' : null)).status, 401);
      assert.deepEqual(deleted, []);
    });
  }
});

test('verified provider identity deletes only its own member', async () => {
  const { app, deleted } = fixture({ verify: async () => ({ provider: 'google', providerUserId: 'alice' }) });
  await withServer(app, async baseUrl => {
    assert.equal((await remove(baseUrl, 'verified')).status, 204);
    assert.deepEqual(deleted, [7]);
    assert.equal((await remove(baseUrl, 'verified')).status, 404);
    assert.deepEqual(deleted, [7]);
  });
});

test('unknown verified identity cannot delete another member', async () => {
  const { app, deleted } = fixture({ verify: async () => ({ provider: 'google', providerUserId: 'mallory' }) });
  await withServer(app, async baseUrl => {
    assert.equal((await remove(baseUrl, 'verified')).status, 404);
    assert.deepEqual(deleted, []);
  });
});
