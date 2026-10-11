import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createConversationService } from '../src/conversation_service.js';
import { createLocalConversationService } from '../src/local_conversation_service.js';

const request = (consent) => ({
  session: { sessionId: 'consent-test', selectedEmotion: '불안', emotionIntensity: 5, turnCount: 1 },
  userMessage: '내일 발표가 걱정돼요', systemPromptVersion: 'ko-v1', allowedVerseIds: [],
  ...(consent === undefined ? {} : { externalAiConsentVersion: consent }),
});
for (const consent of [undefined, 'old-version', '']) {
  test(`missing or obsolete AI consent prevents providers and retrieval: ${consent}`, async () => {
    let calls = 0;
    const service = createConversationService({
      env: { ONARIA_AI_MODE: 'openai', ONARIA_MULTI_AGENT_ENABLED: 'true', OPENAI_API_KEY: 'test-only', ONARIA_COST_ROUTER_V1_ENABLED: 'false' },
      openAiFactory: () => { calls++; throw Error('must not construct'); },
      knowledgeProvider: () => { calls++; throw Error('must not retrieve'); },
    });
    const body = request(consent);
    assert.deepEqual(await service(body, { id: 'integrated' }), await createLocalConversationService()(body, { id: 'integrated' }));
    assert.equal(calls, 0);
  });
}
test('crisis still bypasses consent and all external work', async () => {
  const service = createConversationService({ openAiFactory: () => assert.fail('external') });
  const result = await service({ ...request(), userMessage: '지금 당장 죽고 싶고 계획을 세웠어요' });
  assert.equal(result.stage, 'crisis');
});
