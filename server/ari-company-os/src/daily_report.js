import fs from 'node:fs';
import path from 'node:path';
import {projectFingerprint} from './project_watcher.js';
export async function dailyReport(queue,root,now=new Date()){
 const date=new Date(now.getTime()+9*3600000).toISOString().slice(0,10),tasks=queue.list();
 const today=t=>new Date(Date.parse(t.completedAt??t.createdAt)+9*3600000).toISOString().slice(0,10)===date;
 const latest=new Map();for(const t of [...tasks].sort((a,b)=>a.createdAt.localeCompare(b.createdAt)))if(t.type==='VERIFY_PROJECT')latest.set(t.project,t);
 const currentPass=new Set();for(const t of latest.values())if(t.result?.state==='SERVER_PASS'&&t.projectDir){try{if(await projectFingerprint(t.projectDir)===t.result.fingerprint)currentPass.add(t.project);}catch{}}
 const result={state:'REPORT_CREATED',date,timezone:'Asia/Seoul',todayStatus:'LOCAL_QUEUE_ONLY',completed:tasks.filter(t=>t.status==='COMPLETED'&&today(t)).map(t=>t.id),running:tasks.filter(t=>['IN_PROGRESS','VERIFYING'].includes(t.status)).map(t=>t.id),repairs:tasks.filter(t=>t.type==='REPAIR'&&today(t)).map(t=>({id:t.id,status:t.status})),tests:[...latest.values()].map(t=>({id:t.id,project:t.project,result:t.result?.state==='SERVER_PASS'&&!currentPass.has(t.project)?'UNVERIFIED_STALE':t.result?.state??t.report?.state??'UNVERIFIED'})),serverPassProjects:[...currentPass],risks:tasks.filter(t=>['FAILED','HUMAN_REVIEW'].includes(t.status)).map(t=>({id:t.id,reason:t.reason??t.result?.reason??'UNVERIFIED'})),costAnomalies:'UNVERIFIED',grantDates:'UNVERIFIED',nextAutomaticTasks:tasks.filter(t=>['READY','PENDING'].includes(t.status)).map(t=>t.id),ownerDecisions:tasks.filter(t=>t.status==='HUMAN_REVIEW').map(t=>t.id)};
 const dir=path.join(root,'reports','daily');fs.mkdirSync(dir,{recursive:true});const file=path.join(dir,date+'.json');fs.writeFileSync(file,JSON.stringify(result,null,2)+'\n');
 fs.writeFileSync(path.join(dir,date+'.md'),`# ARI 업무보고 ${date} KST\n\n확인 범위: 로컬 Task Queue. 미연결 외부 지표는 UNVERIFIED.\n\n`+Object.entries(result).map(([k,v])=>`- ${k}: ${JSON.stringify(v)}`).join('\n')+'\n');return {...result,path:file};
}
