const DAY=86400000, KST=9*3600000;
function localDay(now){const d=new Date(now.getTime()+KST);return {date:d.toISOString().slice(0,10),weekday:d.getUTCDay()||7,start:Date.UTC(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate())-KST};}
export class Scheduler{
 constructor(registry,queue){this.registry=registry;this.queue=queue;}
 tick(now=new Date()){
  const day=localDay(now),created=[];
  for(const agent of this.registry.agents.filter(a=>a.enabled))for(const schedule of agent.schedule){
   if(!schedule.at)continue;
   const [h,m]=schedule.at.split(':').map(Number),due=day.start+(h*60+m)*60000;
   if(!schedule.days.includes(day.weekday)||now.getTime()<due)continue;
   const type=schedule.taskType??agent.trigger[0],key=`schedule:${agent.id}:${type}:${day.date}:${schedule.at}`;
   if(this.queue.list().some(t=>t.dedupeKey===key))continue;
   created.push(this.queue.enqueue({type,project:'company',dedupeKey:key,once:true,scheduledFor:new Date(due).toISOString(),timezone:'Asia/Seoul',trigger:'schedule',agentId:agent.id}));
  }return created;
 }
 nextDelay(now=new Date()){
  let next=now.getTime()+900000;
  for(let offset=0;offset<=7;offset++){
   const day=localDay(new Date(now.getTime()+offset*DAY));
   for(const a of this.registry.agents.filter(a=>a.enabled))for(const s of a.schedule){if(!s.at||!s.days.includes(day.weekday))continue;const [h,m]=s.at.split(':').map(Number),due=day.start+(h*60+m)*60000;if(due>now.getTime())next=Math.min(next,due);}
  }return Math.max(10,next-now.getTime());
 }
 deadlineTasks({id,deadline,registrationImpact=false},now=new Date()){
  if(registrationImpact)return [{type:'HIGH_RISK',project:'company',status:'HUMAN_REVIEW',reason:'business_registration_eligibility',dedupeKey:`grant:${id}:registration`}];
  const due=Date.parse(deadline);if(!Number.isFinite(due))throw new Error('invalid_deadline');
  return [30,14,7,3].map(days=>({type:'GRANT_DEADLINE',project:'company',goal:id,daysBefore:days,notBefore:new Date(due-days*DAY).toISOString(),dedupeKey:`grant:${id}:D-${days}`,once:true}));
 }
}
