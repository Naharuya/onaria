import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {AriMainManager} from '../src/main_manager.js';

const temp=()=>fs.mkdtempSync(path.join(os.tmpdir(),'ari-manager-ai-'));

test('finance task with supplied evidence is analyzed by local router',async t=>{
 const root=temp();t.after(()=>fs.rmSync(root,{recursive:true,force:true}));
 let called=0;const aiRouter={complete:async input=>{called++;assert.equal(input.forceLocal,true);assert.equal(input.allowEscalation,false);return {state:'DONE',provider:'ollama',model:'qwen-test',text:'비용 이상 없음',usage:{inputTokens:10,outputTokens:4,totalTokens:14},route:{lane:'local'}};}};
 const m=new AriMainManager({rootDir:root,logger:{},aiRouter});
 m.enqueue({type:'FINANCE',project:'company',sourceData:{apiCost:12,serverCost:3}});await m.cycle({schedule:false});
 const task=m.queue.list()[0];assert.equal(called,1);assert.equal(task.status,'COMPLETED');assert.equal(task.result.provider,'ollama');assert.equal(task.result.evidenceBacked,true);
});

test('business task without evidence remains safely blocked',async t=>{
 const root=temp();t.after(()=>fs.rmSync(root,{recursive:true,force:true}));const m=new AriMainManager({rootDir:root,logger:{},aiRouter:{complete:async()=>{throw new Error('must not call');}}});
 m.enqueue({type:'GROWTH',project:'company'});await m.cycle({schedule:false});const task=m.queue.list()[0];assert.equal(task.status,'BLOCKED');assert.equal(task.result.state,'DATA_SOURCE_NOT_CONNECTED');
});
