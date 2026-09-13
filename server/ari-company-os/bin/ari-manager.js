#!/usr/bin/env node
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { AriMainManager } from '../src/main_manager.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(here, '..');
const manager = new AriMainManager({ rootDir });
const [command, ...args] = process.argv.slice(2);

async function main() {
  if (command === 'status') {
    console.log(JSON.stringify({ tasks: manager.queue.list() }, null, 2));
    return;
  }
  if (command === 'run') {
    const result = await manager.runNext();
    console.log(JSON.stringify(result, null, 2));
    return;
  }
  if (command === 'enqueue-verify') {
    const [project, projectDir, branch] = args;
    if (!project || !projectDir || !branch) {
      throw new Error('usage: ari-manager enqueue-verify <project> <projectDir> <branch>');
    }
    const task = manager.enqueue({ type: 'VERIFY_PROJECT', project, projectDir: path.resolve(projectDir), branch });
    console.log(JSON.stringify(task, null, 2));
    return;
  }
  if (command === 'release-state') {
    const [serverPass, githubCiPass, devicePass, releaseApproved] = args.map(v => v === 'true');
    console.log(manager.releaseDecision({ serverPass, githubCiPass, devicePass, releaseApproved }));
    return;
  }
  if (command === 'daemon') {
    const intervalMs = Number(process.env.ARI_POLL_INTERVAL_MS ?? 15000);
    console.log(JSON.stringify({ service: 'ari-main-manager', state: 'STARTED', intervalMs }));
    for (;;) {
      const result = await manager.runNext();
      if (result.state !== 'IDLE') console.log(JSON.stringify(result));
      await new Promise(resolve => setTimeout(resolve, intervalMs));
    }
  }
  console.log('commands: status | run | enqueue-verify | release-state | daemon');
}

main().catch(error => {
  console.error(error?.stack ?? String(error));
  process.exitCode = 1;
});
