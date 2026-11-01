import {createLocalConversationService as factory} from '../src/local_conversation_service.js';
import test from 'node:test';
import assert from 'node:assert/strict';
import {personalization,personalizationForModel} from '../src/care_personalization.js';
import {requestSchema} from '../src/schema.js';
import {assessRequestCrisis} from '../src/crisis.js';
const body = (answers, askedQuestions=[]) => ({session:{sessionId:'common-test',selectedEmotion:'불안',emotionIntensity:8,
  personalizationContext:{version:1,emotion:'불안',intensity:8,situation:answers[0],desiredHelp:'unspecified',alreadyAnswered:answers,askedQuestions}},
  userMessage:answers.at(-1),systemPromptVersion:'ko-v1',allowedVerseIds:[]});
test('same five factors: topic, need, negation, history and correction',()=>{
 let b=body(['업무가 겹쳐요']); let c=personalization(b);
 assert.equal(c.topic,'workload');assert.equal(c.lowBurden,true);assert.match(c.question,/겹친 일/);
 b=body(['업무가 겹쳐요','쉬기 싫고 먼저 정리하고 싶어요']);c=personalization(b);
 assert.equal(c.desiredHelp,'order');assert.match(c.question,/한 가지/);
 const q=c.question;
 b=body([...b.session.personalizationContext.alreadyAnswered,'정리는 원치 않아요. 위로가 필요해요'],[q]);c=personalization(b);
 assert.equal(c.desiredHelp,'connection');
 b=body([...b.session.personalizationContext.alreadyAnswered,'사실은 가족과 서운한 일이 있었어요'],[c.question]);
 c=personalization(b);assert.equal(c.topic,'relationship');assert.notEqual(c.question,b.session.personalizationContext.askedQuestions[0]);
});
test('facts do not imply help and negation withdraws an earlier choice',()=>{
 assert.equal(personalization(body(['친구에게 연락이 왔어요'])).desiredHelp,'unspecified');
 assert.equal(personalization(body(['쉬고 싶어요','휴식 말고'])).desiredHelp,'unspecified');
});
test('model history is bounded and prefixed questions do not repeat',()=>{
 const b=body(['업무가 겹쳐 쉬고 싶어요']);
 const first=personalization(b).question;
 b.session.personalizationContext.askedQuestions=['직접 적은 마음. '+first];
 assert.notEqual(personalization(b).question,first);
 const mixed=body(['저는 반갑고 기쁜 느낌에 가까워요.'],
   ['지금은 반가운 느낌과 버거운 느낌 중 어느 쪽에 더 가까운가요?']);
 assert.equal(personalization(mixed).situation,'');
 assert.match(personalization(mixed).question,/어떤 일/);
 const long=body(['가'.repeat(1000)]);
 assert.equal(personalizationForModel(long).alreadyAnswered[0].length,512);
 const hidden=body(['가'.repeat(700)+'나를 해치고 싶어요','정리하고 싶어요']);
 assert.ok(assessRequestCrisis(hidden).level>0);
});
test('bounded schema and context safety preflight',()=>{
 const b=body(['업무가 겹쳐요']);assert.ok(requestSchema.safeParse(b).success);
 b.session.personalizationContext.alreadyAnswered=Array(6).fill('답');
 assert.equal(requestSchema.safeParse(b).success,false);
 const risk=body(['나를 해치고 싶어요','정리하고 싶어요']);
 assert.ok(assessRequestCrisis(risk).level>0);
});

test('active local service uses the shared context after safety',async()=>{
 const generate=factory({env:{},logger:{info(){}}});
 const b=body(['업무가 겹쳐 쉬고 싶어요']);
 const response=await generate(b,{id:'integrated'});
 assert.equal(response.question,personalization(b).question);
 assert.match(response.message,/쉬고 싶은 뜻/);
 assert.match((await generate(b,{id:'clinical_reflection'})).message,/상황과 생각/);
 const risk=body(['나를 해치고 싶어요','정리하고 싶어요']);
 assert.equal((await generate(risk,{id:'integrated'})).stage,'crisis');
});

test('compacted history reconstructs current input and keeps declared prior help',()=>{
 const b=body(['업무가 겹쳐요','']);
 b.userMessage='긴 대화의 현재 답변이에요';
 b.session.personalizationContext.historyCompacted=true;
 b.session.personalizationContext.desiredHelp='rest';
 let c=personalization(requestSchema.parse(b));
 assert.equal(c.alreadyAnswered.at(-1),b.userMessage);
 assert.equal(c.desiredHelp,'rest');
 b.userMessage='휴식 말고 정리하고 싶어요';
 assert.equal(personalization(requestSchema.parse(b)).desiredHelp,'order');
 b.userMessage='나를 해치고 싶어요';
 assert.ok(assessRequestCrisis(b).level>0);
});
