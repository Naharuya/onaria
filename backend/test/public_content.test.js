import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { createApp } from '../src/app.js';

test('public content is cacheable, supports 304 and never invokes AI', async t => {
  let calls = 0;
  const app = createApp({ generate: async () => { calls++; throw Error(); }, memberStore: {} });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = 'http://127.0.0.1:' + server.address().port;
  const response = await fetch(base + '/v1/content/verses');
  assert.equal(response.status, 200);
  assert.match(response.headers.get('cache-control'), /^public,/);
  const expected = JSON.parse(readFileSync(new URL('../../assets/data/bible_verses_ko.json', import.meta.url)));
  const {_release,...catalog}=await response.json();assert.deepEqual(catalog,expected);assert.equal(_release.project,'onaria');assert.equal(_release.entries.length,expected.verses.length);
  const cached = await fetch(base + '/v1/content/verses', {
    headers: { 'If-None-Match': response.headers.get('etag'), 'Cache-Control': 'max-age=0' }
  });
  assert.equal(cached.status, 304);
  assert.equal(await cached.text(), '');
  const privateResponse = await fetch(base + '/v1/account');
  assert.equal(privateResponse.headers.get('cache-control'), 'no-store');
  assert.equal(calls, 0);
});
