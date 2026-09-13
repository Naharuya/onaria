import test from 'node:test';
import assert from 'node:assert/strict';
import { ProjectWatcher, DEFAULT_VERIFICATION_QUIET_MS } from '../src/project_watcher.js';

test('verification quiet window defaults to five minutes', () => {
  assert.equal(DEFAULT_VERIFICATION_QUIET_MS, 5 * 60 * 1000);
  const watcher = new ProjectWatcher({ projects: [], onQuietChange: async () => {} });
  assert.equal(watcher.quietMs, 300000);
});

test('quiet window remains overrideable for controlled tests only', () => {
  const watcher = new ProjectWatcher({ projects: [], onQuietChange: async () => {}, quietMs: 25 });
  assert.equal(watcher.quietMs, 25);
});
