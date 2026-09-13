import {VerificationRunner,sensitiveFailure} from './verification_runner.js';
// Existing repair-agent orchestration; the independent verifier never receives a writer.
export class VerificationWorkflow{
 constructor({repairWorker=null,maxRepairAttempts=2}={}){this.verifier=new VerificationRunner();this.repairWorker=repairWorker;this.maxRepairAttempts=Math.min(2,Math.max(0,Math.floor(maxRepairAttempts)||0));}
 async verify(input){
  const repairs=[],checks=[];
  for(;;){
   const result=await this.verifier.verify({...input,expectedFingerprint:repairs.length?undefined:input.expectedFingerprint});checks.push(...result.checks.filter(c=>!c.id.startsWith('core-')));
   const output={...result,checks,repairs};
   if(result.state!=='FAIL'||!result.repairable||!this.repairWorker)return output;
   if(repairs.length>=this.maxRepairAttempts)return {...output,state:'HUMAN_REVIEW',reason:'repair_limit'};
   if(sensitiveFailure(result.failedCheck))return {...output,state:'HUMAN_REVIEW'};
   const repair=await this.repairWorker({...input,failedCheck:result.failedCheck,result:result.failure,attempt:repairs.length+1});repairs.push({attempt:repairs.length+1,...repair});
   if(repair?.humanReview)return {...output,repairs,state:'HUMAN_REVIEW'};
  }
 }
}
