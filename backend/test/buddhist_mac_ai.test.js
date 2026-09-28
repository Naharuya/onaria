import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createMacAiApp } from '../dev/religion-packs/buddhist/mac_ai.js';
const token = 'a'.repeat(64);
const body = { profile:'buddhist', phase:'need', emotion:'anxiety', intensity:5, input:'일이 많아요', previousInputs:[] };
async function fixture(t, fetchImpl, timeoutMs) {
  const server = createMacAiApp({token, fetchImpl, timeoutMs}).listen(0,'127.0.0.1');
  await new Promise(r => server.once('listening',r));
  t.after(() => { server.closeAllConnections(); server.close(); });
  const url = `http://127.0.0.1:${server.address().port}`;
  return (data=body, headers={}) => fetch(url+'/reply',{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`,...headers},body:JSON.stringify(data)});
}
const ok = template => ({ok:true, json:async()=>({done:true, message:{content:JSON.stringify({template})}})});
test('USB AI validates paired requests, profile and closed model output', async t => {
 let calls=0;
 const post=await fixture(t,async(url, options)=>{ calls++; assert.equal(url,'http://127.0.0.1:11434/api/chat');assert.equal(options.redirect,'error'); return ok('need'); });
 assert.equal((await post(body,{Authorization:'bad'})).status,401);
 assert.equal((await post(body,{Origin:'https://external.invalid'})).status,403);
 assert.equal((await post({...body,profile:'christian'})).status,400);
 assert.equal(calls,0);
 const result=await post();assert.equal(result.headers.get('cache-control'),'no-store');
 assert.deepEqual(await result.json(),{profile:'buddhist',phase:'need',template:'need'});assert.equal(calls,1);
});
test('Crisis and prior context block the model; safety stays sticky',async t=>{
 let calls=0;const post=await fixture(t,async()=>{calls++;return ok('need');});
 assert.equal((await post({...body,previousInputs:['죽고 싶어요']})).status,409);
 assert.equal((await post()).status,409);assert.equal(calls,0);
});
test('Model invented source fields never enter the reply',async t=>{
 const post=await fixture(t,async()=>({ok:true,json:async()=>({done:true,message:{content:JSON.stringify({template:'need',source:'invented scripture'})}})}));
 const response=await post();assert.equal(response.status,503);assert.ok(!(await response.text()).includes('invented'));
});
test('Timeout aborts local inference and releases busy guard',async t=>{
 let aborted=0;
 const post=await fixture(t,async(_url,{signal})=>new Promise((_r,reject)=>signal.addEventListener('abort',()=>{aborted++;reject(Error('aborted'));})),30);
 assert.equal((await post()).status,503);assert.equal((await post()).status,503);assert.equal(aborted,2);
});
test('Concurrent request is rejected without a second model call',async t=>{
 let finish;let started;const ready=new Promise(r=>started=r);let calls=0;
 const post=await fixture(t,async()=>{calls++;started();return new Promise(r=>finish=()=>r(ok('need')));});
 const first=post();await ready;assert.equal((await post()).status,429);finish();assert.equal((await first).status,200);assert.equal(calls,1);
});
