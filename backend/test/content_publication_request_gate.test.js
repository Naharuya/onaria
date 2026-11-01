import test from 'node:test';
import assert from 'node:assert/strict';
import {createApp} from '../src/app.js';
const result={message:'합성 테스트 안내입니다.',question:'어떤 생각이 떠올랐나요?',stage:'thought',detectedEmotion:'불안',secondaryEmotion:null,riskLevel:0,shouldOfferVerse:true,verseTags:[],actionTags:[],shouldEndConversation:false,suggestedVerseId:'unregistered-content',agent:'integrated',memorySummary:'',clinicalReflection:null,integratedInsight:null};
test('client-selected source IDs never grant publication and crisis remains before generation',async t=>{
 let calls=0,received;
 const generate=Object.assign(async body=>{calls++;received=structuredClone(body);return structuredClone(result);},{mode:'local'});
 const app=createApp({generate,memberStore:{getAdminOverview:()=>({total:0,recent:[]})},logger:{error(){}}});
 const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));t.after(()=>new Promise(r=>server.close(r)));
 const base='http://127.0.0.1:'+server.address().port;
 const body={session:{sessionId:'synthetic-publication-safety',selectedEmotion:'불안',emotionIntensity:5,turnCount:2,selectedVerse:'unregistered-content'},userMessage:'오늘 있었던 일을 돌아보고 싶어요.',systemPromptVersion:'ko-v1',allowedVerseIds:['unregistered-content'],locale:'ko-KR'};
 const send=payload=>fetch(base+'/v1/mind/chat',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload)});
 const response=await send(body);assert.equal(response.status,200);const value=await response.json();
 assert.equal(calls,1);assert.deepEqual(received.allowedVerseIds,[]);assert.equal(received.session.selectedVerse,null);assert.equal(value.suggestedVerseId,null);assert.equal(value.shouldOfferVerse,false);
 const approved=app.locals.contentPublications.publicManifest().entries[0]?.reference;
 if(approved){await send({...body,allowedVerseIds:[approved]});assert.deepEqual(received.allowedVerseIds,[approved]);}
 const before=calls;const crisis=await send({...body,userMessage:'지금 당장 죽고 싶고 계획을 세웠어요'});assert.equal((await crisis.json()).stage,'crisis');assert.equal(calls,before);
});
