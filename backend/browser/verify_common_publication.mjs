import {createRequire} from 'node:module';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,dirname,basename} from 'node:path';
import {createServer} from 'node:http';
import assert from 'node:assert/strict';
const repo=fileURLToPath(new URL('../../',import.meta.url)).replace(/\/$/,'');
const require=createRequire(repo+'/backend/package.json');
const {chromium}=require(process.env.ARI_PLAYWRIGHT_PATH||'playwright');
const base=dirname(repo)+'/',out=process.env.ARI_BROWSER_OUTPUT||'/tmp/ari-content-release-20261101/';
const results=[];let browser=await chromium.launch({headless:true});
for(const name of [basename(repo)]){
 let server,accounts,audit,repository,store,handler,publicationRepository,publications;const errors=[];
 const load=rel=>import(pathToFileURL(base+name+'/'+rel));
 try{
  let owner;
  const {createContentRelease}=await load('backend/src/content_release_core.js');
  const {createPublicationRepository}=await load('backend/src/content_release_repository.js');
  publicationRepository=createPublicationRepository();
  const project=name==='SORUA'?'sorua':name;
  const artifact={project,reference:'synthetic-browser-content',kind:'original_creative',payload:{item:{id:'synthetic-browser-content',title:'TEST_DATA_ONLY',body:'Synthetic <script>window.pwned=true</script> content only'}}};
  const flow=createContentRelease({project,repository:publicationRepository,resolve:id=>id===artifact.reference?artifact:null,list:()=>[{reference:artifact.reference}]});
  publications={...flow,catalog:()=>({verses:[],items:[]}),publicItems:()=>[],publicManifest:()=>flow.manifest()};
  const writer={actor:'synthetic-writer',role:'editor'},checker={actor:'synthetic-reviewer',role:'reviewer'};
  flow.dispatch({method:'POST',path:'/publications',actor:writer,body:{reference:artifact.reference}});
  const detail=flow.dispatch({method:'GET',path:'/publications/'+artifact.reference,actor:checker});
  flow.dispatch({method:'POST',path:'/publications/'+artifact.reference+'/rights',actor:checker,body:{version:1,contentHash:detail.contentHash,evidence:'synthetic-rights-fixture'}});
  flow.dispatch({method:'POST',path:'/publications/'+artifact.reference+'/review',actor:checker,body:{version:2,contentHash:detail.contentHash,evidence:'synthetic-review-fixture',checks:Object.fromEntries(detail.checks.map(k=>[k,true]))}});

  if(name!=='catholic'){
   const {createApp}=await load('backend/src/app.js'),{createAdminAccounts}=await load('backend/src/admin_accounts.js'),
    {createAuditLog}=await load('backend/src/audit_log.js'),{createAdminRepository}=await load('backend/src/common_admin_repository.js');
   accounts=createAdminAccounts();audit=createAuditLog();repository=createAdminRepository();
   const app=createApp({generate:Object.assign(async()=>({}),{mode:'local'}),adminToken:'synthetic-browser-owner',adminAccounts:accounts,audit,adminRepository:repository,contentReleaseService:publications,
    memberStore:{getAdminOverview:()=>({total:3,recent:[]})}});
   server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
  }else{
   const {createStore,POLICY}=await load('backend/src/service/store.js'),{createContentLibrary}=await load('backend/src/service/content.js'),
    {createAssistant}=await load('backend/src/service/assistant.js'),{createServiceHandler}=await load('backend/src/service/api.js');
   store=createStore();const library=createContentLibrary({repository:store.contentRepository()}),assistant=createAssistant({store,library});
   const session=store.loginVerified({provider:'google',subject:'synthetic-browser-owner'},{version:POLICY.version,account:true,storage:false,ai:false});
   store.grantRole(session.accountId,'owner');const proof=store.confirmReauth(session.token,session.csrf,{provider:'google',subject:'synthetic-browser-owner'}).proof;
   owner=store.adminLogin(session.token,session.csrf,proof);
   server=createServer(async(req,res)=>{
    if(req.url.startsWith('/api/'))return handler(req,res);
    if(req.url==='/common-admin.mjs'){res.writeHead(200,{'Content-Type':'text/javascript'});return res.end(await readFile(base+name+'/admin/common-admin.mjs'));}
    res.writeHead(200,{'Content-Type':'text/html'});res.end('<!doctype html><html lang="ko"><meta name="viewport" content="width=device-width,initial-scale=1"><main id="common"></main></html>');
   });await new Promise(r=>server.listen(0,'127.0.0.1',r));
   handler=createServiceHandler({enabled:true,syntheticLocalOnly:true,adminEnabled:true,requireElevatedAdmin:true,
    trustedOrigin:'http://127.0.0.1:'+server.address().port,store,library,assistant,contentReleaseService:publications,verifyToken:async()=>{throw Error('unused');}});
  }
  const origin='http://127.0.0.1:'+server.address().port,context=await browser.newContext({viewport:{width:390,height:844}}),page=await context.newPage();
  page.on('pageerror',e=>errors.push(e.message));await page.route('**/*',route=>new URL(route.request().url()).origin===origin?route.continue():route.abort());
  await page.goto(origin+(name==='catholic'?'/':'/admin/common'));
  if(name!=='catholic'){
   await page.getByLabel('비밀번호 또는 소유자 인증키').fill('synthetic-browser-owner');await page.getByRole('button',{name:'로그인',exact:true}).click();
  }else{
   await page.evaluate(async owner=>{
    const {mountCommonAdmin}=await import('/common-admin.mjs');
    mountCommonAdmin(document.querySelector('#common'),{async request(path,{method='GET',body,signal}={}){
     const response=await fetch(path,{method,signal,headers:{Origin:location.origin,Authorization:'Bearer '+owner.token,'X-CSRF-Token':owner.csrf,...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});
     if(!response.ok)throw Error('request_failed');return response.json();
    }},{prefix:'/api/v1/admin/common'});
   },owner);
  }
  await page.getByRole('button',{name:'공통 관리 열기',exact:true}).click();
  await page.getByRole('button',{name:'삭제·철회 요청',exact:true}).waitFor();
  await page.getByRole('button',{name:'콘텐츠 승인·게시',exact:true}).click();
  await page.getByRole('button',{name:'본문·승인 단계 확인',exact:true}).click();
  await page.getByText('synthetic-browser-content · reviewed · 공개 상태: reviewed',{exact:true}).waitFor();
  assert.equal(await page.evaluate(()=>window.pwned),undefined);
  page.once('dialog',dialog=>dialog.accept());await page.getByRole('button',{name:'독립 최종 승인',exact:true}).click();
  await page.getByText('synthetic-browser-content · approved · 공개 상태: approved',{exact:true}).waitFor();
  page.once('dialog',dialog=>dialog.accept());await page.getByRole('button',{name:'게시',exact:true}).click();
  await page.getByText('synthetic-browser-content · published · 공개 상태: published',{exact:true}).waitFor();
  assert.equal(flow.allows(artifact.reference),true);
  page.once('dialog',dialog=>dialog.accept());await page.getByRole('button',{name:'게시 철회·새 조회 차단',exact:true}).click();
  await page.getByText('synthetic-browser-content · revoked · 공개 상태: revoked',{exact:true}).waitFor();
  assert.equal(flow.allows(artifact.reference),false);
  await page.getByRole('button',{name:'삭제·철회 요청',exact:true}).click();
  await page.getByLabel('내부 접수·콘텐츠 참조번호').fill('synthetic-case-001');await page.getByRole('button',{name:'등록',exact:true}).click();
  await page.getByRole('button',{name:'삭제·철회 요청',exact:true}).click();await page.getByRole('heading',{name:'synthetic-case-001',exact:true}).waitFor();
  await page.getByRole('button',{name:'문의 처리',exact:true}).click();await page.getByLabel('내부 접수·콘텐츠 참조번호').fill('synthetic-inquiry-001');await page.getByRole('button',{name:'등록',exact:true}).click();
  await page.getByRole('button',{name:'문의 처리',exact:true}).click();await page.getByLabel('담당자 내부 ID').fill('synthetic-staff-001');await page.getByRole('button',{name:'담당자 배정',exact:true}).click();
  await page.getByRole('button',{name:'문의 처리',exact:true}).click();await page.getByText('상태: assigned · 버전: 2',{exact:true}).waitFor();
  page.once('dialog',dialog=>dialog.accept());await page.getByRole('button',{name:'문의 처리 완료',exact:true}).click();
  await page.getByRole('button',{name:'문의 처리',exact:true}).click();await page.getByText('상태: resolved · 버전: 3',{exact:true}).waitFor();
  await page.getByRole('button',{name:'백업·복구 확인',exact:true}).click();await page.getByText('복구 확인: 미확인',{exact:true}).waitFor();
  await page.getByRole('button',{name:'감사 기록',exact:true}).click();await page.getByRole('heading',{name:'문의 처리 완료',exact:true}).waitFor();
  await page.screenshot({path:out+name+'-publication-admin-mobile.png',fullPage:true});
  await page.setViewportSize({width:1280,height:900});
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
  assert.deepEqual(errors,[]);results.push({project:name,result:'PASS',flows:['independent-final-approval','publish','revoke','safe-source-render','login-or-elevated-session','request-create','inquiry-assign-resolve','unverified-backup','audit','mobile-desktop'],pageErrors:errors});
  await context.close();
 }catch(error){results.push({project:name,result:'FAIL',error:error.message,pageErrors:errors});}
 finally{handler?.close();if(server)await new Promise(r=>server.close(r));accounts?.close();audit?.close();repository?.close();publicationRepository?.close();store?.close();}
 await writeFile(out+name+'-publication-browser-results.json',JSON.stringify(results,null,2));console.log(results.at(-1));
}
await browser.close();
if(results.some(r=>r.result!=='PASS'))process.exitCode=1;
