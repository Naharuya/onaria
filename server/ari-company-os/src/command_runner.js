import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
export function redactOutput(value){
 return value.replace(/-----BEGIN [^-]*PRIVATE KEY-----[\s\S]*?(?:-----END [^-]*PRIVATE KEY-----|$)/g,'[REDACTED_PRIVATE_KEY]')
  .split('\n').map(line=>/\bsk-(?:proj-)?[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9]{12,}|api[_ -]?key|password|secret|bearer\s|authorization|access[_ -]?token|userMessage|private[_ -]?key/i.test(line)?'[REDACTED_SENSITIVE_LINE]':line).join('\n');
}
export function runCommand(command,args,{cwd,env={},timeoutMs=1800000}={}){
 return new Promise(resolve=>{
  const child=spawn(command,args,{cwd,env:{PATH:process.env.PATH,HOME:process.env.HOME,TMPDIR:process.env.TMPDIR,...env,...(env.KSTOCK_AI_MODE==='mock'?{NODE_OPTIONS:'--require='+fileURLToPath(new URL('./network_guard.cjs',import.meta.url))}:{}),KSTOCK_LIVE_TRADING_ENABLED:'false'},stdio:['ignore','pipe','pipe'],shell:false,detached:true});
  let done=false,stdout='',stderr='',outCut=false,errCut=false;
  const tail=(data,kind)=>{if(kind==='out'){stdout+=data;if(stdout.length>32768){stdout=stdout.slice(-32768);outCut=true;}}else{stderr+=data;if(stderr.length>32768){stderr=stderr.slice(-32768);errCut=true;}}};
  const safe=(s,cut)=>redactOutput(cut?s.slice(s.indexOf('\n')+1||s.length):s);
  child.stdout.on('data',d=>tail(d.toString(),'out'));child.stderr.on('data',d=>tail(d.toString(),'err'));
  const finish=(code,reason)=>{if(done)return;done=true;clearTimeout(timer);resolve({code,ok:code===0,reason,stdout:safe(stdout,outCut),stderr:safe(stderr,errCut)});};
  const timer=setTimeout(()=>{try{process.kill(-child.pid,'SIGKILL');}catch{}finish(null,'timeout');},timeoutMs);
  child.on('error',()=>finish(null,'spawn_failed'));child.on('close',code=>finish(code,code===0?'passed':'nonzero_exit'));
 });
}
