import { test, expect } from '@playwright/test';
import { createLocalConversationService } from '../src/local_conversation_service.js';

async function openApp(page) {
  await page.goto('/webapp/');
  await expect(page.locator('#startup')).toHaveCount(0, { timeout: 45000 });
  await expect(page.getByRole('button', { name: '메뉴', exact: true })).toBeVisible();
}

async function scrollTo(page, locator) {
  for (let i = 0; i < 10 && !(await locator.count()); i++) {
    const size = page.viewportSize();
    await page.mouse.move(size.width / 2, size.height / 2);
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(250);
  }
  await expect(locator).toBeAttached();
}

test.beforeEach(async ({ page }) => {
  // No test traffic reaches production, including preflight or identity routes.
  await page.route('https://api.onaria.ai.kr/**', route => route.fulfill({
    status: 503, contentType: 'application/json',
    headers: { 'access-control-allow-origin': '*', 'cache-control': 'no-store' },
    body: JSON.stringify({ message: '웹앱 테스트 연결 오류' }),
  }));
});

test('home, web help, unavailable notifications and six-star completion', async ({ page }) => {
  await openApp(page);
  await page.getByRole('button', { name: '메뉴', exact: true }).click();
  await expect(page.getByRole('menuitem', { name: '회원가입', exact: true })).toHaveCount(0);
  await page.getByRole('menuitem', { name: '웹앱 이용 안내', exact: true }).click();
  await expect(page.getByText(/다른 기기와 자동 동기화되지/)).toBeVisible();
  await page.getByRole('button', { name: '확인', exact: true }).click();
  await page.getByRole('button', { name: '메뉴', exact: true }).click();
  await page.getByRole('menuitem', { name: '알림 설정', exact: true }).click();
  await expect(page.getByText(/예약 알림은 Android/)).toBeVisible();
  await page.getByRole('button', { name: /Back|뒤로/ }).click();
  await page.getByRole('button', { name: '메뉴', exact: true }).click();
  await page.getByRole('menuitem', { name: '십자가 미니게임', exact: true }).click();
  await page.waitForTimeout(500); // Finish navigation before tapping moving stars.
  for (const [index, word] of ['평안', '희망', '사랑', '은혜', '용기', '용서'].entries()) {
    if (index) await page.waitForTimeout(5200); // The game intentionally paces collection.
    const star = page.getByRole('button', { name: `${word}의 빛`, exact: true });
    await expect(star).toBeEnabled();
    // Stars deliberately move continuously; skip Playwright's stability wait.
    await star.click({ force: true });
    if (index === 0) {
      await expect(page.getByRole('button', { name: '잠시 쉬기', exact: true })).toBeAttached();
      await expect(page.getByRole('button', { name: '처음부터', exact: true })).toBeAttached();
      await expect(page.getByRole('button', { name: '이번에는 여기까지', exact: true })).toBeAttached();
    }
  }
  await scrollTo(page, page.getByRole('button', { name: '편안히 돌아가기', exact: true }));
  await expect(page.getByRole('button', { name: '잠시 쉬기', exact: true })).toHaveCount(0);
  const replay = page.getByRole('button', { name: '한 번 더 빛 모으기', exact: true });
  await scrollTo(page, replay);
  await replay.click();
  await expect(page.getByRole('button', { name: '처음부터', exact: true })).toBeAttached();
  await page.screenshot({ path: `../build/webapp-${test.info().project.name}.png` });
});

async function openChat(page) {
  await openApp(page);
  await page.getByRole('button', { name: /^불안/ }).click();
  await page.waitForTimeout(1000); // Allow scrolling and the semantics overlay to settle.
  const start = page.getByRole('button', { name: 'AI 마음대화 시작하기', exact: true });
  await scrollTo(page, start);
  await expect(start).toBeEnabled();
  // Flutter's full-screen semantics overlay forwards pointer events to the canvas.
  // Send a real pointer click without Playwright's DOM interception check.
  await start.click({ force: true });
  const input = page.getByRole('textbox');
  await expect(input).toBeVisible();
  return input;
}

test('consent gates chat and a saved card survives reload', async ({ page }) => {
  // Exercise the browser download fallback without opening the OS share sheet.
  await page.addInitScript(() => Object.defineProperty(navigator, 'canShare', { value: undefined, configurable: true }));
  const generate = createLocalConversationService();
  let calls = 0;
  await page.route('https://api.onaria.ai.kr/v1/mind/chat', async route => {
    if (route.request().method() === 'OPTIONS') {
      await route.fulfill({ status: 204, headers: { 'access-control-allow-origin': '*', 'access-control-allow-headers': 'content-type', 'access-control-allow-methods': 'POST' } });
      return;
    }
    calls++;
    const result = await generate(route.request().postDataJSON(), { id: 'integrated' }, '');
    await route.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*', 'cache-control': 'no-store' }, body: JSON.stringify(result) });
  });
  const input = await openChat(page);
  await input.click();
  await expect(input).toBeFocused();
  // Flutter replaces the semantics editor while the route/IME attaches.
  await page.waitForTimeout(500);
  await page.keyboard.insertText('내일 발표가 걱정돼요.');
  await expect(input).toHaveValue('내일 발표가 걱정돼요.');
  await page.keyboard.press('Enter');
  await expect(page.getByText('AI 대화를 시작하기 전에', { exact: true })).toBeVisible();
  expect(calls).toBe(0);
  await page.getByRole('button', { name: '취소', exact: true }).click();
  expect(calls).toBe(0);
  await input.click();
  await expect(input).toBeFocused();
  await page.waitForTimeout(500);
  await expect(input).toHaveValue('내일 발표가 걱정돼요.');
  await page.getByRole('button', { name: '보내기', exact: true }).click();
  await page.getByRole('button', { name: '전송에 동의하고 계속', exact: true }).click();
  await expect.poll(() => calls).toBe(1);
  await expect(page.locator('body')).toContainText('그 순간 머릿속에 가장 먼저 떠오른 생각은 무엇이었나요?');
  for (const [index, text] of ['실수할까 봐 걱정했어요.', '오늘은 잠시 쉬고 싶어요.'].entries()) {
    await input.click();
    await page.waitForTimeout(500);
    await page.keyboard.insertText(text);
    await expect(input).toHaveValue(text);
    await page.keyboard.press('Enter');
    await expect.poll(() => calls).toBe(index + 2);
    if (index === 0) await expect(page.locator('body')).toContainText('지금 가장 필요하다고 느끼는 것은');
  }
  const action = page.getByRole('button', { name: '작은 실천 정하기', exact: true });
  await scrollTo(page, action);
  await action.press('Enter');
  await page.getByRole('button', { name: '1분간 천천히 호흡하기', exact: true }).press('Enter');
  const save = page.getByRole('button', { name: '마음 카드 저장하기', exact: true });
  await scrollTo(page, save);
  await save.press('Enter');
  await expect(page.getByRole('button', { name: '평안의 빛', exact: true })).toBeAttached();
  await openApp(page);
  await page.getByRole('button', { name: '메뉴', exact: true }).click();
  await page.getByRole('menuitem', { name: '저장된 카드', exact: true }).click();
  await page.getByRole('group', { name: /심리·신앙 통합 불안/ }).click();
  await expect(page.locator('body')).toContainText('1분간 천천히 호흡하기');
  await page.getByRole('button', { name: '확인', exact: true }).click();
  await page.getByRole('button', { name: '공유 미리보기', exact: true }).click();
  const share = page.getByRole('button', { name: '이 이미지 공유하기', exact: true });
  await scrollTo(page, share);
  const download = page.waitForEvent('download');
  await share.press('Enter');
  expect((await download).suggestedFilename()).toBe('onaria-card.png');
  expect(calls).toBe(3);
});

test('API failure is explained without presenting fallback as an AI reply', async ({ page }) => {
  const input = await openChat(page);
  await input.click();
  await page.waitForTimeout(500);
  await page.keyboard.insertText('내일 발표가 걱정돼요.');
  await expect(input).toHaveValue('내일 발표가 걱정돼요.');
  await page.keyboard.press('Enter');
  await page.getByRole('button', { name: '전송에 동의하고 계속', exact: true }).click();
  await expect(page.locator('body')).toContainText('서버에 연결하지 못해 AI 답변을 받지 못했어요.');
});

test('crisis support stays local without AI consent or any API call', async ({ page }) => {
  let calls = 0;
  page.on('request', request => { if (request.url().startsWith('https://api.onaria.ai.kr/')) calls++; });
  const input = await openChat(page);
  await input.click();
  await expect(input).toBeFocused();
  await page.waitForTimeout(500);
  await page.keyboard.insertText('죽고싶어요');
  await expect(input).toHaveValue('죽고싶어요');
  await page.keyboard.press('Enter');
  await expect(page.getByRole('button', { name: '자살예방상담전화 109', exact: true })).toBeVisible();
  await expect(page.getByText('AI 대화를 시작하기 전에', { exact: true })).toHaveCount(0);
  expect(calls).toBe(0);
});

test('bootstrap failure offers retry; manifest is scoped and API is not cached', async ({ page, request }) => {
  const manifest = await (await request.get('/webapp/manifest.json')).json();
  expect(manifest.scope).toBe('./');
  expect(manifest.name).toBe('ONARIA');
  expect((await request.get('/v1/mind/chat')).status()).toBe(404);
  expect((await request.get('/webapp/../.env')).status()).toBe(404);
  await page.route('**/flutter_bootstrap.js', route => route.abort());
  await page.goto('/webapp/');
  await expect(page.getByRole('button', { name: '다시 열기' })).toBeVisible();
  expect(await page.evaluate(() => caches.keys())).toEqual([]);
  expect(await page.evaluate(async () => (await navigator.serviceWorker.getRegistrations()).length)).toBe(0);
});
