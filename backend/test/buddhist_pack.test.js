import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile, readdir } from 'node:fs/promises';
import { createCore } from '../dev/religion-packs/core.js';
import { createChristianPack } from '../dev/religion-packs/christian.js';
import { createLocalConversationService } from '../src/local_conversation_service.js';
import { createBuddhistPack } from '../dev/religion-packs/buddhist/pack.js';
import { BuddhistScriptureProvider } from '../dev/religion-packs/buddhist/provider.js';
import { validateBuddhistResponse, NO_SOURCE } from '../dev/religion-packs/buddhist/agent.js';
import { createReligionRouter } from '../dev/religion-packs/router.js';
import { assessRequestCrisis, crisisResponse } from '../src/crisis.js';

const provider = new BuddhistScriptureProvider();
const request = (userMessage, religion = 'buddhist') => ({ userMessage, religion,
  session: { selectedEmotion: '불안', turnCount: 1 }, allowedVerseIds: [] });
const cases = JSON.parse(await readFile(new URL('../../backend_contract/safety_cases.json', import.meta.url)));

test('Buddhist provider: closed TEST_DATA_ONLY corpus, no external intake or production mode', () => {
  assert.throws(() => new BuddhistScriptureProvider({ mode: 'production' }));
  assert.throws(() => new BuddhistScriptureProvider({ environment: 'production' }));
  const results = provider.search('테스트');
  assert.equal(results.length, 2);
  for (const citation of results) {
    assert.equal(citation.copyright_status, 'TEST_DATA_ONLY');
    assert.match(citation.text, /^\[TEST_DATA_ONLY\]/);
    assert.equal(citation.translator, null);
    assert.equal(citation.chapter, null);
    assert.equal(citation.verse, null);
    assert.ok(Object.isFrozen(citation));
  }
  const blocked = provider.status().externalReview;
  assert.equal(blocked.copyright_status, 'BLOCKED_EXTERNAL_REVIEW');
  assert.equal('text' in blocked, false);
  assert.equal(provider.get(blocked.id), null);
  assert.deepEqual(provider.search(blocked.id), []);
  assert.throws(() => provider.mindCard(blocked.id));
  assert.throws(() => provider.assertCitation({ ...results[0], copyright_status: 'BLOCKED_EXTERNAL_REVIEW' }));
});

test('Agent rejects invented titles, chapter/verse, translators, sources, text, and hidden prose', async () => {
  const response = await createBuddhistPack().respond(request('불안'));
  for (const field of ['id', 'title', 'chapter', 'verse', 'translator', 'source', 'text', 'religion']) {
    const citations = [{ ...response.citations[0], [field]: 'invented-value' }];
    assert.throws(() => validateBuddhistResponse({ ...response, citations }, provider), /UNSUPPORTED_SCRIPTURE/, field);
  }
  assert.throws(() => validateBuddhistResponse({ ...response, message: '지어낸 인용문' }, provider));
  assert.throws(() => validateBuddhistResponse({ ...response, extra: '지어낸 경전 설명' }, provider));
  assert.throws(() => provider.assertCitation({ ...response.citations[0], unreviewedTranslation: 'not admitted' }));
});

test('No hits means no generated scripture, citations, title or translator; no-hit card fails', async () => {
  const result = await createBuddhistPack().respond(request('존재하지않는자료'));
  assert.equal(result.message, NO_SOURCE);
  assert.deepEqual(result.citations, []);
  assert.throws(() => provider.mindCard('missing'), /UNSUPPORTED_SCRIPTURE/);
  assert.deepEqual(provider.search(''), []);
});

test('Mind cards contain only canonical provider records and keep the mock label', () => {
  const card = provider.mindCard('test-buddhist-calm');
  assert.equal(card.scripture, provider.get('test-buddhist-calm'));
  assert.match(card.label, /TEST_DATA_ONLY/);
  assert.throws(() => provider.mindCard('christian-verse'));
});

test('Core: entire safety/false-positive corpus preserves fixed response and bypasses downstream', async () => {
  for (const fixture of cases) {
    let psychologyCalls = 0, religionCalls = 0;
    const core = createCore({
      psychology: () => { psychologyCalls++; },
      pack: { id: 'buddhist', respond: () => { religionCalls++; return { stage: 'reflection' }; } },
    });
    const body = request(fixture.text);
    const result = await core.respond(body);
    if (fixture.level > 0) {
      assert.deepEqual(result, crisisResponse('마음', assessRequestCrisis(body)), fixture.id);
      assert.equal(psychologyCalls, 0, fixture.id);
      assert.equal(religionCalls, 0, fixture.id);
    } else {
      assert.equal(result.stage, 'reflection', fixture.id);
      assert.equal(psychologyCalls, 1, fixture.id);
      assert.equal(religionCalls, 1, fixture.id);
    }
  }
});

test('Core: custom emotion and prior risk cannot be downgraded or bypassed by a mismatched pack', async () => {
  const core = createCore({ pack: { id: 'buddhist', respond: () => assert.fail('religion') }, psychology: () => assert.fail('psychology') });
  for (const session of [{ riskLevel: 2 }, { currentStage: 'crisis' }, { customEmotion: '죽고 싶어요' }]) {
    assert.equal((await core.respond({ ...request('괜찮아요', 'christian'), session })).stage, 'crisis');
  }
});

test('Fixed build routing: cross-religion requests fail; Buddhist responses do not echo Christian prompts', async () => {
  const buddhist = createReligionRouter(createBuddhistPack());
  const christian = createReligionRouter(createChristianPack());
  await assert.rejects(buddhist.respond(request('불안', 'christian')), /PACK_MISMATCH/);
  await assert.rejects(christian.respond(request('불안', 'buddhist')), /PACK_MISMATCH/);
  const result = await buddhist.respond(request('예수 성경 하나님 기도 요한복음 불안'));
  assert.doesNotMatch(JSON.stringify(result), /예수|성경|하나님|기도|요한복음/);
});

test('Christian Pack adapter preserves existing local response at every stage without Buddhist fixtures', async () => {
  const baseline = createLocalConversationService();
  const core = createReligionRouter(createChristianPack());
  for (const turnCount of [0, 1, 2, 3, 5, 6]) {
    const body = request('내일 발표가 걱정돼요', 'christian');
    body.session.turnCount = turnCount;
    body.allowedVerseIds = ['synthetic-christian-id'];
    const actual = await core.respond(body);
    assert.deepEqual(actual, await baseline(body, { id: 'integrated' }));
    assert.doesNotMatch(JSON.stringify(actual), /TEST_DATA_ONLY|buddhist|불교|부처/);
  }
});

test('Development runtime has no production data/model/network clients and is excluded from production packaging', async () => {
  const root = new URL('../dev/religion-packs/', import.meta.url);
  async function scan(directory) {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      if (entry.name === 'e2e') continue;
      const url = new URL(entry.name + (entry.isDirectory() ? '/' : ''), directory);
      if (entry.isDirectory()) await scan(url);
      else if (/\.js$/.test(entry.name) && !url.pathname.includes('/public/')) {
        const text = await readFile(url, 'utf8');
        assert.doesNotMatch(text, /from ['"](?:openai|dotenv|better-sqlite3)|\bfetch\s*\(|member_store|bible_verses|https:\/\//, url.pathname);
      }
    }
  }
  await scan(root);
  const packageScript = await readFile(new URL('../../scripts/package-backend.mjs', import.meta.url), 'utf8');
  const paths = packageScript.match(/const paths = (\[[\s\S]*?\]);/)[1];
  assert.doesNotMatch(paths, /backend\/dev|backend['"]/);
  for (const name of ['app.js', 'server.js']) {
    assert.doesNotMatch(await readFile(new URL(`../src/${name}`, import.meta.url), 'utf8'), /dev\/religion-packs/);
  }
});
