import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import Database from 'better-sqlite3';
import { backupDatabases } from '../scripts/backup_databases.js';
import { pruneBackups, acquireBackupLock } from '../src/privacy/backup_retention.js';
import { maintainRetention } from '../scripts/retention_maintenance.js';
import { prepareMemberRestore } from '../scripts/prepare_member_restore.js';
import { createMemberStore } from '../src/member_store.js';
import { createMemberSessions } from '../src/auth/member_session.js';
import { createDeletionManifest } from '../src/privacy/deletion_manifest.js';
import { createSqliteUsageLedger } from '../src/cost/sqlite_usage_ledger.js';

function fixture(t) {
 const root=fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(),'onaria-retention-')));
 t.after(()=>fs.rmSync(root,{recursive:true,force:true}));
 const dataDir=path.join(root,'live'),backupRoot=path.join(root,'backups');
 fs.mkdirSync(dataDir);fs.mkdirSync(backupRoot);
 const members=createMemberStore({filename:path.join(dataDir,'members.sqlite')});
 const manifest=createDeletionManifest({filename:path.join(dataDir,'deletion-manifest.sqlite'),now:()=>new Date('2026-07-01T00:00:00.000Z')});
 const sessions=createMemberSessions({filename:path.join(dataDir,'member-sessions.sqlite'),now:()=>Date.parse('2026-09-01T00:00:00Z')});
 const usage=createSqliteUsageLedger({filename:path.join(dataDir,'ai_usage.sqlite'),now:()=>new Date('2026-07-01T00:00:00Z')});
 t.after(()=>{members.close();manifest.close();sessions.close();usage.close();});
 return {root,dataDir,backupRoot,members,manifest,sessions,usage};
}
test('14-day boundary pruning leaves recent snapshots and live databases intact',async t=>{
 const f=fixture(t), now=new Date('2026-10-11T00:00:00.000Z');
 const old=await backupDatabases({...f,sourceDir:f.dataDir,now:new Date('2026-09-27T00:00:00.000Z')});
 const recent=await backupDatabases({...f,sourceDir:f.dataDir,now:new Date('2026-09-27T00:00:00.001Z')});
 assert.equal(pruneBackups({backupRoot:f.backupRoot,now}).candidates,1);
 assert.ok(fs.existsSync(old.destination));
 assert.equal(pruneBackups({backupRoot:f.backupRoot,now,apply:true}).removed,1);
 assert.ok(fs.existsSync(recent.destination));
 assert.ok(fs.existsSync(path.join(f.dataDir,'members.sqlite')));
 assert.equal(pruneBackups({backupRoot:f.backupRoot,now,apply:true}).removed,0);
});
test('unmanaged or tampered backup blocks the entire sweep before deletion',async t=>{
 const f=fixture(t), now=new Date('2026-10-11T00:00:00.000Z');
 const old=await backupDatabases({sourceDir:f.dataDir,backupRoot:f.backupRoot,now:new Date('2026-09-01T00:00:00.000Z')});
 fs.symlinkSync(f.dataDir,path.join(f.backupRoot,'outside'));
 assert.throws(()=>pruneBackups({backupRoot:f.backupRoot,now,apply:true}),/Unmanaged/);
 assert.ok(fs.existsSync(old.destination));
 fs.unlinkSync(path.join(f.backupRoot,'outside'));
 fs.appendFileSync(path.join(old.destination,'members.sqlite'),'tamper');
 assert.throws(()=>pruneBackups({backupRoot:f.backupRoot,now,apply:true}),/verification/);
 assert.ok(fs.existsSync(old.destination));
});
test('maintenance defaults to dry run then clears expired sessions and 62-day usage only',async t=>{
 const f=fixture(t),now=new Date('2026-10-11T00:00:00.000Z');
 f.sessions.issue({provider:'naver',providerUserId:'fixture'});
 f.usage.reserve({userId:'fixture'}).finish();
 f.members.create({name:'keep',phone:'',churchName:'',loginProvider:'naver',providerUserId:'fixture'});
 const preview=maintainRetention({...f,now});
 assert.equal(preview.sessions.expired,1);assert.equal(preview.sessions.removed,0);
 assert.equal(f.usage.entries().length,1);
 const applied=maintainRetention({...f,now,apply:true});
 assert.equal(applied.sessions.removed,1);
 assert.equal(f.usage.entries().length,0);
 assert.equal(f.members.getAdminOverview().total,1);
 assert.equal(maintainRetention({...f,now,apply:true}).sessions.removed,0);
});
test('offline restore uses latest tombstones, discards sessions and prevents ID reuse after rollback',async t=>{
 const f=fixture(t),stamp=new Date('2026-10-10T00:00:00.000Z');
 const old=f.members.create({name:'old',phone:'',churchName:'',loginProvider:'naver',providerUserId:'old'});
 f.sessions.issue({provider:'naver',providerUserId:'old'});
 const backup=await backupDatabases({sourceDir:f.dataDir,backupRoot:f.backupRoot,now:stamp});
 f.manifest.record(old.id);f.members.deleteById(old.id);
 const newer=f.members.create({name:'new',phone:'',churchName:'',loginProvider:'naver',providerUserId:'new'});
 const destination=path.join(f.root,'candidate');
 const receipt=await prepareMemberRestore({snapshotDir:backup.destination,liveDataDir:f.dataDir,destination,now:new Date('2026-10-11T00:00:00.000Z')});
 assert.equal(receipt.oldSessionsRestored,false);
 assert.equal(fs.existsSync(path.join(destination,'member-sessions.sqlite')),false);
 const staged=createMemberStore({filename:path.join(destination,'members.sqlite')});
 try {
  assert.equal(staged.findByProviderIdentity('naver','old'),null);
  const registered=staged.create({name:'again',phone:'',churchName:'',loginProvider:'naver',providerUserId:'old'});
  assert.ok(registered.id>newer.id);
 }finally{staged.close();}
 assert.ok(f.members.findByProviderIdentity('naver','new'));
 assert.equal(f.manifest.contains(old.id),true);
});
test('restore fails closed with missing latest manifest, expired backup or existing destination',async t=>{
 const f=fixture(t),stamp=new Date('2026-09-01T00:00:00.000Z');
 const backup=await backupDatabases({sourceDir:f.dataDir,backupRoot:f.backupRoot,now:stamp});
 await assert.rejects(prepareMemberRestore({snapshotDir:backup.destination,liveDataDir:f.dataDir,destination:path.join(f.root,'candidate'),now:new Date('2026-10-11T00:00:00Z')}),/retention/);
 await assert.rejects(prepareMemberRestore({snapshotDir:backup.destination,liveDataDir:f.dataDir,destination:f.dataDir,now:stamp}),/Fresh/);
});

test('shared backup lock blocks maintenance and snapshot creation without touching data', async t=>{
 const f=fixture(t), release=acquireBackupLock(f.backupRoot);
 try {
  assert.throws(()=>maintainRetention({...f,apply:true}),/EEXIST/);
  await assert.rejects(backupDatabases({sourceDir:f.dataDir,backupRoot:f.backupRoot}),/EEXIST/);
  assert.ok(fs.existsSync(path.join(f.dataDir,'members.sqlite')));
 } finally {release();}
});

test('restore rejects legacy snapshots from before durable deletion tracking began',async t=>{
 const f=fixture(t),now=new Date('2026-10-11T00:00:00.000Z');
 const backup=await backupDatabases({sourceDir:f.dataDir,backupRoot:f.backupRoot,now:new Date('2026-10-10T00:00:00.000Z')});
 const db=new Database(path.join(f.dataDir,'deletion-manifest.sqlite'));
 db.prepare("UPDATE deletion_control SET value=? WHERE key='restore_not_before'").run(now.toISOString());db.close();
 await assert.rejects(prepareMemberRestore({snapshotDir:backup.destination,liveDataDir:f.dataDir,destination:path.join(f.root,'legacy'),now}),/predates/);
 assert.equal(fs.existsSync(path.join(f.root,'legacy')),false);
});

test('expired deletion markers are pruned only with an advanced restore barrier',async t=>{
 const f=fixture(t),now=new Date('2026-10-11T00:00:00.000Z');
 f.manifest.record(99);
 assert.equal(maintainRetention({...f,now}).deletions.expired,1);
 assert.equal(f.manifest.contains(99),true);
 assert.equal(maintainRetention({...f,now,apply:true}).deletions.removed,1);
 assert.equal(f.manifest.contains(99),false);
 const db=new Database(path.join(f.dataDir,'deletion-manifest.sqlite'),{readonly:true});
 assert.equal(db.prepare("SELECT value FROM deletion_control WHERE key='restore_not_before'").get().value,'2026-09-27T00:00:00.000Z');db.close();
});
