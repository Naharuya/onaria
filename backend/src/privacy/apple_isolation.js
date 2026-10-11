import fs from 'node:fs';import os from 'node:os';import path from 'node:path';
// 외부 인증/네트워크 client 생성 없이 격리 저장 경로만 준비한다.
export function prepareAppleIsolation({directory,env={}}={}){
 if(Object.keys(env).length)throw new Error('외부/운영 설정 주입 금지');
 const root=fs.realpathSync(directory),temporary=fs.realpathSync(os.tmpdir());
 if(!root.startsWith(temporary+path.sep)||!path.basename(root).startsWith('onaria-apple-isolation-'))throw new Error('격리 경로 필요');
 const result={mode:'mock-only',externalRequestsAllowed:false,realAppleAllowed:false,consoleReturnUrlStatus:'BLOCKED'};
 for(const [name,file] of Object.entries({members:'members.sqlite',sessions:'sessions.sqlite',usage:'usage.sqlite',manifest:'manifest.sqlite',backups:'backups'})){
  const target=path.join(root,file);
  // 사전 존재 파일/symlink/경로를 재사용하지 않는다.
  if(fs.existsSync(target)||fs.lstatSync(root).isSymbolicLink())throw new Error('격리 대상 재사용 금지');
  result[name]=target;
 }
 fs.mkdirSync(result.backups,{mode:0o700});
 for(const name of ['members','sessions','usage','manifest'])fs.closeSync(fs.openSync(result[name],'wx',0o600));
 return Object.freeze(result);
}
export function assessIsolationCallback(callback){
 let u;try{u=new URL(callback);}catch{return 'BLOCKED';}
 if(u.hostname==='api.onaria.ai.kr')return 'REJECTED_PRODUCTION';
 // 별도 callback 등록 증거 미확보. 새 주소가 있다는 이유로 사용 가능 판정하지 않는다.
 return 'BLOCKED';
}
