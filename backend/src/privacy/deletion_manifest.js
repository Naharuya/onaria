import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';

export function createDeletionManifest({ filename = path.resolve('data', 'deletion-manifest.sqlite'), now = () => new Date() } = {}) {
  fs.mkdirSync(path.dirname(filename), { recursive: true, mode: 0o700 });
  const db = new Database(filename);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  db.pragma('application_id = 0x4f4e444d'); // ONDM
  db.exec(`
    CREATE TABLE IF NOT EXISTS deletion_control (
      key TEXT PRIMARY KEY, value TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS deleted_members (
      member_id INTEGER PRIMARY KEY,
      deleted_at TEXT NOT NULL
    );
  `);
  const initializedAt = now();
  if (!(initializedAt instanceof Date) || Number.isNaN(initializedAt.getTime())) { db.close(); throw new TypeError('Invalid deletion time'); }
  db.prepare("INSERT OR IGNORE INTO deletion_control(key,value) VALUES ('restore_not_before',?)").run(initializedAt.toISOString());
  try { fs.chmodSync(filename, 0o600); } catch {}

  const mark = db.prepare('INSERT OR IGNORE INTO deleted_members (member_id, deleted_at) VALUES (?, ?)');
  const has = db.prepare('SELECT 1 FROM deleted_members WHERE member_id = ?');
  const all = db.prepare('SELECT member_id AS memberId, deleted_at AS deletedAt FROM deleted_members ORDER BY member_id');

  function validateMemberId(memberId) {
    if (!Number.isSafeInteger(memberId) || memberId < 1) throw new TypeError('Invalid member id');
  }

  return {
    record(memberId) {
      validateMemberId(memberId);
      const stamp = now();
      if (!(stamp instanceof Date) || Number.isNaN(stamp.getTime())) throw new TypeError('Invalid deletion time');
      mark.run(memberId, stamp.toISOString());
    },
    recordMany(memberIds) {
      if (!Array.isArray(memberIds) || !memberIds.length) throw new TypeError('Member ids required');
      memberIds.forEach(validateMemberId);
      const stamp = now();
      if (!(stamp instanceof Date) || Number.isNaN(stamp.getTime())) throw new TypeError('Invalid deletion time');
      db.transaction(() => { for (const id of memberIds) mark.run(id, stamp.toISOString()); }).immediate();
    },
    contains(memberId) {
      validateMemberId(memberId);
      return Boolean(has.get(memberId));
    },
    entries() {
      return all.all();
    },
    reapply(memberStore) {
      if (!memberStore || typeof memberStore.deleteById !== 'function') throw new TypeError('Member store required');
      let removed = 0;
      for (const { memberId } of all.all()) {
        if (memberStore.deleteById(memberId)) removed += 1;
      }
      return removed;
    },
    close() { db.close(); },
  };
}
