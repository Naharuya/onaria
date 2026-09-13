#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { AriMainManager } from '../src/main_manager.js';
import { ProjectWatcher } from '../src/project_watcher.js';

const execFileAsync = promisify(execFile);
const here = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(here, '..');
const manager = new AriMainManager({ rootDir });
const [command, ...args] = process.argv.slice(2);

async function currentBranch(projectDir) {
  const { stdout } = await execFileAsync('git', ['branch', '--show-current'], { cwd: projectDir });
  return stdout.trim();
}

function loadProjects() {
  const file = path.join(rootDir, 'config', 'projects.yaml');
  return YAML.parse(fs.readFileSync(file, 'utf8')).projects ?? [];
}

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
    const pollMs = Number(process.env.ARI_POLL_INTERVAL_MS ?? 15000);
    const quietMs = Number(process.env.ARI_QUIET_WINDOW_MS ?? 20 * 60 * 1000);
    const projects = loadProjects();
    const watcher = new ProjectWatcher({
      projects,
      pollMs,
      quietMs,
      onQuietChange: async project => {
        const branch = await currentBranch(project.dir);
        if (!branch || branch === 'main' || branch === 'master') {
          manager.enqueue({
            type: 'VERIFY_PROJECT', project: project.id, projectDir: project.dir,
            branch: branch || 'DETACHED', status: 'HUMAN_REVIEW', reason: 'protected_or_detached_branch',
          });
          return;
        }
        manager.enqueue({ type: 'VERIFY_PROJECT', project: project.id, projectDir: project.dir, branch });
      },
    });

    console.log(JSON.stringify({ service: 'ari-main-manager', state: 'STARTED', pollMs, quietMs, projects: projects.map(p => p.id) }));
    watcher.start().catch(error => {
      console.error('watcher_failed', error?.stack ?? String(error));
      process.exitCode = 1;
    });

    for (;;) {
      const result = await manager.runNext();
      if (result.state !== 'IDLE') console.log(JSON.stringify(result));
      await new Promise(resolve => setTimeout(resolve, pollMs));
    }
  }
  console.log('commands: status | run | enqueue-verify | release-state | daemon');
}

main().catch(error => {
  console.error(error?.stack ?? String(error));
  process.exitCode = 1;
});
