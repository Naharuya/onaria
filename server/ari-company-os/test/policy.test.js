import test from 'node:test';
import assert from 'node:assert/strict';
import { assertAutomationAllowed, releaseState, requiresHumanApproval } from '../src/policy.js';

test('protected actions require human approval', () => {
  assert.equal(requiresHumanApproval('production_deploy'), true);
  assert.equal(requiresHumanApproval('app_store_publish'), true);
  assert.equal(requiresHumanApproval('verification'), false);
});

test('protected branches cannot be modified by automation', () => {
  assert.throws(() => assertAutomationAllowed({ project: 'onaria', branch: 'main', action: 'verification' }), /Protected branch/);
  assert.equal(assertAutomationAllowed({ project: 'onaria', branch: 'automation/test', action: 'verification' }), true);
});

test('release requires server, CI, device and owner approval', () => {
  assert.equal(releaseState({ serverPass: true, githubCiPass: true, testBuild: true, devicePass: false, releaseApproved: false }), 'WAITING_DEVICE_PASS');
  assert.equal(releaseState({ serverPass: true, githubCiPass: true, testBuild: true, devicePass: true, releaseApproved: false }), 'WAITING_RELEASE_APPROVAL');
  assert.equal(releaseState({ serverPass: true, githubCiPass: true, testBuild: true, devicePass: true, releaseApproved: true }), 'RELEASE_APPROVED');
});
