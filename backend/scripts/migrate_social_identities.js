import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';
import { checkSocialIdentitySchema, migrateSocialIdentities } from '../src/social_identity_migration.js';

const [mode, filename, backup] = process.argv.slice(2);
if (!['--check', '--apply'].includes(mode) || !path.isAbsolute(filename ?? '') || !fs.existsSync(filename)
  || (mode === '--apply' && (!path.isAbsolute(backup ?? '') || fs.existsSync(backup) || backup === filename))) {
  throw new Error('Usage: --check /absolute/members.sqlite OR --apply /absolute/members.sqlite /absolute/new-backup.sqlite');
}
const db = new Database(filename, { readonly: mode === '--check', fileMustExist: true });
try {
  const before = checkSocialIdentitySchema(db);
  const required = !before.phoneNullable || before.phoneUnique || !before.memberProviderUnique;
  if (mode === '--apply' && required) {
    await db.backup(backup);
    fs.chmodSync(backup, 0o600);
    const backupDb = new Database(backup, { readonly: true, fileMustExist: true });
    try { checkSocialIdentitySchema(backupDb); } finally { backupDb.close(); }
    migrateSocialIdentities(db);
  }
  console.log(JSON.stringify({ mode, required, changed: mode === '--apply' && required, before, after: checkSocialIdentitySchema(db) }));
} finally { db.close(); }
