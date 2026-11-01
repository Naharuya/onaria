import test from 'node:test';
import assert from 'node:assert/strict';
import {createContentRelease,contentHash} from '../src/content_release_core.js';
import {emptyAdminState,COMMON_CHECKS,REVIEW_PROFILES} from '../src/common_admin.js';
const writer={actor:'writer',role:'editor'},reviewer={actor:'reviewer',role:'reviewer'},approver={actor:'approver',role:'admin'};
function fixture(project,{preserved=false,onlineOnly=false}={}){
 let stored=emptyAdminState();
 const source={project,reference:'test-content-1',kind:'original_creative',payload:{item:{id:'test-content-1',title:'TEST_DATA_ONLY',body:'Synthetic content only'}},onlineOnly};
 const repository={read:()=>structuredClone(stored),write:s=>{stored=structuredClone(s);},transaction:fn=>fn()};
 const baseline={project,entries:preserved?[{reference:source.reference,contentHash:contentHash(source)}]:[]};
 const flow=createContentRelease({project,repository,baseline,resolve:id=>id===source.reference?source:null,list:()=>[{reference:source.reference}],now:()=>1800000000000});
 const invoke=(action,actor,extra={})=>{const d=flow.decision(source.reference);return flow.dispatch({method:'POST',path:'/publications/'+source.reference+'/'+action,actor,body:{version:d.version,contentHash:d.contentHash,...extra}});};
 const register=()=>flow.dispatch({method:'POST',path:'/publications',actor:writer,body:{reference:source.reference}});
 const checks=Object.fromEntries([...COMMON_CHECKS,...REVIEW_PROFILES[project]].map(k=>[k,true]));
 const review=()=>{invoke('rights',reviewer,{evidence:'rights-test-1'});invoke('review',reviewer,{evidence:'review-test-1',checks});};
 return {source,repository,flow,invoke,register,review,checks};
}
for(const project of Object.keys(REVIEW_PROFILES)){
 test(project+': complete review, independent final approval, publication and revoke',()=>{
  const f=fixture(project);assert.equal(f.flow.allows(f.source.reference),false);f.register();f.review();
  assert.throws(()=>f.invoke('approve',{...reviewer,role:'admin'}),{code:'CONTENT_INDEPENDENT_APPROVAL_REQUIRED'});
  f.invoke('approve',approver);assert.equal(f.flow.isApproved(f.source.reference),true);assert.equal(f.flow.allows(f.source.reference),false);
  f.invoke('publish',approver);assert.equal(f.flow.allows(f.source.reference),true);
  const proof=f.flow.manifest();assert.equal(proof.entries.length,1);assert.equal(proof.entries[0].state,'published');assert.equal(proof.entries[0].offlineSeconds,2592000);
  f.invoke('revoke',approver);assert.deepEqual(f.flow.manifest().blockedIds,[f.source.reference]);
 });
 test(project+': changed text invalidates approval and stale-version requests',()=>{
  const f=fixture(project);f.register();f.review();f.invoke('approve',approver);
  f.source.payload.item.body='Changed synthetic text';assert.equal(f.flow.isApproved(f.source.reference),false);
  assert.throws(()=>f.invoke('publish',approver),{code:'CONTENT_CHANGED_REVIEW_REQUIRED'});
  f.register();assert.equal(f.flow.decision(f.source.reference).state,'draft');
  assert.throws(()=>f.flow.dispatch({method:'POST',path:'/publications/'+f.source.reference+'/rights',actor:reviewer,body:{version:1,contentHash:contentHash(f.source),evidence:'rights-test-1'}}),{code:'CONTENT_VERSION_CONFLICT'});
 });
 test(project+': existing-distribution is explicit and cannot be resurrected after revocation',()=>{
  const f=fixture(project,{preserved:true});assert.equal(f.flow.decision(f.source.reference).state,'existing_distribution');
  f.invoke('revoke',approver);f.register();assert.equal(f.flow.allows(f.source.reference),false);
  f.review();f.invoke('approve',approver);f.invoke('publish',approver);assert.equal(f.flow.allows(f.source.reference),true);
 });
 test(project+': roles, own review, incomplete checks and corrupt storage fail closed',()=>{
  const f=fixture(project);assert.throws(()=>f.flow.dispatch({method:'POST',path:'/publications',actor:{actor:'audit',role:'auditor'},body:{reference:f.source.reference}}),{code:'CONTENT_FORBIDDEN'});
  f.register();assert.throws(()=>f.invoke('rights',{actor:'writer',role:'reviewer'},{evidence:'rights-test-1'}),{code:'CONTENT_SELF_REVIEW'});
  f.invoke('rights',reviewer,{evidence:'rights-test-1'});
  assert.throws(()=>f.invoke('review',reviewer,{evidence:'review-test-1',checks:{...f.checks,safety:false}}),{code:'CONTENT_REVIEW_INCOMPLETE'});
  f.repository.write({version:2,audit:[]});assert.throws(()=>f.flow.manifest(),{code:'CONTENT_STORAGE_INVALID'});
 });
 test(project+': online-only content never grants an offline allowance',()=>{
  const f=fixture(project,{preserved:true,onlineOnly:true});const entry=f.flow.manifest().entries[0];assert.equal(entry.offlineSeconds,0);assert.equal(entry.expiresAt-entry.issuedAt,300000);
 });
}
test('canonical hash binds project, reference, kind and exact source text',()=>{
 const a={project:'onaria',reference:'one',kind:'original_creative',payload:{a:1,b:'원문'}};
 assert.equal(contentHash(a),contentHash({...a,payload:{b:'원문',a:1}}));
 for(const patch of [{project:'sorua'},{reference:'two'},{kind:'source_quote'},{payload:{a:1,b:'원문 '}}])assert.notEqual(contentHash(a),contentHash({...a,...patch}));
});
