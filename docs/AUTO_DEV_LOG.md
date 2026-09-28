# AUTO_DEV_LOG

## 2026-09-28 — Buddhist 데이터 디렉터리 구성 Preflight

범위: `buddhist/scriptures/`, `metadata/`, `index/` 디렉터리와 용도 문서만 추가한다.
첨부 MVP 지시서는 구조·안전 기준으로 적용한다. 실제 자료 투입과 전체 MVP 확장은 진행하지 않는다.

- 장비/OS: Darwin arm64, macOS.
- Repository / 작업 경로: `/Users/ari/ari-server/projects/onaria`.
- Remote: `origin`, `https://github.com/Naharuya/onaria.git`.
- 시작 Branch: `feat/adaptive-emotions-crosslight-365-20260921`.
- HEAD SHA: `5f6031e3328473f337d8a8b7abff801ae1a6763f`.
- Working Tree: dirty. 기존 수정 8개 및 이전 Buddhist 개발 파일, Ollama 관련 미추적 파일을 보존한다.
- 기존 수정: `ONARIA_ROADMAP.md`, `backend/e2e/web.spec.js`, `backend/src/admin_settings.js`,
  `backend/src/conversation_service.js`, `ios/Runner/GeneratedPluginRegistrant.m`, `pubspec.lock`,
  `test/conversation_examples_test.dart`, `test/engagement_integration_test.dart`.
- Frontend: `backend/public/website/`; Admin: `backend/public/admin.*`, `backend/src/admin_auth.js`.
- Flutter: `lib/main.dart`, `lib/app/onaria_app.dart`, `lib/features/`, `test/`.
- Backend: Node ESM / Express, `backend/src/server.js`, `backend/src/app.js`.
- 운영 배포: Cafe24 CI artifact, `scripts/package-backend.mjs`, `scripts/deploy-cafe24.sh`.
  패키징 허용 목록에 `backend/dev/`는 포함되지 않는다.
- Christian 데이터: 회원 SQLite는 `MEMBER_DB_PATH` 설정 또는 작업 디렉터리 기준
  `data/members.sqlite`; 비용 저장은 `backend/src/cost/sqlite_usage_ledger.js`.
  실제 DB와 사용자 데이터는 열지 않았다. 경로와 schema는 코드만 확인했다.
- Bible dataset: `assets/data/bible_verses_ko.json`. 이동·수정·복사하지 않는다.
- AI Router / Agent: `backend/src/ai_router.js`, `backend/src/agents/`,
  `backend/src/agents/religion_router.js`.
- Safety / Psychology: `backend/src/crisis.js`, `backend/src/agents/safety_agent.js`,
  `backend/src/agents/psychology_agent.js`, `lib/src/safety/`.
- 환경변수 구조: `backend/.env.example`의 키만 확인. SOUL_* 레거시 설정,
  OPENAI_* 모델 설정, MEMBER_DB_PATH, PORT, 인증/Origin 관련 설정이 있다.
  실제 `.env`나 secret 값은 읽거나 기록하지 않았다.
- DB/schema: better-sqlite3, members 및 cost_meta/cost_requests/cost_calls 테이블.
- 테스트: backend Node test, Playwright, Flutter test, `backend_contract/safety_cases.json`.
- LISTEN 포트: 3000, 3100, 5037, 8787, 8791, 11434, 31876, 42235, 49154,
  50000, 50241, 53608, 53623, 53628, 53629, 56108, 59542, 62037, 62043, 62044.
  이번 문서/디렉터리 작업에서는 서버를 시작하거나 포트를 점유하지 않는다.
- 앱 버전: 0.4.1+6; backend 패키지 버전: 0.3.0. 실서버 버전은 조회하지 않았다.
- 서비스 구조: `script/onaria-backend.service`는 Linux systemd 예제.
  로컬 Buddhist 개발은 `backend/dev/religion-packs/server.js`; 운영 서비스 제어는 하지 않는다.
- 변경 전 검증: Buddhist Pack + Christian 종교/자료 회귀 32/32 PASS.

선택한 개발 자료 경로: `backend/dev/religion-data/buddhist/`.
실제 경전 및 번역문은 저장하지 않는다. 라이선스 미확인 자료는
`BLOCKED_EXTERNAL_REVIEW`로 유지하며 응답·검색·마음카드·인덱스에 사용하지 않는다.

### 구현

- `feature/onaria-buddhist` 브랜치를 현재 HEAD에서 생성했다. 기존 dirty 작업을 보존했다.
- `backend/dev/religion-data/buddhist/{scriptures,metadata,index}/README.md`를 추가했다.
- 디렉터리가 Git에서 유지되도록 각 경로에 용도·안전 정책 문서를 두었다.
- 실제 본문, metadata 레코드, 검색 인덱스, 자동 로더는 추가하지 않았다.
- 기존 Provider, Mock, Christian 코드 및 데이터는 변경하지 않았다.

### 검증 및 종료

- 변경 후 Buddhist Pack 및 Christian 회귀: 32/32 PASS.
- 디렉터리 3개, README만 존재, 상대 참조 경로, whitespace 및 secret 패턴 검사: PASS.
- Build / Device / 운영 API / CI: NOT RUN — 문서와 디렉터리만 변경.
- Commit / Push: NOT RUN — 로컬 구성 요청 범위이며 원격 게시하지 않음.
- STOP: 실제 경전 투입 없이 별도 지시를 기다린다.

## 2026-09-28 — 사용자 추가 지시: 별도 Buddhist Android 앱 구현 후 USB 설치

- 사용자가 Web 확인 대신 별도 Android 앱 구현 및 설치를 선택했다.
- USB preflight: SM-S908N, authorized. 기존 Christian 패키지 com.onaria.app은 0.4.1+7.
  새 앱은 com.onaria.buddhist이며 기존 패키지를 대체하지 않는다.
- 기존 release keystore 및 key.properties가 없다. 새 키 생성/교체는 하지 않았으며
  기존 파일 복원 또는 위치 제공을 요청했다. 비밀값은 요청하지 않았다.
- apps/buddhist에 독립 offline Flutter 앱을 생성했다. Release는 인터넷 권한이 없고
  딥링크/알림/사용자 데이터/백업을 Christian과 공유하지 않는다.
- 기존 Safety 감지기/모델을 packages/onaria_core로 내용 변경 없이 옮기고 기존 import
  경로는 export로 보존했다. 원본과 byte 단위 동일함을 확인했다.
- packages/onaria_buddhist_pack에 합성 자료와 Provider를 두고 Web도 같은 JSON을 읽도록 했다.
- 기존 install-onaria-release.ps1 → android-release.mjs 경로에 명시적 Buddhist 옵션을 추가했다.
  기본 Christian 동작은 유지한다. 인증서·버전·패키지·권한·자산 검증 후 install -r만 허용한다.
- 신규 패키지에서 pm path가 exit 1을 반환하는 동작을 확인해, Buddhist 설치 전에는
  pm list packages로 설치 여부를 명시적으로 확인하도록 했다.
- 검증: Buddhist 6 PASS, backend 414 PASS, Web E2E 4 PASS, Christian Flutter 120 PASS / 1 SKIP,
  설치 안전장치 18 PASS / Windows 전용 1 SKIP. Buddhist analyze PASS;
  Christian analyze는 기존 example의 print info 4개이며 오류/경고 없음.
- Buddhist Release 컴파일 및 APK 격리 검증 PASS. 현재 산출물은 unsigned이며 설치 불가.
- 실기기 설치 명령은 기존 서명 파일 없음으로 설치 전에 중단되었다. 기기의 앱 데이터 변경 없음.
- 운영 API/DB/배포/실제 경전 수집/스토어 제출/commit/push는 수행하지 않았다.
- 최종 추가 검증: Christian Android Debug / iOS simulator 컴파일 PASS.
  Christian APK의 기존 Bible 자산 유지와 Buddhist Mock 자산 부재 확인 PASS.
  새 파일 및 변경 관련 42개 파일의 secret 패턴/서명 파일 혼입 검사 PASS.
- 남은 작업은 기존 Release 서명 파일 복원 후 Buddhist Release 재빌드·서명 검증·USB 설치·기기 실행 확인이다.

## 2026-09-28 — Buddhist 전용 새 키 명시 승인 및 설치 완료

- 사용자가 Buddhist 전용 새 서명키 생성과 설치를 명시 승인했다. Christian 키 재사용 규칙을
  Buddhist에 한해 변경하며 기존 Christian 키/설정 경로에는 쓰지 않았다.
- apps/buddhist/android/buddhist-release.jks 및 key.properties를 생성했다.
  비밀값을 출력하지 않고 소유자 전용 권한 0600, Git 제외 및 미추적 상태를 검증했다.
- 공개 지문만 release-certificate.sha256에 기록하고 설치기가 이를 검증하도록 변경했다.
- 변경 전 설치 테스트 18 PASS / 1 SKIP; 변경 후 21 PASS / 1 SKIP.
  Buddhist·Christian backend 관련 회귀 32 PASS. git diff --check PASS.
- 기존 wrapper의 Node 구현으로 Release 재빌드, 인증서·패키지·버전·권한·자산 검증 후
  adb install -r 성공. SM-S908N에 com.onaria.buddhist 0.1.0+1을 설치했다.
- 앱 launch Status ok, 프로세스 존재, 기기의 versionCode/versionName 및 non-debuggable 확인.
  추가 화면 캡처는 기기에서 반환되지 않아 시각 검증은 미실행으로 기록한다.
- 기존 Christian 앱 삭제/교체/초기화, 운영 API/DB 접근, 배포, 스토어 제출, commit/push 없음.
- STOP: 실제 경전 데이터는 투입하지 않는다. 새 키와 설정의 안전한 별도 백업이 필요하다.

## 2026-09-28 — 순차 통합 1단계: 현재 기능·공통 모듈 점검

- 사용자 지시에 따라 1단계 코드 점검을 수행하고 `docs/BUDDHIST_CORE_AUDIT.md`를 작성했다.
- 현재 branch/HEAD/dirty 상태를 보존했다. origin/main fetch 후 HEAD 고유 53개,
  원격 고유 2개 커밋을 확인했고 merge/reset/stash는 하지 않았다.
- 발견: 대화·카드·성장 로직이 Bible 타입/문구와 결합돼 있어 직접 재사용 불가.
  기존 social 로그인은 준비 중이며 카드 동기화도 완료 기능으로 간주할 수 없다.
- 다음 구현을 2-A 공통 감정·강도·직접 입력 계약 및 Buddhist 체크인 연결로 한정했다.
- 현재 재검증: backend 관련 32 PASS, Christian 상태/Safety/저장 호환성 9 PASS,
  Buddhist Flutter 6 PASS. 과거 결과를 재사용하지 않았다.
- 원격 CI는 다른 SHA의 Web/Admin 실패, App QA 성공, macmini 실패, Cafe24 SKIPPED를 확인했다.
  현재 작업의 CI로 간주하지 않는다. 상세 원인과 후속 CI 경로 확장 작업은 점검 문서에 기록했다.
- 문서 경로·내용·whitespace·secret 검사 후 종료. 이번 단계 실행 코드/기기/운영 변경 없음.
- commit/push는 수행하지 않았으며 기존 사용자 작업과 혼합하지 않았다.

## 2026-09-28 — 2-A 공통 체크인 구현

- AGENTS 및 브랜치/HEAD/dirty 상태를 재확인하고 origin/main fetch를 수행했다.
  HEAD 고유 53/원격 고유 2개 차이를 유지하며 merge/reset/stash하지 않았다.
- EmotionType을 공통 Core로 내용 변경 없이 이동하고 호환 export를 유지했다.
- CheckInInput의 runtime 범위 검증, Buddhist 감정 16개·강도·직접 입력 전달,
  대화 진입 전 위기 차단 및 sticky risk를 연결했다.
- 상세 변경·수용 기준·로컬 검증은 docs/BUDDHIST_CHECKIN_STEP_2A.md에 기록했다.
- 기존 사용자 작업 14개가 덮어써지지 않았음을 해시 비교로 확인했다.
- 이번 단계는 신규 설치, 운영 변경, 실제 경전 투입 없이 코드·테스트·CI 연결까지 진행한다.

## 2026-09-28 Buddhist 2-B (local)

- P1: Buddhist 세션에 공통 ConversationState/ReligionProfile 경계가 없어 후속 대화 확장 전에 고정 profile과 Safety 선행 계약을 구현했다.
- Core 불변 상태를 BuddhistSession에 연결. 교차 Pack 거부, sticky crisis, 이전 인용/카드 제거, 무검색 시 문구 생성 금지 회귀 검사.
- Christian legacy 단계용 변환 어댑터 추가. 기존 실행 경로 및 wire 형식 유지.
- Flutter Christian 125 pass/1 skip (working tree), Buddhist 14 pass; 집중 Safety/계약 18 pass. backend 격리 10 pass, Web E2E 4 pass. analyze 기존 print info 4건만 남음.
- Buddhist Release 빌드 및 인증서/package/offline/mock 자산 검증 PASS. 실기기 설치/배포/실경전 수집 없음.
- 기존 사용자 미커밋 파일 보존. 이전 자동 승인 심사의 remote push 차단 유지, 원격 CI 미실행.
- 다음 후보: 3-A Mock 기반 단계별 대화·회고·실천 흐름. 실제 경전 투입은 별도 라이선스 검증과 2차 지시까지 금지.

## 2026-09-28 Buddhist 3-A (local)

- P1 핵심 기능: 단일 검색 UI를 상황 → 필요 → 자료 동의 → 회고 → 실천 → 마무리의 고정 로컬 대화로 연결.
- 동의 전 검색 차단, 거절/무검색 결과의 실천 경로, Provider 오류 재시도, 입력/단계 검증 구현. 미전송 위기 입력도 선택·카드·탭 동작 전에 검사.
- Christian 전체 Flutter 125 PASS/1 SKIP, Buddhist 26 PASS. backend 10 PASS, 기존 Web E2E 4 PASS.
- Buddhist analyze clean; Christian 기존 print info 4건. Buddhist Release 0.1.2+3, Christian Android debug 및 iOS simulator compile PASS. APK 자산 분리 및 Buddhist 기존 인증서/패키지/offline 검증 PASS.
- 실기기 설치, 운영 호출, 실제 경전 수집, push/배포 없음. 상세 내용과 중간 테스트 수정 이력은 BUDDHIST_CONVERSATION_STEP_3A.md 참조.
- 다음 후보: 3-B 카드 상세·저장/복원·목록. 사용자 기존 미커밋 변경은 제외한다.

## 2026-09-28 Buddhist 3-B (local; push deferred by user)

- P1 핵심 기능: 저장 목록·상세 출처·권리 상태·저장 시각과 재시도 UI 추가.
- v2 로컬 참조 저장: scriptureId/UTC savedAt만 저장, 기존 v1 원본 보존. Provider로 다시 검증한 합성 자료만 노출. 손상 기록은 덮어쓰기 차단.
- Buddhist 34 PASS/analyze clean, Christian 전체 125 PASS/1 SKIP, backend 10 PASS, 기존 Web E2E 4 PASS.
- Buddhist Release 0.1.3+4 빌드와 전용 서명/package/offline/Mock 자산 검사 PASS.
- 실기기 설치, 실제 경전 수집, 운영 변경, push 없음. 사용자가 push를 나중에 일괄 수행하도록 명시했다.
- 상세 검증·제한·중간 수정 이력은 BUDDHIST_CARD_STEP_3B.md 참조. 다음 후보는 가짜 클라이언트 기반 맥락/감정 계약 고도화.

## 2026-09-28 Buddhist 4단계 local context contract

- P1 핵심 기능: LocalConversationClient 계약을 guided reply에 연결. 감정/강도 및 최근 두 답변의 메모리 맥락으로 고정 안내문 선택.
- Safety·profile·길이·단계 검사 후에만 Mock factory 호출. 폐쇄형 응답 schema로 임의 인용/문구 차단, 실패 시 고정 응답 복구, 재진입 위기 덮어쓰기 방지.
- Buddhist 전체 40 PASS, 신규 계약 재검사 6 PASS, analyze clean. Christian 전체 125 PASS/1 SKIP, backend 10 PASS, Web E2E 4 PASS.
- Buddhist Release 0.1.4+5 및 전용 서명/package/offline/Mock 자산 검증 PASS. 실제 모델·경전·운영 API·기기 설치 없음.
- push는 사용자 요청대로 보류. 자세한 범위와 원격 API 미구현 제한은 BUDDHIST_CONTEXT_STEP_4.md 참조.

## 2026-09-28 Buddhist 5단계 identity/records requirements (docs only)

- P1 설계 과제: 현재 guest v1/v2 기록에 계정 소유권·전환 계약이 없다. 실제 인증을 붙이기 전에 기존 기록과 계정별 데이터 분리 요구사항을 정의했다.
- BUDDHIST_IDENTITY_RECORDS_STEP_5.md에 guest 기본 흐름, 합성 dev identity, 메모리 repository, scope/generation 경계, 데이터 보관, 실패 처리, 후속 수용 테스트 12개를 기록.
- 소스만 읽어 확인했으며 Christian 사용자/운영 DB/토큰을 읽지 않았다. 실제 로그인/동기화/데이터 migration/경전 수집 없음.
- 문서만 변경하여 Flutter/backend 테스트·빌드·실기기/API 검사는 NOT RUN. 문서 링크/범위/diff/secret 검사 수행. push는 사용자 요청에 따라 보류.
- 다음 후보: 5-A 합성 identity와 메모리 repository 계약을 테스트로 구현. 계정 UI·실제 인증 활성화는 제외.

## 2026-09-28 Buddhist 5-A~8 (local; device UI pending)

- 합성 identity/기록 격리, 저장 카드 성장 현황·공유 미리보기·오프라인 TTS·opt-in 단발 알림, localhost Admin 세션 진단 구현.
- 위기 시 인용 제거와 고정 응답을 기기 listener 예외보다 먼저 보장하고 음성/알림을 취소한다.
- Buddhist 50 PASS/analyze clean, Christian 125 PASS/1 SKIP 및 기능별 집중 회귀 10 PASS, backend 작업 트리 415 PASS/staged snapshot 409 PASS, Web E2E 5 PASS.
- Buddhist Release 0.2.0+6 및 기존 인증서·패키지·자산 분리 검사 PASS. Christian Android debug/iOS simulator compile PASS.
- 같은 Release 설치 엔진으로 adb install -r 성공. 휴대폰이 잠겨 있어 기기 UI·음성 청취·알림 도착은 NOT RUN; 8단계 전체 완료로 표시하지 않는다.
- 상세 범위/검증/제한은 BUDDHIST_STEPS_5A_8_REPORT.md 참조. 실제 경전·운영 변경·배포 없음. push는 사용자 요청으로 보류.

## 2026-09-28 Buddhist 오방색 UI

- Buddhist에 청/적/황/백/흑 테마, 안내 영역, 통일된 카드·입력·버튼·선택 표시 적용. 공통 Core/Christian 소스 변경 없음.
- Buddhist 변경 전후 50 PASS, analyze clean, Christian 집중 회귀 4 PASS. 큰 글꼴 스크롤 접근 테스트 보완.
- 0.2.1+7 Release 서명 검증 후 기존 데이터 보존 업데이트 성공. 기기 잠금이 다시 확인되어 실기기 UI 확인 요청 중.
- 상세: BUDDHIST_OBANG_UI.md. push/운영 배포/실제 경전 투입 없음.
