import assert from 'node:assert/strict';
import { test } from 'node:test';
import { get } from 'node:http';
import { startBuddhistDevServer } from '../dev/religion-packs/server.js';

test('Buddhist HTTP: local binding, auth, CSRF, provider-only cards, Admin, sticky Safety and isolation', async (t) => {
  const { server, url } = await startBuddhistDevServer({ log() {} });
  t.after(() => new Promise((resolve) => server.close(resolve)));
  assert.equal(server.address().address, '127.0.0.1');
  assert.equal((await fetch(`${url}/api/admin`)).status, 401);
  // Node fetch normalizes Host; use the actual HTTP boundary for rebinding tests.
  const forgedHostStatus = await new Promise((resolve, reject) => {
    get(url, { headers: { Host: 'attacker.invalid' } }, (response) => {
      response.resume(); resolve(response.statusCode);
    }).on('error', reject);
  });
  assert.equal(forgedHostStatus, 403);
  assert.equal((await fetch(url, { headers: { 'Sec-Fetch-Site': 'cross-site' } })).status, 403);
  const page = await fetch(url);
  const cookie = page.headers.get('set-cookie').split(';')[0];
  assert.match(page.headers.get('set-cookie'), /HttpOnly/);
  assert.match(page.headers.get('set-cookie'), /SameSite=Strict/);
  assert.equal(page.headers.get('cache-control'), 'no-store');
  const headers = { cookie, Origin: url, 'Content-Type': 'application/json' };
  const post = (path, body, extraHeaders = {}) => fetch(`${url}${path}`, { method: 'POST', headers: { ...headers, ...extraHeaders }, body: JSON.stringify(body) });
  assert.equal((await post('/api/respond', { userMessage: '불안' }, { Origin: 'https://attacker.invalid' })).status, 403);
  assert.equal((await fetch(`${url}/api/cards`, { method: 'POST', headers: { cookie, 'Content-Type': 'application/json' }, body: '{}' })).status, 403);
  assert.equal((await post('/api/respond', { userMessage: '불안', religion: 'christian' })).status, 400);
  assert.equal((await post('/api/respond', { userMessage: 1 })).status, 400);
  assert.equal((await post('/api/respond', { userMessage: '불안', session: { riskLevel: 0 } })).status, 400);
  const result = await (await post('/api/respond', { userMessage: '불안' })).json();
  assert.equal(result.citations.length, 1);
  const card = await (await post('/api/cards', { scriptureId: result.citations[0].id })).json();
  assert.deepEqual(card.scripture, result.citations[0]);
  assert.equal((await post('/api/cards', { scriptureId: result.citations[0].id, text: 'forged' })).status, 400);
  assert.equal((await post('/api/cards', { scriptureId: 'external-intake-disabled' })).status, 404);
  assert.equal((await post('/api/admin', { copyright_status: 'APPROVED' })).status, 404);
  const admin = await (await fetch(`${url}/api/admin`, { headers })).json();
  assert.equal(admin.externalReview.copyright_status, 'BLOCKED_EXTERNAL_REVIEW');
  assert.equal(admin.importEnabled, false);
  assert.equal(admin.modelCalls, 0);
  assert.equal(admin.openAiClientCreations, 0);
  const noHits = await (await fetch(`${url}/api/search?q=unknown`, { headers })).json();
  assert.deepEqual(noHits.results, []);
  const crisis = await (await post('/api/respond', { userMessage: '죽고 싶어요', religion: 'christian' })).json();
  assert.equal(crisis.stage, 'crisis');
  assert.equal(crisis.shouldOfferVerse, false);
  assert.equal((await post('/api/cards', { scriptureId: result.citations[0].id })).status, 409);
  assert.equal((await fetch(`${url}/api/search?q=불안`, { headers })).status, 409);
  assert.equal((await (await post('/api/respond', { userMessage: '괜찮아요' })).json()).stage, 'crisis');
  // An independent sandbox browser session never inherits another session's state.
  const other = await fetch(url);
  const otherCookie = other.headers.get('set-cookie').split(';')[0];
  assert.equal((await (await post('/api/respond', { userMessage: '불안' }, { cookie: otherCookie })).json()).stage, 'reflection');
});
