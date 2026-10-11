import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createApp } from '../src/app.js';
import { createMemberStore } from '../src/member_store.js';
import { createMemberSessions } from '../src/auth/member_session.js';
async function lab(action){
 const dir=mkdtempSync(join(tmpdir(),'onaria-auth-ux-'));
 const store=createMemberStore({filename:join(dir,'members.sqlite')});
 const sessions=createMemberSessions();
 const app=createApp({generate:async()=>({}),memberStore:store,memberSessions:sessions,providerIdentity:async({provider,credential})=>({provider,providerUserId:credential}),logger:{error(){}}});
 const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
 try {await action({store,sessions,base:`http://127.0.0.1:${server.address().port}`});} finally {await new Promise(r=>server.close(r));sessions.close();store.close();rmSync(dir,{recursive:true,force:true});}
}
const req=(base,path,method,token,body)=>fetch(base+path,{method,headers:{'content-type':'application/json',...(token?{'x-onaria-member-session':token}:{})},...(body?{body:JSON.stringify(body)}:{})});
test('account proof must match session owner; supplied memberId cannot select another member',()=>lab(async({store,sessions,base})=>{
 const a=store.create({loginProvider:'google',providerUserId:'a'}), b=store.create({loginProvider:'naver',providerUserId:'b'});
 const ta=sessions.issue({provider:'google',providerUserId:'a'}).token,tb=sessions.issue({provider:'naver',providerUserId:'b'}).token;
 const overview=await req(base,`/v1/account?memberId=${b.id}`,'GET',ta);assert.equal((await overview.json()).member.id,a.id);
 assert.equal((await req(base,'/v1/account','DELETE',ta,{})).status,428);
 assert.equal((await req(base,'/v1/account','DELETE',ta,{reauthProvider:'naver',reauthCredential:'b',memberId:b.id})).status,401);
 assert.equal(store.findByProviderIdentity('google','a').id,a.id);assert.equal(store.findByProviderIdentity('naver','b').id,b.id);
 assert.equal((await req(base,'/v1/account','DELETE',ta,{reauthProvider:'google',reauthCredential:'a',memberId:b.id})).status,204);
 assert.equal(store.findByProviderIdentity('google','a'),null);assert.equal(store.findByProviderIdentity('naver','b').id,b.id);assert.doesNotThrow(()=>sessions.verify(tb));
}));
test('concurrent empty-profile signup creates one canonical member; response loss recovers through login',()=>lab(async({store,base})=>{
 const body={provider:'google',credential:'new',termsAccepted:true,privacyAccepted:true,adultConfirmed:true};
 const results=await Promise.all([req(base,'/v1/auth/provider/signup','POST',null,body),req(base,'/v1/auth/provider/signup','POST',null,body)]);
 assert.deepEqual(results.map(r=>r.status).sort(),[201,409]);
 const member=store.findByProviderIdentity('google','new');assert.equal(member.phone,null);assert.equal(member.name,'');assert.equal(member.church_name,'');assert.ok(member.terms_version);assert.ok(member.privacy_version);assert.ok(member.consented_at);
 const recovered=await req(base,'/v1/auth/provider/session','POST',null,{provider:'google',credential:'new'});assert.equal(recovered.status,201);
 const response=await recovered.json();const account=await req(base,'/v1/account','GET',response.sessionToken);assert.equal((await account.json()).member.id,member.id);
 assert.equal(store.getAdminOverview().total,1);
}));
test('unlink requires owner proof and preserves current/last login routes',()=>lab(async({store,sessions,base})=>{
 const member=store.create({loginProvider:'google',providerUserId:'a'});store.attachIdentity(member.id,'naver','n');const token=sessions.issue({provider:'google',providerUserId:'a'}).token;
 assert.equal((await req(base,'/v1/account/providers/naver','DELETE',token,{})).status,428);
 assert.deepEqual(store.listIdentities(member.id),['google','naver']);
 assert.equal((await req(base,'/v1/account/providers/google','DELETE',token,{reauthProvider:'google',reauthCredential:'a'})).status,409);
 assert.equal((await req(base,'/v1/account/providers/naver','DELETE',token,{reauthProvider:'google',reauthCredential:'a'})).status,204);
 assert.deepEqual(store.listIdentities(member.id),['google']);assert.doesNotThrow(()=>sessions.verify(token));
}));
