import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {TaskQueue} from './task_queue.js';
import {VerificationRunner} from './verification_runner.js';
import {loadProfile} from './profile.js';
import {releaseState,releaseEvidence} from './policy.js';
import {AgentRegistry} from './agent_registry.js';
import {Scheduler} from './scheduler.js';
import {CodingWorkflow,highRisk} from './coding_workflow.js';
import {dailyReport} from './daily_report.js';
import {projectFingerprint} from './project_watcher.js';
import {AiUsageStore} from './ai_usage_store.js';
import {AiRouter} from './ai_router.js';
const defaultOS=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const external=new Set(['CUSTOMER_RESEARCH','GROWTH','COMPETITOR','GOVERNMENT_GRANT','FINANCE','GRANT_DEADLINE']);
const safeEvidence=t=>t.evidenceText??t.sourceData??t.inputData??null;
export class AriMainManager{
 constructor({rootDir,osRoot=defaultOS,logger=console,registry,verifier,codingWorker,repairWorker,aiRouter,externalAiComplete,handlers={}}={}){
  this.rootDir=rootDir;this.osRoot=osRoot;this.logger=logger;this.queue=new TaskQueue(path.join(rootDir,'state/tasks.json'));
  this.registry=registry??new AgentRegistry(path.join(osRoot,'config/agents.yaml'));this.queue.migrate(t=>this.registry.resolve(t));this.scheduler=new Scheduler(this.registry,this.queue);
  this.aiUsage=new AiUsageStore(path.join(rootDir,'state/ai-usage.jsonl'));this.ai=aiRouter??new AiRouter({usageStore:this.aiUsage,externalComplete:externalAiComplete});
  this.runner=verifier??new VerificationRunner();this.coding=new CodingWorkflow({stateRoot:rootDir,osRoot,worker:codingWorker,repairWorker});this.handlers=handlers;this.busy=false;
 }
 loadProjectProfile(dir){return loadProfile(dir);}
 enqueue(task){const owner=this.registry.resolve(task);return this.queue.enqueue({...task,owner:owner.agent?.id,registryDecision:{decision:owner.decision,canonicalId:owner.agent?.id},...(!owner.agent?{status:'HUMAN_REVIEW',reason:'registry_owner_required'}:{})});}
 event(event){
  const evidenceKeys={CI_RESULT:'ci',TEST_BUILD:'build',DEVICE_RESULT:'device',RELEASE_APPROVAL:'approval'};
  if(evidenceKeys[event.type]){const task=this.queue.get(event.releaseTaskId),key=evidenceKeys[event.type];if(!task||task.type!=='RELEASE_GATE'||task.status!=='BLOCKED'||(key==='approval'&&event.evidence?.by!=='owner'))return this.enqueue({type:'HIGH_RISK',project:event.project??'company',status:'HUMAN_REVIEW',goal:event.id??event.type,reason:'release_evidence_target_or_owner_invalid'});return this.queue.update(task.id,{evidence:{...task.evidence,[key]:event.evidence},status:'READY',blockKind:null});}
  if(event.type==='HIGH_RISK'||highRisk(event.category??''))return this.enqueue({type:'HIGH_RISK',project:event.project??'company',status:'HUMAN_REVIEW',reason:'high_risk_event',goal:event.id??event.category,dedupeKey:`risk:${event.project??'company'}:${event.id??event.category}`,priority:0});
  const map={BETA_FEEDBACK:'CUSTOMER_RESEARCH',SUPPORT_FEEDBACK:'CUSTOMER_RESEARCH',USER_REVIEW:'CUSTOMER_RESEARCH',CHURN_EVENT:'CUSTOMER_RESEARCH',CUSTOMER_RESEARCH_RESULT:'PRODUCT_SIGNAL',GROWTH_RESULT:'PRODUCT_SIGNAL',COMPETITOR_BUILD:'PRODUCT_SIGNAL',REPEATED_VERIFICATION_FAILURE:'PRODUCT_SIGNAL'};
  return this.enqueue({...event,type:map[event.type]??event.type,trigger:'event'});
 }
 async #execute(task){
  if(task.type==='HIGH_RISK')return {result:{state:'HUMAN_REVIEW',reason:'high_risk_event'}};
  if(this.handlers[task.type])return this.handlers[task.type](task);
  if(external.has(task.type)){
   const evidence=safeEvidence(task);if(evidence===null)return {result:{state:'DATA_SOURCE_NOT_CONNECTED',source:task.owner,reason:'no_connected_data_adapter',businessStatus:task.type==='GOVERNMENT_GRANT'?'PRE_FOUNDER':undefined}};
   const serialized=typeof evidence==='string'?evidence:JSON.stringify(evidence);if(serialized.length>200000)return {result:{state:'HUMAN_REVIEW',reason:'local_ai_input_too_large'}};
   const prompt=task.prompt??`Role: ${task.owner}. Analyze only the supplied evidence for task ${task.type}. Do not invent missing facts. Mark uncertainty explicitly. Return a concise Korean analysis with key findings, risks, and next-action candidates. Evidence:\n${serialized}`;
   const ai=await this.ai.complete({agentId:task.owner,taskId:task.id,taskType:task.type,prompt,riskCategory:task.riskCategory,sensitivity:task.sensitivity,forceLocal:true,allowEscalation:false});
   if(ai.state!=='DONE')return {result:{state:ai.state==='HUMAN_REVIEW'?'HUMAN_REVIEW':'DATA_SOURCE_NOT_CONNECTED',reason:ai.reason??'local_ai_unavailable',route:ai.route}};
   return {result:{state:'DONE',analysis:ai.text,provider:ai.provider,model:ai.model,usage:ai.usage,route:ai.route,evidenceBacked:true}};
  }
  if(task.type==='DAILY_REPORT')return {result:await dailyReport(this.queue,this.rootDir)};
  if(task.type==='MANAGER_CYCLE')return {result:{state:'CYCLE_CHECKED'}};
  if(task.type==='PRODUCT_GOAL'||task.type==='PRODUCT_SIGNAL'){
   const candidates=task.candidates??[];if(!candidates.length)return {result:{state:'DATA_INSUFFICIENT',reason:'no_evidence_backed_candidates'}};
   const seen=new Set(),nextTasks=[];for(const c of candidates){if(!c.problem||!c.userImpact||!c.businessImpact||!c.risk||!c.acceptanceCriteria?.length||!c.resourceScope?.length)continue;const key=JSON.stringify([c.project,c.problem,c.resourceScope]);if(seen.has(key))continue;seen.add(key);if(highRisk([c.problem,c.risk,c.resourceScope])){nextTasks.push({type:'HIGH_RISK',project:c.project,status:'HUMAN_REVIEW',reason:'product_sensitive_scope',goal:c.problem});continue;}nextTasks.push({type:'DEVELOPMENT',project:c.project,projectDir:c.projectDir,goal:c.problem,resourceScope:c.resourceScope,acceptanceCriteria:c.acceptanceCriteria,focusedChecks:c.focusedChecks,priority:c.severity==='critical'?0:c.severity==='high'?1:2,approval:{approved:false},dependencies:[task.id]});}
   return {result:{state:nextTasks.length?'PRODUCT_TASKS_CREATED':'DATA_INSUFFICIENT'},nextTasks};
  }
  if(task.type==='DEVELOPMENT'||task.type==='REPAIR'){
   const result=await this.coding.execute(task,{repair:task.type==='REPAIR'});const nextTasks=result.state==='CODED'?[{type:'VERIFY_PROJECT',project:task.project,projectDir:result.worktree,branch:result.branch,commit:result.commit,expectedFingerprint:result.fingerprint,repairAttempts:result.repairAttempts,acceptanceCriteria:task.acceptanceCriteria,dependencies:[task.id],resourceScope:task.resourceScope,dedupeKey:`${task.project}:verify:${result.fingerprint}`}]:[];return {result,nextTasks};
  }
  if(task.type==='VERIFY_PROJECT'){
   const profile=this.loadProjectProfile(task.projectDir);const result=await this.runner.verify({project:task.project,branch:task.branch,cwd:task.projectDir,checks:profile.checks,build:profile.build,coverage:profile.coverage,expectedFingerprint:task.expectedFingerprint});const nextTasks=[];
   if(result.state==='FAIL'&&result.repairable){if((task.repairAttempts??0)>=2){result.state='HUMAN_REVIEW';result.reason='repair_limit';}else nextTasks.push({type:'REPAIR',project:task.project,projectDir:task.projectDir,branch:task.branch,commit:result.commit,expectedFingerprint:result.fingerprint,failedCheck:result.failedCheck,failure:result.failure,repairAttempts:task.repairAttempts??0,resourceScope:result.failedCheck.repairFiles??[],acceptanceCriteria:task.acceptanceCriteria,dedupeKey:`${task.project}:repair:${result.fingerprint}:${task.repairAttempts??0}`});}
   if(result.state==='SERVER_PASS')nextTasks.push({type:'RELEASE_GATE',project:task.project,projectDir:task.projectDir,dependencies:[task.id],evidence:{commit:result.commit,fingerprint:result.fingerprint,server:{state:result.state,commit:result.commit,fingerprint:result.fingerprint},build:result.testBuild?{...result.testBuild,fingerprint:result.fingerprint}:null},dedupeKey:`${task.project}:release:${result.fingerprint}`});return {result,nextTasks};
  }
  if(task.type==='RELEASE_GATE'){
   const current={commit:execFileSync('git',['rev-parse','HEAD'],{cwd:task.projectDir,encoding:'utf8'}).trim(),fingerprint:await projectFingerprint(task.projectDir)};const evidence=structuredClone(task.evidence??{});if(evidence.build){const file=path.resolve(evidence.build.path??'');if(!file.startsWith(path.resolve(task.projectDir,'build')+path.sep)||!fs.existsSync(file)||createHash('sha256').update(fs.readFileSync(file)).digest('hex')!==evidence.build.sha256)evidence.build=null;}const gate=releaseEvidence(evidence,current);return {result:{state:gate,taskStatus:gate==='RELEASE_APPROVED'?'COMPLETED':gate==='STALE_EVIDENCE'?'HUMAN_REVIEW':'BLOCKED',blockKind:'release_gate',reason:gate,automaticRelease:false}};
  }
  return {result:{state:'HUMAN_REVIEW',reason:'unsupported_task_type'}};
 }
 async runNext(){const task=this.queue.claimNext(t=>this.registry.resolve(t));if(!task)return {state:'IDLE'};try{const {result,nextTasks=[]}=await this.#execute(task);this.queue.update(task.id,{status:'VERIFYING'});const dir=path.join(this.rootDir,'reports',task.id);fs.mkdirSync(dir,{recursive:true});const reportPath=path.join(dir,`attempt-${task.attempts}.json`);fs.writeFileSync(reportPath,JSON.stringify({taskId:task.id,owner:task.owner,registryDecision:task.registryDecision,...result},null,2)+'\n',{flag:'wx',mode:0o600});const followups=nextTasks.map(t=>{const owner=this.registry.resolve(t);return {...t,owner:owner.agent?.id,registryDecision:{decision:owner.decision,canonicalId:owner.agent?.id}};});this.queue.finish(task.id,{...result,reportPath},followups);this.logger.log?.('task_finished',{id:task.id,owner:task.owner,state:result.state});return result;}catch(error){const result={state:'HUMAN_REVIEW',reason:error.code==='HUMAN_REVIEW'?error.message:'execution_exception'};this.queue.finish(task.id,result);return result;}}
 async cycle({now=new Date(),schedule=true}={}){if(this.busy)return {state:'CYCLE_ALREADY_RUNNING'};this.busy=true;try{if(schedule)this.scheduler.tick(now);this.queue.refresh();for(const t of this.queue.list())if(t.status==='FAILED'&&t.result?.retryable&&t.result.reason==='transient_io'){const policy=this.registry.get(t.owner)?.retryPolicy;if((t.attempts??0)<=(policy?.maxAttempts??0))this.queue.update(t.id,{status:'READY'});else this.queue.update(t.id,{status:'HUMAN_REVIEW',reason:'retry_exhausted'});}let count=0;while(count<100){const result=await this.runNext();if(result.state==='IDLE')break;count++;}return {state:'CYCLE_COMPLETE',processed:count,humanReview:this.queue.list().filter(t=>t.status==='HUMAN_REVIEW').length};}finally{this.busy=false;}}
 releaseDecision(input){return releaseState(input);}
}
