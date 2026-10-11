import assert from 'node:assert/strict';
import { test } from 'node:test';
import Database from 'better-sqlite3';
import { migrateSocialIdentities, checkSocialIdentitySchema } from '../src/social_identity_migration.js';
function fixture({duplicate=false,nullable=false}={}) {
 const db=new Database(':memory:'); db.pragma('foreign_keys=ON');
 db.exec(`CREATE TABLE members(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,phone TEXT ${nullable?'':'NOT NULL UNIQUE'},church_name TEXT NOT NULL,login_provider TEXT NOT NULL DEFAULT 'phone',provider_user_id TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,terms_version TEXT,privacy_version TEXT,consented_at TEXT);
 CREATE TABLE member_identities(id INTEGER PRIMARY KEY AUTOINCREMENT,member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,provider TEXT NOT NULL,provider_user_id TEXT NOT NULL,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE(provider,provider_user_id));
 INSERT INTO members(id,name,phone,church_name) VALUES(7,'test','same','');
 INSERT INTO member_identities(id,member_id,provider,provider_user_id) VALUES(4,7,'google','test-g');
 UPDATE sqlite_sequence SET seq=29 WHERE name='members'; UPDATE sqlite_sequence SET seq=33 WHERE name='member_identities';`);
 if(duplicate) db.exec("INSERT INTO member_identities(member_id,provider,provider_user_id) VALUES(7,'google','other')");
 return db;
}
test('migration preserves all rows and sequences, enforces ownership and is repeat-safe',()=>{
 const db=fixture(); try {
 const members=db.prepare('SELECT * FROM members').all(),identities=db.prepare('SELECT * FROM member_identities').all();
 assert.equal(migrateSocialIdentities(db),true);
 assert.deepEqual(db.prepare('SELECT * FROM members').all(),members); assert.deepEqual(db.prepare('SELECT * FROM member_identities').all(),identities);
 assert.equal(db.prepare("SELECT seq FROM sqlite_sequence WHERE name='members'").get().seq,29);
 assert.equal(db.prepare("SELECT seq FROM sqlite_sequence WHERE name='member_identities'").get().seq,33);
 assert.equal(migrateSocialIdentities(db),false);
 assert.throws(()=>db.exec("INSERT INTO member_identities(member_id,provider,provider_user_id) VALUES(7,'google','other')"),/UNIQUE/);
 db.exec("INSERT INTO members(name,phone,church_name) VALUES('test','same','')");
 assert.equal(db.prepare('SELECT MAX(id) AS id FROM members').get().id,30);
 assert.equal(db.pragma('foreign_keys',{simple:true}),1);
 }finally{db.close();}
});
test('duplicate member/provider migration is blocked without modifying data',()=>{
 const db=fixture({duplicate:true});try {
 assert.throws(()=>migrateSocialIdentities(db),/explicit review/);
 assert.equal(db.prepare('SELECT COUNT(*) AS n FROM member_identities').get().n,2);
 assert.equal(db.pragma('table_info(members)').find(c=>c.name==='phone').notnull,1);
 }finally{db.close();}
});
test('already nullable schema preserves data and only adds missing ownership constraint',()=>{
 const db=fixture({nullable:true});try {
 assert.equal(migrateSocialIdentities(db),true);const state=checkSocialIdentitySchema(db);
 assert.equal(state.phoneUnique,false);assert.equal(state.memberProviderUnique,true);
 }finally{db.close();}
});
