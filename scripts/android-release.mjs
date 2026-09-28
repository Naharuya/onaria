// Data-preserving Android updates. Never delegates installation to flutter run.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname, delimiter } from 'node:path';
import { fileURLToPath } from 'node:url';

export const packageId = 'com.onaria.app';
export const productionApi = 'https://api.onaria.ai.kr';
export const releaseCert = '692eabafe55986612f5aa3d475cea16e0e5e7db20ce2e09219a2f536f7e8f6bb';

export function execute(file, args, cwd) {
  try {
    if (process.platform === 'win32' && /\.(bat|cmd)$/i.test(file)) {
      const quote = value => {
        if (/["%\r\n!&|<>^]/.test(value)) throw Error('Unsupported command path');
        return `"${value}"`;
      };
      return execFileSync('cmd.exe', ['/d', '/s', '/c', `"${[file, ...args].map(quote).join(' ')}"`],
        { cwd, windowsVerbatimArguments: true, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 16 * 1024 * 1024 });
    }
    return execFileSync(file, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 16 * 1024 * 1024 });
  } catch (error) {
    const code = `${error.stdout || ''} ${error.stderr || ''}`.match(/INSTALL_FAILED_[A-Z_]+/)?.[0];
    // Do not echo build output: local tool errors can contain signing settings.
    throw Error(code || `Tool failed (${error.status ?? 'launch'}); update stopped without deleting data`);
  }
}

export function certificate(output) {
  const fingerprints = [...output.matchAll(/^Signer #\d+ certificate SHA-256 digest:\s*([a-f0-9]{64})\s*$/gim)].map(m => m[1].toLowerCase());
  if (fingerprints.length !== 1) throw Error('Expected exactly one APK signing certificate');
  return fingerprints[0];
}

export function updateRelease({ root, tools, device, profile = 'christian', macAiConfig, run = execute, report = console.log }) {
  if (!['christian', 'buddhist'].includes(profile)) throw Error('Unknown release profile');
  let pairing;
  if (macAiConfig) {
    if (profile !== 'buddhist' || resolve(macAiConfig).startsWith(resolve(root) + '/')) throw Error('USB pairing must be external to the repository and Buddhist-only');
    pairing = JSON.parse(readFileSync(macAiConfig, 'utf8'));
    if (Object.keys(pairing).length !== 2 || !Number.isInteger(pairing.BUDDHIST_MAC_AI_PORT)
        || pairing.BUDDHIST_MAC_AI_PORT < 1024 || pairing.BUDDHIST_MAC_AI_PORT > 65535
        || !/^[a-f0-9]{64}$/.test(pairing.BUDDHIST_MAC_AI_TOKEN || '')) throw Error('Invalid USB pairing');
  }
  const targetPackage = profile === 'buddhist' ? 'com.onaria.buddhist' : packageId;
  const appRoot = profile === 'buddhist' ? join(root, 'apps/buddhist') : root;
  const pinFile = join(appRoot, 'android/release-certificate.sha256');
  const expectedCert = profile === 'buddhist'
    ? (existsSync(pinFile) ? readFileSync(pinFile, 'utf8').trim() : '') : releaseCert;
  if (!/^[a-f0-9]{64}$/.test(expectedCert)) throw Error('Valid Buddhist release certificate pin required');
  const call = (tool, args) => run(tools[tool], args, root);
  const listing = call('adb', ['devices']);
  const devices = listing.split(/\r?\n/).map(line => line.trim().split(/\s+/))
    .filter(([serial, state]) => serial && ['device', 'unauthorized', 'offline'].includes(state));
  if (!device) {
    if (devices.length !== 1) throw Error('Connect one Android device or specify -Device SERIAL');
    device = devices[0][0];
  }
  const state = devices.find(([serial]) => serial === device)?.[1];
  if (state === 'unauthorized') throw Error('Allow USB debugging on the phone, then retry');
  if (state !== 'device') throw Error('Selected device is not connected and authorized');
  const adb = args => call('adb', ['-s', device, ...args]);
  // Android exits 1 for `pm path` on a new package. Determine absence explicitly
  // rather than treating transport errors as evidence that no app is installed.
  let packagePresent = true;
  if (profile === 'buddhist') {
    const packages = adb(['shell', 'pm', 'list', 'packages', targetPackage]).trim();
    if (packages && packages.split(/\r?\n/).some(line => !/^package:[a-zA-Z0-9_.]+$/.test(line))) throw Error('Installed package query failed');
    packagePresent = packages.split(/\r?\n/).includes(`package:${targetPackage}`);
  }
  const installed = packagePresent ? adb(['shell', 'pm', 'path', targetPackage]) : '';
  const base = installed.split(/\r?\n/).find(line => /^package:\/[^\r\n]*\/base\.apk$/.test(line));
  let previousVersion = null;
  if (installed.trim() && !base) throw Error('Could not identify installed base APK; stopped');
  if (base) {
    const snapshot = join(mkdtempSync(join(tmpdir(), 'onaria-cert-')), 'installed.apk');
    // Copies APK code only, never app data. No recursive cleanup operation.
    adb(['pull', base.slice('package:'.length), snapshot]);
    if (certificate(call('signer', ['verify', '--print-certs', snapshot])) !== expectedCert) {
      throw Error('Installed certificate differs from the approved release key; stopped');
    }
    const details = adb(['shell', 'dumpsys', 'package', targetPackage]);
    previousVersion = details.match(/\bversionCode=(\d+)/)?.[1];
    if (!previousVersion) throw Error('Installed versionCode unavailable; stopped');
  }
  const keyName = profile === 'buddhist' ? 'buddhist-release.jks' : 'soul-bible-release.jks';
  if (!existsSync(join(appRoot, 'android/key.properties')) || !existsSync(join(appRoot, 'android', keyName))) {
    throw Error('Existing release keystore/key.properties required; no key will be generated');
  }
  report(profile === 'buddhist' ? (pairing ? 'Building Buddhist USB Mac AI development release; scripture remains TEST_DATA_ONLY.' : 'Building isolated offline Buddhist TEST_DATA_ONLY release.') : 'Building release with the official API; signing secrets are not printed.');
  run(tools.flutter, ['pub', 'get'], appRoot);
  run(tools.flutter, ['build', 'apk', '--release', ...(profile === 'christian' ? [`--dart-define=ONARIA_API_BASE_URL=${productionApi}`] : pairing ? [`--dart-define-from-file=${resolve(macAiConfig)}`] : [])], appRoot);
  const apk = join(appRoot, 'build/app/outputs/flutter-apk/app-release.apk');
  if (!existsSync(apk)) throw Error('Release APK missing');
  if (certificate(call('signer', ['verify', '--print-certs', apk])) !== expectedCert) throw Error('Built APK certificate mismatch; stopped');
  const badging = call('aapt', ['dump', 'badging', apk]);
  const metadata = badging.match(/^package: name='([^']+)' versionCode='(\d+)' versionName='([^']*)'/m);
  if (!metadata || metadata[1] !== targetPackage || /^application-debuggable\b/m.test(badging)) throw Error('APK must be the expected non-debuggable release package');
  if (profile === 'buddhist') {
    if (/android\.permission\.INTERNET/.test(badging) !== Boolean(pairing)) throw Error('Buddhist network permission does not match selected development mode');
    if (pairing) {
      const resources = call('aapt', ['dump', '--values', 'resources', apk]);
      const policyPath = resources.match(/resource 0x[0-9a-f]+ com\.onaria\.buddhist:xml\/mac_ai_network:[^\n]*\n\s*\(string8\) "(res\/[A-Za-z0-9_/.]+\.xml)"/)?.[1];
      if (!policyPath) throw Error('USB network policy resource missing');
      const policy = call('aapt', ['dump', 'xmltree', apk, policyPath]);
      const expected = [
        'E: network-security-config', 'E: base-config',
        'A: cleartextTrafficPermitted=(type 0x12)0x0', 'E: domain-config',
        'A: cleartextTrafficPermitted=(type 0x12)0xffffffff', 'E: domain',
        'A: includeSubdomains=(type 0x12)0x0', 'C: "127.0.0.1"',
      ];
      const lines = policy.trim().split(/\r?\n/).map(line => line.trim().replace(/ \(line=\d+\)$/, ''));
      if (JSON.stringify(lines) !== JSON.stringify(expected)) throw Error('USB network policy must permit only loopback cleartext');
    }
    const entries = call('aapt', ['list', apk]);
    if (/bible|system_prompt_ko|packages\/onaria\//i.test(entries)
      || !entries.includes('packages/onaria_buddhist_pack/assets/mock_scriptures.json')) throw Error('Buddhist asset isolation failed');
  }
  if (previousVersion && BigInt(metadata[2]) < BigInt(previousVersion)) throw Error('Version downgrade refused; keep the newer installed app');
  if (pairing) {
    const endpoint = `tcp:${pairing.BUDDHIST_MAC_AI_PORT}`;
    const mappings = adb(['reverse', '--list']).trim().split(/\r?\n/);
    if (mappings.some(line => { const fields = line.trim().split(/\s+/); return fields[1] === endpoint && fields[2] !== endpoint; })) throw Error('USB port already mapped elsewhere');
    if (!mappings.some(line => { const fields = line.trim().split(/\s+/); return fields[1] === endpoint && fields[2] === endpoint; })) adb(['reverse', '--no-rebind', endpoint, endpoint]);
  }
  const result = adb(['install', '-r', apk]);
  if (!/^Success\s*$/m.test(result) || /Failure|INSTALL_FAILED_/.test(result)) throw Error('Update failed; stopped without uninstall or retry');
  report(`Installed ${targetPackage} ${metadata[3]}+${metadata[2]} with adb install -r.`);
  const launch = adb(['shell', 'am', 'start', '-W', '-n', `${targetPackage}/.MainActivity`]);
  if (!/^Status: ok\s*$/m.test(launch)) throw Error('Update installed; application launch not confirmed');
  report('Application launch confirmed.');
  return { apk, packageId: targetPackage, version: metadata[3], versionCode: metadata[2], certificate: expectedCert, api: profile === 'christian' ? productionApi : null };
}

export function discoverTools(root) {
  const windows = process.platform === 'win32';
  if (windows && !process.env.JAVA_HOME) {
    const bundledJdk = join(process.env.ProgramFiles || 'C:/Program Files', 'Android/Android Studio/jbr');
    if (existsSync(join(bundledJdk, 'bin/java.exe'))) process.env.JAVA_HOME = bundledJdk;
  }
  const find = name => {
    for (const directory of (process.env.PATH || '').split(delimiter)) {
      for (const suffix of windows ? ['.exe', '.bat', '.cmd'] : ['']) {
        const candidate = join(directory, name + suffix);
        if (existsSync(candidate)) return candidate;
      }
    }
    return null;
  };
  const propertiesPath = join(root, 'android/local.properties');
  const properties = existsSync(propertiesPath) ? readFileSync(propertiesPath, 'utf8') : '';
  const sdk = process.env.ANDROID_HOME || process.env.ANDROID_SDK_ROOT ||
    properties.match(/^sdk\.dir=(.*)$/m)?.[1].trim().replace(/\\([\\:])/g, '$1');
  if (!sdk) throw Error('Android SDK path unavailable');
  const flutterRoot = properties.match(/^flutter\.sdk=(.*)$/m)?.[1].trim().replace(/\\([\\:])/g, '$1');
  // Build-tools 36 is the current project baseline; no signing config mutation.
  const tools = { adb: join(sdk, 'platform-tools', windows ? 'adb.exe' : 'adb'),
    signer: join(sdk, 'build-tools/36.0.0', windows ? 'apksigner.bat' : 'apksigner'),
    aapt: join(sdk, 'build-tools/36.0.0', windows ? 'aapt.exe' : 'aapt'),
    flutter: find('flutter') || (flutterRoot && join(flutterRoot, 'bin', windows ? 'flutter.bat' : 'flutter')) };
  for (const [name, path] of Object.entries(tools)) if (!path || !existsSync(path)) throw Error(`${name} unavailable; verify SDK/build-tools/PATH`);
  return tools;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  try {
    const args = process.argv.slice(2);
    const macAi = args[0] === '--buddhist-mac-ai';
    const buddhist = macAi || args[0] === '--buddhist';
    if (buddhist) args.shift();
    const macAiConfig = macAi ? args.shift() : undefined;
    if (macAi && !macAiConfig) throw Error('USB pairing file required');
    if (args.length > 1 || args.some(arg => arg.startsWith('-'))) throw Error('Only --buddhist and an optional device serial are accepted');
    updateRelease({ root, tools: discoverTools(root), device: args[0], profile: buddhist ? 'buddhist' : 'christian', macAiConfig });
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
