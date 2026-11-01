import {createHash, randomUUID} from 'node:crypto';

// Repository and service adapters belong to this app. This module never opens another app's DB.
export const ADMIN_ROLES = Object.freeze(['owner','admin','editor','reviewer','support','operator','viewer']);
const permissions = {
 owner:['accounts','read','members','requests','approve','inquiries','audit','backup','content','review'],
 admin:['read','members','requests','approve','inquiries','audit','backup','content','review'],
 editor:['read','content'],
 reviewer:['read','content','review'],
 support:['read','requests','inquiries'],
 operator:['read','audit','backup'],
 viewer:['read'],
};
export const adminCan = (role, permission) => Object.hasOwn(permissions,role) && permissions[role].includes(permission);
export const COMMON_CHECKS = Object.freeze(['source','rights','translation','safety']);
export const REVIEW_PROFILES = Object.freeze({
 onaria:['biblicalContext','translationEdition','denominationalDistinction'],
 buddhist:['canonicalLocator','traditionDistinction','originalTranslationSeparation'],
 catholic:['catholicCanon','approvedEditionDisclosure','doctrinalScopeRestriction'],
 sorua:['authorWorkLocator','quotationAuthenticity','pluralPerspectives'],
});
export class AdminControlError extends Error {
 constructor(status,code){super(code);this.status=status;this.code=code;}
}
const fail=(status,code)=>{throw new AdminControlError(status,code);};
const clone=value=>structuredClone(value);
const ref=value=>{
 if(typeof value!=='string'||!/^[a-zA-Z0-9][a-zA-Z0-9._:-]{2,95}$/.test(value))fail(400,'INVALID_REFERENCE');
 return value;
};
const exact=(value,keys)=>{
 if(!value||Array.isArray(value)||typeof value!=='object'||Object.keys(value).sort().join(',')!==keys.slice().sort().join(','))fail(400,'INVALID_INPUT');
};
const digest=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
export function emptyAdminState(){return {version:1,requests:[],inquiries:[],reviews:[],audit:[]};}

// Each command and its minimal audit event commit together. The repository rolls both back on failure.
export function createAdminControl({project,repository,members,verifyDeletion,inspectBackup,accountManagement='named',now=Date.now}={}){
 if(!Object.hasOwn(REVIEW_PROFILES,project)||!repository?.transaction||!repository?.read||!repository?.write)throw new Error('ADMIN_CONFIGURATION_INVALID');
 const checks=[...COMMON_CHECKS,...REVIEW_PROFILES[project]];
 function authorized(actor,permission){
  if(!actor||typeof actor.actor!=='string'||!actor.actor.length||!adminCan(actor.role,permission))fail(403,'FORBIDDEN');
 }
 function event(state,actor,action,id){
  const row={seq:state.audit.length+1,at:now(),actor:actor.actor,role:actor.role,action,target:id??'-',previous:state.audit.at(-1)?.hash??'0'};
  state.audit.push({...row,hash:digest(row)});
 }
 function mutate(actor,permission,action,fn){
  authorized(actor,permission);
  return repository.transaction(()=>{
   const state=repository.read()??emptyAdminState();
   if(state.version!==1||!auditValid(state.audit)||state.audit.length>=100000)fail(503,'ADMIN_STORAGE_UNAVAILABLE');
   const result=fn(state);
   event(state,actor,action,result?.id);
   repository.write(state);
   return clone(result??{ok:true});
  });
 }
 const load=(rows,id)=>rows.find(r=>r.id===id)??fail(404,'NOT_FOUND');
 const revision=(row,input)=>{if(!Number.isInteger(input.version)||row.version!==input.version)fail(409,'VERSION_CONFLICT');};
 const updated=row=>{row.version++;row.updatedAt=now();return row;};
 const add=(rows,value)=>{if(rows.length>=10000)fail(503,'ADMIN_CAPACITY');rows.push(value);return value;};
 function auditValid(rows){
  let previous='0',seq=0;
  for(const entry of rows){const {hash,...row}=entry;if(row.previous!==previous||row.seq!==++seq||digest(row)!==hash)return false;previous=hash;}
  return true;
 }
 function dispatchInner({method,path,body,actor}){
  authorized(actor,'read');
  if(path==='/standard'&&method==='GET')return {version:1,project,role:actor.role,accountManagement,roles:ADMIN_ROLES,permissions:permissions[actor.role],checks,capabilities:{memberCounts:!!members,deletionCompletion:!!verifyDeletion,backupEvidence:!!inspectBackup},automaticDeletion:false};
  if(path==='/members'&&method==='GET'){
   authorized(actor,'members');if(!members)fail(503,'MEMBER_ADAPTER_UNAVAILABLE');
   const value=members();
   if(!Number.isSafeInteger(value?.total)||value.total<0)fail(503,'MEMBER_ADAPTER_UNAVAILABLE');
   // Only counts are returned. Names, phones, provider identities and reflection text are excluded.
   return {total:value.total};
  }
  if(path==='/audit'&&method==='GET'){
   authorized(actor,'audit');const state=repository.read()??emptyAdminState();
   return {valid:auditValid(state.audit),events:state.audit.slice(-200).reverse()};
  }
  if(path==='/backup'&&method==='GET'){
   authorized(actor,'backup');
   if(!inspectBackup)return {configured:false,backup:'UNVERIFIED',restore:'UNVERIFIED',deletionProtection:'UNVERIFIED'};
   const result=inspectBackup();
   const status=value=>['PASS','FAIL'].includes(value)?value:'UNVERIFIED';
   return {configured:true,backup:status(result?.backup),restore:status(result?.restore),deletionProtection:status(result?.deletionProtection),
    checkedAt:Number.isSafeInteger(result?.checkedAt)?result.checkedAt:null,
    environment:['synthetic','candidate','production'].includes(result?.environment)?result.environment:'unknown'};
  }
  for(const [route,permission] of [['requests','requests'],['inquiries','inquiries'],['reviews','content']]){
   if(path==='/'+route&&method==='GET'){authorized(actor,permission);return {items:(repository.read()??emptyAdminState())[route].slice(-200).reverse()};}
  }
  if(path==='/requests'&&method==='POST'){
   exact(body,['reference','kind']);
   if(!['account_deletion','server_records','consent_withdrawal'].includes(body.kind))fail(400,'INVALID_KIND');
   return mutate(actor,'requests','request.received',s=>add(s.requests,{id:randomUUID(),reference:ref(body.reference),kind:body.kind,
    state:'received',version:1,createdAt:now(),updatedAt:now(),createdBy:actor.actor}));
  }
  let match=/^\/requests\/([a-f0-9-]{36})\/(verify|approve|processing|complete|reject)$/.exec(path);
  if(match&&method==='POST'){
   exact(body,match[2]==='complete'?['version','receipt']:['version']);
   return mutate(actor,match[2]==='approve'?'approve':'requests','request.'+match[2],s=>{
    const row=load(s.requests,match[1]);revision(row,body);
    if(match[2]==='verify'){
     if(row.state!=='received')fail(409,'INVALID_STATE');
     // This acknowledges routing to the existing identity-confirmed self-service path; it grants no deletion power.
     row.state='identity_pending';
    }else if(match[2]==='approve'){
     if(row.state!=='identity_pending')fail(409,'INVALID_STATE');
     if(row.createdBy===actor.actor)fail(403,'INDEPENDENT_APPROVAL_REQUIRED');
     row.state='approved';row.approvedBy=actor.actor;
    }else if(match[2]==='processing'){
     if(row.state!=='approved')fail(409,'INVALID_STATE');row.state='processing';
    }else if(match[2]==='complete'){
     if(row.state!=='processing')fail(409,'INVALID_STATE');
     if(!verifyDeletion)fail(503,'DELETION_VERIFIER_UNAVAILABLE');
     const receipt=ref(body.receipt);
     const evidence=verifyDeletion({project,reference:row.reference,kind:row.kind,receipt});
     if(!evidence||evidence.project!==project||evidence.reference!==row.reference||evidence.kind!==row.kind||
        evidence.completed!==true||evidence.identityVerified!==true||
        (row.kind==='account_deletion'&&(evidence.sessionsRevoked!==true||evidence.backupProtected!==true||evidence.providerRevoked!==true))||
        (row.kind==='server_records'&&evidence.backupProtected!==true)||
        (row.kind==='consent_withdrawal'&&(evidence.consentUpdated!==true||evidence.dataDispositionVerified!==true)))fail(409,'DELETION_UNCONFIRMED');
     row.state='completed';row.receipt=receipt;
    }else{
     if(['completed','rejected'].includes(row.state))fail(409,'INVALID_STATE');row.state='rejected';
    }
    return updated(row);
   });
  }
  if(path==='/inquiries'&&method==='POST'){
   exact(body,['reference','category']);
   if(!['general','privacy','technical','content'].includes(body.category))fail(400,'INVALID_CATEGORY');
   return mutate(actor,'inquiries','inquiry.received',s=>add(s.inquiries,{id:randomUUID(),reference:ref(body.reference),category:body.category,
    state:'received',version:1,createdAt:now(),updatedAt:now(),createdBy:actor.actor}));
  }
  match=/^\/inquiries\/([a-f0-9-]{36})\/(assign|resolve|reopen)$/.exec(path);
  if(match&&method==='POST'){
   exact(body,match[2]==='assign'?['version','assignee']:['version']);
   return mutate(actor,'inquiries','inquiry.'+match[2],s=>{
    const row=load(s.inquiries,match[1]);revision(row,body);
    if(match[2]==='assign'){if(row.state==='resolved')fail(409,'INVALID_STATE');row.assignee=ref(body.assignee);row.state='assigned';}
    else if(match[2]==='resolve'){if(row.state!=='assigned')fail(409,'INVALID_STATE');row.state='resolved';}
    else{if(row.state!=='resolved')fail(409,'INVALID_STATE');row.state='received';}
    return updated(row);
   });
  }
  if(path==='/reviews'&&method==='POST'){
   exact(body,['reference','revision']);
   return mutate(actor,'content','content.review.open',s=>add(s.reviews,{id:randomUUID(),reference:ref(body.reference),revision:ref(body.revision),
    state:'pending',version:1,createdBy:actor.actor,createdAt:now(),updatedAt:now(),profile:project}));
  }
  match=/^\/reviews\/([a-f0-9-]{36})\/inspect$/.exec(path);
  if(match&&method==='POST'){
   exact(body,['version','checks','evidence']);
   return mutate(actor,'review','content.review.inspect',s=>{
    const row=load(s.reviews,match[1]);revision(row,body);
    if(row.createdBy===actor.actor)fail(403,'INDEPENDENT_REVIEW_REQUIRED');
    if(row.state!=='pending')fail(409,'INVALID_STATE');
    exact(body.checks,checks);
    if(checks.some(key=>body.checks[key]!==true))fail(409,'CONTENT_REVIEW_INCOMPLETE');
    row.evidence=ref(body.evidence);row.checks=clone(body.checks);row.reviewedBy=actor.actor;row.state='reviewed';
    // Review never publishes material or changes existing source, rights, doctrine or release gates.
    return updated(row);
   });
  }
  fail(404,'NOT_FOUND');
 }
 function dispatch(input){
  try{return dispatchInner(input);}
  catch(error){
   if(error instanceof AdminControlError&&input.actor?.actor){
    try{repository.transaction(()=>{
     const state=repository.read()??emptyAdminState();
     if(auditValid(state.audit)&&state.audit.length<100000){event(state,input.actor,'admin.request.'+error.code);repository.write(state);}
    });}catch{/* Never turn an access denial into a success if the audit store fails. */}
   }
   throw error;
  }
 }
 return {dispatch,checks};
}
