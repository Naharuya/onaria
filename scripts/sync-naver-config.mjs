// Both native SDKs must use the same locally supplied credential pair.
import { readFileSync, writeFileSync, chmodSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

export function readNaverCredentials(text) {
  const values = new Map();
  for (const line of text.split(/\r?\n/)) {
    if (!line.trim() || /^\s*[#!]/.test(line)) continue;
    const match = line.match(/^\s*(naver\.client_(?:id|secret))\s*=(.*?)\s*$/);
    if (!match) continue;
    if (values.has(match[1])) throw Error('Duplicate Naver configuration key');
    values.set(match[1], match[2]);
  }
  const id = values.get('naver.client_id');
  const secret = values.get('naver.client_secret');
  // Reject properties escaping and xcconfig interpolation/comment injection.
  if (![id, secret].every(value => typeof value === 'string' && /^[A-Za-z0-9_-]+$/.test(value))) {
    throw Error('Missing or invalid Naver credentials in android/naver.properties');
  }
  if (id === secret) throw Error('Naver Client ID and Client Secret must be different');
  return { id, secret };
}

export function syncNaverConfig(root) {
  const source = resolve(root, 'android/naver.properties');
  const { id, secret } = readNaverCredentials(readFileSync(source, 'utf8'));
  const target = resolve(root, 'ios/Flutter/NaverKeys.xcconfig');
  writeFileSync(target, `// Generated locally by scripts/sync-naver-config.mjs. Never commit.\nNAVER_CLIENT_ID = ${id}\nNAVER_CLIENT_SECRET = ${secret}\n`, { mode: 0o600 });
  chmodSync(source, 0o600);
  chmodSync(target, 0o600);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    syncNaverConfig(resolve(dirname(fileURLToPath(import.meta.url)), '..'));
    console.log('Naver native configuration synchronized; credentials are not printed.');
  } catch {
    console.error('Naver configuration failed. Check ignored android/naver.properties locally.');
    process.exitCode = 1;
  }
}
