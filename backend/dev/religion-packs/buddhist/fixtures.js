import { readFileSync } from 'node:fs';

// Shared with the isolated Android app; original synthetic text only.
const raw = JSON.parse(readFileSync(new URL('../../../../packages/onaria_buddhist_pack/assets/mock_scriptures.json', import.meta.url), 'utf8'));
export const MOCK_SCRIPTURES = Object.freeze(raw.map((record) => Object.freeze(
  Object.fromEntries(Object.entries(record).map(([key, value]) => [key, Array.isArray(value) ? Object.freeze(value) : value]))
)));

// Metadata only. No external text, inferred title, translator or source is stored.
export const EXTERNAL_REVIEW = Object.freeze({
  id: 'external-intake-disabled', copyright_status: 'BLOCKED_EXTERNAL_REVIEW',
  reason: '별도 라이선스 검증과 2차 작업 지시 전에는 자료를 받지 않습니다. 한국어 번역권은 원전과 별도로 검증해야 합니다.',
});
