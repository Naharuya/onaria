export const HUMAN_APPROVAL_ACTIONS = new Set([
  'production_deploy',
  'app_store_publish',
  'main_or_master_merge',
  'safety_policy_change',
  'privacy_or_retention_change',
  'legal_or_license_decision',
  'payment_or_price_change',
  'live_trading_enablement',
  'irreversible_data_deletion',
  'large_paid_marketing_spend',
]);

export function requiresHumanApproval(action) {
  return HUMAN_APPROVAL_ACTIONS.has(action);
}

export function assertAutomationAllowed({ branch, action, project }) {
  if (branch === 'main' || branch === 'master') {
    const error = new Error(`Protected branch write blocked: ${branch}`);
    error.code = 'HUMAN_REVIEW';
    throw error;
  }
  if (requiresHumanApproval(action)) {
    const error = new Error(`Human approval required for ${action}`);
    error.code = 'HUMAN_REVIEW';
    throw error;
  }
  if (project === 'k-stock-ai' && action === 'live_trade') {
    const error = new Error('Live trading is never allowed from automation.');
    error.code = 'HUMAN_REVIEW';
    throw error;
  }
  return true;
}

export function releaseState({ serverPass, githubCiPass, devicePass, releaseApproved }) {
  if (!serverPass || !githubCiPass) return 'NOT_READY';
  if (!devicePass) return 'WAITING_DEVICE_PASS';
  if (!releaseApproved) return 'WAITING_RELEASE_APPROVAL';
  return 'RELEASE_APPROVED';
}
