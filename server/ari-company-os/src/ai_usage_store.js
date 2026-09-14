import fs from 'node:fs';
import path from 'node:path';

export class AiUsageStore {
  constructor(filePath) {
    this.filePath = filePath;
    fs.mkdirSync(path.dirname(filePath), {recursive: true});
    try { fs.writeFileSync(filePath, '', {flag: 'wx', mode: 0o600}); } catch (e) { if (e.code !== 'EEXIST') throw e; }
  }

  record(event = {}) {
    const row = {
      at: new Date().toISOString(),
      provider: event.provider ?? 'unknown',
      lane: event.lane ?? 'unknown',
      model: event.model ?? 'unknown',
      agentId: event.agentId ?? 'unknown',
      taskType: event.taskType ?? 'unknown',
      outcome: event.outcome ?? 'unknown',
      durationMs: Number.isFinite(event.durationMs) ? event.durationMs : null,
      inputTokens: Number.isFinite(event.inputTokens) ? event.inputTokens : null,
      cachedInputTokens: Number.isFinite(event.cachedInputTokens) ? event.cachedInputTokens : null,
      outputTokens: Number.isFinite(event.outputTokens) ? event.outputTokens : null,
      totalTokens: Number.isFinite(event.totalTokens) ? event.totalTokens : null,
      tokenState: event.tokenState ?? (Number.isFinite(event.totalTokens) ? 'MEASURED' : 'UNAVAILABLE'),
      estimatedCostUsd: Number.isFinite(event.estimatedCostUsd) ? event.estimatedCostUsd : null,
      escalated: event.escalated === true,
      taskId: event.taskId ?? null,
      note: event.note ?? null
    };
    fs.appendFileSync(this.filePath, JSON.stringify(row) + '\n', {encoding: 'utf8', mode: 0o600});
    return row;
  }

  list({since, limit = 1000} = {}) {
    if (!fs.existsSync(this.filePath)) return [];
    const cutoff = since ? Date.parse(since) : 0;
    const rows = fs.readFileSync(this.filePath, 'utf8').split('\n').filter(Boolean).flatMap(line => {
      try { const row = JSON.parse(line); return !cutoff || Date.parse(row.at) >= cutoff ? [row] : []; } catch { return []; }
    });
    return rows.slice(-Math.max(1, Math.min(limit, 10000)));
  }

  summary({since} = {}) {
    const rows = this.list({since, limit: 10000});
    const totals = {calls: rows.length, localCalls: 0, externalCalls: 0, measuredTokens: 0, callsWithMeasuredTokens: 0, escalations: 0, estimatedCostUsd: 0};
    const byAgent = {}, byProvider = {};
    for (const row of rows) {
      if (row.lane === 'local') totals.localCalls++;
      if (row.lane === 'external') totals.externalCalls++;
      if (Number.isFinite(row.totalTokens)) { totals.measuredTokens += row.totalTokens; totals.callsWithMeasuredTokens++; }
      if (row.escalated) totals.escalations++;
      if (Number.isFinite(row.estimatedCostUsd)) totals.estimatedCostUsd += row.estimatedCostUsd;
      const add = (bucket, key) => {
        bucket[key] ??= {calls: 0, localCalls: 0, externalCalls: 0, measuredTokens: 0, unknownTokenCalls: 0};
        bucket[key].calls++;
        if (row.lane === 'local') bucket[key].localCalls++;
        if (row.lane === 'external') bucket[key].externalCalls++;
        if (Number.isFinite(row.totalTokens)) bucket[key].measuredTokens += row.totalTokens; else bucket[key].unknownTokenCalls++;
      };
      add(byAgent, row.agentId); add(byProvider, `${row.provider}:${row.model}`);
    }
    totals.localRate = totals.calls ? totals.localCalls / totals.calls : 0;
    totals.tokenCoverageRate = totals.calls ? totals.callsWithMeasuredTokens / totals.calls : 0;
    totals.estimatedCostUsd = Number(totals.estimatedCostUsd.toFixed(6));
    return {totals, byAgent, byProvider, generatedAt: new Date().toISOString()};
  }
}
