# Feature: 회원탈퇴 / 계정 삭제

- Status: DB + provider verification + opaque member session + closed self-delete API + app/web pre-auth UI implemented; provider console credentials and mobile OAuth SDK binding pending
- Last verified: 2026-10-02
- Baseline commit: 6b01d67 (work after baseline is uncommitted)

## 1. 목적
회원이 본인 확인 후 서버 회원정보와 앱에서 정한 개인정보를 안전하게 삭제하고, 실패 시 기존 데이터를 보존한다.

## 2. 사용자 흐름 (FLOW)
개인정보/계정 관리 → 회원탈퇴 → 삭제 대상/영향 안내 → 본인확인 → 최종 확인 → 서버 삭제 → 성공 확인 → 로컬 개인정보/세션 정리 → 시작 화면.

## 3. UI 구조 (UI)
- PrivacyPage에 회원탈퇴 진입점.
- 파괴적 동작은 일반 기록 삭제와 분리한다.
- 최종 확인 전 삭제 대상과 되돌릴 수 없음을 명시한다.
- 인증 미구현/실패/네트워크 실패 시 삭제 버튼을 성공처럼 처리하지 않는다.

## 4. 상태 / 도메인 로직
- 인증되지 않은 전화번호 단독 삭제 금지.
- 인증 identity와 member ID가 서버에서 검증 가능할 때만 삭제 API 활성화.
- 서버 삭제 성공 전 로컬 데이터를 먼저 지우지 않는다.
- 재요청은 안전해야 하며 다른 회원 데이터에 영향이 없어야 한다.

## 5. 데이터 / 저장소 / API (API/DB)
- SQLite `members.id`가 삭제 대상 primary key.
- `member_store.deleteById(memberId)` 구현 및 테스트 완료.
- 현재 JWT identity는 AI entitlement용이며 members 테이블과 직접 연결되지 않음.
- 회원가입 응답의 member ID는 앱에 로컬 식별자로 저장하지만 삭제 권한으로 신뢰하지 않는다.
- `login_provider + provider_user_id`로 검증된 provider identity에 해당하는 member row만 조회한다.
- `DELETE /v1/account`는 verifier가 trusted `provider + providerUserId`를 반환할 때만 자기 row를 삭제한다. 현재 provider 인증 연동 전에는 닫혀 있다.
- TODO: 인증 공급자 연동 시 trusted identity ↔ member row 매핑을 실제 provider 검증 결과로 완성한다.

## 6. 핵심 파일과 책임
- `backend/src/member_store.js`: 회원 DB 삭제 primitive.
- `backend/src/auth/identity_verifier.js`: trusted identity 검증.
- `backend/src/app.js`: 향후 self-delete API.
- `lib/src/api/member_api_client.dart`: 향후 앱 삭제 API client.
- `lib/features/privacy_page.dart`: 향후 회원탈퇴 UI.

## 7. 의존 기능
인증 공급자/API, 회원가입 identity binding, 개인정보처리방침, Play Data Safety, Apple App Privacy.

## 8. 테스트 맵 (TC)
- `backend/test/member_store.test.js`: ID-scoped 삭제, 재삭제 안전성, 다른 회원 보존, 재가입.
- TODO: 인증 없음 401, invalid identity 401, identity/member mismatch 금지, self-delete 성공, 재요청, DB 실패 시 보존.
- TODO: Flutter UI/API 오류 테스트 + Android/iPhone 실기기 QA.

## 9. 알려진 실패 유형
- 전화번호만 입력받아 삭제하면 타인 계정 삭제 위험.
- AI entitlement identity를 member identity로 오인하면 잘못된 계정 삭제 위험.
- 서버 실패 전에 로컬 데이터를 지우면 복구 불가능한 불일치 발생.

## 10. 변경 불가 조건 (Invariants)
- 본인확인 없는 실제 회원 삭제 금지.
- 클라이언트 제공 phone/memberId만으로 권한 판단 금지.
- 다른 회원 row 삭제 금지.
- 서버 삭제 실패 시 기존 서버/로컬 데이터 보존.
- 운영 DB 삭제/migration/deploy는 사용자 승인 Gate.

## 11. Release / Migration 주의사항
인증 API가 연결되기 전에는 self-delete endpoint와 UI를 실제 삭제 가능 상태로 공개하지 않는다. 구현·정책·스토어 고지는 동일해야 한다.

## 12. 변경 이력
- 2026-10-01: BONUI 기획 프로세스를 역적용해 REQ→FLOW→UI→API→DB→TC 구조로 정리.
- 2026-10-01: `deleteById` DB primitive와 재가입/격리 테스트 PASS.
- 2026-10-01: 현재 identity와 member DB가 직접 연결되지 않음을 확인, 인증 전 실제 삭제 차단 결정.
- 2026-10-02: 앱 홈 메뉴에 `개인정보·회원탈퇴` 직접 진입점 추가, 웹 `/account-deletion` 안내 추가.
- 2026-10-02: Android 실기기에서 회원탈퇴 진입/스크롤 및 기존 마음대화 smoke PASS 후 Release 0.4.2+8 복원/독립 실행 확인.
- 2026-10-02: iPhone 15 XCUITest는 CocoaPods plugin 때문에 `Runner.xcworkspace` 사용, Flutter Debug 직접 실행 제한 때문에 테스트 전용 `RunnerUITest` Profile scheme + test-only empty entitlement override를 사용. 회원탈퇴 진입/실제 swipe/비활성 탈퇴 영역/웹 안내 확인 PASS. 운영 Release/Archive entitlement는 변경하지 않음.
- 2026-10-02: 최종 전체 회귀 Flutter 120/120, Backend 410/410 PASS.
- 2026-10-02: Google/Kakao OIDC와 Naver profile API를 `{provider, providerUserId}`로 정규화하는 provider verifier 추가. Google은 Web client ID audience + `sub`, Kakao는 OIDC `sub`, Naver는 `/v1/nid/me`의 `response.id`를 식별자로 사용.
- 2026-10-02: provider credential은 1회 서버 검증 후 폐기하고, 15분 opaque ONARIA member session을 발급. 서버에는 session token hash만 메모리 보관하며 재시작/만료/로그아웃/탈퇴 시 폐기.
- 2026-10-02: 앱은 secure storage 도입 전까지 member session을 메모리에만 유지. 평문 SharedPreferences 저장 금지.
- 2026-10-02: 소셜 인증 기반 추가 후 전체 회귀 Flutter 123/123, Backend 416/416 PASS. 다음 Gate는 Google/Kakao/Naver 개발자 콘솔 등록 및 모바일 OAuth SDK 연결.
