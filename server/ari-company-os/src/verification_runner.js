import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {assertAutomationAllowed} from './policy.js';
import {projectFingerprint} from './project_watcher.js';
import {runCommand} from './command_runner.js';
export {runCommand} from './command_runner.js';
export const sensitiveFailure=c=>c.humanReviewOnFail===true||/safety|security|privacy|legal|license|trading|trade|deploy|publish|payment|secret|crisis|religio/i.test([c.id,c.category,c.command,...(c.args??[])].join(' '));
const SECRETS=[/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,/gh[pousr]_[A-Za-z0-9]{30,}/,/\bsk-(?:proj-)?[A-Za-z0-9_-]{30,}/];
export function secretScan(cwd){
 const names=execFileSync('git',['ls-files','-z','--cached','--others','--exclude-standard'],{cwd,maxBuffer:16*1024*1024,encoding:'utf8'}).split('\0').filter(Boolean),findings=[];
 for(const name of new Set(names)){
  if(/(^|\/)(node_modules|data|state|logs|build|backups)(\/|$)|\.(db|sqlite\d*|png|jpg|mp4|zip|pdf|lock)$/i.test(name))continue;
  if(/(^|\/)\.env($|\.)/.test(name)&&!name.endsWith('.example')){findings.push({path:name,reason:'credential_file_present'});continue;}
  const file=path.join(cwd,name);try{const st=fs.lstatSync(file);if(st.isFile()&&st.size<1024*1024&&SECRETS.some(p=>p.test(fs.readFileSync(file,'utf8'))))findings.push({path:name,reason:'credential_pattern'});}catch{}
 }return findings;
}
const stage=c=>({lint:0,analyze:0,unit:1,integration:2,smoke:2,risk:3,build:4}[c.stage]??(/analyze|lint/.test(c.id)?0:/smoke|rag/.test(c.id)?2:/safety|psych|citation|risk|audio|ndef|link/.test(c.id)?3:1));
export class VerificationRunner{
 constructor({logger=console}={}){this.logger=logger;}
 async verify({project,branch,cwd,checks,expectedFingerprint,build,coverage}){
  const report={project,branch,startedAt:new Date().toISOString(),state:'VERIFYING',checks:[],repairs:[]};
  const finish=(state,extra={})=>({...report,...extra,state,completedAt:new Date().toISOString()});
  try{
   report.commit=execFileSync('git',['rev-parse','HEAD'],{cwd,encoding:'utf8'}).trim();
   const actual=execFileSync('git',['branch','--show-current'],{cwd,encoding:'utf8'}).trim();
   if(actual!==branch||!actual.startsWith('automation/'))return finish('HUMAN_REVIEW',{reason:'branch_mismatch_or_not_automation'});
   assertAutomationAllowed({project,branch:actual,action:'verification'});
   if(process.env.KSTOCK_LIVE_TRADING_ENABLED==='true'||checks?.some(c=>c.env?.KSTOCK_LIVE_TRADING_ENABLED==='true'))return finish('HUMAN_REVIEW',{reason:'live_trading_environment_blocked'});
   report.fingerprint=await projectFingerprint(cwd);
   if(expectedFingerprint&&expectedFingerprint!==report.fingerprint)return finish('HUMAN_REVIEW',{reason:'stale_verification_input'});
   if(!checks?.length)return finish('HUMAN_REVIEW',{reason:'empty_checks'});
   const diff=await runCommand('git',['diff','--check'],{cwd});report.checks.push({id:'core-git-diff-check',...diff});if(!diff.ok)return finish('FAIL');
   const secrets=secretScan(cwd);report.checks.push({id:'core-secret-scan',ok:secrets.length===0,findings:secrets});if(secrets.length)return finish('HUMAN_REVIEW',{reason:'secrets_detected'});
   for(const check of [...checks].filter(c=>c.id!=='git-diff-check').sort((a,b)=>stage(a)-stage(b))){
    if(/\b(deploy|publish|live_trade|release)\b/i.test([check.command,...(check.args??[])].join(' ')))return finish('HUMAN_REVIEW',{reason:'forbidden_verification_action'});
    const checkDir=path.resolve(cwd,check.cwd??'.'),real=fs.realpathSync(checkDir),base=fs.realpathSync(cwd);
    if(real!==base&&!real.startsWith(base+path.sep))return finish('HUMAN_REVIEW',{reason:'check_cwd_outside_project'});
    const result=await runCommand(check.command,check.args??[],{cwd:checkDir,env:check.env,timeoutMs:check.timeoutMs});report.checks.push({id:check.id,...result});
    if(!result.ok)return finish(sensitiveFailure(check)?'HUMAN_REVIEW':'FAIL',{failedCheck:check,failure:result,repairable:check.repairable===true&&!sensitiveFailure(check)});
   }
   if(coverage){
    const passed=new Set(report.checks.filter(c=>c.ok).map(c=>c.id));
    const missing=(coverage.required??[]).filter(cap=>!coverage.checksByCapability?.[cap]?.length||!coverage.checksByCapability[cap].every(id=>passed.has(id)));
    report.coverage={required:coverage.required,missing};
    if(missing.length)return finish('HUMAN_REVIEW',{reason:'required_capability_tests_missing'});
   }
   if(build?.automatic){
    if(build.command!=='flutter'||JSON.stringify(build.args)!==JSON.stringify(['build','apk','--debug']))return finish('HUMAN_REVIEW',{reason:'only_debug_apk_build_allowed'});
    const result=await runCommand(build.command,build.args,{cwd,timeoutMs:1800000});report.checks.push({id:'debug-apk',...result});if(!result.ok)return finish('FAIL',{reason:'test_build_failed'});
    const artifact=path.resolve(cwd,build.artifact);if(!artifact.startsWith(path.resolve(cwd,'build')+path.sep)||!fs.existsSync(artifact))return finish('FAIL',{reason:'missing_test_artifact'});
    report.testBuild={path:artifact,sha256:createHash('sha256').update(fs.readFileSync(artifact)).digest('hex'),commit:report.commit};
   }
   if(await projectFingerprint(cwd)!==report.fingerprint)return finish('HUMAN_REVIEW',{reason:'source_changed_during_verification'});
   return finish('SERVER_PASS');
  }catch{return finish('HUMAN_REVIEW',{reason:'verification_exception'});}
 }
}
