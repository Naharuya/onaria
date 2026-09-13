import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawn, execFileSync} from 'node:child_process';
import {sensitiveFailure} from './verification_runner.js';
const denied = /backend\/src\/agents|psychology|test|spec|safety|security|privacy|legal|license|trad|deploy|publish|payment|secret|crisis|auth|religio|policy|config|\.env/i;
// The CLI only proposes exact replacements in read-only mode. The adapter owns writes.
export function createCodexRepairWorker({enabled=false, executable='/Users/server/.local/bin/codex', propose,mode='repair'}={}) {
  return async ({cwd,branch,failedCheck,result,attempt,context}) => {
    const review = reason => ({humanReview:true,reason});
    if (!enabled) return review('codex_worker_requires_opt_in');
    if (sensitiveFailure(failedCheck) || attempt > 2) return review('repair_policy_blocked');
    const actual=execFileSync('git',['branch','--show-current'],{cwd,encoding:'utf8'}).trim();
    if (actual !== branch || !actual.startsWith('automation/')) return review('repair_branch_blocked');
    const files=failedCheck.repairFiles;
    if (!Array.isArray(files) || files.length < 1 || files.length > 5) return review('explicit_repair_file_allowlist_required');
    const inputs=[];
    for (const file of files) {
      if (typeof file !== 'string' || !['src/','lib/','backend/src/'].some(prefix=>file.startsWith(prefix)) || denied.test(file) || file.split('/').includes('..')) return review('repair_file_blocked');
      const full=path.resolve(fs.realpathSync(cwd),file);
      if (!fs.existsSync(full) || fs.realpathSync(full) !== full || !fs.statSync(full).isFile() || fs.statSync(full).size > 32000) return review('repair_file_invalid');
      const content=fs.readFileSync(full,'utf8');
      if (/BEGIN .*PRIVATE KEY|(?:api[_-]?key|password|token|secret)\s*[:=]/i.test(content)) return review('sensitive_source_blocked');
      inputs.push({file,content});
    }
    const prompt=JSON.stringify({instruction:'Return JSON exact source replacements to fix the deterministic failure. Do not run tools, write files, change tests or relax criteria. If uncertain or safety/security/legal/trading/deployment related, return humanReview:true. Only provided files may change.',failedCheck:{id:failedCheck.id,command:failedCheck.command,args:failedCheck.args,reason:result.reason,stdout:result.stdout,stderr:result.stderr},files:inputs,context:context??null,mode});
    let proposal;
    try { proposal=propose ? await propose(prompt) : await invoke(executable,cwd,prompt); }
    catch { return review('codex_unavailable_timeout_or_invalid_output'); }
    if (proposal.humanReview || !Array.isArray(proposal.edits) || !proposal.edits.length) return review('codex_requested_review');
    const seen=new Set();
    for (const edit of proposal.edits) {
      const original=inputs.find(f=>f.file===edit.file);
      if (!original || seen.has(edit.file) || typeof edit.content !== 'string' || edit.content.length > 32000 || /skip\s*\(|todo\s*\(|KSTOCK_LIVE_TRADING_ENABLED|BEGIN .*PRIVATE KEY/i.test(edit.content)) return review('invalid_repair_proposal');
      seen.add(edit.file);
      if (fs.readFileSync(path.join(cwd,edit.file),'utf8') !== original.content) return review('concurrent_edit');
    }
    if (execFileSync('git',['branch','--show-current'],{cwd,encoding:'utf8'}).trim() !== branch) return review('branch_changed');
    for (const edit of proposal.edits) fs.writeFileSync(path.join(cwd,edit.file),edit.content);
    return {humanReview:false,files:proposal.edits.map(e=>e.file),adapter:'codex-read-only-proposal'};
  };
}
async function invoke(executable,cwd,prompt) {
  const temp=fs.mkdtempSync(path.join(os.tmpdir(),'ari-codex-'));
  const output=path.join(temp,'response.json'), schema=path.join(temp,'schema.json');
  fs.writeFileSync(schema,JSON.stringify({type:'object',additionalProperties:false,required:['humanReview','edits'],properties:{humanReview:{type:'boolean'},edits:{type:'array',items:{type:'object',additionalProperties:false,required:['file','content'],properties:{file:{type:'string'},content:{type:'string'}}}}}}));
  try {
    await new Promise((resolve,reject)=>{
      const child=spawn(executable,['exec','--ignore-user-config','--ephemeral','--sandbox','read-only','--color','never','--output-schema',schema,'--output-last-message',output,'-'],{cwd,env:{PATH:process.env.PATH,HOME:process.env.HOME,TMPDIR:process.env.TMPDIR,KSTOCK_LIVE_TRADING_ENABLED:'false'},stdio:['pipe','ignore','ignore'],detached:true});
      const timer=setTimeout(()=>{try{process.kill(-child.pid,'SIGKILL');}catch{} reject(new Error('timeout'));},120000);
      child.on('error',e=>{clearTimeout(timer);reject(e);});
      child.on('close',code=>{clearTimeout(timer);code===0?resolve():reject(new Error('codex_failed'));});
      child.stdin.on('error',()=>{}); child.stdin.end(prompt);
    });
    return JSON.parse(fs.readFileSync(output,'utf8'));
  } finally { fs.rmSync(temp,{recursive:true,force:true}); }
}
