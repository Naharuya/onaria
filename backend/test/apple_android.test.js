import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createAppleAndroidAuth, createRuntimeAppleAndroidAuth, withAppleAndroidProofs } from '../src/auth/apple_android.js';

function fixture(verifyOverride) {
  let time = 1000; let sequence = 1; const calls = [];
  const auth = createAppleAndroidAuth({ serviceId: 'com.onaria.web',
    redirectUri: 'https://api.onaria.ai.kr/v1/auth/apple/android/callback',
    now: () => time, random: () => String(sequence++).padStart(43, 'a'),
    verify: verifyOverride || (async (token, nonce) => {
      calls.push({ token, nonce });
      return { provider: 'apple', providerUserId: 'verified-sub' };
    }),
  });
  return { auth, calls, advance: n => { time += n; } };
}

test('callback verifies request nonce, emits only opaque proof and preserves native verifier', async () => {
  const { auth, calls } = fixture(); const challenge = auth.challenge();
  const location = await auth.callback({ state: challenge.state, id_token: 'synthetic-private-jwt', code: 'private-code' });
  assert.deepEqual(calls, [{ token: 'synthetic-private-jwt', nonce: challenge.nonce }]);
  assert.ok(!location.includes('synthetic-private-jwt') && !location.includes('private-code'));
  assert.match(location, /#Intent;package=com.onaria.app;scheme=signinwithapple;end$/);
  const proof = new URLSearchParams(location.split('?')[1].split('#')[0]).get('id_token');
  const wrapped = withAppleAndroidProofs(async input => ({ native: input.credential }), auth);
  assert.deepEqual(await wrapped({ provider: 'apple', credential: proof }), { provider: 'apple', providerUserId: 'verified-sub' });
  assert.deepEqual(await wrapped({ provider: 'apple', credential: 'native-jwt' }), { native: 'native-jwt' });
  await assert.rejects(() => auth.callback({ state: challenge.state, id_token: 'again', code: 'again' }));
});

test('unknown and expired state never invokes identity verification', async () => {
  const { auth, calls, advance } = fixture(); const challenge = auth.challenge();
  await assert.rejects(() => auth.callback({ state: 'b'.repeat(43), id_token: 'x', code: 'y' }));
  advance(300000);
  await assert.rejects(() => auth.callback({ state: challenge.state, id_token: 'x', code: 'y' }));
  assert.equal(calls.length, 0);
});

test('expired or invented proof cannot authenticate', async () => {
  const { auth, advance } = fixture(); const challenge = auth.challenge();
  const location = await auth.callback({ state: challenge.state, id_token: 'x', code: 'y' });
  const proof = new URLSearchParams(location.split('?')[1].split('#')[0]).get('id_token');
  assert.throws(() => auth.resolve('apple_android.' + 'b'.repeat(43)));
  advance(300000); assert.throws(() => auth.resolve(proof));
});

test('rejected identity and cancellation cannot create a proof', async () => {
  const rejected = fixture(async () => { throw Error('synthetic rejection'); });
  const challenge = rejected.auth.challenge();
  await assert.rejects(() => rejected.auth.callback({ state: challenge.state, id_token: 'x', code: 'y' }));
  const { auth, calls } = fixture(); const cancelled = auth.challenge();
  const location = await auth.callback({ state: cancelled.state, error: 'access_denied' });
  assert.match(location, /error=access_denied/); assert.ok(!location.includes('id_token'));
  assert.equal(calls.length, 0);
});

test('missing Service ID and unsafe callback configuration fail closed', () => {
  assert.throws(() => createRuntimeAppleAndroidAuth({ env: {} }).challenge());
  for (const redirectUri of ['http://api.onaria.ai.kr/v1/auth/apple/android/callback',
    'https://user:pass@api.onaria.ai.kr/v1/auth/apple/android/callback',
    'https://api.onaria.ai.kr/other', 'https://api.onaria.ai.kr/v1/auth/apple/android/callback?next=evil']) {
    assert.throws(() => createAppleAndroidAuth({ serviceId: 'com.onaria.web', redirectUri, verify: async () => ({}) }).challenge());
  }
});

test('form callback router does not create ONARIA cookies or reveal Apple credentials', async () => {
  const { default: express } = await import('express'); const app = express(); const { auth } = fixture();
  app.use(auth.router()); app.use((error, _req, res, _next) => res.status(error.status || 500).send('rejected'));
  const server = app.listen(0, '127.0.0.1'); await new Promise(resolve => server.once('listening', resolve));
  try {
    const challenge = auth.challenge();
    const response = await fetch(`http://127.0.0.1:${server.address().port}/callback`, { method: 'POST', redirect: 'manual',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ state: challenge.state, id_token: 'private-jwt', code: 'private-code' }) });
    assert.equal(response.status, 303); assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.equal(response.headers.get('set-cookie'), null);
    assert.ok(!response.headers.get('location').includes('private-jwt'));
    await response.text();
  } finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
});

test('runtime callback verifies signed Apple Service ID audience and nonce with a stub JWKS', async () => {
  const { generateKeyPair, exportJWK, SignJWT } = await import('jose');
  const { privateKey, publicKey } = await generateKeyPair('RS256');
  const key = await exportJWK(publicKey); key.kid = 'synthetic-key'; key.alg = 'RS256'; key.use = 'sig';
  let fetches = 0;
  const make = () => createRuntimeAppleAndroidAuth({ env: { ONARIA_APPLE_SERVICE_ID: 'com.onaria.web' },
    fetchImpl: async url => {
      assert.equal(url, 'https://appleid.apple.com/auth/keys'); fetches++;
      return new Response(JSON.stringify({ keys: [key] }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    } });
  const token = nonce => new SignJWT({ nonce }).setProtectedHeader({ alg: 'RS256', kid: 'synthetic-key' })
    .setIssuer('https://appleid.apple.com').setAudience('com.onaria.web').setSubject('verified-apple-user')
    .setIssuedAt().setExpirationTime('10m').sign(privateKey);
  const auth = make(); const challenge = auth.challenge();
  const location = await auth.callback({ state: challenge.state, id_token: await token(challenge.nonce), code: 'synthetic-code' });
  const proof = new URLSearchParams(location.split('?')[1].split('#')[0]).get('id_token');
  assert.deepEqual(auth.resolve(proof), { provider: 'apple', providerUserId: 'verified-apple-user' });
  const bad = make(); const badChallenge = bad.challenge();
  await assert.rejects(() => token('wrong-nonce').then(id_token => bad.callback({ state: badChallenge.state, id_token, code: 'synthetic-code' })));
  assert.equal(fetches, 2);
});

test('revocation grant stays server-local and is consumed once within proof TTL', async () => {
  const { auth } = fixture();
  const challenge = auth.challenge();
  const location = await auth.callback({ state: challenge.state, id_token: 'server-local-token', code: 'server-local-code' });
  const proof = new URLSearchParams(location.split('?')[1].split('#')[0]).get('id_token');
  assert.ok(!location.includes('server-local-token') && !location.includes('server-local-code'));
  assert.deepEqual(auth.consumeGrant(proof), { authorizationCode: 'server-local-code', credential: 'server-local-token' });
  assert.throws(() => auth.consumeGrant(proof));
  assert.throws(() => auth.resolve(proof));
});
