import test from 'node:test';
import assert from 'node:assert/strict';
import { planRetention } from '../src/privacy/retention_plan.js';
const now = '2026-10-10T00:00:00.000Z';
test('만료 경계 포함 세션 모의 계획은 입력을 변경하거나 식별자를 노출하지 않는다', () => {
  const records = [{ expires_at: Date.parse(now), token_hash: 'fixture-private' }, { expires_at: Date.parse(now) + 1 }];
  const before = structuredClone(records);
  const result = planRetention({ kind: 'sessions', records, now });
  assert.equal(result.candidates, 1); assert.equal(result.retained, 1);
  assert.deepEqual(records, before); assert.equal(JSON.stringify(result).includes('fixture-private'), false);
});
test('비용 원장 경계와 pending은 실제 삭제 전에 구분한다', () => {
  const cutoff = Date.parse(now) - 62 * 86400000;
  const records = [
    { timestamp: new Date(cutoff - 1).toISOString(), state: 'finished' },
    { timestamp: new Date(cutoff).toISOString(), state: 'abandoned' },
    { timestamp: new Date(cutoff - 1).toISOString(), state: 'pending' },
  ];
  const result = planRetention({ kind: 'usage', records, now, retentionDays: 62 });
  assert.equal(result.candidates, 1); assert.equal(result.retained, 1); assert.equal(result.blocked, 1);
});
test('회원·백업·기기 기록에 1년 기준을 임의 적용하지 않는다', () => {
  for (const kind of ['members', 'backups', 'local_records']) {
    const result = planRetention({ kind, now, records: [{ created_at: '2020-01-01T00:00:00.000Z' }] });
    assert.equal(result.blocked, 1); assert.equal(result.candidates, 0);
  }
});
test('설정 누락·범위 오류·잘못된 시각은 안전하게 거절한다', () => {
  assert.throws(() => planRetention({ kind: 'usage', now, records: [] }), TypeError);
  assert.throws(() => planRetention({ kind: 'usage', now, records: [], retentionDays: 367 }), TypeError);
  assert.throws(() => planRetention({ kind: 'sessions', now: NaN, records: [] }), TypeError);
  const result = planRetention({ kind: 'sessions', now, records: [{ expires_at: null }, { expires_at: '2020-01-01' }] });
  assert.equal(result.invalid, 2); assert.equal(result.candidates, 0);
});
test('반복 평가 결과가 같고 입력은 불변', () => {
  const input = { kind: 'usage', now, retentionDays: 62, records: [{ timestamp: '2020-01-01T00:00:00.000Z', state: 'finished' }] };
  assert.deepEqual(planRetention(input), planRetention(input));
});
test('존재하지 않는 날짜와 Date 범위 밖 숫자를 파기 후보로 받아들이지 않는다', () => {
  const result = planRetention({ kind: 'sessions', now, records: [
    { expires_at: '2026-02-30T00:00:00.000Z' },
    { expires_at: -Number.MAX_SAFE_INTEGER },
  ] });
  assert.equal(result.invalid, 2); assert.equal(result.candidates, 0);
  assert.throws(() => planRetention({ kind: 'sessions', now: Number.MAX_SAFE_INTEGER, records: [] }), TypeError);
});
