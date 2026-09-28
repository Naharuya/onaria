const byId = (id) => document.getElementById(id);
let crisis = false;
async function api(path, body) {
  const response = await fetch(path, body === undefined ? {} : {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  if (!response.ok) throw Error(response.status === 409 ? '안전 지원을 먼저 확인해 주세요.' : '요청을 처리할 수 없습니다. 개발 서버 연결을 확인해 주세요.');
  return response.json();
}
function clearSources() {
  for (const id of ['citations', 'results', 'card']) byId(id).replaceChildren();
}
function renderSources(target, records) {
  target.replaceChildren();
  if (!records.length) { target.textContent = '검색된 테스트 자료가 없습니다. 경전 문구나 출처를 생성하지 않습니다.'; return; }
  for (const record of records) {
    const article = document.createElement('article');
    const title = document.createElement('h3'); title.textContent = record.title;
    const quote = document.createElement('blockquote'); quote.textContent = record.text;
    const source = document.createElement('p'); source.textContent = record.source;
    const button = document.createElement('button'); button.textContent = '테스트 마음카드 만들기';
    button.onclick = async () => {
      if (crisis) return;
      button.disabled = true;
      try {
        const card = await api('/api/cards', { scriptureId: record.id });
        if (!crisis) byId('card').textContent = `${card.label}\n${card.scripture.title}\n${card.scripture.text}\n${card.scripture.source}`;
      } catch (error) { if (!crisis) byId('card').textContent = error.message; }
      finally { button.disabled = crisis; }
    };
    article.append(title, quote, source, button); target.append(article);
  }
}
byId('conversation').onsubmit = async (event) => {
  event.preventDefault();
  const button = event.submitter; button.disabled = true;
  // Prevent stale cards remaining visible if the next turn needs crisis support.
  clearSources();
  try {
    const response = await api('/api/respond', { userMessage: byId('message').value });
    byId('answer').textContent = response.message;
    if (response.stage === 'crisis') {
      crisis = true; clearSources(); byId('answer').classList.add('crisis');
      byId('answer').textContent += `\n${response.question}`;
      byId('search').querySelectorAll('input,button').forEach((node) => { node.disabled = true; });
    } else if (!crisis) renderSources(byId('citations'), response.citations);
  } catch (error) { byId('answer').textContent = error.message; }
  finally { button.disabled = false; }
};
byId('search').onsubmit = async (event) => {
  event.preventDefault(); if (crisis) return;
  const button = event.submitter; button.disabled = true;
  try {
    const result = await api(`/api/search?q=${encodeURIComponent(byId('query').value)}`);
    if (!crisis) renderSources(byId('results'), result.results);
  } catch (error) { if (!crisis) byId('results').textContent = error.message; }
  finally { button.disabled = crisis; }
};
byId('admin-load').onclick = async () => {
  try { byId('admin').textContent = JSON.stringify(await api('/api/admin'), null, 2); }
  catch (error) { byId('admin').textContent = error.message; }
};

byId('diagnostics-load').onclick = async () => {
  try { byId('diagnostics').textContent = JSON.stringify(await api('/api/admin/diagnostics'), null, 2); }
  catch (error) { byId('diagnostics').textContent = error.message; }
};

byId('source-review-load').onclick = async () => {
  const target = byId('source-review');
  target.replaceChildren();
  try {
    const catalog = await api('/api/admin/source-review');
    const notice = document.createElement('p');
    notice.textContent = `${catalog.checked_on} 확인 · BLOCKED_EXTERNAL_REVIEW · 본문 수집/사용 비활성. 네이버·구글 직접 검색은 자동 접근 제한으로 결과 확인 불가.`;
    target.append(notice);
    for (const row of catalog.candidates) {
      const article = document.createElement('article');
      const title = document.createElement('h4'); title.textContent = row.name;
      const rights = document.createElement('p'); rights.textContent = row.rights_note;
      const evidence = document.createElement('p'); evidence.textContent = row.verification_note;
      article.append(title, rights, evidence);
      const query = encodeURIComponent(`${row.name} 저작권 이용 조건`);
      const links = [ ['공식 출처', row.source_url], ['확인 근거', row.evidence_url],
        ...(row.license_url ? [['권리 안내', row.license_url]] : []),
        ['네이버에서 직접 검색', `https://search.naver.com/search.naver?query=${query}`],
        ['구글에서 직접 검색', `https://www.google.com/search?q=${query}`] ];
      for (const [label, href] of links) {
        const line = document.createElement('p');
        const link = document.createElement('a'); link.textContent = label; link.href = href;
        link.target = '_blank'; link.rel = 'noopener noreferrer'; link.referrerPolicy = 'no-referrer';
        line.append(link); article.append(line);
      }
      target.append(article);
    }
  } catch (error) { target.textContent = error.message; }
};
