import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { updateRelease, releaseCert, productionApi, packageId, execute } from './android-release.mjs';

function fixture(overrides = {}) {
  const root = mkdtempSync(join(tmpdir(), 'onaria-install-test-'));
  mkdirSync(join(root, 'android'));
  const appPath = overrides.profile === 'buddhist' ? 'apps/buddhist/' : '';
  mkdirSync(join(root, appPath, 'build/app/outputs/flutter-apk'), { recursive: true });
  for (const file of ['android/key.properties', 'android/soul-bible-release.jks', `${appPath}build/app/outputs/flutter-apk/app-release.apk`]) writeFileSync(join(root, file), 'synthetic test fixture');
  if (overrides.profile === 'buddhist') {
    mkdirSync(join(root, appPath, 'android'), { recursive: true });
    for (const file of ['key.properties', 'buddhist-release.jks']) writeFileSync(join(root, appPath, 'android', file), 'synthetic fixture');
    writeFileSync(join(root, appPath, 'android/release-certificate.sha256'), overrides.pin ?? 'c'.repeat(64));
  }
  const calls = [];
  const options = { root, profile: overrides.profile, tools: { adb: 'adb', flutter: 'flutter', signer: 'signer', aapt: 'aapt' }, report: () => {},
    run(tool, args) {
      calls.push([tool, ...args]);
      if (tool === 'adb' && args[0] === 'devices') return overrides.devices ?? 'List of devices attached\nfixture-device device\n';
      if (tool === 'adb' && args.includes('packages')) return overrides.path === '' ? '' : 'package:com.onaria.buddhist\n';
      if (tool === 'signer') return `Signer #1 certificate SHA-256 digest: ${overrides[args.at(-1).endsWith('installed.apk') ? 'installedCert' : 'apkCert'] ?? (overrides.profile === 'buddhist' ? 'c'.repeat(64) : releaseCert)}\n`;
      if (tool === 'aapt' && args.includes('resources')) return 'resource 0x7f100000 com.onaria.buddhist:xml/mac_ai_network: t=0x03\n  (string8) "res/7q.xml"';
      if (tool === 'aapt' && args.includes('xmltree')) return overrides.policy ?? 'E: network-security-config\nE: base-config\nA: cleartextTrafficPermitted=(type 0x12)0x0\nE: domain-config\nA: cleartextTrafficPermitted=(type 0x12)0xffffffff\nE: domain\nA: includeSubdomains=(type 0x12)0x0\nC: "127.0.0.1"';
      if (tool === 'adb' && args.includes('reverse') && args.includes('--list')) return overrides.mappings ?? '';
      if (tool === 'aapt' && args[0] === 'list') return overrides.entries ?? 'assets/flutter_assets/packages/onaria_buddhist_pack/assets/mock_scriptures.json';
      if (tool === 'aapt') return overrides.badging ?? `package: name='${overrides.profile === 'buddhist' ? 'com.onaria.buddhist' : packageId}' versionCode='7' versionName='0.4.2'\n`;
      if (tool === 'adb' && args.includes('path')) return overrides.path ?? 'package:/data/app/fixture/base.apk\n';
      if (tool === 'adb' && args.includes('dumpsys')) return `versionCode=${overrides.version ?? 7}\n`;
      if (tool === 'adb' && args.includes('install')) {
        if (overrides.throwInstall) throw Error('INSTALL_FAILED_UPDATE_INCOMPATIBLE');
        return overrides.install ?? 'Success\n';
      }
      if (tool === 'adb' && args.includes('start')) return 'Status: ok\n';
      return '';
    } };
  return { options, calls };
}
function noDeletion(calls) {
  assert.ok(calls.every(args => !args.some(a => ['uninstall', 'clear', '-d'].includes(a))));
  assert.ok(calls.filter(args => args[0] === 'flutter').every(args => !['run', 'install'].includes(args[1])));
}
test('release update verifies both certificates, package and version before one preserving install', () => {
  const { options, calls } = fixture();
  const result = updateRelease(options);
  assert.equal(result.api, productionApi);
  assert.deepEqual(calls.filter(c => c[0] === 'flutter'), [
    ['flutter', 'pub', 'get'], ['flutter', 'build', 'apk', '--release', `--dart-define=ONARIA_API_BASE_URL=${productionApi}`]]);
  const install = calls.find(c => c.includes('install'));
  assert.deepEqual(install.slice(0, 5), ['adb', '-s', 'fixture-device', 'install', '-r']);
  assert.equal(calls.filter(c => c.includes('install')).length, 1);
  assert.ok(calls.findIndex(c => c[0] === 'aapt') < calls.indexOf(install));
  noDeletion(calls);
});
for (const [name, override] of [
  ['unauthorized', { devices: 'fixture-device unauthorized' }],
  ['offline', { devices: 'fixture-device offline' }],
  ['no device', { devices: '' }],
  ['multiple devices', { devices: 'one device\ntwo device' }],
  ['old signer mismatch', { installedCert: 'a'.repeat(64) }],
  ['new signer mismatch', { apkCert: 'b'.repeat(64) }],
  ['unknown installed APK', { path: 'Unexpected error' }],
  ['downgrade', { version: 8 }],
  ['wrong package', { badging: "package: name='wrong.app' versionCode='7' versionName='test'" }],
  ['debug APK', { badging: `package: name='${packageId}' versionCode='7' versionName='test'\napplication-debuggable` }],
]) test(`${name} blocks installation`, () => {
  const { options, calls } = fixture(override);
  assert.throws(() => updateRelease(options));
  assert.equal(calls.filter(c => c.includes('install')).length, 0);
  noDeletion(calls);
});
for (const override of [{ install: 'Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]' }, { throwInstall: true }]) test('install failure never deletes or retries', () => {
  const { options, calls } = fixture(override);
  assert.throws(() => updateRelease(options));
  assert.equal(calls.filter(c => c.includes('install')).length, 1);
  assert.ok(!calls.some(c => c.includes('start')));
  noDeletion(calls);
});
test('wireless wrapper delegates to the safe release installer', () => {
  const script = readFileSync(new URL('../script/test-wireless.ps1', import.meta.url), 'utf8');
  assert.match(script, /install-onaria-release\.ps1/);
  assert.doesNotMatch(script, /@\('run'|adb\s+uninstall|pm\s+clear/);
});
test('Windows BAT paths and arguments with spaces are passed safely', { skip: process.platform !== 'win32' }, () => {
  const root = mkdtempSync(join(tmpdir(), 'onaria-command-test-'));
  const file = join(root, 'test tool.cmd');
  writeFileSync(file, '@echo off\r\necho %~1\r\n');
  assert.equal(execute(file, ['argument with spaces'], root).trim(), 'argument with spaces');
  assert.throws(() => execute(file, ['invalid&argument'], root));
  writeFileSync(file, '@echo off\r\necho synthetic-sensitive-output 1>&2\r\nexit /b 7\r\n');
  assert.throws(() => execute(file, [], root), error => !error.message.includes('synthetic-sensitive-output'));
});

test('Buddhist release updates only its isolated package with offline fixture assets', () => {
  const { options, calls } = fixture({ profile: 'buddhist', path: '' });
  const result = updateRelease(options);
  assert.equal(result.packageId, 'com.onaria.buddhist');
  assert.equal(result.api, null);
  assert.equal(result.certificate, 'c'.repeat(64));
  assert.ok(!calls.flat().some(value => value.includes('ONARIA_API_BASE_URL')));
  assert.ok(!calls.flat().includes(packageId));
  assert.ok(!calls.some(c => c.includes('path')));
  assert.ok(calls.some(c => c[0] === 'aapt' && c[1] === 'list'));
  noDeletion(calls);
});
for (const override of [
  { pin: 'invalid' },
  { installedCert: releaseCert },
  { apkCert: releaseCert },
  { entries: 'assets/flutter_assets/assets/data/bible_verses_ko.json' },
  { badging: "package: name='com.onaria.buddhist' versionCode='7' versionName='test'\nuses-permission: name='android.permission.INTERNET'" },
  { badging: "package: name='com.onaria.app' versionCode='7' versionName='test'" },
]) test('Buddhist isolation violations prevent installation', () => {
  const { options, calls } = fixture({ profile: 'buddhist', ...override });
  assert.throws(() => updateRelease(options));
  assert.equal(calls.filter(c => c.includes('install')).length, 0);
});

function pairingFile() {
 const file=join(mkdtempSync(join(tmpdir(),'buddhist-pair-test-')),'pairing.json');
 writeFileSync(file,JSON.stringify({BUDDHIST_MAC_AI_PORT:54321,BUDDHIST_MAC_AI_TOKEN:'a'.repeat(64)}));return file;
}
test('USB AI release explicitly pairs loopback and retains certificate/update validation',()=>{
 const {options,calls}=fixture({profile:'buddhist',badging:"package: name='com.onaria.buddhist' versionCode='7' versionName='test'\nuses-permission: name='android.permission.INTERNET'"});
 options.macAiConfig=pairingFile();updateRelease(options);
 assert.ok(calls.some(c=>c.includes('--dart-define-from-file='+options.macAiConfig)));
 assert.ok(calls.some(c=>c.includes('--no-rebind')&&c.includes('tcp:54321')));
 assert.equal(calls.filter(c=>c.includes('install')).length,1);noDeletion(calls);
});
test('USB permission mismatch and conflicting reverse mapping stop before installation',()=>{
 for(const override of [{}, {badging:"package: name='com.onaria.buddhist' versionCode='7' versionName='test'\nuses-permission: name='android.permission.INTERNET'",mappings:'device tcp:54321 tcp:11111'}]) {
  const {options,calls}=fixture({profile:'buddhist',...override});options.macAiConfig=pairingFile();
  assert.throws(()=>updateRelease(options));assert.ok(!calls.some(c=>c.includes('install')));
 }
});
test('Christian installer refuses a Buddhist pairing configuration',()=>{
 const {options,calls}=fixture();options.macAiConfig=pairingFile();assert.throws(()=>updateRelease(options));assert.equal(calls.length,0);
});

test('USB cleartext policy cannot be broadened',()=>{
 const {options,calls}=fixture({profile:'buddhist',badging:"package: name='com.onaria.buddhist' versionCode='7' versionName='test'\nuses-permission: name='android.permission.INTERNET'",policy:'E: base-config\nA: cleartextTrafficPermitted=(type 0x12)0xffffffff'});
 options.macAiConfig=pairingFile();assert.throws(()=>updateRelease(options));assert.ok(!calls.some(c=>c.includes('install')));
});
