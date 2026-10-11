// 읽기 전용 모의 계획. DB/파일/네트워크 접근과 삭제 기능을 제공하지 않는다.
const DAY_MS = 86_400_000;
const validTime = value => {
  if (typeof value === 'number') return Number.isSafeInteger(value) && Math.abs(value) <= 8_640_000_000_000_000 ? value : NaN;
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/.test(value)) return NaN;
  const parsed = Date.parse(value);
  if (!Number.isFinite(parsed)) return NaN;
  const normalized = value.includes('.') ? value : value.replace('Z', '.000Z');
  return new Date(parsed).toISOString() === normalized ? parsed : NaN;
};

export function planRetention({ kind, records, now, retentionDays } = {}) {
  const time = validTime(now);
  if (!Number.isFinite(time) || !Array.isArray(records)) throw new TypeError('모의 실행 입력이 유효하지 않습니다.');
  if (!['sessions', 'usage', 'members', 'backups', 'local_records'].includes(kind)) throw new TypeError('지원하지 않는 데이터 종류입니다.');
  if (kind === 'usage' && (!Number.isSafeInteger(retentionDays) || retentionDays < 32 || retentionDays > 366)) {
    throw new TypeError('실제 원장 보유 설정이 필요합니다.');
  }
  const result = { mode: 'dry-run', kind, scanned: records.length, candidates: 0, retained: 0, blocked: 0, invalid: 0 };
  for (const record of records) {
    if (!['sessions', 'usage'].includes(kind)) { result.blocked++; continue; }
    if (!record || typeof record !== 'object') { result.invalid++; continue; }
    const stamp = validTime(kind === 'sessions' ? record.expires_at : record.timestamp);
    if (!Number.isFinite(stamp)) { result.invalid++; continue; }
    if (kind === 'usage' && !['pending', 'finished', 'abandoned'].includes(record.state)) { result.invalid++; continue; }
    // pending 행은 실제 원장의 reservation 복구를 먼저 검증해야 한다.
    if (kind === 'usage' && record.state === 'pending') { result.blocked++; continue; }
    const eligible = kind === 'sessions' ? stamp <= time : stamp < time - retentionDays * DAY_MS;
    result[eligible ? 'candidates' : 'retained']++;
  }
  // 개별 식별자·원문·token 또는 파기용 목록을 반환하지 않는다.
  return Object.freeze(result);
}
