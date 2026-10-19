// Product pacing rules, not a clinical scale. Crisis detection is independent.
const positive = new Set(['감사', '기쁨', '행복', '기대', '감탄']);
export function emotionResponsePolicy(context, detectedEmotion = context.emotion) {
  const mixed = Boolean(context.customEmotion) || ['놀람', '벅찬'].includes(detectedEmotion);
  const changed = detectedEmotion !== context.emotion;
  const score = changed || mixed ? null : context.intensity;
  const pleasant = positive.has(detectedEmotion) && !mixed;
  const high = !pleasant && score >= 7;
  return {
    mode: mixed ? 'clarify_valence' : pleasant ? 'savor' : high ? 'gentle_support' : 'explore',
    initialIntensity: score,
    maxExamples: mixed ? 2 : high ? (score >= 9 ? 1 : 2) : 3,
    deferVerse: high || mixed || changed,
    guidance: mixed ? '좋은 벅참인지 부담인지 먼저 확인한다.'
      : changed ? '감정이 바뀌었으므로 처음 점수를 새 감정의 점수로 간주하지 않는다.'
      : pleasant ? '기쁨을 문제로 취급하지 않고 의미와 나눔을 살핀다.'
      : score >= 9 ? '짧은 공감과 부담 적은 질문 하나만 한다. 설명을 요구하지 않는다.'
      : high ? '짧은 질문으로 지금 필요한 도움을 먼저 확인한다.'
      : score <= 3 ? '가벼운 감정을 과장하거나 고통을 단정하지 않는다.'
      : '앞선 답을 바탕으로 상황과 필요를 이어서 살핀다.',
  };
}
export function explicitlyRequestsVerse(text) {
  if (/싫|않|말고|원치|거절|나중|아니/.test(text)) return false;
  return /말씀|성경|구절/.test(text) && /읽|보고|볼래|원해|주세요|듣/.test(text);
}
export function applySupportTurn(result, turn, context, { allowVerse }) {
  const policy = emotionResponsePolicy(context, turn.emotion);
  const ready = turn.readyForVerse === true && allowVerse
    && (!policy.deferVerse || explicitlyRequestsVerse(context.userMessage))
    && (context.conversationState.turnCount ?? 0) >= 2
    && context.allowedVerseIds.includes(turn.suggestedVerseId)
    && (context.verseCandidates ?? []).some(item => item.id === turn.suggestedVerseId);
  const complete = (context.conversationState.turnCount ?? 0) >= 4;
  Object.assign(result, {
    message: turn.empathy, detectedEmotion: turn.emotion,
    stage: complete ? 'summary' : ready ? 'verse_offer' : 'need',
    question: complete || ready ? null : turn.nextQuestion,
    answerExamples: complete || ready ? [] : (turn.answerExamples ?? []).slice(0, policy.maxExamples),
    shouldOfferVerse: !complete && ready,
    suggestedVerseId: !complete && ready ? turn.suggestedVerseId : null,
    shouldEndConversation: complete,
    continueConversation: !complete && !ready,
    responseMode: 'ai',
    // Local scaffold observations are not AI insights.
    clinicalReflection: null, integratedInsight: null,
  });
  return result;
}
