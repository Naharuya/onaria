import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import Database from 'better-sqlite3';
import { fileURLToPath } from 'node:url';
import { acquireBackupLock } from '../src/privacy/backup_retention.js';

const DEFAULT_FILES = ['members.sqlite', 'member-sessions.sqlite', 'ai_usage.sqlite', 'deletion-manifest.sqlite'];

function safeDir(value, label) {
  if (typeof value !== 'string' || !value.trim()) throw new TypeError(`${label} is required`);
  return path.resolve(value);
}

function timestamp(now = new Date()) {
  if (!(now instanceof Date) || Number.isNaN(now.getTime())) throw new TypeError('Invalid backup time');
  return now.toISOString().replace(/[:.]/g, '-');
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

export async function backupDatabases({
  sourceDir = process.env.ONARIA_DATA_DIR || '/opt/onaria/backend/data',
  backupRoot = process.env.ONARIA_BACKUP_DIR || '/opt/onaria-periodic-backups',
  files = DEFAULT_FILES,
  now = new Date(),
} = {}) {
  sourceDir = safeDir(sourceDir, 'sourceDir');
  backupRoot = safeDir(backupRoot, 'backupRoot');
  if (sourceDir === backupRoot || backupRoot.startsWith(sourceDir + path.sep)) {
    throw new Error('Backup root must be separate from live data');
  }

  fs.mkdirSync(backupRoot, { recursive: true, mode: 0o700 });
  if (fs.lstatSync(backupRoot).isSymbolicLink()) throw new Error('Unsafe backup root');
  const release = acquireBackupLock(backupRoot);
  const destination = path.join(backupRoot, timestamp(now));
  try { fs.mkdirSync(destination, { mode: 0o700 }); fs.chmodSync(destination, 0o700); }
  catch (error) { release(); throw error; }

  const manifest = {
    createdAt: now.toISOString(),
    sourceDir,
    files: [],
  };

  try {
    for (const name of files) {
      if (!/^[A-Za-z0-9._-]+\.sqlite$/.test(name)) throw new Error('Invalid database filename');
      const source = path.join(sourceDir, name);
      const stat = fs.lstatSync(source);
      if (!stat.isFile() || stat.isSymbolicLink()) throw new Error(`Unsafe database source: ${name}`);

      const target = path.join(destination, name);
      const db = new Database(source, { readonly: true, fileMustExist: true });
      try {
        await db.backup(target);
      } finally {
        db.close();
      }

      fs.chmodSync(target, 0o600);
      const verify = new Database(target, { readonly: true, fileMustExist: true });
      let quickCheck;
      try {
        quickCheck = verify.pragma('quick_check', { simple: true });
      } finally {
        verify.close();
      }
      if (quickCheck !== 'ok') throw new Error(`Backup integrity check failed: ${name}`);

      const targetStat = fs.statSync(target);
      manifest.files.push({
        name,
        bytes: targetStat.size,
        sha256: sha256(target),
        quickCheck,
      });
    }

    const manifestPath = path.join(destination, 'manifest.json');
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n', { mode: 0o600 });
    fs.chmodSync(manifestPath, 0o600);
    return { destination, manifest };
  } catch (error) {
    fs.rmSync(destination, { recursive: true, force: true });
    throw error;
  } finally { release(); }
}

const invokedAsScript = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedAsScript) {
  try {
    const result = await backupDatabases();
    console.log(`ONARIA backup complete: ${result.manifest.files.length} databases -> ${result.destination}`);
  } catch (error) {
    console.error(`ONARIA backup failed: ${error instanceof Error ? error.message : 'unknown error'}`);
    process.exitCode = 1;
  }
}
