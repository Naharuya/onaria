import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import os from 'node:os';import path from 'node:path';import Database from 'better-sqlite3';
import {prepareAppleIsolation,assessIsolationCallback} from '../src/privacy/apple_isolation.js';
import {createMemberStore} from '../src/member_store.js';import {createMemberSessions} from '../src/auth/member_session.js';import {createSqliteUsageLedger} from '../src/cost/sqlite_usage_ledger.js';
test('분리된 실제 저장소 schema로 모의 세션·탈퇴·복원 차단',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-apple-isolation-'));let members,sessions,usage,manifest;
 try{
 const env=prepareAppleIsolation({directory:root});assert.equal(env.externalRequestsAllowed,false);
 members=createMemberStore({filename:env.members});sessions=createMemberSessions({filename:env.sessions});usage=createSqliteUsageLedger({filename:env.usage});manifest=new Database(env.manifest);manifest.exec('CREATE TABLE deleted(g TEXT PRIMARY KEY)');
 const member=members.create({name:'fixture',phone:null,churchName:'',loginProvider:'apple',providerUserId:'fixture-old'});
 members.close();members=null;fs.copyFileSync(env.members,path.join(env.backups,'members-before.sqlite'));members=createMemberStore({filename:env.members});
 const identity={provider:'apple',providerUserId:'fixture-old'};const token=sessions.issue(identity).token;assert.equal(sessions.verify(token).provider,'apple');
 manifest.prepare('INSERT INTO deleted VALUES (?)').run('fixture-old');sessions.revokeIdentity(identity);members.deleteById(member.id);assert.throws(()=>sessions.verify(token));
 members.close();members=null;fs.copyFileSync(path.join(env.backups,'members-before.sqlite'),env.members);members=createMemberStore({filename:env.members});
 const restored=members.findByProviderIdentity('apple','fixture-old');assert.ok(restored);
 if(manifest.prepare('SELECT 1 FROM deleted WHERE g=?').get('fixture-old'))members.deleteById(restored.id);
 assert.equal(members.findByProviderIdentity('apple','fixture-old'),null);
 const next=members.create({name:'fixture-new',phone:null,churchName:'',loginProvider:'apple',providerUserId:'fixture-new'});assert.ok(next);
 // 복원 접속 판단은 독립 명부 확인에 실패하면 차단. 운영 callback은 거절.
 assert.equal(assessIsolationCallback('https://api.onaria.ai.kr/v1/auth/apple/android/callback'),'REJECTED_PRODUCTION');
 assert.equal(assessIsolationCallback('https://isolated.example.invalid/callback'),'BLOCKED');
 assert.throws(()=>prepareAppleIsolation({directory:root,env:{ONARIA_APPLE_CLIENT_ID:'fixture'}}));
 assert.throws(()=>prepareAppleIsolation({directory:'/opt/onaria/backend'}));
 assert.throws(()=>prepareAppleIsolation({directory:root}));
 }finally{members?.close();sessions?.close();usage?.close();manifest?.close();fs.rmSync(root,{recursive:true,force:true});}
});
