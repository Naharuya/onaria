import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import os from 'node:os';import path from 'node:path';
import {createDurableDeletionLab} from '../src/privacy/durable_deletion_lab.js';
test('재시작 후 재시도·독립 명부 복원 차단·새 세대 보존',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-deletion-'));let lab;
 try{
 lab=createDurableDeletionLab({directory:root});lab.register('old');lab.issue('old');lab.add('old','fixture');lab.close();
 fs.copyFileSync(path.join(root,'store.sqlite'),path.join(root,'backup.sqlite'));
 lab=createDurableDeletionLab({directory:root});lab.request('old');assert.throws(()=>lab.run('old',{fail:true}));assert.throws(()=>lab.issue('old'));lab.close();
 lab=createDurableDeletionLab({directory:root});lab.resume();assert.equal(lab.count(),0);assert.equal(lab.run('old'),'already-complete');lab.close();
 fs.copyFileSync(path.join(root,'backup.sqlite'),path.join(root,'store.sqlite'));
 lab=createDurableDeletionLab({directory:root});assert.throws(()=>lab.connect({manifestAvailable:false}));assert.equal(lab.connected(),false);
 lab.connect();assert.equal(lab.access('old'),false);assert.equal(lab.count(),0);assert.throws(()=>lab.register('old'));
 lab.register('new');lab.add('new','new-fixture');lab.connect();assert.equal(lab.access('new'),true);assert.equal(lab.count(),1);
 }finally{lab?.close();fs.rmSync(root,{recursive:true,force:true});}
});
test('최신성 미달 차단, 두 작업자 중복 처리 및 비용 연결은 세대별 삭제',()=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-deletion-'));let a,b;
 try{a=createDurableDeletionLab({directory:root});a.register('old');a.register('new');a.linkCost('old','owner-old','fixture');a.linkCost('new','owner-new','fixture');a.request('old');
 b=createDurableDeletionLab({directory:root});assert.throws(()=>b.connect({minimumWatermark:2}));assert.equal(b.connected(),false);
 assert.equal(a.run('old'),'complete');assert.equal(b.run('old'),'already-complete');assert.equal(b.costCount(),1);assert.equal(b.access('new'),true);b.connect({minimumWatermark:1});
 }finally{a?.close();b?.close();fs.rmSync(root,{recursive:true,force:true});}
});
test('독립 Node 프로세스 둘의 동시 삭제는 한 번만 완료', async()=>{
 const {fork}=await import('node:child_process');
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'onaria-deletion-'));let lab;
 const children=[];
 try{
 lab=createDurableDeletionLab({directory:root});lab.register('old');lab.add('old','fixture');lab.request('old');lab.close();lab=null;
 const moduleUrl=new URL('../src/privacy/durable_deletion_lab.js',import.meta.url).href;
 const script=path.join(root,'worker.mjs');fs.writeFileSync(script,`import {createDurableDeletionLab} from ${JSON.stringify(moduleUrl)}; const lab=createDurableDeletionLab({directory:process.argv[2]}); process.send('ready');process.on('message',()=>{try{process.send(lab.run('old'));}finally{lab.close();process.disconnect();}});`);
 const results=[];
 const workers=[0,1].map(()=>{
 const child=fork(script,[root],{stdio:['ignore','ignore','ignore','ipc']});children.push(child);
 return {child,ready:new Promise((resolve,reject)=>{child.once('error',reject);child.once('message',resolve);}),done:new Promise((resolve,reject)=>{child.on('message',m=>{if(m!=='ready')results.push(m);});child.once('exit',code=>code===0?resolve():reject(new Error('격리 작업자 실패')));})};
 });
 await Promise.all(workers.map(x=>x.ready));workers.forEach(x=>x.child.send('start'));await Promise.all(workers.map(x=>x.done));
 assert.deepEqual(results.sort(),['already-complete','complete']);lab=createDurableDeletionLab({directory:root});assert.equal(lab.count(),0);
 }finally{for(const c of children)if(c.exitCode===null)c.kill();lab?.close();fs.rmSync(root,{recursive:true,force:true});}
});
