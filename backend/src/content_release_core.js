import {createHash} from 'node:crypto';
import {ADMIN_ROLES,COMMON_CHECKS,REVIEW_PROFILES,emptyAdminState} from './common_admin.js';

export class ContentReleaseError extends Error {
 constructor(status,code){super(code);this.status=status;this.code=code;}
}
const fail=(status,code)=>{throw new ContentReleaseError(status,code);};
export function canonicalContent(value){
 if(value===null||typeof value==='string'||typeof value==='boolean')return JSON.stringify(value);
 if(typeof value==='number'&&Number.isSafeInteger(value))return JSON.stringify(value);
 if(Array.isArray(value))return '['+value.map(canonicalContent).join(',')+']';
 if(value&&typeof value==='object'&&Object.getPrototypeOf(value)===Object.prototype){
  return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+canonicalContent(value[k])).join(',')+'}';
 }
 fail(400,'CONTENT_VALUE_INVALID');
}
export const contentHash=({project,reference,kind,payload})=>createHash('sha256').update(canonicalContent({project,reference,kind,payload})).digest('hex');
const auditHash=v=>createHash('sha256').update(JSON.stringify(v)).digest('hex');
const validRef=v=>typeof v==='string'&&/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(v);
const evidence=v=>typeof v==='string'&&( /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/.test(v)||safeEvidenceUrl(v));
const safeEvidenceUrl=v=>{try{const u=new URL(v);return v.length<=512&&u.protocol==='https:'&&!u.username&&!u.password&&!u.search&&!u.hash;}catch{return false;}};
const exact=(body,keys)=>{if(!body||Array.isArray(body)||Object.keys(body).sort().join(',')!==keys.slice().sort().join(','))fail(400,'CONTENT_INPUT_INVALID');};
const permissions={
 read:['owner','admin','editor','reviewer'],
 register:['owner','admin','editor'],
 rights:['owner','admin','reviewer'],
 review:['owner','admin','reviewer'],
 approve:['owner','admin'],
 publish:['owner','admin'],
 revoke:['owner','admin'],
};
export const OFFLINE_SECONDS=Object.freeze({source_quote:604800,ai_translation_draft:604800,original_creative:2592000});
export function createContentRelease({project,repository,resolve,list,baseline={entries:[]},now=Date.now}){
 if(!Object.hasOwn(REVIEW_PROFILES,project)||!repository?.read||!repository?.transaction||!repository?.write||typeof resolve!=='function'||typeof list!=='function')throw Error('CONTENT_RELEASE_CONFIGURATION_INVALID');
 const checks=[...COMMON_CHECKS,...REVIEW_PROFILES[project]];
 const legacy=new Map((baseline.project===project?baseline.entries:[]).map(row=>[row.reference,row]));
 function artifact(reference,actor){
  if(!validRef(reference))fail(400,'CONTENT_REFERENCE_INVALID');
  const value=resolve(reference,actor);if(!value)fail(404,'CONTENT_NOT_FOUND');
  if(value.project!==project||value.reference!==reference||!Object.hasOwn(OFFLINE_SECONDS,value.kind))fail(400,'CONTENT_KIND_INVALID');
  return {...value,hash:contentHash(value)};
 }
 function state(){const s=repository.read()??emptyAdminState();if(s.version!==1||!Array.isArray(s.audit)||(s.publications!==undefined&&!Array.isArray(s.publications)))fail(503,'CONTENT_STORAGE_INVALID');return s;}
 function rows(s){return s.publications??[];}
 function row(s,reference){return rows(s).find(x=>x.reference===reference);}
 function requireRole(actor,action){
  if(!actor?.actor||!ADMIN_ROLES.includes(actor.role)||!permissions[action]?.includes(actor.role))fail(403,'CONTENT_FORBIDDEN');
 }
 function audit(s,actor,action,reference,result){
  let previous='0',sequence=0;
  for(const e of s.audit){const {hash,...body}=e;if(body.seq!==++sequence||body.previous!==previous||auditHash(body)!==hash)fail(503,'CONTENT_AUDIT_INVALID');previous=hash;}
  if(sequence>=100000)fail(503,'CONTENT_AUDIT_CAPACITY');
  const body={seq:sequence+1,at:now(),actor:actor.actor,role:actor.role,action:'publication.'+action,target:reference,previous,...(result?{detail:{contentHash:result.contentHash,version:result.version}}:{})};
  s.audit.push({...body,hash:auditHash(body)});
 }
 function mutation(actor,action,reference,fn){
  requireRole(actor,action);
  return repository.transaction(()=>{
   const s=state();if(s.version!==1)fail(503,'CONTENT_STORAGE_INVALID');
   s.publications??=[];
   // Validate the existing chain before invoking any legacy publication adapter.
   const probe=structuredClone(s);audit(probe,actor,action,reference);
   const result=fn(s);
   audit(s,actor,action,reference,result);repository.write(s);return structuredClone(result);
  });
 }
 function status(a,s=state()){
  const r=row(s,a.reference),base=legacy.get(a.reference);
  if(r?.state==='revoked')return {state:'revoked',allowed:false,version:r.version,contentHash:a.hash};
  if(a.blocked)return {state:'restricted',allowed:false,version:r?.version??0,contentHash:a.hash};
  const strict=r?.contentHash===a.hash&&r.state==='published'&&(!a.distributionReady||a.distributionReady());
  const preserved=base?.contentHash===a.hash&&!r?.baselineSuppressed&&(!r||r.contentHash===a.hash);
  return {state:strict?'published':preserved?'existing_distribution':r?.contentHash===a.hash?(r.state==='published'?'withdrawn_at_source':r.state):'unreviewed',
   allowed:!!(strict||preserved),version:r?.version??0,contentHash:a.hash};
 }
 function ensureCurrent(s,reference,body,actor){
  const a=artifact(reference,actor),r=row(s,reference);
  if(!r)fail(404,'CONTENT_REGISTRATION_REQUIRED');
  if(r.version!==body.version)fail(409,'CONTENT_VERSION_CONFLICT');
  if(r.contentHash!==a.hash||body.contentHash!==a.hash)fail(409,'CONTENT_CHANGED_REVIEW_REQUIRED');
  return {a,r};
 }
 function manifest(references=list().map(x=>x.reference)){
  const s=state(),entries=[],blockedIds=[];
  for(const reference of references){
   const a=artifact(reference),decision=status(a,s);
   if(!decision.allowed){blockedIds.push(reference);continue;}
   const seconds=a.onlineOnly?0:OFFLINE_SECONDS[a.kind];
   const issuedAt=Math.floor(now()/60000)*60000;
   entries.push({reference,kind:a.kind,contentHash:a.hash,state:decision.state,offlineSeconds:seconds,
    issuedAt,expiresAt:issuedAt+(seconds===0?300:seconds)*1000});
  }
  return {schemaVersion:1,project,entries,blockedIds};
 }
 function dispatch({method,path,body,actor}){
  requireRole(actor,'read');
  if(path==='/publications'&&method==='GET'){
   const s=state();return {project,checks,items:list(actor).slice(0,500).map(source=>{
    const a=artifact(source.reference);return {reference:a.reference,kind:a.kind,title:a.payload.item?.title??a.payload.item?.reference??a.payload.item?.book??a.reference,...status(a,s)};
   })};
  }
  let m=/^\/publications\/([A-Za-z0-9][A-Za-z0-9._:-]{0,127})$/.exec(path);
  if(m&&method==='GET'){
   const a=artifact(m[1],actor);a.onOpen?.(actor);return {project,artifact:a,publication:row(state(),a.reference)??null,...status(a),checks};
  }
  if(path==='/publications'&&method==='POST'){
   exact(body,['reference']);
   return mutation(actor,'register',body.reference,s=>{
    const a=artifact(body.reference,actor),existing=row(s,a.reference);
    if(a.blocked)fail(409,'CONTENT_SCOPE_RESTRICTED');
    if(existing?.contentHash===a.hash&&existing.state!=='revoked')return existing;
    if(rows(s).length>=10000&&!existing)fail(503,'CONTENT_CAPACITY');
    const value={reference:a.reference,kind:a.kind,contentHash:a.hash,version:(existing?.version??0)+1,
     state:'draft',baselineSuppressed:existing?.state==='revoked'||existing?.baselineSuppressed===true,createdBy:actor.actor,sourceAuthor:a.author??actor.actor,createdAt:now(),updatedAt:now()};
    if(existing){s.publicationHistory??=[];if(s.publicationHistory.length>=10000)fail(503,'CONTENT_HISTORY_CAPACITY');s.publicationHistory.push(structuredClone(existing));s.publications[s.publications.indexOf(existing)]=value;}else s.publications.push(value);
    return value;
   });
  }
  m=/^\/publications\/([A-Za-z0-9][A-Za-z0-9._:-]{0,127})\/(rights|review|approve|publish|revoke)$/.exec(path);
  if(m&&method==='POST'){
   const [_,reference,action]=m;
   exact(body,action==='rights'?['version','contentHash','evidence']:action==='review'?['version','contentHash','evidence','checks']:['version','contentHash']);
   return mutation(actor,action,reference,s=>{
    if(action==='revoke'&&!row(s,reference)){
     const a=artifact(reference),value={reference,kind:a.kind,contentHash:a.hash,version:1,state:'revoked',baselineSuppressed:true,revokedBy:actor.actor,updatedAt:now()};
     if(body.version!==0||body.contentHash!==a.hash)fail(409,'CONTENT_VERSION_CONFLICT');
     a.onRevoke?.(actor);s.publications.push(value);return value;
    }
    const {a,r}=ensureCurrent(s,reference,body,actor);
    if(action!=='revoke'&&a.blocked)fail(409,'CONTENT_SCOPE_RESTRICTED');
    if(action==='rights'){
     if(r.state!=='draft')fail(409,'CONTENT_STATE_INVALID');
     if(r.sourceAuthor===actor.actor||r.createdBy===actor.actor)fail(403,'CONTENT_SELF_REVIEW');
     if(!evidence(body.evidence)||((a.kind!=='original_creative'||a.requireRightsUrl)&&!safeEvidenceUrl(body.evidence)))fail(400,'CONTENT_EVIDENCE_REQUIRED');
     if(a.rightsReady&&!a.rightsReady())fail(409,'CONTENT_LEGACY_RIGHTS_REQUIRED');
     r.rightsEvidence=body.evidence;r.rightsBy=actor.actor;r.state='rights_checked';
    }else if(action==='review'){
     if(r.state!=='rights_checked')fail(409,'CONTENT_STATE_INVALID');
     if(r.sourceAuthor===actor.actor||r.createdBy===actor.actor)fail(403,'CONTENT_SELF_REVIEW');
     exact(body.checks,checks);
     if(checks.some(k=>body.checks[k]!==true)||!evidence(body.evidence))fail(409,'CONTENT_REVIEW_INCOMPLETE');
     a.onReview?.(actor,r);r.reviewEvidence=body.evidence;r.checks=structuredClone(body.checks);r.reviewedBy=actor.actor;r.state='reviewed';
    }else if(action==='approve'){
     if(r.state!=='reviewed')fail(409,'CONTENT_STATE_INVALID');
     if([r.createdBy,r.sourceAuthor,r.reviewedBy].includes(actor.actor))fail(403,'CONTENT_INDEPENDENT_APPROVAL_REQUIRED');
     a.onApprove?.(actor,r);r.approvedBy=actor.actor;r.state='approved';
    }else if(action==='publish'){
     if(r.state!=='approved')fail(409,'CONTENT_STATE_INVALID');
     if([r.createdBy,r.sourceAuthor].includes(actor.actor))fail(403,'CONTENT_SELF_PUBLISH');
     if(typeof a.canPublish==='function'&&!a.canPublish())fail(409,'CONTENT_LEGACY_GATE_BLOCKED');
     a.onPublish?.(actor,r);r.publishedBy=actor.actor;r.hasBeenPublished=true;r.state='published';
    }else{
     if(r.state==='revoked')fail(409,'CONTENT_STATE_INVALID');
     a.onRevoke?.(actor,r);r.state='revoked';r.baselineSuppressed=true;r.revokedBy=actor.actor;
    }
    r.version++;r.updatedAt=now();return r;
   });
  }
  fail(404,'CONTENT_NOT_FOUND');
 }
 return {dispatch,manifest,artifact,isApproved:reference=>{const a=artifact(reference),r=row(state(),reference);return !a.blocked&&r?.contentHash===a.hash&&['approved','published'].includes(r.state);},decision:reference=>status(artifact(reference)),allows:reference=>status(artifact(reference)).allowed};
}
