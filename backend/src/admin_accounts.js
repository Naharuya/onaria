import { randomBytes, scrypt as scryptCb, timingSafeEqual, randomUUID } from 'node:crypto';
import { promisify } from 'node:util';
import Database from 'better-sqlite3';
import { isRole } from './admin_rbac.js';

const scrypt = promisify(scryptCb);
const MAX_FAILURES = 5;
const LOCK_MS = 15 * 60_000;
const USERNAME = /^[a-z0-9][a-z0-9._-]{2,39}$/;

async function hashPassword(password, salt = randomBytes(16)) {
  const key = await scrypt(password, salt, 64);
  return `${salt.toString('base64')}:${key.toString('base64')}`;
}

// App-isolated admin accounts. Passwords are scrypt hashes; roles are re-read on every request
// by adminAuth so a role change or disable takes effect immediately.
export function createAdminAccounts({ filename = ':memory:', now = () => Date.now() } = {}) {
  const db = new Database(filename);
  db.pragma('journal_mode = WAL');
  db.exec(`CREATE TABLE IF NOT EXISTS admin_accounts (
    id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE, role TEXT NOT NULL, password_hash TEXT NOT NULL,
    disabled INTEGER NOT NULL DEFAULT 0, failed_count INTEGER NOT NULL DEFAULT 0, locked_until INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL)`);
  const publicRow = r => r && ({ id: r.id, username: r.username, role: r.role, disabled: Boolean(r.disabled) });
  const dummy = hashPassword('unknown-account-placeholder');
  return {
    async create({ username, password, role }) {
      if (!USERNAME.test(username ?? '')) throw Object.assign(new Error('invalid username'), { code: 'INVALID_USERNAME' });
      if (typeof password !== 'string' || password.length < 12 || password.length > 200) throw Object.assign(new Error('weak password'), { code: 'WEAK_PASSWORD' });
      if (!isRole(role)) throw Object.assign(new Error('invalid role'), { code: 'INVALID_ROLE' });
      const id = randomUUID();
      try {
        db.prepare('INSERT INTO admin_accounts (id, username, role, password_hash, created_at) VALUES (?, ?, ?, ?, ?)')
          .run(id, username, role, await hashPassword(password), new Date(now()).toISOString());
      } catch (error) {
        if (String(error.code).startsWith('SQLITE_CONSTRAINT')) throw Object.assign(new Error('username exists'), { code: 'USERNAME_EXISTS' });
        throw error;
      }
      return publicRow(this.get(id));
    },
    async authenticate(username, password) {
      const row = db.prepare('SELECT * FROM admin_accounts WHERE username = ?').get(String(username ?? ''));
      const [saltText, keyText] = (row?.password_hash ?? await dummy).split(':');
      const expected = Buffer.from(keyText, 'base64');
      const actual = await scrypt(String(password ?? ''), Buffer.from(saltText, 'base64'), 64);
      const matches = timingSafeEqual(expected, actual);
      if (!row || row.disabled || row.locked_until > now()) return null;
      if (!matches) {
        const failed = row.failed_count + 1;
        db.prepare('UPDATE admin_accounts SET failed_count = ?, locked_until = ? WHERE id = ?')
          .run(failed >= MAX_FAILURES ? 0 : failed, failed >= MAX_FAILURES ? now() + LOCK_MS : 0, row.id);
        return null;
      }
      db.prepare('UPDATE admin_accounts SET failed_count = 0 WHERE id = ?').run(row.id);
      return publicRow(row);
    },
    get: id => publicRow(db.prepare('SELECT * FROM admin_accounts WHERE id = ?').get(id)),
    list: () => db.prepare('SELECT * FROM admin_accounts ORDER BY created_at').all().map(publicRow),
    setRole(id, role) {
      if (!isRole(role)) throw Object.assign(new Error('invalid role'), { code: 'INVALID_ROLE' });
      return db.prepare('UPDATE admin_accounts SET role = ? WHERE id = ?').run(role, id).changes === 1;
    },
    setDisabled: (id, disabled) => db.prepare('UPDATE admin_accounts SET disabled = ? WHERE id = ?').run(disabled ? 1 : 0, id).changes === 1,
    close() { db.close(); },
  };
}
