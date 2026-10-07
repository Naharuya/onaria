// Only invoked by trusted-main manual deployment; no credentials in CI logs.
import { readFileSync, writeFileSync, copyFileSync, existsSync, chmodSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { signingConfig } from './android-release.mjs';
import { syncNaverConfig } from './sync-naver-config.mjs';

export function prepareLocalReleaseConfig(source, target) {
  source = resolve(source);
  target = resolve(target);
  if (source === target || ![source, target].every(root => /^name:\s*onaria\s*$/m.test(readFileSync(resolve(root, 'pubspec.yaml'), 'utf8')))) {
    throw Error('Distinct ONARIA source and checkout required');
  }
  const signing = signingConfig(source);
  const properties = readFileSync(signing.propertiesPath, 'utf8')
    .replace(/^storeFile\s*=.*$/m, `storeFile=${signing.storeFile.replaceAll('\\', '/')}`);
  const signingTarget = resolve(target, 'android/key.properties');
  writeFileSync(signingTarget, properties, { mode: 0o600 });
  chmodSync(signingTarget, 0o600);
  for (const name of ['android/naver.properties', '.onaria.local.env']) {
    const from = resolve(source, name);
    if (!existsSync(from)) {
      if (name === 'android/naver.properties') throw Error('Local Naver configuration missing');
      continue;
    }
    copyFileSync(from, resolve(target, name));
    chmodSync(resolve(target, name), 0o600);
  }
  syncNaverConfig(target);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (process.argv.length !== 3) throw Error('Local source directory required');
    prepareLocalReleaseConfig(process.argv[2], resolve(dirname(fileURLToPath(import.meta.url)), '..'));
    console.log('Local ONARIA release configuration prepared privately.');
  } catch {
    console.error('Release configuration preparation failed; check local ONARIA setup.');
    process.exitCode = 1;
  }
}
