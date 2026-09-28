import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { createBuddhistDevApp } from './app.js';

export function inspectListenPorts() {
  // Fail closed if preflight cannot inspect LISTEN state. Never guess a port.
  try {
    return execFileSync('lsof', ['-nP', '-iTCP', '-sTCP:LISTEN'], { encoding: 'utf8' });
  } catch (error) {
    if (error.status === 1 && !error.stdout?.trim() && !error.stderr?.trim()) return 'No TCP listeners';
    throw Error('LISTEN_PREFLIGHT_FAILED');
  }
}

export async function startBuddhistDevServer({ log = console.log } = {}) {
  if (process.env.NODE_ENV === 'production') throw Error('TEST_DATA_ONLY_REQUIRED');
  const listeners = inspectListenPorts();
  // Print port numbers only, never unrelated process information or credentials.
  const ports = [...listeners.matchAll(/:(\d+)\s+\(LISTEN\)/g)].map((match) => Number(match[1]));
  log(`Preflight LISTEN ports: ${[...new Set(ports)].sort((a, b) => a - b).join(', ') || 'none'}`);
  const app = createBuddhistDevApp();
  const server = await new Promise((resolve, reject) => {
    const candidate = app.listen(0, '127.0.0.1', () => resolve(candidate));
    candidate.once('error', reject);
  });
  const url = `http://127.0.0.1:${server.address().port}`;
  log(`TEST_DATA_ONLY Buddhist development UI: ${url}`);
  return { server, url };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const { server } = await startBuddhistDevServer();
  for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => server.close());
}
