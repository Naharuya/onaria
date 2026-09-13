export const HUMAN_APPROVAL_ACTIONS=new Set(['production_deploy','app_store_publish','main_or_master_merge','safety_policy_change','privacy_or_retention_change','legal_or_license_decision','payment_or_price_change','live_trading_enablement','irreversible_data_deletion','large_paid_marketing_spend']);
export function requiresHumanApproval(action){return HUMAN_APPROVAL_ACTIONS.has(action);}
export function assertAutomationAllowed({branch,action,project}){
 if(branch==='main'||branch==='master')throw Object.assign(new Error(`Protected branch write blocked: ${branch}`),{code:'HUMAN_REVIEW'});
 if(requiresHumanApproval(action)||(project==='k-stock-ai'&&action==='live_trade'))throw Object.assign(new Error('Human approval required'),{code:'HUMAN_REVIEW'});
 return true;
}
export function releaseState({serverPass,githubCiPass,testBuild,devicePass,releaseApproved}){
 if(!serverPass)return 'NOT_READY';
 if(!githubCiPass)return 'WAITING_GITHUB_CI';
 if(!testBuild)return 'WAITING_TEST_BUILD';
 if(!devicePass)return 'WAITING_DEVICE_PASS';
 if(!releaseApproved)return 'WAITING_RELEASE_APPROVAL';
 return 'RELEASE_APPROVED';
}
export function releaseEvidence({commit,fingerprint,server,ci,build,device,approval},current){
 if(!commit||commit!==current.commit||fingerprint!==current.fingerprint)return 'STALE_EVIDENCE';
 const matches=e=>e?.commit===commit&&e?.fingerprint===fingerprint;
 return releaseState({serverPass:matches(server)&&server.state==='SERVER_PASS',githubCiPass:matches(ci)&&ci.state==='PASS',testBuild:matches(build)&&Boolean(build.path&&build.sha256),devicePass:matches(device)&&device.state==='DEVICE_PASS',releaseApproved:matches(approval)&&approval.state==='RELEASE_APPROVED'&&approval.by==='owner'});
}
