import { brandEnv } from './brand_env.js';
import { requestSchema, responseSchema } from './schema.js';
import { assessSafety } from './agents/safety_agent.js';
import { createLocalConversationService } from './local_conversation_service.js';
import { createOllamaService } from './ollama_service.js';
import { createSupportTurn } from './agents/psychology_agent.js';
import { reviewPsychologyIntegrity } from './agents/religious_integrity_agent.js';
import { createConversationOrchestrator, normalizeContext } from './agents/conversation_orchestrator.js';
import { resolveReligion } from './agents/religion_router.js';
import { routeAgent } from './ai_router.js';
import { classifyTask, routeCostRequest } from './cost/model_router.js';
import { createReligionKnowledgeProvider } from './knowledge/provider.js';
import { keywordRetriever } from './knowledge/retriever.js';
import { createProductionIndex, activeIndexStore } from './knowledge/production_index.js';

export function createOllamaConversationService({ env = {}, logger = console,
  ollamaFactory = createOllamaService, timeoutMs = 18_000, knowledgeProvider, selectReligion, usageLedger } = {}) {
  const config = brandEnv(env);
  const model = config.ONARIA_OLLAMA_MODEL || 'qwen3:8b';
  const local = createLocalConversationService();
  let provider;
  let busy = false;
  const deadline = Number.isFinite(timeoutMs) && timeoutMs > 0 ? Math.min(timeoutMs, 18_000) : 18_000;
  // Local generation never enables cloud embeddings or development sample citations.
  const knowledge = knowledgeProvider ?? createReligionKnowledgeProvider({ mode: 'production', retriever: keywordRetriever,
    ...(config.ONARIA_PRODUCTION_INDEX_DIR ? { store: activeIndexStore(createProductionIndex(config.ONARIA_PRODUCTION_INDEX_DIR)) } : {}) });

  async function generate(request, suppliedAgent, memory = '') {
    const started = performance.now();
    const body = requestSchema.parse(request);
    const context = normalizeContext(body, memory);
    let calls = 0;
    let inputTokens = 0;
    let outputTokens = 0;
    function record(providerName, reason = null) {
      try { logger.info?.('conversation_result', { provider: providerName, model: calls ? model : null,
        modelCalls: calls, inputTokens, outputTokens, estimatedCostUsd: 0,
        fallback: reason !== null, fallbackReason: reason, latencyMs: Math.round(performance.now() - started) }); } catch {}
    }
    // Must precede provider creation, retrieval and all agent calls.
    const safety = assessSafety(context);
    if (safety) { record('safety'); return responseSchema.parse(safety); }
    const agent = suppliedAgent ?? routeAgent({ requestedAgent: body.agentMode, userMessage: body.userMessage, verseLanguage: body.verseLanguage });
    const routing = resolveReligion(body);
    async function baseline() {
      const result = await local(body, agent, memory);
      if (routing.tradition !== 'protestant') {
        result.suggestedVerseId = null; result.shouldOfferVerse = false; result.integratedInsight = null;
        if (['verse_offer', 'action'].includes(result.stage)) {
          result.stage = 'action';
          result.message = '지금까지 나눈 마음을 돌아보며, 오늘 할 수 있는 작은 돌봄을 하나 정해 보세요.';
          result.question = '지금 자신을 위해 할 수 있는 작은 행동은 무엇일까요?';
        }
      }
      return responseSchema.parse(result);
    }
    if (busy) { record('local', 'local_busy'); return baseline(); }
    busy = true;
    const controller = new AbortController();
    let timer;
    const attempt = async () => {
      provider ??= ollamaFactory({ model, baseUrl: config.ONARIA_OLLAMA_BASE_URL || 'http://127.0.0.1:11434' });
      const runStructured = async (task, options = {}) => {
        controller.signal.throwIfAborted();
        calls++;
        return provider.runStructured(task, { ...options, signal: controller.signal, onUsage: counts => {
          if (Number.isSafeInteger(counts?.inputTokens) && counts.inputTokens >= 0) inputTokens += counts.inputTokens;
          if (Number.isSafeInteger(counts?.outputTokens) && counts.outputTokens >= 0) outputTokens += counts.outputTokens;
        } });
      };
      const task = classifyTask(body);
      if (['bible_search', 'religion_search'].includes(task) || routeCostRequest(body, env).specialist) {
        return createConversationOrchestrator({ runStructured, knowledgeProvider: knowledge, selectReligion,
          corpusMode: 'production', strictEvidence: true, logger })(body, agent, memory, { signal: controller.signal });
      }
      const turn = await createSupportTurn({ runStructured })(context, { signal: controller.signal });
      controller.signal.throwIfAborted();
      reviewPsychologyIntegrity({ emotionSummary: turn.empathy, supportNeed: turn.summary,
        suggestedTone: 'gentle', avoid: [turn.nextQuestion, ...(turn.answerExamples ?? [])] }, { religion: routing.tradition });
      const result = await baseline();
      result.message = turn.empathy;
      result.detectedEmotion = turn.emotion;
      if (result.question !== null) {
        result.question = turn.nextQuestion;
        result.answerExamples = turn.answerExamples ?? [];
      }
      result.memorySummary = [context.memorySummary.slice(-600), turn.summary].filter(Boolean).join('\n').slice(-800);
      return responseSchema.parse(result);
    };
    try {
      const result = await Promise.race([attempt(), new Promise((_, reject) => {
        timer = setTimeout(() => {
          const error = Object.assign(new Error('Local deadline exceeded.'), { code: 'LOCAL_TIMEOUT' });
          controller.abort(error); reject(error);
        }, deadline);
      })]);
      record('ollama'); return responseSchema.parse(result);
    } catch (error) {
      record('local', controller.signal.aborted ? 'timeout' : error?.code === 'RELIGIOUS_INTEGRITY' ? 'religious_integrity' : 'local_provider_error');
      return baseline();
    } finally { clearTimeout(timer); busy = false; }
  }
  generate.mode = 'ollama conversation';
  generate.usageLedger = usageLedger;
  return generate;
}
