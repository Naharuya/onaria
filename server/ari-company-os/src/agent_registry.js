import fs from 'node:fs';
import YAML from 'yaml';
export const CONTRACT_FIELDS=['id','mission','trigger','schedule','inputs','preconditions','procedure','outputs','completionCriteria','nextTasks','retryPolicy','escalationPolicy','approvalRequired','dedupeKey','concurrencyGroup','enabled'];
const OWNERS={MANAGER_CYCLE:'ari-main-manager',DAILY_REPORT:'ari-main-manager',HIGH_RISK:'ari-main-manager',DEVELOPMENT:'coding-agent',REPAIR:'repair-agent',VERIFY_PROJECT:'verification-core',RELEASE_GATE:'release-manager',PRODUCT_SIGNAL:'product-manager',PRODUCT_GOAL:'product-manager',CUSTOMER_RESEARCH:'customer-research-agent',GROWTH:'growth-agent',COMPETITOR:'competitor-agent',GOVERNMENT_GRANT:'government-grant-agent',GRANT_DEADLINE:'government-grant-agent',FINANCE:'finance-agent'};
export class AgentRegistry{
 constructor(file){this.config=YAML.parse(fs.readFileSync(file,'utf8'));this.agents=[this.config.mainManager,...this.config.agents];this.existing=this.config.existingAgents??[];const ids=new Set();for(const a of [...this.agents,...this.existing]){if(ids.has(a.id))throw new Error('duplicate_agent_id');ids.add(a.id);}for(const a of this.agents)for(const f of CONTRACT_FIELDS)if(a[f]===undefined)throw new Error(`missing_contract:${a.id}:${f}`);}
 get(id){const canonical=this.config.registryPolicy.canonicalAliases[id]??id;return [...this.agents,...this.existing].find(a=>a.id===canonical);}
 resolve(task){
  if(task.type==='DEVELOPMENT'&&task.project==='rami'&&/audio|record|playback|card.sound/i.test([task.capability,...(task.resourceScope??[])].join(' ')))return {decision:'REUSE_EXISTING',agent:this.get('rami-audio-manager')};
  const canonical=OWNERS[task.type];const requested=task.agentId?this.get(task.agentId):null;
  if(requested&&canonical&&requested.id!==canonical)return {decision:'NEW_AGENT_REQUIRED',reason:'task_owner_mismatch'};
  const agent=this.get(canonical??task.agentId??'');return agent&&agent.enabled!==false?{decision:'REUSE_EXISTING',agent}:{decision:'NEW_AGENT_REQUIRED',reason:'unknown_or_disabled_capability'};
 }
 assess(candidate){
  const exact=this.get(candidate.id)??this.get((candidate.id??'').replaceAll('-','_'));if(exact)return {decision:'REUSE_EXISTING',agent:exact.id};
  // Alias-like labels and known runtime responsibilities never create shadow owners.
  const hint=[candidate.id,candidate.mission].join(' ').toLowerCase();
  if(/\b(qa|test|verification)\b|safety.review|psychology.review/.test(hint))return {decision:'EXTEND_EXISTING',agent:'verification-core'};
  const runtime=[['safety','safety_agent'],['psychology','psychology_agent'],['citation','citation_validator'],['religion','religion_router'],['bible','religion_router'],['rami.audio','rami-audio-manager']].find(([term])=>hint.includes(term));
  if(runtime)return {decision:'EXTEND_EXISTING',agent:runtime[1]};
  const dimensions=['inputs','outputs','domain','authority','successKpi'];
  const matches=[...this.agents,...this.existing].map(a=>({a,overlap:dimensions.filter(k=>{const x=[candidate[k]].flat().filter(Boolean),y=[a[k]].flat().filter(Boolean);return x.some(v=>y.includes(v));}).length})).filter(x=>x.overlap>=2).sort((a,b)=>b.overlap-a.overlap);
  if(matches.length)return {decision:'EXTEND_EXISTING',agent:matches[0].a.id,duplicateCandidate:true,dimensions:matches[0].overlap};
  return {decision:'NEW_AGENT_REQUIRED',reason:'no_existing_owner_matches',creationAuthorized:false};
 }
}
