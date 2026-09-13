import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { QuietWindowDebouncer } from './debounce.js';

const execFileAsync = promisify(execFile);
export const DEFAULT_VERIFICATION_QUIET_MS = 10 * 60 * 1000;

export async function projectFingerprint(cwd, metadataOnly = false) {
  const [{ stdout: head }, { stdout: branch }] = await Promise.all([
    execFileAsync('git', ['rev-parse', 'HEAD'], { cwd }),
    execFileAsync('git', ['branch', '--show-current'], { cwd }),
  ]);
  const {stdout: files} = await execFileAsync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'], {cwd, maxBuffer: 16 * 1024 * 1024});
  const hash = crypto.createHash('sha256').update(head).update(branch);
  for (const name of [...new Set(files.split('\0').filter(Boolean))].sort()) {
    // Do not read credentials, user databases, or generated runtime output.
    if (/^(backend\/)?evaluation\/results\/|^\.ari\/reports\//.test(name)) continue;
    if (/(^|\/)(\.env[^/]*|node_modules|build|state|logs|data|backups)(\/|$)|\.(pem|key|jks|keystore|db|sqlite\d*)$/i.test(name)) continue;
    const file = path.join(cwd,name);
    hash.update(name);
    try { const st = fs.lstatSync(file); if (st.isFile()) hash.update(metadataOnly ? `${st.size}:${st.mtimeMs}:${st.ctimeMs}` : fs.readFileSync(file)); } catch { hash.update('missing'); }
  }
  return hash.digest('hex');
}

export class ProjectWatcher {
  constructor({ projects, onQuietChange, pollMs = 15000, quietMs = DEFAULT_VERIFICATION_QUIET_MS, logger = console, statePath = null } = {}) {
    this.projects = projects;
    this.onQuietChange = onQuietChange;
    this.pollMs = pollMs;
    this.quietMs = quietMs;
    this.logger = logger;
    this.statePath = statePath;
    this.stableFingerprints = statePath && fs.existsSync(statePath) ? JSON.parse(fs.readFileSync(statePath, 'utf8')) : {};
    this.running = false;
    this.fingerprints = new Map();
    this.debouncers = new Map();
  }

  async #pollProject(project) {
    let fingerprint;
    try {
      fingerprint = await projectFingerprint(project.dir, project.metadataOnly);
    } catch (error) {
      this.logger.error?.('watch_failed', { project: project.id, error: 'git_fingerprint_failed' });
      return;
    }
    const previous = this.fingerprints.get(project.id) ?? this.stableFingerprints[project.id];
    this.fingerprints.set(project.id, fingerprint);
    if (previous === undefined) { this.#saveStable(project.id, fingerprint); return; }
    if (previous === fingerprint) return;

    let debouncer = this.debouncers.get(project.id);
    if (!debouncer) {
      debouncer = new QuietWindowDebouncer({
        quietMs: this.quietMs,
        onReady: async snapshot => { try { await this.onQuietChange(project, snapshot); this.#saveStable(project.id, snapshot.meta.fingerprint); } catch { this.logger.error?.('enqueue_failed', {project:project.id}); } },
      });
      this.debouncers.set(project.id, debouncer);
    }
    debouncer.markChanged({ fingerprint });
    this.logger.log?.('project_changed', { project: project.id, quietMs: this.quietMs });
  }

  #saveStable(id, fingerprint) {
    this.stableFingerprints[id] = fingerprint;
    if (this.statePath) {
      const tmp = this.statePath + '.tmp';
      fs.writeFileSync(tmp, JSON.stringify(this.stableFingerprints));
      fs.renameSync(tmp, this.statePath);
    }
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
