import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { z } from 'zod';
import { createOllamaService } from '../src/ollama_service.js';
import { createConversationService } from '../src/conversation_service.js';
import { crisisResponse, assessRequestCrisis } from '../src/crisis.js';
import { responseSchema } from '../src/schema.js';
import { psychologyOutput } from './fixtures/agent_outputs.js';

const env = { ONARIA_AI_MODE: 'ollama', ONARIA_EXTERNAL_API_DISABLED: 'true' };
const body = (userMessage = '내일 발표가 걱정돼요') => ({ userMessage,
  session: { sessionId: 'local-test', selectedEmotion: '불안', emotionIntensity: 5, turnCount: 0 },
  systemPromptVersion: 'ko-v1', allowedVerseIds: [] });
const support = () => ({ emotion: '불안', empathy: '발표를 앞두고 걱정이 드셨군요.',
  nextQuestion: '발표에서 어떤 부분이 가장 걱정되나요?', summary: '발표를 앞둔 불안과 준비에 대한 필요',
  answerExamples: ['저는 말을 잊어버릴까 봐 걱정돼요.', '저는 사람들의 시선이 부담스러워요.'] });
function setup(options = {}) {
  const events = [];
  const calls = [];
  const service = createConversationService({ env, logger: { info: (_, data) => events.push(data) },
    openAiFactory: () => assert.fail('OpenAI must never initialize'),
    ollamaFactory: () => ({ runStructured: async task => { calls.push(task.name); return support(); } }), ...options });
  return { service, events, calls };
}

test('Ollama mode generates support while external APIs are disabled; no text enters telemetry', async () => {
  const { service, events, calls } = setup();
  const result = await service(body());
  assert.equal(result.message, support().empathy);
  assert.deepEqual(responseSchema.parse(result), result);
  assert.deepEqual(calls, ['support_turn_v1']);
  assert.equal(events[0].provider, 'ollama');
  assert.equal(events[0].modelCalls, 1);
  assert.equal(events[0].estimatedCostUsd, 0);
  assert.doesNotMatch(JSON.stringify(events), /발표|걱정/);
});

test('Ollama cold/warm safety corpus bypasses all models, factories and retrieval; safe cases reach the model', async () => {
  const cases = JSON.parse(await readFile(new URL('../../backend_contract/safety_cases.json', import.meta.url)));
  let creations = 0;
  let calls = 0;
  const { service, events } = setup({
    ollamaFactory: () => { creations++; return { runStructured: async () => { calls++; return support(); } }; },
    knowledgeProvider: { search: () => assert.fail('No retrieval for crisis or general support') },
    selectReligion: () => assert.fail('No religion agent for crisis or general support'),
  });
  for (const warm of [false, true]) {
    if (warm) await service(body());
    const before = { creations, calls };
    for (const item of cases.filter(row => row.level > 0)) {
      const request = body(item.text);
      assert.deepEqual(await service(request), crisisResponse('불안', assessRequestCrisis(request)), item.id);
      assert.equal(events.at(-1).modelCalls, 0);
    }
    assert.deepEqual({ creations, calls }, before);
  }
  for (const item of cases.filter(row => row.level === 0)) {
    const before = calls;
    const result = await service(body(item.text));
    assert.equal(result.riskLevel, 0, item.id);
    assert.ok(calls > before, item.id);
  }
  const request = body(); request.session.riskLevel = 2;
  const before = calls;
  assert.equal((await service(request)).stage, 'crisis');
  assert.equal(calls, before);
});

test('Ollama errors, invalid output and unsupported scripture fall back without cloud calls', async () => {
  for (const runStructured of [async () => { throw Error('private-provider-error'); },
    async () => ({ invalid: true }), async () => ({ ...support(), empathy: '요한복음 3:16은 "가짜 말씀"이라고 합니다.' })]) {
    const { service, events } = setup({ ollamaFactory: () => ({ runStructured }) });
    const result = await service(body());
    assert.equal(events.at(-1).fallback, true);
    assert.equal(events.at(-1).provider, 'local');
    assert.doesNotMatch(JSON.stringify(result), /가짜 말씀|private-provider-error/);
    responseSchema.parse(result);
  }
});

test('Ollama deadline aborts transport and simultaneous requests do not grow an inference queue', async () => {
  let signal;
  const { service, events } = setup({ timeoutMs: 20, ollamaFactory: () => ({ runStructured: (_, options) => {
    signal = options.signal; return new Promise((_, reject) => signal.addEventListener('abort', () => reject(signal.reason), { once: true }));
  } }) });
  const first = service(body());
  await service(body());
  assert.equal(events.at(-1).fallbackReason, 'local_busy');
  await first;
  assert.equal(signal.aborted, true);
  assert.equal(events.at(-1).fallbackReason, 'timeout');
});

test('Ollama religion path never asks for doctrine without approved evidence', async () => {
  const calls = [];
  const { service } = setup({ ollamaFactory: () => ({ runStructured: async task => {
    calls.push(task.name); assert.equal(task.name, 'psychology_reflection'); return psychologyOutput();
  } }) });
  const result = await service(body('성경에서 말하는 구원을 설명해 주세요'));
  assert.deepEqual(calls, ['psychology_reflection']);
  assert.equal(result.riskLevel, 0);
  assert.match(result.message, /근거|자료|확인/);
});

test('Ollama transport restricts endpoints/models, rejects incomplete data and validates JSON', async () => {
  for (const baseUrl of ['https://example.com', 'http://localhost.evil:11434', 'http://127.0.0.1@evil', 'http://127.0.0.1/path']) {
    assert.throws(() => createOllamaService({ baseUrl }));
  }
  assert.throws(() => createOllamaService({ model: 'qwen-cloud' }));
  const task = { instructions: 'policy', input: { text: 'private' }, jsonSchema: { type: 'object' }, schema: z.object({ ok: z.boolean() }).strict() };
  for (const output of [{ done: false }, { done: true, done_reason: 'length', message: { content: '{"ok":true}' } },
    { done: true, message: { content: 'invalid' } }, { done: true, message: { content: '{"wrong":1}' } }]) {
    const provider = createOllamaService({ fetchImpl: async () => Response.json(output) });
    await assert.rejects(provider.runStructured(task));
  }
  const signal = new AbortController().signal;
  const provider = createOllamaService({ fetchImpl: async (url, options) => {
    assert.equal(url.href, 'http://127.0.0.1:11434/api/chat');
    assert.equal(options.redirect, 'error'); assert.equal(options.signal, signal);
    const request = JSON.parse(options.body);
    assert.equal(request.think, false); assert.equal(request.stream, false);
    assert.deepEqual(request.format, task.jsonSchema);
    return Response.json({ done: true, message: { content: '{"ok":true}' } });
  } });
  assert.deepEqual(await provider.runStructured(task, { signal }), { ok: true });
});
