import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import Database from 'better-sqlite3';
import { backupDatabases } from '../scripts/backup_databases.js';

function makeDb(file, table, value) {
  const db = new Database(file);
  db.exec(`CREATE TABLE ${table} (id INTEGER PRIMARY KEY, value TEXT NOT NULL)`);
  db.prepare(`INSERT INTO ${table} (value) VALUES (?)`).run(value);
  db.close();
}

test('periodic backup creates verified independent SQLite snapshots and manifest', async t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-periodic-backup-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const sourceDir = path.join(root, 'live');
  const backupRoot = path.join(root, 'backups');
  fs.mkdirSync(sourceDir);

  makeDb(path.join(sourceDir, 'members.sqlite'), 'members', 'member');
  makeDb(path.join(sourceDir, 'member-sessions.sqlite'), 'sessions', 'session');
  makeDb(path.join(sourceDir, 'ai_usage.sqlite'), 'usage', 'usage');
  makeDb(path.join(sourceDir, 'deletion-manifest.sqlite'), 'deleted_members', 'deleted');

  const now = new Date('2026-10-10T06:00:00.000Z');
  const result = await backupDatabases({ sourceDir, backupRoot, now });

  assert.equal(result.manifest.files.length, 4);
  assert.equal(path.dirname(result.destination), backupRoot);
  assert.equal(fs.statSync(result.destination).mode & 0o777, 0o700);

  for (const entry of result.manifest.files) {
    assert.equal(entry.quickCheck, 'ok');
    assert.match(entry.sha256, /^[a-f0-9]{64}$/);
    const copied = path.join(result.destination, entry.name);
    assert.ok(fs.existsSync(copied));
    assert.equal(fs.statSync(copied).mode & 0o777, 0o600);
  }

  const manifestPath = path.join(result.destination, 'manifest.json');
  assert.equal(fs.statSync(manifestPath).mode & 0o777, 0o600);
  const saved = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  assert.equal(saved.createdAt, now.toISOString());

  const live = new Database(path.join(sourceDir, 'members.sqlite'));
  live.prepare('INSERT INTO members (value) VALUES (?)').run('newer');
  live.close();

  const snapshot = new Database(path.join(result.destination, 'members.sqlite'), { readonly: true });
  assert.equal(snapshot.prepare('SELECT COUNT(*) AS n FROM members').get().n, 1);
  snapshot.close();
});

test('periodic backup rejects backup directory inside live data and cleans partial output on failure', async t => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'onaria-periodic-backup-fail-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const sourceDir = path.join(root, 'live');
  fs.mkdirSync(sourceDir);

  await assert.rejects(
    backupDatabases({ sourceDir, backupRoot: path.join(sourceDir, 'backups') }),
    /separate from live data/,
  );

  makeDb(path.join(sourceDir, 'members.sqlite'), 'members', 'member');
  const backupRoot = path.join(root, 'backups');
  await assert.rejects(
    backupDatabases({
      sourceDir,
      backupRoot,
      files: ['members.sqlite', 'missing.sqlite'],
      now: new Date('2026-10-10T07:00:00.000Z'),
    }),
  );
  assert.deepEqual(fs.existsSync(backupRoot) ? fs.readdirSync(backupRoot) : [], []);
});
