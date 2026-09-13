import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawn,execFileSync} from 'node:child_process';
const root=process.cwd(),sandbox=fs.mkdtempSync(path.join(os.tmpdir(),'ari-engine-daemon-'));
const source=path.join(sandbox,'fixture');fs.mkdirSync(path.join(source,'src'),{recursive:true});fs.mkdirSync(path.join(source,'.ari'));
const check={id:'value-regression',command:process.execPath,args:['-e',"if(require('./src/value.cjs')!==2)process.exit(1)"],repairable:true,repairFiles:['src/value.cjs']};
fs.writeFileSync(path.join(source,'src/value.cjs'),'module.exports = 1;\n');fs.writeFileSync(path.join(source,'.ari/verification.yaml'),JSON.stringify({project:'fixture',checks:[check]}));
for(const args of [['init','-q','-b','automation/fixture'],['add','.'],['-c','user.name=Fixture','-c','user.email=fixture@localhost','commit','-qm','fixture']])execFileSync('git',args,{cwd:source});
const registry=path.join(sandbox,'projects.yaml');fs.writeFileSync(registry,'projects: []\n');
const env={...process.env,ARI_STATE_ROOT:path.join(sandbox,'runtime'),ARI_PROJECTS_FILE:registry,ARI_POLL_INTERVAL_MS:'900000',ARI_WATCH_POLL_INTERVAL_MS:'100',ARI_QUIET_WINDOW_MS:'1200000',ARI_SCHEDULER_ENABLED:'false',ARI_CODEX_CODING_ENABLED:'true',ARI_CODEX_REPAIR_ENABLED:'true',KSTOCK_LIVE_TRADING_ENABLED:'false'};
const log=path.join(sandbox,'daemon.log'),fd=fs.openSync(log,'a');const child=spawn(process.execPath,['bin/ari-manager.js','daemon'],{cwd:root,env,stdio:['ignore',fd,fd]});const exited=new Promise(r=>child.on('exit',r));const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const queue=path.join(env.ARI_STATE_ROOT,'state/tasks.json'),tasks=()=>JSON.parse(fs.readFileSync(queue));
const invoke=(command,payload)=>{const file=path.join(sandbox,'input-'+Date.now()+'.json');fs.writeFileSync(file,JSON.stringify(payload));return JSON.parse(execFileSync(process.execPath,['bin/ari-manager.js',command,file],{cwd:root,env,encoding:'utf8'}));};
let result;
try{
 for(let i=0;i<100&&!fs.readFileSync(log,'utf8').includes('STARTED');i++)await sleep(30);
 const started=Date.now();const coding=invoke('enqueue',{type:'DEVELOPMENT',project:'fixture',projectDir:source,goal:'Change exported value to two',resourceScope:['src/value.cjs'],acceptanceCriteria:['Requiring src/value.cjs returns number 2'],approval:{approved:true,by:'owner'},focusedChecks:[check]});
 for(let i=0;i<100&&tasks().find(t=>t.id===coding.id)?.status==='PENDING';i++)await sleep(30);
 const dispatchMs=Date.now()-started;
 const risk=invoke('event',{id:'fixture-risk',type:'HIGH_RISK',category:'privacy',project:'fixture'});
 if(risk.status!=='HUMAN_REVIEW')throw new Error('urgent_risk_not_immediate');
 for(let i=0;i<600&&!tasks().some(t=>t.type==='RELEASE_GATE');i++){const t=tasks().find(t=>t.id===coding.id);if(t.status==='HUMAN_REVIEW'||t.status==='FAILED')break;await sleep(250);}
 const all=tasks();result={sandbox,log,dispatchMs,managerPollMs:900000,realCodex:true,originalUnchanged:fs.readFileSync(path.join(source,'src/value.cjs'),'utf8')==='module.exports = 1;\n',tasks:all.map(t=>({id:t.id,type:t.type,status:t.status,owner:t.owner,history:t.history,result:t.result,registryDecision:t.registryDecision}))};
 result.state=dispatchMs<5000&&result.originalUnchanged&&all.some(t=>t.type==='VERIFY_PROJECT'&&t.result?.state==='SERVER_PASS')?'SERVER_PASS':'HUMAN_REVIEW';
}finally{child.kill('SIGTERM');await exited;fs.closeSync(fd);}
const output=process.env.ARI_ENGINE_VALIDATION_REPORT??path.join(sandbox,'validation.json');fs.writeFileSync(output,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({state:result.state,dispatchMs:result.dispatchMs,output,tasks:result.tasks.map(t=>({type:t.type,status:t.status,result:t.result?.state}))},null,2));
