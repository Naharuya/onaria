import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {acquireLock} from './process_lock.js';
import {createCodexRepairWorker} from './codex_repair_worker.js';
import {AiUsageStore} from './ai_usage_store.js';
import {runCommand,secretScan,sensitiveFailure} from './verification_runner.js';
import {projectFingerprint} from './project_watcher.js';
const git=(cwd,args)=>execFileSync('git',args,{cwd,encoding:'utf8',stdio:['ignore','pipe','pipe']}).trim();
export const highRisk=text=>/safety|privacy|retention|legal|license|payment|pricing|production|publish|app.store|live.trad|secret|개인정보|법률|실거래|안전정책/i.test(typeof text==='string'?text:JSON.stringify(text));
export class CodingWorkflow{
 constructor({stateRoot,worker,repairWorker,osRoot}){this.stateRoot=stateRoot;this.osRoot=osRoot;const usageStore=new AiUsageStore(path.join(stateRoot,'state/ai-usage.jsonl'));this.worker=worker??createCodexRepairWorker({enabled:process.env.ARI_CODEX_CODING_ENABLED==='true',mode:'coding',usageStore});this.repairWorker=repairWorker??createCodexRepairWorker({enabled:process.env.ARI_CODEX_REPAIR_ENABLED==='true',usageStore});}
 async execute(task,{repair=false}={}){
  const review=reason=>({state:'HUMAN_REVIEW',reason});
  if(process.env.KSTOCK_LIVE_TRADING_ENABLED==='true')return review('live_trading_environment_blocked');
  if(!repair&&(!task.approval?.approved||task.approval?.by!=='owner'||!task.acceptanceCriteria?.length))return review('approved_development_and_criteria_required');
  if(repair&&((task.repairAttempts??0)>=2||sensitiveFailure(task.failedCheck??{})))return review('repair_limit_or_sensitive_failure');
  if(highRisk([task.riskCategory,task.goal,...(task.resourceScope??[])]))return review('sensitive_scope');
  if(!Array.isArray(task.resourceScope)||!task.resourceScope.length)return review('explicit_scope_required');
  if(!/^[A-Za-z0-9_-]+$/.test(task.id))return review('invalid_task_id');
  const source=task.projectDir,commit=git(source,['rev-parse','HEAD']);
  if(task.commit&&task.commit!==commit)return review('stale_task_commit');
  if(task.expectedFingerprint&&await projectFingerprint(source)!==task.expectedFingerprint)return review('stale_task_fingerprint');
  const common=path.resolve(source,git(source,['rev-parse','--git-common-dir']));
  const release=acquireLock(path.join(common,'ari-writer.lock'));
  try{
   const cwd=path.join(this.stateRoot,'worktrees',task.id);fs.mkdirSync(path.dirname(cwd),{recursive:true});
   if(fs.existsSync(cwd))return review('existing_task_worktree_requires_review');
   const branch='automation/ari-'+task.id;git(source,['worktree','add','-b',branch,cwd,commit]);
   const files=repair?(task.failedCheck.repairFiles??[]):task.resourceScope;
   for(const file of files){
    if(path.isAbsolute(file)||file.split('/').includes('..')||!['src/','lib/','backend/src/'].some(p=>file.startsWith(p))||highRisk(file)||/test|spec|\.env/i.test(file))return review('scope_not_automatically_writable');
    const from=path.join(source,file),to=path.join(cwd,file);
    if(!fs.existsSync(from)||!fs.existsSync(to)||fs.realpathSync(from)!==path.join(fs.realpathSync(source),file))return review('existing_regular_scoped_file_required');
    if(repair)fs.copyFileSync(from,to);
   }
   const failedCheck=repair?task.failedCheck:{id:'approved-development',command:'node',args:[],repairFiles:files};
   let specialist;if(task.owner==='rami-audio-manager')specialist=fs.readFileSync(path.resolve(this.osRoot,'../../.github/agents/rami-audio-manager.agent.md'),'utf8');
   const worker=repair?this.repairWorker:this.worker;
   const result=await worker({cwd,branch,project:task.project,failedCheck,result:task.failure??{reason:'approved_development'},attempt:(task.repairAttempts??0)+1,context:{acceptanceCriteria:task.acceptanceCriteria,specialist},taskId:task.id,agentId:task.owner});
   if(result?.humanReview)return review(result.reason??'worker_requested_review');
   if(git(cwd,['branch','--show-current'])!==branch)return review('worker_changed_branch');
   const changed=git(cwd,['diff','--name-only']).split('\n').filter(Boolean);
   if(!changed.length||changed.some(f=>!files.includes(f)))return review('empty_or_out_of_scope_diff');
   if(secretScan(cwd).length)return review('secrets_detected');
   const focused=[];
   if(!repair){if(!task.focusedChecks?.length)return review('focused_test_required');for(const check of task.focusedChecks){const checkDir=path.resolve(cwd,check.cwd??'.');if(checkDir!==cwd&&!checkDir.startsWith(cwd+path.sep))return review('focused_test_outside_worktree');if(!['node','npm','flutter',process.execPath].includes(check.command)||/deploy|publish|release|live_trade/.test((check.args??[]).join(' ')))return review('focused_command_blocked');const r=await runCommand(check.command,check.args??[],{cwd:checkDir,env:check.env,timeoutMs:check.timeoutMs});focused.push({id:check.id,...r});if(!r.ok)return {state:'FAIL',reason:'focused_test_failed',worktree:cwd,focused};}}
   const diff=git(cwd,['diff','--no-ext-diff','--',...files]);const dir=path.join(this.stateRoot,'reports',task.id);fs.mkdirSync(dir,{recursive:true});const diffPath=path.join(dir,'changes.diff');fs.writeFileSync(diffPath,diff+'\n',{flag:'wx',mode:0o600});
   return {state:'CODED',worktree:cwd,branch,commit,fingerprint:await projectFingerprint(cwd),files:changed,focused,diffPath,diffSha256:createHash('sha256').update(diff).digest('hex'),repairAttempts:(task.repairAttempts??0)+(repair?1:0)};
  }finally{release();}
 }
}
