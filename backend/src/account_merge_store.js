import { createHash, randomBytes } from 'node:crypto';
import { planAccountMerge } from './account_merge_plan.js';

export class AccountMergeError extends Error {
  constructor(code, status = 409) {
    super('계정 통합을 완료하지 못했어요. 계정을 다시 확인해 주세요.');
    this.code = code; this.status = status;
  }
}
export const mergeHash = value => createHash('sha256').update(value).digest('hex');

// Uses the member database transaction; never persists provider credentials.
export function createAccountMergeStore(db, { now = Date.now } = {}) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS member_aliases (
      source_id INTEGER PRIMARY KEY REFERENCES members(id) ON DELETE CASCADE,
      canonical_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
      CHECK(source_id != canonical_id)
    );
    CREATE INDEX IF NOT EXISTS member_aliases_canonical ON member_aliases(canonical_id);
    CREATE TABLE IF NOT EXISTS account_merge_attempts (
      attempt_hash TEXT PRIMARY KEY,
      target_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
      source_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
      session_hash TEXT NOT NULL,
      snapshot_hash TEXT NOT NULL,
      expires_at INTEGER NOT NULL,
      status TEXT NOT NULL CHECK(status IN ('pending', 'completed')),
      completed_at INTEGER
    );
  `);
  const canonical = id => Boolean(db.prepare('SELECT 1 FROM members WHERE id=? AND NOT EXISTS (SELECT 1 FROM member_aliases WHERE source_id=?)').get(id,id));
  const owners = id => canonical(id)
    ? [id, ...db.prepare('SELECT source_id FROM member_aliases WHERE canonical_id=? ORDER BY source_id').all(id).map(r=>r.source_id)].sort((a,b)=>a-b) : [];
  const details = id => db.prepare('SELECT member_id AS memberId,provider,provider_user_id AS providerUserId FROM member_identities WHERE member_id=? ORDER BY provider').all(id);
  function snapshot(targetId, sourceId) {
    if (!canonical(targetId) || !canonical(sourceId)) throw new AccountMergeError('MERGE_ACCOUNT_CHANGED');
    let plan;
    try { plan = planAccountMerge({members:[{id:targetId},{id:sourceId}], identities:[...details(targetId),...details(sourceId)],targetId,sourceIds:[sourceId]}); }
    catch (e) { throw new AccountMergeError(e.message); }
    const recordOwnerIds = [...owners(targetId),...owners(sourceId)].sort((a,b)=>a-b);
    if (recordOwnerIds.length>100) throw new AccountMergeError('MERGE_ACCOUNT_LIMIT');
    return { providers:plan.providers, recordOwnerIds,
      hash:mergeHash(JSON.stringify({targetId,sourceId,identities:[...details(targetId),...details(sourceId)],recordOwnerIds})) };
  }
  function attempt(token, targetId, sessionHash) {
    if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) throw new AccountMergeError('INVALID_MERGE_ATTEMPT',400);
    const row=db.prepare('SELECT * FROM account_merge_attempts WHERE attempt_hash=?').get(mergeHash(token));
    if (!row || row.target_id!==targetId || row.session_hash!==sessionHash) throw new AccountMergeError('INVALID_MERGE_ATTEMPT',403);
    if (row.status!=='pending') throw new AccountMergeError('MERGE_ALREADY_COMPLETED');
    if (row.expires_at<=now()) throw new AccountMergeError('MERGE_ATTEMPT_EXPIRED',410);
    const snap=snapshot(row.target_id,row.source_id);
    if (snap.hash!==row.snapshot_hash) throw new AccountMergeError('MERGE_ACCOUNT_CHANGED');
    return {row,snap};
  }
  return {
    recordOwnerIds: owners,
    prepare(targetId, sourceId, sessionHash, proofs, verifySession) {
      if (typeof sessionHash !== 'string' || !/^[a-f0-9]{64}$/.test(sessionHash)) throw new AccountMergeError('INVALID_SESSION_BINDING',400);
      return db.transaction(()=>{
        if (typeof verifySession!=='function' || !proofs?.targetProof || !proofs?.sourceProof) throw new AccountMergeError('MERGE_PROOFS_REQUIRED',401);
        verifySession();
        for (const [proof,ownerId] of [[proofs.targetProof,targetId],[proofs.sourceProof,sourceId]]) {
          const owner=db.prepare('SELECT member_id FROM member_identities WHERE provider=? AND provider_user_id=?').get(proof.provider,proof.providerUserId);
          if (owner?.member_id!==ownerId) throw new AccountMergeError('MERGE_ACCOUNT_CHANGED');
        }
        const snap=snapshot(targetId,sourceId);
        db.prepare("DELETE FROM account_merge_attempts WHERE (status='pending' AND expires_at<?) OR (status='completed' AND completed_at<?)").run(now(),now()-365*86400000);
        // At most one pending attempt for this session; repeated prepare invalidates the old prompt.
        db.prepare("DELETE FROM account_merge_attempts WHERE session_hash=? AND status='pending'").run(sessionHash);
        const attemptToken=randomBytes(32).toString('base64url'), expiresAt=now()+120000;
        db.prepare("INSERT INTO account_merge_attempts(attempt_hash,target_id,source_id,session_hash,snapshot_hash,expires_at,status) VALUES(?,?,?,?,?,?,'pending')")
          .run(mergeHash(attemptToken),targetId,sourceId,sessionHash,snap.hash,expiresAt);
        return {attemptToken,targetId,sourceId,providers:snap.providers,recordOwnerIds:snap.recordOwnerIds,expiresAt};
      }).immediate();
    },
    confirm(token,targetId,sessionHash,revokeIdentities) {
      return db.transaction(()=>{
        const {row,snap}=attempt(token,targetId,sessionHash);
        // Synchronous, fail-closed revocation of both members' old sessions.
        // If the separate session DB fails, the member transaction rolls back.
        const result=revokeIdentities([...details(row.target_id),...details(row.source_id)]);
        if (result && typeof result.then==='function') throw new AccountMergeError('ASYNC_REVOCATION_NOT_SUPPORTED',503);
        db.prepare('UPDATE member_identities SET member_id=? WHERE member_id=?').run(row.target_id,row.source_id);
        db.prepare('UPDATE member_aliases SET canonical_id=? WHERE canonical_id=?').run(row.target_id,row.source_id);
        db.prepare('INSERT INTO member_aliases(source_id,canonical_id) VALUES(?,?)').run(row.source_id,row.target_id);
        db.prepare("UPDATE account_merge_attempts SET status='completed',completed_at=? WHERE attempt_hash=?").run(now(),row.attempt_hash);
        return {targetId:row.target_id,sourceId:row.source_id,providers:snap.providers,recordOwnerIds:snap.recordOwnerIds,completed:true};
      }).immediate();
    },
    deleteFamily(id) {
      if (!canonical(id)) return false;
      return db.transaction(()=>{
        const ids=owners(id);
        for (const ownerId of ids.filter(x=>x!==id)) db.prepare('DELETE FROM members WHERE id=?').run(ownerId);
        return db.prepare('DELETE FROM members WHERE id=?').run(id).changes===1;
      }).immediate();
    },
  };
}
