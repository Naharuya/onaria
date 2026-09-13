import test from 'node:test';
import assert from 'node:assert/strict';
import { brandEnv } from '../src/brand_env.js';
import { costPolicy } from '../src/cost/cost_gate.js';
import { productionConfiguration } from '../src/knowledge/production_readiness.js';

test('ONARIA environment names take precedence without mutating legacy configuration', () => {
  const env = Object.freeze({ ONARIA_AI_MODE: '', SOUL_AI_MODE: 'local', MIND_AI_MODE: 'other' });
  assert.equal(brandEnv(env).ONARIA_AI_MODE, '');
  assert.equal(brandEnv({ SOUL_AI_MODE: 'local' }).ONARIA_AI_MODE, 'local');
  assert.equal(brandEnv({ MIND_AI_MODE: 'local' }).ONARIA_AI_MODE, 'local');
  assert.equal(env.SOUL_AI_MODE, 'local');
});

test('legacy budgets and safety settings retain behavior during migration', () => {
  assert.deepEqual(costPolicy('free', { SOUL_FREE_DAILY_AI_CALLS: '2' }),
    costPolicy('free', { ONARIA_FREE_DAILY_AI_CALLS: '2' }));
  assert.equal(costPolicy('free', { ONARIA_FREE_DAILY_AI_CALLS: '0', SOUL_FREE_DAILY_AI_CALLS: '20' }).dailyCalls, 0);
  assert.deepEqual(productionConfiguration({ SOUL_EXTERNAL_API_DISABLED: 'true', SOUL_MULTI_AGENT_ENABLED: 'false' }),
    productionConfiguration({ ONARIA_EXTERNAL_API_DISABLED: 'true', ONARIA_MULTI_AGENT_ENABLED: 'false' }));
});
