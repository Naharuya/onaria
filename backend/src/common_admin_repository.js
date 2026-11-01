import Database from 'better-sqlite3';
import {emptyAdminState} from './common_admin.js';
// Only internal ticket/content references and administrative metadata are stored here.
// No inquiry body, contact details, credentials or user reflection text belong in this database.
export function createAdminRepository({filename=':memory:'}={}){
 const db=new Database(filename);db.pragma('journal_mode = WAL');db.pragma('secure_delete = ON');
 db.exec('CREATE TABLE IF NOT EXISTS common_admin_state(id INTEGER PRIMARY KEY CHECK(id=1),payload TEXT NOT NULL)');
 return {read:()=>{const row=db.prepare('SELECT payload FROM common_admin_state WHERE id=1').get();return row?JSON.parse(row.payload):emptyAdminState();},
 write:value=>db.prepare('INSERT INTO common_admin_state VALUES(1,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload').run(JSON.stringify(value)),
 transaction:fn=>db.transaction(fn)(),close:()=>db.close()};
}
