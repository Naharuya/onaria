import Database from 'better-sqlite3';
import {chmodSync} from 'node:fs';
import {emptyAdminState} from './common_admin.js';
// Approval references and review metadata only; no user conversations or credentials.
export function createPublicationRepository({filename=':memory:',requireExisting=false}={}){
 const db=new Database(filename,{fileMustExist:requireExisting&&filename!==':memory:'});
 try{
  if(filename!==':memory:')chmodSync(filename,0o600);
  db.pragma('journal_mode = WAL');db.pragma('secure_delete = ON');
  if(!requireExisting||filename===':memory:'){
   db.exec('CREATE TABLE IF NOT EXISTS content_publication_state(id INTEGER PRIMARY KEY CHECK(id=1),payload TEXT NOT NULL)');
   db.prepare('INSERT OR IGNORE INTO content_publication_state VALUES(1,?)').run(JSON.stringify(emptyAdminState()));
  }
  const select=db.prepare('SELECT payload FROM content_publication_state WHERE id=1');
  const read=()=>{const row=select.get();if(!row)throw Error('CONTENT_STORAGE_INVALID');const s=JSON.parse(row.payload);if(s.version!==1||!Array.isArray(s.audit)||(s.publications!==undefined&&!Array.isArray(s.publications)))throw Error('CONTENT_STORAGE_INVALID');return s;};
  read();
  return {read,write:value=>db.prepare('UPDATE content_publication_state SET payload=? WHERE id=1').run(JSON.stringify(value)),transaction:fn=>db.transaction(fn)(),close:()=>db.close()};
 }catch(error){db.close();throw error;}
}
