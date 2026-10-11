import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { createDeletionManifest } from '../src/privacy/deletion_manifest.js';

test('deletion manifest is durable, idempotent and reapplies old member ids only', t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-deletion-manifest-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const file = path.join(root, 'deletion-manifest.sqlite');
  const calls = [];
  const store = { deleteById(id) { calls.push(id); return id === 7; } };

  let manifest = createDeletionManifest({ filename: file, now: () => new Date('2026-10-10T07:30:00.000Z') });
  manifest.record(7);
  manifest.record(7);
  assert.equal(manifest.contains(7), true);
  assert.deepEqual(manifest.entries(), [{ memberId: 7, deletedAt: '2026-10-10T07:30:00.000Z' }]);
  assert.equal(manifest.reapply(store), 1);
  assert.deepEqual(calls, [7]);
  manifest.close();

  manifest = createDeletionManifest({ filename: file });
  assert.equal(manifest.contains(7), true);
  assert.equal(manifest.contains(8), false);
  manifest.close();
  assert.equal(fs.statSync(file).mode & 0o777, 0o600);
});

test('deletion manifest validates ids and cannot silently accept invalid tombstones', t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-deletion-manifest-invalid-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const manifest = createDeletionManifest({ filename: path.join(root, 'manifest.sqlite') });
  t.after(() => manifest.close());

  for (const value of [0, -1, 1.2, Number.NaN, '1', null]) {
    assert.throws(() => manifest.record(value), TypeError);
  }
  assert.throws(() => manifest.reapply(null), TypeError);
});
