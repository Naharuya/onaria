import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createMemberStore } from '../src/member_store.js';

test('provider identity resolves only the matching social member', () => {
  const directory = mkdtempSync(join(tmpdir(), 'onaria-member-identity-test-'));
  const filename = join(directory, 'fixture.sqlite');
  const store = createMemberStore({ filename });
  try {
    const google = store.create({ name: '구글회원', phone: '01055556666', churchName: '테스트교회', loginProvider: 'google', providerUserId: 'google-sub-1' });
    store.create({ name: '카카오회원', phone: '01077778888', churchName: '테스트교회', loginProvider: 'kakao', providerUserId: 'kakao-sub-1' });
    assert.equal(store.findByProviderIdentity('google', 'google-sub-1').id, google.id);
    assert.equal(store.findByProviderIdentity('kakao', 'google-sub-1'), null);
    assert.equal(store.findByProviderIdentity('phone', 'google-sub-1'), null);
    assert.equal(store.findByProviderIdentity('google', ''), null);
  } finally {
    store.close();
    rmSync(directory, { recursive: true, force: true });
  }
});

test('member deletion is id-scoped, idempotent and allows later re-registration', () => {
  const directory = mkdtempSync(join(tmpdir(), 'onaria-member-delete-test-'));
  const filename = join(directory, 'fixture.sqlite');
  const store = createMemberStore({ filename });
  try {
    const first = store.create({ name: '삭제회원', phone: '01011112222', churchName: '테스트교회', loginProvider: 'phone' });
    store.create({ name: '유지회원', phone: '01033334444', churchName: '테스트교회', loginProvider: 'phone' });
    assert.equal(store.deleteById(first.id), true);
    assert.equal(store.deleteById(first.id), false);
    assert.equal(store.getAdminOverview().total, 1);
    const recreated = store.create({ name: '재가입회원', phone: '01011112222', churchName: '테스트교회', loginProvider: 'phone' });
    assert.notEqual(recreated.id, first.id);
    assert.equal(store.getAdminOverview().total, 2);
    assert.equal(store.deleteById(0), false);
  } finally {
    store.close();
    rmSync(directory, { recursive: true, force: true });
  }
});

test('native SQLite persists members and rejects duplicate phone after reopening', () => {
  const directory = mkdtempSync(join(tmpdir(), 'soul-member-test-'));
  const filename = join(directory, 'fixture.sqlite');
  let store;
  try {
    store = createMemberStore({ filename });
    const fixture = { name: '테스트회원', phone: '01012345678', churchName: '테스트교회', loginProvider: 'phone' };
    const member = store.create(fixture);
    assert.equal(member.phone, fixture.phone);
    store.close();
    store = undefined;
    store = createMemberStore({ filename });
    const overview = store.getAdminOverview();
    assert.equal(overview.total, 1);
    assert.equal(overview.recent[0].phone, '010****5678');
    assert.equal(overview.recent[0].churchName, '비공개');
    assert.throws(() => store.create(fixture), { code: 'PHONE_EXISTS' });
  } finally {
    store?.close();
    rmSync(directory, { recursive: true, force: true });
  }
});
