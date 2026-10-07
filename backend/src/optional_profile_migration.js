// Run explicitly against a backed-up database, never during server startup.
export function migrateOptionalProfiles(db) {
  const columns = db.prepare('PRAGMA table_info(members)').all();
  if (!columns.find(column => column.name === 'phone')?.notnull) return false;
  const expected = ['id', 'name', 'phone', 'church_name', 'login_provider', 'provider_user_id', 'created_at', 'updated_at', 'terms_version', 'privacy_version', 'consented_at'];
  if (columns.length !== expected.length || expected.some(name => !columns.some(column => column.name === name))) {
    throw new Error('Unsupported member schema; migration requires review.');
  }
  if (db.prepare("SELECT name FROM sqlite_master WHERE tbl_name = 'members' AND (type = 'trigger' OR (type = 'index' AND sql IS NOT NULL))").all().length) {
    throw new Error('Custom member indexes or triggers require migration review.');
  }
  const sequence = db.prepare("SELECT seq FROM sqlite_sequence WHERE name = 'members'").get()?.seq ?? 0;
  db.pragma('foreign_keys = OFF');
  try {
    db.transaction(() => {
      db.exec(`CREATE TABLE members_optional (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        phone TEXT UNIQUE, church_name TEXT NOT NULL,
        login_provider TEXT NOT NULL DEFAULT 'phone', provider_user_id TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        terms_version TEXT, privacy_version TEXT, consented_at TEXT
      );
      INSERT INTO members_optional SELECT id, name, phone, church_name, login_provider,
        provider_user_id, created_at, updated_at, terms_version, privacy_version, consented_at FROM members;
      DROP TABLE members;
      ALTER TABLE members_optional RENAME TO members;`);
      db.prepare("UPDATE sqlite_sequence SET seq = MAX(seq, ?) WHERE name = 'members'").run(sequence);
      if (db.pragma('foreign_key_check').length) throw new Error('Foreign key check failed.');
    })();
    return true;
  } finally { db.pragma('foreign_keys = ON'); }
}
