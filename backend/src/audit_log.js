import { createHash } from 'node:crypto';
import Database from 'better-sqlite3';

const SENSITIVE_KEY = /token|password|passwd|secret|authorization|cookie|apikey|api_key|message|content|body|text|credential/i;
const GENESIS = '0'.repeat(64);
// Proposed policy: not a legally confirmed retention period until the operator approves it.
export const AUDIT_POLICY = Object.freeze({ version: 'audit-retention-2026-10-20-draft1', retentionDays: 365, status: 'PROPOSED_NOT_APPROVED' });
const OUTCOMES = new Set(['started', 'success', 'failure', 'denied']);

// Detail is an allow-list of short scalar values; free text and secrets are never stored.
export function sanitizeDetail(detail = {}) {
  const clean = {};
  for (const [key, value] of Object.entries(detail ?? {}).slice(0, 20)) {
    if (SENSITIVE_KEY.test(key)) continue;
    if (typeof value === 'string') clean[key] = value.slice(0, 120);
    else if (typeof value === 'number' || typeof value === 'boolean' || value === null) clean[key] = value;
  }
  return clean;
}

const rowHash = r => createHash('sha256')
  .update(JSON.stringify([r.prev_hash, r.ts, r.request_id, r.actor, r.role, r.action, r.target, r.outcome, r.detail]))
  .digest('hex');

// Append-only, hash-chained audit trail. Triggers reject UPDATE/DELETE so edits need
// schema-level access and are detectable by verify().
export function createAuditLog({ filename = ':memory:', now = () => new Date() } = {}) {
  const db = new Database(filename);
  db.pragma('journal_mode = WAL');
  db.exec(`CREATE TABLE IF NOT EXISTS audit_log (
    seq INTEGER PRIMARY KEY AUTOINCREMENT, ts TEXT NOT NULL, request_id TEXT NOT NULL, actor TEXT NOT NULL,
    role TEXT NOT NULL, action TEXT NOT NULL, target TEXT NOT NULL, outcome TEXT NOT NULL,
    detail TEXT NOT NULL, prev_hash TEXT NOT NULL, hash TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS audit_anchor (id INTEGER PRIMARY KEY CHECK (id = 1), seq INTEGER NOT NULL, hash TEXT NOT NULL, pruned_total INTEGER NOT NULL, pruned_at TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS audit_holds (id INTEGER PRIMARY KEY AUTOINCREMENT, reason_code TEXT NOT NULL, created_at TEXT NOT NULL, released_at TEXT);
    CREATE TRIGGER IF NOT EXISTS audit_log_no_update BEFORE UPDATE ON audit_log BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END;
    CREATE TRIGGER IF NOT EXISTS audit_log_no_delete BEFORE DELETE ON audit_log BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END;`);
  const NO_DELETE = "CREATE TRIGGER audit_log_no_delete BEFORE DELETE ON audit_log BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END;";
  const anchor = () => db.prepare('SELECT * FROM audit_anchor WHERE id = 1').get();
  const last = db.prepare('SELECT hash FROM audit_log ORDER BY seq DESC LIMIT 1');
  const insert = db.prepare(`INSERT INTO audit_log (ts, request_id, actor, role, action, target, outcome, detail, prev_hash, hash)
    VALUES (@ts, @request_id, @actor, @role, @action, @target, @outcome, @detail, @prev_hash, @hash)`);
  const append = db.transaction(entry => {
    const prev_hash = last.get()?.hash ?? anchor()?.hash ?? GENESIS;
    const row = { prev_hash, ...entry };
    insert.run({ ...row, hash: rowHash(row) });
  });
  return {
    record({ requestId = 'none', actor, role = 'none', action, target = '-', outcome, detail }) {
      if (!actor || !action || !OUTCOMES.has(outcome)) throw new TypeError('invalid audit entry');
      append({ ts: now().toISOString(), request_id: String(requestId).slice(0, 64), actor: String(actor).slice(0, 80),
        role: String(role).slice(0, 20), action: String(action).slice(0, 80), target: String(target).slice(0, 120),
        outcome, detail: JSON.stringify({ ...sanitizeDetail(detail), policy_version: AUDIT_POLICY.version }) });
    },
    list({ limit = 100, action } = {}) {
      const rows = action
        ? db.prepare('SELECT * FROM audit_log WHERE action = ? ORDER BY seq DESC LIMIT ?').all(action, Math.min(limit, 500))
        : db.prepare('SELECT * FROM audit_log ORDER BY seq DESC LIMIT ?').all(Math.min(limit, 500));
      return rows.map(({ prev_hash, hash, detail, ...row }) => ({ ...row, detail: JSON.parse(detail) }));
    },
    verify() {
      const base = anchor();
      let prev = base?.hash ?? GENESIS;
      for (const row of db.prepare('SELECT * FROM audit_log ORDER BY seq').iterate()) {
        const { hash, seq, ...rest } = row;
        if (rest.prev_hash !== prev || rowHash(rest) !== hash) return { ok: false, brokenAt: seq };
        prev = hash;
      }
      return { ok: true, brokenAt: null };
    },
    placeLegalHold(reasonCode) {
      if (!/^[A-Z0-9_]{3,40}$/.test(reasonCode ?? '')) throw new TypeError('reasonCode must be an upper-case code');
      return Number(db.prepare('INSERT INTO audit_holds (reason_code, created_at) VALUES (?, ?)').run(reasonCode, now().toISOString()).lastInsertRowid);
    },
    releaseLegalHold(id) { return db.prepare('UPDATE audit_holds SET released_at = ? WHERE id = ? AND released_at IS NULL').run(now().toISOString(), id).changes === 1; },
    activeHolds: () => db.prepare('SELECT id, reason_code, created_at FROM audit_holds WHERE released_at IS NULL').all(),
    // Removes only an expired, contiguous prefix of the chain and stores its last hash as the new anchor,
    // so verify() still proves integrity of everything that remains. Blocked while a legal hold is active.
    pruneExpired({ retentionDays = AUDIT_POLICY.retentionDays, dryRun = true } = {}) {
      if (!Number.isInteger(retentionDays) || retentionDays < 30) throw new RangeError('retentionDays must be an integer >= 30');
      if (db.prepare('SELECT 1 FROM audit_holds WHERE released_at IS NULL LIMIT 1').get()) return { pruned: 0, blocked: 'LEGAL_HOLD' };
      const cutoff = new Date(now().getTime() - retentionDays * 86_400_000).toISOString();
      const first = db.prepare('SELECT MIN(seq) AS seq FROM audit_log WHERE ts >= ?').get(cutoff).seq;
      const edge = first === null ? db.prepare('SELECT MAX(seq) AS seq FROM audit_log').get().seq : first - 1;
      const doomed = db.prepare('SELECT COUNT(*) AS n FROM audit_log WHERE seq <= ?').get(edge ?? 0).n;
      if (!edge || doomed === 0) return { pruned: 0, blocked: null };
      if (dryRun) return { pruned: 0, wouldPrune: doomed, blocked: null };
      db.transaction(() => {
        const tail = db.prepare('SELECT seq, hash FROM audit_log WHERE seq = ?').get(edge);
        const total = (anchor()?.pruned_total ?? 0) + doomed;
        db.exec('DROP TRIGGER audit_log_no_delete');
        db.prepare('DELETE FROM audit_log WHERE seq <= ?').run(edge);
        db.exec(NO_DELETE);
        db.prepare(`INSERT INTO audit_anchor (id, seq, hash, pruned_total, pruned_at) VALUES (1, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET seq = excluded.seq, hash = excluded.hash, pruned_total = excluded.pruned_total, pruned_at = excluded.pruned_at`)
          .run(tail.seq, tail.hash, total, now().toISOString());
      })();
      return { pruned: doomed, blocked: null };
    },
    anchorInfo: () => { const a = anchor(); return a ? { seq: a.seq, prunedTotal: a.pruned_total, prunedAt: a.pruned_at } : null; },
    count: () => db.prepare('SELECT COUNT(*) AS n FROM audit_log').get().n,
    close() { db.close(); },
  };
}
