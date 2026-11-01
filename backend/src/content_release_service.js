import {readFileSync} from 'node:fs';
import {createContentRelease} from './content_release_core.js';
const read=path=>JSON.parse(readFileSync(new URL(path,import.meta.url),'utf8'));
export function contentPayload(project,catalog,item){
 const pick=keys=>Object.fromEntries(keys.filter(k=>catalog[k]!==undefined).map(k=>[k,catalog[k]]));
 if(project==='onaria')return {item,catalog:pick(['translation','copyrightNotice','englishLicense','koreanLicense'])};
 if(project==='catholic')return {item,catalog:pick(['title','sourceEdition','rightsUrl','notice'])};
 if(project==='sorua')return {item,sourceQuotation:(catalog.sourceQuotations??[]).find(q=>q.id===item.sourceQuoteId)??null,
  catalog:pick(['translation','copyrightNotice','quotationReviewDate'])};
 return {item};
}
export function publishedBuddhistItem(item){
 const rights={};
 for(const key of ['status','license','edition','translator','attribution','commercial_redistribution','excerpt_allowed'])if(item.rights?.[key]!==undefined)rights[key]=item.rights[key];
 return {id:item.id,kind:item.kind,title:item.title,body:item.body,source:item.source,rights,
  ...(item.kind==='scripture_quote'?{...(typeof item.rights.attribution==='string'?{attribution:item.rights.attribution}:{})}:{label:'앱이 만든 창작 문장 (경전 인용 아님)'})};
}
export function createPublicationService({project,repository,content,library,now=Date.now}){
 const baseline=read('./content_release_baseline.json');
 let catalog,key;
 if(project==='onaria'){catalog=read('./public_verses.json');key='verses';}
 if(project==='sorua'){catalog=read('../assets/philosophy_reflections_ko.json');key='verses';}
 if(project==='catholic'){catalog=read('../content/daily-drafts.json');key='items';}
 const staticItems=()=>catalog?.[key]?.filter(x=>x.releaseStatus!=='candidate_pending_discussion')??[];
 const nativeRef=id=>'cms:'+id;
 function resolve(reference,actor){
  const item=staticItems().find(x=>x.id===reference);
  if(item){
   const kind=project==='catholic'?'ai_translation_draft':project==='sorua'&&!item.sourceQuoteId?'original_creative':'source_quote';
   return {project,reference,kind,payload:contentPayload(project,catalog,item)};
  }
  if(project==='buddhist'&&content){
   let record;try{record=content.get(reference,actor?.actor??'publication-control',actor?.role!=='editor');}catch{return null;}
   return {project,reference,kind:record.kind==='original_creative'?'original_creative':'source_quote',
    payload:{item:publishedBuddhistItem(record)},author:record.author,onlineOnly:true,
    distributionReady:()=>{const current=content.get(reference,'publication-control',true);return current.state==='published'&&content.gate(current).length===0;},
    rightsReady:()=>record.rights.status==='APPROVED'&&content.gate(record).filter(x=>x.startsWith('RIGHTS_')||x.startsWith('SOURCE_')).length===0,
    onReview:who=>{if(record.state==='draft')content.review(reference,who.actor,{expectedVersion:record.version});},
    onApprove:who=>{const current=content.get(reference,'publication-control',true);if(current.state==='reviewed')content.approve(reference,who.actor,{expectedVersion:current.version});},
    canPublish:()=>content.gate(content.get(reference,'publication-control',true)).length===0,
    onPublish:who=>{const current=content.get(reference,'publication-control',true);if(current.state!=='published')content.publish(reference,who.actor,{expectedVersion:current.version});},
    onRevoke:who=>{const current=content.get(reference,'publication-control',true);if(current.state!=='archived')content.archive(reference,who.actor,{expectedVersion:current.version});}};
  }
  if(project==='catholic'&&reference.startsWith('cms:')&&library?.approvalSnapshot){
   let record;try{record=library.approvalSnapshot(reference.slice(4));}catch{return null;}
   const kind=record.kind==='reflection'?'original_creative':'source_quote';
   const payload={item:{id:reference,kind:record.kind,title:record.title,text:record.text,sourceUrl:record.sourceUrl,attribution:record.attribution,...(record.reference?{reference:record.reference}:{})}};
   return {project,reference,kind,payload,author:record.author,requireRightsUrl:true,blocked:record.kind==='doctrine',
    onOpen:who=>library.inspect({accountId:who.actor,role:who.role},record.id),
    onReview:(who,row)=>{if(!['reviewed','published'].includes(library.approvalSnapshot(record.id).state))library.review({accountId:who.actor,role:who.role},record.id,{rightsEvidence:row.rightsEvidence,doctrineReviewed:true});},
    distributionReady:()=>{const current=library.approvalSnapshot(record.id);return current.state==='published'&&!current.replacedBy;},
    canPublish:()=>['reviewed','published'].includes(library.approvalSnapshot(record.id).state),
    onPublish:who=>{if(library.approvalSnapshot(record.id).state!=='published')library.publish({accountId:who.actor,role:who.role},record.id);},
    onRevoke:who=>library.revoke({accountId:who.actor,role:who.role},record.id)};
  }
  return null;
 }
 function list(actor){
  if(project==='buddhist')return (content?.list({actor:actor?.actor??'publication-control',canSeeAll:actor?.role!=='editor'})??[]).map(x=>({reference:x.id}));
  const result=staticItems().map(x=>({reference:x.id}));
  if(project==='catholic'&&actor&&library?.list)for(const row of library.list({accountId:actor.actor,role:actor.role}))result.push({reference:nativeRef(row.id)});
  return result;
 }
 const workflow=createContentRelease({project,repository,resolve,list,baseline,now});
 if(library?.setPublicationPolicy)library.setPublicationPolicy({
  canRead:id=>workflow.allows(nativeRef(id)),
  canPublish:id=>workflow.isApproved(nativeRef(id))&&workflow.decision(nativeRef(id)).state==='approved',
 });
 return {...workflow,
  catalog(){
   if(!catalog)return null;
   const release=workflow.manifest(staticItems().map(x=>x.id));
   const permitted=new Set(release.entries.map(x=>x.reference));
   const items=staticItems().filter(x=>permitted.has(x.id));
   const sources=new Set(items.map(x=>x.sourceQuoteId).filter(Boolean));
   return {...structuredClone(catalog),[key]:items,...(project==='sorua'?{sourceQuotations:(catalog.sourceQuotations??[]).filter(x=>sources.has(x.id))}:{}),_release:release};
  },
  publicItems(){
   if(project!=='buddhist')return [];
   return content.listPublished().filter(x=>content.gate(x).length===0&&workflow.allows(x.id)).slice(0,20).map(publishedBuddhistItem);
  },
  publicManifest(){
   if(project!=='buddhist')return workflow.manifest(staticItems().map(x=>x.id));
   return workflow.manifest(content.listPublished().filter(x=>content.gate(x).length===0&&workflow.allows(x.id)).slice(0,20).map(x=>x.id));
  },
 };
}
