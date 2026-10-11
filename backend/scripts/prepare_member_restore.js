import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';
import { fileURLToPath } from 'node:url';
import { inspectSnapshot } from '../src/privacy/backup_retention.js';

// Creates an OFFLINE candidate only. Never overwrites live DBs, never restores
// old sessions, never trusts the deletion manifest from an old backup.
export async function prepareMemberRestore({ snapshotDir, liveDataDir, destination, now = new Date() } = {}) {
  const inspected = inspectSnapshot(snapshotDir);
  const age = now.getTime() - inspected.created;
  if (!(now instanceof Date) || !Number.isFinite(now.getTime()) || age < 0 || age >= 14*86400000)
    throw new Error('Snapshot outside retention window');
  liveDataDir = fs.realpathSync(liveDataDir);
  snapshotDir = fs.realpathSync(snapshotDir);
  destination = path.resolve(destination);
  const parent = fs.realpathSync(path.dirname(destination));
  if (parent !== path.dirname(destination) || destination === liveDataDir ||
      destination.startsWith(liveDataDir+path.sep) || destination.startsWith(snapshotDir+path.sep) ||
      fs.existsSync(destination)) throw new Error('Fresh offline destination required');
  const openVerified = (file) => {
    const info = fs.lstatSync(file);
    if (!info.isFile() || info.isSymbolicLink()) throw new Error('Unsafe database');
    const db = new Database(file, { readonly: true, fileMustExist: true });
    if (db.pragma('quick_check', { simple: true }) !== 'ok') { db.close(); throw new Error('Invalid database'); }
    return db;
  };
  const currentManifest = openVerified(path.join(liveDataDir, 'deletion-manifest.sqlite'));
  const currentMembers = openVerified(path.join(liveDataDir, 'members.sqlite'));
  try {
    if (currentManifest.pragma('application_id', { simple: true }) !== 0x4f4e444d)
      throw new Error('Current deletion manifest required');
    const cutoff = currentManifest.prepare("SELECT value FROM deletion_control WHERE key='restore_not_before'").get()?.value;
    if (!cutoff || !Number.isFinite(Date.parse(cutoff)) || inspected.created < Date.parse(cutoff))
      throw new Error('Snapshot predates durable deletion tracking');
    const deleted = currentManifest.prepare('SELECT member_id FROM deleted_members').all();
    const liveFloor = currentMembers.prepare("SELECT seq FROM sqlite_sequence WHERE name='members'").get()?.seq ?? 0;
    const floor = deleted.reduce((max, row) => Math.max(max, row.member_id), liveFloor);
    fs.mkdirSync(destination, { mode: 0o700 });
    try {
      const source = openVerified(path.join(snapshotDir, 'members.sqlite'));
      try { await source.backup(path.join(destination, 'members.sqlite')); } finally { source.close(); }
      const staged = new Database(path.join(destination, 'members.sqlite'));
      try {
        staged.pragma('foreign_keys = ON');
        staged.pragma('secure_delete = ON');
        staged.transaction(() => {
          const remove = staged.prepare('DELETE FROM members WHERE id=?');
          for (const row of deleted) remove.run(row.member_id);
          // Re-registration after rollback must not reuse newer or deleted IDs.
          const saved = staged.prepare("SELECT seq FROM sqlite_sequence WHERE name='members'").get()?.seq ?? 0;
          if (floor > saved) {
            staged.prepare("INSERT INTO sqlite_sequence(name,seq) SELECT 'members',? WHERE NOT EXISTS(SELECT 1 FROM sqlite_sequence WHERE name='members')").run(floor);
            staged.prepare("UPDATE sqlite_sequence SET seq=? WHERE name='members'").run(floor);
          }
        }).immediate();
        staged.exec('VACUUM');
        if (staged.pragma('quick_check', { simple: true }) !== 'ok') throw new Error('Restore integrity failed');
      } finally { staged.close(); }
      fs.chmodSync(path.join(destination,'members.sqlite'),0o600);
      await currentManifest.backup(path.join(destination,'deletion-manifest.sqlite'));
      fs.chmodSync(path.join(destination,'deletion-manifest.sqlite'),0o600);
      const receipt = { version:'1.0.0-retention.1', mode:'offline-candidate', preparedAt:now.toISOString(),
        memberSequenceFloor:floor, deletionEntriesApplied:deleted.length, oldSessionsRestored:false,
        activationRequiresFreshManifestRecheck:true };
      fs.writeFileSync(path.join(destination,'restore-review.json'),JSON.stringify(receipt,null,2)+'\n',{mode:0o600});
      return receipt;
    } catch(error) { fs.rmSync(destination,{recursive:true,force:true}); throw error; }
  } finally { currentManifest.close(); currentMembers.close(); }
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  console.error('Use prepareMemberRestore with explicit offline paths. Automatic production activation is disabled.');
  process.exitCode=1;
}
