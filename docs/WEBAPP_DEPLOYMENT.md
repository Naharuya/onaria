# ONARIA Flutter 웹앱

대상은 이 저장소의 Christian ONARIA `com.onaria.app`이다. 홈페이지/Admin 및
별도 Buddhist 앱과 구분한다. 공개 예정 경로는 `https://onaria.ai.kr/webapp/`이며
이 문서는 운영 배포 또는 DNS 변경 완료를 의미하지 않는다.

## 빌드와 로컬 확인

```sh
flutter pub get
flutter analyze lib test example --no-fatal-infos
flutter test
flutter build web --release --base-href /webapp/ --dart-define=ONARIA_API_BASE_URL=https://api.onaria.ai.kr
node scripts/serve-webapp.mjs
```

이 Mac의 `http://127.0.0.1:8788/webapp/`에서 확인한다. 서버는 loopback에만
바인딩되며 다른 기기/인터넷용 주소가 아니다. 외부 API에 대한 프록시와 비밀값
로딩은 없다. 운영 API의 CORS 정책에 따라 로컬 AI 대화는 실패할 수 있으며
앱은 기존 연결 실패 안내를 표시한다. 로컬 화면을 열었다고 AI 정상 운영으로
판정하지 않는다. `build/web/`만 정적 호스팅 대상이다.

```sh
cd backend
npm ci
npx playwright install chromium webkit
npx playwright test --config playwright.webapp.config.js
```

브라우저 테스트는 production API를 모두 가로채고 기존 로컬 응답 생성기로
합성 대화를 검증한다. 실제 AI, 회원 DB, `.env`, 유료 API는 사용하지 않는다.
WebKit의 iPhone 크기 검사는 실제 Safari/iPhone 시험을 대신하지 않는다.

## 웹 동작

- 기존 감정 선택, 마음대화, 카드, 여정, 별 모으기를 공통 Flutter 코드로 제공.
- 웹에서는 대화별 최초 일반 입력 전 ONARIA/OpenAI 전송 동의. 취소하면 입력을
  유지하고 전송하지 않음. 위기 입력은 동의창보다 로컬 Safety를 우선한다.
- 웹 회원가입 메뉴는 비노출. 기존 모바일 회원가입 동작은 유지.
- 예약 알림 설정은 웹 미지원 안내. 음성·공유는 브라우저 지원/사용자 권한 필요.
- 기록은 해당 브라우저 저장소에 남으며 동기화되지 않는다. 삭제/공용기기 주의와
  홈 화면 추가 방법은 메뉴의 웹앱 이용 안내에 표시한다.
- manifest와 기존 ONARIA 심볼을 제공한다. 오프라인 앱 실행/백그라운드 푸시를
  제공하지 않는다. 자체 service worker나 API 응답 캐시를 등록하지 않는다.
- CanvasKit은 동일 호스트 자산을 사용한다. Flutter의 글꼴 fallback은
  `fonts.gstatic.com` 접속이 필요할 수 있다.

## 공개 전 Gate

1. 개인정보처리방침의 운영 주체·문의처·보유기간·OpenAI 국외이전을 실제 운영
   사실로 확정한다. 동의 UI만으로 법적 안내가 완성된 것으로 간주하지 않는다.
2. NIV 등 포함 본문의 출시 권한·필수 표시를 확인한다.
3. API `ALLOWED_ORIGINS`에 정확한 `https://onaria.ai.kr`이 허용되는지 확인한다.
   2026-09-29 읽기 전용 OPTIONS 검사에서는 Access-Control-Allow-Origin이
   반환되지 않았다. 2026-09-29 사용자가 운영 배포를 승인했다. 실제 서버의
   기존 허용 목록을 보존하며 해당 Origin만 추가하고 응답을 재검증한다.
4. 운영 API가 공유 bearer 또는 회원 인증을 요구한다면 현재 웹앱을 바로 공개하지
   않는다. 서버 측 인증 설계를 먼저 확정한다. `ONARIA_APP_TOKEN`, 기존
   `SOUL_BIBLE_APP_TOKEN`, OpenAI 키를 웹 JS에 빌드하거나 URL에 넣지 않는다.
5. 정확한 커밋의 `ONARIA Flutter Web App` CI 통과 artifact를 사용한다.
   로컬 ZIP은 미리보기 결과물이며 Cafe24 운영 배포용 CI artifact를 대체하지 않는다.
6. HTTPS 공개 주소에서 정상 대화·CORS·위기 zero-call·카드 저장·이미지 공유·새로고침·
   홈 화면 추가·실제 Android Chrome/iPhone Safari를 확인한다.

## 운영 변경안 — 승인 후에만 적용

기존 소개 홈페이지와 `/admin`, `/v1`, `/app/open` 경로는 유지한다.
CI artifact의 정적 파일을 별도 release 디렉터리에 풀고 웹 서버의 `/webapp/`에만
연결한다. DB 및 backend 코드를 교체하거나 마이그레이션하지 않는다. 기존 웹 서버
종류/설정 위치를 확인한 후 아래 Nginx 예시를 실제 환경에 맞춰 검토한다.

```nginx
location = /webapp { return 302 /webapp/; }
location /webapp/ {
    alias /srv/onaria-webapp/current/;
    index index.html;
    add_header Cache-Control "no-store" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' https://api.onaria.ai.kr https://fonts.gstatic.com; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'" always;
}
```

JavaScript, Wasm, JSON, CSS, 폰트 MIME 매핑을 확인한다. 실제 서버의 기존 HSTS 등
보안 헤더 상속은 유지해야 한다. HTML과 초기화 스크립트의 오래된 캐시를 허용하지
않는다. SPA 내부 이동은 기본 hash 방식이므로 API나 Admin을 `index.html`로
fallback하지 않는다. 문제가 생기면 정적 release 링크만 이전 것으로 되돌린다.
운영 배포 승인은 2026-09-29 받았다. 서버 연결 정보와 실제 설정을 확인한 뒤
CI artifact를 배포하며, 이 문서는 배포 완료를 의미하지 않는다.
