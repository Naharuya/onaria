const labels={requests:'삭제·철회 요청',inquiries:'문의 처리',reviews:'검수 기록',publications:'콘텐츠 승인·게시',members:'회원 집계',audit:'감사 기록',backup:'백업·복구 확인'};
const checkLabels={source:'원문·출전 확인',rights:'사용권 근거 확인',translation:'원문·번역·자체 해설 구분',safety:'안전·차별·강요 검토',
 biblicalContext:'성경 장절과 문맥',translationEdition:'번역본·판본',denominationalDistinction:'교단별 해석 구분',
 canonicalLocator:'경전·장절 확인',traditionDistinction:'종파·전통 구분',originalTranslationSeparation:'원문·번역 초안 구분',
 catholicCanon:'가톨릭 정경·출전',approvedEditionDisclosure:'인준·번역본 상태 고지',doctrinalScopeRestriction:'허용된 교리 범위',
 authorWorkLocator:'저자·작품·장절',quotationAuthenticity:'실제 원전과 인용 일치',pluralPerspectives:'복수 철학 관점 존중'};
const el=(tag,text)=>{const node=document.createElement(tag);if(text!==undefined)node.textContent=text;return node;};
export function mountCommonAdmin(root,api,{prefix='/v1/admin/common'}={}){
 let generation=0,busy=false,controller,alive=true;
 const status=el('p','인증 후 공통 관리 항목을 확인할 수 있습니다.');status.setAttribute('role','status');
 const button=el('button','공통 관리 열기'),content=el('div');root.replaceChildren(el('h2','공통 관리'),status,button,content);
 const clear=()=>{generation++;controller?.abort();content.replaceChildren();busy=false;button.disabled=false;};
 const visibility=()=>{if(document.visibilityState==='hidden'){clear();status.textContent='화면이 비활성화되어 표시 정보를 지웠습니다.';}};
 document.addEventListener('visibilitychange',visibility);
 async function run(action){
  if(busy||!alive||!root.isConnected||document.visibilityState==='hidden')return;
  const version=++generation;busy=true;controller=new AbortController();
  root.querySelectorAll('button').forEach(b=>b.disabled=true);
  const request=(path,options={})=>api.request(prefix+path,{...options,signal:controller.signal});
  try{await action(request,()=>alive&&version===generation);if(version===generation)status.textContent='조회·처리 결과를 확인했습니다.';}
  catch{if(version===generation){content.replaceChildren();status.textContent='권한·연결·처리 상태를 확인하세요. 완료 여부가 확인되지 않은 요청은 다시 조회하세요.';}}
  finally{if(version===generation){busy=false;root.querySelectorAll('button').forEach(b=>b.disabled=false);}}
 }
 const actionButton=(name,fn)=>{const b=el('button',name);b.disabled=busy;b.type='button';b.addEventListener('click',()=>run(fn));return b;};
 function field(form,name,type='text'){
  const label=el('label',name),input=el('input');input.type=type;input.required=true;input.maxLength=96;label.append(input);form.append(label);return input;
 }
 function select(form,name,options){
  const label=el('label',name),input=el('select');
  for(const [value,text]of options){const o=el('option',text);o.value=value;input.append(o);}label.append(input);form.append(label);return input;
 }

 async function publicationDetail(reference,request,valid,panel,standard){
  const d=await request('/publications/'+reference);if(!valid())return;
  const lifecycle=d.publication?.state??'unregistered';
  panel.replaceChildren(el('h3','콘텐츠 승인·게시'),el('p',reference+' · '+lifecycle+' · 공개 상태: '+d.state));
  panel.append(el('p','본문이나 출처가 바뀌면 다시 검수해야 합니다. 기존 배포본 표시는 새 검수·전문가 승인 완료를 뜻하지 않습니다.'));
  const source=el('pre',JSON.stringify(d.artifact.payload,null,2));source.style.whiteSpace='pre-wrap';source.style.overflowWrap='anywhere';panel.append(source);
  const identity=el('p','버전 '+d.version+' · SHA-256 '+d.contentHash);identity.style.overflowWrap='anywhere';panel.append(identity);
  if(['owner','admin','editor'].includes(standard.role))panel.append(actionButton('이 버전을 초안으로 등록',async(r,v)=>{
   await r('/publications',{method:'POST',body:{reference}});if(v())await publicationDetail(reference,r,v,panel,standard);
  }));
  const actions={draft:'rights',rights_checked:'review',reviewed:'approve',approved:'publish'};
  const action=actions[lifecycle];
  const names={rights:'권리 근거 확인',review:'독립 검수 기록',approve:'독립 최종 승인',publish:'게시'};
  if(action){
   const form=el('form');
   const evidence=['rights','review'].includes(action)?field(form,action==='rights'?'권리 근거 HTTPS URL 또는 내부 참조번호':'검수 근거 참조번호'):null;
   if(evidence)evidence.maxLength=512;
   const boxes={};if(action==='review')for(const key of d.checks){const label=el('label',checkLabels[key]??key),box=el('input');box.type='checkbox';box.required=true;boxes[key]=box;label.prepend(box);form.append(label);}
   const submit=el('button',names[action]);submit.type='submit';submit.disabled=busy;form.append(submit);
   form.addEventListener('submit',event=>{event.preventDefault();run(async(r,v)=>{
    if(['approve','publish'].includes(action)&&!window.confirm(names[action]+' 처리할 본문과 버전을 확인했나요?'))return;
    const body={version:d.version,contentHash:d.contentHash};if(evidence)body.evidence=evidence.value;
    if(action==='review')body.checks=Object.fromEntries(Object.entries(boxes).map(([k,b])=>[k,b.checked]));
    await r('/publications/'+reference+'/'+action,{method:'POST',body});if(v())await publicationDetail(reference,r,v,panel,standard);
   });});panel.append(form);
  }
  if(lifecycle!=='revoked'&&['owner','admin'].includes(standard.role))panel.append(actionButton('게시 철회·새 조회 차단',async(r,v)=>{
   if(!window.confirm('이 콘텐츠의 새 배포를 차단할까요? 오프라인 기기는 승인된 캐시 기한과 재접속 시점에 따라 반영됩니다.'))return;
   await r('/publications/'+reference+'/revoke',{method:'POST',body:{version:d.version,contentHash:d.contentHash}});if(v())await publicationDetail(reference,r,v,panel,standard);
  }));
 }
 async function open(request,current){
  const standard=await request('/standard');if(!current())return;
  content.replaceChildren(el('p',standard.project+' · 현재 역할: '+standard.role));
  content.append(el('p','개인 대화·연락처를 입력하지 마세요. 문의 원문은 기존 접수 경로에서 확인하고 여기에는 내부 접수 참조번호만 등록합니다. 삭제 요청 등록·승인은 실제 삭제 완료를 뜻하지 않습니다.'));
  const tabs=el('nav'),panel=el('section');tabs.setAttribute('aria-label','공통 관리 메뉴');content.append(tabs,panel);
  const permissions={requests:'requests',inquiries:'inquiries',reviews:'content',publications:'content',members:'members',audit:'audit',backup:'backup'};
  if(standard.permissions.includes('accounts')){labels.accounts='관리자 계정·권한';permissions.accounts='accounts';}
  for(const name of Object.keys(labels))if(standard.permissions.includes(permissions[name])){
   tabs.append(actionButton(labels[name],async(req,valid)=>{
    panel.replaceChildren(el('p','불러오는 중입니다.'));
    const result=await req('/'+name);if(!valid())return;
    panel.replaceChildren(el('h3',labels[name]));
    if(name==='publications'){
      panel.append(el('p','권리 확인 → 독립 검수 → 독립 최종 승인 → 게시 → 철회. 작성자·검수자·최종 승인자 분리를 서버에서 확인합니다. 앱별 기존 권리·전통 검수 Gate도 유지합니다.'));
      for(const row of result.items){const box=el('article');box.append(el('h4',row.title),el('p',row.reference+' · '+row.kind+' · '+row.state),actionButton('본문·승인 단계 확인',async(r,v)=>publicationDetail(row.reference,r,v,panel,standard)));panel.append(box);}
      return;
    }
    if(name==='accounts'){
      const providerMode=standard.accountManagement==='provider';
      const form=el('form'),username=field(form,providerMode?'기존 회원 내부 ID':'새 관리자 ID'),password=providerMode?null:field(form,'새 관리자 비밀번호','password');
      if(password){password.maxLength=200;password.minLength=12;}
      const role=select(form,'역할',standard.roles.map(r=>[r,r])),submit=el('button','관리자 등록');submit.type='submit';submit.disabled=busy;form.append(submit);
      form.addEventListener('submit',event=>{event.preventDefault();run(async(r,v)=>{
        await r('/accounts',{method:'POST',body:providerMode?{accountId:username.value,role:role.value}:{username:username.value,password:password.value,role:role.value}});if(password)password.value='';if(v())await open(r,v);
      });});panel.append(form);
      for(const row of result.accounts){
        const box=el('article');box.append(el('h4',row.username),el('p',row.role+(row.disabled?' · 중지':' · 활성')));
        const pick=select(box,'변경할 역할',standard.roles.map(r=>[r,r]));pick.value=row.role;
        box.append(actionButton(row.disabled?'활성화·역할 적용':'중지·역할 적용',async(r,v)=>{
          if(!window.confirm('관리자 권한을 변경할까요?'))return;
          await r('/accounts/'+row.id,{method:'POST',body:{role:pick.value,disabled:!row.disabled}});if(v())await open(r,v);
        }));panel.append(box);
      }return;
    }
    if(!result.items){
      if(name==='members')panel.append(el('p','등록 회원: '+result.total+'명'));
      else if(name==='backup'){
        const states={PASS:'확인됨',FAIL:'실패',UNVERIFIED:'미확인'};
        for(const[key,title]of [['backup','백업 확인'],['restore','복구 확인'],['deletionProtection','삭제 후 복구 차단']])panel.append(el('p',title+': '+(states[result[key]]??'미확인')));
        if(!result.configured)panel.append(el('p','이 환경에는 실제 백업 증거 확인기가 연결되지 않았습니다.'));
        if(result.checkedAt)panel.append(el('p','확인 시각: '+new Date(result.checkedAt).toLocaleString()));
        if(result.environment)panel.append(el('p','확인 환경: '+({synthetic:'합성 시험',candidate:'출시 후보',production:'운영',unknown:'미확인'}[result.environment]??'미확인')));
      }else if(name==='audit'){
        panel.append(el('p',result.valid?'감사 기록 연결이 정상입니다.':'감사 기록이 일치하지 않습니다. 관리자 변경 작업을 중단하고 확인하세요.'));
        const names={'request.received':'삭제·철회 요청 접수','request.verify':'본인확인 경로 안내','request.approve':'처리 승인','request.processing':'처리 시작','request.complete':'완료 증빙 확인','request.reject':'요청 반려','inquiry.received':'문의 접수','inquiry.assign':'문의 담당자 배정','inquiry.resolve':'문의 처리 완료','inquiry.reopen':'문의 다시 열기','content.review.open':'콘텐츠 검수 등록','content.review.inspect':'독립 콘텐츠 검수'};
        for(const row of result.events){const item=el('article');item.append(el('h4',names[row.action]??'관리자 요청 거부·확인'),el('p',new Date(row.at).toLocaleString()),el('p','담당자: '+row.actor+' · 역할: '+row.role),el('p','처리 참조: '+row.target));panel.append(item);}
      }return;
    }
    const refresh=async()=>{await open(req,valid);};
    if(['requests','inquiries','reviews'].includes(name)){
     const form=el('form'),reference=field(form,'내부 접수·콘텐츠 참조번호');
     let kind,revision;
     if(name==='requests')kind=select(form,'요청 범위',[['account_deletion','회원탈퇴'],['server_records','서버 기록'],['consent_withdrawal','동의 철회']]);
     if(name==='inquiries')kind=select(form,'문의 분류',[['general','일반'],['privacy','개인정보'],['technical','기술'],['content','콘텐츠']]);
     if(name==='reviews')revision=field(form,'콘텐츠 버전 참조번호');
     const submit=el('button','등록');submit.type='submit';submit.disabled=busy;form.append(submit);
     form.addEventListener('submit',event=>{event.preventDefault();run(async(r,v)=>{
      await r('/'+name,{method:'POST',body:{reference:reference.value,...(name==='requests'?{kind:kind.value}:name==='inquiries'?{category:kind.value}:{revision:revision.value})}});
      if(v())await open(r,v);
     });});panel.append(form);
    }
    for(const row of result.items){
     const item=el('article');item.append(el('h4',row.reference),el('p','상태: '+row.state+' · 버전: '+row.version));
     const command=(suffix,title,body={version:row.version})=>item.append(actionButton(title,async(r,v)=>{
      if(!window.confirm(title+' 작업을 진행할까요?'))return;
      await r('/'+name+'/'+row.id+'/'+suffix,{method:'POST',body});if(v())await open(r,v);
     }));
     if(name==='requests'){
      if(row.state==='received')command('verify','본인확인 경로 안내');
      if(row.state==='identity_pending'&&standard.permissions.includes('approve'))command('approve','독립 담당자 처리 승인');
      if(row.state==='approved')command('processing','처리 중으로 변경');
      if(row.state==='processing'){
       const f=el('div'),receipt=field(f,'서버 발급 완료 증빙 참조번호');item.append(f);
       item.append(actionButton('완료 증빙 확인',async(r,v)=>{
        await r('/requests/'+row.id+'/complete',{method:'POST',body:{version:row.version,receipt:receipt.value}});if(v())await open(r,v);
       }));
      }
      if(!['completed','rejected'].includes(row.state))command('reject','요청 반려');
     }else if(name==='inquiries'){
      if(row.state==='received'||row.state==='assigned'){
       const f=el('div'),assignee=field(f,'담당자 내부 ID');item.append(f);
       item.append(actionButton('담당자 배정',async(r,v)=>{
        await r('/inquiries/'+row.id+'/assign',{method:'POST',body:{version:row.version,assignee:assignee.value}});if(v())await open(r,v);
       }));
      }
      if(row.state==='assigned')command('resolve','문의 처리 완료');
      if(row.state==='resolved')command('reopen','문의 다시 열기');
     }else if(row.state==='pending'&&standard.permissions.includes('review')){
      const form=el('form'),checks={};
      for(const key of standard.checks){const label=el('label',checkLabels[key]??key),box=el('input');box.type='checkbox';box.required=true;label.prepend(box);form.append(label);checks[key]=box;}
      const evidence=field(form,'검수 근거 문서 참조번호'),submit=el('button','독립 검수 기록');submit.type='submit';submit.disabled=busy;form.append(submit);
      form.addEventListener('submit',event=>{event.preventDefault();run(async(r,v)=>{
       await r('/reviews/'+row.id+'/inspect',{method:'POST',body:{version:row.version,evidence:evidence.value,checks:Object.fromEntries(Object.entries(checks).map(([k,b])=>[k,b.checked]))}});
       if(v())await open(r,v);
      });});item.append(form);
     }
     panel.append(item);
    }
   }));
  }
 }
 button.addEventListener('click',()=>run(open));
 return {dispose(){alive=false;clear();document.removeEventListener('visibilitychange',visibility);root.replaceChildren();}};
}
if(typeof document!=='undefined'){
 const root=document.querySelector('[data-common-admin]');
 if(root){
  let csrf=null,view;
  const form=document.querySelector('#common-login'),message=document.querySelector('#common-message');
  const api={async request(path,{method='GET',body,signal}={}){
   const pending=new AbortController(),timer=setTimeout(()=>pending.abort(),5000),cancel=()=>pending.abort();
   signal?.addEventListener('abort',cancel,{once:true});if(signal?.aborted)cancel();
   try{
    const response=await fetch(path,{method,signal:pending.signal,credentials:'same-origin',cache:'no-store',redirect:'error',
     headers:{...(body?{'Content-Type':'application/json'}:{}),...(csrf?{'X-CSRF-Token':csrf}:{})},...(body?{body:JSON.stringify(body)}:{})});
    if(!response.ok||response.headers.get('cache-control')!=='no-store')throw Error('request_failed');return await response.json();
   }finally{clearTimeout(timer);signal?.removeEventListener('abort',cancel);}
  }};
  form.addEventListener('submit',async event=>{
   event.preventDefault();const button=form.querySelector('button');button.disabled=true;
   const data=new FormData(form),username=data.get('username');
   try{const session=await api.request('/v1/admin/session',{method:'POST',body:username?{username,password:data.get('password')}:{token:data.get('password')}});
    view?.dispose();csrf=session.csrfToken;form.reset();form.hidden=true;message.textContent='관리자 인증을 확인했습니다.';view=mountCommonAdmin(root,api);
   }catch{message.textContent='관리자 인증을 확인하지 못했습니다.';}finally{button.disabled=false;}
  });
  document.querySelector('#common-logout').addEventListener('click',async()=>{
   view?.dispose();try{await api.request('/v1/admin/session',{method:'DELETE'});}catch{}csrf=null;form.hidden=false;root.replaceChildren();message.textContent='연결을 종료했습니다.';
  });
 }
}
