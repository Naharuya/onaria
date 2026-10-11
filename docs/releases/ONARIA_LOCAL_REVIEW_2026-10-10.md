# ONARIA LOCAL REVIEW — 2026-10-10

상태: PRE-FLIGHT 진행 중. Release Gate 미통과.

## PRE-FLIGHT
- 프로젝트: /Users/ari/ARI/projects/onaria
- 브랜치: codex/apple-android-20261006
- HEAD: 1aef3815c8e25022a948c4307e1c755e5cc8507b
- origin: https://github.com/Naharuya/onaria.git
- 최초 dirty entries: 64 (핸드오프 예상 63과 다름)
- 버전: 0.4.4+10
- 기존 파일 SHA-256 baseline: /tmp/onaria-preflight-20261010.json (값/내용 미출력)
- Production 배포/DB 변경 수행 안 함. merge/rebase/cherry-pick/push/tag/release 수행 안 함.

## 변경 분류
| 파일 | 상태 | 그룹 | 목적/의존성 | 위험도 |
|---|---|---|---|---|
| `assets/data/bible_verses_ko.json` | 수정 | RAG/LICENSE | 경전 콘텐츠/라이선스; 콘텐츠 Release Gate 의존 | P0 |
| `backend/src/app.js` | 수정 | BACKEND | API/서비스/웹 계약; AUTH/ACCOUNT 의존 | P1 |
| `backend/src/auth/apple_android.js` | 수정 | AUTH | 공급자 인증/세션; 클라이언트-서버 계약 의존 | P1 |
| `backend/src/auth/member_session.js` | 수정 | AUTH | 공급자 인증/세션; 클라이언트-서버 계약 의존 | P1 |
| `backend/src/conversation_service.js` | 수정 | BACKEND | API/서비스/웹 계약; AUTH/ACCOUNT 의존 | P1 |
| `backend/src/member_schema.js` | 수정 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `backend/src/member_store.js` | 수정 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `backend/src/schema.js` | 수정 | BACKEND | API/서비스/웹 계약; AUTH/ACCOUNT 의존 | P1 |
| `backend/src/server.js` | 수정 | BACKEND | API/서비스/웹 계약; AUTH/ACCOUNT 의존 | P1 |
| `backend/src/website.js` | 수정 | BACKEND | API/서비스/웹 계약; AUTH/ACCOUNT 의존 | P1 |
| `backend/test/a_track_pilot.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/app.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/apple_android.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/chat_integration.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/conversation_service.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/fixtures/cost_fixtures.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/knowledge_rag.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/onaria_web.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/phase2_service.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/phase3_agents.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/production_corpus.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/production_deployment.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/religion_specialization.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/vector_rag.test.js` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `docs/STORE_SUBMISSION_CHECKLIST.md` | 수정 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved` | 수정 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | 삭제 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | 삭제 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | 삭제 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | 삭제 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | 삭제 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | 수정 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `lib/app/mind_card_store.dart` | 수정 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `lib/app/verse_narration.dart` | 수정 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `lib/features/conversation_page.dart` | 수정 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `lib/features/privacy_page.dart` | 수정 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `lib/features/signup_page.dart` | 수정 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `lib/src/api/llm_models.dart` | 수정 | APP/UI | 앱 UI/음성/런치/SDK; Flutter 및 iOS 구성 의존 | P2 |
| `lib/src/api/member_api_client.dart` | 수정 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `lib/src/api/provider_auth_api_client.dart` | 수정 | AUTH | 공급자 인증/세션; 클라이언트-서버 계약 의존 | P1 |
| `test/conversation_examples_test.dart` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `test/conversation_lifecycle_test.dart` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `test/provider_auth_api_client_test.dart` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `test/verse_speech_lifecycle_test.dart` | 수정 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `.codex/` | 신규 | AGENT/TOOLS | 작업 실행/인계; 승인 경계 의존 | P2 |
| `ONARIA_CODEX_HANDOFF_2026-10-10.md` | 신규 | AGENT/TOOLS | 작업 실행/인계; 승인 경계 의존 | P2 |
| `backend/scripts/migrate_optional_profiles.js` | 신규 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `backend/src/auth/apple_revocation.js` | 신규 | AUTH | 공급자 인증/세션; 클라이언트-서버 계약 의존 | P1 |
| `backend/src/optional_profile_migration.js` | 신규 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `backend/test/ai_consent.test.js` | 신규 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/apple_revocation.test.js` | 신규 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `backend/test/optional_profile.test.js` | 신규 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `docs/APPLE_ACCOUNT_DELETION.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `docs/APP_STORE_CONTENT_RELEASE_GATE.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `docs/ONARIA_AGENT_TEAM.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `docs/releases/APP_STORE_BUILD_2026-10-07.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `docs/releases/APP_STORE_READINESS_2026-10-07.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `docs/releases/APP_STORE_SUBMISSION_PACKAGE_2026-10-07.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `docs/releases/GABIA_APPLE_DEPLOYMENT_2026-10-07.md` | 신규 | STORE/RELEASE DOCS | 출시/정책/운영 증거; 실제 구현과 일치 필요 | P1 |
| `lib/app/ai_consent.dart` | 신규 | ACCOUNT | 동의/선택 프로필/탈퇴; 세션과 삭제 정책 의존 | P1 |
| `scripts/onaria-agent.py` | 신규 | AGENT/TOOLS | 작업 실행/인계; 승인 경계 의존 | P2 |
| `test/ai_consent_test.dart` | 신규 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `test/privacy_account_deletion_test.dart` | 신규 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |
| `test/yuna_narration_voice_test.dart` | 신규 | TESTS | 해당 기능 회귀 검증; 구현 파일에 의존 | P2 |

## origin/main 분기 분석
fetch origin --prune: PASS (권한 확보 후 성공). tracking: 0 ahead / 0 behind. main: 5 ahead / 4 behind.

```text
> 3fa97ca Merge pull request #39 from Naharuya/codex/app-store-client-20261007
> 1014deb Prepare ONARIA app privacy and content for App Store release
> 454cb6b Fix ONARIA App Store backend privacy and account deletion gates (#38)
> eb58b03 Fix Naver relogin and restore ONARIA release CI (#37)
< 1aef381 Fix Naver relogin and restore ONARIA release CI
< ad8be39 Restore Naver config and bound social login waits
< 7b78ac3 Record Apple Services ID activation checks
< e46af98 Connect Android Apple callback and preserve release updates
< ae999ea Improve social login order and account logout navigation
```

공통 조상: `c09844f03588f11f43a20c127985dd194accef1d`

충돌 검토 대상 (같은 파일 변경; 실제 충돌 확정 아님):
- `.github/actionlint.yaml`
- `.github/workflows/build-android.yml`
- `.github/workflows/macmini-phone-deploy.yml`
- `.gitignore`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `assets/data/bible_verses_ko.json`
- `backend/.env.example`
- `backend/e2e/website-v2.spec.js`
- `backend/public/admin.html`
- `backend/public/admin.js`
- `backend/scripts/migrate_optional_profiles.js`
- `backend/src/app.js`
- `backend/src/auth/apple_android.js`
- `backend/src/auth/apple_revocation.js`
- `backend/src/auth/member_session.js`
- `backend/src/auth/provider_identity.js`
- `backend/src/conversation_service.js`
- `backend/src/member_schema.js`
- `backend/src/member_store.js`
- `backend/src/optional_profile_migration.js`
- `backend/src/schema.js`
- `backend/src/server.js`
- `backend/src/website.js`
- `backend/test/a_track_pilot.test.js`
- `backend/test/account_deletion.test.js`
- `backend/test/ai_consent.test.js`
- `backend/test/app.test.js`
- `backend/test/apple_android.test.js`
- `backend/test/apple_revocation.test.js`
- `backend/test/chat_integration.test.js`
- `backend/test/conversation_service.test.js`
- `backend/test/fixtures/cost_fixtures.js`
- `backend/test/knowledge_rag.test.js`
- `backend/test/onaria_web.test.js`
- `backend/test/optional_profile.test.js`
- `backend/test/phase2_service.test.js`
- `backend/test/phase3_agents.test.js`
- `backend/test/production_corpus.test.js`
- `backend/test/production_deployment.test.js`
- `backend/test/provider_identity.test.js`
- `backend/test/religion_specialization.test.js`
- `backend/test/vector_rag.test.js`
- `docs/APPLE_ACCOUNT_DELETION.md`
- `docs/APPLE_ANDROID_SETUP_20261006.md`
- `docs/CAFE24_ZIP_DEPLOYMENT.md`
- `docs/LOGIN_UX_UPDATE_20261006.md`
- `docs/SOCIAL_LOGIN_RECOVERY_20261006.md`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `ios/Runner/Info.plist`
- `lib/app/ai_consent.dart`
- `lib/app/mind_card_store.dart`
- `lib/app/verse_narration.dart`
- `lib/features/check_in_page.dart`
- `lib/features/conversation_page.dart`
- `lib/features/privacy_page.dart`
- `lib/features/records_page.dart`
- `lib/features/signup_page.dart`
- `lib/src/api/llm_models.dart`
- `lib/src/api/member_api_client.dart`
- `lib/src/api/provider_auth_api_client.dart`
- `lib/src/auth/apple_android_auth_client.dart`
- `lib/src/auth/google_login_service.dart`
- `lib/src/auth/naver_login_service.dart`
- `pubspec.yaml`
- `scripts/android-release.mjs`
- `scripts/android-release.test.mjs`
- `scripts/deploy-cafe24.sh`
- `scripts/prepare-local-release-config.mjs`
- `scripts/prepare-local-release-config.test.mjs`
- `scripts/sync-naver-config.mjs`
- `scripts/sync-naver-config.test.mjs`
- `scripts/test_deploy_cafe24.py`
- `test/account_layout_test.dart`
- `test/ai_consent_test.dart`
- `test/apple_android_auth_client_test.dart`
- `test/conversation_examples_test.dart`
- `test/conversation_lifecycle_test.dart`
- `test/naver_login_service_test.dart`
- `test/naver_relogin_request_test.dart`
- `test/privacy_account_deletion_test.dart`
- `test/provider_auth_api_client_test.dart`
- `test/signup_layout_test.dart`
- `test/signup_validation_test.dart`
- `test/social_login_completion_test.dart`
- `test/verse_speech_lifecycle_test.dart`
- `test/yuna_narration_voice_test.dart`

추천: 현 working tree를 먼저 검증하고 AUTH/ACCOUNT, 콘텐츠, UI, 도구를 별도 커밋 단위로 보존한다. 승인 후 별도 통합 worktree에서 origin/main을 기준으로 비교하고 동일 패치/중복 변경을 제외해 적용한다. 현재 dirty branch에서 직접 merge/rebase하지 않는다. `1aef381`과 main의 `eb58b03`은 제목이 같으므로 패치 중복 여부부터 확인한다.

## 로컬 검증 (중간 기록)
| 검증 | 결과 | 증거 |
|---|---|---|
| backend `npm test` | PASS: 453 pass / 0 fail | /tmp/onaria-backend-review.log; 최초 sandbox EPERM 후 재실행 exit 0 |
| Flutter analyze lib test example --no-fatal-infos | PASS: error/warning 0, info 17 | /tmp/onaria-analyze-review.log; exit 0 |
| Flutter test | PASS: 150 pass / 1 skipped | /tmp/onaria-flutter-review.log; exit 0; skipped는 미실행 |
| Android debug build | PASS | /tmp/onaria-android-build-review.log; exit 0; 설치하지 않음 |
| iOS release no-codesign build | PASS | /tmp/onaria-ios-build-review.log; exit 0 |
| iOS Release signing build | PASS | /tmp/onaria-ios-signed-review.log; exit 0; codesign --verify --deep --strict exit 0 |

## 실기기 준비
iPhone 15 physical connected, UDID 00008120-001855410CC3A01E. 초기 sandbox CoreDevice timeout 후 권한 확보 조회 성공. bundle ID com.onaria.app, team BJL8U6B46S (소스 설정값; 유효 인증서 확인 전). 설치 앱은 **1.0.0+13**으로 소스 0.4.4+10과 불일치. 설치된 구버전/다른 빌드 E2E를 현재 소스 PASS로 표시하지 않는다. Android adb devices: 0대.

## CI (읽기 전용)
- run 37742017521: Cafe24 deployment package, `3fa97ca65f3c24329a22e8f3e66504e670d2f6c9`, completed/skipped
- run 37741252404: Cafe24 deployment package, `3fa97ca65f3c24329a22e8f3e66504e670d2f6c9`, completed/skipped
- run 37741008568: App QA and Android Test APK, `e2d0470c72e1ff19a5ad208b8e89bc3adebd0af2`, completed/success
- run 37741008491: ONARIA Web and Admin, `e2d0470c72e1ff19a5ad208b8e89bc3adebd0af2`, completed/success
- run 37739761728: Cafe24 deployment package, `3fa97ca65f3c24329a22e8f3e66504e670d2f6c9`, completed/skipped
- run 37738823611: App QA and Android Test APK, `2cc43ee9ff64477c995aed8d62615731ec608325`, completed/success
- run 37728437639: Cafe24 deployment package, `3fa97ca65f3c24329a22e8f3e66504e670d2f6c9`, completed/success
- run 37727577722: App QA and Android Test APK, `3fa97ca65f3c24329a22e8f3e66504e670d2f6c9`, completed/success

현재 dirty working tree는 CI 대상이 아니다. 위 원격 SHA의 성공을 현재 로컬 변경 PASS로 간주하지 않는다. skipped workflow는 미실행. 최근 8개 조회 범위에 failure 없음.

## 변경 목적 상세 보완
- `backend/src/app.js`: Apple 철회 선행, 전체 identity 세션 폐기, adult consent 전달, 구 스키마 503
- `backend/src/auth/apple_android.js`: Apple code/JWT 메모리 임시 보관 및 grant 일회 소비
- `backend/src/auth/member_session.js`: identity 단위 전체 세션 철회; 메모리/SQLite parity
- `backend/src/member_schema.js`: 이름/전화 선택 입력, 만 18세 확인, admin null masking
- `backend/src/member_store.js`: nullable phone 신규 DB와 기존 DB fail-closed; identity 조회
- `backend/src/conversation_service.js`: 외부 AI 동의 버전 누락 시 local fallback; crisis 우선 순서
- `backend/src/schema.js`: 선택 externalAiConsentVersion 계약 추가
- `backend/src/server.js`: Apple native/Android revocation 런타임 주입
- `backend/src/website.js`: 개인정보/약관/탈퇴 공개 안내 업데이트
- `backend/src/auth/apple_revocation.js`: subject 검증 → Apple code 교환 → revoke; 실패 시 삭제 차단
- `backend/src/optional_profile_migration.js`: 명시적 기존 회원 스키마 변경; 오늘 운영 실행 금지
- `backend/scripts/migrate_optional_profiles.js`: --check/--apply 및 백업 요구 migration CLI; 실행하지 않음
- `lib/features/privacy_page.dart`: Apple 재인증 탈퇴/연결해제, 세션 폐기, AI 동의 철회
- `lib/features/signup_page.dart`: 선택 프로필, 성인 확인, 동의 UI/API 연결
- `lib/app/ai_consent.dart`: 외부 AI 전송 동의 저장/철회
- `lib/features/conversation_page.dart`: 전송 동의 Gate, WEB 안내와 음성 UI
- `lib/app/mind_card_store.dart`: 저장된 구절 export English 표기
- `lib/app/verse_narration.dart`: 영어 음성 선택/문장 정리 및 fallback
- `lib/src/api/llm_models.dart`: 동의 버전 선택 직렬화
- `lib/src/api/member_api_client.dart`: optional phone 및 adultConfirmed 전달
- `lib/src/api/provider_auth_api_client.dart`: 탈퇴/연결해제 Apple proof body
- `assets/data/bible_verses_ko.json`: 한/영 구절 및 라이선스/출처 메타데이터; 오늘 수정 제외
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`: LaunchImage 대신 launch view 구성
- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`: SwiftPM 의존성 lock 추가
- `.codex/agents/backend_auth.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/agents/coordinator.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/agents/flutter_device.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/agents/qa_security.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/agents/scheduler.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/agents/server_deploy.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/agents/web_admin.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/config.toml`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).
- `.codex/onaria-schedule.json`: 신규 AGENT/TOOLS, 에이전트 역할/설정/스케줄 자료; 자동 스케줄 실행하지 않음, 실행 시 별도 영향 검토 (P2).

TESTS의 RAG/서비스 fixture 다수 수정은 externalAiConsentVersion 전달에 의존한다. Apple/optional profile/AI consent/privacy account deletion 신규 테스트는 위 AUTH/ACCOUNT 구현에 의존한다. LaunchImage 삭제 5개는 LaunchScreen 변경과 함께 검토한다. 출시 문서의 과거 실서버 결과는 이번 실서버 검증으로 인정하지 않는다.

## 최종 산출물/보존 검증
- iOS: `build/ios/iphoneos/Runner.app`, com.onaria.app, 0.4.4+10, TeamIdentifier BJL8U6B46S. Release signed build와 codesign deep/strict 검증 성공. 최초 sandbox trust 오류는 권한 확보 검증에서 해소. 인증서/키 교체 없음.
- Android: `build/app/outputs/flutter-apk/app-debug.apk`는 컴파일 검증용. 정식 실기기 업데이트용으로 사용하지 않음.
- `git diff --check`: PASS.
- 최초 dirty 파일 SHA-256 비교: 변화 0. baseline에서 디렉터리 `.codex/` 자체는 해시 대상이 아니므로 하위 파일 전체의 시작 해시 보존 증거는 없음. 해당 도구/스케줄 실행 및 수정 없음.
- 최종 status: 기존 64 항목 + 이번 리뷰 문서 1개 = 65 항목. 기존 수정/삭제 상태 유지.
- secret pattern scan: 읽을 수 있는 변경 텍스트/리뷰 68개, private key/OpenAI/GitHub/AWS key 패턴 탐지 0. 범위 제한된 정적 검사이며 모든 종류의 secret 부재를 보장하지 않음. 값 출력 없음.
- git cherry origin/main HEAD: local-only 5개 모두 `+`; 제목 중복만으로 동일 패치라고 판단하지 않음.

## 정확한 HEAD CI
- run 37564659931: ONARIA Web and Admin, SHA `1aef3815c8e25022a948c4307e1c755e5cc8507b`, success.
- run 37564659896: App QA and Android Test APK, SHA `1aef3815c8e25022a948c4307e1c755e5cc8507b`, success.
기존 커밋 CI 증거이며 이번 미커밋 변경의 CI 검증은 NOT RUN. 이번 commit/push 없음.

## iPhone 핵심 E2E
| 시나리오 | 결과 | 이유/HTTP status |
|---|---|---|
| 실행 후 0.4.4+10 확인 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| 로그아웃 버튼 노출 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| Google 로그인 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| Kakao 로그인 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| Naver 로그인 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| Apple 로그인 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| 재실행 session 유지 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| 로그아웃 session 폐기 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| 재로그인 중복/401 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |
| 계정삭제 UI → 본인확인 → 삭제 → 세션 폐기 → 재로그인 | BLOCKED | 현재 소스 설치 보류: 설치 앱 1.0.0+13 대비 source 0.4.4+10; 실제 E2E/HTTP status 미관찰 |

실제 사용자 데이터 삭제는 실행하지 않았다. 테스트 전용 계정과 사용자의 공급자 선택/동의/비밀번호/2FA/삭제 최종 확인이 필요하다. 콘솔/네트워크 인증 로그 수집은 NOT RUN: 해당 흐름을 실행하지 않았으며 토큰/비밀번호/authorization code 원문을 수집하지 않는다.

## Android 핵심 E2E
| 시나리오 | 결과 | 이유 |
|---|---|---|
| 설치 앱 버전, Release 설치/실행 | BLOCKED | adb devices 0대; 무한 대기/자동 polling 없음 |
| Google/Kakao/Naver 로그인 | BLOCKED | 장치 미연결 |
| session 유지/로그아웃 | BLOCKED | 장치 미연결 |
| 계정삭제 E2E | BLOCKED | 장치 미연결 및 사용자 최종 확인 필요 |

## Release Gate / 다음 조치
상태: **미통과; 전체 작업 완료 아님**. 승인 경계까지 로컬 검증 수행.
1. P1 실기기 설치 버전 불일치: 현재 설치 앱 1.0.0+13의 출처/Release 계열 확인과 업데이트 버전 결정이 먼저 필요하다. 자동 버전 변경/다운그레이드 우회/설치/실행 없음. 준비된 0.4.4+10 Release artifact를 대체 설치하거나 버전을 높이는 결정은 사용자에게 넘긴다.
2. iPhone 로그인 공급자별 성공/실패/HTTP status, session 및 삭제 E2E는 실제 결과 필요. 사용자 계정 선택/동의/비밀번호/2FA/삭제 최종 확인 Gate. 실제 회원을 삭제 테스트에 사용하지 않는다.
3. Android USB/무선 디버깅 연결과 Release 서명/package/version 검증 후 scripts/install-onaria-release.ps1 절차 필요.
4. 기존 운영 회원 DB가 nullable phone 이전 스키마이면 선택 프로필 가입은 503일 수 있다. 이번 운영 스키마 상태 미확인, 운영 migration 실행 안 함. migration은 백업과 승인 Gate.
5. Apple revoke 운영 키/config/실제 승인 철회는 미검증. 운영 변경/계정 승인이 필요한 경우 사용자 Gate.
6. 콘텐츠/저작권, 실제 로그·백업 보유/파기, 외부 AI 국외이전/스토어 고지는 기존 출시 문서의 미확정 항목으로 남는다. 오늘 수정하거나 완료 표시하지 않음.
7. main 겹침 파일 95개는 내용 충돌 확정이 아닌 검토 목록. 검증 후 변경을 기능별로 보존하고 별도 통합 worktree 전략에 대한 merge/push 승인이 필요하다.
8. Web/browser security 및 Android Release/iOS simulator 추가 빌드는 NOT RUN: 오늘 요청한 기본 로컬 검증 범위로 한정했고 코드 수정 없음. 운영 API 점검은 NOT RUN: 실기기 인증 흐름 미실행; 과거 실서버 보고를 재사용하지 않음.

**Production 배포/DB 변경 수행 안 함.** 운영 서비스 재시작, merge, rebase, cherry-pick, commit, push, tag, release, 데이터 삭제 수행 안 함.

## P1 실기기 Release 검증 재개 (2026-10-10)

이번 요청: 설치 출처/서명 대조 후 데이터 보존 Release 업데이트, 네이버 로그인 → 로그아웃 → 재로그인 → 앱 재실행. 커밋·푸시 보류.

### 출처와 버전 결정
- 설치 앱 재조회: com.onaria.app, 1.0.0(13), developer-built / container accessible. 준비된 이전 Release는 같은 bundle의 0.4.4(10).
- App Store 버전1.0의 기존 사용자 확인과 build11 CLI override는 APP_STORE_BUILD_2026-10-07.md 및 `/Users/ari/ARI/deploy-artifacts/onaria-app-store/archive-source.json`에 기록되어 있다.
- build12: Apple 로그인 entitlement 복구 이력, `/Users/ari/ARI/deploy-artifacts/onaria-app-store/apple-auth-fix-build12.json` 및 submission-20261008/APPLE_AUTH_FIX.md.
- build13 출처: `/Users/ari/ARI/worktrees/onaria-full-bible-search-20261008`, version commit `71611b732b44b8a4e4515df5cf99f189ffecc8be` (성경 검색 기기 Release 1.0.0 build13), upload 기록 commit `7ef71bb697a9525fefa74b7966db04f7d723e6a9`.
- 2026-10-08 세션의 메타데이터만 추출해 직접 iPhone 설치(10:38 UTC), signed Archive 생성(10:49 UTC), TestFlight upload succeeded(10:53 UTC) 이력을 확인. 원문 인증 로그/비밀값은 출력하거나 복사하지 않았다. Archive creation 2026-10-08 10:49:38 UTC.
- 실제 installed binary 서명은 devicectl apps에서 직접 제공하지 않는다. 기존 설치 기록/동일 버전 Archive의 서명 대조는 출처 근거이며 설치 바이너리 해시를 직접 대조한 결과와 구분한다.
- 원인: 이전 검증이 현재 pubspec 기본값으로 빌드하여 배포 계열의 명시적 버전 인자(1.0.0/13)를 놓쳤다. Bundle 충돌/다른 Team 문제는 발견하지 못했다.
- 결정: 검증 후보 1.0.0+14 (현재 installed13보다 증가). `--build-name=1.0.0 --build-number=14`; pubspec 0.4.4+10 유지. 최종 App Store 제출 버전/업로드는 이번 작업 범위 밖.
- 기능 차이: 현재 dirty 작업트리는 installed13의 full Bible search/후속 signup retry 수정과 다른 소스 계열이다. 오늘 AUTH/ACCOUNT 검증용 후보로 구분하고 최신 기능 통합 완료로 표시하지 않는다. merge/cherry-pick/다른 worktree 수정 없음.

### 서명/설정 사전 비교
| 항목 | 기존 build13 Archive | 이전 준비 Release 0.4.4+10 |
|---|---|---|
| Bundle | com.onaria.app | com.onaria.app |
| Team | BJL8U6B46S | BJL8U6B46S |
| 인증서 SHA-256 | 5f9c17cf0488242ba6c9a677a9883850a4e79d399d9bde58f3e3514c6512a12e | 동일 |
| 서명 계열 | Apple Development (Release 컴파일) | Apple Development (Release 컴파일) |
| codesign deep/strict | PASS | PASS |
| provisioning | iOS Team Provisioning Profile: com.onaria.app; iPhone UDID 포함 | 동일 |
| profile 유효기간 | 2026-10-06 ~ 2027-10-06 | 동일 |
| Release bundle 설정 | FLUTTER_BUILD_NAME/NUMBER 기반 | CLI 인자 없으면 pubspec 기본값 |

서명된 Release 컴파일과 App Store Distribution 서명은 별개다. 실기기 직접 설치용 개발 서명 Release를 사용한다. 키/인증서 교체 없음.

### 진행 상태
- iPhone 새 Release build14: 준비 중.
- iPhone 네이버 E2E: PENDING_USER_AUTH; 로그인 계정 선택/동의/비밀번호/2FA는 사용자가 직접 수행.
- Android: adb devices 0대, BLOCKED. 연결 자동 polling 없음.
- 앱 데이터 삭제/초기화 및 탈퇴는 필요하지 않으며 수행하지 않음.

### build14 사전 검증 결과
- signed Release build: PASS (`/tmp/onaria-p1-ios-build14.log`, exit0).
- build13 Archive와 build14의 application-identifier, Team, get-task-allow=true, Apple Default entitlement, keychain-access-groups(명시 항목 없음) 일치. embedded provisioning SHA256도 동일. codesign deep/strict PASS, iPhone UDID 포함.
- 네이버 native NidClientID/NidClientSecret/NidUrlScheme/NidAppName은 기존13 Archive와 모두 일치하고 placeholder 아님. 값 출력/기록 없음. 최초 비교 스크립트의 잘못된 키 이름(kConsumer*)을 실제 Nid*로 고쳐 재확인했으며 설정 자체를 변경하지 않음.
- compile flags: 1.0.0/14, production HTTPS 명시, ONARIA_AUTH_DIAGNOSTICS=true.
- 인증 HTTP 진단 추가: `lib/src/api/auth_diagnostics.dart` + MemberApiClient/ProviderAuthApiClient hook. 기본 OFF, 허용한 고정 operation(login/logout/signup_or_link/account)과 status(100~599)만 출력. request/response 본문·헤더·provider credential·session 값·동적 URL 입력을 로그로 전달하지 않는다.
- 변경 전 API/세션 테스트 PASS. 변경 후 auth/네이버/세션 회귀 12 PASS; 진단 ON 테스트 3 PASS. 분석 PASS(17 info, error/warning0).
- 기기 console은 `/tmp/onaria-p1-auth-console.py`의 whitelist 필터로 처리하여 원시 SDK 로그를 출력/파일 저장하지 않는다. 상태 로그는 `/tmp/onaria-p1-auth-status.log`에 고정 operation/status/time만 저장.
- iPhone 잠금 해제/인증 조작 가능 사용자 확인 수신. 설치는 전체 Flutter 회귀 통과 후 진행.

### iPhone 업데이트 설치 및 네이버 검증 기록
- 전체 Flutter 회귀: 153 PASS / 1 skipped (`/tmp/onaria-p1-flutter-test.log`, exit0).
- devicectl 기존 앱 위 Release 설치 PASS (`/tmp/onaria-p1-install14.json`); 앱 목록에서 com.onaria.app 1.0.0(14) 직접 확인.
- uninstall/초기화/삭제 없음. Bundle 컨테이너와 dataContainerPath는 iOS 업데이트 처리로 변경되었으므로 경로 동일성을 보존 증거로 사용하지 않는다. 설치 전후 Preferences의 com.onaria.app.plist 크기 3734 bytes, 수정 시각 동일; 권한도 0600 동일. 새 data-protection 확장 속성만 추가. 실제 기록 내용은 읽지 않았으며 완전한 데이터 동일성을 파일 메타데이터만으로 보장하지 않는다. 사용자 기록 확인은 별도.
- 사용자 관찰: build14 네이버 로그인 성공, 기존 회원에게 가입 정보 재요구 없음 → PASS(사용자 실기기 관찰).
- 사용자 관찰: 로그아웃 → 재로그인 성공, 가입 정보 재요구 없음, 401 화면 없음 → PASS(사용자 실기기 관찰).
- 앱 완전 종료 후 재실행/session 유지/기존 기록 보존: 사용자 검증 요청 중.
- iPhone 정확한 HTTP status는 현재 whitelist console에서 관찰되지 않음. 로그인 성공에 근거해 HTTP201/로그아웃204를 추정 기재하지 않는다. 서버 세션 실제 폐기 검증도 단말 UI 결과와 구분하며 별도 검증 전 PASS 표시하지 않는다.

### Android 연결/서명 Gate
- R3CT10BVG6V device (authorized), 설치 com.onaria.app 1.0.0(13), versionCode13, 기존 데이터 경로 /data/user/0/com.onaria.app.
- 기존 ps1 wrapper는 android-release.mjs를 위임 호출한다. 이 macOS에는 pwsh가 없어 **동일 exported updateRelease 엔진을 재사용**하는 /tmp/onaria-p1-android-release.mjs를 사용한다. 공식 인증서/package/non-debuggable/version/adb install -r 검증 로직 유지. flutter build 명령에 1.0.0/14 및 redacted diagnostics 인자만 추가한다. 설치기 소스/서명 설정/키를 수정하지 않는다.
- 최초 안전 점검: AGENTS 명시 soul-bible-release.jks는 현재 없음. key.properties는 기존 secure onaria-upload.jks를 참조. 계획된 다른 이름 키 사용에 대한 자동 승인 검토 거부로 설치 중단; 우회 설치 없음.
- 추가 읽기 전용 증거: 현재 keystore의 공개 인증서와 기기 설치 APK 인증서 모두 SHA256 `972ae4645e3c7c93fc4d3858250de1a3af93c514386c5d6540efd51652cd3d07`. key.properties/개인키/password 미출력. docs/APPLE_ANDROID_SETUP_20261006.md의 실제 설치 APK와 기존 upload keystore 일치/교체 없음 이력 확인. docs/ANDROID_RELEASE_UPDATE.md의 이전 지문(692e...)은 현재 설치 지문과 달라 최신 검증 근거로 사용하지 않음.
- 추가 증거 제시 후 동일 키 재사용 업데이트 실행 승인 수신. 키 생성/교체/alias/package 변경 없음. Android Release build14 설치 엔진 진행 중.
- 기존 설치기 회귀: 15 PASS / 1 Windows 조건부 skipped. 인증서 불일치/downgrade/debug/non-debuggable/설치실패 시 무삭제 경로 검증 포함.

- iPhone 사용자 최종 확인 수신: 앱 완전 종료 → 재실행 후 로그인 유지, 가입 정보 재요구 없음, 기존 기록 보존 → PASS(사용자 실기기 관찰). 첫 로그인/로그아웃/재로그인/재실행 4단계 모두 사용자 관찰 PASS. HTTP status 미관찰 제한은 유지한다.

### Android Release 설치 및 E2E 진행 결과
- 기존 updateRelease 엔진 완료 exit0: 인증서/package/version/non-debuggable 확인 후 adb install -r 한 번, 설치 Success, MainActivity Status: ok.
- 직접 dumpsys 확인: com.onaria.app, versionName1.0.0/versionCode14, firstInstallTime2026-10-02 15:45:02 유지, dataDir /data/user/0/com.onaria.app 유지. lastUpdateTime2026-10-10 10:34:24. 앱 삭제/초기화 없음.
- 사용자 관찰: 기존 네이버 로그인 성공, 가입 정보 재요구/401 없음 → PASS.
- 사용자 관찰: 로그아웃 → 같은 네이버 계정 재로그인 성공, 가입 정보 재요구/401 없음 → PASS.
- 필터된 앱 로그: 2026-10-10 10:35:37 KST account200, 10:35:40 logout204, 10:35:50 login201. 인증 body/header/세션값 수집 없음. 실제 HTTP 관찰이며 사용자 UI 응답과 분리한다.
- 재실행 로그인 유지/기록 보존: 사용자 검증 요청 중.

### 최종 검증/보존 재점검
- baseline603 tracked/untracked 파일 SHA256 재비교: 기존 파일에서 바뀐 것은 리뷰 문서 및 member_api_client/provider_auth_api_client에 추가한 진단 hook뿐. 기존 사용자 변경을 삭제/동기화하지 않았다. 새 파일은 auth_diagnostics.dart 및 auth_diagnostics_test.dart.
- 이번 변경 5개 파일의 secret pattern scan 탐지0, git diff --check PASS. 실제 비밀값 파일/keystore는 변경하거나 Git에 추가하지 않았다.
- Backend 코드는 이번 재개 작업에서 변경하지 않음. 직전453 PASS를 이전 검증 증거로 참조하며 재개 작업에서 재실행하지 않았다.
- Android 로그 buffer 재조회도 fixed time/operation/status만 메모리 필터링: 10:35:36 account200, 10:35:40 logout204, 10:35:50 login201. 사용자 추가 로그아웃/재로그인 확인에 해당하는 두 번째 네트워크 cycle은 현재 로그에 없음. 첫 cycle의201/204를 두 번째 cycle 결과로 재사용하지 않는다.

### Android 사용자 최종 확인 및 현재 E2E 판정
사용자 확인: Android 앱 완전 종료 → 재실행 후 로그인 유지, 가입 정보 재요구 없음, 기존 기록 보존 → PASS(실기기 사용자 관찰).

아래 표는 이번 build14의 결과이며 이전 BLOCKED 표를 현재 상태로 대체한다. 계정삭제/다른 공급자 검증은 이전 미검증 상태를 유지한다.

| 시나리오 | iPhone 15 | Android | 근거/제한 |
|---|---|---|---|
| 동일 Bundle/서명 Release 업데이트 | PASS | PASS | installed 1.0.0(14), 기존 키/Team 유지; 무삭제 업데이트 |
| 기존 네이버 계정 로그인 | PASS | PASS | 사용자 조작 관찰; Android login201 직접 관찰 |
| 기존 회원 가입 정보 재요구 없음 | PASS | PASS | 사용자 확인; 가입/링크 진단 이벤트 관찰 없음 |
| 로그아웃 → 재로그인 | PASS (사용자 관찰) | PASS (사용자 관찰) | Android 첫 logout204/login201 관찰; 추가 cycle HTTP 미관찰 |
| 앱 종료 → 재실행 로그인 유지 | PASS (사용자 관찰) | PASS (사용자 관찰) | secure-storage 내부 token/값을 읽거나 출력하지 않음 |
| 401 재발 없음 | PASS (사용자 관찰) | PASS (사용자 관찰 + 관찰한 HTTP) | iPhone HTTP status 미수집; 모든 숨은 재시도를 관찰한 것으로 표시하지 않음 |
| 기존 마음카드/기록 보존 | PASS (사용자 관찰) | PASS (사용자 관찰) | 기기 데이터 삭제/초기화 없음; 내부 값 전체 해시 검증은 수행하지 않음 |
| 서버 세션 폐기 후 옛 token으로 재요청 | NOT RUN | NOT RUN | token 직접 추출/재사용하지 않음; 사용자 로그아웃 UI와 별도 검증 |
| Apple/Google/Kakao 및 실제 계정삭제 E2E | NOT RUN | NOT RUN | 이번 요청은 네이버 흐름 검증; 실제 탈퇴/데이터 삭제 승인 없음 |

- 필터링 console 관찰 프로세스 종료. 지속 자동 polling/스케줄 없음.
- iPhone 직접 설치 Release는 개발 인증서로 서명된 Release 컴파일이며 App Store Distribution export/업로드/심사와 구분한다.
- iPhone의 정확한 HTTP 코드와 Android 추가 cycle의 HTTP trace는 확보하지 못했다. 사용자 조작 결과를 네트워크 수집 PASS로 바꾸지 않는다.

### 남은 Release/정책 Gate
1. 현 working tree와 main, installed13의 성경 전체검색·후속 가입 재인증 소스 계열을 별도로 보존/통합 검토해야 한다. build14는 AUTH/ACCOUNT 검증 후보이며 latest feature 통합 또는 App Store 최종 후보로 확정하지 않는다. 통합/merge/push는 보류.
2. 실제 계정삭제 및 Apple authorization 철회/전체 세션 폐기 실기기 검증은 미실행. 테스트용 계정과 최종 사용자 확인이 필요하다.
3. 활성 회원 외 사용량/안전 집계/서버 로그/백업의 보유기간과 파기 구현·테스트, 삭제 요청 경로/지원 운영 검증은 기존 정책 Gate로 남는다. 자동 파기 완료 표시 없음.
4. 실제 외부 AI 제공자·국외이전·OS/SDK 처리, 사용자 동의와 개인정보처리방침/Play Data Safety/Apple App Privacy의 일치 확인, 운영자 법적 사실값·연령/스토어 입력 Gate 유지.
5. 경전/콘텐츠 라이선스 및 저장된 이전 번역의 공유·낭독 권리 Gate 유지. 오늘 콘텐츠를 임의 변경하지 않았다.
6. Android AGENTS의 오래된 keystore 파일명과 실제 secure key 문서 지문 차이는 기록했다. 현재 설치 인증서 동일성으로 이번 무교체 업데이트를 검증했으며 지침/기존 문서를 임의 덮어쓰지 않았다.
7. commit/push/CI 신규 실행, Production 코드 배포/서비스 재시작, 운영 DB migration/직접 관리 수정/삭제는 수행하지 않았다. 사용자 로그인/로그아웃은 정상 서비스 API를 통해 인증 세션을 생성/폐기하므로 운영 DB에 어떠한 쓰기도 없었다고 주장하지 않는다.

### 재개 작업 완료 보고
```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: pubspec 기본값과 실제 배포 버전 인자 불일치; 오래된 Android 키 파일명 지침
PRIORITY: P1 실기기 Release 인증 검증
ROOT CAUSE: 배포계열 1.0.0(13)의 명시적 버전 override 이력을 이전 빌드가 반영하지 않음
IMPLEMENTED: 출처/이력 대조; 기존 서명 Release 1.0.0(14) 양 기기 데이터 보존 설치; 비밀없는 opt-in HTTP 진단; 네이버 사용자 조작 검증
CHANGED FILES:
  - docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
  - lib/src/api/auth_diagnostics.dart
  - lib/src/api/member_api_client.dart
  - lib/src/api/provider_auth_api_client.dart
  - test/auth_diagnostics_test.dart
TEST: Flutter 153 PASS/1 SKIPPED; 인증 회귀12 PASS; 진단 ON3 PASS; 설치기15 PASS/1 SKIPPED; analyze error/warning0 info17
BUILD: iOS signed Release1.0.0(14)/codesign PASS; Android non-debuggable signed Release1.0.0(14) PASS
DEVICE: 양 기기 네이버 login/logout/relogin/restart 및 기록 보존 사용자 관찰 PASS
API: Android account200/logout204/login201 관찰; iPhone 및 추가 cycle 정확한 HTTP status 미관찰
CI: 'NOT RUN: 미커밋 변경; 기존 HEAD CI 결과와 분리'
COMMIT: 'NOT RUN: 사용자 보류'
PUSH: 'NOT RUN: 사용자 보류'
REMAINING RISKS: 최신 기능 소스 통합, 정책·삭제·보유기간 Gate, HTTP trace 관찰 범위 제한
NEXT ACTION: 소스 통합 검토 및 정책/계정삭제 실기기 Gate 진행 여부 결정
```

## 인증 상태 표시/메뉴 개선 (2026-10-10)

사용자 요청: 메뉴 상단 실제 로그인 상태·공급자, 로그아웃 시 로그인 버튼, 직접 로그아웃, 계정 관리 안의 별도 회원탈퇴, 로그인/로그아웃/재실행 반영. 양 기기 Release 검증 및 기존 데이터 보존. commit/push 보류 유지.

- 시작 baseline: /tmp/onaria-auth-menu-baseline.json, 605개 tracked/untracked 파일 해시. 기존 working tree 보존.
- 변경 전 session/privacy 회귀 PASS.
- 메뉴를 갱신 가능한 스크롤 bottom sheet로 변경. 상단 확인 중/로그인하지 않음/로그인됨 · 네이버·Google·Apple·카카오. 로그인/로그아웃은 바로 표시하고 회원탈퇴는 계정 관리 내부 경로 유지. 기존 기록/여정/게임/알림 메뉴 보존.
- 서버 GET /v1/account로 실제 세션과 currentProvider 확인. 앱 시작/foreground 복귀/메뉴 열기/세션 변경 시 재확인. 401/404는 인증 상태만 정리; timeout/5xx/secure storage 복원 오류는 확인 불가로 구분하고 재시도, 기존 세션 보존. 늦은 이전 세션 응답은 새 로그인을 덮어쓰지 않음.
- MemberSessionStore 변경 알림과 secure storage 쓰기 직렬화. 빠른 로그인→로그아웃에서 이전 로그인 저장이 삭제 후 다시 적용되는 경합 방지. 토큰 getter는 UI build 중 저장/알림을 실행하지 않음. 기존 secure key와 개인 기록 키 유지.
- 검증 후보: 기존 1.0.0(14) 다음 build15, --build-name=1.0.0 --build-number=15. pubspec 변경 없음; 기존 서명 유지.
- backend/Production 배포/DB 관리 변경/계정삭제/다른 프로젝트 수정 없음.

### build15 자동 검증 및 설치
- Flutter 전체: 163 PASS / 1 SKIPPED. 관련 controller/menu/session 12 PASS. analyze error/warning 0, 기존 info 17. 변경 전 session/privacy 회귀 PASS.
- iOS signed Release 1.0.0(15) 빌드/codesign 검증 PASS. Bundle com.onaria.app, Team BJL8U6B46S, 기존 Apple Development 인증서와 동일. 실기기 설치 후 앱 목록에서 version 1.0.0 / bundleVersion 15 확인 및 실행 성공. App Store Distribution 검증과 구분한다.
- Android signed non-debuggable Release 1.0.0(15) 빌드 PASS. 기존 인증서 SHA256 972ae4645e3c7c93fc4d3858250de1a3af93c514386c5d6540efd51652cd3d07 유지. 기존 scripts/android-release.mjs 엔진(정식 설치 PowerShell과 공유)을 재사용하여 package/인증서/버전 검증 후 adb install -r, 실행 PASS. 최초 설치 시각 2026-10-02 15:45:02 유지, 이번 업데이트 시각 2026-10-10 10:54:16.
- baseline 605개 파일 중 누락 0. 수정은 이번 범위 기존 파일 6개와 신규 controller/menu/test 4개로 한정. 기존 미커밋 변경을 reset/stash/checkout하지 않았다. git diff --check PASS; 작업 파일 비밀 패턴 검사 발견 0(자동 패턴 검사의 한계 있음).
- ‘확인 중’ 전환, 4개 provider 이름, 401 인증 정리/5xx 세션 보존, 지연 응답 경합, 저장 실패 재시도, 로그아웃 API와 계정삭제 API 분리, 빠른 로그인/로그아웃 저장 경합은 자동 테스트로 확인. 실제 기기에서 네이버 외 provider E2E는 미실행.
- 사용자에게 두 기기의 새 메뉴와 로그아웃 확인을 요청한 상태. 아래 사용자 검증 완료 기록 전까지 build14 관찰을 build15 결과로 대체하지 않는다.

### 현재 build15 검증 상태 / 남은 Gate
- Android 시작 시 account200 직접 관찰(2026-10-10 10:54:17 KST). 고정 동작명/상태/시각만 whitelist하여 기록, 원본 SDK 로그·토큰 저장/출력 없음. iPhone HTTP status 수집은 NOT RUN.
- 양 기기 새 메뉴의 로그인 표시→로그아웃 표시 전환: 사용자 조작 응답 대기, NOT RUN으로 유지.
- 양 기기 새 메뉴 로그인 버튼→네이버 재로그인→앱 완전 종료/재실행 후 표시 및 기존 기록 보존: 아직 사용자 조작 결과 없음, NOT RUN. 이전 build14의 성공 확인은 별도 기록이다.
- 구현/자동 검사/Release 설치는 완료. 실기기 사용자 확인을 받은 후 이 문서에 결과를 추가하고 실제 기기 PASS 여부를 판단한다.
- 기존 Release/정책 Gate 유지: 최신 기능 소스 통합, 실제 계정삭제/Apple 철회 E2E, 보유기간 자동 파기 구현·검증, 국외이전 및 스토어 개인정보 고지 일치, 운영자 법적 사실값과 콘텐츠 권리. 이번 메뉴 개선으로 정책 Gate를 통과했다고 표시하지 않는다.
- COMMIT/PUSH/신규 CI/Production 배포: NOT RUN(사용자 보류 또는 미승인 범위). 기기 데이터 삭제/초기화 없음.

### build15 사용자 검증 1차 확인
- iPhone: 메뉴의 ‘로그인됨 · 네이버’, 직접 로그아웃, 로그아웃 후 ‘로그인하지 않음’과 로그인 버튼, 계정 관리 안의 회원탈퇴 위치 모두 정상이라고 사용자 확인 → PASS(사용자 관찰).
- Android: 동일한 메뉴 표시·로그아웃·회원탈퇴 위치 모두 정상이라고 사용자 확인 → PASS(사용자 관찰).
- 위 결과는 앞선 build15 로그아웃 표시 전환 NOT RUN 상태를 대체한다. 재로그인/재실행/기록 보존은 추가 확인 요청 중이며 아직 PASS로 표시하지 않는다.
- Android build15 진단 추가 관찰: 11:04:48 account200, 11:04:50 logout204, 11:04:54 login201/account200, 11:04:58 account200, 11:05:00 logout204(KST). 관찰 이벤트에 401/가입·링크 이벤트 없음. 이 HTTP 관찰만으로 이후 앱 재실행/기록 보존을 PASS로 간주하지 않는다.

### build15 사용자 검증 완료
아래 결과로 앞선 build15 사용자 확인 대기/NOT RUN 항목을 대체한다.

| 시나리오 | iPhone 15 | Android | 검증 근거 |
|---|---|---|---|
| 로그인됨 · 네이버 및 직접 로그아웃 표시 | PASS | PASS | build15 사용자 관찰 |
| 로그아웃 후 로그인하지 않음 + 로그인 버튼 | PASS | PASS | build15 사용자 관찰; Android logout204 추가 관찰 |
| 회원탈퇴는 계정 관리 내부의 별도 항목 | PASS | PASS | 사용자 메뉴 확인; 계정삭제 실행 없음 |
| 메뉴 로그인 버튼으로 기존 네이버 계정 재로그인, 상태 갱신 | PASS | PASS | 사용자 확인; Android login201/account200 관찰 |
| 앱 완전 종료 → 재실행 후 로그인됨 · 네이버 유지 | PASS | PASS | 사용자 관찰 |
| 기존 마음카드·기록 보존 | PASS | PASS | 사용자 확인; 앱 삭제/초기화 없음 |
| 기존 회원 가입 정보 재요구·401 재발 없음 | PASS | PASS | 사용자 확인; 확보한 Android HTTP 이벤트 범위에도 401 없음 |
| 확인 중 표시 및 네이버 외 3개 provider 상태명 | PASS(자동 테스트) | PASS(자동 테스트) | 대기 응답 widget/controller 테스트; 해당 provider 실기기 E2E 미실행 |

이번 요청의 메뉴 개선과 양 기기 네이버 세션 흐름 검증 완료. iPhone의 정확한 HTTP status는 미수집이며 사용자 확인과 구분한다. 기존 정책/소스 통합 Gate는 유지하고 App Store 최종 배포 준비 완료로 표시하지 않는다. 기존 working tree와 사용자 데이터를 보존했으며 commit/push 보류를 유지한다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: 메뉴에 실제 세션 상태/로그인 수단과 직접 로그아웃 동선 부족
PRIORITY: P1 인증 상태 정확성 / P2 메뉴 UX
ROOT CAUSE: 정적 메뉴가 세션 변경과 서버 세션 검증 결과를 구독하지 않음
IMPLEMENTED: 서버 기반 상태/수단/확인 중 표시; 직접 로그인·로그아웃; 계정 관리 내 회원탈퇴; 저장/응답 경합 방지
CHANGED FILES:
  - lib/app/member_auth_controller.dart
  - lib/app/member_session_store.dart
  - lib/features/account_menu.dart
  - lib/features/check_in_page.dart
  - lib/src/api/provider_auth_api_client.dart
  - test/member_auth_controller_test.dart
  - test/account_menu_test.dart
  - test/member_session_store_test.dart
  - test/widget_test.dart
  - docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
TEST: Flutter 163 PASS/1 SKIPPED; 관련12 PASS; analyze error/warning0 info17; diff check PASS
BUILD: Android/iOS 기존 서명 Release 1.0.0(15) PASS
DEVICE: 양 기기 새 메뉴/login/logout/relogin/restart 및 기존 기록 보존 사용자 확인 PASS
API: Android account200/logout204/login201 관찰; iPhone HTTP status 미수집
CI: 'NOT RUN: 미커밋 변경'
COMMIT: 'NOT RUN: 사용자 보류'
PUSH: 'NOT RUN: 사용자 보류'
REMAINING RISKS: 최신 소스 통합; 정책·삭제·파기·고지·콘텐츠 권리 Gate; 네이버 외 provider 실기기 E2E 미실행
NEXT ACTION: 기존 Gate를 별도 범위로 검토; commit/push 보류 유지
```

## 남은 Release Gate 검토 (2026-10-10)

범위: 소스 통합의 누락/충돌/영향 보고, 실제 회원탈퇴·보유기간·스토어 고지 대조, 테스트 계정/격리 환경 삭제 검증, 비밀없는 iPhone 인증 HTTP 수집. 운영 데이터 변경·commit/push 보류. AGENTS/ARI_COMPLIANCE/HANDOFF 재확인. HEAD 1aef3815c8e25022a948c4307e1c755e5cc8507b, origin fetch 후 main 3fa97ca 유지. merge/rebase/cherry-pick/소스 통합 실행 없음.

### 소스 통합 사전 영향 보고
읽기 전용 3-way 텍스트 시뮬레이션(임시 파일 git merge-file -p, 실제 index/tree 변경 없음):

| 대상 | 누락/충돌 | 영향 및 처리 제안 |
|---|---|---|
| main 3fa97ca / merge-base c09844f | main 변경95개 중 현재 파일86개 byte 동일; 누락0; check_in_page.dart 텍스트 충돌 | 상당수 main 변경은 이미 dirty tree에 포함. 무조건 덮어쓰기/일괄 cherry-pick은 기존 인증/메뉴 개선을 잃거나 변경을 중복할 위험. 별도 통합 후보에서 main 기준으로 이번 변경을 선택 적용해야 함 |
| build13 source 7ef71bb / main 기준 | 19개 경로 차이, 10개 경로가 현재 tree에 없음; check_in_page.dart 텍스트 충돌 | 현재 build15/16은 build13 전체검색 기능을 포함하지 않음. 앱 메뉴 진입점 충돌을 AccountMenuButton 안에 통합하고 asset 등록/검색 화면/검색 repository/테스트를 함께 검토 |
| 2cc43ee | signup 재인증 로직/테스트 누락 | 신규 가입 인증 거절 후 오래된 credential 재사용 대신 다시 인증해야 하는 복구 흐름 부재. 기존 회원 네이버 성공 테스트로 대체 불가 |
| e2d0470 | signup_page/member_store 중복 전화번호 안내 차이 | 기존 계정 로그인 후 provider 연결 안내 영향. 앱·서버 문구를 함께 검토 |
| a3281e0 | cross_light_game 및 테스트 차이 | 게임 별 생성 간격3초 변경이 현재 후보에 없음; 인증과 독립 기능 Gate |
| 5bb382a | full_bible_ko/en assets, bible_search_page, full_bible_repository, build_full_bible_assets, 검색 테스트/문서 누락 | 번역·출처·라이선스, asset 크기, 오프라인 검색 성능/안전한 인용 검증 필요 |
| 71611b7/7ef71bb | pubspec 버전 및 업로드 기록 계열 차이 | build13 이력 보존. 현재 pubspec를 근거 없이 변경하지 않으며 build16은 기존 버전 override를 사용 |

누락 경로: assets/data/full_bible_en.json, assets/data/full_bible_ko.json, docs/AUTO_DEV_LOG.md, docs/FULL_BIBLE_SEARCH.md, lib/features/bible_search_page.dart, lib/src/bible/full_bible_repository.dart, scripts/build_full_bible_assets.py, test/bible_search_page_test.dart, test/full_bible_search_test.dart, test/signup_reauthentication_test.dart.

현재 local-vs-main 별도 차이: backend/e2e/website-v2.spec.js, Apple revocation/optional profile 신규 파일군(미추적 파일은 git diff에서 파일 부재로 보이므로 실제 누락과 구분), AI consent, session/menu, API 진단, 관련 테스트/문서. 텍스트 자동 병합이 충돌하지 않는 파일도 기능 충돌 없음의 증거는 아니다. 실제 main 병합 후 CI/서명 검증은 NOT RUN. build13의 전체검색 소스를 자동 가져오지 않았다.

### 회원탈퇴 실제 동작과 격리 검증
- 앱 PrivacyPage: 삭제 확인 → fresh GET account → Apple 연결 있으면 Apple 재인증 → DELETE /v1/account. 성공 뒤 세션/회원 등록 메타데이터 정리, 개인 마음카드·임시문장 보존. 실패 시 완료 표시 없음.
- API: 유효 ONARIA 세션의 provider identity로 대상 회원 결정; Apple 철회 성공 전 삭제하지 않음; 회원 삭제 FK cascade로 identity 제거; 모든 연결 provider 세션 revokeIdentity. 임의 회원번호 삭제 경로 없음.
- 신규 backend/test/release_gate_deletion.test.js: tmpdir 전용 SQLite 회원/세션 DB, 가상 테스트 계정, loopback 임시 포트, provider verifier stub. 미인증401 → 본인 삭제204 → 회원/identity0 → 동일·다중 provider 세션 무효화 → 다른 계정/세션 보존 → 이전 세션 재삭제401 → 삭제된 identity 로그인404. 삭제 전 SQLite 백업에는 회원 행이 남는 사실까지 확인. 테스트용 임시 폴더만 정리. 운영 DB/외부 provider 호출 없음.
- 관련40 PASS, 신규 SQLite1 PASS, backend 전체454 PASS. 초기 sandbox의 listen EPERM 실패는 격리 loopback 권한으로 재실행하여 해결.
- Apple 철회 성공/실패/다른 subject 거절은 stub Apple HTTP + 임시 생성 테스트 키로 검증. 실제 테스트용 Apple 계정/격리 staging 및 외부 Apple 철회 E2E는 아직 준비되지 않았으므로 NOT RUN. 10월7일 운영 삭제 기록은 역사적 근거이며 오늘의 격리 실기기 검증으로 재표기하지 않음.

### 보유기간/고지 대조
| 데이터 | 실제 구현 | 문서/공개 안내 및 Gate |
|---|---|---|
| 활성 회원/identity | 계정 유지, 인증 삭제/FK cascade; 일괄1년 파기 없음 | privacy가 전체1년 자동 파기를 약속하지 않는 점은 구현과 일치. 기간 확정·휴면 정책/테스트 미완료 |
| ONARIA session | 기본30일 TTL, issue/size 시 만료 정리, verify 시 해당 만료 행 정리; 주기 작업 없음 | 무트래픽 시 정확한 시각 물리 파기 아님. 유효성 만료와 DB 잔존을 구분해서 고지/정책 확정 필요 |
| AI usage | SQLite 기본62일(env32..366일), recoverAt 호출 시 하루 단위 지난 비pending 요청 삭제; orphan pending은 abandoned 정산 | 회원 탈퇴 API가 usage ledger를 삭제하지 않음. 가명화만으로 삭제 대상 제외 불가; 실제 연결 가능성과 보유 사유/기간·실행 경로 추가 검토 |
| 로그/Safety 집계 | 코드의 고정 분류·집계 로그; 운영 journald/프록시 회전기간·수집경로 미확인 | 서비스 원문 기본 비표시가 모든 인프라 무보관을 증명하지 않음. 운영 읽기 전용 설정 근거/파기 테스트 필요 |
| DB/배포/변환 백업 | snapshot/deploy 백업 경로 존재; 자동 만료 삭제/삭제 계정 복원 방지 미확인 | 실제 격리 snapshot은 삭제된 회원을 보존. 보유기간·접근권한·만료 파기·복원 시 삭제 처리 재적용 Gate |
| 기기 개인 기록 | 계정 삭제와 별도 기록 삭제 기능; OS 백업 설정 별도 | 현재 privacy/삭제 안내와 일치. 테스트용 앱 격리 E2E/백업 동작은 미실행 |

공개 privacy/account-deletion을 HTTPS GET으로 읽음. 운영 페이지 변경 없음. 공개 삭제 안내 및 backend/src/website.js는 ‘개인정보·회원탈퇴’ 진입점, 현재 build15 메뉴는 ‘계정 관리’: 문구 불일치. App Store 준비물 Review notes의 같은 진입점도 갱신 필요. 운영 배포 없이 이번 검토 문서에 수정 필요 항목으로 기록한다.

스토어 고지: 선택 이름/전화번호/교회명도 실제 저장되는 수집 항목; userID/usage/진단/지원 요청, 제3자 SDK/음성 처리/외부 AI 흐름을 포함해야 함. 기존 App Privacy 표는 초안이며 실제 콘솔 설정/최종 Archive/SDK 동작과 일치 증거 없음. Google Play Data Safety 최종 입력도 미확인.
- [Apple App Privacy 공식 기준](https://developer.apple.com/app-store/app-privacy-details/): 제3자 파트너 포함, 선택 입력이라는 이유만으로 제외 불가, 실시간 요청 처리보다 오래 접근 가능한 보관 확인 필요.
- [Google Play 계정삭제 공식 기준](https://support.google.com/googleplay/android-developer/answer/13327111): 앱 재설치 없이 요청 가능한 웹 경로와 이메일 경로 허용. 공개 페이지의 이메일 문의는 후보 경로이나 실제 소유확인/처리기한/처리 완료 및 보유 예외 고지 운영 검증 전 PASS 아님. 익명 웹 폼이 없다는 사실만으로 실패 판정하지 않음.

### iPhone HTTP 수집 준비
기존 콘솔 경로에서 HTTP 진단이 확보되지 않아 opt-in AuthDiagnostics의 iOS 임시 파일로 고정 operation/status만 수집하도록 보완. 임의 path/body/header/provider credential/member token 오류문자열을 받지 않음. 64줄 bounded/직렬 저장, 실패는 인증 요청에 영향 없음; 비활성 빌드는 기록하지 않음. temp 파일이므로 앱/OS가 제거할 수 있고 영구 보유 증거로 취급하지 않음. 테스트로 비밀문자열 거절/기존 오염 행 제거/64줄 제한 확인(진단 ON4 PASS). 앱 자체 tmp/onaria-auth-status.log 한 파일만 복사 예정; 전체 container/keychain/백업을 추출하지 않음.
Release1.0.0(16) 기존 Bundle/Team/인증서/profile/codesign PASS, pubspec 변경 없음. 정상 로그인 상태 account GET만 확인할 계획, 운영 데이터 변경 금지에 따라 logout/login/delete API 호출하지 않음.

### iPhone HTTP 실제 수집 결과 / 현재 판단
- iPhone에 기존 서명 1.0.0(16) 데이터 보존 업데이트 및 실행 PASS. 기기 앱 목록 Bundle com.onaria.app / version1.0.0 / bundleVersion16 확인.
- appDataContainer의 tmp/onaria-auth-status.log만 복사하고 각 행의 전체 문자열을 정규식 검증한 뒤 고정 operation/status만 읽음. 실제 account200 두 건 확보. iPhone 기존 HTTP 미수집 제한 중 **세션 확인 GET**은 해결됐다.
- logout/login/signup/delete HTTP는 이번 요청의 운영 데이터 변경 보류 때문에 NOT RUN. build15 사용자 성공 관찰과 구분한다. TLS MITM/proxy 인증서 설치·자격증명 추출/재사용 없음.
- Flutter 전체164 PASS/1 SKIPPED, 진단 ON4 PASS, analyze error/warning0 info17, backend454 PASS, 기존 서명 iOS Release16/codesign PASS. 이번 진단 파일의 formatting 외 기능 변경 이후 추가 수정 없음. git diff --check PASS; 이번 작업4개 파일 secret pattern 발견0(패턴 검사 한계 있음).
- Android build15 기존 사용자 검증은 유지. 이번 진단 저장은 iOS opt-in 경로만 영향; Android 재설치/실기기 재검증 NOT RUN(이번 범위 iPhone HTTP 수집).

Release Gate: HOLD. 소스 통합/최종 배포 후보 고정, 실제 Apple test-account 격리 E2E, 운영 로그·백업·usage의 보유기간/파기/복원 삭제 재적용 검증, 실제 SDK·외부 AI·국외이전과 App Privacy/Data Safety 최종 입력 대조가 필요하다. 기간·법적 사실값을 임의 정하지 않았으며 자동 파기나 스토어 제출 완료로 표시하지 않는다. 개인정보 삭제 처리 이메일 경로의 실제 본인확인·접수·완료 운영 절차도 미검증이다.
운영 DB/서버 변경/재시작/배포, 실제 회원 삭제, merge/commit/push 수행 안 함. 공개 HTTPS GET 및 기존 세션 account GET만 읽었으며 인증 세션 생성/폐기 API를 실행하지 않았다.

추가 검토 한계: 회원 SQLite와 세션 SQLite는 별도 파일이며 DELETE 후 linked session revoke는 단일 다중 DB transaction이 아니다. 정상 삭제·Apple 실패 보존은 검증했으나 삭제 직후 프로세스 중단/세션 DB 오류 fault injection은 NOT RUN. 잔존 세션의 계정 조회는 회원 부재로 차단되지만 잔존 데이터 파기/복구 절차를 별도 검증해야 한다. SQLite DELETE는 활성 행의 논리 삭제 검증이며 WAL/파일 페이지/백업의 물리 흔적 삭제를 보장하는 테스트가 아니다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: build13 기능/가입 재인증 누락; 메뉴 통합 충돌; 고지 진입점 불일치; 파기/백업/최종 스토어 근거 부족
PRIORITY: P1 Release/개인정보 Gate
ROOT CAUSE: 분기된 소스 계열 및 활성 DB 삭제와 전체 보유/파기의 범위 차이
IMPLEMENTED: 읽기 전용 통합 시뮬레이션; 격리 SQLite 삭제 회귀; 고지/보유 대조; iOS opt-in 고정 HTTP 상태 export
CHANGED FILES:
  - lib/src/api/auth_diagnostics.dart
  - test/auth_diagnostics_test.dart
  - backend/test/release_gate_deletion.test.js
  - docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
TEST: backend454 PASS; 관련40 PASS; 격리SQLite1 PASS; Flutter164 PASS/1 SKIPPED; 진단ON4 PASS; analyze error/warning0 info17
BUILD: 기존 서명 iOS Release1.0.0(16)/codesign PASS; Android 추가 빌드 NOT RUN(iOS 전용 opt-in 변경)
DEVICE: iPhone16 무삭제 설치/실행 PASS; 업데이트 후 개인 기록 사용자 확인 대기
API: iPhone account200 두 건 확보; login/logout/delete NOT RUN(운영 변경 보류); 공개 policy GET 대조
CI: 'NOT RUN: 미커밋 후보'
COMMIT: 'NOT RUN: 사용자 보류'
PUSH: 'NOT RUN: 사용자 보류'
REMAINING RISKS: 소스통합; Apple 격리 실계정 E2E; 다중DB 장애; 로그/백업/usage 파기; 스토어 고지/SDK 일치
NEXT ACTION: 통합 범위 결정 후 별도 후보 검증; 실제 기간/운영 절차 및 격리 Apple 테스트 계정 환경 확정
```

### build16 후속 이상 보고
사용자가 iPhone build16의 로그인 상태·네이버 표시 이상을 보고했다. build16 설치/실행 및 account200 수집 결과와 구분하여 **실기기 로그인 상태 표시 검증 FAIL(사용자 관찰, 원인 조사 중)**로 기록한다. 기존 기록 이상은 아직 보고되지 않았으며 build16 기록 보존은 확인 완료로 간주하지 않는다. 실제 표시 문구 추가 확인 요청. 앱 삭제/초기화/로그아웃/회원탈퇴/운영 변경 없음.
- 후속 사용자 확인: ‘확인 중’은 20초 후 확인 불가 계열 문구로 바뀜. 따라서 영구 spinner로 확정하지 않으며 실제 계정 재확인 실패가 지속되는 상태다. ‘상태 다시 확인’ 재시도 후에도 ‘로그인 상태 확인 불가’라고 사용자 보고. 초기2건 account200 외 새 HTTP 응답 진단 없음. 특정 timeout/DNS/TLS 원인은 아직 미확정, 서버 세션 무효/기존 기록 손실로 단정하지 않는다.
- test/member_auth_controller_test.dart에 timeout 종료→세션 보존→재시도200 복구 회귀 추가. controller/menu10 PASS. 앱 제품 코드 변경/추가 설치 없음. Safari 공개 health GET으로 iPhone 연결 문제와 앱 요청 문제를 구분하는 확인 요청 중.
- iPhone Safari의 https://api.onaria.ai.kr/health는 정상 응답이라고 사용자 확인. 일반적인 API 접근 가능성은 확인됐지만 Safari와 앱의 연결 경로/캐시/요청 환경은 다르므로 앱 정상 통신으로 대체하지 않는다.
- 고정 실패 분류(timeout/network/tls/transport)만 추가 수집하도록 AuthDiagnostics 및 ProviderAuthApiClient 보완. 에러 원문·URL/headers/body/token 출력 없음. 임시64줄 whitelist에 분류 포함. 관련18 PASS. Release17 기존 서명 빌드 준비; product 로그인 상태 로직은 원인 미확정 상태에서 임의 변경하지 않음.

### build17 요청 실패 분류 준비 및 관찰
- Safari health 정상인데 앱 확인 불가가 지속되어, 전송 실패를 timeout/network/tls/transport로만 기록. API 예외는 그대로 rethrow하여 인증 판정/세션 보존 동작 유지. 고정 문자열 외 오류 원문·개인정보 없음.
- Flutter 전체166 PASS/1 SKIPPED, 진단/인증 관련18 PASS, analyze error/warning0 info17. 기존 서명·Bundle 검증/codesign 및 iPhone1.0.0(17) 무삭제 설치/실행 PASS.
- build17 실행 이후 account200 신규2건 관찰(파일의 기존 build16 2건과 합계4건). timeout/network/tls/transport 이벤트는 현재 수집 범위에 없음. 새 프로세스 실행 후 요청 성공만 확인했으며 build16 실패 원인을 확정하거나 제품 수정 완료로 표시하지 않는다.
- build17 메뉴 표시 및 재시도 사용자 확인 요청 중. build16 상태 확인 불가 FAIL 기록 유지. 로그아웃/재로그인/삭제/운영 변경/commit/push 없음.
- Android signed Release1.0.0(17) compile PASS(공통 API 실패 분류 영향 확인). 설치/기기 조작은 하지 않았다. 이번 코드/테스트 secret pattern 발견0, diff check PASS.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: iPhone build16 세션 재확인 실패; Safari health 정상
PRIORITY: P1 인증
ROOT CAUSE: 미확정; build16 후속 HTTP 응답 없음; build17 새 프로세스 GET200
IMPLEMENTED: 비밀없는 고정 전송 실패 분류 및 timeout/세션 보존/복구 회귀
CHANGED FILES: AuthDiagnostics, ProviderAuthApiClient, 진단/controller 테스트, 릴리스 문서
TEST: Flutter166 PASS/1 SKIPPED; 관련18 PASS; analyze error/warning0 info17; diff/secret pattern 검사 PASS
BUILD: iOS/Android signed Release1.0.0(17) PASS
DEVICE: iPhone17 설치/실행 PASS; 메뉴 사용자 확인 대기; Android17 설치 NOT RUN(컴파일 확인 범위)
API: iPhone17 account200 신규2건; 실패 분류 이벤트 미관찰; 운영 변경 API NOT RUN
CI: 'NOT RUN: 미커밋'
COMMIT: 'NOT RUN: 사용자 보류'
PUSH: 'NOT RUN: 사용자 보류'
REMAINING RISKS: build16 실패 원인 미확정; build17 사용자 표시/기록 확인 및 기존 Release Gate
NEXT ACTION: build17 메뉴 응답 확인 후 재현 시 고정 실패 분류 수집
```

### iPhone/Android 메뉴 차이 사용자 보고
사용자가 양 기기의 메뉴 차이를 보고하여 조사 재개. 실제 기기 조회: iPhone1.0.0(17), Android1.0.0(15). lib/features/account_menu.dart는 단일 공통 구현이며 Platform/defaultTargetPlatform 분기가 없다. 로그인 확인 상태에 따라 로그인/상태 다시 확인/계정 연결 항목이 조건부로 달라진다. 따라서 빌드 번호 차이만을 원인으로 단정하지 않는다. build17 iPhone 진단 파일 현재 account200 합계4건, 실패 분류 없음. 실제로 다른 항목·문구 사용자 확인 요청 중. 이번 확인에서는 설치/로그인/로그아웃/삭제/운영 변경 없음. 기존 기기 결과를 메뉴 동일성 PASS로 바꾸지 않는다.

### 제공 사진에 따른 양 기기 메뉴 대조
사용자가 제공한 Android 화면과 iPhone 사진을 직접 대조했다. 양쪽 모두 ‘로그인됨 · 네이버’, 로그아웃, 계정 관리, 계정 연결, 작은 성장 기록, 7일 마음의 여정, 말씀과 작은 기록, 십자가 미니게임, 알림 설정, 저장된 마음 카드가 같은 순서로 보인다. 메뉴 항목 누락이나 provider 표시 차이는 사진에서 관찰되지 않았다.
Android는 상대적으로 글자 크기가 커서 계정 관리 설명의 ‘개인정보’가 줄바꿈되며 sheet 높이/상단 여백도 다르게 보인다. 화면 논리 폭·글자 배율·기본 플랫폼 글꼴 등의 영향 후보이며 사진만으로 시스템 설정 원인을 확정하지 않는다. 접근성 글자 확대를 임의 비활성화하거나 사용자 시스템 설정을 변경하지 않았다.
iPhone 사진의 ‘로그인됨 · 네이버’ 표시는 현시점 회복의 사용자 제공 시각 근거다. 기존 build16 확인 불가의 원인은 여전히 미확정이고 사진만으로 재시도/재실행 안정성·개인 기록 보존을 PASS로 바꾸지 않는다. 소스/기기 설치/데이터/운영 변경 없음; commit/push 보류.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: Android 글자 크기/계정 관리 설명 줄바꿈 차이
PRIORITY: P2 메뉴 표시
ROOT CAUSE: 글자 배율·논리 폭·플랫폼 글꼴 영향 후보; 설정 직접 대조 미실행
IMPLEMENTED: 사용자 제공 사진의 항목/순서/인증 표시 대조 및 기록
CHANGED FILES: docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
TEST: 문서 diff check PASS; 코드 테스트 NOT RUN(문서만 변경)
BUILD: NOT RUN(코드 변경 없음)
DEVICE: 제공 사진에서 메뉴 항목/순서 동일 및 양쪽 네이버 로그인 표시 확인
API: 추가 호출 NOT RUN(사진 대조)
CI: NOT RUN(문서 검토)
COMMIT: NOT RUN(사용자 보류)
PUSH: NOT RUN(사용자 보류)
REMAINING RISKS: 배율/논리 폭 직접 확인; build16 실패 원인; 기록 보존 확인 및 기존 Gate
NEXT ACTION: 표시 차이의 원인 설정 대조 필요 시 접근성 확대를 보존하며 레이아웃 검토
```

### 메뉴 동일성 최종 사용자 확인
사용자가 ‘지금 변경되서 같아졌네’라고 확인했다. 현시점 iPhone/Android 메뉴 동일성은 사용자 관찰 PASS로 갱신한다. 제공 사진에서도 항목·순서와 네이버 로그인 표시가 일치했다. 추가 코드/설치/설정/데이터 변경은 수행하지 않았다. 이전 build16 세션 재확인 실패 원인 미확정 및 재실행 안정성/기록 보존 확인 범위, 기존 Release·정책 Gate는 유지한다. commit/push 보류 유지.

## 앱 정보 실제 설치 버전·빌드 표시 / build18 (2026-10-10)
사용자 승인 범위: 양 기기 build18 데이터 보존 설치, 앱 정보에서 실제 설치 버전/빌드 확인, 세션 GET만 점검. logout/relogin/account deletion/commit/push 보류. 기기 연결·잠금 해제 가능 사용자 확인.
- 기존 package_info_plus의 PackageInfo.fromPlatform()으로 설치된 native metadata(version/buildNumber)를 읽는다. pubspec 기본값·상수 대신 실제 runtime 값 표시. 메뉴 최상단 인증 상태 유지, 하단 ‘앱 정보’ → ‘버전 … · 빌드 …’. 대기/metadata 오류를 구분하고 추정 버전 fallback 없음.
- widget 테스트의 platform metadata를1.2.3/987로 지정하여 하드코딩 아닌 표시를 확인. 관련14 PASS. 초기 전체 테스트의 하단 스크롤 후 header offscreen 검사 실패는 테스트 viewport를 상단으로 복귀시켜 수정; 최종 전체 회귀 재실행 중. 제품 인증 코드 변경 없음.
- iOS1.0.0(18) 빌드/codesign/기존 인증서/Bundle 일치 PASS. Android 기존 installer 엔진으로 Release18 준비·설치 중.
- iPhone 실패 구분: (원인) build16 확인 불가의 timeout/DNS/TLS/전송 상세 원인은 아직 미확정; (수정) build17은 고정 실패 분류 진단 추가이며 해당 실패 원인을 수정한 것으로 표시하지 않음; (HTTP) build16 초기account200 두 건, 이후 실패 시 응답 미수집; build17 새 프로세스account200 신규두 건, 실패 분류 미관찰; (UI) 제공 사진/후속 사용자 확인에서 양 기기 네이버 로그인 표시·메뉴 동일성 회복. build18 HTTP 결과는 아래 별도 기록 예정.

### build18 최종 검증
- Flutter 전체 최종166 PASS/1 SKIPPED; 관련14 PASS; analyze error/warning0 info17. 초기 전체 실행은 viewport 관련 테스트1 FAIL이었고 수정 후 전체 재실행 PASS로 대체. backend 제품 변경 없음(이번 backend 전체 재실행 NOT RUN), 기존454 결과와 구분.
- iPhone 기존 서명 Release1.0.0(18) 설치/실행, devicectl 앱 목록 version1.0.0/bundleVersion18 확인 PASS. Android installer가 기존 package/인증서/version guard를 통과한 후 adb install -r 및 실행 PASS; 실제 versionName1.0.0/versionCode18. Android 최초 설치 시각2026-10-02 15:45:02 유지, 업데이트2026-10-10 11:53:28 KST.
- 사용자 확인: iPhone/Android 양쪽 메뉴 ‘앱 정보’에서 버전1.0.0·빌드18 표시, ‘로그인됨 · 네이버’, 기존 마음카드·기록 유지 모두 정상 → PASS(사용자 관찰). runtime 표시와 OS 설치 metadata를 대조함.
- Android 업데이트 이후 HTTP: 11:53:30/11:53:58 KST account200 관찰. iPhone build18 진단 baseline7행 대비 추가3행 모두 account200(확인된 build18 재실행·관찰 구간); 파일10행 전체 whitelist 검증. 이전 build16/17 이벤트와 구분하여 증분을 비교했으며 요청 원문/응답 body/token/header/credential 미수집. 관찰 구간 login/logout/signup/delete 이벤트 없음.
- 원인: build16 확인 불가의 정확한 전송 실패 원인은 여전히 미확정. Safari health 성공은 앱과 동일 연결 경로 증명이 아님. 실패 당시 상세 분류가 없어 timeout/DNS/TLS를 확정하지 않음.
- 수정: build17의 timeout/network/tls/transport 고정 분류 진단, timeout 세션 보존·재시도 복구 회귀 검증은 관찰력 개선이다. 원인을 해결하는 제품 로직 변경으로 표시하지 않음. build18 변경은 runtime 앱 정보 표시이며 세션 검증 로직 변경 없음.
- HTTP/현재 동작: build18 양 기기 GET200 및 사용자 로그인 표시 정상. 현재 정상 회복의 근거이며 이전 실패 원인 수정/완전 재발 방지 PASS와 구분한다.
- 실기기 logout/relogin/account deletion, 앱/기기 데이터 삭제·초기화, 운영 변경/배포/재시작, merge/commit/push 없음. 남은 소스 통합/삭제·파기·백업·스토어/콘텐츠 Gate 유지.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: 메뉴 실제 설치 버전·빌드 표시 부재; 과거 iPhone 세션 확인 실패 원인 미확정
PRIORITY: P1 인증 관찰 / P2 앱 정보
ROOT CAUSE: 앱 정보 runtime metadata 미표시; iPhone 과거 실패 원인은 미확정
IMPLEMENTED: PackageInfo native version/buildNumber 표시; 양 기기 Release18 무삭제 업데이트; GET 결과 및 사용자 표시/기록 대조
CHANGED FILES:
  - lib/features/account_menu.dart
  - test/account_menu_test.dart
  - docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
TEST: Flutter166 PASS/1 SKIPPED; 관련14 PASS; analyze error/warning0 info17; diff check PASS
BUILD: Android/iOS 기존 서명 Release1.0.0(18) PASS
DEVICE: 양 기기 앱 정보·네이버 로그인 표시·기존 기록 보존 사용자 확인 PASS
API: 양 기기 account GET200 확인; 인증 생성/폐기/회원삭제 요청 NOT RUN(사용자 보류)
CI: 'NOT RUN: 미커밋'
COMMIT: 'NOT RUN: 사용자 보류'
PUSH: 'NOT RUN: 사용자 보류'
REMAINING RISKS: 과거 iPhone 실패 원인 미확정; 기존 Release/정책 Gate
NEXT ACTION: 재발 시 고정 실패 분류로 원인 검증; 기존 Gate 별도 검토; 보류 유지
```

## build18 이후 Release Gate 재검증 및 로컬 최소 수정 (2026-10-10)

### 범위와 현재 상태
- PROJECT ONARIA, cwd /Users/ari/ARI/projects/onaria, branch codex/apple-android-20261006, HEAD 1aef3815c8e25022a948c4307e1c755e5cc8507b. 원격 ONARIA origin 확인 후 참조 fetch만 수행. main3fa97ca, HEAD 대비5 ahead/4 behind 유지. 다른 프로젝트·환경·DB·기존 포트 변경 없음.
- 시작 baseline /tmp/onaria-post18-gate-baseline.json:610파일 SHA256. 기존 dirty tree를 보존하고 merge/rebase/reset/stash/변경 폐기 없음.
- 실기기 설치 버전 읽기 전용 재조회: Android/iPhone 모두1.0.0(18). 기존 메뉴/로그인/앱 정보/기록 보존/GET200 PASS는 앞선 build18 사용자 검증과 HTTP 근거를 유지한다. 이번에는 앱 실행·설치·인증/삭제 조작 및 운영 인증 API 호출 없음.
- 아래 수정은 **build18 이후 로컬 소스**다. 검토용 build19의 Android signed Release compile / iOS Release no-codesign compile만 실행했고 미설치. 기존 build18 파일/운영 코드에 반영된 것으로 표시하지 않는다.

### 소스 통합 Gate 재검토
기준 main 변경95개 경로 중 현재 source와82개 byte 동일(이번 문서 후속 수정 시 달라질 수 있음). 누락0. merge-base c09844f 기준 텍스트 병합 시뮬레이션 충돌: backend/src/app.js, backend/src/website.js, lib/features/check_in_page.dart. 파일/내용 비교는 임시 파일 git merge-file -p이며 index/tree 변경 없다.
main 개인정보·Apple 철회·동의 변경 대부분은 이미 미커밋 tree에 반영돼 있다. 동일 기능을 main에서 일괄 가져오면 중복 또는 이번 탈퇴 장애 수정/메뉴 개선 손실 위험이 있다. branch의 auth/release commit 계열과 main의 squash/merge 계열은 commit 수가 기능 누락 수와 같지 않으므로 경로·내용 기준으로 비교했다.

build13 계열7ef71bb 대비 main 이후19개 경로 차이, 다음10개 파일이 현재 source에 없음: full_bible_ko/en assets, FULL_BIBLE_SEARCH/AUTO_DEV_LOG 문서, bible_search_page, full_bible_repository, build_full_bible_assets, bible_search_page/full_bible_search/signup_reauthentication 테스트. build13 전체검색·가입 재인증·전화번호 연결 안내·게임3초 변경은 현 build18 또는 오늘 변경으로 대체됐다고 표시하지 않는다. check_in_page 충돌은 검색 진입점과 공통 AccountMenuButton 변경을 함께 검토해야 한다. 버전 commit71611b7을 무조건 적용하면 소스 기본 버전과 설치 override 이력이 섞이므로 별도 검토 필요.

| 통합 필요 항목 | 근거 | 영향/의존성 | 상태 |
|---|---|---|---|
| main 개인정보/Apple/auth 기반 정합화 | 5/4 분기 및 대다수 파일 동일 | 기존 미커밋 작업 중복 제거 없이 별도 후보에서 검토; app.js/website/check_in 수동 대조 | BLOCKED: 검토 단계로 실제 병합 보류 |
| 2cc43ee 가입 재인증 | signup_reauthentication_test와 대응 복구 코드 누락 | 신규 가입 credential 거절 복구, provider별 회귀 필요 | FAIL: 최종 후보 기능 누락 |
| 5bb382a 전체검색 | corpus/repository/page/test 미존재 | asset 등록·오프라인 성능·출처·번역 권리·메뉴 통합 필요 | FAIL: build13 기능 누락 |
| e2d0470 연결 안내 / a3281e0 게임 간격 | 해당 source 및 test와 차이 | 앱+회원 DB 안내 문구, 게임 독립 회귀 | NOT RUN: 이번에 통합·행동 회귀하지 않음 |
| 오늘 탈퇴 장애 및 고지 수정 | 아래 격리 재현/수정 근거 | main app.js/website와 텍스트 충돌 추가; 현재 build18에는 미반영 | PASS: 로컬 회귀, 실제 통합은 NOT RUN |

가장 안전한 이후 작업은 보존된 현재 tree를 기준으로 별도 통합 후보를 구성해 main의 이미 반영된 변경과 추가 변경을 대조하고 필요한 build13 기능만 단계별 검증하는 것이다. 이번 작업에서는 후보 생성/병합/커밋도 실행하지 않았다.

### 현재 미커밋 변경의 기능별 분류
분류 시점의 84개 경로이며 기존 삭제 표시도 그대로 보존했다. 아래 전체를 이번 수정으로 간주하지 않는다. 테스트·문서·도구가 함께 미추적 상태이므로 제품 파일만 선택하면 필요한 의존성이나 회귀 근거를 누락할 수 있다.

- RAG/LICENSE (1): `assets/data/bible_verses_ko.json`

- AUTH/ACCOUNT backend (8): `backend/src/app.js`, `backend/src/auth/apple_android.js`, `backend/src/auth/member_session.js`, `backend/src/member_schema.js`, `backend/src/member_store.js`, `backend/scripts/migrate_optional_profiles.js`, `backend/src/auth/apple_revocation.js`, `backend/src/optional_profile_migration.js`

- BACKEND (4): `backend/src/conversation_service.js`, `backend/src/schema.js`, `backend/src/server.js`, `backend/src/website.js`

- TESTS (30): `backend/test/a_track_pilot.test.js`, `backend/test/app.test.js`, `backend/test/apple_android.test.js`, `backend/test/chat_integration.test.js`, `backend/test/conversation_service.test.js`, `backend/test/fixtures/cost_fixtures.js`, `backend/test/knowledge_rag.test.js`, `backend/test/onaria_web.test.js`, `backend/test/phase2_service.test.js`, `backend/test/phase3_agents.test.js`, `backend/test/production_corpus.test.js`, `backend/test/production_deployment.test.js`, `backend/test/religion_specialization.test.js`, `backend/test/vector_rag.test.js`, `test/conversation_examples_test.dart`, `test/conversation_lifecycle_test.dart`, `test/member_session_store_test.dart`, `test/provider_auth_api_client_test.dart`, `test/verse_speech_lifecycle_test.dart`, `test/widget_test.dart`, `backend/test/ai_consent.test.js`, `backend/test/apple_revocation.test.js`, `backend/test/optional_profile.test.js`, `backend/test/release_gate_deletion.test.js`, `test/account_menu_test.dart`, `test/ai_consent_test.dart`, `test/auth_diagnostics_test.dart`, `test/member_auth_controller_test.dart`, `test/privacy_account_deletion_test.dart`, `test/yuna_narration_voice_test.dart`

- STORE/RELEASE DOCS (10): `docs/STORE_SUBMISSION_CHECKLIST.md`, `ONARIA_CODEX_HANDOFF_2026-10-10.md`, `docs/APPLE_ACCOUNT_DELETION.md`, `docs/APP_STORE_CONTENT_RELEASE_GATE.md`, `docs/ONARIA_AGENT_TEAM.md`, `docs/releases/APP_STORE_BUILD_2026-10-07.md`, `docs/releases/APP_STORE_READINESS_2026-10-07.md`, `docs/releases/APP_STORE_SUBMISSION_PACKAGE_2026-10-07.md`, `docs/releases/GABIA_APPLE_DEPLOYMENT_2026-10-07.md`, `docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md`

- APP/UI (12): `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`, `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` [기존 삭제], `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` [기존 삭제], `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` [기존 삭제], `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` [기존 삭제], `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` [기존 삭제], `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `lib/app/mind_card_store.dart`, `lib/app/verse_narration.dart`, `lib/features/check_in_page.dart`, `lib/features/conversation_page.dart`, `lib/src/api/llm_models.dart`

- AUTH/ACCOUNT app (9): `lib/app/member_session_store.dart`, `lib/features/privacy_page.dart`, `lib/features/signup_page.dart`, `lib/src/api/member_api_client.dart`, `lib/src/api/provider_auth_api_client.dart`, `lib/app/ai_consent.dart`, `lib/app/member_auth_controller.dart`, `lib/features/account_menu.dart`, `lib/src/api/auth_diagnostics.dart`

- AGENT/TOOLS (10): `.codex/agents/backend_auth.toml`, `.codex/agents/coordinator.toml`, `.codex/agents/flutter_device.toml`, `.codex/agents/qa_security.toml`, `.codex/agents/scheduler.toml`, `.codex/agents/server_deploy.toml`, `.codex/agents/web_admin.toml`, `.codex/config.toml`, `.codex/onaria-schedule.json`, `scripts/onaria-agent.py`

인증/계정 변경은 DB schema·세션·Apple proof·앱 API 계약을 함께 검토해야 한다. AI 변경은 동의 차단과 Safety/modelCalls=0 회귀가 의존한다. iOS 시작 화면 삭제와 storyboard 변경은 기존 작업이며 이번에 복구·폐기하지 않았다. RAG corpus 변경은 인용 무결성·번역 권리 Gate와 별개로 검토해야 한다. 기존 에이전트/스케줄 파일은 실행하거나 상시 작업으로 등록하지 않았다.

### 회원탈퇴: 격리 재현, 수정, 남은 범위
모든 삭제는 테스트가 생성한 임시 SQLite DB와 가짜 계정/세션에서만 수행했다. 실제 provider 요청·운영 DB·실기기 탈퇴 없음.
- 수정 전: 회원을 먼저 지운 다음 세션 철회에 실패하면 회원은 이미 없어졌다. 회원 DB 실패는 일반 AI 오류 응답으로 전달돼 탈퇴 안내와 불일치했다. 장애 주입 3건 중 2건 실패로 재현.
- 로컬 수정: `backend/src/app.js`에서 연결된 인증 수단과 호출 세션 철회를 먼저 수행하고 회원/연결 정보를 삭제한다. 저장소 오류는 비밀정보 없는 고정 로그와 HTTP503 및 일부 로그인 해제 가능 안내로 처리한다. 입력/인증 오류는 기존 계약을 유지한다.
- `lib/features/privacy_page.dart`: DELETE 요청 이후 오류는 처리 결과 확인 불가로 안내한다. 응답 유실 시 실제 삭제가 끝났을 가능성을 부정하지 않는다. 요청 전 본인확인 오류 및 서버 성공 후 로컬 회원 번호 정리 실패는 구분한다.
- 정상 삭제: 회원/연결 정보 제거, 모든 연결 수단의 기존 세션 GET401, 기존 DELETE401, 기존 identity 로그인404. 다른 테스트 회원과 세션 보존 PASS.
- 세션 저장소 일부 실패: HTTP503, 회원/연결 정보 보존, 이미 철회된 세션과 남은 세션의 실제 상태 및 안내 일치 PASS. 장애 해소 후 재시도204 PASS.
- 회원 저장소 실패: HTTP503, 회원/연결 정보 보존, 기존 세션 GET401, 다른 회원 보존 PASS. 테스트용 새 본인확인 세션으로 재시도204 PASS.
- Apple 철회는 모의 외부 응답/실패 테스트를 포함하지만 실제 Apple 테스트 계정의 격리 환경 E2E는 NOT RUN. 외부 grant 철회 후 DB 실패는 외부 철회를 되돌리지 못한다. 별도 DB 간 원자적 transaction 및 프로세스 강제 종료 복구는 미검증이다.
- 마음카드·초안·말씀·여정 등 기기 기록은 기존 동작대로 별도 삭제 기능 대상이며 탈퇴가 자동 삭제하지 않는다. 비용 원장에는 탈퇴 시 삭제 연결이 없다. 원장 식별자와 회원 provider identity가 동일하다고 추정하지 않았다.
- 삭제 이전 SQLite 백업을 별도 테스트 경로에서 다시 열면 삭제된 회원이 나타남을 확인했다. 백업 만료/복원 후 삭제 재적용 설계와 실행 근거 부재. SQLite 논리 행 삭제가 WAL·백업·물리 흔적의 안전한 소거까지 입증하지 않는다.

### 기본 보유기간 1년 대조
**RETENTION GATE: FAIL.** 기본 1년은 목표 기준이며 현재 전체 자동 파기의 구현·실행 근거가 없다. 아래 기존 TTL을 법적 예외로 승인된 기간이라고 표시하지 않는다.

| 데이터 | 시작점/현재 기간 | 만료·삭제 실행 | 확인 및 남은 작업 |
|---|---|---|---|
| 회원 프로필·동의·provider 연결 | created_at/updated_at 존재; 어느 시점을 1년 기산점으로 할지 미확정 | 자동 만료·정기 파기 작업 없음 | 1년 초과 테스트 회원 잔존 확인; 기산점·연장 조건·본인확인 삭제 및 파기 구현 필요 |
| 인증 세션 | 발급 시각 기준 기본30일 | 발급/조회 등 호출 시 정리; 정기 작업 없음 | 1년 경과 행은 호출 전1개, 만료 검증 거절 후0개; 접근 차단과 저장 파기 구분 |
| AI 비용/사용량 원장 | 요청 시각; 기본62일, 설정32~366일 | 원장 호출 시 만료 정리; 독립 정기 작업 없음 | 호출 전 만료 행1개, overview 후0개; pending 처리·실제 실행 설정·기간 근거 검토 필요 |
| 기기 개인 기록/동의 표시 | 저장 시점; 일괄 만료 없음 | 사용자 별도 삭제 | 앱 탈퇴와 독립; OS 백업 및 보유 예외 설명·실제 처리 검증 필요 |
| 웹 의견/집계 | 프로세스 메모리, 제한된 식별·집계 | 재시작/자료구조 제한 | 원문/IP 저장을 직접 확인한 구현과 인프라 로그를 구분; 전체1년 파기 증명 아님 |
| DB 백업·접근/운영 로그 | 백업/로그 생성 시점; 정책·실행 미확인 | 실제 작업·복원 후 삭제 재적용 미확인 | 격리 백업에서 삭제 회원 복원 확인; 운영 읽기 설정 감사 및 별도 예외 근거 필요 |
| 외부 provider/AI 서비스 | 외부 전송/계약 기준 | ONARIA DB 삭제와 독립 | 외부 보유·철회·삭제 계약/설정 확인 필요 |

격리 증거 `/tmp/onaria-post18-retention-results.json`: 1년 초과 회원 잔존=true, 세션 만료 접근 차단=true, 호출 기반 원장 정리 확인, 삭제 전 백업에서 회원 조회=true. 운영 파기 실행·cron/스케줄 등록·보유기간 임의 변경 없음. 기산점/법정 예외/백업 기간은 사실값 확정 후 구현해야 하므로 추측해서 문서에 1년 완료를 선언하지 않았다.

### 개인정보·스토어: 실제 흐름과 고지 대조

| 흐름 | 구현 근거와 실제 처리 | 고지/수정안 및 Gate |
|---|---|---|
| 소셜 로그인·프로필 | member_schema/member_store 및 auth: provider/sub, 선택 이름·전화·교회, 동의 버전/시각을 회원 DB에 저장; provider 증명 확인에는 외부 요청 사용 | 필수/선택 항목 및 provider별 SDK 수집을 제출 자료와 최종 archive 기준으로 대조; SDK가 이메일·기기 정보 등을 전혀 수집하지 않는다고 단정 금지 |
| 세션 | member_session: 토큰 원문 대신 해시 및 provider 식별·발급/만료 정보 | 세션30일과 회원1년 목표를 구분하고 호출 기반 정리/백업 범위 명시 |
| AI 대화 | conversation_service/schema: 입력·감정·강도·최근 맥락·요약·선택 말씀/종교 등; 앱 AiConsent의 허용 버전 필요 | 자유 입력 개인정보 포함 가능성 및 목적/항목/거부 경로 명시. 이름/전화/회원 token을 자동 덧붙이지 않는 구현과 입력의 비식별 보장은 다름 |
| 외부 AI·검색 | 허용/설정이 충족되면 OpenAI 호출, 검색 설정에 따라 embedding 가능; openai_service는 store:false | store:false를 외부 보유0일로 설명 금지. 실제 운영 활성 설정·처리국/수탁자·계약 보유/삭제·국외이전 사실값 확인 필요 |
| 로컬 개인 기록·음성 | 카드/초안/여정/말씀은 기기 저장, 별도 삭제. ONARIA의 음성 파일 저장 경로와 OS 음성 처리 서비스는 구분 | 탈퇴 후 기기 기록 잔존 안내와 OS 백업/음성 provider 사실 확인 필요 |
| 사용량/관측/웹 | 비용 원장은 해시 식별·시각·모델/사용량 등; 웹 집계/의견은 제한된 메모리 자료. dormant memory_store를 활성 서버 대화 저장이라고 보고하지 않음 | 실제 proxy/APM/운영 로그·보유·백업은 미확인; 서버가 대화 원문을 전혀 보유하지 않는다고 확대 해석 금지 |
| 회원탈퇴 동선 | 계정 관리 → 회원탈퇴, 별도 연결 관리 | website의 이전 ‘개인정보·회원탈퇴’ 진입 문구를 실제 ‘계정 관리’로 로컬 수정하고 웹 테스트 추가. App Store 리뷰 안내도 동선 수정; 외부 공개 페이지는 배포 전 상태 |
| 1년 기준 | 전체 자동 파기 미구현; 현재 정책은 미구현 사실을 밝힘 | 미구현 사실 고지는 정직하지만 목표 기준 충족은 아님. 구현·실행·예외를 확정하기 전 완료/자동파기 보장 문구 금지 |

공개 개인정보/삭제 페이지는 HTTPS GET200으로 읽기만 확인했다. 공개된 페이지와 로컬 수정본을 구분하며 게시/운영 배포 없음. 이메일 삭제 요청 접수·본인확인·관련 기록 처리의 실제 업무 흐름은 NOT RUN. 스토어 콘솔 최종 답변과 실제 SDK/archive 대조는 외부 계정/사실 확인이 없어 BLOCKED.
‘런칭 후 6개월’은 내부 도입 검토 기준으로 유지하고 확정된 외부 전송 날짜로 고지하지 않는다. 새 법적 사실값/전송 시점/보유 예외를 만들어 넣지 않았다.
Apple의 수집 판단은 기기 밖 전송 및 보유와 제3자 처리를 포함하므로 최종 SDK 흐름까지 대조해야 한다([Apple 공식 안내](https://developer.apple.com/app-store/app-privacy-details/)). Google의 계정 삭제 요구사항과 앱 외부 요청 경로는 [Google 공식 안내](https://support.google.com/googleplay/android-developer/answer/13327111)를 기준으로 기존 제출 자료와 함께 검토한다. 외부 제출/고지 확정은 NOT RUN.

### 검증 결과와 설치본 구분
- backend 전체456 PASS; 탈퇴 장애/웹 관련 최종13 PASS. Flutter 전체166 PASS/1 SKIPPED, 탈퇴 관련9 PASS. analyze 오류0/경고0/info17.
- Android 기존 인증서 signed Release1.0.0(19) 빌드 PASS, iOS Release1.0.0(19) no-codesign 컴파일 PASS. iOS 배포 서명/스토어 검증은 NOT RUN. build19는 검토용 로컬 산출물이고 양 기기 설치는 여전히 signed Release1.0.0(18).
- 기존 build18 양 기기 표시/기록 보존과 세션 GET200은 앞선 관찰 근거다. 이번 작업은 설치 버전 읽기만 수행했고 추가 실기기 인증 GET/로그아웃/재로그인/탈퇴 없음.
- 과거 iPhone 실패 **원인: 미확정**. **수정: 이전 고정 진단 분류 추가, 이번에 인증 수정 없음**. **HTTP: 앞선 build18 account200; 실패 당시 응답 미수집**. 재발 시 고정 단계와 status 또는 timeout/network/tls/transport만 수집하며 요청/응답 원문·토큰·개인정보를 출력하지 않는다.
- 로그: `/tmp/onaria-post18-backend-final.log`, `/tmp/onaria-post18-fault-web-final.log`, `/tmp/onaria-post18-flutter-full.log`, `/tmp/onaria-post18-flutter-related.log`, `/tmp/onaria-post18-analyze.log`, `/tmp/onaria-post18-android-compile.log`, `/tmp/onaria-post18-ios-compile.log`. 임시 파일은 영구 증거 보관소가 아니므로 핵심 결과를 이 문서에 기록했다.

| Gate | 상태 | 근거 |
|---|---|---|
| 기존 데이터/미커밋 보존 | PASS | baseline 대조, 운영/실기기 삭제 없음, 설치18 유지 |
| 소스 통합 | FAIL | build13 기능 누락 및3개 main 충돌; 실제 병합 NOT RUN |
| 탈퇴 로컬 기능·부분 실패 | PASS | 격리204/401/503·재시도·다른 회원 보존 및 앱 안내 회귀 |
| 탈퇴 관련 기록/백업 포함 전체 범위 | FAIL | 비용 원장 삭제 연결 및 백업 복원 후 삭제 재적용 부재 |
| 실제 Apple 격리 계정 E2E | BLOCKED | 외부 테스트 계정/격리 서비스 준비 미확인; 모의 검증과 구분 |
| 기본1년 보유·자동 파기 | FAIL | 회원 만료/정기 작업/백업 정책·실행 근거 부재 |
| 개인정보/스토어 최종 일치 | FAIL | 전체 파기 기준 미충족·관련 기록 범위 및 실제 SDK/국외이전/로그 사실 미확정 |
| 스토어 콘솔/운영 설정 사실 대조 | BLOCKED | 외부 계정 및 실제 설정 증거 미확보 |
| 현재 기기 build18 | PASS | 앞선 사용자 검증/GET200, 이번 metadata18 재확인 |
| 새 로컬 소스 배포/실기기 검증 | NOT RUN | 사용자 범위에 따라 미설치·미배포 |
| CI/커밋/푸시/스토어 제출 | NOT RUN | 미커밋 및 사용자 보류 |

자동 진행 가능한 다음 작업: 별도 후보의 기능별 통합 검토, 확정된 보유 기준에 대한 dry-run/격리 파기·복원/재시도 테스트, 관련 기록 연결 설계, 실제 설정의 비밀정보 없는 읽기 감사. 실제 병합은 이번 검토 범위에서 실행하지 않았다.
사용자 사실 확인/조작이 필요한 항목: 1년 기산점·별도 보유 예외 근거·백업 기준, 외부 서비스 계약/처리국과 지원 요청 담당·본인확인 흐름, 스토어 콘솔 최종 항목, 실제 Apple 테스트 계정과 격리 환경 준비. 운영 변경·배포·스토어 제출·커밋·푸시는 계속 보류한다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: 소스 누락/충돌; 탈퇴 부분 실패 처리; 1년 자동 파기 및 관련 기록/백업 처리 미완성
ROOT CAUSE: 회원 삭제가 세션 철회보다 먼저 실행됨; 분기된 소스 이력; 파기/복원 실행 경로 부재
IMPLEMENTED: 격리 장애 재현 및 탈퇴 순서/오류 안내 최소 수정; 실제 메뉴 동선 고지 수정; Gate 증거 기록
CHANGED FILES:
  - backend/src/app.js
  - backend/src/website.js
  - backend/test/release_gate_deletion.test.js
  - backend/test/onaria_web.test.js
  - lib/features/privacy_page.dart
  - test/privacy_account_deletion_test.dart
  - docs/STORE_SUBMISSION_CHECKLIST.md
  - docs/releases/APP_STORE_SUBMISSION_PACKAGE_2026-10-07.md
  - docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
TEST: backend456 PASS; Flutter166 PASS/1 SKIPPED; analyze 오류/경고0(info17)
BUILD: Android signed Release19 PASS; iOS Release19 no-codesign compile PASS; 미설치
DEVICE: 양 기기1.0.0(18) 유지; 추가 인증/삭제 조작 NOT RUN
API: 격리 탈퇴204/기존 세션401/장애503 PASS; 운영 인증 요청 NOT RUN; 이전 build18 양 기기 GET200
SOURCE INTEGRATION GATE: FAIL — 기능 누락/충돌; 통합 NOT RUN
ACCOUNT DELETION GATE: FAIL — 로컬 기능 PASS; 관련 기록/백업 미완성; 실제 Apple 격리 E2E BLOCKED
RETENTION GATE: FAIL — 기본1년 자동 파기·정기 실행·백업 근거 부재
PRIVACY / STORE GATE: FAIL — 파기 범위 미완성; 실제 SDK/운영 사실·콘솔 대조 BLOCKED
CI: NOT RUN — 미커밋
COMMIT: NOT RUN — 사용자 보류
PUSH: NOT RUN — 사용자 보류
REMAINING RISKS: 분리 DB/외부 철회 비원자성; 백업 복원; 미통합 기능; 과거 iPhone 실패 원인 미확정
NEXT ACTION: 소스 통합 후보 검토 및 보유 기준/관련 기록 설계 확정 후 격리 회귀; 보류 유지
```

최종 보존/문서 점검: 시작 baseline610개 중 이번 변경9개만 확인, 새로 사라진 파일0. git diff --check PASS. 이번9개 파일의 private-key/OpenAI-key/GitHub-token/AWS-key 패턴 검사 검출0(값 출력 없음). 이 검사는 알려진 패턴 점검이며 모든 개인정보 부재를 보증하는 전체 보안 감사와 구분한다. 기존 미커밋 변경/삭제 상태 보존.

## 남은 Release Gate 해결 준비 — 통합 후보·보유 기준·복구 설계 (2026-10-10)

### 기준 재확인 및 이전 표기 정정
cwd/프로젝트 ONARIA, branch codex/apple-android-20261006, HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b 유지. **로컬 main은 ae999eae6f548ad47e7d9d36b384dca97b18c148이며 HEAD 대비4 ahead/0 behind**다. 앞선 ‘main3fa97ca/5 ahead4 behind’는 정확히 **origin/main3fa97ca65f3c24329a22e8f3e66504e670d2f6c9**를 지칭한다. 이번에는 기존 원격 참조 기준으로 비교했으며 추가 fetch/CI 조회는 NOT RUN. 기존 미커밋 삭제·수정은 보존하고 병합/리베이스/폐기/기기 설치/운영 접근을 하지 않았다. 현재 기기 build18을 유지한다.

### 기능별 통합 후보와 선택 기준
아래는 적용 계획이며 실제 통합 완료가 아니다. 앞선 충돌 시뮬레이션은 origin/main 기준이다. 미추적 파일을 포함한 현재 tree를 통합 후보의 기반으로 보존한다.

| 후보 | 누락·충돌 파일/참조 | 유지할 구현과 선택 근거 | 검증 계획 |
|---|---|---|---|
| 인증 세션·메뉴·앱 정보 | app.js, check_in_page.dart 충돌; member_auth_controller/account_menu/auth_diagnostics 미추적 | 현재 generation 보호·실제 세션 GET·실제 runtime 버전·직접 로그아웃/별도 탈퇴 동선 유지. main의 오래된 메뉴/세션 구현으로 되돌리지 않음 | controller 늦은401/timeout·재시도·재실행, 메뉴 metadata·provider·접근성 테스트; 기기 조작은 별도 승인 범위 |
| 회원 schema·선택 프로필·Apple 탈퇴 | app.js 충돌; apple_revocation/optional_profile_migration 및 test 미추적 | 선택 입력·fresh Apple proof·철회 우선/회원 삭제 후속·부분 실패 안내 유지. DB migration은 후보에 포함하되 운영 실행 금지 | 임시 SQLite schema 이전/identity cascade, Apple mock 성공·외부 실패, 장애 재시도·세션401 |
| 웹/스토어 고지·AI 동의 | website.js 충돌; ai_consent와 관련 test 미추적 | 현재 실제 계정 관리 동선·동의 거부 시 외부 호출 차단·미구현 파기 사실 고지 유지 | 웹 문구/CSRF/cache/API 계약, 동의 철회, crisis modelCalls/client 생성0 회귀 |
| 가입 재인증·전화번호 연결 안내 | 2cc43ee/e2d0470; signup_reauthentication_test.dart 누락, signup_page.dart/member_store.js 차이 | 현재 선택 프로필·동의·연결 계약에 재인증 복구를 이식하는 후보. 두 파일 전체 교체 금지 | credential 만료/취소·기존 전화 충돌·중복 identity·기존 회원 추가 입력 없음 |
| 전체 성경 검색 | 5bb382a; full_bible_ko/en.json, repository/page/asset 생성 script, 검색 test 및 문서 누락; check_in_page.dart 충돌 | 검색 repository/page 후보를 추가하되 공통 메뉴 유지. corpus 출처/번역 권리 통과 전 배포 자산 포함 보류 | asset 등록·오프라인 검색/Unicode·용량/성능·출처/라이선스·인용 무결성 |
| 게임 간격·음성·시작 화면 | a3281e0 게임 변경; verse_narration/mind_card/LaunchScreen/기존 LaunchImage 삭제 등 현재 변경 | 기능별 비교 후 선택; 기존 음성 lifecycle 및 사용자 기록 보존. 시작 화면 삭제는 관련 storyboard와 한 묶음으로 검토 | 게임3초 경계, speech 취소/dispose, 기기 기록 deserialize, iOS 시작 화면 compile |
| 버전·서명 | build13 버전71611b7와 pubspec 기본값 차이 | 1.0.0+13 배포 이력 및18 설치 override 유지; pubspec 임의 변경/빌드 하향 금지 | 후보 build번호18 초과, 실제metadata·인증서/package 확인; 이번 설치 NOT RUN |

중복 판단은 commit 제목이 아니라 파일 내용·API 계약·회귀 결과로 한다. main의 이미 반영된82개 경로는 이전 비교 시점 근거이며 오늘 문서/모의 모듈 추가 후 정확한 byte 동일 개수는 재산출하지 않았다. 통합 최종 선택은 위 조건을 만족한 후보 diff를 보고한 뒤 진행한다.

### 데이터별 보유·파기 기준표
1년은 사용자 지정 기본 기준이다. **기산점과 연장/예외가 미정이면 자동 삭제 기준으로 확정하지 않는다.** 다음 표는 실제 구현, 목표, 미정 사실을 분리한다.

| 데이터·수집 목적 | 보유 기산점 | 1년 적용 | 탈퇴 처리 | 별도 보유 예외 | 백업 및 근거 |
|---|---|---|---|---|---|
| 회원 이름/전화/교회·provider identity: 계정·연결·선택 프로필 | 생성/수정 시각 존재; 가입일/최종활동일 중 정책 선택 미정 | 기본 대상 후보, 기산점·자동 만료 미확정 | 로컬 DELETE 회원 및 연결 cascade; 이전 수정본 미배포 | 분쟁/의무 보유가 필요한 항목·근거·기간 미정, 임의 법정기간 없음 | members.sqlite/WAL/스냅샷; 기간·복원 재적용 미구현 |
| 약관/개인정보 동의 증거: 동의 확인 | consented_at | 적용 여부/별도 증명 보유 근거 미정 | 현재 회원 행과 함께 삭제 | 동의 증명 보유 필요성과 최소 필드/기간 확정 필요 | 회원 백업과 동일 |
| 세션 hash/provider: 인증·접근 제어 | 발급; expires_at은 실제 TTL | 현재30일 만료가 있으나 독립 정기 파기 없음; 1년까지 연장하지 않음 | 연결 수단별 철회 및 기존 접근 차단 | 보안 조사용 별도 보유 승인 없음 | 별도 session DB/WAL; 복원 시 재철회 필요 |
| AI 비용 원장/모델/해시 식별: 예산·운영 관측 | request timestamp | 현재기본62일 설정32~366일; 기본1년 기준과의 관계/예외 승인 미정 | 회원과 연결 mapping 및 삭제 경로 부재 | 회계 자료라는 이유만으로 법정기간을 추정하지 않음; pending 정산·익명화 근거 필요 | cost DB/WAL; salt·식별 연결과 백업 처리 설계 필요 |
| 대화 요청/최근 맥락: 답변 생성 | 요청/외부 전송 | ONARIA 지속 원문 저장 경로 미확인; provider 보유 별도 사실 필요 | 외부 요청 철회/삭제 지원 여부 미정 | provider 계약·보안 로그 보유 미정 | proxy/APM/외부 서비스 백업 확인 필요; store:false는0일 증명 아님 |
| 카드·초안·말씀·여정: 사용자가 저장한 개인 기록 | 기기 저장; 일괄 만료 없음 | 1년 기기 적용 여부 미정 | 현재 자동 삭제 없음, 별도 삭제 제공 | 사용자 보존 선택의 범위/동의 및 탈퇴 후 안내 확정 필요 | OS backup 포함 여부·restore 삭제 정책 미확인 |
| AI 허용 버전/로컬 회원 metadata: 허용 확인·UI | 버전만 저장하는 항목 존재; 시각 미저장 | 기준 미정 | 회원 번호 정리, AI 동의/기기 기록은 별도 | 기간·계정과의 연결 미정 | 기기 백업 확인 필요 |
| 웹 의견·집계: 개선/운영 | 메모리 수신/프로세스 | 프로세스 수명·자료구조 제한; 1년 작업 없음 | 현재 회원 identity로 연결되지 않음 | 식별 불가능한 집계라는 판단과 원문/식별 흐름 실제 검토 필요 | 운영 로그와 구분, 인프라 보유 확인 필요 |
| 접근/보안/관리자 로그: 감사·장애 대응 | 이벤트 발생 | 실제 설정 미확인 | 연결 가능 기록·익명화 정책 미정 | 보안/분쟁 예외의 근거·기간 미정 | journald/proxy/APM/백업 실제 읽기 감사 필요 |
| 삭제 작업·삭제 증명/복원 제외 명부: 재시도·재등장 방지 | 삭제 요청/완료 | 신규 설계의 기간 미정 | 최소 식별/처리 결과만 분리 보관하는 후보 | 삭제 증명을 무기한 보관한다고 확정하지 않음 | 운영 DB 백업과 독립, 최대 백업 수명+검증 범위를 정책으로 확정 필요 |

확정에 필요한 질문: 회원1년의 기산점(가입/최종활동 등), 동의 증거/사용량 예외의 실제 목적과 근거, 사용자 기기 기록 보존 의사, 백업 최대 수명과 삭제 증명 보유 기간. 근거가 없는 항목을 에이전트가 법적 사실로 확정하지 않는다.

### 탈퇴·파기 구현안 — 아직 운영 코드 미구현
1. 본인확인 직후 계정별 삭제 요청 UUID와 정책 버전/접수 시각을 transaction으로 저장하고 계정을 deleting 상태로 전환한다. 인증 GET·발급·연결·AI 회원권 경로에서 같은 상태를 확인해 접근을 차단한다. 기존 세션 DB만 지우는 것으로 동시 신규 세션 발급을 막았다고 보지 않는다.
2. 단계별 작업은 세션 차단 → 외부 철회 → 회원/identity 삭제 → 관련 원장/연결 가능한 기록 처리 → 백업 제외 명부 기록 → 완료로 구성한다. 파기와 익명화 중 선택·기산점·예외가 확정되지 않은 관련 데이터 단계는 blocked로 남긴다. 전체 범위 완료 전 완료204를 반환하는 계약 변경은 기존 앱 호환성 검토가 선행돼야 한다.
3. durable outbox에 고정 provider/job stage와 재시도 시각/횟수/결과 코드만 저장한다. token 원문을 일반 job/log에 넣지 않는다. Apple 단기 authorization code를 장기 재시도에 재사용할 수 있다고 가정하지 않는다. 재철회 가능한 자격의 암호화 보관·수명·사용 권한을 확정하거나 사용자 재본인확인이 필요한 상태로 구분한다.
4. 일시적 네트워크/429/5xx는 제한된 지수 backoff 후보, 자격 거절은 재본인확인 또는 담당자 확인으로 구분한다. ‘이미 철회됨’을 성공으로 처리할 수 있는 응답은 provider 공식 계약 검증 후 whitelist한다. retry 횟수·기간은 미정이며 무한 재시도 없음.
5. job(account, deletion generation, stage) unique 및 transaction lease/compare-and-set으로 중복 실행을 막는다. 완료 단계는 재실행하지 않고 삭제된 행 재삭제는 no-op로 처리한다. crash 후 lease 만료와 마지막 durable checkpoint부터 재개한다. 별도 DB/외부 호출을 하나의 원자 transaction이라고 표현하지 않는다.
6. 이전 계정과 나중의 재가입 계정을 분리하는 identity generation/삭제 시각 경계를 사용한다. tombstone을 provider 식별자만으로 적용하면 합법적 재가입까지 영구 차단할 수 있어 금지한다. 최소 HMAC 식별자의 키 보관·교체·명부 보유기간·PII 해당성은 별도 정책/보안 검토한다.
7. 백업 복원은 외부에 공개하기 전에 독립 삭제 명부/완료 watermark를 대조하여 회원·세션·원장 및 WAL/스냅샷 대상에 삭제 상태를 재적용하고 검증한다. 명부가 없거나 stale이면 restore를 차단한다. 이후 접근 차단/재가입 generation 보존을 확인한 뒤 서비스 연결한다. 백업 자체의 만료 파기와 이 복원 절차를 모두 검증한다.
8. 정기 작업은 정책 버전·고정 UTC 시각·chunk/cursor·lease로 모의 계획을 먼저 생성한다. 결과는 종류별 건수/차단 사유만 보고한다. 임계 건수·동시성·재시도·운영 적용은 다음 별도 검증/승인 경계이며 이번 cron 등록/삭제 executor 구현 없음.

검증 계획: 모든 단계의 저장소/외부 오류·응답 유실·강제 종료·동시 요청·중복 job·retry 후 복구·새 identity 발급 경합을 임시 DB로 검증. 백업은 삭제 전 스냅샷 복원 후 기존세션401/회원 부재/관련 기록 처리/재가입 보존을 검증. 실제 external Apple 테스트와 모의 응답을 구분한다.

### 이번 로컬 구현 완료: 삭제 기능 없는 보유 모의 계획
`backend/src/privacy/retention_plan.js` 추가. 파일/DB/네트워크 접근, default DB 경로, 삭제 함수, cron 등록이 없는 순수 함수다. production app/server에서 import하지 않았다.
- 기존 session expires_at <= now 대상, 비용 원장의 실제 전달받은 retentionDays(32~366)와 timestamp < cutoff 대상만 건수로 산출한다. 62일은 현재 기본값이지 승인된 별도 예외라는 선언이 아니다.
- 비용 pending은 reservation 복구 확인이 선행되므로 blocked. 회원/백업/기기 기록은 기산점 미정으로 전부 blocked. 날짜/설정 오류는 거절 또는 invalid로 분류한다.
- 반환은 scanned/candidates/retained/blocked/invalid 집계만 포함한다. 개별 개인정보·token·ID·파기 실행 목록은 출력하지 않는다. 모의 결과가 실제 파기 완료라는 의미가 아니다.
- `backend/test/retention_plan.test.js`: 세션 경계·원장 strict 경계·pending·미정1년 차단·잘못된 설정/날짜·개인정보 미노출·입력 불변/반복 결과 검증5 PASS. fixture는 메모리 안에서만 생성하며 사용자 DB 접근 없음.
- fixture 모의 결과: 세션2건 중 후보1/유지1; 원장3건 중 후보1/유지1/pending 차단1. 회원/백업/기기 기록은 종류별1건 차단. 실제 정기 파기/삭제 복구 outbox/tombstone/migration은 **미구현**.

### BLOCKED 사유와 필요한 사용자 조작
| 항목 | 차단 사유 | 필요한 구체적 조작/증거 | 자동 작업 범위 |
|---|---|---|---|
| 실제 Apple 탈퇴 E2E | 격리 backend/DB 및 삭제 가능한 테스트 Apple identity가 확정되지 않음; 운영/실기기 탈퇴 금지 | 별도 테스트 계정과 격리 환경 지정, 해당 테스트 계정의 Apple 본인확인 직접 수행. 기존 사용자 계정 사용 금지 | mock 철회/장애·세션/복구 테스트 계속 가능 |
| Apple 재시도 자격 | authorization code 수명·재철회 자격/보관 계약 미확정 | 외부 서비스 설정·허용된 자격 수명 확인; 비밀값은 채팅 제공 금지 | 고정 오류 분류와 모의 backoff 설계 가능 |
| SDK/최종 제출 archive | 검토 소스와 최종 배포 archive/SDK 활성 설정이 같다는 증거 없음 | 최종 서명 archive 및 SDK 목록/설정 제공 또는 로컬 파일 경로 지정; 플랫폼 설정 본인 로그인 | 공개 metadata·manifest/권한·버전 정적 대조 가능 |
| 운영 데이터 흐름 | 실제 AI 활성/provider region·로그·백업/파기 작업 설정 미확보 | 기존 운영 읽기 경로 지정, 담당자의 비밀정보 제외 설정/계약·리전/보유 증거 확인 | 승인된 읽기 접근 시 안전한 whitelist 요약; 설정 변경 없음 |
| Apple App Privacy/Play Data Safety | 현재 콘솔 최종 답변/변경 이력 미확보 | 각 콘솔에서 본인 로그인 후 수집/목적/연결/공유·삭제 항목의 최신 답변을 확인 가능한 자료로 제공; 제출 버튼 누르지 않음 | 실제 코드 흐름과 제출 전 후보표 작성 가능 |
| 지원 요청·보유 사실 | 삭제 이메일 접수/본인확인 담당·기산점/예외/백업 기준 미정 | 실제 담당/연락 경로·처리 절차 및 기준 확인; 개인정보 포함 자료는 제거 | 정책 버전/실행 설계·격리 테스트 준비 가능 |

이번에 사용자 조작이 필요한 질문을 반복하거나 운영 변경 승인을 요청하지 않았다. 위 항목은 사실 확인·테스트 환경 준비를 위한 구체적 목록이며 기존 보류를 해제하지 않는다. 과거 iPhone 실패 원인 미확정과 고정 HTTP 진단 범위 유지.

### 이번 검증과 최종 상태
- 모의 계획5 PASS; backend 전체 **461 PASS/0 FAIL**. 최초 sandbox 실행은 loopback HTTP listen 제한으로 실패했고 환경 권한을 부여한 동일 전체 재실행은 통과했다. 최종 로그 `/tmp/onaria-release-preparation-backend-final.log`.
- 신규 모듈/test node --check 및 git diff --check PASS. 앱 코드·연결·설치 metadata·서명 설정 변경 없음. Flutter/analyze/Android/iOS 빌드는 이번에 NOT RUN(backend 독립 모의 모듈/문서만 변경); 이전166 PASS/1 SKIPPED/analyze 오류·경고0 및 검토용19 빌드 결과와 구분한다.
- 변경: 신규 retention_plan.js, retention_plan.test.js 및 기존 릴리스 문서 추가만. 신규 모듈은 app/server 경로에 연결하지 않았고 삭제 executor/스케줄러가 없다. 운영/실기기/외부 인증 요청 NOT RUN.
- 준비 문서 및 모의 검증 PASS. 소스 통합 Gate FAIL(실제 통합 보류), 전체 탈퇴 Gate FAIL(관련 기록/백업 복구 미구현), 보유 Gate FAIL(회원1년/정기 파기 미구현), 개인정보/스토어 Gate FAIL 및 실제 Apple/콘솔/설정 사실 대조 BLOCKED 유지.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: 미통합 기능·충돌; 보유 기준 미정; 탈퇴/복원 전체 처리 미구현
PRIORITY: P1 인증/데이터·Release Gate
ROOT CAUSE: 분기된 소스와 확정되지 않은 기산점/예외 및 복구 실행 경로
IMPLEMENTED: 기능별 통합 후보·선택 근거/회귀 계획; 데이터별 기준표; 탈퇴 복구안; 삭제 없는 모의 계획기
CHANGED FILES:
  - backend/src/privacy/retention_plan.js
  - backend/test/retention_plan.test.js
  - docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
TEST: 모의5 PASS; backend461 PASS; syntax/diff check PASS
BUILD: NOT RUN — 앱/배포 코드 변경 없음
DEVICE: build18 유지; 설치/인증/삭제 조작 NOT RUN
API: NOT RUN — 운영/실기기/외부 요청 없음; 전체 테스트의 격리 HTTP 회귀 PASS
SOURCE INTEGRATION GATE: FAIL — 후보 정리 PASS; 실제 통합 보류
ACCOUNT DELETION GATE: FAIL — 복구안 준비; 관련 기록/백업 실행 미구현; 실제 Apple BLOCKED
RETENTION GATE: FAIL — 모의 계획 PASS; 회원1년 기준/실제 정기 파기 미완성
PRIVACY / STORE GATE: FAIL — 실제 사실/콘솔 대조 BLOCKED
CI: NOT RUN — 미커밋
COMMIT: NOT RUN — 사용자 보류
PUSH: NOT RUN — 사용자 보류
REMAINING RISKS: 외부 재시도 자격; 미정 보유/예외/백업; 실제 복원·삭제 미구현; 과거 iPhone 원인 미확정
NEXT ACTION: 기준과 격리 외부 계정/설정 증거 확보; 확정 범위부터 복구·파기 단계별 격리 구현
```

### 기준 결정안 제시와 확정 범위 경계 수정 (2026-10-10)
권장안은 확정 기준과 구분한다. 회원 기본1년은 최종 인증 활동일 기산 후보를 권장하지만 사용자가 선택해야 한다. 가입일 기산의 경우 활동 회원도1년 후 파기되므로 서비스 의도 확인이 필요하다. 동의 증거는 회원과 함께 삭제를 기본 후보로 두고 별도 증명 보유가 실제 필요한 경우 최소 필드/기간/근거를 따로 확정한다. 비용 원장의 현재62일은 운영상 최소 보유 후보이며 법적 예외로 확정된 것이 아니다. 기기 기록은 탈퇴 시 사용자 선택 삭제/보존 후보이며 현재 자동 보존 동작 변경은 보류한다. 백업 최대 수명과 삭제 명부 기간은 운영 복구 요구 확인 후 결정하고 수치를 임의 설정하지 않는다.
날짜 경계 결함 재현: Date.parse가 존재하지 않는2026-02-30을 보정하고 Date 지원 범위 밖 정수를 받아 후보로 계산했다. 테스트 추가 시5 PASS/1 FAIL로 확인 후 ISO round-trip 및 Date 범위 검증으로 최소 수정했다. 신규 모의 테스트6 PASS; backend 전체462 PASS/0 FAIL. 사용자 DB/외부 API/삭제 executor 접근 없음. 로그 /tmp/onaria-retention-boundary-final.log. diff check PASS. 앱/analyze/build는 NOT RUN(독립 backend 모의 모듈만 변경), 기기18 유지, 운영 변경/외부 철회/병합/커밋/푸시 없음.
Apple 준비 증거: native client ID·Team/key ID 일치 여부, private-key 파일의 존재/읽기 가능 여부만 확인(내용 출력 금지), Android Service ID·HTTPS redirect/callback·audience 일치, 격리 DB/session/cost 경로 및 운영 경로와 분리, 삭제 가능한 테스트 identity와 테스트 기기의 직접 인증 준비. 현재 실제 철회 실행은 계속 보류한다. App Store Connect 테스트 계정이라는 이유만으로 Sign in with Apple 철회가 격리 서비스라고 가정하지 않는다.

## 통합 패치 준비와 격리 탈퇴·복원 구현 (2026-10-10)

### 소스 통합 패치
HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b 기준의 검토용 `docs/releases/patches/ONARIA_AUTH_INTEGRATION_CANDIDATE_2026-10-10.patch`를 준비했다. app.js/website.js/check_in_page.dart는 현재 tree의 권장 선택을 그대로 포함한다. 인증 session/controller·철회 우선·오류 안내·공통 메뉴·runtime 설치 버전·AI 동의와 필요한 auth/schema를 포함한20개 제품 경로 패치다. **origin/main에 직접 적용 가능한 병합 결과라는 의미가 아니다.** main에는 이미 겹치는 변경이 있으므로 해당 충돌에 내용별 선택할 후보이며 HEAD와 현재 tree의 차이를 검토 가능하게 고정한 것이다. 현재 tree에서 reverse --check PASS(실제 적용 없음). 테스트/migration 배포 절차·문서는 별도 검토 대상이며 이 패치 하나를 완성 배포물로 사용하면 안 된다.
검색 corpus/repository/page·검색 진입점·버전 override·서명 변경은 추가하지 않았다. 검색은 자산·출처·번역 권리 확인 전 보류. 기존 파일 수정/폐기 없이 신규 패치 산출만 수행. 알려진 비밀값 패턴 검사 PASS. 실제 merge/rebase/apply/commit/push 없음.

### 격리 구현 완료와 범위
`backend/src/privacy/deletion_lab.js`는 **:memory: SQLite만 사용하는 격리 실험 모듈**이다. 운영 경로/라우트/기존 회원 DB 및 external provider 연결 없음. 실제 계정 데이터 처리나 영속 worker가 아니다.
- 계정 generation별 active/deleting 상태, 관련 기록·세션·unique 삭제 job·접수 시 삭제 명부 구현.
- 탈퇴 접수 transaction에서 deleting 전환·기존 세션 제거·job/명부 기록. 신규 세션 및 기록 발급 차단.
- 기록/계정 삭제 transaction 실패는 rollback하고 deleting/명부를 유지. 오류 해소 후 재시도 완료. 완료 job 중복 실행 no-op.
- 복원 시 연결 상태를 먼저 false로 전환. 명부 확인 실패 또는 알고 있는 삭제 세대가 명부에서 누락되면 복원/연결 거절. 성공 시 이전 세대의 계정·세션·기록 제거 후 연결 허용.
- 재가입은 이전 계정과 다른 generation으로 구분. 동일 provider의 새 세대를 삭제 대상으로 취급하지 않는 구조를 시험한다. 실제 provider-sub mapping 통합은 미구현이며 generation 재사용 금지는 운영 설계에 필요하다.
- 검증3 PASS: 탈퇴 신규 발급 차단/기존 세션 제거/중복 job; 각 삭제 단계 오류·rollback·재시도; 미검증/누락 명부 차단·이전 백업 제거·새 세대 기록 보존.
- 명부 verified는 격리 테스트가 제공하는 모의 증거다. 외부 서명·독립 영속 저장소의 최신 watermark/복원 인증·다중 프로세스 lease·프로세스 종료 복구는 **미구현**. 현재 메모리 명부만으로 실제 운영 복원 안전성을 PASS로 표시하지 않는다. 실제 비용 원장 관련 mapping·OS 기기 기록 삭제·외부 철회는 미연결.

### 백업 일수 제안: 근거와 조건
실제 확인 근거: scripts/deploy-cafe24.sh는 배포 시 previous 백업을 생성하며 DB는 별도 백업이 필요하다고 명시한다. GABIA_APPLE_DEPLOYMENT_2026-10-07.md에2026-10-07 DB 보호 스냅샷 및 삭제 전 백업 보존 근거가 있다. 정기 DB 백업 주기/만료 작업·복구 요구(RPO/RTO)·가장 오래된 서버/오프사이트 스냅샷 목록은 로컬에 없어 **최장 복원 가능 시점 미확정**. GitHub Actions retention-days30은 CI artifact이며 DB 기간 근거가 아니다.
따라서 실제 운영 기준에 근거한 확정 일수 제안은 아직 BLOCKED. 검토할 **조건부 운영안**은 다음과 같다.
- 개인정보 포함 DB 백업 최대30일 후보: 향후 매일1회 백업, 최대30일 과거 상태 복원이 필요하다는 운영 요구가 승인되는 경우에 한함. 현재 매일 백업한다는 보고가 아니다.
- 삭제 명부37일 후보: 위30일 최대 백업 수명 + 복원 검증/지연 정리 여유7일을 운영 요구로 승인하는 경우. 이7일은 확인된 실제 지연이 아니라 제안이며 최소 정보·키 관리·예외 근거 검토 필요.
- 지금 무기한 남은 백업을 삭제하거나37일 만료를 적용하지 않는다. 모든 복원 가능한 사본이30일 이하라는 실행 증거가 없는 상태에서 명부를37일 후 삭제하면 삭제 계정이 다시 나타날 수 있으므로 적용 금지.
- 확정 전 확보할 자료: ONARIA DB 백업 job의 빈도·성공 시각, 최장 snapshot 날짜와 모든 복제본/수동 보호 백업 목록, 실제 복원 가능 기간·RPO/RTO. 자료를 본 뒤30/37 후보를 늘리거나 줄인다.

회원 활동 권장 정의: 유효한 세션으로 수행한 사용자 주도 기록 생성/변경·대화·계정 작업의 성공 시각. 앱 자동 account GET/health/푸시·백그라운드 polling은 기간을 연장하지 않는 후보다. 신규 활동 timestamp 구현 전에는 created_at/updated_at을 이를 대신한 활동 증거로 사용하지 않는다. 1년 기산점은 여전히 사용자 결정 필요.
기기 기록 기본값 권장: 명시적 선택 전에는 기존 기록 보존, 탈퇴 확인 화면에서 ‘이 기기 기록도 삭제’를 별도 선택 가능하게 하는 후보. 삭제 범위/OS 백업 처리를 알리고 서버 탈퇴와 구분한다. 기존 데이터는 자동 삭제하지 않았으며 UI 선택은 미구현/미확정이다.

### Apple 로컬 점검 및 사용자 단계
로컬 Runner Bundle ID com.onaria.app 확인. backend/.env 및 루트 .env의6개 Apple 설정(client/team/key/private-key-path/service/redirect)은 이번 검사에서 모두 설정값 미확인(미존재/빈값). 값·키 내용 출력 없음. env 다른 공급원/운영 설정은 조회하지 않았으므로 운영 Apple 설정 부재라고 결론 내리지 않는다. 현재 코드의 request-only grant 및 HTTPS callback 요구 확인. 키 파일을 추측해 검색·출력하거나 외부 요청하지 않았다.
사용자가 해야 할 작업 순서:
1. ONARIA 전용 격리 backend/테스트 기기와 삭제 가능한 별도 Apple 계정을 지정한다. 현재 build18/운영 계정 사용 금지.
2. 격리 설정을 보호된 로컬 설정 경로에 준비한다. Bundle/native client·Team/key·key 파일·Android Service ID/등록 callback 일치 증거를 제공하되 비밀값은 채팅으로 보내지 않는다.
3. 실제 SDK/archive와 콘솔 최신 개인정보 답변을 본인 로그인으로 확인 가능한 자료로 준비한다. 제출/설정 변경 없음.
4. 격리 준비 검증 후 별도 허용된 범위에서만 테스트 계정 본인확인을 직접 한다. **현재 실제 외부 철회는 계속 보류**.

### 검증·남은 Gate
backend 전체465 PASS(최종 명부 누락 검사 보강 직전); 보강 후 해당 격리3 PASS. 관련 데이터·신규 세션 차단·부분 실패/재시도·중복·복원·새 세대 보존은 격리 모델에서 PASS. 실제 운영 adapter/독립 영속 명부/실제 비용 mapping/외부 철회는 NOT RUN 또는 미구현이므로 전체 탈퇴/복원 Gate는 FAIL 유지. 백업 사실값·Apple 환경·SDK/콘솔은 BLOCKED. 미정 기간 실제 적용 없음.
초기 npm test를 루트에서 실행한 경로 오류는 backend에서 재실행해 최종465 PASS로 확인했다. 앱 소스·Flutter·설치 산출물 변경 없음; analyze/build/기기 검증 NOT RUN. build18과 운영 데이터를 유지. CI/커밋/푸시/배포/스토어 제출 NOT RUN(사용자 보류). diff check PASS. 이번 변경은 신규 패치, deletion_lab.js, deletion_lab.test.js 및 본 문서다.

## 읽기 감사·영속 격리 구현·별도 패치 사본 검증 (2026-10-10)
- HEAD/branch 유지, AGENTS/공통 기준 재확인. 기존 tree/삭제 상태·build18 유지. 운영 파일 삭제/설정 변경 없음.
- 백업 로컬 근거: deploy-cafe24.sh 배포별 previous 경로, DB는 별도 작업 필요. 문서의 /opt/onaria-backups 및 /opt/onaria/rollout-20261007-GqWM9Q/db-before-rollout 보호 백업 참조. 실제 주기/가장 오래된 사본/오프사이트 사본/만료 여부는 **BLOCKED**. 기존 대상 ari-prod-01 SSH 읽기 전용 메타데이터·설정 유무 조회를 시도했으나 hostname 해석 실패로 접속하지 못했다. 원격 명령 실행/변경 없음. 30일/37일 적용 금지 유지. 필요한 사용자 조작은 기존 SSH 대상의 로컬 접속 별칭 또는 실제 접속 경로를 확인해 주는 것이며, 계정/키/토큰을 채팅에 제공할 필요 없음.
- Apple: 기존 배포 문서의 서버 보호 키/설정 참조와 backend의 ONARIA_APPLE_PRIVATE_KEY_PATH 파일 기반 읽기 확인. 로컬 설정6개 미확인은 앞선 근거 유지. 원격 보호 경로는 위 접속 실패로 **미확인**이며 키가 없다고 판정하지 않는다. 점검할 설정 이름: ONARIA_APPLE_CLIENT_ID, ONARIA_APPLE_TEAM_ID, ONARIA_APPLE_KEY_ID, ONARIA_APPLE_PRIVATE_KEY_PATH, ONARIA_APPLE_SERVICE_ID, ONARIA_APPLE_REDIRECT_URI. 사용자 조작은 접속 경로 확인 → 기존 보호 설정 유무/키 읽기 권한 확인 → 별도 테스트 Apple 계정/격리 대상 지정 순서. 키 내용·설정 값 미출력, 실제 외부 철회 없음.
- 영속 격리 모듈 durable_deletion_lab.js: 직접 만든 OS 임시 onaria-deletion-* 경로만 허용, store.sqlite와 별도 manifest.sqlite를 WAL로 사용. 운영 기본 경로/adapter/라우트 없음. 탈퇴 명부를 먼저 기록하여 store 작업 실패에도 접근/신규 발급을 차단한다. 작업 상태 unique·transaction rollback·완료 no-op·명부 기반 resume 구현. 두 DB에 분산 transaction을 보장한다고 주장하지 않는다.
- 복원 사본 서비스 연결 전 독립 명부 대조/파기를 수행한다. 명부 장애 시 connected=false. 이전 store 백업 복원 후에도 명부에 기록된 이전 계정 제거, 기존 세대 재사용 거절, 새 generation 보존. 명부 실제 SQL 오류도 성공으로 처리하지 않는다. 실제 운영 manifest freshness/서명·오프사이트 복제·다중 worker lease·실제 비용 원장 identity 연결·외부 credential 재시도는 아직 미구현이다.
- 테스트: 파일형 DB 종료/재개 후 실패 작업 재시도, 삭제 명부를 제외한 이전 store 사본 복원, 명부 불가 시 연결 차단, 새 세대 기록 보존 PASS. 모든 계정/세션/기록은 fixture, 임시 테스트 경로만 삭제. 운영/사용자 데이터 미접근.
- 패치: git archive로 별도 HEAD 사본 생성 후 git apply --check/실제 apply PASS. 기존 작업 tree·Git index 수정 없음. 별도 origin/main 사본의 check는 FAIL: app/website/session/apple/schema/member/conversation/privacy/signup/API 경로 및 이미 존재하는 Apple/AI 파일과 겹침. 그러므로 현재 패치는 **HEAD 기반 후보로만 적용 가능**하며 main 즉시 적용 불가. 내용별 정합화가 필요한 SOURCE INTEGRATION GATE FAIL 유지. 실제 merge/rebase/commit/push 없음.
- 빌드/analyze/기기 작업 NOT RUN: 앱 소스 변경 없음, build18 유지. 운영 연결/배포/외부 철회 NOT RUN. 테스트 PASS와 운영 Gate 통과를 구분하며 전체 탈퇴/복원 Gate FAIL, 백업/Apple 운영 읽기 감사 BLOCKED 유지.

## SSH 경로 확인 및 격리 최신성·작업자·비용 연결 보강 (2026-10-10)
- Mac ~/.ssh/config 미존재. ONARIA scripts/.github/기존 배포 문서에서 SSH Host/HostName/User/Port/IdentityFile의 실행 가능한 접속 조합을 찾지 못했다. ari-prod-01은 기존 배포 문서의 서버 이름이며 이 Mac의 SSH 별칭으로 확인되지 않음. 앞선 같은 대상 연결은 hostname 해석 실패. 새로 확인된 대상이 없어 임의 주소·사용자·키를 추측하거나 재접속하지 않았다. 부족한 항목은 실제 SSH 주소, 사용자명, 기존 IdentityFile 경로 및 비표준 port 사용 시 해당 port. 키 내용·비밀번호·env 비밀값 출력 없음.
- 기존 Apple 보호 설정 참조는 ONARIA_APPLE_PRIVATE_KEY_PATH 및 기존 가비아 배포의 보호 폴더/키 권한 근거다. 원격 주소 미확보로 현시점 Apple6개 설정의 운영 유무/키 읽기 권한, 백업 실제 주기/가장 오래된 사본/복제본/만료는 BLOCKED. 설정 부재로 판정하지 않음.30일/37일 미적용.
- 격리 durable 모듈: 독립 명부의 transaction watermark 증가 및 복원 연결 시 minimumWatermark 미달 차단 구현. minimumWatermark를 제공하는 신뢰 외부 경로·서명·오프사이트 최신성 검증은 미구현. 기본0은 테스트 호환이며 운영 최신성 보장이 아니다.
- job 실행을 SQLite BEGIN IMMEDIATE로 직렬화하고 lock 안에서 완료 상태를 재확인. 두 열린 DB handle 작업자가 동일 job을 처리해 완료/no-op 및 다른 세대 보존 PASS. 두 OS 프로세스의 실제 동시 경쟁·장기 lease·분산 작업자는 NOT RUN.
- 격리 비용 adapter: generation→owner unique 연결 및 관련 cost row 삭제를 로컬 transaction에 포함. 탈퇴 이전 세대 비용만 제거하고 새 세대 비용1개 보존 PASS. 실제 cost.sqlite HMAC identity salt/mapping·provider 회원 저장소에 아직 연결하지 않음. 운영 adapter의 계약 모델이며 실제 운영 어댑터 완성으로 표시하지 않음.
- 원격 origin/main 충돌별 현재 diff: app.js +9/-2(철회 우선/고정 오류 안내), website.js +1/-1(실제 계정 관리 동선), check_in_page.dart +2/-73(기존 PopupMenu 대신 공통 AccountMenuButton). 권장 선택은 현재 로컬 구현 유지, main의 이미 반영된 schema/Apple/AI 파일은 중복 추가하지 않고 내용 정합화. 검색/자산/권리 확인은 보류. HEAD 후보 패치의 main 강제 적용/merge/rebase 없음.
- 관련 영속 테스트2 PASS. 전체 백엔드 최종 결과 /tmp/onaria-ssh-isolated-final.log. 앱/build/analyze/기기 설치 NOT RUN(앱 변경 없음), build18 유지. 운영 Gate는 여전히 FAIL/BLOCKED이며 테스트 PASS와 구분. 운영 변경/외부 철회/커밋/푸시 없음.

## 열린 SSH·키 후보 경로 및 실제 프로세스/원장 schema 격리 검증 (2026-10-10)
- ari-prod-01 재접속 없음. 현재 실행 중 ssh 프로세스에서 주소·사용자·port만 추출하도록 검사했으나 대상0. 처음 ps 조회 sandbox 차단은 읽기 전용 권한 재실행으로 확인. 종료된 터미널 이력/원문 명령·env는 읽지 않았으므로 다른 도구의 서버 터미널 부재까지 확정하지 않는다.
- ~/.ssh 및 Downloads 최상위의 키 이름 후보 경로1개: [기존 키 경로: 로컬 SSH_ACCESS.md 참조]. 키 내용 미열람/복사/생성/덮어쓰기 없음. 이름 후보이며 실제 유효성/어느 서버의 키인지 검증하지 않음. 접속 주소·사용자·비표준 port는 여전히 미확인/BLOCKED.
- 독립 Node 프로세스2개를 IPC ready barrier로 동시 시작, 같은 SQLite job 처리 경쟁을 검증. 수정 전 완료2개 응답으로 재현(데이터 중복 삭제는 아니고 결과 보고 결함). transaction 잠금 안의 완료 재확인 결과를 직접 반환하도록 최소 수정. 수정 후 complete1/already-complete1 및 기록0 확인 PASS.
- isolated_cost_adapter.js 추가: 실제 createSqliteUsageLedger가 만든 application_id0x53424347 및 cost_requests(owner_id/state), cost_calls FK cascade 계약에 기반. OS 임시 onaria-deletion-* 경로만 허용. provider/sub→HMAC owner를 추정하지 않고 검증된 명시 association 요구; anonymous/미확인 연결/pending reservation은 차단. completed owner row 삭제·중복 no-op·다른 owner 보존 PASS. 실제 schema fixture로 확인하며 실제 운영 identity association 증거는 미확보. associationVerified는 테스트 입력이지 운영 사실 증명/권한 시스템이 아니다. 서버 production import·실제 회원/세션 adapter 연결 없음.
- 관련 테스트: 영속/프로세스3 PASS, 실제 원장 adapter1 PASS. 백엔드 전체 로그 /tmp/onaria-process-adapter-final.log. 최초 루트 npm test 경로 오류는 backend 경로 재실행으로 교정. build18 유지; 앱/analyze/build/기기 조작 NOT RUN.30일/37일 미적용. 운영 연결/외부 철회/병합/커밋/푸시 없음. diff check PASS.

## 운영 접속 준비 및 검증 결과 정리 (2026-10-10)

### 접속 전 키/대상 확인
- PROJECT ONARIA, branch codex/apple-android-20261006, HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b 유지. 키 후보 [기존 키 경로: 로컬 SSH_ACCESS.md 참조]은 존재하는 일반 파일, symlink 아님, 현재 사용자 소유, 권한0600(그룹/기타 접근 없음). stat 정보만 확인했고 키 내용 읽기/생성/복사/덮어쓰기/권한 변경 없음. 서버 일치 여부는 미확인.
- 사용자에게 현재 가비아 공인 IP·SSH 사용자명·포트를 요청했다. [검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]는 과거 후보일 뿐 확정 사용자명 아님. ari-prod-01 재접속 없음.
- 접속 정보가 오면 명시된 IP/user/port 기준으로 기존 known_hosts 일치 여부를 확인한다. 최초 대상은 신뢰 경로에서 받은 host-key 지문과 대조하기 전 인증 접속하지 않는다. 원격에서 관찰한 지문만으로 신뢰를 확정하지 않는다. StrictHostKeyChecking을 끄거나 불일치를 우회하지 않는다. 기존 키 사용이며 키 내용 출력 없음.

### 접속 전 검증 상태
| 항목 | 현재 근거 | 상태 |
|---|---|---|
| HEAD 기반 통합 후보 패치 | 별도 HEAD 사본 검사/적용 성공; 원본 tree 미변경 | 격리 PASS |
| origin/main 후보 직접 적용 | 이미 반영된 auth/schema/AI 변경 및 충돌 | FAIL; 강제 적용/병합 보류 |
| 백엔드 회귀 | 직전 전체469 PASS | 로컬 PASS; 이번 재실행 NOT RUN(문서/권한 확인만) |
| 영속 삭제·복원·경합 | 임시 SQLite 재시작/복원/명부 장애/새 세대 보존, 독립 프로세스 중복 처리 | 격리 PASS |
| 비용 원장 adapter | 실제 schema fixture, 검증 없는 association/pending 차단 | 격리 PASS; 운영 mapping 미확인 |
| 실제 운영 adapter/명부 최신성 | 운영 권한·신뢰 watermark/명부 복제·회원/원장 식별 연결 미검증 | 운영 FAIL/BLOCKED |
| 실기기 | 앞선 설치18/표시·기록·GET200 근거 유지; 이번 조작 없음 | 이전 PASS; 이번 NOT RUN |
| 백업 현황·Apple 보호 설정 | 기존 문서/코드 참조만 확인; 운영 접속 경로 대기 | BLOCKED |
| 1년/백업30일/명부37일 | 기산점·예외·실제 백업 최대수명 미확정 | 미적용; RETENTION FAIL |

### 접속 후 예정된 읽기 전용 범위
서버 identity/ONARIA 경로·서비스를 먼저 대조한 뒤 ONARIA에 한정해 백업 설정/성공 시각/최장 사본/별도 복제/만료 설정의 metadata를 읽는다. Apple6개 설정의 유무와 참조 키의 권한·서비스 사용자 읽기 가능 여부만 요약한다. 회원·세션·원장의 table/column/FK/application_id 및 코드상 식별 연결을 확인하며 실제 행·token·hash identity·키·env값은 출력하지 않는다. 임의 운영 SQLite 객체 생성/마이그레이션/정리 호출 금지. 다른 프로젝트 DB/환경/포트는 접근하지 않는다.

운영 데이터/설정 변경·서비스 재시작·build18 교체·실기기 인증/삭제·기간 적용·외부 철회·병합/리베이스/커밋/푸시/배포 보류 유지. diff check PASS. 접속 정보가 올 때까지 운영 조회는 NOT RUN이며 신규 전체 테스트/빌드는 불필요하게 반복하지 않았다.

## 사용자 확인 공인 IP 접속 및 운영 읽기 감사 (2026-10-10)
사용자가 가비아 콘솔에서 확인한 공인 IP[검증된 공인 IP: 로컬 SSH_ACCESS.md 참조]와 [검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]/22 후보, 기존 키를 이용한 접속 확인을 명시 허용했다. 기존 known_hosts 대상 등록 확인 후 StrictHostKeyChecking=yes, UpdateHostKeys=no, IdentitiesOnly=yes, BatchMode=yes로 접속 성공. 키 내용/host-key 검증 비활성화/known_hosts 변경 없음. [검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]/22와 해당 키는 이번 실제 인증 성공으로 확인. ari-prod-01 별칭 재접속은 하지 않았고 실제 서버 hostname이 ari-prod-01임을 확인했다.

### 운영 식별/백업
- /opt/onaria/backend 존재, onaria-backend.service 존재/active/running, WorkingDirectory=/opt/onaria/backend, 서비스 User=[검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]. 서비스 재시작/설정 변경 없음.
- 읽기 조사한 /opt/onaria 내 개인정보 DB 사본: deployments/20261006-115216-multi-social/members.sqlite(2026-10-06 02:52:16 UTC), deployments/20261006-120406-reset-test-member/members.sqlite(2026-10-06 03:04:06 UTC), rollout-20261007-GqWM9Q/db-before-rollout/members.sqlite 및 sessions.sqlite(2026-10-07 05:41:42 UTC). 확인 범위 최장 DB 사본은10월6일. mtime은 실제 복원 가능 snapshot 시각을 보증하지 않는다.
- incoming 배포 zip/tar 및 성경 asset zip도 존재하지만 DB 백업으로 분류하지 않는다. /opt/onaria-backups에서 이번 확장자 스캔에 해당하는 DB/archive 후보0; 디렉터리 권한/다른 확장자/다른 위치를 제외한 전체 백업 부재 증명이 아니다.
- /etc/cron.d 및 /etc/systemd/system의 ONARIA+backup/retention/purge 참조 후보0. ONARIA timer0, [검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조] crontab ONARIA 항목0. 정기 백업 주기·만료 실행은 이 범위에서 확인되지 않음. root/다른 사용자 crontab·provider snapshot/오프사이트 복사본·다른 보호 위치는 미확인. **실제 최대수명/모든 복제본 미확정,30일/37일 미적용**.

### Apple와 저장소
- 기존 /opt/onaria/backend/.env의 APPLE_CLIENT_ID/TEAM_ID/KEY_ID/PRIVATE_KEY_PATH/SERVICE_ID/REDIRECT_URI(모두 ONARIA_ prefix) 설정 유무 true. 참조 key 파일 SSH 사용자 읽기 가능 true. 서비스 User=[검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]와 동일하지만 실제 daemon sandbox/환경 최종 로딩·Apple API 성공을 입증하지 않음. 키/설정 값 미출력, 외부 철회 없음.
- immutable read-only SQLite 메인 파일에서 schema만 조회: members.sqlite의 members/member_identities, member-sessions.sqlite의 member_sessions(token_hash/provider/provider_user_id/expires_at/created_at), ai_usage.sqlite의 cost_requests(owner_id/session_id/state 등)/cost_calls/cost_meta. cost application_id1396851527(0x53424347) 일치. 행·token·HMAC 식별값·salt 미조회. immutable은 최신 WAL 상태를 반영하지 않을 수 있으므로 최신 데이터/행 수 검증으로 표시하지 않는다.
- 운영 코드에서 원장은 hash(input.userId), 회원은 findByProviderIdentity를 사용함을 확인. app.js에서 비용 파기 연결 참조 미확인. 일반 원장 delete 정리 코드 존재는 회원 탈퇴 mapping의 근거가 아니다. 회원 provider identity와 원장 input.userId의 실제 association은 여전히 미확정. 격리 adapter PASS가 운영 mapping 완성이라는 의미 아님.

이번은 운영 읽기 감사만 실행. 기존 로컬469 PASS 근거 유지, 새 테스트/빌드 NOT RUN(코드 변경 없음). 운영 연결 준비/서버 identity PASS; 실제 삭제/보유/복원/스토어 Release Gate는 미통과. build18 유지; 운영 데이터/설정 변경·실기기 조작·기간 적용·외부 철회·병합/리베이스/커밋/푸시/배포 없음.

### 사용자 확인 접속 명령 재검증 및 권한 범위 보완 (2026-10-10)
사용자가 확인한 ssh -i 기존키 [검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]@[검증된 공인 IP: 로컬 SSH_ACCESS.md 참조]를 절대 키 경로로 실행하되 StrictHostKeyChecking=yes/UpdateHostKeys=no/BatchMode=yes/IdentitiesOnly=yes 유지. 접속 성공, hostname ari-prod-01, /opt/onaria/backend, 서비스 User=[검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조]/ActiveState=active 재확인. 운영 변경/재시작 없음.
Apple6개 설정 존재, 참조 키 일반 파일/현재 [검증된 SSH 사용자: 로컬 SSH_ACCESS.md 참조] 소유/0600/읽기 가능 확인. 키 내용·설정 값 미출력. 실제 provider 인증/철회 성공 검증은 아님.
DB 사본은10월6일 deployments의 회원 DB2개 및10월7일 db-before-rollout 회원/세션 DB2개 재확인. **권한 범위 보완:** /opt/onaria-backups 탐색 오류1, deployments 하위 탐색 오류1. 앞선 후보0은 백업 부재가 아니라 해당 사용자 접근 범위의 결과이며 전체/최장 사본 확정 불가.10월6일은 읽을 수 있었던 DB 사본 중 최장일 뿐이다. 정기 주기/만료/오프사이트 복제본 미확인 유지. 권한 상승/설정 변경/파일 삭제 없이 종료.30일/37일 미적용, build18/운영 데이터 유지, 외부 철회/병합/커밋/푸시/배포 보류. 문서만 추가하여 테스트/빌드 NOT RUN; diff check PASS.

## 공개 저장소 접속 정보 분리 및 인계 갱신 (2026-10-10)
GitHub gh repo view로 Naharuya/onaria PUBLIC 확인. 실제 접속 주소/사용자/키 경로를 두 공유 문서에서 로컬 참조로 바꾸고 SSH_ACCESS.md에 분리했다. .gitignore로 추적 제외, 파일 권한0600. 접속 성공은 앞선 실제 인증/호스트 검증 결과에 근거하며 새 접속 시도 없이 기존 근거를 정리했다.469 PASS는 직전 테스트, 이번 문서 변경에 전체 테스트/빌드 NOT RUN. 운영 Gate 미통과와 격리 PASS 구분. 기존 파일 삭제·작업 폐기·커밋·푸시 없음.

## 백업 보호 권한·sudo 읽기 감사 및 Apple 일치 확인 (2026-10-10)
로컬 SSH_ACCESS.md의 기존 검증 접속 정보를 유지하고 추가 점검을 기록했다. 추적 제외/0600 유지. 실제 접속 정보·비밀값은 공유 문서에 추가하지 않았다.
- 접근 오류: /opt/onaria-backups는 root:root0700, SSH 사용자 직접 read/search 불가. /opt/onaria/deployments는 root:root0755이지만 하위 backups가 root0700이어서 탐색 오류 발생. 기존 sudo -n true 성공 후 sudo 읽기만 실행. 권한 변경/관리자 설정 수정 없음.
- /opt/onaria-backups의 deploy-20261007-122138 및 deploy-20261007-144143 계열 previous/data에서 회원·세션·ai_usage DB 각3개(총6개) 확인. 별도 deployments 회원 사본2개와 rollout db-before-rollout 회원/세션2개도 확인. 읽은 범위의 최장 회원 DB mtime은2026-10-06 02:52:16 UTC. mtime은 백업 일관성/실제 복구 가능 시점을 보증하지 않으며 복원 테스트는 미실행.
- /etc/cron.d, /var/spool/cron/crontabs, /etc/systemd/system 읽기 검사에서 ONARIA와 backup/retention/purge/snapshot/rclone/rsync를 함께 참조하는 설정0. 앞선 ONARIA timer0 결과와 함께 정기 백업·만료 규칙을 확인하지 못했다. 시스템 공통 백업, 다른 unit/cron 위치, 가비아 콘솔 snapshot·오프사이트/다른 디스크 복제본은 전체 조사 미완료. ‘정기 백업 없음’ 또는 ‘최장 복원일10월6일’로 확정하지 않는다.30일/37일 미확정·미적용 유지.
- 필요한 관리자 자료: 가비아 snapshot 목록/최장 날짜·만료 정책, 외부 복제 job/대상 및 수명, 시스템 공통 백업 포함 범위, 모든 수동 사본 목록, 복구 요구/RPO/RTO 및 최근 일관성 복원 결과. 기존 sudo로 확인한 보호 경로 권한을 바꿀 필요는 없다.
- Apple 값 미출력 일치 검사: native client ID와 로컬 Release Bundle ID 일치 true, Service ID와 native ID 구분 true, Team/key ID10자리 형식 true, Android HTTPS host/path callback 일치 true, 참조 key 파일 존재 true. 기존 key0600/서비스 사용자 읽기 가능 근거 유지. 형식 일치가 키의 Team 귀속/Developer 콘솔 Service 등록/실제 인증 성공을 증명하지 않는다. 콘솔 등록 및 실제 key ID 대응은 미확인. 실제 인증/외부 철회 없음.
- 운영 변경/서비스 재시작/데이터 삭제/기간 적용/기기18교체/병합/리베이스/커밋/푸시 없음. 이번 문서·읽기 감사만 수행, tests/build NOT RUN; 직전469 PASS 유지. 운영 Release Gate는 백업 전체 범위/보유 기준·복원/식별 연결/스토어 대조 미완료로 미통과.

## 콘솔 확인 준비표와 독립 격리 회귀 (2026-10-10)

### 가비아 콘솔 — 사용자 확인 목록
조회만 하고 활성화/비활성화·보관기간 수정·snapshot 삭제/생성·내보내기는 하지 않는다.
- 해당 ONARIA 서버의 자동 백업·스냅샷 활성 여부 및 대상 디스크/DB 포함 범위.
- 생성 주기·시간대·최근 성공 시각·실패 이력.
- 보관기간/사본 수·만료/삭제 규칙과 예외 사본.
- 가장 오래된 **실제로 선택 가능한 복원 지점**의 날짜/시각 및 복원 단위.
- 별도 리전/스토리지 복제·수동 snapshot·내보내기 사본의 존재, 대상·보관/만료 및 최장 날짜.
증거는 개인정보/계정정보를 제외한 설정값·목록 또는 캡처. 로컬 파일 mtime과 콘솔 복원 지점은 구분한다. 전체 사본 범위·최장 시점·만료 실행 근거 확보 전30일/37일 확정/적용 금지.

### Apple 콘솔 대조표 — 실제 값 대신 비교 기준
| 콘솔 확인 항목 | 로컬/운영 비교 기준 | 현재 확인 | 완료 조건 |
|---|---|---|---|
| Identifiers의 native App ID/Bundle 및 capability | Runner PRODUCT_BUNDLE_IDENTIFIER ↔ ONARIA_APPLE_CLIENT_ID | ID 일치 PASS; capability 콘솔 미확인 | 동일 App ID의 Sign in with Apple 활성 및 연결 확인 |
| Service ID와 연결된 primary App ID | ONARIA_APPLE_SERVICE_ID ↔ 콘솔 Service ID 및 native App ID 연결 | Service/native 구분 PASS; 연결 미확인 | 해당 Service ID가 올바른 primary App ID에 연결 |
| Team | 프로젝트 서명 Team/ONARIA_APPLE_TEAM_ID ↔ 콘솔 Membership Team | 서버 형식 PASS; 실제 콘솔 대응 미확인 | 동일 Team 소유 확인; 값은 보호 로컬 비교만 |
| Key ID·키 귀속 | ONARIA_APPLE_KEY_ID/PRIVATE_KEY_PATH ↔ 콘솔 Keys | 설정/형식/0600·읽기 PASS; 귀속 미확인 | Key ID의 Team 및 Sign in with Apple 활성/primary App ID 연결 확인 |
| Domains/Return URLs | ONARIA_APPLE_REDIRECT_URI ↔ Service ID 웹 설정 | 코드 기대 HTTPS host/path 일치 PASS | 콘솔 domain·return URL 정확한 일치 확인 |
| Native/Android 검증 대상 | client/service audience 설정 ↔ 등록 identifier | 코드/설정 존재만 확인 | 플랫폼별 client/audience와 위 등록 관계 일치 |

사용자 조작: Apple Developer에서 본인 로그인 → Identifiers/Service ID 설정을 읽기 확인 → Membership/Keys 연결을 읽기 확인 → 값 없는 일치/불일치 결과 또는 민감정보를 가린 증거 제공. 키 다운로드/교체/등록 수정·실제 인증/철회 실행 없음. 형식/로컬 ID 일치가 콘솔 등록 완성을 의미하지 않는다.

### 완료/남은 Gate 및 안전 작업
새 격리 회귀: 실제 createSqliteUsageLedger schema의 cost_requests→cost_calls FK cascade에서 삭제 trigger 장애를 주입. request/call 모두 rollback 확인, 장애 해소 후 재시도로 해당 owner만 삭제·다른 owner call 보존 PASS. 관련2 PASS. 운영 식별자 매핑은 추정/연결하지 않았고 임시 fixture만 삭제했다. 테스트 추가만 수행, 기존 제품·기기/운영 변경 없음.
콘솔 조사 완료 조건은 백업 전체 대상/최장 지점/만료·복제 목록 및 Apple 등록 관계의 확인 증거 확보다. 전체 출시 완료 조건은 확정 기간의 자동 파기/실행·독립 최신 명부/복원 검증·실제 계정-원장 연결·지원 삭제/스토어 고지 일치까지 필요하며 콘솔 확인만으로 출시 PASS가 아니다.
현재: 격리 삭제/경합/원장회귀 PASS, 백업 전체 범위/Apple 등록 BLOCKED, 보유·운영 삭제/복원·소스통합/스토어 Gate 미통과. build18 유지,30일/37일 미적용. 운영 변경/재시작/외부 철회/병합/리베이스/커밋/푸시 보류. 앱 analyze/build/기기 검증 NOT RUN(앱 변경 없음).

최종 backend 전체470 PASS/0 FAIL. 로그 /tmp/onaria-console-prep-final.log; 관련2 PASS, diff check PASS. 이전469 기록은 당시 결과로 유지.

## 가비아 ARI Production / Project 콘솔 사용자 확인 반영 (2026-10-10)

근거: 사용자가 가비아 ARI Production / Project 화면에서 확인하여 전달한 결과. 이번에는 에이전트가 콘솔에 접속하거나 설정을 변경하지 않았다.

| 콘솔 항목 | 사용자 확인 결과 | 해석 범위 |
|---|---|---|
| 스토리지 스냅샷 | 목록 없음 | 확인한 프로젝트 화면에 표시된 스냅샷 없음 |
| 스냅샷 스케줄러 | 목록 없음 | 확인한 프로젝트 화면에 표시된 스케줄러 없음 |
| 백업 서비스 | 목록 없음 | 확인한 프로젝트 화면에 표시된 백업 서비스 없음 |
| 서버 연결 디스크 | ari-prod-01 → RootStorage-20260920231134 | 루트 SSD50GB, 생성일2026-09-20 |

위 콘솔 목록과 서버 내부의 deployments/rollout/배포 previous DB 보호 사본은 별개다. 앞선 서버 읽기 조사에서 확인한 회원·세션·비용 원장 사본의 존재 근거는 유지한다. 콘솔 목록이 없다는 사실로 내부 사본이 없다고 판단하지 않는다. 루트 디스크 생성일은 백업 생성일이나 복원 지점이 아니다.

외부 사본·다른 프로젝트/계정의 복제·수동 내보내기 여부, 전체 사본의 만료 규칙, 최장 실제 복원 가능 시점은 **미확인**으로 유지한다. 확인 범위 밖에 백업이 전혀 없다고 확정하지 않는다. 내부 DB 파일 mtime으로 최장 복원 시점을 확정하지 않는다.

가비아 콘솔 목록 확인은 사용자 관찰 근거로 기록 완료. 백업 전체 범위/만료·복원 Gate는 아직 미통과.30일/37일 보유 후보는 확정·적용하지 않았다. 기존 backend470 PASS는 이전 격리 검증 결과이며 이번에는 문서만 갱신하여 tests/build/서버·콘솔 조회 NOT RUN. build18·운영 데이터·기존 작업 보존. 운영 변경/재시작/외부 철회/병합/리베이스/커밋/푸시 보류 유지.

## Apple 콘솔 제공값과 서버·앱 읽기 대조 (2026-10-10)

### 프로젝트/보존
cwd /Users/ari/ARI/projects/onaria, branch codex/apple-android-20261006, HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b. 시작 dirty83 entries 확인 및 tracked/untracked619파일 SHA256 보존 기준 저장. ONARIA만 조사, 다른 프로젝트 수정 없음. 기존 known_hosts 검증 유지한 확인 접속 대상으로 서버 설정 whitelist 비교/키 stat만 수행. 키 내용·client secret·token·전체 env 출력/복사 없음.

### 항목별 판정
| 항목 | 판정 | 근거와 범위 |
|---|---|---|
| Team | PASS | 사용자 콘솔 BJL8U6B46S ↔ 서버 ONARIA_APPLE_TEAM_ID ↔ 앱 DEVELOPMENT_TEAM 일치 |
| Native App/Bundle | PASS | 사용자 콘솔 com.onaria.app ↔ 서버 native client ↔ Runner Bundle 설정 일치; local Runner.app metadata도 일치 |
| Android Service | PASS | 사용자 콘솔 com.onaria.web.login ↔ 서버 ONARIA_APPLE_SERVICE_ID 일치. 앱은 server challenge의 clientId를 사용하며 하드코딩한 별도 Service ID 없음; 실제 challenge 호출 NOT RUN |
| Key ID | PASS | 사용자 콘솔2XFTY86GB9 ↔ 서버 ONARIA_APPLE_KEY_ID 일치. 키 내용이나 cryptographic 귀속을 확인한 판정 아님 |
| App ID/Service의 Sign in with Apple 활성 | PASS(사용자 관찰) | 콘솔 활성 확인 제공; native entitlements Default 확인. 최종 설치본 entitlement 신규 조회는 NOT RUN |
| Service 및 Key의 연결 App | PASS(사용자 관찰+설정) | 사용자 제공 BJL8U6B46S.com.onaria.app이 확인된 Team+Bundle 조합과 일치; 에이전트 콘솔 직접 조회 없음 |
| 등록 domain | PASS | 사용자 콘솔 api.onaria.ai.kr ↔ 서버 callback host 일치 |
| 서버↔앱 전체 callback | PASS(정적 설정) | 서버 redirect가 앱의 baseUrl 기반 /v1/auth/apple/android/callback 요구와 일치. 서버 설정 전체값은 내부에서 비교; 실제 인증/challenge 없음 |
| 콘솔 전체 Return URL | BLOCKED | 사용자 화면은 https://api.onaria.ai.kr/v1/auth/apple/android/callb…까지. 끝부분 미확인; prefix 관찰을 전체 일치 PASS로 바꾸지 않음 |
| 보호 키 소유/권한/읽기 | PASS(파일 권한) | 서비스와 SSH 사용자 동일, 해당 사용자 소유 일반 파일0600, 해당 사용자 읽기 가능. daemon 실제 sandbox 로딩/키 내용/서명 요청 미검증 |
| 실제 Apple 인증·철회·탈퇴 | NOT RUN | 사용자 보류; 설정 일치와 별개 |
| 운영 Release Gate | BLOCKED/미통과 | 콘솔 전체 Return URL, 실제 격리 E2E 및 기존 삭제·보유·복원·스토어 Gate 남음 |

앱 설정 대조는 현재 source와 로컬 compile 산출물에 한정한다. 로컬 Runner.app은1.0.0(19)이며 현재 기기 signed Release1.0.0(18)과 구분한다. 기기18 교체/인증/삭제 조작 없음. 기존18 Bundle/Team 확인 근거는 이전 릴리스 기록 유지, 이번에 새 실기기 조회/서명 검증은 하지 않았다.

### 사용자 준비 조건
1. 콘솔 Return URL을 전체 선택/펼쳐 끝부분까지 확인해 주소 대조 완료(비밀값/키 내용 제외).
2. 기존 운영 계정과 분리된 삭제 가능한 테스트 Apple 계정 및 별도 테스트 기기 지정.
3. 운영 DB·session·usage·backup과 분리된 격리 서비스 경로 및 해당 client/Service의 허용 callback 구성을 확인. 운영 callback을 임의 변경하지 않음. 격리 callback 별도 등록이 필요하면 현재 설정 변경 보류와 별개 승인 필요.
4. 준비 검증과 실행 범위 확정 후에만 사용자가 테스트 계정 본인확인을 수행. 현재 실제 인증/외부 철회/회원삭제는 계속 보류.

이번 제품 코드 변경 없음, tests/build NOT RUN; 직전 backend470 PASS는 격리 테스트 결과 유지.30일/37일 미적용, 운영 변경/재시작/배포·병합/리베이스/커밋/푸시 없음. 전체 일치 판정을 설정 수준 밖으로 확대하지 않는다.

## Apple 모의 격리 환경 준비 (2026-10-10)
- prepareAppleIsolation은 OS 임시 onaria-apple-isolation-* 폴더에만 회원·세션·비용·독립 명부 SQLite와 별도 backups 경로를 구성한다. 파일0600/backup0700, 사전 존재 대상·운영 경로·설정 객체 주입을 거절. 실제.env 로딩/네트워크/Apple client 생성 없음. mode mock-only/realAppleAllowed=false.
- 환경 설정 주입 금지는 이 모듈 입력에 해당하며 프로세스 전체 env의 존재를 검사한 것은 아니다. 모듈은 env를 사용하지 않으며 app/server에 연결하지 않았다. 운영 key/DB 파일을 복사하지 않는다.
- 실제 createMemberStore/createMemberSessions/createSqliteUsageLedger schema를 임시 경로에 생성. 모의 Apple identity로 세션 발급/검증→세션 철회/회원 삭제→이전 회원 백업 복원→독립 명부 대조로 이전 계정 제거→새 identity 회원 생성 보존을 검증. 이것은 provider credential 검증이 아니라 모의 trusted identity이며 실제 Apple 인증 아님.
- 운영 api.onaria.ai.kr callback은 격리 callback으로 거절한다. 별도 callback 주소는 등록 증거 없어 BLOCKED. 기존 콘솔 Return URL 끝부분 미확인 유지. 기존 등록 범위가 별도 격리 URL을 포함한다는 근거가 없으므로 사용 가능으로 판단하지 않는다. 콘솔 설정 변경/운영 routing 변경 없음.
- 독립 명부 장애 시 접속 차단·재시작/동시 작업자/재가입 generation 보존은 기존 durable 격리 회귀를 함께 실행. 이번 경로 모듈은 운영 연결 자동 게이트나 실제 배포 환경이 아니고 격리 회귀 준비물이다. 실제 worker의 신뢰 watermark/운영 identity mapping은 여전히 미구현.
- 사용자 준비: (1) 콘솔 전체 Return URL 확인, (2) 운영과 별도 테스트 Apple 계정/테스트 기기 지정, (3) 별도 callback의 실제 등록 가능 범위와 격리 HTTPS 서비스/데이터 경로 확인, (4) 필요 시 등록/배포 변경은 별도 승인 후 준비. 지금은 실제 인증·철회·삭제 실행하지 않는다.
- 관련 모의1 PASS. 전체 회귀 로그 /tmp/onaria-apple-isolation-final.log. build18/운영 데이터/기존 변경 유지. 운영 변경/배포/기간30일·37일 적용/병합/리베이스/커밋/푸시 없음. 앱 analyze/build/실기기 작업 NOT RUN. 콘솔 전체 Return URL/실제 격리 callback/실제 E2E BLOCKED 및 운영 Release Gate 미통과 유지.

## 격리 실행 절차와 origin/main 기준 후보 재준비 (2026-10-10)
- ONARIA_APPLE_ISOLATION_RUNBOOK_2026-10-10.md에 모의 환경 설정 예시·재현 명령·수용 기준·실제 검증 차단 조건 기록. 비밀값/운영 설정/키 미포함.
- origin/main3fa97ca 기준 git archive 임시 사본에20개 auth/schema/AI/메뉴 제품 경로의 현재 구현 및 관련 backend test4개를 선택 복사해 새 패치 ONARIA_ORIGIN_MAIN_AUTH_CANDIDATE_2026-10-10.patch 준비. 임시 사본의 index를 baseline으로 diff 생성한 것뿐이며 원본 Git index/HEAD/파일에 패치 적용·merge/commit 없음.
- 새 origin/main 별도 깨끗한 사본의 apply --check/실제 apply PASS, 후보 reverse --check PASS. 선택24개 파일 byte가 원본 구현과 같음을 확인해 현재 인증·철회 순서·고정 오류 안내·공통 메뉴·runtime 버전 표시 보존. 검색 corpus/page/repository/진입점 추가 없음.
- 관련 backend22 PASS, 별도 후보 전체backend456 PASS. 기존 작업 tree 전체471 PASS와 **후보456 PASS를 구분**: 후보에는 로컬 격리 실험 모듈/테스트 모두를 통합하지 않았다. 이번 Flutter/analyze/Android/iOS build는 NOT RUN; 앱 byte 보존 검사만으로 새 후보 전체 앱 검증 PASS를 선언하지 않음. 최종 후보 빌드/Flutter 회귀는 남은 Gate.
- 기존 HEAD 패치는 origin/main 직접 적용 FAIL 기록을 유지하고 새 main 기준 패치를 별도 이름으로 제공. 새 후보의 텍스트 적용 충돌은0이지만 파일별 현재 구현 선택이 main의 모든 의미 변경을 보존했는지 최종 내용 리뷰가 남는다. main 기반 부분 기능 후보이며 실제 병합 결과/완성 배포물 아님. migration 실행·테스트 의존성·최종 source 포함 범위도 배포 전 검토 필요.
- Apple 콘솔 전체 Return URL/격리 callback 등록 범위/별도 테스트 계정·기기·서비스는 BLOCKED 유지. 실제 인증/외부 철회/운영 접속/설정 변경 없음. 미정 보유기간 미적용, build18/운영 데이터/기존 작업 보존. 운영 변경/재시작/병합/리베이스/커밋/푸시 없음. patch 알려진 비밀값 패턴 및 diff check PASS.

## 별도 origin/main 후보 통합 회귀와 보호 구현 보완 (2026-10-10)

### 471 대456 테스트 차이와 보완
이전 main 후보456은 원본471보다 다음15개가 누락됐다. 후보의 초기 패치에 로컬 격리 제품 모듈과 테스트가 포함되지 않았기 때문이며15개 성공을 후보에 추정 적용하지 않았다.
| 테스트 파일 | 건수 | 검증 범위 |
|---|---:|---|
| retention_plan.test.js |6| 경계/미정 기준 차단/입력 불변/잘못된 날짜 거절 |
| deletion_lab.test.js |3| 탈퇴/재시도/복원/새 세대 보존 |
| durable_deletion_lab.test.js |3| 파일 DB 재시작/명부 최신성/독립 프로세스 경합 |
| isolated_cost_adapter.test.js |2| association/pending 차단·FK rollback/재시도·다른 owner 보존 |
| apple_isolation.test.js |1| 분리 저장소·모의 세션/탈퇴/복원·운영 callback 거절 |
각 대응 backend/src/privacy 모듈5개 및 테스트5개를 별도 후보에 추가해 후보backend471 PASS/0 FAIL 확인. 운영 app/server에 연결하지 않은 격리 기능임을 유지한다. 실제 운영 계정/원장 association·신뢰 최신 명부/외부 철회는 여전히 미완성.

### 앱/계약 내용 리뷰
선택된 auth/controller/session/API/privacy/menu/check_in/schema/website 구현은 원본 byte와 동일. 현재 library dart source의 차이도 확인하지 못했다. 철회 우선/고정503 및 일부 세션 해제 안내, DELETE 응답 불확실 안내, generation 보호·timeout 세션 보존·GET 상태 확인, 직접 로그아웃·별도 계정 관리·PackageInfo 실제metadata 표시 유지. 검색 page/repository/assets/진입점 추가 없음.
후보에서 누락·차이 있던 Flutter 인증/메뉴/진단/탈퇴/widget 테스트6개를 후보에 보완. 원본 파일에는 구현/테스트 변경하지 않았다. 후보 Flutter 전체166 PASS/1 SKIPPED, analyze 오류0/경고0/info17. 테스트의 장시간 대화 실패 fixture는 기대 동작이며 최종 All tests passed 확인.

### 패치/산출물 구분
후보에서 ONARIA_ORIGIN_MAIN_AUTH_CANDIDATE_2026-10-10.patch 갱신(보호 모듈·회귀 포함). 새로운 origin/main archive 사본 apply --check PASS, 강제 적용/실제 병합 없음. 후보 수정은 누락 파일 보완이며 제품 로직 새 변경은 없음. 텍스트 충돌0, 최종 선택 내용 리뷰/전체 배포 manifest·migration·운영 Gate는 남음.
후보 build-name1.0.0/build-number19로 Android/iOS Release 빌드 검증 진행. 원본 pubspec 기본값/서명 설정 미수정. 기존 ignored SDK/provider 설정을 후보 로컬에서만 사용하고 key.properties의 상대 경로는 기존 키 절대 참조로 해석해 후보에 기록; 키 내용 출력/키 복사/교체 없음. 보호 로컬 설정은 후보 패치에 포함하지 않는다. 설치된 기기18과 검토용19를 구분하며 기기 설치/실행 없음.

### 후보 최종 빌드 결과
- Android signed Release1.0.0(19) PASS; package com.onaria.app/versionCode19/versionName1.0.0 확인, apksigner 검증 및 기존 인증서 SHA256 일치 PASS.
- iOS Release19 no-codesign compile PASS 후 기존 Team/서명 설정으로 signed Release19 빌드 PASS. codesign strict/deep 검증 및 Team/Bundle/실제1.0.0(19) metadata 확인. App Store Distribution archive 검증은 NOT RUN; 기존 개발 서명 Release 검증과 구분.
- 최종 후보backend471 PASS, Flutter166 PASS/1 SKIPPED, analyze 오류/경고0 info17. 갱신 패치 새 origin/main 사본 apply-check PASS. 민감 설정/접속 문서 패치 미포함 및 알려진 키/token 패턴 검출0, diff check PASS.
- 로그 /tmp/onaria-candidate-backend-new.log, /tmp/onaria-candidate-flutter.log, /tmp/onaria-candidate-analyze.log, /tmp/onaria-candidate-android.log, /tmp/onaria-candidate-ios.log, /tmp/onaria-candidate-ios-signed.log.
- 설치된 build18 유지, 이번19는 별도 후보 산출물이고 미설치. 실제 소스 병합/운영 배포/실기기 인증·삭제/외부 Apple 인증·철회/미확정 기간 적용/커밋/푸시 없음. 원본 변경은 요청된 패치·릴리스 기록 갱신에 한정.
- 운영 Gate 미통과: 전체 Return URL/격리 callback 등록·실제 E2E, 실제 회원/원장 association·독립 최신 명부·자동 파기/보유 예외/전체 백업 복원·스토어/콘텐츠 범위 및 최종 통합 내용 검토. 격리/빌드 PASS를 운영 PASS로 표시하지 않는다.
서명 검증 환경 구분: 최초 sandbox codesign --verify는 CSSMERR_TP_NOT_TRUSTED 실패. 시스템 신뢰 저장소 접근을 허용한 동일 읽기 전용 codesign --verify --deep --strict 재실행 exit0 PASS. 인증서 신뢰 설정 변경/우회 없음. 최종 signed Release19 검증 PASS는 재실행 근거이며 최초 실패를 숨기지 않는다.

## build19 실기기 설치 및 1차 실행 검증 (2026-10-10 14시대)

사용자 승인 후 Release Gate 전의 테스트 기기 설치만 진행했다. Production 코드/운영 DB/회원 데이터/원격 Git에는 변경하지 않았다.

### Android — SM-S908N (Galaxy S22 Ultra)
- ADB serial R3CT10BVG6V, Android 16 / API 36 확인.
- 설치 전 ONARIA: versionName 1.0.0 / versionCode 18.
- 후보 APK: build/app/outputs/flutter-apk/app-release.apk, versionName 1.0.0 / versionCode 19.
- 설치본과 후보 APK의 signer SHA-256이 동일함을 읽기 검증 후 데이터 보존 업데이트 설치.
- 설치 결과 PASS. 설치 후 package metadata 1.0.0(19) 확인.
- 앱 launch PASS, process 생존 확인, 즉시 FATAL EXCEPTION 없음.
- UI hierarchy로 홈 화면 및 메뉴 노출 확인.
- 메뉴에서 로그인됨 · 네이버, 로그아웃, 계정 관리, 계정 연결 확인.
- 앱 정보에 버전 1.0.0 · 빌드 19 표시 확인.
- 기존 Naver 로그인 세션이 build18→19 업데이트 후 유지된 상태를 확인. 이 확인은 새 로그인 E2E 성공을 의미하지 않는다.
- 로그아웃/회원탈퇴/새 로그인은 계정 상태를 변경하므로 자동 실행하지 않고 사용자 조작 Gate로 유지.
- 현재 연결 Android는 A33이 아니라 SM-S908N이다. A33 별도 검증은 기기 연결 후 진행.

### iPhone
- 실제 기기 00008120-001855410CC3A01E, iOS 26.6.1 연결 확인.
- 설치 전 ONARIA 1.0.0(18) 확인.
- 기존 retained build/ios/iphoneos/Runner.app은 1.0.0(19) metadata였지만 그 시점 artifact에 code signature가 없어 첫 설치가 No code signature found로 실패. 이전 signed-build PASS 기록과 모순으로 확대하지 않으며, signed artifact가 후속 no-codesign build로 덮였을 가능성을 구분 기록.
- 현재 원본 source 상태를 바꾸지 않는 flutter build ios --release --build-name=1.0.0 --build-number=19 재빌드 PASS.
- 자동 signing Team BJL8U6B46S, bundle com.onaria.app, codesign deep/strict PASS.
- 빌드 전/후 git status --porcelain 차이 없음: 제품 source 상태 추가 변경 없음.
- signed 1.0.0(19) iPhone 설치 PASS, 설치 metadata 1.0.0(19) 확인.
- 자동 launch는 iPhone 잠금 상태로 BLOCKED (Unable to launch ... device ... unlocked). 설치 실패가 아니라 잠금 해제 필요 상태.
- iPhone 잠금 해제 후 앱 실행/로그인/세션/로그아웃/계정삭제 E2E가 남음.

### 현재 판정
- Android build19: INSTALL PASS / LAUNCH PASS / 기존 Naver session 보존 확인.
- iPhone build19: SIGNED BUILD PASS / INSTALL PASS / LAUNCH BLOCKED(device locked).
- 실제 Google/Kakao/Naver/Apple 신규 로그인, 로그아웃, 회원탈퇴/세션 폐기 E2E는 아직 PASS 아님.
- 운영 Release Gate는 계속 BLOCKED. merge/rebase/commit/push/Production 배포/DB 변경 없음.

### Android build19 비파괴 UI 확인 추가
- 기존 Naver 로그인 상태에서 계정 관리 화면까지 비파괴 탐색.
- 외부 AI 전송 허용 철회 항목 노출 확인.
- 회원 정보와 계정 설명, 연결된 로그인 계정, Naver 현재 로그인, 로그아웃, 회원탈퇴 항목 노출 확인.
- 기기 기록 삭제 항목들과 웹 계정삭제 안내/공식 개인정보 안내 링크 노출 확인.
- 회원탈퇴/연결해제/로그아웃/기록삭제 버튼은 누르지 않았고 계정·운영 데이터 변경 없음.

### iPhone build19 잠금 해제 후 실행 확인
- 사용자가 iPhone 잠금을 해제했다고 확인.
- 설치된 ONARIA metadata 1.0.0(19) 재확인.
- xcrun devicectl launch PASS: com.onaria.app 정상 실행.
- 기기 process 목록에서 Runner process 생존 확인.
- 이 단계는 앱 실행 성공 증거이며 로그인/세션/로그아웃/회원탈퇴 E2E PASS를 의미하지 않는다.
- 다음 단계는 사용자가 실제 화면에서 로그인 상태 및 메뉴/앱정보를 확인한 뒤, 공급자별 인증 테스트를 사용자 조작과 함께 진행한다.

### iPhone 잠금 해제 확인 및 재실행
- devicectl lockState: passcodeRequired=false, unlockedSinceBoot=true.
- ONARIA build19을 terminate-existing 옵션으로 재실행 PASS.
- 현재 iPhone에서 ONARIA가 foreground launch된 상태로 준비됨.
- 다음 단계는 사용자 화면 조작이 필요한 로그인 상태 확인/로그아웃/공급자 재로그인 E2E. 계정 비밀번호·2FA·최종 회원탈퇴 확인은 사용자 직접 입력/승인.

### iPhone build19 현재 로그인 상태 사용자 확인
- 사용자가 iPhone build19 메뉴에서 **로그인됨 · 네이버** 표시를 직접 확인.
- Android build19에서도 기존 Naver 로그인 세션 유지가 확인된 상태와 일치.
- 이 단계는 update 후 세션 보존/표시 확인이며, 신규 Naver 로그인 E2E 성공 판정은 아님.
- 다음 테스트 Gate: 사용자가 로그아웃 실행 → 재로그인 화면 진입 → Naver 신규 로그인 → 앱 재실행 후 세션 유지 확인.

### iPhone Naver 재로그인 후 재실행
- 사용자가 iPhone build19에서 로그아웃 후 Naver 재로그인을 완료하고 메뉴의 **로그인됨 · 네이버** 표시를 직접 확인.
- 이어서 devicectl로 ONARIA를 terminate-existing 후 재실행 PASS, Runner process 생존 확인.
- 다음 확인은 재실행 후 메뉴의 **로그인됨 · 네이버**가 유지되는지 사용자 직접 확인.
- 재실행 후 표시 유지가 확인되면 iPhone Naver 신규 로그인 + 세션 지속성 E2E를 PASS로 판정 가능. 다른 provider 및 회원탈퇴는 별도 Gate 유지.

### iPhone Naver 로그인/세션 지속성 E2E PASS
- 사용자가 build19에서 로그아웃 후 Naver 재로그인 완료.
- 로그인 직후 메뉴에서 로그인됨 · 네이버 표시 확인.
- devicectl terminate-existing → relaunch 후 Runner process 생존 확인.
- 재실행 후 사용자가 다시 로그인됨 · 네이버 표시 유지 확인.
- 판정: iPhone build19 Naver 신규 로그인 + 앱 재실행 후 세션 지속성 E2E PASS.
- 로그아웃 자체도 사용자 조작으로 성공 확인. 계정삭제/다른 provider는 별도 Gate 유지.

### iPhone Google 로그인 후 재실행
- 사용자가 iPhone build19에서 Google 로그인을 완료하고 메뉴의 **로그인됨 · Google** 표시를 직접 확인.
- 이어서 devicectl로 ONARIA를 terminate-existing 후 재실행 PASS, Runner process 생존 확인.
- 다음 확인은 재실행 후 메뉴의 **로그인됨 · Google** 유지 여부.
- 유지가 확인되면 iPhone build19 Google 신규 로그인 + 세션 지속성 E2E PASS로 판정.

### iPhone Google 로그인/세션 지속성 E2E PASS
- 사용자가 build19에서 Google 로그인 완료.
- 로그인 직후 메뉴에서 로그인됨 · Google 표시 확인.
- devicectl terminate-existing → relaunch 후 Runner process 생존 확인.
- 재실행 후 사용자가 다시 로그인됨 · Google 표시 유지 확인.
- 판정: iPhone build19 Google 신규 로그인 + 앱 재실행 후 세션 지속성 E2E PASS.
- 로그아웃/다른 provider/회원탈퇴는 별도 Gate 유지.

### Kakao iPhone 설정 누락 원인 및 build19 재빌드
- iPhone Kakao 로그인 시 사용자 화면에 카카오 앱 키 설정 필요 메시지가 표시됨.
- 소스 확인 결과 KakaoAuthConfig는 compile-time dart define ONARIA_KAKAO_NATIVE_APP_KEY를 요구함.
- 로컬 iOS Kakao 설정 파일은 존재했으나 xcconfig 변수만으로는 Dart String.fromEnvironment에 주입되지 않아 기존 build19에서 KakaoAuthConfig.enabled=false가 된 것으로 판정.
- 비밀값을 소스/패치에 하드코딩하지 않고 로컬 보호 설정에서 값을 읽어 --dart-define로 주입해 iOS/Android Release 1.0.0(19) 재빌드.
- iOS signed build PASS, Android signed release build PASS, 재빌드 전/후 git status 동일(PASS).
- iPhone에 재빌드된 1.0.0(19) 설치 및 launch PASS.
- 다음 사용자 Gate: 현재 로그인 상태에서 로그아웃 → Kakao 로그인 재시도 → 로그인됨 · Kakao 확인.
- Production/운영 설정/DB/Git remote 변경 없음.

### iPhone Kakao 로그인 후 재실행
- 사용자가 iPhone build19에서 Kakao 로그인 완료를 보고.
- 이어서 devicectl terminate-existing → relaunch PASS, Runner process 생존 확인.
- 다음 확인은 재실행 후 메뉴의 **로그인됨 · Kakao** 유지 여부.
- 유지 확인 시 iPhone build19 Kakao 신규 로그인 + 세션 지속성 E2E PASS로 판정.

### iPhone Kakao 로그인/세션 지속성 E2E PASS
- 사용자가 build19에서 Kakao 로그인 완료.
- 로그인 직후 메뉴에서 로그인됨 · Kakao 표시 확인.
- devicectl terminate-existing → relaunch 후 Runner process 생존 확인.
- 재실행 후 사용자가 다시 로그인됨 · Kakao 표시 유지 확인.
- 판정: iPhone build19 Kakao 신규 로그인 + 앱 재실행 후 세션 지속성 E2E PASS.
- Apple/회원탈퇴는 별도 Gate 유지.

### iPhone Apple 로그인 후 재실행
- 사용자가 iPhone build19에서 Apple 로그인을 완료하고 메뉴의 **로그인됨 · Apple** 표시를 직접 확인.
- 이어서 devicectl terminate-existing → relaunch PASS, Runner process 생존 확인.
- 다음 확인은 재실행 후 메뉴의 **로그인됨 · Apple** 유지 여부.
- 유지가 확인되면 iPhone build19 Apple 신규 로그인 + 세션 지속성 E2E PASS로 판정.
- 회원탈퇴 E2E는 별도 테스트 계정으로 마지막 Gate 유지.

### iPhone Apple 로그인/세션 지속성 E2E PASS
- 사용자가 build19에서 Apple 로그인 완료.
- 로그인 직후 메뉴에서 로그인됨 · Apple 표시 확인.
- devicectl terminate-existing → relaunch 후 Runner process 생존 확인.
- 재실행 후 사용자가 다시 로그인됨 · Apple 표시 유지 확인.
- 판정: iPhone build19 Apple 신규 로그인 + 앱 재실행 후 세션 지속성 E2E PASS.
- iPhone 소셜 로그인 4종(Naver/Google/Kakao/Apple) 신규 로그인 및 재실행 세션 지속성 모두 PASS.
- 마지막 출시 전 계정 lifecycle Gate는 별도 테스트 계정 회원탈퇴 E2E이며, 실제 계정 삭제이므로 사용자 최종 확인과 함께 진행.

### iPhone 회원탈퇴 E2E — 사용자 완료 확인 및 재실행
- 사용자가 별도 테스트 계정에서 회원탈퇴를 수행했고 앱에서 **회원탈퇴가 완료되었습니다.** 메시지를 직접 확인.
- 탈퇴 직후 devicectl terminate-existing → relaunch PASS, Runner process 생존 확인.
- 다음 확인은 재실행 후 로그인 상태가 해제되어 있는지, 이전 세션이 복원되지 않는지 사용자 직접 확인.
- 재실행 후 로그아웃/미로그인 상태가 확인되면 세션 폐기까지 PASS로 판정.
- 같은 공급자/동일 테스트 계정 재로그인은 별도 확인으로, 신규 가입/재생성 동작과 generation 보호를 검증할 수 있음.

### iPhone 회원탈퇴/세션 폐기 E2E PASS
- 회원탈퇴 완료 메시지 확인 후 앱 완전 재실행 수행.
- 재실행 후 사용자가 메뉴에서 **로그인하지 않음** 메시지를 직접 확인.
- 판정: 회원탈퇴 → 세션 폐기 → 앱 재실행 후 미로그인 상태 유지 E2E PASS.
- 삭제된 동일 테스트 계정으로 재로그인/신규 회원 generation 생성 검증은 선택적 후속 테스트로 남김.
- 운영 DB 자동 동기화/복원/Production 배포/Git merge·push는 수행하지 않음.

### 삭제 후 동일 계정 재가입 / 신규 generation 검증
- 회원탈퇴 후 동일 사용자 계정으로 Naver/Google/Kakao/Apple을 각각 다시 시도했을 때 앱에서 **처음 사용하시는 계정이에요** 메시지를 사용자 직접 확인.
- 이는 기존 탈퇴 세션/회원 상태가 그대로 복원되지 않고 신규 가입 흐름으로 진입했음을 보여주는 실기기 관찰 근거.
- 사용자는 Naver 공급자로 실제 회원가입을 완료.
- 판정:
  - Naver: 탈퇴 후 동일 계정 → 신규 가입 안내 확인 → 회원가입 완료 PASS.
  - Google: 탈퇴 후 동일 계정 → 신규 가입 안내 확인 PASS (회원가입 완료까지는 미실행).
  - Kakao: 탈퇴 후 동일 계정 → 신규 가입 안내 확인 PASS (회원가입 완료까지는 미실행).
  - Apple: 탈퇴 후 동일 계정 → 신규 가입 안내 확인 PASS (회원가입 완료까지는 미실행).
- 이 결과는 실기기 앱 흐름 기준의 신규 generation/재가입 동작 확인이며, 운영 DB 내부 generation row/삭제명부/원장 association을 직접 조회한 증거와는 구분한다.
- Production 배포/운영 DB 동기화/Git merge·push 없음.
### Android 소셜 로그인 교차검증 — 기존 전화번호 충돌 관찰
- 사용자 실기기 흐름:
  1) Naver 로그인 성공 → 로그아웃.
  2) Google/Kakao/Apple을 각각 신규 인증하면 앱은 "처음 이용하시는 계정이에요. 아래 회원 정보를 입력해 가입을 완료해 주세요."로 신규 가입 흐름 진입.
  3) 기존 Naver 회원과 동일한 휴대폰 번호를 입력하고 필수 동의 후 가입 완료를 누르면 서버가 "이미 가입된 휴대폰 번호입니다. 기존 계정으로 로그인한 뒤 소셜 계정을 연결해 주세요."를 반환.
- 코드 확인 결과 이는 member_store의 phone UNIQUE + PHONE_EXISTS 보호동작이며, 인증되지 않은 새 소셜 identity를 휴대폰 번호만으로 기존 회원에 자동 연결하지 않도록 하는 계정 탈취 방지 동작.
- 현재 앱에는 기존 회원 세션이 살아 있을 때 provider 인증을 하면 인증된 계정 연결 경로로 연결하는 구현과 "계정 연결" UI가 존재함.
- 판정: 백엔드 보안 동작은 EXPECTED/PASS. 단, 로그아웃 상태에서 새 provider 사용자가 기존 전화번호를 입력한 뒤 충돌을 만나는 UX는 개선 여지 있음.
- 안전한 검증/사용 흐름: 기존 Naver 계정 로그인 → 계정 관리/계정 연결 → Google/Kakao/Apple을 순차 연결 → 각 provider로 로그아웃/재로그인 및 세션 지속성 확인.
- 금지: PHONE_EXISTS를 제거하거나 전화번호 일치만으로 provider를 자동 연결하지 않음.
### Android 계정 연결 1~6 단계 PASS
- 사용자 실기기에서 다음 흐름을 모두 PASS로 확인:
  1) Naver 기존 계정 로그인.
  2) 메뉴 → 계정 관리 → 계정 연결 진입.
  3) 로그인 상태 유지 후 Google 계정 연결.
  4) Kakao 계정 연결.
  5) Apple 계정 연결.
  6) 연결된 로그인 계정 목록에 Naver/Google/Kakao/Apple 모두 표시.
- 판정: Android build19에서 인증된 기존 회원 세션을 기준으로 4개 소셜 identity 연결 흐름 PASS.
- PHONE_EXISTS 보호정책과 authenticated provider linking이 실기기에서 함께 정상 동작함.
- 다음 Gate: 로그아웃 후 Google/Kakao/Apple/Naver 각 공급자로 개별 재로그인 → 로그인됨 표시 → 앱 재실행 후 세션 지속성 확인.
### Android 소셜 재로그인/세션 지속성 E2E PASS
- 사용자가 Android build19에서 연결 완료된 Google/Kakao/Apple/Naver 각 공급자에 대해 로그아웃 → 개별 로그인 → 앱 재실행 후 세션 유지까지 모두 PASS로 확인.
- 판정:
  - Google: 재로그인 + 재실행 세션 유지 PASS.
  - Kakao: 재로그인 + 재실행 세션 유지 PASS.
  - Apple: 재로그인 + 재실행 세션 유지 PASS.
  - Naver: 재로그인 + 재실행 세션 유지 PASS.
- Android build19 계정 연결 4종 + 각 provider 독립 로그인 + 세션 지속성 E2E 모두 PASS.
- 다음 남은 모바일 핵심 Gate는 Android 회원탈퇴 → 재실행 후 미로그인 → 동일 계정 재가입 흐름 교차검증.
### Android 회원탈퇴 후 재실행
- 사용자가 Android build19에서 회원탈퇴를 완료하고 앱의 `회원탈퇴가 완료되었습니다.` 메시지를 직접 확인.
- 이어서 adb force-stop → launcher 재실행 수행, com.onaria.app process PID 확인 PASS.
- 다음 확인은 재실행 후 메뉴의 `로그인하지 않음` 상태 유지 여부.
- 유지 확인 시 Android 회원탈퇴 → 세션 폐기 → 재실행 후 미로그인 E2E PASS로 판정.
### Android 회원탈퇴/세션 폐기 E2E PASS
- 회원탈퇴 완료 메시지 확인 후 앱 강제 종료 → 재실행 수행.
- 재실행 후 사용자가 메뉴에서 `로그인하지 않음` 문구를 직접 확인.
- 판정: Android build19 회원탈퇴 → 세션 폐기 → 앱 재실행 후 미로그인 상태 유지 E2E PASS.
- 다음 Gate: 탈퇴한 동일 계정 재로그인 → `처음 이용하시는 계정이에요` 확인 → 최소 한 공급자로 재가입 완료.
### Android 탈퇴 후 동일 계정 재가입 E2E PASS
- 사용자가 탈퇴했던 동일 계정으로 다시 로그인.
- `처음 이용하시는 계정이에요` 신규 가입 안내 확인.
- 회원정보 입력 및 가입 완료.
- 가입 후 해당 공급자로 로그인된 상태 확인.
- 판정: Android build19 탈퇴 → 세션 폐기 → 동일 계정 신규 가입 흐름 E2E PASS.
- 모바일 계정 lifecycle 교차검증 요약:
  - iPhone: Naver/Google/Kakao/Apple 로그인 + 재실행 세션 유지 PASS, 회원탈퇴 + 세션 폐기 PASS, 동일 계정 재가입 흐름 PASS.
  - Android: Naver/Google/Kakao/Apple 계정 연결 PASS, 각 provider 독립 로그인 + 재실행 세션 유지 PASS, 회원탈퇴 + 세션 폐기 PASS, 동일 계정 재가입 흐름 PASS.
## 2026-10-10 최종 모바일/Release Gate 갱신

### 실기기 계정 lifecycle
- iPhone Release 1.0.0(19): Naver/Google/Kakao/Apple 신규 로그인, 앱 완전 재실행 후 세션 유지, 회원탈퇴, 재실행 후 `로그인하지 않음`, 탈퇴 후 동일 계정 신규 가입 흐름 PASS.
- Android Release 1.0.0(19): Naver/Google/Kakao/Apple 계정 연결, 각 provider 독립 로그인, 앱 재실행 세션 유지, 회원탈퇴, 재실행 후 `로그인하지 않음`, 탈퇴 후 동일 계정 신규 가입 흐름 PASS.
- Apple identity가 연결된 회원은 iPhone/Android 모두 탈퇴 시 Apple 재인증을 요구했고, 재인증 후 탈퇴 완료. 실제 Apple 인증/재인증/탈퇴 E2E는 이제 PASS로 갱신한다.
- 과거 문서의 `실제 Apple 인증·철회·탈퇴 NOT RUN/BLOCKED` 표기는 당시 시점 기록이며 현재 실기기 결과로 superseded.

### 최종 회귀
- backend 전체: 471 PASS / 0 FAIL.
- Flutter: 166 PASS / 1 SKIPPED, All tests passed.
- flutter analyze: error 0 / warning 0 / info 17. 명령 자체는 info lint 때문에 exit 1이며 오류/경고 실패와 구분한다.
- 버전 동기화 후 backend health 관련 target test 12 PASS / 0 FAIL.

### 버전 정합화
- Android/iOS 설치 및 산출물 metadata: 1.0.0(19).
- pubspec.yaml을 1.0.0+19로 정합화.
- backend package/package-lock을 1.0.0으로 정합화.
- `/health`가 status와 함께 version(기본 1.0.0), build(기본 19)를 노출하도록 변경. 운영에서는 ONARIA_VERSION/ONARIA_BUILD env로 override 가능.
- Production 배포는 수행하지 않았으므로 현재 운영 health가 이 버전을 노출한다고 보고하지 않는다.

### 현재 남은 Release Gate
- PASS: 모바일 소셜 로그인 4종, 계정 연결, 로그아웃/세션 유지, 회원탈퇴/세션 폐기, 탈퇴 후 재가입, Android/iOS build19 서명/설치/실행.
- PASS: backend471, Flutter166(+1 skipped), Android/iOS 1.0.0(19) metadata, iOS codesign strict/deep.
- OPEN: App Store Distribution archive/스토어 제출용 최종 검증.
- OPEN: 실제 운영 백업 전체 범위·최장 복원 가능 시점·만료/삭제 명부 적용 증거.
- OPEN: 운영 회원 identity ↔ usage ledger 실제 association 및 자동 파기/보유 예외 정책.
- OPEN: origin/main 최종 통합 범위와 현재 85-entry working tree 정리. reset/clean/merge/rebase/commit/push는 아직 하지 않음.
- 콘솔 전체 Return URL 문자열은 화면에서 끝까지 별도 캡처하지 않았으나 Android 실제 Apple 로그인/재인증 E2E가 성공하여 runtime callback 동작 근거는 확보됨.

### 변경 안전성
- Production 배포, 운영 DB 변경/동기화, 기간 파기 적용, 원격 Git merge/rebase/commit/push, 스토어 제출 없음.
- 다른 프로젝트 변경 없음.
### 버전 정합화 후 최종 signed build 재검증
- pubspec 1.0.0+19 및 backend release version 정합화 후 protected local Kakao native app key를 dart-define로 주입하여 Android/iOS Release 재빌드.
- Android Release build PASS: com.onaria.app, versionName 1.0.0, versionCode 19.
- iOS signed Release build PASS: CFBundleShortVersionString 1.0.0, CFBundleVersion 19.
- iOS codesign --verify --deep --strict PASS.
- build 전/후 git status hash 동일: 빌드가 작업 tree를 추가 변경하지 않음.
- 비밀 키 값은 출력/문서화/소스 하드코딩하지 않음.
## origin/main 최종 통합 후보 — 1.0.0(19)
- 현재 작업 tree를 직접 merge/rebase/reset하지 않고 `/tmp` 격리 worktree를 `origin/main`에서 생성해 기존 인증/삭제 보호 패치를 적용.
- 후보에 앱 버전 `1.0.0+19`, backend package `1.0.0`, `/health` version/build 노출을 추가.
- `.gitignore`의 로컬 SSH 접속 정보 추적 방지와 최신 Store Submission Checklist를 후보에 포함.
- 최종 패치: `docs/releases/patches/ONARIA_ORIGIN_MAIN_RELEASE_CANDIDATE_1.0.0_19_2026-10-10.patch` (33 files).
- 새 origin/main 격리 사본에서 `git apply --check` PASS, 실제 apply 후 `git diff --check` PASS.
- 보호된 Kakao/Naver/Android signing 실제 값이 패치에 포함되지 않았음을 값 일치 방식으로 검사 PASS.
- root와 적용 후보의 핵심 런타임 파일(signup, Apple Android auth, Google/Naver auth, member store/schema/session/server, Apple revocation, optional profile, AI consent 등) byte 비교 SAME.
- 후보 backend 전체 471 PASS / 0 FAIL.
- 후보 Flutter 166 PASS / 1 SKIPPED, All tests passed.
- 후보 analyze: error 0 / warning 0 / info 17 (info lint 때문에 exit 1).
- 후보 Android Release build PASS, package com.onaria.app / 1.0.0(19).
- 격리 worktree iOS build는 SPM/Xcode clean compile이 장시간 진행되어 시간 절약을 위해 중단. 이는 컴파일 오류 판정이 아님. 원본 작업 tree에서 동일 버전/동일 보호 Kakao define 기준 iOS signed Release 1.0.0(19) build 및 codesign strict/deep PASS 근거 유지.
- SOURCE INTEGRATION GATE 판정: **후보 구성/적용/회귀 PASS, 실제 main merge/commit/push는 NOT RUN**.
- Production/운영 DB/스토어 제출 변경 없음.
## 운영 백업/보존 Gate 진행 — 2026-10-10
- Production read-only 감사 결과: onaria-backend.service active, 운영 /health는 여전히 {status:ok}만 반환하여 1.0.0(19) 미배포 상태.
- ONARIA 전용 root/user cron 없음. systemd에서 ONARIA backup/retention/purge timer 없음. dpkg-db-backup.timer는 OS 패키지 DB용으로 ONARIA 데이터 백업이 아님.
- 배포/롤아웃 보호 DB 사본 확인: 2026-10-06 members DB 2개, 2026-10-07 /opt/onaria-backups previous/data의 members/member-sessions/ai_usage 2세트, rollout db-before-rollout members/sessions 1세트.
- 디스크: 약 48GB 중 44GB 여유(9% 사용). 기존 백업 삭제/만료 작업 없음.
- 판정: 배포 시점 보호 백업은 존재하지만 정기 자동 백업은 현재 미구현/미설치.

### 정기 백업 후보 구현
- 신규 backend/scripts/backup_databases.js: members.sqlite, member-sessions.sqlite, ai_usage.sqlite를 SQLite Online Backup API로 독립 snapshot 생성.
- 각 snapshot quick_check=ok, SHA-256 manifest, 디렉터리0700/파일0600, 부분 실패 시 해당 회차 정리, live data 내부 backup root 거부.
- 기존 백업 자동 삭제/retention purge는 의도적으로 포함하지 않음.
- 신규 backend/test/periodic_backup.test.js 2 PASS.
- backend 전체 회귀 473 PASS / 0 FAIL.
- systemd 후보 ops/onaria-backup.service + ops/onaria-backup.timer 준비. 매일 03:17 KST, Persistent=true, 최대10분 random delay.
- 운영 적용 runbook: docs/releases/ONARIA_BACKUP_RUNBOOK_2026-10-10.md.

### Release 후보 갱신
- origin/main 최종 통합 패치를 정기 백업 코드/테스트/unit/runbook 포함 38-file 후보로 갱신.
- fresh origin/main worktree에서 최종 patch git apply --check PASS, 실제 apply 후 git diff --check PASS.
- 버전 1.0.0+19/backend1.0.0 유지, backup script/timer 포함 확인.
- 보호된 Kakao/Naver/Android signing 실제 값이 패치에 포함되지 않음: SECRET_VALUE_SCAN PASS.
- Production 배포/서비스 재시작/timer 설치/운영 DB 변경/백업 생성/파기 적용/merge/commit/push는 아직 NOT RUN.

### 다음 승인 Gate
- 다음 실제 단계는 Production 변경이므로 별도 사용자 승인 필요:
  1) /opt/onaria-periodic-backups 생성(0700, ubuntu 소유)
  2) release 후보 backend 배포 또는 backup script만 안전 배치
  3) onaria-backup.service 1회 수동 실행 및 생성 snapshot 무결성/권한 검증
  4) 별도 임시 경로 복원 검증
  5) PASS 후 onaria-backup.timer enable/start
- 자동 삭제/30일·37일 retention은 아직 승인/적용 대상 아님.
## Production 정기 백업 설치/검증 — 2026-10-10
- 사용자 승인 후 Production 백업 서비스 설치를 진행.
- `/opt/onaria-periodic-backups` 생성, ubuntu:ubuntu / 0700.
- `/opt/onaria/backend/scripts/backup_databases.js` 설치.
- `/etc/systemd/system/onaria-backup.service`, `onaria-backup.timer` 설치 후 daemon-reload.
- 1회 수동 backup service 실행 PASS: Result=success, ExecMainStatus=0.
- 생성 snapshot: `/opt/onaria-periodic-backups/2026-10-10T07-20-59-531Z`.
- 생성 파일: members.sqlite, member-sessions.sqlite, ai_usage.sqlite, manifest.json.
- 권한: snapshot dir 0700, DB/manifest 0600.
- manifest quickCheck=ok 및 SHA-256 기록 확인.
- 별도 재검증 quick_check: 3 DB 모두 ok.
- `/tmp` 임시 복원 sandbox에서 integrity_check=ok 및 예상 테이블 확인 후 sandbox 삭제 PASS.
- `systemd-analyze verify` service/timer PASS.
- `onaria-backup.timer` enable --now 완료: enabled + active.
- 다음 예약 실행: 2026-10-11 03:19:22 KST (RandomizedDelaySec 반영).
- 설치/검증 중 onaria-backend.service는 계속 active, 내부/외부 health 모두 `{"status":"ok"}`.
- Production 앱/backend 코드 버전 1.0.0(19) 배포는 수행하지 않음. 운영 DB 내용 변경/복원/삭제 없음.
- 자동 retention/30일·37일 삭제는 적용하지 않음.

### 운영 백업 Gate 판정
- 정기 자동 백업: PASS (설치·1회 실행·timer 활성·무결성 검증).
- 별도 임시 복원 검증: PASS.
- 기존 과거 배포 백업 + 신규 주기 snapshot 존재 확인.
- 전체 오프사이트 복제본/장기 retention 정책/삭제 명부와 백업 재적용 자동화는 별도 OPEN.
## 삭제명부/보존 Gate 후보 강화 — 2026-10-10
- 운영 읽기 감사: SOUL_USAGE_RETENTION_DAYS=62. 현재 usage ledger는 cost_requests 288건, oldest 2026-09-21T10:31:07.893Z, newest 2026-10-10T01:22:02.841Z, pending 0. 현재 시점에서 62일보다 오래된 기록 없음.
- member session DB: 1 session, expired 0. member DB: 1 member / 1 identity. 집계만 확인했고 개인정보 값은 출력하지 않음.
- usage ledger는 reserve/startCall 등 실제 원장 활동 시 recoverAt()에서 non-pending 62일 초과 행을 자동 pruning하는 코드가 이미 존재.
- member 로그인 계정과 AI usage owner_id는 서로 다른 identity 체계이며, provider/sub → usage owner를 추측해 연결하지 않는 기존 fail-closed 원칙 유지.

### 독립 삭제명부 후보 구현
- 신규 `backend/src/privacy/deletion_manifest.js`: 삭제된 member generation의 member_id + deleted_at만 별도 SQLite에 영속 저장.
- 계정 삭제 성공 경로 전에 deletion manifest를 우선 기록하고, 모든 회원 조회는 tombstoned member generation을 로그인/계정 접근 대상으로 인정하지 않도록 후보 app.js에 연결.
- server startup에서 manifest를 먼저 열고 member store에 reapply하여 오래된 백업/복구로 되살아난 삭제 generation을 다시 제거하도록 후보 연결.
- 탈퇴 후 같은 provider로 재가입하면 AUTOINCREMENT로 새 member generation이 생성되고 기존 tombstone member_id와 분리됨.
- deletion manifest DB는 개인정보 원문/전화번호/provider subject를 저장하지 않고 member numeric generation id와 삭제 시각만 저장.
- backup 후보 기본 목록에 `deletion-manifest.sqlite` 추가. 현재 Production에 설치된 backup script는 아직 3 DB 버전이며, manifest 기능 배포 후 함께 갱신해야 함.
- focused deletion/backup tests 6 PASS.
- backend 전체 회귀 477 PASS / 0 FAIL.
- fresh origin/main 후보 patch를 42 files로 갱신, apply-check PASS / diff-check PASS / secret value scan PASS.

### Android Store artifact
- Release AAB 1.0.0(19) 생성 PASS: `build/app/outputs/bundle/release/app-release.aab`, 약61.6MB.
- release buildType는 정식 release signingConfig 사용. jarsigner verify exit0, signer certificate expiry 2054-02-13 확인.
- production API source default는 `https://api.onaria.ai.kr`; release에서 HTTP/IP/loopback override를 거부하는 ApiConfig 보호 로직 확인.
- `flutter analyze lib test example --no-fatal-infos` PASS(exit0, info17 / error0 / warning0).
- analytics/crash reporting SDK scan에서 Firebase Analytics/Crashlytics/Sentry/Mixpanel/Amplitude/AppCenter/Datadog/New Relic 의존성 미확인. 로컬 engagement event 주석만 확인.

### 현재 Gate
- PASS: 모바일 로그인/세션/연결/탈퇴/재가입 E2E, backend477, Flutter166(+1 skipped), Android APK/AAB Release, iOS signed Release, Production 정기 backup + restore sandbox.
- READY-BUT-NOT-DEPLOYED: deletion manifest + restore reapply + manifest backup 후보.
- OPEN: deletion manifest 후보 Production 배포/기존 backup service 4-DB 갱신, App Store archive/TestFlight, Play Console/App Store Connect 실제 메타데이터/심사 항목, final commit SHA/merge/push.
- Production 앱 1.0.0(19) 배포·Git merge/commit/push·스토어 제출은 아직 미실행.
## 최종 Release 후보 무결성 — 2026-10-10
- origin/main fresh worktree에서 최종 42-file patch `git apply --check` PASS.
- 실제 apply 후 `git diff --check` PASS.
- 적용 결과 변경 파일 상태 36 entries.
- Release patch SHA-256: `3eb2600c15bd5b3cc2a3c768c160b96de11b1493d3483a71c9cb6f2358399ab8`.
- 보호된 Kakao/Naver/Android signing 실제 값 미포함 재검사 PASS.
- Production usage retention은 62일 설정이며 현재 oldest usage가 2026-09-21로 62일보다 짧고 pending 0.
- deletion manifest 후보는 아직 Production 미배포. 기존 Production backup timer는 3 DB 백업을 계속 수행 중이며 release 배포 후 manifest DB 포함 4 DB 버전으로 갱신 필요.
- 최종 commit SHA/merge/push/Production 1.0.0(19) 배포/스토어 제출은 아직 NOT RUN.

## 오늘 마음 카드·마음대화 예시 확장 확인 (2026-10-10)
- 사용자 요청에 따라 ONARIA 원본 로컬 소스에서 예시 콘텐츠를 확장했다. 앞선 main 후보와 구분하는 후속 변경이며 후보 패치/설치된build18에 적용됐다고 표시하지 않는다. 기존 인증/배포 변경 유지, 운영/실기기 조작 없음.
- 카드 목록: 기본 EmotionType16종은 고정. 사용자가 직접 입력한 기타 마음의 추출 키워드가 같은 기기에서30회 이상 기록되면 최대12개 추가 카드로 노출되며 preset/custom 사용빈도로 순서를 정한다. counts는 서버 공동 학습이 아니라 로컬 SharedPreferences다.30회 임계·저장 키·기록은 변경하지 않았다. 문장에서 일반 명사도 추출하므로 감정 분류 AI가 자동 새 감정 종류를 발명하는 구조는 아니다.
- 예시 목록: 질문/최근 메시지/선택 감정/서버 answerExamples로 동적으로 답변 예시 선택. 서버 예시의 필터·최대3개 제한 및 질문 intent별 fallback 유지. 기본 card별 상황 예시는 정적 작성 데이터이며 사용자 대화를 저장해 자동 학습/누적하지 않는다. custom 마음은 complexity 기반으로 시작하므로 각 신규 키워드 전용 예시가 자동 생성되는 것은 아니다.
- 카드별 상황 예시3→6,16종 총48→96(추가48). 불안/외로움/지침/분노/슬픔/복잡함/감사/기쁨/두려움/거부감/놀람/행복/기대/감탄/벅참/질투 각각 일·관계·일상 장면 보강. emotion_situation_examples.dart로 분리하고 conversation_page가 참조. 경전·교리 생성/추가 없음, 외부 AI 비용/요청/수집 없음.
- 관련17 PASS: 모든16종6개·중복 없음·crisis 판정 없음·질문 intent 연동·서버 새 답변 예시 반영·미지 선택 질문 fallback 금지·기존30회카드 승격. 개인정보 대화를 자동 저장하거나 사용자 기록을 삭제하지 않았다.
- 변경: lib/features/conversation_page.dart, 신규lib/features/emotion_situation_examples.dart, 신규test/emotion_situation_examples_test.dart, 본 문서. 현재build18 유지/미설치. backend/인증API 변경 없음.30일/37일 및 기존 운영/외부 인증·철회/병합/커밋/푸시 보류 유지. 별도 Release 빌드 NOT RUN(콘텐츠/참조만 변경,Flutter 회귀/분석으로 확인).

최종 Flutter168 PASS/1 SKIPPED,관련17 PASS 및 화면 포함28 PASS. analyze 오류/경고0 info17. 로그 /tmp/onaria-examples-full.log, /tmp/onaria-examples-new.log, /tmp/onaria-example-related.log, /tmp/onaria-examples-analyze.log. diff check PASS. 실제 기기 화면 검증은 미실행.
## 마음대화 전용 commit/push/Production 검증 — 2026-10-10
- 기존 dirty 작업 tree와 분리한 `/tmp/onaria-mind-conversation-release-20261010` worktree에서 branch `release/mind-conversation-20261010` 생성.
- 마음대화 전용 범위 27 files만 선별: 외부 AI 동의 gate, 상황 예시, 대화 UI, 말씀 낭독/출처, WEB/KRV asset 정리, LLM request consent version, backend consent gate 및 관련 테스트.
- backend 전체(해당 branch 기준) 440 PASS / 0 FAIL.
- Flutter 146 PASS / 1 SKIPPED, All tests passed.
- `flutter analyze lib test example --no-fatal-infos` PASS; error0/warning0/info16.
- secret pattern scan PASS, git diff --check PASS.
- commit: `6e8b55fe4e7d7fb6e0c7a8de9a5d300c5cf8ea0a` (`feat: harden mind conversation consent and guidance`).
- GitHub push: `origin/release/mind-conversation-20261010` PASS.
- Production precheck에서 `/opt/onaria/backend/src/conversation_service.js`와 `schema.js` SHA-256이 위 commit의 동일 파일과 byte-identical 확인.
- Production service는 해당 파일 mtime(2026-10-07 14:41:43 KST) 직후 14:41:44 KST에 시작되어, 현재 running process가 동일 구현을 로드한 상태로 판정. 동일 파일을 불필요하게 재복사/재시작하지 않음.
- Production synthetic no-consent mind-chat smoke: HTTP 200, stage=need, riskLevel=0, agent=integrated, memorySummary 존재, shouldOfferVerse=false. 외부 AI 동의 없는 요청의 local-safe 경로 정상.
- Production backend active 및 health 정상. 운영 DB 변경 없음.

## 웹↔앱 parity Codex 지시서
- 생성: `ONARIA_CODEX_WEB_APP_PARITY_2026-10-10.md`.
- 목표: 앱 1.0.0(19)의 브랜드/마음대화/4종 로그인/계정연결/Apple 탈퇴 재인증/AI 동의/성경 출처/개인정보 동선을 공개 웹과 반응형으로 정합화.
- 웹 parity 작업 자체의 Production 배포/commit/push는 Codex 지시에서 금지하고, 검증 결과를 별도 release 문서에 기록하도록 지정.

## 웹·앱 정합화 실행 결과 (2026-10-10)
ONARIA_CODEX_WEB_APP_PARITY_2026-10-10.md 지시 실행. 홈/흐름/FAQ/footer와 반응형 밝은 스타일을 현재 앱 언어에 맞춤. 계정·AI동의·삭제 경계·출처/미출시 고지 유지. 상세 docs/releases/ONARIA_WEB_APP_PARITY_2026-10-10.md.
backend478 PASS,웹node9 PASS,Playwright website8 PASS/전체20 PASS/계정삭제 포함 추가 WCAG7 PASS. 요구360/390/768/1024/1440 폭과 public4개 route200·link/CTA·키보드·자동 대비/접근성 확인. secret 알려진 패턴/diff check PASS. 실제 앱/운영 인증 미실행,기기/운영 데이터 유지. Production 배포/커밋/푸시 NOT RUN. 기존 앱/pubspec/backup/manifest 변경은 시작 전 상태 보존.

## 2026-10-10 Existing-member social recovery candidate

- Root cause confirmed from Production read-only aggregate: current Production has 1 member and 1 linked provider identity (`google`); unlinked providers are correctly treated as new identities, and re-entering an existing phone hits `PHONE_EXISTS`.
- Added a fail-closed recovery path: duplicate phone never auto-merges. A user must prove an already-linked social identity before a new provider identity is attached to the existing member.
- New endpoint candidate: `POST /v1/auth/provider/recover-link` verifies both the new provider proof and a different existing provider proof, rejects unknown existing identities, same-provider account merging, and identities owned by another member.
- App candidate changes `PHONE_EXISTS` into an explicit existing-account verification flow instead of a dead end. Profile fields are not used as account proof.
- Verification: focused backend recovery tests 3 PASS; focused Flutter recovery/signup tests 7 PASS; backend full 482 PASS / 0 FAIL; `flutter analyze --no-fatal-infos` produced 0 errors/warnings and 17 pre-existing/info-only lint messages; full Flutter run reached 165 PASS / 1 skipped before being stopped because the long conversation fixture suite continued running, with no failure observed before stop.
- Production database was read only. No member, identity, or session rows were changed. Candidate is not deployed to Production and Build 19 on devices is unchanged.

## 2026-10-10 Social identity architecture correction (supersedes temporary recovery candidate)

The earlier `recover-link` candidate was discarded before deployment. The permanent design now separates authentication concerns instead of repairing `PHONE_EXISTS` after the fact.

- Canonical member identity is `members.id` plus verified rows in `member_identities(provider, provider_user_id)`.
- Name, phone, and church are profile fields only and never prove account ownership.
- Unverified phone is no longer unique in the candidate schema. Production read-only inspection confirmed the current Production schema is nullable but still has a UNIQUE auto-index on `phone`; changing that constraint requires an explicit backed-up DB migration and has NOT been applied.
- Existing social login: `POST /v1/auth/provider/session` only.
- New social signup: `POST /v1/auth/provider/signup` only; an already-registered provider identity returns structured `IDENTITY_ALREADY_REGISTERED` rather than silently logging in.
- Provider linking: dedicated authenticated `POST /v1/account/providers`; it requires an existing ONARIA member session plus a freshly verified provider credential and rejects provider identities owned by another member.
- New-device UX is a state machine: unknown provider identity -> choose `기존 ONARIA 계정에 연결` or `새 계정 만들기`. Linking requires signing into a different provider already attached to the existing member; profile fields are never used for merge.
- Same-provider different-account merging remains blocked unless a future independently verified recovery factor is added.
- Production remains unchanged. No DB row or schema mutation was performed.
- Verification after the architecture correction: backend full 483 PASS / 0 FAIL; focused Flutter identity/link/signup tests 7 PASS; `flutter analyze --no-fatal-infos` has 0 errors/warnings and 15 info-only lints.

## 소셜 identity Build 20 후속 실행
지시서 전체 및 compliance 사전점검 후 별도 후보 검증. Backend488 PASS, identity UI3 PASS, analyze 오류/경고0. 운영 최신 백업 후 최소 인증 코드 및 UNIQUE(member_id,provider) 적용 PASS, 회원1/identity2 및 행·소유권·시퀀스 보존. 내부/공개 health1.0.0 build20 PASS. 실제 Android 시작본은 이미20이며 후보 업데이트/교차 인증은 진행 중. 상세 `ONARIA_SOCIAL_IDENTITY_BUILD20_2026-10-10.md`. 기기/운영/격리 결과는 구분하며 최종판정 BLOCKED. 병합/리베이스/커밋/푸시/스토어 제출 및 미정30/37일 정책 적용 없음.

Build20 추가 확인: Flutter174 PASS/1 SKIPPED, 새 identity UI4 PASS(320px/글자2배 포함). 초기 작업 트리 해시 복원 및 두 패치 순서 적용/최종 후보 일치 PASS. S22/A33 Google 로그인 성공 사용자 확인 + 회원1/identity2 유지 PASS. 나머지 provider 및 iPhone 검증 진행 대기, 운영 Release Gate 완료 선언하지 않음.

### Build20 현재 단계 최종 기록
- 최종 backend489 PASS/0FAIL, Flutter174 PASS/1SKIPPED, analyze 오류/경고0/info15. 로컬 서버 시작 삭제 명부 변수명 오타 수정·실제 시작/종료 smoke PASS(운영 server.js 미교체).
- 최종 S22/A33 Release20 데이터 유지 업데이트/실행 PASS; Google 양 기기 성공 사용자 확인 및 회원1/identity2 불변. 이후 양 기기 account GET200 고정 진단 확인. Naver 사용자 인증/Apple 전체callback 확인 응답 대기, Kakao실검증 NOT RUN.
- APK/AAB 기존 Release 인증서 일치 및 iOS Bundle/Team/1.0.0+20·엄격서명 PASS. iPhone 실제 설치본1.0.0+19,20설치/인증 회귀 NOT RUN(Android 완료 뒤 진행). 실제 삭제·외부 철회 없음.
- Production HTTP200/statusok/1.0.0/build20, integrityok/FK0, 회원1(Google1/Kakao1 identity2) 유지. 30/37정책,병합/리베이스/커밋/푸시/스토어 제출 미실행. 상세 단계표와 산출물 manifest 작성. 현재 최종판정 BLOCKED: 사용자 공급자 인증 및 나머지 실검증 필요.

### Apple 전체 Return URL 및 A33 Naver SDK 실패 후속
Apple 전체 Return URL 사용자 일치 확인 + 운영 설정 내부 대조 true → 설정 Gate PASS. 실제Apple 인증은 NOT RUN. A33 Naver 로그인/동의 이후 SDK 단계 FAIL, logout HTTP204 뒤 provider/session 호출 없음. 원인미확정, 회원1/identity2/integrityok 보존. APK 네이버 보호 설정 실제 resource 일치 확인(값출력없음). raw오류를 노출하지 않는 고정 SDK 분류 추가, 관련9 PASS/analyze오류경고0. A33동일서명 Build20 데이터유지 진단 업데이트 PASS, 재시도code 응답대기. S22/AAB/iOS는 기존최종후보와 구분. 자동회원가입·병합·삭제·외부철회·운영추가변경·커밋/푸시 없음.

네이버 진단 후속 최종 회귀: Flutter176 PASS/1 SKIPPED, 관련9 PASS, analyze오류0/경고0/info15. A33 고정 SDK code를 확인하는 사용자 재시도 대기. 실제 원인·수정완료·네이버실검증 PASS는 선언하지 않음. 운영 추가 변경/회원삭제/외부철회/커밋/푸시 없음.

## A33 네이버 실기기 화면 증거: SDK logged_out
- 사용자 제공 화면에서 `네이버 SDK가 로그인 완료 상태를 반환하지 않았어요. (SDK: logged_out)` 확인. 네이버 로그인·동의 완료 후 실패라는 사용자 보고와 함께 기록. **Naver 실검증 FAIL / 원인 미확정 / 완료 판정 BLOCKED**.
- 설치된 SDK Android 소스의 반환 경로를 확인했다. 로그인 실패 callback에서 `user_cancel` 또는 설명에 cancel이 포함된 경우와, 로그인 성공 callback 이후 access token이 없는 경우가 모두 동일한 loggedOut 상태로 반환된다. 따라서 이 화면만으로 사용자 취소·토큰 누락 중 어느 경로인지 구분할 수 없다. Dart 결과 파서는 대소문자를 정규화하므로 상태 문자열 대소문자 불일치를 이번 원인으로 볼 근거는 없다.
- 다음 진단 조건: 위 두 native 반환 경로를 구분하는 고정 단계 코드만 수집해야 한다. SDK 원문 오류·토큰·계정 정보 출력, 캐시 토큰으로 로그인 성공 간주, loggedOut 무시, 외부 철회 방식의 초기화는 금지한다. 원인 입증 전 SDK/운영 설정을 임의 변경하지 않는다.
- 이번 후속은 읽기 전용 SDK 코드 검토와 문서 기록만 수행. 기기 재설치·운영 변경·회원 데이터 변경·회원삭제·외부 철회·병합·커밋·푸시 없음. 이전 회귀 결과와 이번 신규 실기기 성공을 혼동하지 않는다.

## 사용자 참고 이미지 기반 별빛 웹 테마 — 로컬 완료
- 기준: 사용자 이미지 하단 ONARIA 앱 화면의 짙은 남색·별빛/궤도·금빛 강조·차분한 카드. 이전 밝은 테마 지침보다 최신 사용자 디자인 요청을 우선 적용. App Store Connect 관리 화면을 웹에 복제하지 않음.
- 구현: 공개 웹 전역 남색 배경, CSS 별빛/궤도 장식, 금빛 CTA/포커스, 감정 선택 소개 카드, 대화·기록·FAQ·법적 안내의 공통 색상과 대비. 기존 콘텐츠/링크/동선과 인증 API는 보존. 새 외부 이미지·폰트·추적 요청 없음.
- 변경 파일: backend/public/website/site.css, backend/src/website.js(theme-color), backend/e2e/website-v2.spec.js(기존 support 페이지를 사이트맵/라우트 기대 목록에 반영). 기존 미커밋 변경 위에 추가했으며 폐기 없음.
- TEST PASS: 공개 웹 Node 10/10, 전체 backend489/489, 전체 Playwright20/20. 360/390/430/768/1024/1440 폭·접근성·키보드·reduced-motion·링크·라우트·관리자 기존 회귀 PASS. 초기 E2E1건은 기존 /support 기대 누락으로 실패 후 수정/재검증 PASS.
- 시각 확인: 1024 폭 전체 홈페이지 브라우저 캡처 확인. 결과 이미지 build/onaria-web-results에 생성. 실제 사용자 기록이나 운영 DB를 사용하지 않은 격리 fixture.
- Production 배포 NOT RUN. 앱/기기 Build20 교체 NOT RUN. 운영 데이터/설정/서비스 변경·외부 인증/철회·병합/리베이스/커밋/푸시 없음. 네이버 logged_out 조사 및 기존 Release Gate는 별도로 유지.

## 별빛 웹 테마 운영 적용 — 사용자 승인 후
- 사용자 요청 “웹서버에 적용해”에 따라 기존 SSH 호스트 키 검증을 유지하고 ONARIA 서버/서비스/라우팅 확인. 운영 CSS가 이번 변경 전 로컬 CSS와 정확히 일치함을 확인.
- 배포 PASS: backend/public/website/site.css 한 파일만 기존 소유자/권한 유지하여 원자적으로 교체. 백업 /opt/onaria-backups/web-starlight-20261010-235451/site.css. 공개 CSS SHA256 29e3f3ddaa6c270d0dfe12ed924c1418186c0c108f41a8003c381124e8f6e976 로컬과 일치.
- 서버 JS/theme-color 메타 수정 및 E2E 테스트 파일은 로컬에 유지하고 운영에 복사하지 않음. CSS만으로 테마 적용되므로 서비스 재시작 없이 처리. onaria-backend active 유지.
- 공개 GET PASS: 홈페이지/privacy/terms/account-deletion/assets/site.css 모두200, API health200.
- 운영 DB·인증 설정·회원 데이터·기기 Build20 변경 없음. 병합/리베이스/커밋/푸시 NOT RUN. 운영 디자인 적용이 인증/삭제/보유기간 Release Gate 통과를 의미하지 않음.
- 운영 브라우저 PASS: 360/390/768/1440 폭에서 HTTP200, 남색 테마 확인, 가로 넘침 없음, page error0. 캡처 build/onaria-starlight-production-1440.png.

## 인증 UX 지시서 사전점검 — 2026-10-11
- 프로젝트 ONARIA /Users/ari/ARI/projects/onaria, branch codex/apple-android-20261006, HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b. AGENTS.md와 ARI_COMPLIANCE_STANDARD 전체 읽음.
- 현재 Git status133항목 미커밋. 기존 변경 보존. pubspec1.0.0+20, naver_login_flutter는 기존 third_party 로컬 경로 참조임을 확인. 과거 설치/테스트 보고를 현재 결과로 대체하지 않음.
- 요청된 ONARIA_CODEX_AUTH_UX_INSTRUCTIONS_v1.0.md는 프로젝트/Downloads/Desktop/Documents/tmp 파일 목록 검색에서 미발견, 메시지 첨부 내용도 접근 불가. 지시서 전체 읽기 및 지시서 순서에 따른 수정 BLOCKED: 파일 또는 정확한 경로 필요. 지시서 요구를 추측 적용하지 않음.
- 이번 사전점검 중 앱 소스 수정/버전 변경/실기기 설치·인증/운영 변경/커밋/푸시 NOT RUN. 기존 데이터 유지. 현재 백엔드 격리 회귀 실행 후 결과를 추가 기록.
- 이번 실행 TEST: backend489 PASS/0 FAIL(격리). Flutter/analyze/build/device/API/CI NOT RUN(지시서 미확보 사전점검). COMMIT/PUSH NOT RUN—사용자 보류.


## 2026-10-11 인증 UX 지시서 v1.0 재개 — 로컬 후보 진행 기록

지시서 전체, AGENTS.md, ARI_COMPLIANCE_STANDARD 및 기존 인증 감사/방향 문서를 읽고 진행했다. 기준 HEAD는 `1aef3815c8e25022a948c4307e1c755e5cc8507b`, 브랜치는 `codex/apple-android-20261006`이다. 기존 미커밋 작업을 보존했고 작업 시작 status와 수정 전 주요 파일 사본은 임시 로컬 경로에 보관했다. origin/main 비교는 ahead 5 / behind 4이며 병합하지 않았다. 이전 단계 보고는 이번 후보의 실기기 PASS 증거로 사용하지 않는다.

### 버전·설치 상태
- 소스 버전은 1.0.0+20 유지. 새로운 후보 번호는 App Store Connect/TestFlight와 Google Play 최고 사용 번호 확인 전 미확정.
- 사용자 확인: S22 20, A23 20, iOS 19. 읽기 조회한 연결 모델은 A33(SM_A336N) 20이므로 A23/A33 명칭 차이는 미확인으로 남긴다.
- 이번 APK/AAB는 로컬 컴파일용 20 후보이며 이전 설치 20과 동일 소스라고 간주하지 않는다. 기기 설치/로그아웃/인증/탈퇴는 이번 작업에서 실행하지 않았다.

### 단계별 실제 수정 및 Gate
| 단계 | 반영한 로컬 구현·증거 | 상태와 미완료 |
|---|---|---|
| 0 사전점검 | 경로/HEAD/브랜치/dirty/원격·CI 확인, 기존 변경 보존 | PASS — 로컬 사전점검. 최신 dirty 후보 CI는 NOT RUN |
| 1 네이버 | 기존 라이선스 보존 포크 재사용. native 중복 callback 차단, 토큰 없는 성공/명시적 취소/정리 실패 분리. 로그인 timeout 뒤 raw callback 종료 전 재시도 차단. 사전 SDK 정리 지연도 동일 시도 안에서 기다림 | 격리 회귀 PASS. A33/S22 Chrome·앱 복귀·재생성 실제 인증 BLOCKED. 원인 미확정 유지 |
| 2 기록 소유권 | 서버 account.member.id를 검증하여 로컬 기록 namespace 구성. 이전 공용 키는 수량 안내만 제공. 명시적 복사 primitive는 원본 보존/반복 실행/부분 쓰기 재개/타 회원 claim 차단 | 격리 PASS. OS 소유 확인, 사용자가 선택하는 가져오기 UI, 기존 대상 기록 병합·완전 rollback은 미완료. 실제 사용자 이관 NOT RUN |
| 3 계정 경계 | member/guest 분리. 계정 세대 변경 시 기존 store 접근 거부, Navigator·engagement 재생성, 알림 정리. 늦은 load/draft 작업 차단 | 저장소 격리 PASS. 모든 기기 화면 전환·알림 경합 E2E 미검증 |
| 4 가입·로그인 | 이름/전화/교회 초기 입력 제거. 18세 자기 확인·필수 동의 유지. 최근 성공 제공자 힌트, 중복 탭 방지, 409 기존 계정 재조회, 서버 완료/기기 저장 실패 안내 분리. 동의 버전·시각 보존 | 로컬 UI/API 회귀 PASS. 18세 자기 확인은 신원·나이 인증이 아님. 각 제공자 실가입·응답 유실 기기 재현 NOT RUN |
| 5 연결·민감 작업 | 서버에서 기존 회원의 reauthProvider/reauthCredential과 대상 owner를 대조. 연결은 새 제공자 증명도 요구. 비동기 증명 이후 원래 세션 재검증. 타 owner/마지막 수단 차단 유지 | 격리 PASS. 오래된 동일 제공자 credential의 재사용을 엄격한 최신 인증으로 제한하는 서버 challenge/유효시간 정책은 추가 검토 필요 |
| 6 로그아웃·탈퇴 | secure storage write/delete 완료 확인과 정리 실패 재시도 안내. 서버 탈퇴 성공 확인 후 해당 member prefix만 기기 정리. durable pending marker로 재시작 정리 재시도. 늦은 A 응답으로 B 세션 clear하지 않음 | 격리 PASS. 실제 외부 철회/운영 DB 삭제 NOT RUN. 삭제 응답 유실 결과조회·marker 자체 저장 실패·백업 운영 연계는 미완료 |
| 7 전체 회귀 | Flutter/backend/Web 회귀, Android/iOS 컴파일 결과를 아래에 별도 기록 | 출시 HOLD — 실기기/운영/최신 후보 CI 미통과 |

### 회원번호와 실제 데이터 연결
| 데이터 | 현재 소유권/접근 | 이관·삭제·복원 범위 |
|---|---|---|
| 서버 회원·소셜 identity | 기존 canonical memberId/provider 고유 ID 사용. 이름/전화/이메일로 자동 병합하지 않음 | 격리 owner proof·연결 충돌·삭제 회귀. 운영 반영 없음 |
| 서버 세션 | 검증된 provider identity로 canonical member 조회 | 민감 작업의 proof 후 재검증. 모든 linked identity 세션 폐기 기존 회귀 유지 |
| 마음카드·사용량·감정 선택 집계 | 검증된 memberId별 v2 namespace, 미로그인 guest 별도 | 해당 회원 prefix만 삭제. legacy 공용 원본 자동 귀속/삭제 없음 |
| 초안·최근 말씀·engagement/저장 말씀/알림·AI 동의 | 동일 member namespace와 세대 lease | 전환 뒤 예전 읽기/쓰기 거부. 알림 제거와 컨트롤러 재생성 |
| 이전 기기 공용 기록 | 소유자 미확정, 원래 키 그대로 보존 | 계정 관리의 개인정보 화면에서 수량 안내. 가져오기 기능은 소유 확인 준비 전 비활성 |
| 서버 대화·사용량·비용 원장 | 기존 운영 어댑터/식별자 스키마 검토 범위를 유지 | 기기 namespace 변경만으로 서버 기록 소유권 완성이라고 주장하지 않음. 운영 연결 Gate 별도 |
| 삭제 명부·백업 | 기존 격리 삭제·복원 차단 구현 유지 | 독립 명부 운영 연결·외부 사본·최장 복원 시점 미확인. 30일/37일 적용하지 않음 |

### 실패·복구와 호환성
- 가입 서버 성공 후 secure storage/부가 캐시 저장 실패는 서버 가입 실패로 안내하지 않는다. 같은 제공자로 재조회하면 기존 canonical 회원을 반환하는 회귀를 추가했다.
- 로그아웃 서버 실패 시 성공으로 표시하지 않는다. 기기 정리 실패는 별도 안내/재시도한다. 저장소 장애 시 재시작 정책 전체는 실기기 미검증이다.
- 삭제는 서버 204 확인 뒤에만 로컬 member cleanup marker를 만든다. 미확인 삭제 상태에서 실제 기록을 제거하지 않는다. 다른 회원·legacy 키는 남긴다.
- 로컬 이관 실패 시 원본과 owner claim을 보존하고 같은 회원의 반복 복사로 재개한다. 기존 대상과 내용이 다르면 덮어쓰지 않고 중단한다. 이 설계는 완전한 원자적 rollback 구현이 아니다.
- 새 민감 작업 요청 필드는 기존 설치 앱이 보내지 않는다. 후보 서버만 먼저 배포하면 428 거부가 발생할 수 있어 앱/서버 동시 호환성 전환 Gate가 필요하다. 배포하지 않았다.
- 제공자 간 전역 인증 single-flight, Google timeout 뒤 늦은 native callback, 앱 재생성/브라우저 복귀는 추가 검증이 필요하다. 네이버 단독 single-flight PASS를 모든 제공자의 PASS로 확대하지 않는다.
- 개인정보/스토어 고지는 최종 운영 데이터 흐름·외부 철회·자동파기/백업이 확인되기 전 완료로 선언하지 않는다.

### 이번 수정 파일 범위
`lib/app/member_record_scope.dart`, `member_record_cleanup.dart`, `legacy_record_import.dart`, `member_session_store.dart`, `member_auth_controller.dart`, `conversation_draft.dart`, `emotion_card_store.dart`, `mind_card_store.dart`, `onaria_app.dart`, `verse_history.dart`, `ai_consent.dart`; `lib/engagement/storage.dart`; `lib/features/signup_page.dart`, `privacy_page.dart`, `previous_device_records_page.dart`, `account_menu.dart`; `lib/main.dart`; `lib/src/api/member_api_client.dart`, `provider_auth_api_client.dart`; `lib/src/auth/naver_login_service.dart`, `google_login_service.dart`, `kakao_login_service.dart`; vendored Android Naver adapter; 관련 Flutter 테스트; `backend/src/app.js`, `member_schema.js`, `member_store.js`, `backend/test/auth_ux_boundaries.test.js`와 관련 인증/삭제 fixture. 공유 파일의 기존 변경을 포함한 전체 git diff를 이번 수정만으로 간주하지 않는다.

### 남은 사용자 확인·출시 차단
1. App Store Connect/TestFlight 및 Google Play의 최고 업로드 빌드 번호 확인 후 신규 단조 증가 번호 결정.
2. A23/A33 명칭과 S22/iPhone 실제 연결 확인. 기존 서명/데이터 유지 후보 설치 후 사용자의 인증 조작으로만 E2E 진행.
3. A33 네이버 실제 실패 원인과 제공자별 취소/늦은 callback/재시작 검증.
4. 이전 기록의 실제 소유 확인·사용자 선택 이관, 민감 작업의 최신 proof 정책, 응답 유실 결과조회 보강.
5. 앱/서버 호환성 전환·운영 어댑터/독립 명부/백업·보유기간·스토어 Gate. 실제 인증/철회/삭제/운영 변경은 승인 범위 확인 전 실행하지 않음.

커밋·푸시·병합·리베이스·운영 배포·재시작·실제 사용자 삭제/외부 철회는 NOT RUN. 기기 설치본과 운영 데이터 유지.


### 2026-10-11 최종 로컬 후보 검증

| 검증 | 명령/결과 | 범위 |
|---|---|---|
| Backend | `npm test`: 492 PASS, FAIL/SKIP 0, 종료 0 | 임시 DB·fixture. owner proof/동시 가입/세션·삭제명부·복원·기존 Safety 회귀 |
| Flutter 전체 | `flutter test`: 187 PASS / 1 SKIP, 종료 0 | 최종 오류 문구/네이버 늦은 정리 콜백 수정 후 재실행 |
| Flutter analyze | `flutter analyze lib test example --no-fatal-infos`: 오류 0, 경고 0, info 36, 종료 0 | 정보 수준 스타일 지적은 남아 있음 |
| Web 브라우저 | `npm run test:web`: 20 PASS, 종료 0 | ONARIA 전용 로컬 fixture, 접근/CSRF/웹 페이지·반응형 회귀 |
| Android APK | `flutter build apk --release`: PASS, 최종 재빌드 종료 0 | 기존 보호 설정 파일/서명 재사용, package·version·signer 확인 |
| Android AAB | `flutter build appbundle --release`: PASS, 종료 0 | 기존 서명 재사용, 업로드 NOT RUN |
| iOS | `flutter build ios --release --no-codesign`: PASS, 종료 0 | com.onaria.app / 1.0.0 / 20. 서명·설치·실기기 검증 아님 |
| diff/secret | `git diff --check`: PASS. 후보 lib 및 수정 backend 소스의 private key/API key 패턴 검출 0 | 보호 설정/키의 값은 출력·복사하지 않음. 제한된 패턴 검사이며 완전한 보안 감사 아님 |
| 실제 기기/운영 | NOT RUN | 설치·사용자 인증·실제 삭제·외부 철회·서버 변경 없음 |
| CI | NOT RUN — 현재 미커밋 후보 | 원격 과거 CI 성공을 현재 후보 PASS로 사용하지 않음 |

Flutter SKIP은 `conversation_lifecycle_test.dart`의 API endpoint 미설정 분기이며 현재 baseUrl이 설정된 구성에서 제외된다. 이 미설정 분기 자체를 PASS로 선언하지 않는다. 초기 회귀에서 legacy 자동 표시 기대값·메뉴 위치·secure storage fixture 때문에 실패가 발생했고, 새 소유권 기준/이전 기록 안내 진입 위치/격리 persistence fixture를 수정한 뒤 전체를 재실행했다. 통과 숫자를 위해 실제 계정 접근을 완화하지 않았다.

빌드 과정의 기존 플러그인 Kotlin Gradle/Swift Package Manager 전환 안내는 남아 있다. SDK를 임의 업그레이드하거나 기존 서명 설정을 교체하지 않았다.

정확한 산출물 SHA256/크기/서명·버전은 `ONARIA_AUTH_UX_LOCAL_ARTIFACTS_2026-10-11.json`에 기록했다. Android signer SHA256은 기존 `972ae4645e3c7c93fc4d3858250de1a3af93c514386c5d6540efd51652cd3d07`과 일치한다. 로컬 20 후보의 같은 번호가 기존 기기 20과 같은 코드를 뜻하지 않으므로 설치하지 않았다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b + 기존 dirty 및 로컬 후보
ISSUE FOUND: 기기 공용 기록의 계정 경계, 가입/저장 실패 혼합 안내, 민감 작업 본인확인 부족, 지연 SDK callback
PRIORITY: P0 기록 소유권 / P1 인증
ROOT CAUSE: 공용 저장 키와 비동기 계정 세대 확인 부족; A33 실제 실패 원인은 미확정
IMPLEMENTED: 회원 namespace/세대 lease, 이전 기록 원본 보존·격리 복사 primitive, 초기 입력 최소화, 저장 완료 확인, owner proof, 회원 기기 cleanup 재시도, 한국어 오류 분리
CHANGED FILES: 위 수정 범위 표 및 산출물 manifest; 기존 공동 변경과 분리해서 리뷰 필요
TEST: backend 492 PASS; Flutter 187 PASS / 1 SKIP; Web 20 PASS; analyze 오류·경고 0/info 36
BUILD: Android signed APK/AAB PASS; iOS unsigned Release compile PASS; 임시 소스 버전 1.0.0+20
DEVICE: NOT RUN — 현재 설치본 유지, 스토어 최대 번호 미확인
API: 격리 PASS; 후보 운영 배포·실제 인증/철회/삭제 NOT RUN
CI: NOT RUN — 미커밋 후보
COMMIT: NOT RUN — 사용자 보류
PUSH: NOT RUN — 사용자 보류
REMAINING RISKS: OS 소유 확인/선택 이관, 제공자 간 동시 인증 및 재생성, 최신 proof 정책, 삭제 응답 유실 결과조회, 기기·운영·백업·정책 Gate
NEXT ACTION: 스토어 최고 번호와 A23/A33 명칭 확인 후 후보 버전 결정; 남은 로컬 경계 보강과 승인 범위 내 사용자 인증 E2E
```


## 2026-10-11 사용자 확인 — 후보 Build21 번호 결정
- 사용자 확인: App Store Connect/TestFlight 최고 빌드 19; Google Play 최신 앱 버전 0.4.1, 최고 versionCode 7. 콘솔 직접 조회 결과가 아닌 사용자 제공 증거로 기록한다.
- A23 표기는 현재 연결된 A33을 뜻한다고 사용자 확인. S22/A33 설치 build20, iOS 설치 build19 유지.
- 확인된 로컬 소스/산출물/Android 설치 최고 20과 스토어 번호를 모두 초과하는 다음 후보는 1.0.0+21. pubspec.yaml의 빌드 번호만 20→21로 수정했으며 앱 버전 1.0.0과 기존 서명/package는 유지한다.
- 후보 번호 미확인 Gate는 해소. 앞선 1.0.0+20 컴파일 결과와 manifest는 해당 당시 산출물의 증거로 유지하고, build21 결과는 별도로 기록한다.
- 번호 확인은 실제 네이버 로그인 성공이나 운영 Release Gate 통과를 뜻하지 않는다. 기기 설치/외부 인증/삭제/운영 반영·커밋·푸시는 이번 확인 단계에서 실행하지 않는다.

### Build21 산출물 확인
- APK/AAB 기존 서명 Release 빌드 PASS(종료 0). APK의 실제 package com.onaria.app, versionName 1.0.0, versionCode 21 확인. signer SHA256 기존 값 일치.
- iOS Release --no-codesign 컴파일 PASS(종료 0); Info.plist의 실제 빌드 21 확인. 서명·실기기 설치 검증은 NOT RUN.
- 산출물 manifest에 현재 Build21 해시/크기를 기록하고 이전 Build20 해시는 historical_artifacts_build20으로 보존했다. 기존 경로의 로컬 빌드 산출물은 Build21로 갱신됐으며 설치된 기기 앱은 교체하지 않았다.
- 이번 추가 변경은 pubspec 버전 메타데이터와 기록뿐이다. 기능 회귀 결과는 직전 동일 기능 소스의 backend 492 PASS, Flutter 187 PASS/1 SKIP, Web 20 PASS를 참조하며 버전 변경 후 전체 테스트를 다시 실행한 결과로 표시하지 않는다. git diff --check PASS.
- 새 후보 번호 결정 Gate PASS; A33 실제 네이버 인증/전체 회원 흐름 및 운영 Release Gate는 HOLD. 커밋·푸시·운영 변경·외부 인증/철회·실제 회원 삭제 NOT RUN.


## 2026-10-11 Build21 실기기 설치 및 실행 확인

- A33(SM-A336N): 기존 서명/패키지와 APK 해시 확인 후 `adb install -r`로 Build20 → Build21 업데이트 PASS. 실행, 메뉴, 앱 정보 1.0.0/21 확인 PASS.
- iPhone 15(실기기): 기존 로컬 서명 설정으로 Release Build21 빌드 PASS. codesign strict 검증, 팀/패키지/기기 프로비저닝 검증 PASS. 기존 Build19 → Build21 설치 및 프로세스 실행 PASS. 설치 후 bundleVersion 21 확인.
- S22: 현재 연결되지 않아 설치/테스트 NOT RUN.
- 삭제/데이터 초기화/회원탈퇴 수행 없음. 업데이트 방식만 확인했으며 기존 사용자 기록 보존 및 실제 로그인 유효성은 아직 미검증.
- 신규 가입, Naver/Kakao/Apple 실제 인증, 재실행 세션 복원, 로그아웃, 계정 전환, 회원탈퇴 E2E: NOT RUN. 기존 A33 메뉴에서 로그아웃 항목이 노출되나 서버 세션 유효성 판정 근거로 사용하지 않음.
- iOS 서명 빌드가 기존 unsigned 경로를 갱신함. 이전 manifest의 unsigned 해시는 과거 빌드 증거이며 현재 서명 Runner 해시는 별도 iPhone JSON에 기록.
- 증거: ONARIA_BUILD21_A33_DEVICE_2026-10-11.json, ONARIA_BUILD21_IPHONE_DEVICE_2026-10-11.json.
- Release Gate HOLD 유지. 운영 변경/커밋/푸시 수행 없음. 실제 인증은 사용자 기기 인증 절차와 함께 다음 단계로 진행.

### S22 추가 설치 — 2026-10-11
- SM-S908N 연결 확인. 기존 서명과 Build21 APK 해시 검증 후 adb install -r 업데이트 PASS, 1.0.0+21 실행 PASS. 삭제/데이터 초기화 없음. 실제 소셜 인증 및 기존 기록 보존은 미검증. 증거: ONARIA_BUILD21_S22_DEVICE_2026-10-11.json. 운영/커밋/푸시 보류 유지.

### ARI 선행 Android 실기기 점검
[{"device": "S22", "coldLaunch": true, "menu": true, "logoutVisibleAfterRelaunch": true, "version21": true, "accountPageEntry": true, "accountPageObserved": true, "backNavigation": true}, {"device": "A33", "coldLaunch": true, "menu": true, "logoutVisibleAfterRelaunch": true, "version21": true, "accountPageEntry": true, "accountPageObserved": true, "backNavigation": true}]
강제 종료 후 재실행/메뉴/계정 관리 진입/뒤로가기 점검. 로그아웃 표시만으로 서버 인증 유효성을 판단하지 않음. 로그아웃/회원탈퇴/데이터 초기화 없음. 실제 인증과 기록 보존 미검증.

### 사용자 보고: 네이버 SDK 정리 실패
사용자 메시지: 네이버 인증 상태를 정리하지 못했어요. 다시 시도해 주세요. Build21 실기기 인증 검증 FAIL(기기/발생 동작 미확인). 코드상 NaverLoginService._signOutRaw의 SDK 로그아웃 실패 또는 성공 후 상태값 검증 실패 경로. 로그인 전 강제 SDK 정리에서도 발생 가능. 서버 회원 중복 오류로 단정하지 않음. Android 네이티브는 로그아웃 콜백 후 access/refresh token null 여부를 검사하므로 빈 문자열/잔존 상태/콜백 실패 구분 필요. 실제 원인은 미확정. Release HOLD 유지.

### 네이버 정리 실패 / Apple 미연결 계정 선택 UX 수정 후보
- 네이버: SDK 5.11.2의 logout 성공 콜백 뒤 동기 getter null 검사를 추가해 완료를 거부하던 로직 제거. 공식 문서상 성공 콜백은 로컬 토큰 삭제 완료이며, 실패 콜백은 여전히 error 반환. disconnect/외부 철회 호출 없음. 이 추가 검사가 사용자 오류의 실제 원인인지 실기기 재현 확인은 아직 필요. SDK AAR 바이트코드에서 logout 저장소 작업 뒤 Main 콜백 전달 확인.
- Apple: PROVIDER_IDENTITY_NOT_FOUND 후 기존 계정 연결/새 계정 생성 선택 카드를 화면 위로 이동, 스크롤 위치 초기화, 선택 단계의 provider 버튼 숨김, 덮는 SnackBar 제거. 기존 계정 본인확인 안내도 위로 이동. 이메일 기반 자동 병합이나 새 회원 자동 생성 없음.
- 작은 화면 320x640 / 글자 2배에서 연결 버튼 즉시 hit-test 가능 회귀 추가. 초기 테스트 실패를 수정한 최종 관련 Flutter 16 PASS, analyze PASS, diff check PASS.
- Android 최종 소스 Release APK Build22 컴파일 PASS. pubspec 버전은 기존 1.0.0+21 보존, CLI build-number=22로 명확히 구분한 설치 후보. AAB/iOS 새 후보 NOT RUN. 기존 unsigned manifest와 Build21 증거는 과거 아티팩트 기준.
- 공식 참조: https://developers.naver.com/docs/login/android/android.md (logout 성공/실패 의미).
- 실제 계정 인증/기록 보존/운영 변경/CI/커밋/푸시 미실행. Release Gate HOLD. Android 설치 결과는 ONARIA_AUTH_FIX_BUILD22_2026-10-11.json 참조.

Build22 설치: S22/A33 기존 release 인증서/package 확인 후 adb install -r PASS, 실행 PASS. S22 네이버 버튼 진입 시 즉시 정리 오류는 관찰되지 않았으나 제공자 화면/인증 결과 확인은 미완료. A33은 현재 메뉴에서 로그인 진입 버튼이 없어 기존 세션을 강제 로그아웃하지 않고 중단. 두 기기 인증 E2E NOT VERIFIED. iPhone Build21 유지.

### Build22 실제 인증 진입 추가 확인
S22 정상 로그아웃 수행 후 메뉴 로그인 → 네이버 버튼 진입. 정리 실패 대신 네이버/아이디 관련 인증 화면 관찰. 계정 선택/본인 인증 완료 전이므로 서버 로그인 성공으로 판정하지 않음. 뒤로가기 결과: {"healthStatus": 200, "appleAndroidPostChallenge": 200, "appleRequiredFieldsPresent": true, "s22NaverAccountInputSurfaceObserved": true, "s22CleanupErrorObserved": false, "s22BackToLogin": true, "s22CancellationMessageObserved": true, "authE2E": "NOT VERIFIED", "productionChanges": false}
Apple challenge GET 404는 잘못된 메서드 조회로 폐기. 실제 앱과 같은 POST challenge 200 및 필수 필드 존재 확인. 토큰/state/nonce 미출력. 운영 수정/회원 삭제/외부 철회/커밋/푸시 없음.

### Build22 사용자 인증 실패 보고
사용자: Apple/네이버 모두 로그인 불가. 전체 인증 FAIL, 원인 미확정. 현재 화면 관찰: [{"device": "S22", "publicLabels": []}, {"device": "A33", "publicLabels": ["로그인 또는 시작하기", "Apple 계정은 아직 ONARIA에 연결되어 있지 않아요", "기존 ONARIA 계정에 연결", "새 계정 만들기"]}]
인증 진입/취소 PASS를 로그인 성공으로 간주하지 않음. Release HOLD 유지.

### 운영 회원 DB 읽기 전용 점검
실제 서비스 서버/경로 확인 후 SQLite mode=ro, query_only로 조회. 회원3명: #4 google+kakao, #5 apple, #6 naver. 새 Apple/네이버는 KST 2026-10-11 19:32:27/19:32:54 생성. 고아/기존 주 제공자 매핑 누락0. 현재 소셜 ID가 다른 회원 소유면 운영 link API는 409 IDENTITY_EXISTS로 차단하므로 신규 가입된 두 회원을 기존 회원에 단순 연결할 수 없음. 신규 가입 전 연결 실패 원인은 별도 미확정. 운영 최신 requireAccountProof 미반영 및 identity UNIQUE(member_id,provider) 제약 차이 확인. 사용자 본인 계정 여부/기록 소유권은 DB 목록만으로 확정하지 않음. 삭제/병합/수정/서비스 재시작 없음.

### 계정 통합 준비 1차
읽기 전용 계획기 및 통합 지시서 작성. 두 계정 최신 인증/명시적 동의/세션 폐기/원본 회원 및 기록 보존 설계. 6 PASS. 실행 API·실제 계정 인증·기기 기록 통합 미구현, 운영 무변경.

### 계정 통합 테스트 재확인
계획기 단위6 PASS. 운영 DB 관계를 읽기 전용으로 조회해 소셜 고유 ID를 제거한 projection으로 #4 <- #5,#6 계획 검증 PASS. 실제 고유ID 중복/본인 인증/통합 실행/기기 기록 검증은 이 결과에 포함하지 않음. 운영 무변경.


## Build23 three-device startup review — 2026-10-11

See ONARIA_BUILD23_THREE_DEVICE_REVIEW_2026-10-11.md. Three signed release installs and launches verified; S22 Naver/A33 Apple sessions restored; startup record-scope exceptions fixed. Backend 498 PASS, Flutter 44 PASS, analyze 0 errors/warnings. Account merge runtime NOT IMPLEMENTED; production/commit/push HOLD.


## Optional account merge Build24 — 2026-10-11 KST

Implemented opt-in prepare/confirm API, proof/session-bound two-minute attempts, snapshot recheck, source aliases, record-owner mapping, read-only original record view and merged-family deletion/backup replay. Backend 509 PASS; Flutter full 195 PASS / 1 SKIP; merge/accessibility focused 8 PASS; analyze errors/warnings 0. Build24 signed release installed/launched on S22, A33, iPhone15. Production merge remains disabled/undeployed; real merge NOT RUN; commit/push HOLD. See ONARIA_OPTIONAL_ACCOUNT_MERGE_BUILD24_2026-10-11.md.
