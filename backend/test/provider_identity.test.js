import assert from 'node:assert/strict';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';
import { test } from 'node:test';
import { createNaverProviderVerifier, createOidcProviderVerifier, createProviderIdentityVerifier } from '../src/auth/provider_identity.js';

const now = new Date('2026-10-02T00:00:00Z');
async function oidcFixture({ issuer, audience, subject = 'provider-user-123', nonce }) {
  const { privateKey, publicKey } = await generateKeyPair('RS256');
  const publicJwk = await exportJWK(publicKey); publicJwk.kid = 'kid-1'; publicJwk.use = 'sig'; publicJwk.alg = 'RS256';
  const token = await new SignJWT(nonce ? { nonce } : {}).setProtectedHeader({ alg: 'RS256', typ: 'JWT', kid: 'kid-1' })
    .setIssuer(issuer).setAudience(audience).setSubject(subject).setIssuedAt(Math.floor(now.getTime()/1000))
    .setExpirationTime(Math.floor(now.getTime()/1000)+600).sign(privateKey);
  return { token, jwks: { keys: [publicJwk] } };
}

test('Google and Kakao OIDC normalize verified sub only', async () => {
  for (const [provider, issuer] of [['google','https://accounts.google.com'], ['kakao','https://kauth.kakao.com']]) {
    const audience = `${provider}-client`; const nonce = provider === 'kakao' ? '0123456789abcdef0123456789abcdef' : undefined; const { token, jwks } = await oidcFixture({ issuer, audience, nonce });
    const verify = createOidcProviderVerifier({ provider, issuer, audience, jwks, now: () => now });
    assert.deepEqual(await verify(token, { nonce }), { provider, providerUserId: 'provider-user-123' });
    const wrong = createOidcProviderVerifier({ provider, issuer, audience: 'wrong-client', jwks, now: () => now });
    await assert.rejects(() => wrong(token), /회원 인증/);
  }
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
  await assert.rejects(() => router({ provider: 'google', credential: 'x' }), /확인할 수 없습니다/);
  await assert.rejects(() => router({ provider: 'evil', credential: 'x' }), /확인할 수 없습니다/);
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

test('Kakao OIDC rejects missing or mismatched nonce', async () => {
  const issuer='https://kauth.kakao.com', audience='kakao-client', nonce='0123456789abcdef0123456789abcdef';
  const { token, jwks } = await oidcFixture({ issuer, audience, nonce });
  const verify=createOidcProviderVerifier({ provider:'kakao', issuer, audience, jwks, now:()=>now });
  await assert.rejects(() => verify(token), /회원 인증/);
  await assert.rejects(() => verify(token, { nonce:'fedcba9876543210fedcba9876543210' }), /회원 인증/);
});
