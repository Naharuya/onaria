import { spawn } from 'node:child_process';
import { assertAutomationAllowed } from './policy.js';

function runCommand(command, args, { cwd, env = {}, timeoutMs = 30 * 60 * 1000 } = {}) {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      cwd,
      env: { ...process.env, ...env },
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: false,
    });
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => child.kill('SIGKILL'), timeoutMs);
    child.stdout.on('data', d => { stdout += d.toString(); });
    child.stderr.on('data', d => { stderr += d.toString(); });
    child.on('close', code => {
      clearTimeout(timer);
      resolve({ code, stdout, stderr, ok: code === 0 });
    });
  });
}

export class VerificationRunner {
  constructor({ repairWorker = null, maxRepairAttempts = 2, logger = console } = {}) {
    this.repairWorker = repairWorker;
    this.maxRepairAttempts = maxRepairAttempts;
    this.logger = logger;
  }

  async verify({ project, branch, cwd, checks }) {
    assertAutomationAllowed({ project, branch, action: 'verification' });
    const report = { project, branch, state: 'VERIFYING', checks: [], repairs: [] };

    for (const check of checks) {
      const result = await runCommand(check.command, check.args ?? [], { cwd, env: check.env, timeoutMs: check.timeoutMs });
      report.checks.push({ id: check.id, ok: result.ok, code: result.code, stdout: result.stdout.slice(-12000), stderr: result.stderr.slice(-12000) });
      if (!result.ok) {
        if (!this.repairWorker || check.repairable === false) {
          report.state = check.humanReviewOnFail ? 'HUMAN_REVIEW' : 'FAIL';
          return report;
        }
        for (let attempt = 1; attempt <= this.maxRepairAttempts; attempt++) {
          report.state = 'REPAIRING';
          const repair = await this.repairWorker({ project, branch, cwd, failedCheck: check, result, attempt });
          report.repairs.push({ attempt, ...repair });
          if (repair?.humanReview) {
            report.state = 'HUMAN_REVIEW';
            return report;
          }
          report.state = 'REVERIFYING';
          const retry = await runCommand(check.command, check.args ?? [], { cwd, env: check.env, timeoutMs: check.timeoutMs });
          report.checks.push({ id: `${check.id}:retry:${attempt}`, ok: retry.ok, code: retry.code, stdout: retry.stdout.slice(-12000), stderr: retry.stderr.slice(-12000) });
          if (retry.ok) break;
          if (attempt === this.maxRepairAttempts) {
            report.state = 'HUMAN_REVIEW';
            return report;
          }
        }
      }
    }
    report.state = 'SERVER_PASS';
    return report;
  }
}
