import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawn} from 'node:child_process';
import YAML from 'yaml';
const root=process.cwd();
const projects=YAML.parse(fs.readFileSync('config/projects.yaml','utf8')).projects;
const stateRoot=fs.mkdtempSync(path.join(os.tmpdir(),'ari-real-watch-'));
const log=path.join(stateRoot,'daemon.log'),fd=fs.openSync(log,'a');
const child=spawn(process.execPath,['bin/ari-manager.js','daemon','--enqueue-only'],{cwd:root,env:{...process.env,ARI_STATE_ROOT:stateRoot,ARI_POLL_INTERVAL_MS:'100',ARI_WATCH_POLL_INTERVAL_MS:'100',ARI_QUIET_WINDOW_MS:'600',KSTOCK_LIVE_TRADING_ENABLED:'false'},stdio:['ignore',fd,fd]});
const exited=new Promise(r=>child.on('exit',r));const sleep=ms=>new Promise(r=>setTimeout(r,ms));const made=[];
try {
 for(let i=0;i<100&&!fs.readFileSync(log,'utf8').includes('STARTED');i++)await sleep(50);
 await sleep(1500);
 for(const p of projects){const file=path.join(p.dir,'.ari','installation-probe.js');fs.writeFileSync(file,'// ARI isolated verification worktree probe 1\n',{flag:'wx'});made.push(file);}
 await sleep(350);
 for(const file of made)fs.writeFileSync(file,'// ARI isolated verification worktree probe 2\n');
 const last=Date.now();await sleep(400);
 const queue=path.join(stateRoot,'state/tasks.json');if(JSON.parse(fs.readFileSync(queue)).length)throw new Error('early debounce');
 let tasks=[];for(let i=0;i<100;i++){tasks=JSON.parse(fs.readFileSync(queue));if(tasks.length===3)break;await sleep(100);}
 if(tasks.length!==3||!tasks.every(t=>Date.parse(t.createdAt)>=last+600))throw new Error('project watch incomplete');
 const result={state:'SERVER_PASS',mode:'enqueue-only',quietMs:600,lastChangeAt:last,log,tasks};
 fs.writeFileSync('/Users/server/ari-server/runtime/ari-company-os/evidence/actual-project-watches.json',JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));
}finally{child.kill('SIGTERM');await exited;fs.closeSync(fd);for(const file of made)fs.unlinkSync(file);}
