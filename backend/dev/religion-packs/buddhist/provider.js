import { isDeepStrictEqual } from 'node:util';
import { MOCK_SCRIPTURES, EXTERNAL_REVIEW } from './fixtures.js';

export class BuddhistScriptureProvider {
  constructor({ mode = 'TEST_DATA_ONLY', environment = process.env.NODE_ENV } = {}) {
    if (mode !== 'TEST_DATA_ONLY' || environment === 'production') throw Error('TEST_DATA_ONLY_REQUIRED');
    Object.freeze(this);
  }

  // Closed fixture allowlist: even relabelled external content cannot be admitted.
  get(id) { return MOCK_SCRIPTURES.find((item) => item.id === id) ?? null; }

  search(query) {
    const normalized = String(query ?? '').normalize('NFKC').trim().toLowerCase();
    if (!normalized || normalized.length > 2000) return [];
    return MOCK_SCRIPTURES.filter((item) => item.tags.some((tag) => normalized.includes(tag)));
  }

  assertCitation(citation) {
    const canonical = this.get(citation?.id);
    if (!canonical || !isDeepStrictEqual(citation, canonical)) throw Error('UNSUPPORTED_SCRIPTURE');
    return canonical;
  }

  mindCard(id) {
    const scripture = this.get(id);
    if (!scripture) throw Error('UNSUPPORTED_SCRIPTURE');
    return Object.freeze({ religion: 'buddhist', label: 'TEST_DATA_ONLY · 실제 경전이 아닌 테스트 마음카드', scripture });
  }

  status() {
    return { mode: 'TEST_DATA_ONLY', productionEnabled: false, importEnabled: false,
      fixtures: MOCK_SCRIPTURES.map(({ id, copyright_status }) => ({ id, copyright_status })),
      externalReview: EXTERNAL_REVIEW };
  }
}
