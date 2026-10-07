import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { readNaverCredentials, syncNaverConfig } from './sync-naver-config.mjs';

test('rejects missing, duplicate and build syntax without exposing input', () => {
  for (const input of [
    'naver.client_id=test',
    'naver.client_id=test\nnaver.client_secret=',
    'naver.client_id=test\nnaver.client_secret=fake\nnaver.client_secret=other',
    'naver.client_id=test\nnaver.client_secret=$(OTHER)',
    'naver.client_id=test\nnaver.client_secret=fake//comment',
    'naver.client_id=test\nnaver.client_secret=test',
  ]) {
    assert.throws(() => readNaverCredentials(input), error => !error.message.includes(input));
  }
});

test('replaces stale iOS pair from canonical file with private permissions', () => {
  const root = mkdtempSync(join(tmpdir(), 'onaria-naver-test-'));
  mkdirSync(join(root, 'android'));
  mkdirSync(join(root, 'ios/Flutter'), { recursive: true });
  writeFileSync(join(root, 'android/naver.properties'), 'naver.client_id=fixture-id\nnaver.client_secret=fixture-secret\n');
  const target = join(root, 'ios/Flutter/NaverKeys.xcconfig');
  writeFileSync(target, 'NAVER_CLIENT_SECRET = stale-fixture');
  syncNaverConfig(root);
  assert.match(readFileSync(target, 'utf8'), /NAVER_CLIENT_ID = fixture-id\nNAVER_CLIENT_SECRET = fixture-secret\n/);
  if (process.platform !== 'win32') assert.equal(statSync(target).mode & 0o777, 0o600);
});
