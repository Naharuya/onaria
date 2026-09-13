import fs from 'node:fs';
import path from 'node:path';
import {randomUUID,createHash} from 'node:crypto';
import {acquireLock} from './process_lock.js';
export const ACTIVE = new Set(['PENDING','READY','IN_PROGRESS','VERIFYING','BLOCKED','HUMAN_REVIEW']);
export const TRANSITIONS = {
 PENDING:['READY','BLOCKED','HUMAN_REVIEW','CANCELLED'],
 READY:['IN_PROGRESS','BLOCKED','HUMAN_REVIEW','CANCELLED'],
 IN_PROGRESS:['VERIFYING','FAILED','HUMAN_REVIEW','BLOCKED','CANCELLED'],
 VERIFYING:['COMPLETED','FAILED','HUMAN_REVIEW','BLOCKED','CANCELLED'],
 BLOCKED:['READY','HUMAN_REVIEW','CANCELLED'],
 FAILED:['READY','HUMAN_REVIEW','CANCELLED'],
 HUMAN_REVIEW:['PENDING','CANCELLED'],COMPLETED:[],CANCELLED:[]
};
function taskKey(t){return t.dedupeKey??`${t.project??'company'}:${t.type??'TASK'}:${[...(t.resourceScope??[])].sort().join(',')}:${createHash('sha256').update(JSON.stringify(t.goal??t.acceptanceCriteria??t.id??t.type??'task')).digest('hex').slice(0,20)}`;}
export class TaskQueue {
 constructor(filePath){this.filePath=filePath;fs.mkdirSync(path.dirname(filePath),{recursive:true});try{fs.writeFileSync(filePath,'[]\n',{flag:'wx',mode:0o600});}catch(e){if(e.code!=='EEXIST')throw e;}}
 #read(){const tasks=JSON.parse(fs.readFileSync(this.filePath,'utf8'));if(!Array.isArray(tasks))throw new Error('invalid_queue');return tasks;}
 #write(tasks){const tmp=this.filePath+'.tmp';fs.writeFileSync(tmp,JSON.stringify(tasks,null,2)+'\n',{mode:0o600});fs.renameSync(tmp,this.filePath);}
 #transaction(fn){const release=acquireLock(this.filePath+'.lock');try{const tasks=this.#read(),before=JSON.stringify(tasks);const result=fn(tasks);if(JSON.stringify(tasks)!==before)this.#write(tasks);return structuredClone(result);}finally{release();}}
 migrate(resolveOwner){return this.#transaction(tasks=>{
  for(const t of tasks){
   if(t.schemaVersion===3)continue;
   const owner=resolveOwner(t);
   t.owner??=owner.agent?.id??'ari-main-manager';
   t.registryDecision??={decision:owner.decision,canonicalId:t.owner,migration:true};
   t.ownerAssignment??='migration_inferred_from_type';
   t.dedupeKey??=t.reason==='source_changed_requires_worktree_sync_review'?`${t.project}:source-review`:`legacy:${t.id}`;
   t.concurrencyGroup??=`project:${t.project??'company'}`;t.resourceScope??=[];
   t.history??=[{to:t.status,at:t.updatedAt??t.createdAt,migration:true}];
   if(t.report&&!t.result)t.result=t.report;t.schemaVersion=3;
  }return tasks;
 });}
 list(){return this.#read();}
 get(id){return this.list().find(t=>t.id===id);}
 #insert(tasks,t){
  const key=taskKey(t),existing=tasks.find(x=>x.dedupeKey===key&&(ACTIVE.has(x.status)||t.once));
  if(existing)return existing;
  const now=new Date().toISOString(),status=t.status??'PENDING';
  if(!['PENDING','HUMAN_REVIEW'].includes(status))throw new Error('invalid_initial_state');
  if(t.id&&!/^[A-Za-z0-9_-]+$/.test(t.id))throw new Error('invalid_task_id');
  if(t.id&&tasks.some(x=>x.id===t.id))throw new Error('duplicate_task_id');
  const record={schemaVersion:3,...t,id:t.id??'task-'+randomUUID(),dedupeKey:key,concurrencyGroup:t.concurrencyGroup??`project:${t.project??'company'}`,resourceScope:t.resourceScope??[],status,createdAt:now,updatedAt:now,attempts:0,dependencies:t.dependencies??[],history:[{to:status,at:now}]};
  if(record.dependencies.includes(record.id))throw new Error('self_dependency');
  tasks.push(record);return record;
 }
 enqueue(task){return this.#transaction(tasks=>this.#insert(tasks,task));}
 #patch(tasks,id,patch){
  const t=tasks.find(t=>t.id===id);if(!t)throw new Error('unknown_task');
  const next=patch.status;
  if(next&&next!==t.status&&!TRANSITIONS[t.status]?.includes(next))throw new Error(`invalid_transition:${t.status}:${next}`);
  if(patch.id&&patch.id!==id)throw new Error('immutable_task_id');
  if(next&&next!==t.status)t.history=[...(t.history??[]),{from:t.status,to:next,at:new Date().toISOString()}];
  Object.assign(t,patch,{updatedAt:new Date().toISOString()});return t;
 }
 update(id,patch){return this.#transaction(tasks=>this.#patch(tasks,id,patch));}
 #refresh(tasks){
  for(const t of tasks){
   if(!['PENDING','READY','BLOCKED'].includes(t.status)||t.blockKind&&t.blockKind!=='dependency'&&t.blockKind!=='concurrency')continue;
   if(t.notBefore&&Date.parse(t.notBefore)>Date.now())continue;
   const blocked=(t.dependencies??[]).some(id=>tasks.find(x=>x.id===id)?.status!=='COMPLETED');
   const status=blocked?'BLOCKED':'READY';
   if(t.status!==status)this.#patch(tasks,t.id,{status,blockKind:blocked?'dependency':null});
  }
 }
 refresh(){return this.#transaction(tasks=>{this.#refresh(tasks);return tasks;});}
 nextReady(){return this.refresh().find(t=>t.status==='READY')??null;}
 claimNext(resolveOwner){return this.#transaction(tasks=>{
  this.#refresh(tasks);
  const ready=tasks.filter(t=>t.status==='READY').sort((a,b)=>(a.priority??2)-(b.priority??2)||a.createdAt.localeCompare(b.createdAt));
  for(const t of ready){
   const locked=tasks.some(x=>x.id!==t.id&&['IN_PROGRESS','VERIFYING'].includes(x.status)&&(x.concurrencyGroup===t.concurrencyGroup||(t.project&&x.project===t.project)));
   if(locked){this.#patch(tasks,t.id,{status:'BLOCKED',blockKind:'concurrency'});continue;}
   const owner=resolveOwner(t);
   if(!owner.agent||owner.decision==='NEW_AGENT_REQUIRED'){this.#patch(tasks,t.id,{status:'HUMAN_REVIEW',reason:'registry_owner_required',registryDecision:owner});continue;}
   return this.#patch(tasks,t.id,{status:'IN_PROGRESS',owner:owner.agent.id,registryDecision:{decision:owner.decision,canonicalId:owner.agent.id},attempts:(t.attempts??0)+1,startedAt:new Date().toISOString()});
  }return null;
 });}
 finish(id,result,nextTasks=[]){return this.#transaction(tasks=>{
  const task=tasks.find(t=>t.id===id);if(task.status==='IN_PROGRESS')this.#patch(tasks,id,{status:'VERIFYING'});
  const status=result.taskStatus??(result.state==='HUMAN_REVIEW'?'HUMAN_REVIEW':result.state==='FAIL'?'FAILED':result.state==='DATA_SOURCE_NOT_CONNECTED'?'BLOCKED':'COMPLETED');
  this.#patch(tasks,id,{status,result,report:result,completedAt:new Date().toISOString(),...(status==='BLOCKED'?{blockKind:result.blockKind??'data_source'}:{})});
  const followups=nextTasks.map(t=>this.#insert(tasks,{...t,triggerTaskId:id}));task.nextTaskIds=followups.map(t=>t.id);return {task,followups};
 });}
 recover(){return this.#transaction(tasks=>{for(const t of tasks)if(['IN_PROGRESS','VERIFYING'].includes(t.status))this.#patch(tasks,t.id,{status:'HUMAN_REVIEW',reason:'interrupted_by_restart'});return tasks;});}
}
