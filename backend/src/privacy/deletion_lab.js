// 격리 검증 전용: 운영 저장소/라우트와 연결하지 않는다.
import Database from 'better-sqlite3';
export function createDeletionLab() {
  const db = new Database(':memory:');
  db.exec(`CREATE TABLE accounts(generation TEXT PRIMARY KEY, state TEXT NOT NULL);
    CREATE TABLE records(generation TEXT, value TEXT);
    CREATE TABLE sessions(generation TEXT, token TEXT);
    CREATE TABLE jobs(generation TEXT PRIMARY KEY, done INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE manifest(generation TEXT PRIMARY KEY);`);
  let connected = false;
  const ensureGeneration = generation => { if (typeof generation !== 'string' || !generation) throw new Error('계정 세대 필요'); };
  const api = {
    register(generation) { ensureGeneration(generation); db.prepare("INSERT INTO accounts VALUES (?, 'active')").run(generation); },
    addRecord(generation, value) { if (!api.canAccess(generation)) throw new Error('접근 차단'); db.prepare('INSERT INTO records VALUES (?,?)').run(generation,value); },
    issue(generation, token) {
      if (!api.canAccess(generation)) throw new Error('발급 차단');
      db.prepare('INSERT INTO sessions VALUES (?,?)').run(generation,token);
    },
    canAccess(generation) { return db.prepare('SELECT state FROM accounts WHERE generation=?').get(generation)?.state === 'active'; },
    request(generation) {
      ensureGeneration(generation);
      db.transaction(() => {
        if (!db.prepare('SELECT 1 FROM accounts WHERE generation=?').get(generation) && !db.prepare('SELECT 1 FROM jobs WHERE generation=?').get(generation)) throw new Error('계정 없음');
        db.prepare("UPDATE accounts SET state='deleting' WHERE generation=?").run(generation);
        db.prepare('INSERT OR IGNORE INTO jobs(generation) VALUES (?)').run(generation);
        db.prepare('DELETE FROM sessions WHERE generation=?').run(generation);
        // 파기 도중 중단돼도 이전 백업에서 active로 복원되지 않도록 접수 시 기록.
        db.prepare('INSERT OR IGNORE INTO manifest VALUES (?)').run(generation);
      })();
    },
    run(generation, { failAt } = {}) {
      const job = db.prepare('SELECT done FROM jobs WHERE generation=?').get(generation);
      if (!job) throw new Error('작업 없음');
      if (job.done) return 'already-complete';
      db.transaction(() => {
        db.prepare('DELETE FROM records WHERE generation=?').run(generation);
        if (failAt === 'records') throw new Error('모의 저장 실패');
        db.prepare('DELETE FROM sessions WHERE generation=?').run(generation);
        db.prepare('DELETE FROM accounts WHERE generation=?').run(generation);
        if (failAt === 'account') throw new Error('모의 저장 실패');
        db.prepare('UPDATE jobs SET done=1 WHERE generation=?').run(generation);
      })();
      return 'complete';
    },
    snapshot() { return { accounts: db.prepare('SELECT * FROM accounts').all(), records: db.prepare('SELECT * FROM records').all(), sessions: db.prepare('SELECT * FROM sessions').all() }; },
    manifest() { return db.prepare('SELECT generation FROM manifest ORDER BY generation').all().map(x=>x.generation); },
    restore(snapshot, { manifest, verified = false } = {}) {
      connected = false;
      if (!verified || !Array.isArray(manifest) || manifest.some(x=>typeof x !== 'string' || !x)
        || api.manifest().some(generation => !manifest.includes(generation))) throw new Error('삭제 명부 대조 실패');
      db.transaction(() => {
        db.exec('DELETE FROM accounts; DELETE FROM records; DELETE FROM sessions;');
        for (const row of snapshot.accounts) db.prepare('INSERT INTO accounts VALUES (?,?)').run(row.generation,row.state);
        for (const row of snapshot.records) db.prepare('INSERT INTO records VALUES (?,?)').run(row.generation,row.value);
        for (const row of snapshot.sessions) db.prepare('INSERT INTO sessions VALUES (?,?)').run(row.generation,row.token);
        for (const generation of manifest) {
          for (const table of ['accounts','records','sessions']) db.prepare(`DELETE FROM ${table} WHERE generation=?`).run(generation);
        }
      })();
      connected = true;
    },
    connected() { return connected; },
    close() { db.close(); },
  };
  return api;
}
