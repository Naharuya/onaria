import {test} from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import {dataRightsRouter} from '../src/privacy/data_rights.js';
import {once} from 'node:events';
test('standalone account deletion and data controls work without app installation or authentication', async()=>{
 const app=express();app.use(dataRightsRouter());const server=app.listen(0,'127.0.0.1');await once(server,'listening');
 try{for(const path of ['/account-deletion','/data-controls']){
  const response=await fetch(`http://127.0.0.1:${server.address().port}${path}`);
  assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');
  const html=await response.text();assert.ok(html.includes('mailto:'));assert.ok(html.includes('회원탈퇴'));
  assert.ok(html.includes('본인 확인'));assert.ok(html.includes('앱 재설치 없이'));
  assert.ok(html.includes('이메일을 여는 것만으로 요청이 접수되거나 계정이 삭제되지는 않습니다'));
  assert.ok(!html.includes('.invalid'));assert.ok(!html.includes('<script'));
 }
 const response=await fetch(`http://127.0.0.1:${server.address().port}/v1/privacy/rights`);const profile=await response.json();
 assert.equal(profile.version,'ari-data-rights-v1');assert.equal(profile.automaticCrossAppDeletion,false);
 assert.equal(profile.automaticDeviceSync,false);assert.ok(!JSON.stringify(profile).includes('token'));
 }finally{await new Promise(resolve=>server.close(resolve));}
});
