import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { prepareLocalReleaseConfig } from './prepare-local-release-config.mjs';

test('trusted checkout uses original signing key and local pair without changing source', () => {
  const root = mkdtempSync(join(tmpdir(), 'onaria-release-config-'));
  const source = join(root, 'source');
  const target = join(root, 'target');
  for (const dir of [source, target]) {
    mkdirSync(join(dir, 'android'), { recursive: true });
    mkdirSync(join(dir, 'ios/Flutter'), { recursive: true });
    writeFileSync(join(dir, 'pubspec.yaml'), 'name: onaria\n');
  }
  const signing = 'keyAlias=onaria-upload\nstoreFile=fixture.jks\nkeyPassword=fixture-only\nstorePassword=fixture-only\n';
  writeFileSync(join(source, 'android/key.properties'), signing);
  writeFileSync(join(source, 'android/fixture.jks'), 'fixture-only');
  writeFileSync(join(source, 'android/naver.properties'), 'naver.client_id=fixture-id\nnaver.client_secret=fixture-secret\n');
  prepareLocalReleaseConfig(source, target);
  assert.equal(readFileSync(join(source, 'android/key.properties'), 'utf8'), signing);
  assert.ok(readFileSync(join(target, 'android/key.properties'), 'utf8').includes(`storeFile=${join(source, 'android/fixture.jks')}`));
  assert.ok(readFileSync(join(target, 'ios/Flutter/NaverKeys.xcconfig'), 'utf8').includes('NAVER_CLIENT_SECRET = fixture-secret'));
  if (process.platform !== 'win32') assert.equal(statSync(join(target, 'android/key.properties')).mode & 0o777, 0o600);
  assert.throws(() => prepareLocalReleaseConfig(source, source), /Distinct ONARIA/);
  writeFileSync(join(target, 'pubspec.yaml'), 'name: another_app\n');
  assert.throws(() => prepareLocalReleaseConfig(source, target), /Distinct ONARIA/);
});
