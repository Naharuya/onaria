import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';
import { fileURLToPath } from 'node:url';
import { createSqliteUsageLedger } from '../src/cost/sqlite_usage_ledger.js';
import { pruneBackups, acquireBackupLock } from '../src/privacy/backup_retention.js';

function runMaintenance({ dataDir, backupRoot, now = new Date(), apply = false } = {}) {
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) throw new TypeError('Invalid retention time');
  dataDir = path.resolve(dataDir);
  const report = { version: '1.0.0-retention.1', mode: apply ? 'apply' : 'dry-run', timestamp: now.toISOString() };
  // Validate backup root first. This job never removes active members.
  report.backups = pruneBackups({ backupRoot, now });
  const sessionFile = path.join(dataDir, 'member-sessions.sqlite');
  const stat = fs.lstatSync(sessionFile);
  if (!stat.isFile() || stat.isSymbolicLink()) throw new Error('Unsafe session database');
  const sessions = new Database(sessionFile, { readonly: !apply, fileMustExist: true });
  try {
    const columns = sessions.pragma('table_info(member_sessions)').map(x => x.name);
    if (!['token_hash','provider','provider_user_id','expires_at','created_at'].every(x => columns.includes(x)))
      throw new Error('Unexpected session schema');
    report.sessions = { expired: sessions.prepare('SELECT COUNT(*) n FROM member_sessions WHERE expires_at <= ?').get(now.getTime()).n, removed: 0 };

  } finally { sessions.close(); }
  const usageFile = path.join(dataDir, 'ai_usage.sqlite');
  const usageStat = fs.lstatSync(usageFile);
  if (!usageStat.isFile() || usageStat.isSymbolicLink()) throw new Error('Unsafe usage database');
  const usage = new Database(usageFile, { readonly: true, fileMustExist: true });
  try {
    if (usage.pragma('application_id', { simple: true }) !== 0x53424347) throw new Error('Unexpected usage database');
    report.usage = { retentionDays: 62, expired: usage.prepare('SELECT COUNT(*) n FROM cost_requests WHERE timestamp < ?')
      .get(new Date(now.getTime()-62*86400000).toISOString()).n };
  } finally { usage.close(); }
  const manifestFile = path.join(dataDir, 'deletion-manifest.sqlite');
  const manifestStat = fs.lstatSync(manifestFile);
  if (!manifestStat.isFile() || manifestStat.isSymbolicLink()) throw new Error('Latest deletion manifest required');
  const manifest = new Database(manifestFile, { readonly: true, fileMustExist: true });
  const deletionCutoff = new Date(now.getTime()-14*86400000).toISOString();
  try {
    if (manifest.pragma('application_id', { simple: true }) !== 0x4f4e444d ||
        !manifest.prepare("SELECT value FROM deletion_control WHERE key='restore_not_before'").get())
      throw new Error('Unexpected deletion manifest');
    report.deletions = { retentionDays:14,
      expired:manifest.prepare('SELECT COUNT(*) n FROM deleted_members WHERE deleted_at <= ?').get(deletionCutoff).n, removed:0 };
  } finally { manifest.close(); }
  if (apply) {
    const writer = new Database(sessionFile, { fileMustExist: true });
    try {
      writer.pragma('secure_delete = ON');
      report.sessions.removed = writer.transaction(() =>
        writer.prepare('DELETE FROM member_sessions WHERE expires_at <= ?').run(now.getTime()).changes).immediate();
    } finally { writer.close(); }
    // Existing cost accounting recovers abandoned reservations before pruning,
    // preserving unknown-cost accounting and child-call cascades.
    const ledger = createSqliteUsageLedger({ filename: usageFile, retentionDays: 62, now: () => now });
    try { ledger.overview(); } finally { ledger.close(); }
    report.backups = pruneBackups({ backupRoot, now, apply: true });
    // Purge minimal tombstones only after verified snapshot pruning succeeds.
    // Advance the restore barrier first in the same transaction so an old
    // snapshot can never become eligible after its deletion record is removed.
    const deletions = new Database(manifestFile, { fileMustExist:true });
    try {
      deletions.pragma('secure_delete = ON');
      report.deletions.removed = deletions.transaction(() => {
        const previous = deletions.prepare("SELECT value FROM deletion_control WHERE key='restore_not_before'").get().value;
        if (!Number.isFinite(Date.parse(previous))) throw new Error('Invalid restore barrier');
        if (previous < deletionCutoff) deletions.prepare("UPDATE deletion_control SET value=? WHERE key='restore_not_before'").run(deletionCutoff);
        return deletions.prepare('DELETE FROM deleted_members WHERE deleted_at <= ?').run(deletionCutoff).changes;
      }).immediate();
    } finally {deletions.close();}

  }
  return report; // Counts only, never member IDs, credentials or conversation text.
}

export function maintainRetention(options = {}) {
  // Share the lock with snapshot creation. A crash leaves a fail-closed lock
  // for operator review rather than silently racing a partially written backup.
  const release = options.apply ? acquireBackupLock(options.backupRoot) : () => {};
  try { return runMaintenance(options); } finally { release(); }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    console.log(JSON.stringify(maintainRetention({
      dataDir: process.env.ONARIA_DATA_DIR || '/opt/onaria/backend/data',
      backupRoot: process.env.ONARIA_BACKUP_DIR || '/opt/onaria-periodic-backups',
      apply: process.argv.includes('--apply'),
    })));
  } catch { console.error('ONARIA retention failed; inspect configured paths and schemas.'); process.exitCode = 1; }
}
