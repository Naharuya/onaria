import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import os from 'node:os';import path from 'node:path';import Database from 'better-sqlite3';
import {createSqliteUsageLedger} from '../src/cost/sqlite_usage_ledger.js';
import {deleteIsolatedCostRows} from '../src/privacy/isolated_cost_adapter.js';
test('실제 원장 schema에서 확인 없는 mapping/pending 차단 및 다른 owner 보존',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-deletion-'));const filename=path.join(root,'cost.sqlite');let ledger,db;
 try{
 ledger=createSqliteUsageLedger({filename});const a=ledger.reserve({userId:'fixture-old'});a.finish({tier:'local',provider:'local'});const b=ledger.reserve({userId:'fixture-new'});b.finish({tier:'local',provider:'local'});ledger.close();ledger=null;
 db=new Database(filename);const rows=db.prepare('SELECT owner_id FROM cost_requests ORDER BY rowid').all();const ownerId=rows[0].owner_id;
 assert.throws(()=>deleteIsolatedCostRows({filename,ownerId}));
 db.prepare("UPDATE cost_requests SET state='pending' WHERE owner_id=?").run(ownerId);assert.throws(()=>deleteIsolatedCostRows({filename,ownerId,associationVerified:true}));
 db.prepare("UPDATE cost_requests SET state='finished' WHERE owner_id=?").run(ownerId);
 assert.equal(deleteIsolatedCostRows({filename,ownerId,associationVerified:true}),1);assert.equal(deleteIsolatedCostRows({filename,ownerId,associationVerified:true}),0);
 assert.equal(db.prepare('SELECT count(*) n FROM cost_requests').get().n,1);
 }finally{ledger?.close();db?.close();fs.rmSync(root,{recursive:true,force:true});}
});
test('실제 FK cascade 실패는 전체 rollback, 해소 후 재시도는 다른 owner call 보존',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-deletion-'));const filename=path.join(root,'cost.sqlite');let ledger,db;
 try{
 ledger=createSqliteUsageLedger({filename});
 for(const userId of ['fixture-old','fixture-new'])ledger.reserve({userId}).finish({tier:'local',provider:'local'});
 ledger.close();ledger=null;db=new Database(filename);const rows=db.prepare('SELECT id,owner_id FROM cost_requests ORDER BY rowid').all();
 rows.forEach((r,i)=>db.prepare('INSERT INTO cost_calls(id,request_id,model,model_tier) VALUES (?,?,?,?)').run('fixture-call-'+i,r.id,'fixture','local'));
 db.exec("CREATE TRIGGER fixture_fail BEFORE DELETE ON cost_calls BEGIN SELECT RAISE(ABORT,'fixture failure'); END");
 assert.throws(()=>deleteIsolatedCostRows({filename,ownerId:rows[0].owner_id,associationVerified:true}));
 assert.equal(db.prepare('SELECT count(*) n FROM cost_requests').get().n,2);assert.equal(db.prepare('SELECT count(*) n FROM cost_calls').get().n,2);
 db.exec('DROP TRIGGER fixture_fail');assert.equal(deleteIsolatedCostRows({filename,ownerId:rows[0].owner_id,associationVerified:true}),1);
 assert.equal(db.prepare('SELECT count(*) n FROM cost_calls').get().n,1);assert.equal(db.prepare('SELECT request_id FROM cost_calls').get().request_id,rows[1].id);
 }finally{ledger?.close();db?.close();fs.rmSync(root,{recursive:true,force:true});}
});
