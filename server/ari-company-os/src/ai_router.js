import {performance} from 'node:perf_hooks';

const HIGH_RISK = /safety|crisis|privacy|legal|license|payment|pricing|production|publish|release|live.?trad|secret|security|auth|개인정보|법률|실거래|안전/i;
const EXTERNAL_FIRST = new Set(['DEVELOPMENT','REPAIR','ARCHITECTURE','SECURITY_REVIEW','RELEASE_GATE']);
const LOCAL_FIRST = new Set(['DAILY_REPORT','CUSTOMER_RESEARCH','COMPETITOR','GROWTH','FINANCE','GOVERNMENT_GRANT','SUMMARIZE','CLASSIFY','LOG_ANALYSIS']);

export class AiRouter {
  constructor({usageStore, localBaseUrl='http://127.0.0.1:11434', localModel=process.env.ARI_LOCAL_AI_MODEL ?? 'qwen3.5:4b-mlx', externalComplete=null, fetchImpl=globalThis.fetch}={}) {
    this.usageStore=usageStore; this.localBaseUrl=localBaseUrl.replace(/\/$/,''); this.localModel=localModel; this.externalComplete=externalComplete; this.fetch=fetchImpl;
  }

  decide({taskType='UNKNOWN', riskCategory='', sensitivity='', forceExternal=false, forceLocal=false}={}) {
    const high = HIGH_RISK.test([taskType,riskCategory,sensitivity].join(' '));
    if (high) return {lane:'external', reason:'high_risk_or_sensitive', humanReview:true};
    if (forceExternal || EXTERNAL_FIRST.has(taskType)) return {lane:'external', reason:'external_first', humanReview:false};
    if (forceLocal || LOCAL_FIRST.has(taskType)) return {lane:'local', reason:'local_first', humanReview:false};
    return {lane:'local', reason:'local_default_with_escalation', humanReview:false};
  }

  async complete({agentId='unknown',taskId=null,taskType='UNKNOWN',prompt,riskCategory='',sensitivity='',forceExternal=false,forceLocal=false,allowEscalation=true}={}) {
    if (typeof prompt!=='string' || !prompt.trim()) throw new Error('prompt_required');
    const decision=this.decide({taskType,riskCategory,sensitivity,forceExternal,forceLocal});
    if (decision.humanReview) return {state:'HUMAN_REVIEW',route:decision};
    if (decision.lane==='external') return this.#external({agentId,taskId,taskType,prompt,decision});
    const local=await this.#local({agentId,taskId,taskType,prompt,decision});
    if (local.state==='DONE' || !allowEscalation) return local;
    if (!this.externalComplete) return local;
    const external=await this.#external({agentId,taskId,taskType,prompt,decision:{lane:'external',reason:'local_failed_escalation'}});
    return {...external, escalatedFromLocal:true};
  }

  async #local({agentId,taskId,taskType,prompt,decision}) {
    const started=performance.now();
    try {
      const response=await this.fetch(`${this.localBaseUrl}/api/generate`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({model:this.localModel,prompt,stream:false,keep_alive:'10m'})});
      if(!response.ok) throw new Error(`ollama_http_${response.status}`);
      const data=await response.json();
      const inputTokens=Number.isFinite(data.prompt_eval_count)?data.prompt_eval_count:null;
      const outputTokens=Number.isFinite(data.eval_count)?data.eval_count:null;
      const totalTokens=inputTokens!==null&&outputTokens!==null?inputTokens+outputTokens:null;
      this.usageStore?.record({provider:'ollama',lane:'local',model:data.model??this.localModel,agentId,taskId,taskType,outcome:'success',durationMs:Math.round(performance.now()-started),inputTokens,outputTokens,totalTokens,tokenState:totalTokens===null?'UNAVAILABLE':'MEASURED'});
      return {state:'DONE',route:decision,provider:'ollama',model:data.model??this.localModel,text:data.response??'',usage:{inputTokens,outputTokens,totalTokens}};
    } catch (error) {
      this.usageStore?.record({provider:'ollama',lane:'local',model:this.localModel,agentId,taskId,taskType,outcome:'failed',durationMs:Math.round(performance.now()-started),tokenState:'UNAVAILABLE',note:String(error.message??'local_ai_failed')});
      return {state:'LOCAL_AI_UNAVAILABLE',route:decision,reason:'local_ai_unavailable'};
    }
  }

  async #external({agentId,taskId,taskType,prompt,decision}) {
    const started=performance.now();
    if (!this.externalComplete) {
      this.usageStore?.record({provider:'external',lane:'external',model:'unconfigured',agentId,taskId,taskType,outcome:'blocked',durationMs:0,tokenState:'UNAVAILABLE',escalated:decision.reason==='local_failed_escalation',note:'external_adapter_not_configured'});
      return {state:'EXTERNAL_AI_REQUIRED',route:decision,reason:'external_adapter_not_configured'};
    }
    try {
      const result=await this.externalComplete({prompt,agentId,taskId,taskType});
      const usage=result?.usage??{};
      const totalTokens=Number.isFinite(usage.totalTokens)?usage.totalTokens:(Number.isFinite(usage.inputTokens)&&Number.isFinite(usage.outputTokens)?usage.inputTokens+usage.outputTokens:null);
      this.usageStore?.record({provider:result?.provider??'external',lane:'external',model:result?.model??'unknown',agentId,taskId,taskType,outcome:'success',durationMs:Math.round(performance.now()-started),inputTokens:usage.inputTokens,cachedInputTokens:usage.cachedInputTokens,outputTokens:usage.outputTokens,totalTokens,tokenState:totalTokens===null?'UNAVAILABLE':'MEASURED',estimatedCostUsd:result?.estimatedCostUsd,escalated:decision.reason==='local_failed_escalation'});
      return {state:'DONE',route:decision,...result,usage:{...usage,totalTokens}};
    } catch {
      this.usageStore?.record({provider:'external',lane:'external',model:'unknown',agentId,taskId,taskType,outcome:'failed',durationMs:Math.round(performance.now()-started),tokenState:'UNAVAILABLE',escalated:decision.reason==='local_failed_escalation'});
      return {state:'EXTERNAL_AI_UNAVAILABLE',route:decision,reason:'external_ai_unavailable'};
    }
  }
}
