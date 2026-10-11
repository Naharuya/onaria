import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const BACKUP_RETENTION_DAYS = 14;
export const snapshotName = value => /^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z$/.test(value);
const digest = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');

export function inspectSnapshot(directory) {
  const stat = fs.lstatSync(directory);
  if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error('Unsafe backup directory');
  const manifestPath = path.join(directory, 'manifest.json');
  const meta = fs.lstatSync(manifestPath);
  if (!meta.isFile() || meta.isSymbolicLink()) throw new Error('Unsafe backup manifest');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const created = Date.parse(manifest.createdAt);
  if (!Number.isFinite(created) || new Date(created).toISOString() !== manifest.createdAt ||
      path.basename(directory) !== manifest.createdAt.replace(/[:.]/g, '-')) throw new Error('Invalid backup timestamp');
  if (!Array.isArray(manifest.files) || !manifest.files.length) throw new Error('Empty backup manifest');
  const names = new Set(['manifest.json']);
  for (const entry of manifest.files) {
    if (!/^[A-Za-z0-9._-]+\.sqlite$/.test(entry.name) || names.has(entry.name) ||
        !/^[a-f0-9]{64}$/.test(entry.sha256) || entry.quickCheck !== 'ok') throw new Error('Invalid backup entry');
    const file = path.join(directory, entry.name);
    const info = fs.lstatSync(file);
    if (!info.isFile() || info.isSymbolicLink() || info.size !== entry.bytes || digest(file) !== entry.sha256)
      throw new Error('Backup verification failed');
    names.add(entry.name);
    // SQLite readers may create an empty WAL and shared-memory index. A
    // nonempty WAL contains unverified state and must block this snapshot.
    for (const suffix of ['-wal','-shm']) {
      const sidecar = file + suffix;
      if (fs.existsSync(sidecar)) {
        const side = fs.lstatSync(sidecar);
        if (!side.isFile() || side.isSymbolicLink() || (suffix === '-wal' && side.size !== 0))
          throw new Error('Unverified backup sidecar');
        names.add(entry.name + suffix);
      }
    }
  }
  if (fs.readdirSync(directory).some(name => !names.has(name))) throw new Error('Unmanaged backup contents');
  return { manifest, created };
}

// Only complete, verified ONARIA snapshots are eligible. Unknown files and
// symlinks fail closed rather than being recursively removed.
export function pruneBackups({ backupRoot, now = new Date(), apply = false } = {}) {
  if (!(now instanceof Date) || !Number.isFinite(now.getTime())) throw new TypeError('Invalid retention time');
  const root = fs.realpathSync(backupRoot);
  if (root !== path.resolve(backupRoot) || root === path.parse(root).root) throw new Error('Unsafe backup root');
  const cutoff = now.getTime() - BACKUP_RETENTION_DAYS * 86400000;
  const snapshots = [];
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    if (entry.name === '.maintenance.lock') continue;
    if (!entry.isDirectory() || entry.isSymbolicLink() || !snapshotName(entry.name)) throw new Error('Unmanaged backup root entry');
    const directory = path.join(root, entry.name);
    snapshots.push({ directory, ...inspectSnapshot(directory) });
  }
  const eligible = snapshots.filter(s => s.created <= cutoff);
  // Validate the entire root before the first mutation.
  if (apply) for (const s of eligible) {
    inspectSnapshot(s.directory);
    fs.rmSync(s.directory, { recursive: true });
  }
  return { retentionDays: BACKUP_RETENTION_DAYS, scanned: snapshots.length,
    candidates: eligible.length, removed: apply ? eligible.length : 0 };
}

export function acquireBackupLock(backupRoot) {
  const root = fs.realpathSync(backupRoot);
  const lock = path.join(root, '.maintenance.lock');
  const fd = fs.openSync(lock, 'wx', 0o600);
  fs.writeSync(fd, String(process.pid));
  let released = false;
  return () => {
    if (released) return;
    released = true;
    fs.closeSync(fd);
    fs.unlinkSync(lock);
  };
}
