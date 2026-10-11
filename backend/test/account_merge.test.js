import assert from 'node:assert/strict';
import { test } from 'node:test';
import Database from 'better-sqlite3';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createApp } from '../src/app.js';
import { createMemberStore } from '../src/member_store.js';
import { createMemberSessions } from '../src/auth/member_session.js';
import { createDeletionManifest } from '../src/privacy/deletion_manifest.js';
import { IdentityError } from '../src/auth/identity_verifier.js';
import { mergeHash } from '../src/account_merge_store.js';
async function fixture(run,{enabled=true}={}) {
 const dir=mkdtempSync(join(tmpdir(),'onaria-merge-test-')); let stamp=1000000;
 let store=createMemberStore({filename:join(dir,'members.sqlite'),mergeNow:()=>stamp});
 const sessions=createMemberSessions();
 const manifest=createDeletionManifest({filename:join(dir,'deletions.sqlite')});
 const verifier=async({provider,credential})=>{
  if (!['google','naver','apple','kakao'].includes(provider)||!['target','source','third'].includes(credential)) throw new IdentityError();
  return {provider,providerUserId:provider+':'+credential};
 };
 const a=store.create({name:'same',phone:'01012345678',loginProvider:'google',providerUserId:'google:target'});
 const b=store.create({name:'same',phone:'01012345678',loginProvider:'naver',providerUserId:'naver:source'});
 const c=store.create({name:'same',phone:'01012345678',loginProvider:'apple',providerUserId:'apple:third'});
 const app=createApp({generate:async()=>({}),memberStore:store,memberSessions:sessions,providerIdentity:verifier,
  deletionManifest:manifest,accountMergeEnabled:enabled,appleRevocation:async()=>{}});
 const server=await new Promise(resolve=>{const s=app.listen(0,'127.0.0.1',()=>resolve(s));});
 const base='http://127.0.0.1:'+server.address().port;
 const token=sessions.issue({provider:'google',providerUserId:'google:target'}).token;
 const sourceToken=sessions.issue({provider:'naver',providerUserId:'naver:source'}).token;
 async function request(path,body,auth=token,method='POST') {
  const r=await fetch(base+path,{method,headers:{'content-type':'application/json','x-onaria-member-session':auth},...(body===undefined?{}:{body:JSON.stringify(body)})});
  const raw=await r.text(); return {status:r.status,body:raw?JSON.parse(raw):null};
 }
 const prepare=()=>request('/v1/account/merge/prepare',{reauthProvider:'google',reauthCredential:'target',sourceProvider:'naver',sourceCredential:'source'});
 try {await run({store,sessions,manifest,a,b,c,token,sourceToken,request,prepare,advance:()=>stamp+=120001,
 backup:async()=>{const reader=new Database(join(dir,'members.sqlite'),{readonly:true});try{await reader.backup(join(dir,'before.sqlite'));}finally{reader.close();}},
 reopenBackup:()=>{store.close();store=createMemberStore({filename:join(dir,'before.sqlite')});return store;},
 reopen:()=>{
  store.close();store=createMemberStore({filename:join(dir,'members.sqlite')});return store;
 }});} finally {await new Promise(r=>server.close(r));store.close();sessions.close();manifest.close();rmSync(dir,{recursive:true,force:true});}
}
test('merge disabled by default; signup and login remain independent',async()=>fixture(async({request,store,a,b})=>{
 assert.equal((await request('/v1/account/merge/prepare',{})).status,503);
 assert.equal(store.findByProviderIdentity('naver','naver:source').id,b.id);
 assert.equal((await request('/v1/account',undefined,undefined,'GET')).body.mergeAvailable,false);
 assert.equal(store.listIdentities(a.id).length,1);
},{enabled:false}));
test('both proofs and explicit consent required; same name/phone never merges',async()=>fixture(async({request,prepare,store,a,b})=>{
 const bad=await request('/v1/account/merge/prepare',{reauthProvider:'google',reauthCredential:'source',sourceProvider:'naver',sourceCredential:'source'});
 assert.equal(bad.status,401);
 const plan=await prepare();assert.equal(plan.status,201);
 assert.equal(store.findByProviderIdentity('naver','naver:source').id,b.id);
 const no=await request('/v1/account/merge/confirm',{attemptToken:plan.body.attemptToken,consent:false});assert.equal(no.status,400);
 assert.deepEqual(store.recordOwnerIds(a.id),[a.id]);
}));
test('confirmed merge preserves owners, revokes both sessions and survives restart',async()=>fixture(async({prepare,request,store,sessions,token,sourceToken,a,b,c,reopen})=>{
 const plan=await prepare(); const result=await request('/v1/account/merge/confirm',{attemptToken:plan.body.attemptToken,consent:true});
 assert.equal(result.status,200);assert.deepEqual(result.body.recordOwnerIds,[a.id,b.id]);
 assert.throws(()=>sessions.verify(token));assert.throws(()=>sessions.verify(sourceToken));
 const account=await request('/v1/account',undefined,result.body.sessionToken,'GET');
 assert.deepEqual(account.body.providers,['google','naver']);assert.deepEqual(account.body.recordOwnerIds,[a.id,b.id]);
 assert.equal(store.findByProviderIdentity('apple','apple:third').id,c.id);
 const replay=await request('/v1/account/merge/confirm',{attemptToken:plan.body.attemptToken,consent:true},result.body.sessionToken);assert.equal(replay.status,403);
 const opened=reopen();assert.equal(opened.findByProviderIdentity('naver','naver:source').id,a.id);
 assert.deepEqual(opened.recordOwnerIds(a.id),[a.id,b.id]);assert.equal(opened.getAdminOverview().total,2);
}));
test('expiry, session binding, concurrent identity change and repeated prepare fail closed',async()=>fixture(async({prepare,request,sessions,store,a,b,advance})=>{
 let p=await prepare();const other=sessions.issue({provider:'google',providerUserId:'google:target'}).token;
 assert.equal((await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true},other)).status,403);
 const newer=await prepare();assert.equal((await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true})).status,403);
 store.attachIdentity(b.id,'kakao','kakao:source');
 assert.equal((await request('/v1/account/merge/confirm',{attemptToken:newer.body.attemptToken,consent:true})).body.code,'MERGE_ACCOUNT_CHANGED');
 p=await prepare();advance();assert.equal((await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true})).status,410);
 assert.equal(store.findByProviderIdentity('naver','naver:source').id,b.id);assert.deepEqual(store.recordOwnerIds(a.id),[a.id]);
}));
test('session-store failure leaves ownership untouched and retry is safe',async()=>fixture(async({prepare,request,store,sessions,a,b})=>{
 const p=await prepare(), original=sessions.revokeIdentity;sessions.revokeIdentity=()=>{throw new Error('fixture storage failure');};
 const failure=await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true});assert.equal(failure.status,503);
 assert.equal(store.findByProviderIdentity('naver','naver:source').id,b.id);
 sessions.revokeIdentity=original;
 assert.equal((await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true})).status,200);
 assert.equal(store.findByProviderIdentity('naver','naver:source').id,a.id);
}));
test('deletion tombstones all merged owners and leaves unrelated member intact',async()=>fixture(async({prepare,request,manifest,store,a,b,c})=>{
 const p=await prepare(), merged=await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true});
 const deleted=await request('/v1/account',{reauthProvider:'google',reauthCredential:'target'},merged.body.sessionToken,'DELETE');assert.equal(deleted.status,204);
 assert.ok(manifest.contains(a.id));assert.ok(manifest.contains(b.id));assert.equal(manifest.contains(c.id),false);
 assert.equal(store.findByProviderIdentity('naver','naver:source'),null);assert.equal(store.getAdminOverview().total,1);
}));
test('same-provider conflicts do not revoke sessions or overwrite identities',async()=>fixture(async({prepare,request,store,sessions,token,a,b})=>{
 store.attachIdentity(b.id,'google','google:source');
 const p=await prepare();assert.equal(p.status,409);assert.equal(p.body.code,'SAME_PROVIDER_ACCOUNT_CONFLICT');
 assert.ok(sessions.verify(token));assert.deepEqual(store.listIdentities(a.id),['google']);
}));
test('success followed by session issuance failure is recoverable through normal login',async()=>fixture(async({prepare,request,sessions,store,a,b})=>{
 const p=await prepare(), original=sessions.issue;sessions.issue=()=>{throw new Error('fixture issuance failure');};
 assert.equal((await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true})).status,503);
 sessions.issue=original;
 const login=await request('/v1/auth/provider/session',{provider:'naver',credential:'source'});
 assert.equal(login.status,201);
 const account=await request('/v1/account',undefined,login.body.sessionToken,'GET');
 assert.equal(account.body.member.id,a.id);assert.deepEqual(account.body.recordOwnerIds,[a.id,b.id]);
}));

test('sequential merges preserve all owners and detached primary stays detached on restart',async()=>fixture(async({prepare,request,store,a,b,c,reopen})=>{
 const p=await prepare(), first=await request('/v1/account/merge/confirm',{attemptToken:p.body.attemptToken,consent:true});
 const next=await request('/v1/account/merge/prepare',{reauthProvider:'google',reauthCredential:'target',sourceProvider:'apple',sourceCredential:'third'},first.body.sessionToken);
 const done=await request('/v1/account/merge/confirm',{attemptToken:next.body.attemptToken,consent:true},first.body.sessionToken);
 assert.equal(done.status,200);assert.deepEqual(store.recordOwnerIds(a.id),[a.id,b.id,c.id]);
 store.detachIdentity(a.id,'google');const opened=reopen();
 assert.equal(opened.findByProviderIdentity('google','google:target'),null);
 assert.equal(opened.findByProviderIdentity('naver','naver:source').id,a.id);
 assert.equal(opened.findByProviderIdentity('apple','apple:third').id,a.id);
 assert.deepEqual(opened.recordOwnerIds(a.id),[a.id,b.id,c.id]);
}));
test('deleted source cannot merge before tombstones are replayed',async()=>fixture(async({prepare,manifest,store,b})=>{
 manifest.record(b.id);assert.equal((await prepare()).status,404);
 assert.equal(store.findByProviderIdentity('naver','naver:source').id,b.id);
}));

test('restoring a pre-merge member backup cannot resurrect any deleted source',async()=>fixture(async({prepare,request,manifest,store,a,b,c,backup,reopenBackup})=>{
 await backup();
 const plan=await prepare();
 const done=await request('/v1/account/merge/confirm',{attemptToken:plan.body.attemptToken,consent:true});
 assert.equal((await request('/v1/account',{reauthProvider:'google',reauthCredential:'target'},done.body.sessionToken,'DELETE')).status,204);
 const restored=reopenBackup();manifest.reapply(restored);
 assert.equal(restored.findByProviderIdentity('google','google:target'),null);
 assert.equal(restored.findByProviderIdentity('naver','naver:source'),null);
 assert.equal(restored.findByProviderIdentity('apple','apple:third').id,c.id);
}));
