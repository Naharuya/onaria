import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createApp} from '../src/app.js';
import {createAdminAccounts} from '../src/admin_accounts.js';
import {createAuditLog} from '../src/audit_log.js';
import {createAdminRepository} from '../src/common_admin_repository.js';
const fixtureToken='synthetic-owner-credential-only';
async function fixture(fn){
 const directory=mkdtempSync(join(tmpdir(),'admin-common-'));
 const accounts=createAdminAccounts(),audit=createAuditLog(),repository=createAdminRepository({filename:join(directory,'operations.sqlite')});
 const app=createApp({generate:Object.assign(async()=>({}),{mode:'local'}),adminToken:fixtureToken,
  adminAccounts:accounts,audit,adminRepository:repository,memberStore:{getAdminOverview:()=>({total:4,recent:[{name:'private'}]})}});
 const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
 const origin='http://127.0.0.1:'+server.address().port;
 async function login(body){
  const response=await fetch(origin+'/v1/admin/session',{method:'POST',headers:{Origin:origin,'Content-Type':'application/json'},body:JSON.stringify(body)});
  assert.equal(response.status,200);return {cookie:response.headers.get('set-cookie').split(';')[0],...(await response.json())};
 }
 const owner=await login({token:fixtureToken});
 const request=(path,{method='GET',body,session=owner,csrf=true}={})=>fetch(origin+path,{method,headers:{Cookie:session.cookie,Origin:origin,...(csrf?{'X-CSRF-Token':session.csrfToken}:{}),...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});
 try{await fn({request,login,owner,accounts,repository,origin});}
 finally{await new Promise(r=>server.close(r));accounts.close();audit.close();repository.close();rmSync(directory,{recursive:true,force:true});}
}
test('common web workspace and API require real session, role and CSRF',()=>fixture(async({request,login,accounts,origin})=>{
 const publicPage=await fetch(origin+'/admin/common');assert.equal(publicPage.status,200);assert.match(await publicPage.text(),/공통 관리/);
 assert.equal((await fetch(origin+'/v1/admin/common/standard')).status,401);
 assert.equal((await request('/v1/admin/common/standard')).headers.get('cache-control'),'no-store');
 const created=await accounts.create({username:'fixture-support',password:'synthetic-password-123',role:'support'});
 const session=await login({username:'fixture-support',password:'synthetic-password-123'});
 assert.equal((await request('/v1/admin/common/members',{session})).status,403);
 assert.equal((await request('/v1/admin/settings',{session})).status,403);
 assert.equal((await request('/v1/admin/common/requests',{method:'POST',body:{reference:'case-001',kind:'account_deletion'},session,csrf:false})).status,403);
 const response=await request('/v1/admin/common/requests',{method:'POST',body:{reference:'case-001',kind:'account_deletion'},session});
 assert.equal(response.status,200);assert.equal((await response.json()).state,'received');
 accounts.setDisabled(created.id,true);assert.equal((await request('/v1/admin/common/requests',{session})).status,401);
}));
test('owner provisions and changes named roles, while non-owners cannot create admins',()=>fixture(async({request,login})=>{
 const create=await request('/v1/admin/common/accounts',{method:'POST',body:{username:'fixture-viewer',password:'synthetic-password-123',role:'viewer'}});
 assert.equal(create.status,201);const {account}=await create.json();
 const session=await login({username:'fixture-viewer',password:'synthetic-password-123'});
 assert.equal((await request('/v1/admin/common/accounts',{session})).status,403);
 assert.equal((await request('/v1/admin/common/accounts/'+account.id,{method:'POST',body:{role:'operator',disabled:false}})).status,200);
 assert.equal((await request('/v1/admin/common/backup',{session})).status,200);
 assert.equal((await request('/v1/admin/common/requests',{session})).status,403);
}));
test('real SQLite operations survive reopening and preserve audit validity',()=>{
 const directory=mkdtempSync(join(tmpdir(),'admin-persistence-')),filename=join(directory,'operations.sqlite');
 let repository=createAdminRepository({filename});
 const state={version:1,requests:[],inquiries:[],reviews:[],audit:[]};
 repository.transaction(()=>repository.write(state));repository.close();
 repository=createAdminRepository({filename});assert.deepEqual(repository.read(),state);
 assert.throws(()=>repository.transaction(()=>{repository.write({...state,version:5});throw Error('rollback');}));assert.deepEqual(repository.read(),state);
 repository.close();rmSync(directory,{recursive:true,force:true});
});
