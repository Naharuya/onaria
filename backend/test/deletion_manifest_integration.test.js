import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { createApp } from '../src/app.js';
import { createMemberStore } from '../src/member_store.js';
import { createMemberSessions } from '../src/auth/member_session.js';
import { createDeletionManifest } from '../src/privacy/deletion_manifest.js';

async function withServer(app, action) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    await action(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
}

test('account deletion records durable member generation and permits later re-registration as a new generation', async t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-generation-delete-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));

  const members = createMemberStore({ filename: path.join(root, 'members.sqlite') });
  const sessions = createMemberSessions({ filename: path.join(root, 'sessions.sqlite') });
  const manifest = createDeletionManifest({ filename: path.join(root, 'manifest.sqlite') });
  t.after(() => { members.close(); sessions.close(); manifest.close(); });

  const old = members.create({
    name: 'old',
    phone: '01011112222',
    churchName: '',
    loginProvider: 'google',
    providerUserId: 'same-provider-user',
  });
  const oldSession = sessions.issue({ provider: 'google', providerUserId: 'same-provider-user' });

  const app = createApp({
    generate: Object.assign(async () => ({}), { mode: 'test' }),
    memberStore: members,
    memberSessions: sessions,
    deletionManifest: manifest,
    providerIdentity: async ({ provider, credential }) => ({ provider, providerUserId: credential }),
    identity: { required: false, verify: null },
    logger: { error() {} },
  });

  await withServer(app, async base => {
    const removed = await fetch(`${base}/v1/account`, {
      method: 'DELETE',
      headers: { 'X-Onaria-Member-Session': oldSession.token, 'content-type':'application/json' },
      body:JSON.stringify({reauthProvider:'google',reauthCredential:'same-provider-user'}),
    });
    assert.equal(removed.status, 204);
    assert.equal(manifest.contains(old.id), true);
    assert.equal(members.findByProviderIdentity('google', 'same-provider-user'), null);

    const signup = await fetch(`${base}/v1/auth/provider/signup`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        provider: 'google',
        credential: 'same-provider-user',
        name: 'new',
        phone: '01011112222',
        churchName: '',
        termsAccepted: true,
        privacyAccepted: true,
        adultConfirmed: true,
      }),
    });
    assert.equal(signup.status, 201);
    const body = await signup.json();
    assert.notEqual(body.member.id, old.id);
    assert.equal(manifest.contains(body.member.id), false);

    const login = await fetch(`${base}/v1/auth/provider/session`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ provider: 'google', credential: 'same-provider-user' }),
    });
    assert.equal(login.status, 201);
  });
});

test('manifest reapply removes a deleted generation from an older restored member snapshot', async t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-generation-restore-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));

  const source = path.join(root, 'members.sqlite');
  let store = createMemberStore({ filename: source });
  const old = store.create({
    name: 'restore-old',
    phone: '01022223333',
    churchName: '',
    loginProvider: 'naver',
    providerUserId: 'restore-provider-user',
  });
  store.close();

  const snapshot = path.join(root, 'old-backup.sqlite');
  fs.copyFileSync(source, snapshot);

  const manifest = createDeletionManifest({ filename: path.join(root, 'manifest.sqlite') });
  t.after(() => manifest.close());
  manifest.record(old.id);

  store = createMemberStore({ filename: snapshot });
  assert.ok(store.findByProviderIdentity('naver', 'restore-provider-user'));
  assert.equal(manifest.reapply(store), 1);
  assert.equal(store.findByProviderIdentity('naver', 'restore-provider-user'), null);
  store.close();
});
