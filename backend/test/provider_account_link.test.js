import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createApp } from '../src/app.js';
import { createMemberStore } from '../src/member_store.js';
import { createMemberSessions } from '../src/auth/member_session.js';

async function fixture(run) {
  const dir = mkdtempSync(join(tmpdir(), 'onaria-provider-link-'));
  const store = createMemberStore({ filename: join(dir, 'members.sqlite') });
  const sessions = createMemberSessions();
  const providerIdentity = async ({ provider, credential }) => ({
    provider,
    providerUserId: `${provider}:${credential}`,
  });
  const member = store.create({
    name: '기존회원', phone: '01012345678', churchName: '',
    loginProvider: 'google', providerUserId: 'google:existing',
  });
  const app = createApp({ generate: async () => ({}), memberStore: store, memberSessions: sessions, providerIdentity });
  const server = await new Promise(resolve => {
    const instance = app.listen(0, '127.0.0.1', () => resolve(instance));
  });
  try {
    await run({ base: `http://127.0.0.1:${server.address().port}`, store, sessions, member });
  } finally {
    await new Promise(resolve => server.close(resolve));
    sessions.close(); store.close(); rmSync(dir, { recursive: true, force: true });
  }
}

async function post(base, path, body, token) {
  const response = await fetch(base + path, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { 'x-onaria-member-session': token } : {}),
    },
    body: JSON.stringify(path === '/v1/account/providers' ? {reauthProvider:'google',reauthCredential:'existing',...body} : body),
  });
  const text = await response.text();
  return { response, json: text ? JSON.parse(text) : null };
}

test('provider session is the only login path for an already linked provider', async () => {
  await fixture(async ({ base, member }) => {
    const login = await post(base, '/v1/auth/provider/session', { provider: 'google', credential: 'existing' });
    assert.equal(login.response.status, 201);
    assert.equal(typeof login.json.sessionToken, 'string');

    const signup = await post(base, '/v1/auth/provider/signup', {
      provider: 'google', credential: 'existing', termsAccepted: true, privacyAccepted: true, adultConfirmed: true,
    });
    assert.equal(signup.response.status, 409);
    assert.equal(signup.json.code, 'IDENTITY_ALREADY_REGISTERED');
    assert.equal(member.id, 1);
  });
});

test('dedicated account link requires existing member session and attaches verified provider', async () => {
  await fixture(async ({ base, store, member }) => {
    const login = await post(base, '/v1/auth/provider/session', { provider: 'google', credential: 'existing' });
    const linked = await post(base, '/v1/account/providers', {
      provider: 'naver', credential: 'new-naver',
    }, login.json.sessionToken);
    assert.equal(linked.response.status, 200);
    assert.equal(linked.json.member.id, member.id);
    assert.equal(linked.json.linked, true);
    assert.deepEqual(store.listIdentities(member.id), ['google', 'naver']);

    const newLogin = await post(base, '/v1/auth/provider/session', { provider: 'naver', credential: 'new-naver' });
    assert.equal(newLogin.response.status, 201);
  });
});

test('account link rejects provider identity owned by another member', async () => {
  await fixture(async ({ base, store }) => {
    store.create({ name: '다른회원', phone: '01012345678', churchName: '', loginProvider: 'kakao', providerUserId: 'kakao:other' });
    const login = await post(base, '/v1/auth/provider/session', { provider: 'google', credential: 'existing' });
    const conflict = await post(base, '/v1/account/providers', { provider: 'kakao', credential: 'other' }, login.json.sessionToken);
    assert.equal(conflict.response.status, 409);
    assert.equal(conflict.json.code, 'IDENTITY_EXISTS');
  });
});

test('same unverified phone can exist on separate accounts and never proves ownership', async () => {
  await fixture(async ({ base, store }) => {
    const signup = await post(base, '/v1/auth/provider/signup', {
      provider: 'naver', credential: 'second', name: '다른 사람', phone: '010-1234-5678', churchName: '',
      termsAccepted: true, privacyAccepted: true, adultConfirmed: true,
    });
    assert.equal(signup.response.status, 201);
    assert.equal(store.getAdminOverview().total, 2);
    assert.equal(store.findByProviderIdentity('naver', 'naver:second').id, signup.json.member.id);
  });
});

test('unknown identity and invalid link sessions fail closed without mutation',async()=>{
 await fixture(async({base,store,member})=>{
 const unknown=await post(base,'/v1/auth/provider/session',{provider:'naver',credential:'unknown'});
 assert.equal(unknown.response.status,404);assert.equal(unknown.json.code,'PROVIDER_IDENTITY_NOT_FOUND');
 for(const token of [undefined,'invalid']) {
 const linked=await post(base,'/v1/account/providers',{provider:'naver',credential:'unknown'},token);
 assert.equal(linked.response.status,401);
 }assert.deepEqual(store.listIdentities(member.id),['google']);
 });
});
test('same-provider replacement blocked, duplicate idempotent and old session revoked on success',async()=>{
 await fixture(async({base,store,sessions,member})=>{
 const login=await post(base,'/v1/auth/provider/session',{provider:'google',credential:'existing'});
 const conflict=await post(base,'/v1/account/providers',{provider:'google',credential:'different'},login.json.sessionToken);
 assert.equal(conflict.response.status,409);assert.equal(conflict.json.code,'PROVIDER_ALREADY_LINKED');
 assert.ok(sessions.verify(login.json.sessionToken));
 const same=await post(base,'/v1/account/providers',{provider:'google',credential:'existing'},login.json.sessionToken);
 assert.equal(same.response.status,200);assert.equal(same.json.linked,false);
 assert.throws(()=>sessions.verify(login.json.sessionToken));
 assert.deepEqual(store.listIdentities(member.id),['google']);
 const linked=await post(base,'/v1/account/providers',{provider:'naver',credential:'new'},same.json.sessionToken);
 assert.equal(linked.response.status,200);assert.throws(()=>sessions.verify(same.json.sessionToken));
 assert.equal(store.getAdminOverview().total,1);
 });
});
