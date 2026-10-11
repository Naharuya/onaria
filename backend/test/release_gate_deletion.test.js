import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import Database from 'better-sqlite3';
import { createApp } from '../src/app.js';
import { createMemberStore } from '../src/member_store.js';
import { createMemberSessions } from '../src/auth/member_session.js';

test('isolated SQLite deletion removes linked identities and all sessions; unrelated member and earlier backup survive', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'onaria-release-delete-'));
  const filename = path.join(root, 'members.sqlite');
  const store = createMemberStore({ filename });
  const sessions = createMemberSessions({ filename: path.join(root, 'sessions.sqlite') });
  const db = new Database(filename, { readonly: true });
  let server;
  try {
    const member = store.create({ loginProvider: 'naver', providerUserId: 'fixture-owner' });
    store.attachIdentity(member.id, 'google', 'fixture-linked');
    const unrelated = store.create({ loginProvider: 'naver', providerUserId: 'fixture-other' });
    const tokens = [sessions.issue({ provider: 'naver', providerUserId: 'fixture-owner' }),
      sessions.issue({ provider: 'naver', providerUserId: 'fixture-owner' }),
      sessions.issue({ provider: 'google', providerUserId: 'fixture-linked' })];
    const other = sessions.issue({ provider: 'naver', providerUserId: 'fixture-other' });
    const snapshot = path.join(root, 'snapshot.sqlite');
    await db.backup(snapshot);
    const app = createApp({ generate: Object.assign(async () => ({}), { mode: 'test' }), memberStore: store,
      memberSessions: sessions, providerIdentity: async ({ provider, credential }) => ({ provider, providerUserId: credential }),
      logger: { error() {} }, identity: { required: false, verify: null } });
    server = app.listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    const remove = token => fetch(`${base}/v1/account`, { method: 'DELETE', headers: token ? { 'X-Onaria-Member-Session': token, 'content-type':'application/json' } : {}, body:JSON.stringify({reauthProvider:'naver',reauthCredential:'fixture-owner'}) });
    assert.equal((await remove(null)).status, 401);
    assert.equal(store.getAdminOverview().total, 2);
    assert.equal((await remove(tokens[0].token)).status, 204);
    assert.equal(db.prepare('SELECT COUNT(*) AS n FROM members WHERE id = ?').get(member.id).n, 0);
    assert.equal(db.prepare('SELECT COUNT(*) AS n FROM member_identities WHERE member_id = ?').get(member.id).n, 0);
    for (const session of tokens) assert.throws(() => sessions.verify(session.token));
    for (const session of tokens) {
      assert.equal((await fetch(`${base}/v1/account`, { headers: { 'X-Onaria-Member-Session': session.token } })).status, 401);
    }
    assert.equal(sessions.verify(other.token).providerUserId, 'fixture-other');
    assert.equal(store.findByProviderIdentity('naver', 'fixture-other').id, unrelated.id);
    assert.equal((await remove(tokens[0].token)).status, 401);
    const response = await fetch(`${base}/v1/auth/provider/session`, { method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ provider: 'naver', credential: 'fixture-owner' }) });
    assert.equal(response.status, 404);
    const backup = new Database(snapshot, { readonly: true });
    try { assert.equal(backup.prepare('SELECT COUNT(*) AS n FROM members WHERE id = ?').get(member.id).n, 1); }
    finally { backup.close(); }
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    db.close(); sessions.close(); store.close();
    assert.equal(path.dirname(root), tmpdir().replace(/\/$/, ''));
    assert.ok(path.basename(root).startsWith('onaria-release-delete-'));
    await rm(root, { recursive: true });
  }
});

for (const failure of ['session', 'member']) {
  test(`deletion ${failure} failure preserves member and reports account failure without AI/secret text`, async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'onaria-release-failure-'));
    const store = createMemberStore({ filename: path.join(root, 'members.sqlite') });
    const sessions = createMemberSessions({ filename: path.join(root, 'sessions.sqlite') });
    let server;
    try {
      const owner = store.create({ loginProvider: 'naver', providerUserId: 'fixture-owner' });
      store.attachIdentity(owner.id, 'google', 'fixture-linked');
      const one = sessions.issue({ provider: 'naver', providerUserId: 'fixture-owner' });
      const linked = sessions.issue({ provider: 'google', providerUserId: 'fixture-linked' });
      const otherMember = store.create({ loginProvider: 'naver', providerUserId: 'fixture-other' });
      const other = sessions.issue({ provider: 'naver', providerUserId: 'fixture-other' });
      const wrappedStore = Object.create(store);
      const wrappedSessions = Object.create(sessions);
      let failing = true;
      if (failure === 'member') wrappedStore.deleteById = id => {
        if (failing) throw new Error('fixture-private-database-error');
        return store.deleteById(id);
      };
      if (failure === 'session') wrappedSessions.revokeIdentity = identity => {
        if (failing && identity.provider === 'naver') throw new Error('fixture-private-session-error');
        sessions.revokeIdentity(identity);
      };
      const logs = [];
      const app = createApp({ generate: async () => ({}), memberStore: wrappedStore,
        memberSessions: wrappedSessions, providerIdentity:async ({provider,credential})=>({provider,providerUserId:credential}), logger: { error: (...values) => logs.push(values) } });
      server = app.listen(0, '127.0.0.1');
      await new Promise(resolve => server.once('listening', resolve));
      const base = `http://127.0.0.1:${server.address().port}`;
      const response = await fetch(`${base}/v1/account`, { method: 'DELETE', body:JSON.stringify({reauthProvider:'naver',reauthCredential:'fixture-owner'}), headers: { 'content-type':'application/json', 'X-Onaria-Member-Session': one.token } });
      assert.equal(store.findByProviderIdentity('naver', 'fixture-owner')?.id, owner.id);
      assert.deepEqual(store.listIdentities(owner.id), ['google', 'naver']);
      assert.equal(response.status, 503);
      const body = await response.json();
      assert.match(body.message, /회원탈퇴/);
      assert.doesNotMatch(body.message, /AI|fixture-private/);
      assert.deepEqual(logs, [['account_deletion_failed', { status: 503 }]]);
      assert.equal(sessions.verify(other.token).providerUserId, 'fixture-other');
      assert.equal(store.findByProviderIdentity('naver', 'fixture-other').id, otherMember.id);
      if (failure === 'session') assert.throws(() => sessions.verify(linked.token));
      else assert.throws(() => sessions.verify(one.token));
      assert.equal((await fetch(`${base}/v1/account`, { headers: { 'X-Onaria-Member-Session': one.token } })).status, failure === 'session' ? 200 : 401);
      failing = false;
      const retry = failure === 'member' ? sessions.issue({ provider: 'naver', providerUserId: 'fixture-owner' }) : one;
      assert.equal((await fetch(`${base}/v1/account`, { method: 'DELETE', body:JSON.stringify({reauthProvider:'naver',reauthCredential:'fixture-owner'}), headers: { 'content-type':'application/json', 'X-Onaria-Member-Session': retry.token } })).status, 204);
      assert.equal(store.findByProviderIdentity('naver', 'fixture-owner'), null);
    } finally {
      if (server) await new Promise(resolve => server.close(resolve));
      sessions.close(); store.close();
      assert.equal(path.dirname(root), tmpdir().replace(/\/$/, ''));
      assert.ok(path.basename(root).startsWith('onaria-release-failure-'));
      await rm(root, { recursive: true });
    }
  });
}
