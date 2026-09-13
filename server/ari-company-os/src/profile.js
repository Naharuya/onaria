import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';
export function humanReview(reason) { return Object.assign(new Error(reason), { code: 'HUMAN_REVIEW' }); }
export function loadProfile(dir) {
  const file = path.join(dir, '.ari', 'verification.yaml');
  if (!fs.existsSync(file)) throw humanReview('missing_verification_profile');
  let profile;
  try { profile = YAML.parse(fs.readFileSync(file, 'utf8')); } catch { throw humanReview('invalid_profile_yaml'); }
  if (!Array.isArray(profile?.checks) || !profile.checks.length) throw humanReview('empty_verification_profile');
  const ids = new Set();
  for (const c of profile.checks) {
    if (!c.id || ids.has(c.id) || typeof c.command !== 'string' || !/^[a-zA-Z0-9_@./-]+$/.test(c.command) || !Array.isArray(c.args) || c.args.some(a => typeof a !== 'string')) throw humanReview('invalid_check_requires_id_command_args');
    if(!['node','npm','flutter','git',process.execPath].includes(c.command))throw humanReview('command_not_allowlisted');
    if(Object.keys(c.env??{}).some(k=>!['KSTOCK_LIVE_TRADING_ENABLED','KSTOCK_AI_MODE','SOUL_AI_MODE','SOUL_EXTERNAL_API_DISABLED'].includes(k)))throw humanReview('environment_not_allowlisted');
    ids.add(c.id);
    const cwd = path.resolve(dir, c.cwd ?? '.');
    const realRoot = fs.realpathSync(dir);
    if (!fs.existsSync(cwd) || !(fs.realpathSync(cwd) === realRoot || fs.realpathSync(cwd).startsWith(realRoot + path.sep))) throw humanReview('check_cwd_outside_project');
    if (c.env?.KSTOCK_LIVE_TRADING_ENABLED && c.env.KSTOCK_LIVE_TRADING_ENABLED !== 'false') throw humanReview('live_trading_environment_blocked');
    if (c.timeoutMs !== undefined && (!Number.isSafeInteger(c.timeoutMs) || c.timeoutMs <= 0)) throw humanReview('invalid_timeout');
  }
  return profile;
}
