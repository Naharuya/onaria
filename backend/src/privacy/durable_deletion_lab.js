import Database from 'better-sqlite3';
import fs from 'node:fs';
import path from 'node:path';
// 호출자가 직접 만든 OS 임시 격리 폴더만 허용. 운영 adapter는 연결하지 않는다.
import os from 'node:os';
export function createDurableDeletionLab({ directory } = {}) {
 const root=fs.realpathSync(directory);const temporary=fs.realpathSync(os.tmpdir());
 if(!root.startsWith(temporary+path.sep)||!path.basename(root).startsWith('onaria-deletion-')) throw new Error('격리 경로 필요');
 const store=new Database(path.join(root,'store.sqlite'));const manifest=new Database(path.join(root,'manifest.sqlite'));
 store.pragma('journal_mode = WAL');manifest.pragma('journal_mode = WAL');
 store.exec(`CREATE TABLE IF NOT EXISTS accounts(g TEXT PRIMARY KEY,state TEXT NOT NULL);
 CREATE TABLE IF NOT EXISTS records(g TEXT,value TEXT);
 CREATE TABLE IF NOT EXISTS sessions(g TEXT);
 CREATE TABLE IF NOT EXISTS jobs(g TEXT PRIMARY KEY,done INTEGER NOT NULL DEFAULT 0);`);
 manifest.exec("CREATE TABLE IF NOT EXISTS deleted(g TEXT PRIMARY KEY); CREATE TABLE IF NOT EXISTS control(k TEXT PRIMARY KEY,n INTEGER); INSERT OR IGNORE INTO control VALUES ('watermark',0);");
 store.exec('CREATE TABLE IF NOT EXISTS cost_links(g TEXT,owner TEXT UNIQUE); CREATE TABLE IF NOT EXISTS cost_rows(owner TEXT,value TEXT);');
 let connected=false;
 const api={
 register(g){if(manifest.prepare('SELECT 1 FROM deleted WHERE g=?').get(g))throw new Error('세대 재사용 금지');store.prepare("INSERT INTO accounts VALUES (?,'active')").run(g);},
 issue(g){if(!api.access(g))throw new Error('발급 차단');store.prepare('INSERT INTO sessions VALUES (?)').run(g);},
 add(g,value){if(!api.access(g))throw new Error('접근 차단');store.prepare('INSERT INTO records VALUES (?,?)').run(g,value);},
 access(g){return !manifest.prepare('SELECT 1 FROM deleted WHERE g=?').get(g)&&store.prepare('SELECT state FROM accounts WHERE g=?').get(g)?.state==='active';},
 request(g){
 if(!store.prepare('SELECT 1 FROM accounts WHERE g=?').get(g)&&!store.prepare('SELECT 1 FROM jobs WHERE g=?').get(g))throw new Error('계정 없음');
 // 독립 명부 우선. 다음 store transaction 실패/재시작에도 access는 차단된다.
 manifest.transaction(()=>{const r=manifest.prepare('INSERT OR IGNORE INTO deleted VALUES (?)').run(g);if(r.changes)manifest.prepare("UPDATE control SET n=n+1 WHERE k='watermark'").run();})();
 store.transaction(()=>{store.prepare("UPDATE accounts SET state='deleting' WHERE g=?").run(g);store.prepare('INSERT OR IGNORE INTO jobs(g) VALUES (?)').run(g);store.prepare('DELETE FROM sessions WHERE g=?').run(g);})();
 },
 run(g,{fail=false}={}){
 if(!manifest.prepare('SELECT 1 FROM deleted WHERE g=?').get(g))throw new Error('명부 대조 실패');
 const job=store.prepare('SELECT done FROM jobs WHERE g=?').get(g);if(job?.done)return 'already-complete';
 return store.transaction(()=>{store.prepare('INSERT OR IGNORE INTO jobs(g) VALUES (?)').run(g);if(store.prepare('SELECT done FROM jobs WHERE g=?').get(g).done)return 'already-complete';store.prepare('DELETE FROM cost_rows WHERE owner IN (SELECT owner FROM cost_links WHERE g=?)').run(g);store.prepare('DELETE FROM cost_links WHERE g=?').run(g);for(const t of ['records','sessions','accounts'])store.prepare(`DELETE FROM ${t} WHERE g=?`).run(g);if(fail)throw new Error('모의 부분 실패');store.prepare('UPDATE jobs SET done=1 WHERE g=?').run(g);return 'complete';}).immediate();
 },
 resume(){for(const {g} of manifest.prepare('SELECT g FROM deleted').all())api.run(g);},
 watermark(){return manifest.prepare("SELECT n FROM control WHERE k='watermark'").get().n;},
 linkCost(g,owner,value){if(!api.access(g))throw new Error('접근 차단');store.transaction(()=>{store.prepare('INSERT INTO cost_links VALUES (?,?)').run(g,owner);store.prepare('INSERT INTO cost_rows VALUES (?,?)').run(owner,value);})();},
 costCount(){return store.prepare('SELECT count(*) n FROM cost_rows').get().n;},
 connect({manifestAvailable=true,minimumWatermark=0}={}){connected=false;if(!Number.isSafeInteger(minimumWatermark)||minimumWatermark<0||api.watermark()<minimumWatermark)throw new Error('명부 최신성 확인 실패');if(!manifestAvailable)throw new Error('명부 장애');for(const {g} of manifest.prepare('SELECT g FROM deleted').all())api.run(g);connected=true;},
 connected(){return connected;},
 count(){return store.prepare('SELECT count(*) n FROM records').get().n;},
 close(){store.close();manifest.close();}
 };return api;
}
