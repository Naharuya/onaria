import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {AiUsageStore} from './ai_usage_store.js';

const here=path.dirname(fileURLToPath(import.meta.url));
const webRoot=path.resolve(here,'../web');
const safeReadJson=(file,fallback=[])=>{try{return JSON.parse(fs.readFileSync(file,'utf8'));}catch{return fallback;}};
const send=(res,status,body,type='application/json; charset=utf-8')=>{res.writeHead(status,{'content-type':type,'cache-control':'no-store','x-content-type-options':'nosniff'});res.end(body);};

export function createDashboardServer({stateRoot,host=process.env.ARI_DASHBOARD_HOST??'127.0.0.1',port=Number(process.env.ARI_DASHBOARD_PORT??8787),logger=console}={}){
  if(!stateRoot)throw new Error('dashboard_state_root_required');
  const usage=new AiUsageStore(path.join(stateRoot,'state/ai-usage.jsonl'));
  const tasksFile=path.join(stateRoot,'state/tasks.json');
  const server=http.createServer((req,res)=>{
    const url=new URL(req.url,'http://localhost');
    if(req.method!=='GET')return send(res,405,JSON.stringify({error:'method_not_allowed'}));
    if(url.pathname==='/api/health')return send(res,200,JSON.stringify({state:'OK',service:'ari-dashboard',at:new Date().toISOString()}));
    if(url.pathname==='/api/tasks'){
      const tasks=safeReadJson(tasksFile,[]).sort((a,b)=>String(b.updatedAt??b.createdAt).localeCompare(String(a.updatedAt??a.createdAt))).slice(0,200);
      return send(res,200,JSON.stringify({tasks,generatedAt:new Date().toISOString()}));
    }
    if(url.pathname==='/api/usage'){
      const hours=Math.max(1,Math.min(Number(url.searchParams.get('hours')??168),24*90));
      const since=new Date(Date.now()-hours*3600000).toISOString();
      return send(res,200,JSON.stringify({summary:usage.summary({since}),events:usage.list({since,limit:500})}));
    }
    if(url.pathname==='/api/summary'){
      const tasks=safeReadJson(tasksFile,[]),active=['PENDING','READY','IN_PROGRESS','VERIFYING','BLOCKED','HUMAN_REVIEW'];
      const counts={total:tasks.length,active:0,completed:0,humanReview:0,failed:0,blocked:0};
      const agents={};
      for(const t of tasks){if(active.includes(t.status))counts.active++;if(t.status==='COMPLETED')counts.completed++;if(t.status==='HUMAN_REVIEW')counts.humanReview++;if(t.status==='FAILED')counts.failed++;if(t.status==='BLOCKED')counts.blocked++;const key=t.owner??'unassigned';agents[key]??={total:0,active:0,completed:0,failed:0};agents[key].total++;if(active.includes(t.status))agents[key].active++;if(t.status==='COMPLETED')agents[key].completed++;if(['FAILED','HUMAN_REVIEW'].includes(t.status))agents[key].failed++;}
      const since=new Date(Date.now()-7*24*3600000).toISOString();
      return send(res,200,JSON.stringify({tasks:counts,agents,ai:usage.summary({since}),generatedAt:new Date().toISOString()}));
    }
    if(url.pathname==='/'||url.pathname==='/index.html'){
      try{return send(res,200,fs.readFileSync(path.join(webRoot,'index.html'),'utf8'),'text/html; charset=utf-8');}catch{return send(res,500,'dashboard_missing','text/plain; charset=utf-8');}
    }
    return send(res,404,JSON.stringify({error:'not_found'}));
  });
  return {
    server,host,port,
    start:()=>new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,host,()=>{logger.log?.('dashboard_started',{host,port});resolve({host,port,url:`http://${host}:${port}/`});});}),
    stop:()=>new Promise(resolve=>server.close(()=>resolve()))
  };
}
