import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';
import { TaskQueue } from './task_queue.js';
import { VerificationRunner } from './verification_runner.js';
import { releaseState } from './policy.js';

export class AriMainManager {
  constructor({ rootDir, logger = console, repairWorker = null } = {}) {
    this.rootDir = rootDir;
    this.logger = logger;
    this.queue = new TaskQueue(path.join(rootDir, 'state', 'tasks.json'));
    this.runner = new VerificationRunner({ repairWorker, logger });
  }

  loadProjectProfile(projectDir) {
    const file = path.join(projectDir, '.ari', 'verification.yaml');
    if (!fs.existsSync(file)) throw new Error(`Missing verification profile: ${file}`);
    return YAML.parse(fs.readFileSync(file, 'utf8'));
  }

  enqueue(task) {
    return this.queue.enqueue(task);
  }

  async runNext() {
    const task = this.queue.nextReady();
    if (!task) return { state: 'IDLE' };
    this.queue.update(task.id, { status: 'IN_PROGRESS', startedAt: new Date().toISOString() });
    try {
      if (task.type === 'VERIFY_PROJECT') {
        const profile = this.loadProjectProfile(task.projectDir);
        const report = await this.runner.verify({
          project: task.project,
          branch: task.branch,
          cwd: task.projectDir,
          checks: profile.checks ?? [],
        });
        const finalStatus = report.state === 'SERVER_PASS' ? 'COMPLETED' : report.state === 'HUMAN_REVIEW' ? 'HUMAN_REVIEW' : 'FAILED';
        this.queue.update(task.id, { status: finalStatus, report, completedAt: new Date().toISOString() });
        return report;
      }
      this.queue.update(task.id, { status: 'HUMAN_REVIEW', reason: `Unsupported task type ${task.type}` });
      return { state: 'HUMAN_REVIEW', reason: 'unsupported_task_type' };
    } catch (error) {
      const state = error.code === 'HUMAN_REVIEW' ? 'HUMAN_REVIEW' : 'FAILED';
      this.queue.update(task.id, { status: state, error: String(error.message ?? error) });
      return { state, error: String(error.message ?? error) };
    }
  }

  releaseDecision(input) {
    return releaseState(input);
  }
}
