import assert from 'node:assert/strict';
import { test } from 'node:test';
import Database from 'better-sqlite3';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { memberSchema, adminMember } from '../src/member_schema.js';
import { createMemberStore } from '../src/member_store.js';
import { migrateOptionalProfiles } from '../src/optional_profile_migration.js';

test('social signup allows empty profile but still requires both consents', () => {
  const input = { loginProvider: 'apple', providerUserId: 'a', termsAccepted: true, privacyAccepted: true, adultConfirmed: true };
  const member = memberSchema.parse(input);
  assert.equal(member.name, ''); assert.equal(member.phone, null);
  assert.equal(memberSchema.parse({ ...input, phone: '+1 202-555-0199' }).phone, '+12025550199');
  assert.equal(memberSchema.safeParse({ ...input, termsAccepted: false }).success, false);
  assert.equal(memberSchema.safeParse({ ...input, adultConfirmed: false }).success, false);
  assert.equal(memberSchema.safeParse({ ...input, adultConfirmed: undefined }).success, false);
  assert.equal(memberSchema.safeParse({ ...input, privacyAccepted: undefined }).success, false);
  assert.equal(memberSchema.safeParse({ ...input, phone: 'garbage' }).success, false);
});

test('multiple members without contact details retain distinct provider identities', () => {
  const dir = mkdtempSync(join(tmpdir(), 'onaria-optional-profile-'));
  const store = createMemberStore({ filename: join(dir, 'members.sqlite') });
  try {
    const first = store.create({ loginProvider: 'apple', providerUserId: 'a' });
    const second = store.create({ loginProvider: 'naver', providerUserId: 'b' });
    assert.notEqual(first.id, second.id); assert.equal(first.phone, null);
    assert.equal(store.findByProviderIdentity('apple', 'a').id, first.id);
    assert.equal(store.findByProviderIdentity('naver', 'b').id, second.id);
    assert.deepEqual(store.listIdentityDetails(first.id), [{ provider: 'apple', providerUserId: 'a' }]);
    assert.equal(adminMember(first).phone, '****');
  } finally { store.close(); rmSync(dir, { recursive: true, force: true }); }
});

test('explicit migration preserves members, linked identities, consent metadata and sequence', () => {
  const db = new Database(':memory:');
  db.pragma('foreign_keys = ON');
  db.exec(`CREATE TABLE members(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE, church_name TEXT NOT NULL, login_provider TEXT NOT NULL DEFAULT 'phone',
    provider_user_id TEXT, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, terms_version TEXT, privacy_version TEXT, consented_at TEXT);
    CREATE TABLE member_identities(id INTEGER PRIMARY KEY, member_id INTEGER REFERENCES members(id) ON DELETE CASCADE,
      provider TEXT, provider_user_id TEXT);
    INSERT INTO members(id,name,phone,church_name,login_provider,terms_version) VALUES(7,'existing','01012345678','','apple','old');
    INSERT INTO member_identities VALUES(1,7,'apple','a');
    UPDATE sqlite_sequence SET seq = 20 WHERE name = 'members';`);
  try {
    const before = db.prepare('SELECT * FROM members').all();
    assert.equal(migrateOptionalProfiles(db), true);
    assert.deepEqual(db.prepare('SELECT * FROM members').all(), before);
    assert.equal(db.prepare('SELECT member_id FROM member_identities').get().member_id, 7);
    assert.equal(db.prepare("SELECT seq FROM sqlite_sequence WHERE name='members'").get().seq, 20);
    db.prepare("INSERT INTO members(name,phone,church_name) VALUES('',NULL,'')").run();
    assert.equal(db.prepare('SELECT MAX(id) AS id FROM members').get().id, 21);
    assert.equal(db.pragma('foreign_key_check').length, 0);
    assert.equal(migrateOptionalProfiles(db), false);
    assert.throws(() => db.prepare("INSERT INTO members(name,phone,church_name) VALUES('','01012345678','')").run());
  } finally { db.close(); }
});

test('HTTP social signup requires consent and permits contact-free registration', async () => {
  const { createApp } = await import('../src/app.js');
  const { createMemberSessions } = await import('../src/auth/member_session.js');
  const dir = mkdtempSync(join(tmpdir(), 'onaria-optional-signup-'));
  const store = createMemberStore({ filename: join(dir, 'members.sqlite') });
  const sessions = createMemberSessions();
  const app = createApp({ generate: async () => ({}), memberStore: store, memberSessions: sessions,
    providerIdentity: async ({ provider, credential }) => ({ provider, providerUserId: credential }) });
  let server;
  try {
    server = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
    const signup = body => fetch(`http://127.0.0.1:${server.address().port}/v1/auth/provider/signup`, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body),
    });
    const input = { provider: 'apple', credential: 'test-identity' };
    assert.equal((await signup(input)).status, 400);
    assert.equal((await signup({ ...input, termsAccepted: true, privacyAccepted: true, adultConfirmed: false })).status, 400);
    assert.equal(store.getAdminOverview().total, 0);
    const response = await signup({ ...input, termsAccepted: true, privacyAccepted: true, adultConfirmed: true });
    assert.equal(response.status, 201);
    const created = await response.json();
    assert.equal(created.member.phone, null); assert.equal(created.member.name, '');
    assert.equal(store.getAdminOverview().total, 1);
    const relogin = await signup(input);
    assert.equal(relogin.status, 200);
    assert.equal((await relogin.json()).member.id, created.member.id);
    assert.equal(store.getAdminOverview().total, 1);
  } finally { if (server) await new Promise(resolve => server.close(resolve)); store.close(); rmSync(dir, { recursive: true, force: true }); }
});
