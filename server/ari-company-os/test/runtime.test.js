import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {runCommand} from '../src/verification_runner.js';
import {VerificationWorkflow as VerificationRunner} from '../src/repair_workflow.js';
import {createCodexRepairWorker} from '../src/codex_repair_worker.js';
import {ProjectWatcher} from '../src/project_watcher.js';
import {QuietWindowDebouncer} from '../src/debounce.js';
import {TaskQueue} from '../src/task_queue.js';
import {loadProfile} from '../src/profile.js';
import {acquireLock} from '../src/process_lock.js';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function fixture(t) {
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'ari-test-'));
 t.after(()=>fs.rmSync(dir,{recursive:true,force:true}));
 execFileSync('git',['init','-q','-b','automation/fixture'],{cwd:dir});
 fs.mkdirSync(path.join(dir,'src'));fs.writeFileSync(path.join(dir,'src/value.cjs'),'module.exports = 1;\n');
 execFileSync('git',['add','.'],{cwd:dir});execFileSync('git',['-c','user.name=ARI Fixture','-c','user.email=fixture@localhost','commit','-qm','isolated fixture'],{cwd:dir});
 return dir;
}
const check={id:'value-regression',command:process.execPath,args:['-e',"if(require('./src/value.cjs')!==2)process.exit(1)"],repairable:true,repairFiles:['src/value.cjs']};
const input=cwd=>({project:'fixture',branch:'automation/fixture',cwd,checks:[check]});
test('repair adapter applies proposal then entire profile reverifies',async t=>{
 const cwd=fixture(t);const worker=createCodexRepairWorker({enabled:true,propose:async()=>({humanReview:false,edits:[{file:'src/value.cjs',content:'module.exports = 2;\n'}]})});
 const r=await new VerificationRunner({repairWorker:worker}).verify(input(cwd));
 assert.equal(r.state,'SERVER_PASS');assert.equal(r.repairs.length,1);assert.deepEqual(r.checks.map(c=>c.ok),[false,true]);
});
test('repair count hard capped at two across profile',async t=>{
 const cwd=fixture(t);let count=0;const r=await new VerificationRunner({maxRepairAttempts:99,repairWorker:async()=>{count++;return {};}}).verify(input(cwd));
 assert.equal(count,2);assert.equal(r.state,'HUMAN_REVIEW');
});
test('sensitive failures never reach repair worker',async t=>{
 const cwd=fixture(t);for(const id of ['safety','security','legal','live-trading','production-deploy']) {
 const r=await new VerificationRunner({repairWorker:async()=>assert.fail('unsafe repair')}).verify({...input(cwd),checks:[{...check,id}]});assert.equal(r.state,'HUMAN_REVIEW');assert.equal(r.repairs.length,0);
 }
});
test('nonrepairable failure yields FAIL',async t=>{const r=await new VerificationRunner().verify(input(fixture(t)));assert.equal(r.state,'FAIL');});
test('actual branch overrides untrusted queued branch',async t=>{
 const cwd=fixture(t);execFileSync('git',['checkout','-qb','main'],{cwd});assert.equal((await new VerificationRunner().verify(input(cwd))).state,'HUMAN_REVIEW');
});
test('empty profile never passes and legacy shell command rejected',t=>{
 const cwd=fixture(t);fs.mkdirSync(path.join(cwd,'.ari'));const file=path.join(cwd,'.ari/verification.yaml');
 fs.writeFileSync(file,'checks: []');assert.throws(()=>loadProfile(cwd),/empty/);
 fs.writeFileSync(file,'checks:\n  - name: test\n    command: npm test\n');assert.throws(()=>loadProfile(cwd),/invalid_check/);
});
test('spawn failures and timeouts resolve safely',async()=>{
 assert.equal((await runCommand('/no-such-ari-command',[],{})).reason,'spawn_failed');
 assert.equal((await runCommand(process.execPath,['-e','setInterval(()=>{},1000)'],{timeoutMs:40})).reason,'timeout');
});
test('live trading env cannot be overridden by a check',async()=>{
 const r=await runCommand(process.execPath,['-e',"process.exit(process.env.KSTOCK_LIVE_TRADING_ENABLED==='false'?0:1)"],{env:{KSTOCK_LIVE_TRADING_ENABLED:'true'}});assert.equal(r.ok,true);
});
test('repair cannot edit tests or an unlisted file',async t=>{
 const cwd=fixture(t);const worker=createCodexRepairWorker({enabled:true,propose:async()=>({humanReview:false,edits:[{file:'test.cjs',content:''}]})});
 assert.equal((await worker({...input(cwd),failedCheck:check,result:{},attempt:1})).humanReview,true);assert.equal(fs.readFileSync(path.join(cwd,'src/value.cjs'),'utf8'),'module.exports = 1;\n');
});
test('queue survives process object restart and preserves dependencies',t=>{
 const file=path.join(fixture(t),'state/tasks.json');const q=new TaskQueue(file);q.enqueue({id:'a'});q.enqueue({id:'b',dependencies:['a']});q.update('a',{status:'READY'});q.update('a',{status:'IN_PROGRESS'});q.update('a',{status:'VERIFYING'});q.update('a',{status:'COMPLETED'});assert.equal(new TaskQueue(file).nextReady().id,'b');
});
test('duplicate daemon lock blocked and dead pid lock recoverable',t=>{
 const file=path.join(fixture(t),'lock');const release=acquireLock(file);assert.throws(()=>acquireLock(file),/already_running/);release();fs.writeFileSync(file,'2147483647');acquireLock(file)();
});
test('default quiet window is twenty minutes',()=>{assert.equal(new QuietWindowDebouncer({onReady:()=>{}}).quietMs,1200000);});
test('three projects detect repeated edits of an already dirty file and debounce once',async t=>{
 const projects=['onaria','rami','k-stock-ai'].map(id=>({id,dir:fixture(t)}));const events=[];
 const watcher=new ProjectWatcher({projects,pollMs:20,quietMs:180,logger:{},onQuietChange:async(p)=>events.push({id:p.id,at:Date.now()})});
 const loop=watcher.start();t.after(async()=>{watcher.stop();await loop;});
 await sleep(100);
 for(const p of projects)fs.writeFileSync(path.join(p.dir,'src/value.cjs'),'module.exports = 2;');
 await sleep(120);
 const last=Date.now();for(const p of projects)fs.writeFileSync(path.join(p.dir,'src/value.cjs'),'module.exports = 3;');
 await sleep(120);assert.equal(events.length,0);
 await sleep(250);assert.deepEqual(events.map(e=>e.id).sort(),projects.map(p=>p.id).sort());assert.ok(events.every(e=>e.at-last>=180));
});
test('watcher detects changes made while stopped using persisted fingerprint',async t=>{
 const cwd=fixture(t),statePath=path.join(cwd,'.git','watcher.json'),projects=[{id:'fixture',dir:cwd}];
 const first=new ProjectWatcher({projects,statePath,pollMs:20,quietMs:80,logger:{},onQuietChange:async()=>{}});
 const a=first.start();await sleep(80);first.stop();await a;
 fs.writeFileSync(path.join(cwd,'src/value.cjs'),'module.exports = 2;');
 let count=0;const second=new ProjectWatcher({projects,statePath,pollMs:20,quietMs:80,logger:{},onQuietChange:async()=>count++});
 const b=second.start();await sleep(220);second.stop();await b;assert.equal(count,1);
});
test('metadata-only source watcher detects repeated dirty edits without reading source contents',async t=>{
 const cwd=fixture(t);let count=0;
 const watcher=new ProjectWatcher({projects:[{id:'original',dir:cwd,metadataOnly:true}],pollMs:20,quietMs:120,logger:{},onQuietChange:async()=>count++});
 const loop=watcher.start();t.after(async()=>{watcher.stop();await loop;});await sleep(80);
 fs.writeFileSync(path.join(cwd,'src/value.cjs'),'module.exports = 2;');await sleep(70);
 fs.writeFileSync(path.join(cwd,'src/value.cjs'),'module.exports = 3;');await sleep(80);assert.equal(count,0);
 await sleep(120);assert.equal(count,1);
});
test('generated verification reports do not trigger another verification cycle',async t=>{
 const cwd=fixture(t),dir=path.join(cwd,'backend/evaluation/results');fs.mkdirSync(dir,{recursive:true});
 const file=path.join(dir,'expert-review.json');fs.writeFileSync(file,'{}');execFileSync('git',['add','.'],{cwd});execFileSync('git',['-c','user.name=ARI Fixture','-c','user.email=fixture@localhost','commit','-qm','generated fixture'],{cwd});
 let count=0;const watcher=new ProjectWatcher({projects:[{id:'fixture',dir:cwd}],pollMs:20,quietMs:80,logger:{},onQuietChange:async()=>count++});
 const loop=watcher.start();t.after(async()=>{watcher.stop();await loop;});await sleep(80);fs.writeFileSync(file,'{"generated":1}');await sleep(180);assert.equal(count,0);
 fs.writeFileSync(path.join(cwd,'src/value.cjs'),'module.exports = 2;');await sleep(180);assert.equal(count,1);
});
