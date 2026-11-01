# ONARIA

PROJECT=ONARIA
TYPE=Flutter + Node.js + AI + Web/Admin

## 프로젝트 우선순위
1. Safety
2. Religion integrity
3. API reliability
4. AI cost
5. Android/iOS
6. Web/Admin

PRODUCTION_API=https://api.onaria.ai.kr
WEBSITE=https://onaria.ai.kr
ADMIN=https://onaria.ai.kr/admin

## 프로젝트 규칙
- release signing은 `android/key.properties`가 가리키는 기존 승인 서명키를 재사용하고 `scripts/android-release.mjs`의 alias·인증서 검증을 유지한다. 구형 `soul-bible-release.jks` 파일명으로 설정을 되돌리지 않는다. 현재 키 경로 보존·기존 인증서 대조 기록은 `docs/releases/ONARIA_GOOGLE_PLAY_READINESS_2026-10-19.md`의 후속 AAB 검증을 참고하며 키 생성·교체는 별도 승인 Gate다.
- 정식 실기기 업데이트는 Release 계열로 통일한다. USB/무선 설치는 scripts/install-onaria-release.ps1 경로를 재사용하고 인증서·package·버전 검증 후 adb install -r만 실행한다.
- debug/release 설치를 혼용하지 않는다. Flutter run/IDE Run과 CI Debug APK를 정식 앱 업데이트에 사용하지 않는다.
- .debug suffix는 데이터·로그인·딥링크·알림·provider authority 영향 분석과 사용자 승인 후에만 적용한다.
- production API에서 http/localhost/127.0.0.1/raw IP/기존 Cafe24 도메인을 금지한다. 기존 Debug override는 보존한다.
- RAMI/K-Stock은 수정하지 않는다. 별도 프로젝트 지침 작성처럼 사용자가 명시한 범위만 예외로 한다.
- crisis input은 modelCalls=0, OpenAI client 생성=0, Psychology/Religion 호출=0 및 고정 local crisis 응답을 보장한다. Safety parity와 false-positive 회귀를 유지한다.
- 선택적 답변 평가와 반복 문구의 능동적 추가 저장 관련 작업은 `docs/FEEDBACK_ADAPTIVE_PHRASE_POLICY_2026-10-24.md`의 사용자 확정 목적과 실제 데이터 흐름 구분을 따른다.
- RAG 근거 없는 경전·교리를 생성하지 않는다. 종교 인용 무결성을 비용보다 우선한다.
- Cafe24 배포는 CI artifact 방식이며 승인 없이 운영 서버를 변경하지 않는다.
- Web/Admin 인증·CSRF·민감 데이터 cache 정책과 기존 API contract를 보존한다.
- 코드 영향에 따라 backend tests, Flutter tests, flutter analyze lib test example --no-fatal-infos, Android debug/release build, web/browser/security tests를 실행한다. iOS simulator compile은 가능한 macOS 환경 또는 CI에서 확인한다.
- 실기기 NFC 등 다른 프로젝트 검증을 ONARIA 검증으로 대체하지 않는다.

## 공통 자동 작업 규칙

사용자가 "다음 단계 진행해"라고 요청하면 이 파일을 먼저 읽고 다음 순서를 따른다.
이 파일은 요청받은 작업의 실행 지침이며, 무인 상시 실행이나 별도 스케줄러를 만들지 않는다.

1. 현재 경로와 적용되는 AGENTS.md, package/pubspec/project 파일, git remote, 폴더명 순서로 프로젝트를 식별한다.
2. git status, git branch --show-current, git rev-parse HEAD, git remote -v를 확인한다. remote에 인증정보가 포함되면 값을 숨겨서 보고한다.
3. 기본 브랜치는 main이다. origin/main을 fetch하여 비교하고 기존 작업을 보존한다. dirty 상태에서 강제 reset/checkout/stash를 하지 않는다. 필요하면 별도 작업 트리를 사용한다.
4. 최근 CI 실패, 테스트, 코드와 미완료 문서를 근거로 문제를 수집한다. 과거 대화의 성공 보고를 현재 검증 결과로 간주하지 않는다.
5. P0 보안/Safety/데이터 손실, P0 실행/빌드 불가, P1 API/네트워크/인증, P1 서명/배포, P1 핵심 기능, P2 성능/비용, P2 UI/UX, P3 문서/정리 순서로 우선순위를 정한다. 같은 위험도 안에서는 아래 프로젝트 우선순위를 따른다.
6. 가장 높은 우선순위의 구체적인 작업 하나를 선택하고 분석 → 계획 → 구현 → 테스트 → 리뷰 → 수정 → 재테스트를 진행한다. 문제를 찾지 못하면 불필요한 변경을 만들지 않는다.
7. 변경 전 관련 테스트를 실행하고 변경 후 관련 테스트와 변경 영향에 맞는 회귀 테스트를 실행한다. 기존 CI 명령을 우선 재사용한다. 문서만 변경하면 경로·내용·차이·secret 검사를 수행하고 불필요한 전체 빌드는 피한다.
8. 테스트 실패를 수정하고 재실행한다. 미검증·실패 상태를 PASS로 표시하지 않는다. 실패 상태에서는 push하지 않는다.
9. 수용 기준 통과 후 git status, git diff 및 커밋 대상 전체 secret 검사를 확인한다. 이번 작업 파일/변경만 선택하여 짧고 목적에 맞는 메시지로 commit/push한다. 다른 기존 변경을 섞지 않고 force push하지 않는다.
10. 정확한 커밋 SHA의 GitHub Actions를 확인한다. 경로 필터로 실행되지 않은 작업은 미실행으로 표시한다. 로컬 검증·CI·실서버·실기기 결과를 구분해 보고한다.
11. Git 저장소나 remote가 없거나 접근이 차단되면 생성/교체를 추측하지 말고 가능한 로컬 작업을 완료한 뒤 제한을 보고한다.

## 안전 및 승인 경계

- .env, API key, password, token, keystore password, private key를 출력하거나 Git에 넣지 않는다. 예시에는 실제 값 대신 placeholder만 사용한다.
- 기존 미커밋 변경과 사용자 데이터를 보존한다. 다른 프로젝트 폴더는 명시적으로 허용된 작업 이외에 수정하지 않는다.
- adb uninstall, pm clear, 운영 DB 삭제/초기화는 금지한다.
- production server를 자동 변경하거나 재시작하지 않는다.
- production DB migration, keystore 변경/교체, applicationId/package name 변경, 운영 서버 재시작, 실거래, 유료 외부 API 대량 호출, 데이터 삭제 가능 작업은 사용자 승인 전에 실행하지 않는다.
- 승인 판단이 필요한 작업과 독립적인 안전한 분석·테스트는 계속 진행한다. 비밀값을 채팅으로 요청하지 않는다.
- 기기가 unauthorized이면 설치를 중단하고 휴대폰에서 USB 디버깅 허용을 안내한다. 서명 불일치나 버전 다운그레이드를 강제로 우회하지 않는다.

## 완료 보고

다음 YAML 항목으로 결과를 보고한다. 실행하지 못한 항목은 이유와 함께 NOT RUN으로 표시한다.

PROJECT:
CURRENT COMMIT:
ISSUE FOUND:
PRIORITY:
ROOT CAUSE:
IMPLEMENTED:
CHANGED FILES:
TEST:
BUILD:
DEVICE:
API:
CI:
COMMIT:
PUSH:
REMAINING RISKS:
NEXT ACTION:


## ARI 공통 법적·사회적·개인정보 Gate
- 모든 작업 시작 시 `docs/ARI_COMPLIANCE_STANDARD.md`를 Preflight 기준으로 함께 읽는다.
- 개인정보·법적·사회적 위험은 문구만 수정하지 말고 실제 데이터 흐름/코드/삭제/보유기간/스토어 고지까지 일치시킨다.
- 자동으로 해결 가능한 항목은 에이전트가 처리하고, 사용자 본인 인증·결제·외부 계정·법적 사실값·물리 조치만 승인 Gate로 남긴다.
- 정책에 적은 보유기간은 실제 자동 파기와 테스트가 없으면 완료로 표시하지 않는다.
- 계정/개인정보 수집 기능은 안전한 본인확인 기반 삭제 경로가 없으면 출시 Gate를 통과시키지 않는다.
- 국외이전은 실제 데이터 흐름을 기준으로 판단하며 내부 검토 일정은 외부 고지에 사용하지 않는다.
- Play Data Safety / Apple App Privacy / 개인정보처리방침 / 이용약관은 실제 구현과 항상 동일하게 유지한다.

## 앱 표시 채널 공통 기준 (2026-10-31 사용자 지시)
- DEV / TEST / 정식 이름은 docs/APP_CHANNEL_STANDARD.md와 scripts/build-app-channel.py를 따른다. 기기 검증 빌드는 명시적으로 dev/test를 선택하고 정식 배포는 prod를 선택한다. Release가 정식 배포를 뜻하지 않는다. 기존 서명·인증서·버전·설치 검증을 유지한다. 표시 이름만 바꾸며 서버·DB·ID 분리를 완료했다고 주장하지 않는다. 별도 지시 없는 설치·배포·commit/push는 하지 않는다.

## 콘텐츠 전달·캐시 공통 기준 (2026-10-31)
- 사용자 지시에 따라 docs/CONTENT_DELIVERY_STANDARD.md를 따른다. 기본 콘텐츠 로컬 우선, 자체 서버 조회·백그라운드 갱신, 공개 캐시/개인 데이터 분리, 앱 독립성과 출처/권리/초안 상태를 유지한다. 코드 적용과 운영 배포·실기기·실측 완료를 구분한다.

## 공통 사용자 흐름 (2026-10-31 사용자 지시)
- docs/COMMON_CARE_FLOW.md의 감정→대화→전통별 콘텐츠→실천→카드·기록 계약과 두 common_care_flow 테스트를 유지한다. 앱별 콘텐츠·계정·서버·키·저장 정책은 독립적이다. 현재 철학 대상은 SORUA이며 이전 philosophy 시안을 현재 제품으로 비교하지 않는다. 공통 단계 수정 시 다른 세 앱과 대조하되 기존 안전/권리/동의 검사를 생략하거나 운영 서비스를 임의 활성화하지 않는다.

## 기록·삭제 공통 사용자 계약 (2026-11-01)
- docs/DATA_RIGHTS_STANDARD.md와 docs/DATA_RIGHTS_REVIEW_20261101.md를 따른다. 로컬 기록 삭제·서버 기록 삭제·탈퇴·동의 철회·로그아웃을 구분하고 실패·미확인을 완료로 안내하지 않는다. 현재 비교 대상은 SORUA이며 philosophy 시안을 다시 기준으로 삼지 않는다.
- 네 앱의 DataRightsCopy/DataRightsNotice 공통 문구와 관련 회귀를 유지한다. 저장 위치·AI 제공자·보유기간은 실제 앱별 동작대로 표시하며 계정·서버·키는 합치지 않는다. 운영 배포·실기기·스토어 양식 검증과 코드/합성 테스트를 구분한다.

## 원문·번역 언어 색상 (2026-11-01 사용자 확정)
- docs/LANGUAGE_COLORS_20261101.md에 따라 읽기 콘텐츠의 한글은 기존 기본색을 상속하고 영문·한자만 LanguageText/LanguageSelectableText로 구분한다. 본문·선택·복사·출처/AI 초안 고지를 유지하며 앱별 브랜드·계정·데이터를 합치지 않는다.


## 관리자 공통 기준 (2026-11-01 사용자 지시)
- docs/ADMIN_COMMON_STANDARD.md의 공통 인증·7개 역할·요청/문의·감사·백업 증거 상태와 앱별 콘텐츠 검수 프로필을 따른다. 기본 작업은 common_admin 계층과 공통 관리 UI를 함께 대조하고 계정·서버·DB·키를 공유하지 않는다. 삭제 처리 승인과 본인확인/실제 완료를 구분하며 미연결 확인기를 PASS로 표시하지 않는다. 기존 콘텐츠 게시 Gate와 관리자 비활성 기본값을 유지한다.


## 공통 변경 운영 반영 (2026-11-01 사용자 배포 지시)
- docs/PRODUCTION_COMMON_DEPLOYMENT_20261101.md와 docs/production-common-deployment-20261101.json이 이 대화 공통 변경의 최신 운영 반영 근거다. 과거 미배포 보고서와 구분한다. 웹·서버 배포와 앱마켓/실기기 배포를 혼동하지 않고, MAEON 관리자 잠금 및 미연결 삭제 완료/백업 증거 어댑터 상태를 유지한다.


## 감정 카드·예시 공통 추가 지시 (2026-11-01)
- docs/EMOTION_EXAMPLE_STANDARD_20261101.md를 따른다. 원문 합본을 보존하고 대화 예시5개·선택 문구 제외/보충을 유지한다. 개인 키워드는 안전한 직접 입력만 이번 사용 중 계산하며 예시 선택을 학습하지 않는다. 추가 기능 끄기·초기화·계정 경계와 기존 Safety를 유지한다. 운영 배포/영구 저장/스토어 제출은 검증 결과와 구분한다.
