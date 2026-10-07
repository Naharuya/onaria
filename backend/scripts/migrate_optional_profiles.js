import Database from 'better-sqlite3';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { migrateOptionalProfiles } from '../src/optional_profile_migration.js';

// No defaults: callers must select a database and explicitly approve applying.
process.umask(0o077);
const [filename, action, backup] = process.argv.slice(2);
if (!filename || !path.isAbsolute(filename) || !['--check', '--apply'].includes(action)
  || (action === '--apply' && (!backup || !path.isAbsolute(backup) || existsSync(backup)))) {
  throw new Error('Usage: node scripts/migrate_optional_profiles.js /absolute/db --check | --apply /absolute/new-backup');
}
const db = new Database(filename, { fileMustExist: true, readonly: action === '--check' });
try {
  const required = Boolean(db.prepare('PRAGMA table_info(members)').all().find(column => column.name === 'phone')?.notnull);
  if (action === '--check') console.log(JSON.stringify({ migrationRequired: required }));
  else {
    if (required) await db.backup(backup);
    console.log(JSON.stringify({ migrated: migrateOptionalProfiles(db) }));
  }
} finally { db.close(); }
