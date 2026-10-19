import { answerExamplesSchema, answerExamplesJsonSchema, answerExamplesInstructions } from '../answer_examples.js';
import { psychologySchema, psychologyJsonSchema } from './agent_contracts.js';
import { prompt } from './prompts/psychology_prompt.js';
import { z } from 'zod';
import { emotions } from '../schema.js';
import { emotionResponsePolicy } from '../emotion_response_policy.js';

export const supportSchema = z.object({
  emotion: z.enum(emotions), empathy: z.string().trim().min(1).max(140),
  answerExamples: answerExamplesSchema,
  readyForVerse: z.boolean().optional(), suggestedVerseId: z.string().max(100).nullable().optional(),
  nextQuestion: z.string().trim().min(1).max(100), summary: z.string().trim().min(1).max(120),
}).strict();
export const supportJsonSchema = {
  type: 'object', additionalProperties: false, required: ['emotion', 'empathy', 'nextQuestion', 'summary', 'answerExamples', 'readyForVerse', 'suggestedVerseId'],
  properties: { readyForVerse: { type: 'boolean' }, suggestedVerseId: { type: ['string', 'null'] }, answerExamples: answerExamplesJsonSchema, emotion: { type: 'string', enum: emotions }, empathy: { type: 'string' },
    nextQuestion: { type: 'string' }, summary: { type: 'string' } },
};

export function createSupportTurn({ runStructured }) {
  return async (context, options) => supportSchema.parse(await runStructured({
    name: 'support_turn_v1',
    instructions: '감정 관찰과 짧은 공감, 다음 질문 하나, 핵심 기억 한 문장을 한 번에 작성합니다. 각 문장은 짧게 쓰세요. 요약은 감정과 필요만 담고 원문을 복사하지 마세요. 진단·처방·교리 해석·경전 인용은 하지 마세요. 질문은 사용자가 이미 답한 질문을 반복하지 마세요. responsePolicy를 따라 현재 답변에 공감하고 질문과 예시를 함께 작성하세요. 초기 감정과 강도는 현재 상태를 확정하지 않습니다. 말씀을 원하거나 필요를 충분히 살핀 때만 readyForVerse=true로 하고 verseCandidates의 tags가 현재 필요에 맞을 때 그 ID만 고르세요. 후보가 없으면 읽기를 제안하지 마세요. tags는 선택용이며 인용 근거가 아닙니다. 구절 내용을 추측하거나 인용하지 마세요. 근거가 없으면 false와 null입니다. 전환 시 공감 문장에서 사용자가 말한 필요와 읽기를 연결하세요.' + answerExamplesInstructions + ' responsePolicy.maxExamples가 예시 개수의 상한이며 더 우선합니다.',
    input: { ...context, responsePolicy: emotionResponsePolicy(context) }, schema: supportSchema, jsonSchema: supportJsonSchema,
  }, options));
}

export function createPsychologyAgent({ runStructured }) {
  return async (context, { signal } = {}) => psychologySchema.parse(await runStructured({
    name: 'psychology_reflection',
    instructions: `[${prompt.version}]\n${prompt.instructions}`,
    input: context,
    jsonSchema: psychologyJsonSchema,
    schema: psychologySchema,
  }, { signal }));
}
