import { randomBytes } from 'node:crypto';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { inspectListenPorts } from './server.js';
import { createMacAiApp } from './buddhist/mac_ai.js';

if (process.env.NODE_ENV === 'production') throw Error('DEV_ONLY');
const listeners = inspectListenPorts();
const ports = [...new Set([...listeners.matchAll(/:(\d+)\s+\(LISTEN\)/g)].map(m => Number(m[1])))];
console.log(`Preflight LISTEN ports: ${ports.sort((a,b)=>a-b).join(', ')}`);
const token = randomBytes(32).toString('hex');
const app = createMacAiApp({ token });
const server = app.listen(0, '127.0.0.1', () => {
  const path = join(mkdtempSync(join(tmpdir(), 'buddhist-usb-')), 'pairing.json');
  writeFileSync(path, JSON.stringify({ BUDDHIST_MAC_AI_PORT: server.address().port, BUDDHIST_MAC_AI_TOKEN: token }), { mode: 0o600 });
  console.log(`Buddhist USB pairing file: ${path}`);
  console.log(`Buddhist localhost port: ${server.address().port}; model=qwen3:8b; no database or transcript log`);
});
for (const signal of ['SIGINT','SIGTERM']) process.once(signal, () => server.close());
