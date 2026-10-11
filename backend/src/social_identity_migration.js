import { createHash } from 'node:crypto';
import { migrateOptionalProfiles } from './optional_profile_migration.js';

function unique(db, table, names) {
  return db.pragma(`index_list('${table}')`).some(index => {
    if (!index.unique || index.partial) return false;
    const escaped = index.name.replaceAll("'", "''");
    return JSON.stringify(db.pragma(`index_info('${escaped}')`).map(row => row.name)) === JSON.stringify(names);
  });
}
export function checkSocialIdentitySchema(db) {
  const phone = db.pragma('table_info(members)').find(row => row.name === 'phone');
  if (!phone) throw new Error('Unsupported member schema');
  const duplicateGroups = db.prepare('SELECT COUNT(*) AS n FROM (SELECT member_id, provider FROM member_identities GROUP BY member_id, provider HAVING COUNT(*) > 1)').get().n;
  if (duplicateGroups) throw new Error('Duplicate member/provider ownership requires explicit review; no rows changed');
  if (db.pragma('integrity_check', { simple: true }) !== 'ok' || db.pragma('foreign_key_check').length) throw new Error('Database integrity check failed');
  return {
    phoneNullable: !phone.notnull,
    phoneUnique: unique(db, 'members', ['phone']),
    identityUnique: unique(db, 'member_identities', ['provider', 'provider_user_id']),
    memberProviderUnique: unique(db, 'member_identities', ['member_id', 'provider']),
    members: db.prepare('SELECT COUNT(*) AS n FROM members').get().n,
    identities: db.prepare('SELECT COUNT(*) AS n FROM member_identities').get().n,
  };
}
function snapshot(db) {
  // Internal digest only. Never emit member/profile/identity contents.
  return createHash('sha256').update(JSON.stringify({
    members: db.prepare('SELECT * FROM members ORDER BY id').all(),
    identities: db.prepare('SELECT * FROM member_identities ORDER BY id').all(),
    sequences: db.prepare("SELECT name, seq FROM sqlite_sequence WHERE name IN ('members','member_identities') ORDER BY name").all(),
  })).digest('hex');
}
export function migrateSocialIdentities(db) {
  const before = checkSocialIdentitySchema(db);
  if (before.phoneNullable && !before.phoneUnique && before.identityUnique && before.memberProviderUnique) return false;
  if (!before.identityUnique) throw new Error('Unsupported identity ownership schema');
  const digest = snapshot(db);
  db.pragma('foreign_keys = OFF');
  try {
    db.transaction(() => {
      // Nested transaction keeps both changes atomic; helper re-enables FK afterwards.
      migrateOptionalProfiles(db);
      db.exec('CREATE UNIQUE INDEX IF NOT EXISTS member_identities_member_provider_unique ON member_identities(member_id, provider)');
      if (snapshot(db) !== digest) throw new Error('Migration changed existing data or sequences');
      const after = checkSocialIdentitySchema(db);
      if (!after.phoneNullable || after.phoneUnique || !after.memberProviderUnique) throw new Error('Migration postcondition failed');
    }).immediate();
  } finally { db.pragma('foreign_keys = ON'); }
  return true;
}
