import Database from 'better-sqlite3';
import fs from 'node:fs';import os from 'node:os';import path from 'node:path';
// 실제 cost schema 검증용. mapping은 확인된 association을 명시 전달해야 하며 provider/sub를 hash로 추측하지 않는다.
export function deleteIsolatedCostRows({filename,ownerId,associationVerified=false}={}){
 const file=fs.realpathSync(filename);const temporary=fs.realpathSync(os.tmpdir());
 if(!file.startsWith(temporary+path.sep)||!path.basename(path.dirname(file)).startsWith('onaria-deletion-'))throw new Error('격리 경로 필요');
 if(!associationVerified||typeof ownerId!=='string'||!ownerId||ownerId==='anonymous')throw new Error('확인된 연결 필요');
 const db=new Database(file,{fileMustExist:true});
 try{
 if(db.pragma('application_id',{simple:true})!==0x53424347)throw new Error('원장 schema 불일치');
 db.pragma('foreign_keys = ON');
 return db.transaction(()=>{
 if(db.prepare("SELECT 1 FROM cost_requests WHERE owner_id=? AND state='pending'").get(ownerId))throw new Error('예약 복구 선행 필요');
 return db.prepare('DELETE FROM cost_requests WHERE owner_id=?').run(ownerId).changes;
 }).immediate();
 }finally{db.close();}
}
