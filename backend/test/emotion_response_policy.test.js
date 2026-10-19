import assert from 'node:assert/strict';
import { test } from 'node:test';
import { emotionResponsePolicy, applySupportTurn, explicitlyRequestsVerse } from '../src/emotion_response_policy.js';
import { compactModelInput } from '../src/cost/prompt_context.js';
import { createLocalConversationService } from '../src/local_conversation_service.js';
import { createConversationService } from '../src/conversation_service.js';
import { costBody } from './fixtures/cost_fixtures.js';
const context = (overrides = {}) => ({ emotion: '불안', intensity: 8,
  conversationState: { turnCount: 2 }, allowedVerseIds: ['approved-test'],
  verseCandidates: [{ id: 'approved-test', tags: ['쉼'] }], userMessage: '잠시 쉬고 싶어요.', ...overrides });
const turn = (overrides = {}) => ({ emotion: '불안', empathy: '잠시 쉬고 싶은 마음을 함께 살펴볼게요.',
  nextQuestion: '지금 어떤 쉼이 필요할까요?', summary: '쉼이 필요함',
  answerExamples: ['저는 조용히 쉬고 싶어요.', '저는 함께 있고 싶어요.', '저는 물을 마시고 싶어요.'],
  readyForVerse: true, suggestedVerseId: 'approved-test', ...overrides });
test('all difficult intensity bands and pleasant/mixed feelings have distinct pacing', () => {
  assert.equal(emotionResponsePolicy(context({ intensity: 2 })).maxExamples, 3);
  assert.equal(emotionResponsePolicy(context()).maxExamples, 2);
  assert.equal(emotionResponsePolicy(context({ intensity: 10 })).maxExamples, 1);
  assert.equal(emotionResponsePolicy(context({ emotion: '기쁨', intensity: 10 })).mode, 'savor');
  assert.equal(emotionResponsePolicy(context({ emotion: '벅찬' })).mode, 'clarify_valence');
  assert.equal(emotionResponsePolicy(context(), '슬픔').initialIntensity, null);
  assert.equal(emotionResponsePolicy(context({ customEmotion: '기쁘고 부담돼요' })).initialIntensity, null);
});
test('high distress defers scripture, aligns question/examples, ends at five', () => {
  const result = applySupportTurn({}, turn(), context(), { allowVerse: true });
  assert.equal(result.question, turn().nextQuestion);
  assert.equal(result.shouldOfferVerse, false);
  assert.equal(result.continueConversation, true);
  assert.equal(result.answerExamples.length, 2);
  assert.equal(result.responseMode, 'ai');
  const ended = applySupportTurn({}, turn(), context({ conversationState: { turnCount: 4 } }), { allowVerse: true });
  assert.equal(ended.shouldEndConversation, true);
  assert.equal(ended.question, null);
  assert.deepEqual(ended.answerExamples, []);
});
test('only eligible catalog IDs and explicit non-refused requests permit deferred reading', () => {
  const allowed = applySupportTurn({}, turn(), context({ userMessage: '말씀 읽고 싶어요' }), { allowVerse: true });
  assert.equal(allowed.shouldOfferVerse, true);
  for (const override of [{ verseCandidates: [] }, { allowedVerseIds: [] }, { userMessage: '말씀 읽고 싶지 않아요' }]) {
    assert.equal(applySupportTurn({}, turn(), context(override), { allowVerse: true }).shouldOfferVerse, false);
  }
  assert.equal(applySupportTurn({}, turn(), context({ intensity: 4 }), { allowVerse: false }).shouldOfferVerse, false);
  assert.equal(explicitlyRequestsVerse('성경 말고 이야기를 나누고 싶어요'), false);
});
test('model history keeps prior user answer before assistant question and current input', () => {
  const compact = compactModelInput({ userMessage: 'current', conversationState: {
    previousUserAnswer: 'previous', previousAssistantQuestion: 'follow-up' } });
  assert.deepEqual(compact.recentTurns, [{ role: 'user', content: 'previous' }, { role: 'assistant', content: 'follow-up' }]);
  assert.equal(compact.userMessage, 'current');
});
test('local high-intensity third turn stays supportive and clearly identifies fallback', async () => {
  const body = costBody(); body.session.turnCount = 2; body.allowedVerseIds = ['approved-test'];
  const result = await createLocalConversationService()(body, { id: 'integrated' });
  assert.equal(result.shouldOfferVerse, false); assert.equal(result.continueConversation, true);
  assert.equal(result.responseMode, 'local');
});
test('real service uses one coherent support turn after turn three, without live providers', async () => {
  let calls = 0; let received;
  const service = createConversationService({ env: { ONARIA_AI_MODE: 'openai', ONARIA_MULTI_AGENT_ENABLED: 'true',
    OPENAI_API_KEY: 'TEST_DATA_ONLY' }, logger: {}, openAiFactory: () => ({ runStructured: async (task) => {
      calls++; received = task; return turn({ readyForVerse: false });
    } }) });
  const body = costBody('마음이 좀 답답해요'); body.session.turnCount = 2;
  body.session.previousUserAnswer = '발표가 있었어요'; body.session.previousAssistantQuestion = '어떤 생각이 들었나요?';
  const result = await service(body);
  assert.equal(calls, 1); assert.equal(received.name, 'support_turn_v1');
  assert.equal(received.input.responsePolicy.mode, 'gentle_support');
  assert.equal(result.continueConversation, true); assert.equal(result.responseMode, 'ai');
  assert.equal(result.question, turn().nextQuestion);
});
