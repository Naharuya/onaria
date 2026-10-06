import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';
import { adminMember } from './member_schema.js';

const socialProviders = new Set(['apple', 'naver', 'kakao', 'google']);

export function createMemberStore({ filename = path.resolve('data', 'members.sqlite') } = {}) {
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  const db = new Database(filename);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  db.exec(`
    CREATE TABLE IF NOT EXISTS members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL UNIQUE,
      church_name TEXT NOT NULL,
      login_provider TEXT NOT NULL DEFAULT 'phone',
      provider_user_id TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS member_identities (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
      provider TEXT NOT NULL,
      provider_user_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(provider, provider_user_id)
    );
    CREATE INDEX IF NOT EXISTS member_identities_member_id
      ON member_identities(member_id);
  `);

  db.exec(`
    INSERT OR IGNORE INTO member_identities (member_id, provider, provider_user_id)
    SELECT id, login_provider, provider_user_id
    FROM members
    WHERE provider_user_id IS NOT NULL
      AND login_provider IN ('apple', 'naver', 'kakao', 'google');
  `);

  const findByPhone = db.prepare('SELECT * FROM members WHERE phone = ?');
  const findIdentity = db.prepare(`
    SELECT m.*
    FROM member_identities i
    JOIN members m ON m.id = i.member_id
    WHERE i.provider = ? AND i.provider_user_id = ?
  `);
  const identityOwner = db.prepare(`
    SELECT member_id FROM member_identities
    WHERE provider = ? AND provider_user_id = ?
  `);
  const insertIdentity = db.prepare(`
    INSERT INTO member_identities (member_id, provider, provider_user_id)
    VALUES (?, ?, ?)
  `);
  const countMembers = db.prepare('SELECT COUNT(*) AS count FROM members');
  const recentMembers = db.prepare(`
    SELECT id, name, phone, church_name, login_provider, created_at
    FROM members ORDER BY id DESC LIMIT ?
  `);
  const insert = db.prepare(`
    INSERT INTO members (name, phone, church_name, login_provider, provider_user_id)
    VALUES (@name, @phone, @churchName, @loginProvider, @providerUserId)
  `);
  const deleteById = db.prepare('DELETE FROM members WHERE id = ?');
  const findById = db.prepare('SELECT * FROM members WHERE id = ?');

  const transactionCreate = db.transaction(member => {
    if (findByPhone.get(member.phone)) {
      const error = new Error('이미 가입된 휴대폰 번호입니다. 기존 계정으로 로그인한 뒤 소셜 계정을 연결해 주세요.');
      error.code = 'PHONE_EXISTS';
      throw error;
    }
    const result = insert.run({ ...member, providerUserId: member.providerUserId ?? null });
    const created = findById.get(result.lastInsertRowid);
    if (member.providerUserId && socialProviders.has(member.loginProvider)) {
      insertIdentity.run(created.id, member.loginProvider, member.providerUserId);
    }
    return created;
  });

  return {
    create(member) {
      return transactionCreate(member);
    },
    findByProviderIdentity(loginProvider, providerUserId) {
      if (!socialProviders.has(loginProvider)
        || typeof providerUserId !== 'string'
        || !providerUserId
        || providerUserId.length > 200) return null;
      return findIdentity.get(loginProvider, providerUserId) ?? null;
    },
    attachIdentity(memberId, loginProvider, providerUserId) {
      if (!Number.isSafeInteger(memberId) || memberId < 1
        || !socialProviders.has(loginProvider)
        || typeof providerUserId !== 'string'
        || !providerUserId
        || providerUserId.length > 200) return null;
      const member = findById.get(memberId);
      if (!member) return null;
      const owner = identityOwner.get(loginProvider, providerUserId);
      if (owner && owner.member_id !== memberId) {
        const error = new Error('이미 다른 회원 계정에 연결된 소셜 계정입니다.');
        error.code = 'IDENTITY_EXISTS';
        throw error;
      }
      if (!owner) insertIdentity.run(memberId, loginProvider, providerUserId);
      return member;
    },
    deleteById(memberId) {
      if (!Number.isSafeInteger(memberId) || memberId < 1) return false;
      return deleteById.run(memberId).changes === 1;
    },
    getAdminOverview({ limit = 8 } = {}) {
      return {
        total: countMembers.get().count,
        recent: recentMembers.all(limit).map(adminMember),
      };
    },
    close() {
      db.close();
    },
  };
}
