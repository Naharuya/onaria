# ONARIA 웹·앱 정보구조 정합화 로컬 검토

## Preflight 및 보존
2026-10-10 /Users/ari/ARI/projects/onaria, git root 동일, branch codex/apple-android-20261006, HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b, origin/main3fa97ca65f3c24329a22e8f3e66504e670d2f6c9. 작업 시작 전체 tracked/untracked SHA256 기준 /tmp/onaria-web-parity-baseline.json. origin/main 참조만 읽었으며 fetch/병합/리베이스/reset/clean/commit/push 없음. 다른 프로젝트/포트/DB/서비스 변경 없음.
시작 시 이미 변경된 backend package/backup/manifest/pubspec와 기존 작업을 보존했다. 현재 pubspec1.0.0+19는 시작 전 변경이며 이번 웹 작업이 수정하지 않았다. 지시 문서의 ‘실기기19 검증 완료’는 이번에 재검증하지 않았다. 앞선 기록의 기기18/후보19를 유지하고 웹에 설치 버전/Production 배포 완료를 주장하지 않았다.

## 변경 전후
| 파일 | 시작 상태 | 이번 변경 |
|---|---|---|
| backend/src/website_content.js | tracked | 밝은 hero/안내 preview,3단계 흐름,계정·기록·성경 FAQ,외부 AI 동의 명시 |
| backend/src/website.js | 기존 dirty | footer 계정삭제·고객지원 링크,theme color |
| backend/public/website/site.css | tracked | 밝은 hero/header,예시 preview/FAQ·모바일 스타일 |
| backend/test/onaria_web.test.js | 기존 dirty | 앱 동선/동의/출처/미출시 안내 회귀 |
| backend/e2e/website-v2.spec.js | tracked | 새 FAQ 구조·계정삭제 링크·mailto 분리 |
| backend/e2e/web.spec.js | tracked | 계정삭제 페이지 WCAG/bounds 검사 포함 |
| 본 문서 | 신규 | 검증/보존/미배포 기록 |
시작 이후 원본 기존 파일 변경은 위6개에 한정, 새 누락0. 보호 설정·접속 정보·DB 내용 미수집. 기존 dirty 내용에서 해당 범위를 이어 수정했으며 기존 탈퇴 오류 처리 등 유지.

## 화면·앱 정합화
- 첫 화면은 ‘오늘의 마음을 듣고, 작은 실천으로.’ 및 마음 선택→마음대화→말씀/실천. 기독교 초기 방향,의료 진단/치료 대체 아님을 유지.
- 웹 역할은 앱 경험·안전·계정·기록 안내. 감정 preview는 list이며 가짜 로그인/대화 실행 버튼이 아니다. 실제 사용자 기록을 공개하지 않으며 신규 입력 수집 없음.
- 앱의 카드/예시 언어,질문별 상황 변화 소개.16개/30회·96개 같은 구현 숫자를 공개 약속으로 박지 않았다.
- 네이버/Google/카카오/Apple,기존 계정 연결,전화번호 자동 연결 금지,계정 관리→탈퇴,Apple 연결 시 재본인확인,회원 삭제와 기기 기록 삭제 분리.
- 외부 AI는 사용자 허용 시만 처리하며 위기는 외부 호출 대기 없이 안전 안내 우선. 기존 API/Safety 모델 호출 로직 수정 없음.
- 성경 출처는 실제 assets metadata 기준 개역한글/World English Bible(WEB)/eBible.org. NIV 잔존0(검사 범위 website source/assets),새 성경 본문/권리 주장은 추가하지 않음.
- 미출시/Closed Beta 준비 상태 CTA 유지. 스토어 다운로드 링크/설치19/운영 배포/전체1년 파기 완료 약속 없음.
- 법적 페이지의 기존 선택 수집/삭제/미확정 백업 고지를 유지. 관리자 UI/인증/CSRF/민감 cache 정책은 미수정.

## 검증
변경 전 웹 node8 PASS. 변경 후 웹node9 PASS,backend전체478 PASS/0 FAIL. 시작 시 추가돼 있던 backup/manifest 테스트를 포함하는 현재 실행 결과이며 과거471과 비교해 이번 웹에서만7개 추가했다고 해석하지 않는다.
Playwright website8 PASS: /,/privacy,/terms,/account-deletion 포함 route200/SEO·링크/CTA/hash/404,keyboard/reduced-motion,360/390/430/768/1024/1440 폭bounds. mailto는 HTTP 페이지가 아니므로 기존 지원 주소 href로 검토하며 이메일 발송/수신 가능성은 NOT RUN.
전체 Playwright20 PASS: 공개 WCAG·메뉴·관리자 cookie/CSRF/cache/오프라인/API 비캐시·escape·성능 실험 포함.390px 전체 화면 직접 시각 검토. 관리자의 테스트 로그인은 fixture 자격만 사용하며 운영 인증 없음. 계정삭제 페이지 추가 WCAG 범위의7개 폭 검사는 아래 최종 결과 기록.
성능 샘플 LCP436ms/CLS0/externalResources0은 로컬 실험값이며 실제 서비스 field 성능으로 일반화하지 않는다.
로그 /tmp/onaria-parity-before.log,/tmp/onaria-parity-web-final.log,/tmp/onaria-web-parity-backend.log,/tmp/onaria-web-parity-browser.log,/tmp/onaria-web-parity-browser-full.log,/tmp/onaria-parity-legal-axe.log. screenshot은 build/onaria-web-results 임시 산출물.
알려진 private-key/API/GitHub-token 패턴 검출0,git diff --check PASS. Flutter/build/기기 NOT RUN(웹 전용). 운영 서버/DB/서비스 변경 없음.

## 남은 수동 확인/Gate
- 최종 한국어 문구/실제 모바일 앱19 상태는 담당자 확인 필요. 이번 앱 실기기 검증 없음.
- 지원 이메일 수신/삭제 본인확인 업무·Apple 실제 E2E·전체 Return URL·백업 전체 범위/기간·운영 파기/복원·스토어 고지 Gate 유지.
- 스크린리더의 실제 음성 사용성은 NOT RUN;자동 WCAG/키보드 검증과 구분.
- Production 배포: NOT RUN. 커밋/푸시: NOT RUN(사용자 보류). 새 로컬 웹이 공개 사이트에 반영됐다고 표시하지 않는다.

최종 보강: /account-deletion을 포함한 공개7개 페이지의 WCAG/overflow/메뉴 회귀7 PASS(360/390/430/768/1024/1280/1440). 위20 PASS 이후 테스트 범위만 추가하여 실행한 결과이며 제품 변경 없음.
