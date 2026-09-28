export const NO_SOURCE = '검색된 테스트 자료가 없습니다. 경전 문구나 출처를 생성하지 않습니다.';
export const MOCK_MESSAGE = '실제 경전이 아닌 화면 검증용 자료입니다. 원하시면 잠시 쉬어 가셔도 괜찮습니다.';

// No model, client factory, external retrieval, or generated scripture in this phase.
export function createBuddhistAgent(provider) {
  return Object.freeze({
    respond(request) {
      const citations = provider.search(request.userMessage);
      const response = { religion: 'buddhist', mode: 'TEST_DATA_ONLY', stage: 'reflection',
        message: citations.length ? MOCK_MESSAGE : NO_SOURCE, citations };
      return validateBuddhistResponse(response, provider);
    },
  });
}

export function validateBuddhistResponse(response, provider) {
  if (response.religion !== 'buddhist' || response.mode !== 'TEST_DATA_ONLY' || response.stage !== 'reflection'
    || !Array.isArray(response.citations)
    || Object.keys(response).sort().join(',') !== 'citations,message,mode,religion,stage'
    || response.message !== (response.citations.length ? MOCK_MESSAGE : NO_SOURCE)) throw Error('UNSUPPORTED_SCRIPTURE');
  response.citations.forEach((citation) => provider.assertCitation(citation));
  return response;
}
