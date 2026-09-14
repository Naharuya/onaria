import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createDashboardServer} from '../src/dashboard_server.js';
import {AiUsageStore} from '../src/ai_usage_store.js';

test('dashboard exposes task and AI summaries without mutation endpoints',async t=>{
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'ari-dash-'));t.after(()=>fs.rmSync(root,{recursive:true,force:true}));fs.mkdirSync(path.join(root,'state'),{recursive:true});
 fs.writeFileSync(path.join(root,'state/tasks.json'),JSON.stringify([{id:'a',type:'VERIFY_PROJECT',project:'onaria',owner:'verification-core',status:'COMPLETED',updatedAt:new Date().toISOString(),result:{state:'SERVER_PASS'}}]));
 new AiUsageStore(path.join(root,'state/ai-usage.jsonl')).record({provider:'ollama',lane:'local',model:'qwen-test',agentId:'finance-agent',taskType:'FINANCE',outcome:'success',inputTokens:5,outputTokens:3,totalTokens:8});
 const d=createDashboardServer({stateRoot:root,host:'127.0.0.1',port:0,logger:{log(){}}});await d.start();t.after(()=>d.stop());const port=d.server.address().port;
 const summary=await fetch(`http://127.0.0.1:${port}/api/summary`).then(r=>r.json());assert.equal(summary.tasks.completed,1);assert.equal(summary.ai.totals.measuredTokens,8);
 const html=await fetch(`http://127.0.0.1:${port}/`).then(r=>r.text());assert.match(html,/Operations Dashboard/);
 const denied=await fetch(`http://127.0.0.1:${port}/api/tasks`,{method:'POST'});assert.equal(denied.status,405);
});
