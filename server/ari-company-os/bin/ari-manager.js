#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import YAML from 'yaml';
import {execFileSync} from 'node:child_process';
import {AriMainManager} from '../src/main_manager.js';
import {rotatingLogger} from '../src/logger.js';
import {acquireLock} from '../src/process_lock.js';
import {loadProfile} from '../src/profile.js';
import {ProjectWatcher,projectFingerprint} from '../src/project_watcher.js';
const osRoot=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const stateRoot=path.resolve(process.env.ARI_STATE_ROOT??osRoot);
if(process.env.ARI_LOG_DIR){const log=rotatingLogger(process.env.ARI_LOG_DIR);console.log=log.log;console.error=log.error;}
const manager=new AriMainManager({rootDir:stateRoot,osRoot});
const [command,...args]=process.argv.slice(2);
const branch=dir=>execFileSync('git',['branch','--show-current'],{cwd:dir,encoding:'utf8'}).trim();
const projects=()=>YAML.parse(fs.readFileSync(process.env.ARI_PROJECTS_FILE??path.join(osRoot,'config/projects.yaml'),'utf8')).projects??[];
const json=file=>JSON.parse(fs.readFileSync(file,'utf8'));
async function main(){
 if(command==='status'){console.log(JSON.stringify({tasks:manager.queue.list()},null,2));return;}
 if(command==='registry'){console.log(JSON.stringify({agents:manager.registry.agents,existing:manager.registry.existing},null,2));return;}
 if(command==='registry-check'){console.log(JSON.stringify(manager.registry.assess(json(args[0]))));return;}
 if(command==='approve-development'){
  const task=manager.queue.get(args[0]);if(task?.type!=='DEVELOPMENT'||task.status!=='HUMAN_REVIEW')throw new Error('approval_target_invalid');
  console.log(JSON.stringify(manager.queue.update(task.id,{approval:{approved:true,by:'owner',at:new Date().toISOString()},status:'PENDING'})));return;
 }
 if(command==='enqueue'||command==='event'){console.log(JSON.stringify(command==='event'?manager.event(json(args[0])):manager.enqueue(json(args[0]))));return;}
 if(command==='enqueue-verify'){
  const [project,dir,b]=args;if(!project||!dir||!b)throw new Error('missing_enqueue_arguments');
  console.log(JSON.stringify(manager.enqueue({type:'VERIFY_PROJECT',project,projectDir:path.resolve(dir),branch:b,expectedFingerprint:await projectFingerprint(path.resolve(dir))})));return;
 }
 if(command==='run'||command==='cycle'){
  const release=acquireLock(path.join(stateRoot,'state/daemon.lock'));
  try{console.log(JSON.stringify(command==='run'?await manager.runNext():await manager.cycle(),null,2));}finally{release();}return;
 }
 if(command==='release-state'){const [serverPass,githubCiPass,testBuild,devicePass,releaseApproved]=args.map(v=>v==='true');console.log(manager.releaseDecision({serverPass,githubCiPass,testBuild,devicePass,releaseApproved}));return;}
 if(command!=='daemon'){console.log('commands: status | registry | registry-check | enqueue | event | enqueue-verify | run | cycle | release-state | daemon');return;}
 const pollMs=Number(process.env.ARI_POLL_INTERVAL_MS??900000),watchPollMs=Number(process.env.ARI_WATCH_POLL_INTERVAL_MS??15000),quietMs=Number(process.env.ARI_QUIET_WINDOW_MS??1200000);
 if([pollMs,watchPollMs,quietMs].some(v=>!Number.isSafeInteger(v)||v<10))throw new Error('invalid_intervals');
 if(process.env.KSTOCK_LIVE_TRADING_ENABLED==='true'){manager.event({type:'HIGH_RISK',category:'live_trading',id:'environment-live-trading',project:'k-stock-ai'});throw new Error('live_trading_environment_blocked');}
 const registryProjects=projects();
 if(args.includes('--dry-run')){
  const diagnostics=registryProjects.map(p=>{try{loadProfile(p.dir);return {project:p.id,exists:fs.existsSync(p.dir),branch:branch(p.dir),profile:'VALID'};}catch{return {project:p.id,profile:'HUMAN_REVIEW'};}});
  console.log(JSON.stringify({state:diagnostics.length>0&&diagnostics.every(d=>d.profile==='VALID'&&d.branch.startsWith('automation/'))?'SERVER_PASS':'HUMAN_REVIEW',dryRun:true,pollMs,watchPollMs,quietMs,projects:diagnostics,contracts:manager.registry.agents.length},null,2));return;
 }
 const release=acquireLock(path.join(stateRoot,'state/daemon.lock'));process.on('exit',release);manager.queue.recover();
 let running=true,active=false,requested=false,timer=null,immediate=null;
 const wake=()=>{
  if(!running)return;if(active){requested=true;return;}
  clearTimeout(immediate);immediate=setTimeout(async()=>{
   if(!running)return;active=true;
   try{if(!args.includes('--enqueue-only'))await manager.cycle({schedule:process.env.ARI_SCHEDULER_ENABLED!=='false'});}catch{console.error('cycle_failed');}
   finally{active=false;if(!running)return;clearTimeout(timer);timer=setTimeout(wake,Math.min(pollMs,manager.scheduler.nextDelay()));if(requested){requested=false;wake();}}
  },10);
 };
 const watched=registryProjects.flatMap(p=>p.sourceDir&&p.sourceDir!==p.dir?[p,{...p,id:p.id+'-source',sourceProject:p.id,dir:p.sourceDir,metadataOnly:true}]:[p]);
 const watcher=new ProjectWatcher({projects:watched,statePath:path.join(stateRoot,'state/watcher.json'),pollMs:watchPollMs,quietMs,onQuietChange:async p=>{
  const b=branch(p.dir),project=p.sourceProject??p.id;
  if(p.sourceProject||!b.startsWith('automation/'))manager.enqueue({type:'VERIFY_PROJECT',project,projectDir:p.dir,branch:b,status:'HUMAN_REVIEW',reason:p.sourceProject?'source_changed_requires_worktree_sync_review':'protected_or_detached_branch',dedupeKey:`${project}:source-review`});
  else{const fingerprint=await projectFingerprint(p.dir);manager.enqueue({type:'VERIFY_PROJECT',project,projectDir:p.dir,branch:b,expectedFingerprint:fingerprint,dedupeKey:`${project}:verify:${fingerprint}`});}
  wake();
 }});
 const queueFile=path.join(stateRoot,'state/tasks.json');
 let queueWatch;
 const fallback=()=>{queueWatch?.close();fs.watchFile(queueFile,{interval:250},(now,previous)=>{if(now.mtimeMs!==previous.mtimeMs)wake();});};
 try{queueWatch=fs.watch(path.dirname(queueFile),(_,name)=>{if(String(name)==='tasks.json')wake();});queueWatch.on('error',fallback);}catch{fallback();}
 const stop=()=>{running=false;clearTimeout(timer);clearTimeout(immediate);queueWatch?.close();fs.unwatchFile(queueFile);watcher.stop();};
 for(const signal of ['SIGTERM','SIGINT'])process.on(signal,stop);
 console.log(JSON.stringify({service:'ari-main-manager',state:'STARTED',pollMs,watchPollMs,quietMs,projects:registryProjects.map(p=>p.id),watchedPaths:watched.length,contracts:manager.registry.agents.length}));
 wake();await watcher.start();while(active)await new Promise(r=>setTimeout(r,50));release();
}
main().catch(error=>{console.error('manager_failed',error.message?.startsWith('daemon_')?error.message:'configuration_or_policy_error');process.exitCode=1;});
