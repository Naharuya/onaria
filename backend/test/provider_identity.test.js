import assert from 'node:assert/strict';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { test } from 'node:test';
import { IdentityError } from '../src/auth/identity_verifier.js';
import { createNaverProviderVerifier, createOidcProviderVerifier, createProviderIdentityVerifier } from '../src/auth/provider_identity.js';

const now = new Date('2026-10-02T00:00:00Z');
async function oidcFixture({ issuer, audience, subject = 'provider-user-123', includeTyp = true, lifetimeSeconds = 600 }) {
  const { privateKey, publicKey } = await generateKeyPair('RS256');
  const publicJwk = await exportJWK(publicKey); publicJwk.kid = 'kid-1'; publicJwk.use = 'sig'; publicJwk.alg = 'RS256';
  const token = await new SignJWT({}).setProtectedHeader({ alg: 'RS256', kid: 'kid-1', ...(includeTyp ? { typ: 'JWT' } : {}) })
    .setIssuer(issuer).setAudience(audience).setSubject(subject).setIssuedAt(Math.floor(now.getTime()/1000))
    .setExpirationTime(Math.floor(now.getTime()/1000)+lifetimeSeconds).sign(privateKey);
  return { token, jwks: { keys: [publicJwk] } };
}

test('Apple, Google and Kakao OIDC normalize verified sub only', async () => {
  for (const [provider, issuer] of [['apple','https://appleid.apple.com'], ['google','https://accounts.google.com'], ['kakao','https://kauth.kakao.com']]) {
    const audience = `${provider}-client`; const { token, jwks } = await oidcFixture({ issuer, audience });
    const verify = createOidcProviderVerifier({ provider, issuer, audience, jwks, now: () => now });
    assert.deepEqual(await verify(token), { provider, providerUserId: 'provider-user-123' });
    const wrong = createOidcProviderVerifier({ provider, issuer, audience: 'wrong-client', jwks, now: () => now });
    await assert.rejects(() => wrong(token), /회원 인증/);
  }
});


test('Apple OIDC accepts the standard ID token header without typ', async () => {
  const issuer = 'https://appleid.apple.com';
  const audience = 'com.onaria.app';
  const { token, jwks } = await oidcFixture({ issuer, audience, includeTyp: false });
  const verify = createOidcProviderVerifier({ provider: 'apple', issuer, audience, jwks, now: () => now });
  assert.deepEqual(await verify(token), { provider: 'apple', providerUserId: 'provider-user-123' });
});

test('Apple OIDC accepts Apple-style day-long ID token lifetime', async () => {
  const issuer = 'https://appleid.apple.com';
  const audience = 'com.onaria.app';
  const { token, jwks } = await oidcFixture({ issuer, audience, includeTyp: false, lifetimeSeconds: 86400 });
  const verify = createOidcProviderVerifier({
    provider: 'apple', issuer, audience, jwks, now: () => now, maxTokenAgeSeconds: 86400,
  });
  assert.deepEqual(await verify(token), { provider: 'apple', providerUserId: 'provider-user-123' });
});

test('Kakao OIDC accepts iOS SDK token lifetime of 12 hours', async () => {
  const issuer = 'https://kauth.kakao.com';
  const audience = 'kakao-native-key';
  const { token, jwks } = await oidcFixture({ issuer, audience, lifetimeSeconds: 43200 });
  const verify = createOidcProviderVerifier({
    provider: 'kakao', issuer, audience, jwks, now: () => now, maxTokenAgeSeconds: 43200,
  });
  assert.deepEqual(await verify(token), { provider: 'kakao', providerUserId: 'provider-user-123' });
});

test('Naver verifier calls only fixed profile endpoint and returns response.id', async () => {
  const calls = [];
  const verify = createNaverProviderVerifier({ fetchImpl: async (url, options) => {
    calls.push({ url, options });
    return new Response(JSON.stringify({ resultcode: '00', response: { id: 'naver-user-9', email: 'ignored@example.com' } }),
      { status: 200, headers: { 'content-type': 'application/json' } });
  }});
  assert.deepEqual(await verify('abcdefghijklmnopqrstuvwxyz'), { provider: 'naver', providerUserId: 'naver-user-9' });
  assert.equal(calls.length, 1); assert.equal(calls[0].url, 'https://openapi.naver.com/v1/nid/me');
  assert.equal(calls[0].options.redirect, 'manual'); assert.equal(calls[0].options.headers.Authorization, 'Bearer abcdefghijklmnopqrstuvwxyz');
});

test('Naver rejects malformed/upstream responses and provider router fails closed', async () => {
  for (const response of [new Response('', { status: 401 }), new Response(JSON.stringify({ resultcode: '01' }), { status: 200 }),
    new Response(JSON.stringify({ resultcode: '00', response: { id: '' } }), { status: 200 })]) {
    const verify = createNaverProviderVerifier({ fetchImpl: async () => response });
    await assert.rejects(() => verify('abcdefghijklmnopqrstuvwxyz'), /회원 인증/);
  }
  const router = createProviderIdentityVerifier();
  await assert.rejects(() => router({ provider: 'apple', credential: 'x' }), /확인할 수 없습니다/);
  await assert.rejects(() => router({ provider: 'google', credential: 'x' }), /확인할 수 없습니다/);
  await assert.rejects(() => router({ provider: 'evil', credential: 'x' }), /확인할 수 없습니다/);
});

test('Naver forwards a padded bearer credential unchanged for provider validation', async () => {
  let authorization;
  const verify = createNaverProviderVerifier({ fetchImpl: async (_url, options) => {
    authorization = options.headers.Authorization;
    return new Response(JSON.stringify({ resultcode: '00', response: { id: 'fixture-existing-member' } }), { status: 200 });
  } });
  const credential = 'fixture-bearer-token==';
  assert.deepEqual(await verify(credential), { provider: 'naver', providerUserId: 'fixture-existing-member' });
  assert.equal(authorization, `Bearer ${credential}`);
});

test('Naver rejection diagnostics separate format and upstream 401 without secrets', async () => {
  const events = [];
  let calls = 0;
  const verify = createNaverProviderVerifier({ onFailure: event => events.push(event), fetchImpl: async () => {
    calls++;
    return new Response('private-upstream-body', { status: 401 });
  } });
  await assert.rejects(() => verify('bad\r\nheader'), IdentityError);
  assert.equal(calls, 0);
  await assert.rejects(() => verify('private-fixture-credential'), IdentityError);
  assert.deepEqual(events, [
    { reason: 'credential_format', upstreamStatus: null },
    { reason: 'provider_response', upstreamStatus: 401 },
  ]);
  assert.equal(JSON.stringify(events).includes('private'), false);
});

test('Naver padding is accepted only at the end and header whitespace is rejected', async () => {
  let calls = 0;
  const verify = createNaverProviderVerifier({ fetchImpl: async () => { calls++; throw Error('must not call'); } });
  for (const credential of ['=fixture-invalid-token', 'fixture=invalid-token', 'fixture-invalid-token\n', 'fixture-invalid-token\r\n']) {
    await assert.rejects(() => verify(credential), IdentityError);
  }
  assert.equal(calls, 0);
});

test('runtime provider config enables providers independently and fails closed when absent', async () => {
  const { createRuntimeProviderIdentity } = await import('../src/auth/provider_identity.js');
  const disabled = createRuntimeProviderIdentity({ env: {} });
  await assert.rejects(() => disabled({ provider: 'google', credential: 'x' }), /확인할 수 없습니다/);
  const naver = createRuntimeProviderIdentity({ env: { ONARIA_NAVER_ENABLED: 'true' }, fetchImpl: async () =>
    new Response(JSON.stringify({ resultcode: '00', response: { id: 'naver-runtime' } }), { status: 200 }) });
  assert.deepEqual(await naver({ provider: 'naver', credential: 'abcdefghijklmnopqrstuvwxyz' }),
    { provider: 'naver', providerUserId: 'naver-runtime' });
  await assert.rejects(() => naver({ provider: 'google', credential: 'x' }), /확인할 수 없습니다/);
});
