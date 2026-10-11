import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const folderPattern=/^(?:deploy|social-identity(?:-build20)?|web-starlight|support-url|web-parity)-(\d{8})-(\d{6})(?:-[A-Za-z0-9]+)?$/;
export function pruneLegacyBackups({root='/opt/onaria-backups',now=new Date(),apply=false}={}) {
 root=fs.realpathSync(root);
 if(path.basename(root)!=='onaria-backups'||root===path.parse(root).root)throw new Error('ONARIA backup root required');
 const cutoff=now.getTime()-14*86400000;
 if(!Number.isFinite(cutoff))throw new TypeError('Invalid time');
 const eligible=[];let scanned=0;
 for(const entry of fs.readdirSync(root,{withFileTypes:true})){
  if(entry.name==='.deploy.lock'&&entry.isFile())continue;
  const match=folderPattern.exec(entry.name);
  if(!match||!entry.isDirectory()||entry.isSymbolicLink())throw new Error('Unmanaged legacy backup');
  scanned++;
  const [_,date,time]=match;
  const stamp=Date.parse(date.slice(0,4)+'-'+date.slice(4,6)+'-'+date.slice(6,8)+'T'+time.slice(0,2)+':'+time.slice(2,4)+':'+time.slice(4,6)+'.000Z');
  if(!Number.isFinite(stamp))throw new Error('Invalid legacy timestamp');
  const folder=path.join(root,entry.name);
  // Names alone cannot force early deletion of a newer rollback directory.
  if(Math.max(stamp,fs.statSync(folder).mtimeMs)<=cutoff)eligible.push(folder);
 }
 if(apply)for(const folder of eligible){
  if(fs.lstatSync(folder).isSymbolicLink())throw new Error('Unsafe legacy backup');
  // fs.rm unlinks contained symlinks; it does not follow their targets.
  fs.rmSync(folder,{recursive:true});
 }
 return {version:'1.0.0-retention.1',retentionDays:14,scanned,candidates:eligible.length,removed:apply?eligible.length:0};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{console.log(JSON.stringify(pruneLegacyBackups({apply:process.argv.includes('--apply')})));}
 catch{console.error('ONARIA legacy backup retention failed.');process.exitCode=1;}
}
