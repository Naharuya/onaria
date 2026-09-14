import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {AiRouter} from '../src/ai_router.js';
import {AiUsageStore} from '../src/ai_usage_store.js';

const temp=()=>fs.mkdtempSync(path.join(os.tmpdir(),'ari-ai-'));

test('local-first task uses Ollama and records measured tokens',async t=>{
 const dir=temp();t.after(()=>fs.rmSync(dir,{recursive:true,force:true}));
 const store=new AiUsageStore(path.join(dir,'usage.jsonl'));
 const router=new AiRouter({usageStore:store,fetchImpl:async()=>({ok:true,json:async()=>({model:'qwen-test',response:'ok',prompt_eval_count:12,eval_count:8})})});
 const r=await router.complete({agentId:'finance-agent',taskType:'FINANCE',prompt:'summarize'});
 assert.equal(r.state,'DONE');assert.equal(r.route.lane,'local');assert.equal(r.usage.totalTokens,20);
 const s=store.summary();assert.equal(s.totals.localCalls,1);assert.equal(s.totals.measuredTokens,20);assert.equal(s.totals.tokenCoverageRate,1);
});

test('high risk routing never silently sends to local AI',async()=>{
 const router=new AiRouter({fetchImpl:async()=>{throw new Error('must not call local');}});
 const r=await router.complete({agentId:'safety-agent',taskType:'ANALYSIS',riskCategory:'privacy',prompt:'sensitive'});
 assert.equal(r.state,'HUMAN_REVIEW');assert.equal(r.route.lane,'external');
});

test('external-first without adapter reports requirement and unknown tokens',async t=>{
 const dir=temp();t.after(()=>fs.rmSync(dir,{recursive:true,force:true}));const store=new AiUsageStore(path.join(dir,'usage.jsonl'));
 const router=new AiRouter({usageStore:store});const r=await router.complete({agentId:'coding-agent',taskType:'DEVELOPMENT',prompt:'code'});
 assert.equal(r.state,'EXTERNAL_AI_REQUIRED');const rows=store.list();assert.equal(rows[0].lane,'external');assert.equal(rows[0].tokenState,'UNAVAILABLE');
});
