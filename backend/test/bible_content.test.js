import assert from 'node:assert/strict';
import test from 'node:test';
import { createApp } from '../src/app.js';

function fixtureApp() {
  return createApp({
    generate: async () => ({ message: 'unused' }),
    memberStore: {},
    logger: { error() {} },
  });
}

test('bible content endpoint serves KRV launch data without NIV text', async t => {
  const server = fixtureApp().listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const response = await fetch(base + '/v1/content/bible');
  assert.equal(response.status, 200);
  assert.match(response.headers.get('cache-control') || '', /public/);
  const body = await response.json();
  assert.equal(body.translation, 'KRV');
  assert.ok(Array.isArray(body.verses) && body.verses.length > 0);
  for (const verse of body.verses) {
    assert.equal(verse.translation, 'KRV');
    assert.equal(verse.englishText, '');
  }
  assert.doesNotMatch(JSON.stringify(body), /NIV/);
});
