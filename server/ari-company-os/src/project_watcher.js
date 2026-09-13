import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { QuietWindowDebouncer } from './debounce.js';

const execFileAsync = promisify(execFile);

async function gitFingerprint(cwd) {
  const [{ stdout: head }, { stdout: status }] = await Promise.all([
    execFileAsync('git', ['rev-parse', 'HEAD'], { cwd }),
    execFileAsync('git', ['status', '--porcelain=v1'], { cwd }),
  ]);
  return `${head.trim()}\n${status}`;
}

export class ProjectWatcher {
  constructor({ projects, onQuietChange, pollMs = 15000, quietMs = 20 * 60 * 1000, logger = console } = {}) {
    this.projects = projects;
    this.onQuietChange = onQuietChange;
    this.pollMs = pollMs;
    this.quietMs = quietMs;
    this.logger = logger;
    this.running = false;
    this.fingerprints = new Map();
    this.debouncers = new Map();
  }

  async #pollProject(project) {
    let fingerprint;
    try {
      fingerprint = await gitFingerprint(project.dir);
    } catch (error) {
      this.logger.error?.('watch_failed', { project: project.id, error: error.message });
      return;
    }
    const previous = this.fingerprints.get(project.id);
    this.fingerprints.set(project.id, fingerprint);
    if (previous === undefined || previous === fingerprint) return;

    let debouncer = this.debouncers.get(project.id);
    if (!debouncer) {
      debouncer = new QuietWindowDebouncer({
        quietMs: this.quietMs,
        onReady: async snapshot => this.onQuietChange(project, snapshot),
      });
      this.debouncers.set(project.id, debouncer);
    }
    debouncer.markChanged({ fingerprint });
    this.logger.log?.('project_changed', { project: project.id, quietMs: this.quietMs });
  }

  async start() {
    this.running = true;
    while (this.running) {
      await Promise.all(this.projects.map(project => this.#pollProject(project)));
      await new Promise(resolve => setTimeout(resolve, this.pollMs));
    }
  }

  stop() {
    this.running = false;
    for (const debouncer of this.debouncers.values()) debouncer.cancel();
  }
}
