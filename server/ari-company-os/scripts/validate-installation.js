import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {execFileSync,spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {createCodexRepairWorker} from '../src/codex_repair_worker.js';
import {VerificationWorkflow as VerificationRunner} from '../src/repair_workflow.js';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sandbox=fs.mkdtempSync(path.join(os.tmpdir(),'ari-installation-'));
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function git(dir,args){return execFileSync('git',args,{cwd:dir,encoding:'utf8'}).trim();}
const projects=['onaria','rami','k-stock-ai'].map(id=>{
 const dir=path.join(sandbox,id);fs.mkdirSync(path.join(dir,'src'),{recursive:true});fs.mkdirSync(path.join(dir,'.ari'));
 git(dir,['init','-q','-b','automation/fixture']);
 fs.writeFileSync(path.join(dir,'src/value.cjs'),'module.exports = 1;\n');
 fs.writeFileSync(path.join(dir,'.ari/verification.yaml'),JSON.stringify({project:id,checks:[{id:'fixture-value',command:process.execPath,args:['-e',"if(require('./src/value.cjs')!==3)process.exit(1)"],repairable:false}]}));
 git(dir,['add','.']);git(dir,['-c','user.name=ARI Fixture','-c','user.email=fixture@localhost','commit','-qm','fixture']);return {id,dir};
});
const registry=path.join(sandbox,'projects.yaml');fs.writeFileSync(registry,JSON.stringify({projects}));
const log=path.join(sandbox,'daemon.log');const fd=fs.openSync(log,'a');
const child=spawn(process.execPath,[path.join(root,'bin/ari-manager.js'),'daemon'],{env:{...process.env,ARI_PROJECTS_FILE:registry,ARI_STATE_ROOT:sandbox,ARI_POLL_INTERVAL_MS:'30',ARI_WATCH_POLL_INTERVAL_MS:'30',ARI_QUIET_WINDOW_MS:'400',ARI_CODEX_REPAIR_ENABLED:'false',ARI_SCHEDULER_ENABLED:'false',KSTOCK_LIVE_TRADING_ENABLED:'false'},stdio:['ignore',fd,fd]});
const exited=new Promise(r=>child.on('exit',r));
let summary;
try {
 for(let i=0;i<100&&!fs.readFileSync(log,'utf8').includes('STARTED');i++)await sleep(30);
 await sleep(250);
 for(const p of projects)fs.writeFileSync(path.join(p.dir,'src/value.cjs'),'module.exports = 2;\n');
 await sleep(250);
 const last=Date.now();for(const p of projects)fs.writeFileSync(path.join(p.dir,'src/value.cjs'),'module.exports = 3;\n');
 await sleep(250);
 const queue=path.join(sandbox,'state/tasks.json');
 if(JSON.parse(fs.readFileSync(queue)).filter(t=>t.type==='VERIFY_PROJECT').length)throw new Error('debounce fired before quiet window');
 let tasks=[];
 for(let i=0;i<150;i++){tasks=JSON.parse(fs.readFileSync(queue)).filter(t=>t.type==='VERIFY_PROJECT');if(tasks.length===3&&tasks.every(t=>t.status==='COMPLETED'))break;await sleep(30);}
 if(tasks.length!==3||!tasks.every(t=>t.report?.state==='SERVER_PASS'))throw new Error('three project task flow failed');
 summary={sandbox,log,quietMs:400,lastChangeAt:last,projects:tasks.map(t=>({project:t.project,status:t.status,state:t.report.state,createdAt:t.createdAt})),realProjectCodeTested:false};
} finally {child.kill('SIGTERM');await exited;fs.closeSync(fd);}
if(process.argv.includes('--codex')) {
 const p=projects[0];fs.writeFileSync(path.join(p.dir,'src/value.cjs'),'module.exports = 1;\n');
 const report=await new VerificationRunner({repairWorker:createCodexRepairWorker({enabled:true})}).verify({project:'fixture',branch:'automation/fixture',cwd:p.dir,checks:[{id:'value-must-equal-2',command:process.execPath,args:['-e',"if(require('./src/value.cjs')!==2)process.exit(1)"],repairable:true,repairFiles:['src/value.cjs']}]});
 summary.codexRepair=report;
}
const output=process.env.ARI_VALIDATION_REPORT ?? path.join(sandbox,'validation.json');fs.writeFileSync(output,JSON.stringify(summary,null,2)+'\n');console.log(JSON.stringify(summary,null,2));
