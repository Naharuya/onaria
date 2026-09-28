import assert from 'node:assert/strict';
import { test } from 'node:test';
import { startBuddhistDevServer } from '../dev/religion-packs/server.js';

test('Development Admin: per-session aggregate diagnostics, no text/identity, no mutations or cross-pack access', async t => {
  const { server, url } = await startBuddhistDevServer({ log() {} });
  t.after(() => new Promise(resolve => server.close(resolve)));
  const path = `${url}/api/admin/diagnostics`;
  assert.equal((await fetch(path)).status, 401);
  const cookie = async () => (await fetch(url)).headers.get('set-cookie').split(';')[0];
  const a = await cookie(), b = await cookie();
  const headers = { cookie: a, Origin: url, 'Content-Type': 'application/json' };
  const privateText = '불안한 비밀 이야기 SAMPLE_PRIVATE_921';
  await fetch(`${url}/api/respond`, { method: 'POST', headers, body: JSON.stringify({ userMessage: privateText }) });
  const response = await fetch(path, { headers });
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const diagnostics = await response.json();
  assert.deepEqual(diagnostics.counts, { respond: 1, search: 0, cards: 0 });
  assert.equal(JSON.stringify(diagnostics).includes(privateText), false);
  assert.deepEqual(diagnostics.controls, { import: false, approveExternal: false, publish: false, resetData: false });
  assert.equal((await (await fetch(path, { headers: { cookie: b } })).json()).counts.respond, 0);
  assert.equal((await fetch(`${path}?religion=christian`, { headers })).status, 400);
  assert.equal((await fetch(`${url}/api/admin?religion=christian`, { headers })).status, 400);
  assert.equal((await fetch(path, { headers: { ...headers, Origin: 'https://invalid.example' } })).status, 403);
  assert.equal((await fetch(path, { method: 'POST', headers: { cookie: a, 'Content-Type': 'application/json' }, body: '{}' })).status, 403);
  for (const method of ['POST', 'PUT', 'PATCH', 'DELETE']) {
    assert.equal((await fetch(path, { method, headers, body: '{}' })).status, 404);
  }
});

test('Source review is session-protected metadata and cannot become a scripture search/card result', async t => {
  const { server, url } = await startBuddhistDevServer({ log() {} });
  t.after(() => new Promise(resolve => server.close(resolve)));
  const path = `${url}/api/admin/source-review`;
  assert.equal((await fetch(path)).status, 401);
  const cookie = (await fetch(url)).headers.get('set-cookie').split(';')[0];
  const headers = { cookie, Origin:url, 'Content-Type':'application/json' };
  const response = await fetch(path, { headers });
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const catalog = await response.json();
  assert.equal(catalog.mode,'SOURCE_REVIEW_ONLY');
  assert.equal(catalog.candidates.length,4);
  for (const row of catalog.candidates) {
    assert.equal(row.copyright_status,'BLOCKED_EXTERNAL_REVIEW');
    assert.equal(row.ingest_allowed,false);
    for(const field of ['text','scriptureId','translator','chapter','section']) assert.equal(field in row,false);
    const search = await (await fetch(`${url}/api/search?q=${encodeURIComponent(row.name)}`,{headers})).json();
    assert.deepEqual(search.results,[]);
    assert.equal((await fetch(`${url}/api/cards`,{method:'POST',headers,body:JSON.stringify({scriptureId:row.id})})).status,404);
  }
  assert.equal((await fetch(`${path}?religion=christian`,{headers})).status,400);
  assert.equal((await fetch(path,{method:'POST',headers,body:'{}'})).status,404);
  assert.equal((await fetch(path,{headers:{...headers,Origin:'https://invalid.example'}})).status,403);
});
