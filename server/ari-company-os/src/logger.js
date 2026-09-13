import fs from 'node:fs';
import path from 'node:path';
export function rotatingLogger(dir,maxBytes=5*1024*1024) {
 fs.mkdirSync(dir,{recursive:true});
 const write=(name,args)=>{
  const file=path.join(dir,name);
  if(fs.existsSync(file)&&fs.statSync(file).size>=maxBytes)fs.renameSync(file,file+'.1');
  fs.appendFileSync(file,JSON.stringify({at:new Date().toISOString(),event:args})+'\n',{mode:0o600});
 };
 return {log:(...args)=>write('manager.log',args),error:(...args)=>write('manager.err.log',args)};
}
