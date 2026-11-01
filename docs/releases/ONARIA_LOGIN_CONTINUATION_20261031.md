# ONARIA 로그인 후속 점검 · 2026-10-31

## 범위와 기준
- 대상: /Users/ari/ARI/projects/onaria, main, 기준 HEAD 40cd65851553238c426b32f5af2639e76f24f64b.
- origin/main fetch 후 HEAD와 차이 0/0. 기존 미커밋 작업 전체 보존.
- ONARIA 전용 계정·서버·키 유지. 다른 앱 수정 없음.
- 서버·DB·키의 비밀값을 출력하거나 변경하지 않음.

## 발견 및 수정
- 카카오 authenticate는 외부 SDK 응답 유실 시 무기한 대기할 수 있고, 서비스 인스턴스 사이의 중복 인증 방지가 없었음.
- 인증 호출자에 90초 제한과 한국어 복구 안내 추가.
- 실제 SDK 콜백 종료까지 공유 요청 슬롯을 유지하여 시간초과 뒤에도 두 번째 네이티브 인증 창을 열지 않음.
- 늦은 성공은 만료된 호출자의 서버 로그인으로 이어지지 않음. 실제 콜백 종료 후 새 인증 허용.
- SDK 설치 확인 단계의 예외도 공급자 원문 없이 안전한 안내로 변환.
- 기존 카카오톡→계정 인증 분기와 nonce/서버 교환 계약 유지.

## 변경 파일
- lib/src/auth/kakao_login_service.dart
- test/kakao_login_service_test.dart
- docs/releases/ONARIA_LOGIN_CONTINUATION_20261031.md

## 검증
- 수정 전 social_login_completion_test: 2 PASS.
- 서버 member_session/auth_ux_boundaries/legacy_signup_security: 9 PASS.
- 수정 후 카카오·Google·네이버·provider API 관련 Flutter: 16 PASS.
- 변경 파일 정적 분석: No issues found.
- 변경 diff 공백 검사 및 비밀키 패턴 검사 통과.
- 전체 Flutter: 223 PASS, 1 SKIP. 제외 사유: API 주소가 설정되어 invalid API configuration 전용 테스트의 실행 조건에 해당하지 않음.
- 전체 backend: 535개 중 534 PASS / 1 FAIL. server_startup.test.js가 전체 병렬 실행에서 5초 시작 제한 초과. 해당 테스트 단독 재실행 1 PASS. 전체 실행을 PASS로 표시하지 않음.
- 전체 flutter analyze lib test example --no-fatal-infos: error 0, warning 0, info 68. 변경 파일의 분석은 별도 No issues found.
- Web 컴파일: PASS (122.2초), /tmp/onaria-login-web-20261031. CupertinoIcons 글꼴 참조 경고가 있으며 화면 검증은 미실행. 배포 산출물로 확정하지 않음.

## 운영 읽기 확인
- https://api.onaria.ai.kr/health: HTTP 200.
- https://api.onaria.ai.kr/v1/account: 자격증명 없이 HTTP 401.
- 위 확인은 계정 경로의 인증 요구만 확인. 유효 세션·DB·네 제공자 실제 로그인 성공 증거가 아님.

## 미완료 및 다음 검증
- 실제 Google/Apple/네이버/카카오 로그인과 기존 회원/신규/계정 연결/로그아웃/탈퇴 전체 여정은 이번 작업에서 미실행.
- 설치본 빌드28과 스토어 버전 대사 및 S22/A33/iPhone 실제 인증·복귀 검증 필요.
- SDK 콜백이 끝내 돌아오지 않으면 요청 슬롯은 계속 보호됨. 강제 초기화로 중복 창을 허용하지 않으며 앱 재실행 경로의 실제 기기 확인 필요.
- 운영 배포·재시작·migration·실제 계정 삭제·설치·commit/push 없음.


## 최종 작업 보고
```yaml
PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: Kakao native authentication lacked timeout and shared duplicate-request guard
PRIORITY: P1 authentication recovery
ROOT CAUSE: SDK futures were awaited without caller deadline or shared pending slot
IMPLEMENTED: 90s timeout, duplicate guard until actual callback, sanitized failure, retry tests
CHANGED FILES: kakao_login_service.dart; kakao_login_service_test.dart; this report
TEST: Flutter 223 PASS / 1 conditional SKIP; auth subset 16 PASS; backend 534 PASS / 1 timeout FAIL, failed test standalone retry PASS
BUILD: Web PASS; Android/iOS NOT RUN (this change is Dart-only; native device validation remains)
DEVICE: NOT RUN (no installation or interactive provider authorization this run)
API: health 200; unauthenticated account 401; valid session NOT RUN
CI: NOT RUN (no new commit/push)
COMMIT: NOT RUN (existing mixed working tree; no separate commit instruction)
PUSH: NOT RUN (no push instruction)
REMAINING RISKS: full backend timeout; real-provider/device flow unverified; one conditional Flutter skip; web font warning
NEXT ACTION: verify real provider login and return on designated TEST device, compare installed/store builds, then review release readiness
```
