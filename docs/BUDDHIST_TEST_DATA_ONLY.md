# Buddhist TEST_DATA_ONLY 개발 단계

> 후속 지시로 별도 Android 앱도 구현했다. 최신 Android 구현·빌드·설치 제한은
> [Android README](../apps/buddhist/README.md)에 기록한다. 아래 보고서는 최초 Web 검증 시점 기록이다.

이 단계의 종료 지점은 독립 로컬 Web UI와 Admin의 Mock E2E 검증이다.
실제 경전 구축, 운영 연결, 앱스토어 제출은 범위에 포함하지 않는다.
실제 자료 투입은 별도 라이선스 검증과 명시적인 2차 작업 지시를 기다린다.

## 구조와 격리

- `backend/dev/religion-packs/core.js`: 종교와 독립된 Safety 선행 처리, 고정 Pack 경계.
- `router.js`: 실행 시 주입한 Pack만 사용하며 입력 문구로 다른 종교로 전환하지 않는다.
- `christian.js`: 기존 로컬 Christian 서비스의 선택적 어댑터. 운영 진입점은 변경하지 않는다.
- `buddhist/pack.js`, `agent.js`: 결정적 Mock 응답. 모델 호출이나 OpenAI client 생성 경로가 없다.
- `buddhist/provider.js`: `BuddhistScriptureProvider`. 두 개의 합성 문장만 반환한다.
  후속 Android 작업에서 원본은 `packages/onaria_buddhist_pack/assets/mock_scriptures.json`으로 공유했다.
- `public/`: 독립 Buddhist Web UI, Provider 기반 마음카드, 읽기 전용 개발 Admin.
- `app.js`: 운영 앱과 별도인 Express 인스턴스. 프로세스 메모리의 만료되는 개발 세션만 사용한다.
- `server.js`: LISTEN preflight 후 `127.0.0.1:0`으로 바인딩하여 OS가 빈 포트를 원자적으로 선택한다.

운영 `backend/src/app.js`, `backend/src/server.js`, Flutter 진입점, Bible dataset,
DB schema, nginx/DNS/SSL, 배포 workflow를 수정하지 않는다. 기존 Cafe24 패키징의
명시적 경로 목록에 `backend/dev`가 없으므로 이 개발 앱은 운영 산출물에 포함되지 않는다.
독립 Flutter Buddhist 앱이나 모바일 배포 산출물은 이번 Web 검증에 포함하지 않는다.

## 자료 정책

두 합성 문장은 경전이나 번역문이 아니다. 모든 출력과 카드에 `TEST_DATA_ONLY`를 표시한다.
경전명·장절·번역자·출처를 AI가 생성하지 않는다. 장절과 번역자는 `null`이다.
검색 결과가 없으면 빈 인용과 고정 안내문만 반환한다. 카드는 Provider ID만 받아 생성한다.
Provider의 원본과 다른 인용 필드 및 응답의 임의 추가 설명은 검증에서 거부한다.

외부 자료는 이 단계에서 입력받지 않는다. Admin의 외부 검토 항목은 본문 없는 정책
placeholder이며 `copyright_status = BLOCKED_EXTERNAL_REVIEW`이다. 검색·응답·카드에
사용할 수 없다. 검토 상태를 변경하거나 자료를 수집·업로드·가져오는 API도 없다.
오래된 원전의 저작권 상태로 한국어 번역문의 Public Domain 여부를 추정하지 않는다.
번역자의 번역 저작권을 별도로 확인해야 한다.

## Safety와 개발 보안

기존 `crisis.js`와 공유 Safety corpus를 재사용한다. 위기 입력은 Psychology/Religion
호출보다 먼저 고정 로컬 응답으로 종료한다. 이 개발 실행 경로에는 유료 API 호출,
모델 호출, OpenAI client 생성 자체가 없다. 위기 세션은 이후 일반 입력으로 낮추지 않으며
검색·카드 API를 차단하고 UI에서 기존 인용과 카드를 제거한다.

Host와 loopback 주소 검사, 동일 Origin POST, cross-site 차단, HttpOnly/SameSite=Strict
임시 세션, CSP, `Cache-Control: no-store`를 적용한다. Admin은 동일 개발 세션의 읽기 전용
Mock 상태만 보여 준다. 이는 운영 관리자 로그인/권한 시스템이 아니며 운영에 연결하지 않는다.
세션은 한 시간 뒤 만료되고 프로세스 종료 시 사라진다. 대화 본문과 카드의 영구 저장은 없다.

## 로컬 실행

저장소 루트에서 실행한다. `.env`를 읽지 않는다. `NODE_ENV=production`이면 실행을 거부한다.

```sh
node backend/dev/religion-packs/server.js
```

출력된 `http://127.0.0.1:<OS가 선택한 포트>`만 연다. 임의의 기존 서버 포트를 재사용하지 않는다.
`lsof`로 LISTEN 검사를 수행하지 못하면 실행을 중단한다. Ctrl+C로 종료한다.

## 검증 명령

Buddhist 기능을 수정할 때마다 같은 실행에 Christian 회귀를 포함한다.

```sh
cd backend
node --test test/buddhist_pack.test.js test/buddhist_http.test.js test/religion_specialization.test.js test/christianity_pilot.test.js test/safety_invariants.test.js
./node_modules/.bin/playwright test --config dev/religion-packs/playwright.config.js
node --test
```

Flutter 회귀는 저장소 루트에서 실행한다.

```sh
flutter test --no-pub test/widget_test.dart test/safety_parity_test.dart test/crisis_detector_test.dart test/backend_contract_test.dart
```

테스트 서버는 loopback 임시 포트를 사용하고 테스트가 끝나면 종료된다.
운영 DB나 Christian 사용자 데이터는 사용하지 않는다.

## 최종 검증 보고 — 2026-09-28

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 5f6031e3328473f337d8a8b7abff801ae1a6763f
ISSUE FOUND: 독립 Mock Buddhist Provider와 Pack 실행 경계가 없었음
PRIORITY: P0 Safety 및 종교 인용 무결성
ROOT CAUSE: 기존 다종교 Agent 구조에는 이번 개발 전용의 닫힌 자료 경계와 별도 UI가 없었음
IMPLEMENTED: 독립 Core/Pack, Christian 어댑터, Buddhist Provider/Agent/Router, Safety, Web UI, 마음카드, 읽기 전용 Admin
CHANGED FILES:
  - backend/dev/religion-packs/
  - backend/test/buddhist_pack.test.js
  - backend/test/buddhist_http.test.js
  - docs/BUDDHIST_TEST_DATA_ONLY.md
TEST:
  baseline: Christian 및 Safety 34/34 PASS
  feature_regression: Core/Provider 추가 후 및 UI/Admin 추가 후 각각 Christian 23/23 PASS
  targeted: Buddhist/Christian/Safety 44/44 PASS
  backend_full: 414/414 PASS
  flutter_christian: 13/13 PASS
  buddhist_browser_e2e: 4/4 PASS, 접근성 및 360px 화면 포함
BUILD: NOT RUN — 독립 Node/정적 Web 앱이며 모바일 코드와 빌드 설정 변경 없음
DEVICE: NOT RUN — 실기기 설치 범위 아님
API: 임시 localhost HTTP 검증 PASS, 운영 API NOT RUN
CI: NOT RUN — 로컬 미커밋 작업이며 원격 workflow 실행 없음
COMMIT: NOT RUN — 이번 요청은 로컬 개발·검증 후 STOP, 기존 미커밋 변경 보존
PUSH: NOT RUN — 원격 게시 및 배포 진행 안 함
REMAINING RISKS:
  - 운영 연결 및 모바일 Buddhist 앱은 검증 대상이 아님
  - 실제 경전 및 번역문은 라이선스 검증 전 BLOCKED_EXTERNAL_REVIEW
  - 기존 미커밋 작업이 포함된 현재 작업 트리에서 실행한 로컬 결과임
NEXT ACTION: STOP — 실제 경전 투입 없이 별도 라이선스 검증과 2차 작업 지시 대기
```
