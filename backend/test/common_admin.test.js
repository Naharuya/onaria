import test from 'node:test';
import assert from 'node:assert/strict';
import {createAdminControl,emptyAdminState,REVIEW_PROFILES,COMMON_CHECKS,ADMIN_ROLES} from '../src/common_admin.js';
const actor=(role='admin',id=role)=>({actor:id,role});
function setup(options={}){
 let state=emptyAdminState(),failWrite=false;
 const repository={read:()=>structuredClone(state),write:value=>{if(failWrite)throw Error('disk full');state=structuredClone(value);},
 transaction:fn=>{const old=structuredClone(state);try{return fn();}catch(e){state=old;throw e;}}};
 const control=createAdminControl({project:'onaria',repository,...options});
 return {call:(method,path,body,a=actor())=>control.dispatch({method,path,body,actor:a}),
  state:()=>structuredClone(state),fail:()=>failWrite=true,tamper:()=>state.audit[0].action='tampered'};
}
const code=(fn,value)=>assert.throws(fn,error=>error.code===value);
function processing(s,kind='account_deletion'){
 let row=s.call('POST','/requests',{reference:'case-001',kind},actor('support'));
 row=s.call('POST','/requests/'+row.id+'/verify',{version:row.version},actor('support'));
 row=s.call('POST','/requests/'+row.id+'/approve',{version:row.version},actor('admin'));
 return s.call('POST','/requests/'+row.id+'/processing',{version:row.version},actor('support'));
}
test('all profiles share roles and four baseline checks, with only tradition checks differing',()=>{
 assert.equal(ADMIN_ROLES.length,7);
 for(const project of Object.keys(REVIEW_PROFILES)){
  const s=setup({project}),standard=s.call('GET','/standard');
  assert.deepEqual(standard.checks.slice(0,4),COMMON_CHECKS);assert.equal(standard.checks.length,7);
  assert.equal(standard.automaticDeletion,false);
 }
});
test('unknown roles, prototype keys and unauthenticated callers are denied',()=>{
 const s=setup();
 for(const role of ['toString','__proto__','unknown'])code(()=>s.call('GET','/standard',null,actor(role)),'FORBIDDEN');
 code(()=>s.call('GET','/standard',null,null),'FORBIDDEN');
});
test('server permissions separate support, reviewer, operator, viewer and editor',()=>{
 const s=setup({members:()=>({total:3,recent:[{name:'must not leak',phone:'secret'}]})});
 for(const [role,path]of [['support','/members'],['reviewer','/requests'],['operator','/inquiries'],['viewer','/audit'],['editor','/backup']]){
  code(()=>s.call('GET',path,null,actor(role)),'FORBIDDEN');
 }
 assert.deepEqual(s.call('GET','/members'),{total:3});
});
test('missing member adapter and absent backup evidence never claim success',()=>{
 const s=setup();code(()=>s.call('GET','/members'),'MEMBER_ADAPTER_UNAVAILABLE');
 assert.deepEqual(s.call('GET','/backup'),{configured:false,backup:'UNVERIFIED',restore:'UNVERIFIED',deletionProtection:'UNVERIFIED'});
});
test('backup results expose only explicit status, environment and timestamp',()=>{
 const s=setup({inspectBackup:()=>({backup:'PASS',restore:'pending',deletionProtection:'FAIL',environment:'synthetic',checkedAt:100,secret:'hidden',path:'/private'})});
 assert.deepEqual(s.call('GET','/backup'),{configured:true,backup:'PASS',restore:'UNVERIFIED',deletionProtection:'FAIL',environment:'synthetic',checkedAt:100});
});
test('request lifecycle rejects self-approval, skipped stages and stale writes',()=>{
 const s=setup();let row=s.call('POST','/requests',{reference:'case-001',kind:'account_deletion'});
 code(()=>s.call('POST','/requests/'+row.id+'/complete',{version:1,receipt:'receipt-001'}),'INVALID_STATE');
 row=s.call('POST','/requests/'+row.id+'/verify',{version:1});
 code(()=>s.call('POST','/requests/'+row.id+'/approve',{version:2}),'INDEPENDENT_APPROVAL_REQUIRED');
 code(()=>s.call('POST','/requests/'+row.id+'/reject',{version:1}),'VERSION_CONFLICT');
 assert.equal(s.call('GET','/requests').items[0].state,'identity_pending');
});
test('no deletion adapter leaves request processing without false completion',()=>{
 const s=setup(),row=processing(s);
 code(()=>s.call('POST','/requests/'+row.id+'/complete',{version:row.version,receipt:'receipt-001'}),'DELETION_VERIFIER_UNAVAILABLE');
 assert.equal(s.call('GET','/requests').items[0].state,'processing');
});
test('deletion receipt requires matching app, case, scope and all protections',()=>{
 let evidence;
 const s=setup({verifyDeletion:()=>evidence}),row=processing(s);
 const good={project:'onaria',reference:'case-001',kind:'account_deletion',completed:true,identityVerified:true,sessionsRevoked:true,backupProtected:true,providerRevoked:true};
 for(const [key,value]of [['project','sorua'],['reference','case-other'],['kind','server_records'],['completed',false],['identityVerified',false],['sessionsRevoked',false],['backupProtected',false],['providerRevoked',false]]){
  evidence={...good,[key]:value};code(()=>s.call('POST','/requests/'+row.id+'/complete',{version:row.version,receipt:'receipt-001'}),'DELETION_UNCONFIRMED');
 }
 evidence=good;assert.equal(s.call('POST','/requests/'+row.id+'/complete',{version:row.version,receipt:'receipt-001'}).state,'completed');
});
test('inquiry workflow assigns, resolves and reopens without storing inquiry text or contact',()=>{
 const s=setup();let row=s.call('POST','/inquiries',{reference:'support-001',category:'privacy'},actor('support'));
 row=s.call('POST','/inquiries/'+row.id+'/assign',{version:1,assignee:'staff-001'},actor('support'));
 row=s.call('POST','/inquiries/'+row.id+'/resolve',{version:2},actor('support'));assert.equal(row.state,'resolved');
 row=s.call('POST','/inquiries/'+row.id+'/reopen',{version:3},actor('support'));assert.equal(row.state,'received');
 code(()=>s.call('POST','/inquiries',{reference:'support-002',category:'privacy',body:'private'}),'INVALID_INPUT');
});
test('content self-review and incomplete or cross-profile checks cannot advance',()=>{
 const s=setup(),row=s.call('POST','/reviews',{reference:'content-001',revision:'revision-001'},actor('editor'));
 const checks=Object.fromEntries([...COMMON_CHECKS,...REVIEW_PROFILES.onaria].map(k=>[k,true]));
 code(()=>s.call('POST','/reviews/'+row.id+'/inspect',{version:1,checks,evidence:'evidence-001'},actor('reviewer','editor')),'INDEPENDENT_REVIEW_REQUIRED');
 code(()=>s.call('POST','/reviews/'+row.id+'/inspect',{version:1,checks:{...checks,safety:false},evidence:'evidence-001'},actor('reviewer')),'CONTENT_REVIEW_INCOMPLETE');
 const done=s.call('POST','/reviews/'+row.id+'/inspect',{version:1,checks,evidence:'evidence-001'},actor('reviewer'));
 assert.equal(done.state,'reviewed');assert.equal(done.published,undefined);
});
test('atomic persistence failure rolls back business state and audit event',()=>{
 const s=setup();s.fail();assert.throws(()=>s.call('POST','/requests',{reference:'case-001',kind:'account_deletion'}));
 assert.deepEqual(s.state(),emptyAdminState());
});
test('audit chain detects tampering and blocks subsequent mutation',()=>{
 const s=setup();s.call('POST','/inquiries',{reference:'support-001',category:'general'});
 assert.equal(s.call('GET','/audit').valid,true);s.tamper();assert.equal(s.call('GET','/audit').valid,false);
 code(()=>s.call('POST','/inquiries',{reference:'support-002',category:'general'}),'ADMIN_STORAGE_UNAVAILABLE');
});
test('audit contains IDs and actions but excludes request bodies, credentials and content',()=>{
 const s=setup();s.call('POST','/inquiries',{reference:'support-001',category:'general'});
 const audit=s.call('GET','/audit');assert.equal(audit.valid,true);
 assert.equal(JSON.stringify(audit).includes('support-001'),false);assert.equal(audit.events[0].action,'inquiry.received');
});
test('unsupported API paths and HTML-like references are rejected',()=>{
 const s=setup();code(()=>s.call('POST','/publish',{}),'NOT_FOUND');
 code(()=>s.call('POST','/inquiries',{reference:'<img src=x>',category:'general'}),'INVALID_REFERENCE');
});

test('record-only deletion completion does not require logging out or provider revocation',()=>{
 const s=setup({verifyDeletion:()=>({project:'onaria',reference:'case-001',kind:'server_records',completed:true,identityVerified:true,backupProtected:true,sessionsRevoked:false,providerRevoked:false})});
 const row=processing(s,'server_records');assert.equal(s.call('POST','/requests/'+row.id+'/complete',{version:row.version,receipt:'record-receipt-001'}).state,'completed');
});
test('consent withdrawal completion requires actual consent and data-disposition evidence',()=>{
 let confirmed=false;const s=setup({verifyDeletion:()=>({project:'onaria',reference:'case-001',kind:'consent_withdrawal',completed:true,identityVerified:true,consentUpdated:confirmed,dataDispositionVerified:confirmed})});
 const row=processing(s,'consent_withdrawal');code(()=>s.call('POST','/requests/'+row.id+'/complete',{version:row.version,receipt:'consent-receipt-001'}),'DELETION_UNCONFIRMED');
 confirmed=true;assert.equal(s.call('POST','/requests/'+row.id+'/complete',{version:row.version,receipt:'consent-receipt-001'}).state,'completed');
});
