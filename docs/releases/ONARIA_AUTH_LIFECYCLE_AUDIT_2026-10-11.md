# ONARIA 인증 생애주기 점검 v0.1 — 2026-10-11

기준: codex/apple-android-20261006, HEAD 1aef3815c8e25022a948c4307e1c755e5cc8507b + 기존 미커밋 작업 + 이번 후보. 운영 Build20과 후보를 구분한다.

## 판단
A33 원인 미확정. 플러그인의 반환 경로 손실은 코드로 확인. 출시 HOLD 유지. 데이터 초기화·재설치로 문제를 숨기지 않는다.

## 공식 벤치마킹
- https://developers.naver.com/docs/login/android/android.md : requestLogin 성공 콜백에서 토큰 획득, 실패 콜백의 코드 확인, logout과 disconnect 분리.
- https://developers.naver.com/docs/login/api/api.md : 토큰과 회원 프로필 검증/연동 해제 API 구분.
- https://www.rfc-editor.org/info/rfc9700/ : OAuth 보안 검토 기준. 공급자마다 지원하는 기능을 확인하고 적용; 네이버가 지원하지 않는 PKCE를 추정하지 않는다.

## 확인한 결함과 후보 수정
1. naver_login_flutter 4.0.0 Android: onFailure 설명 문자열에 cancel이 포함되면 loggedOut으로 반환. onSuccess 후 토큰이 없어도 loggedOut. A33 화면만으로 둘을 구분할 수 없음.
2. 로그인 성공 후 기기에서 프로필을 추가 조회하여 인증 결과를 프로필 요청에 종속. ONARIA 서버에서도 프로필을 검증하므로 중복 단계.
3. logout 콜백 실패와 예외도 loggedOut으로 반환하여 Dart의 정리 성공 검사가 실제 성공을 보장하지 못함.
4. Dart MethodChannel.logOut은 네이티브 결과를 무시하고 loggedOut을 만들어 반환. 새 회귀테스트로 실패 재현 후 status map 파싱으로 수정.
5. 후보: 프로젝트 내부 third_party 포크(라이선스 보존, 캐시 원본 수정 없음). 정확한 user_cancel / success_token_missing 구분; 공급자 설명 원문 제거; 성공 토큰을 서버에서 검증; SDK 정리 실패는 실패로 반환. iOS 소스 동일.
6. 로그인 전 SDK 정리를 유지. 삭제/연동철회 기능을 로그인 복구 수단으로 사용하지 않음. 정리 정책은 실기기 비교 후 별도로 평가.

## 현재 흐름별 체크
| 단계 | 확인한 구현 | 남은 검증/개선 |
|---|---|---|
| 신규가입 | 소셜 인증 → 서버 조회 → 미연결 계정 선택 → 동의·성인 확인 → 생성·세션 | 가입 서버 성공 후 로컬 회원번호 저장 실패 시 성공을 실패로 안내할 수 있음. 응답 유실/중복 제출 회복 필요 |
| 기존로그인 | 공급자+검증된 고유 ID로 조회. 이름/전화/교회만으로 자동 병합하지 않음 | A33 후보 실제 성공 및 기존 member ID 유지 |
| 다른 소셜 연결 | 기존 소셜 본인확인 후 새 소셜 연결, 다른 회원의 ID 충돌 차단 | Google·Naver·Kakao·Apple 각 조합 실제 기기 확인 |
| 앱 사용 | 세션 보안저장, 서버 계정 확인, 만료검사, 401 정리, 일시 장애 unavailable | 마음기록은 기기 공용 키. 계정별 표시/소유권 정책과 기존 기록 안전 이관 필요. 모든 기능별 서버 회원 인증 연결 추가 점검 |
| 로그아웃 | 서버 세션 폐기 → 기기 세션 정리 → 네이버 SDK 정리. 서버 실패 시 유지 | 오프라인 로그아웃 UX/재시도, secure storage 삭제 실패 후 앱 재시작 동작. 네이버 브라우저 로그인 쿠키와 ONARIA 로그아웃 구분 |
| 회원탈퇴 | fresh account 조회, Apple 연결 시 fresh Apple 증명, 삭제명부 기록, 모든 연결 ID 세션 폐기, 회원 삭제 | 네이버·카카오 외부 연동 해제 정책/실행 별도. 본인확인 최신성(현재 일반 세션 최대 30일) 검토. 기록·초안은 기기에 남으며 안내와 일치 필요 |
| 탈퇴 후 | 서버 회원/세션 제거 회귀 존재 | 실제 외부 철회 E2E, 백업 복원 재생성 방지, 신규가입 시 이전 기록 노출 방지 |

## 업무 프로세스 개정
환경 확인 → 증거 수집 → 원인 가설과 반증 조건 → 한 범위 후보 수정 → 고정 코드 단위검증 → 서버·앱 회귀 → 서명/패키지/버전 검증 → 데이터 유지 업데이트 → 실기기 생애주기 → 정확한 SHA의 CI → 릴리스.
코드/로컬시험/컴파일/실기기/운영/CI 결과를 각각 기록. API health 200 또는 mock callback을 실제 로그인 PASS로 사용하지 않는다.

## A33 재현 표
A33 연결 확인: SM_A336N, Android16, ONARIA 1.0.0 Build20. 설치 패키지 조회에서 네이버 앱 패키지 없음, Chrome 존재. 네이버 앱 인증과 브라우저 인증을 동일 조건으로 간주하지 않는다.
1. A33/S22 설치 package, signer SHA256, version, OS, 브라우저·네이버앱 버전을 값만 비교(비밀값 제외).
2. 공식 예제와 비교: 실제 인증 완료/명시적 취소/뒤로가기/앱 전환/장시간 지연/재시도. 네이버앱 없는 Chrome 경로 우선.
3. 후보에서 SDK 고정 코드와 서버 도달 여부만 기록. 토큰, 프로필, URL query, 전체 logcat 금지.
4. 네이버 인증성공 → 서버 201 → 계정조회200 → 종료/재시작 유지 → 로그아웃 → 재로그인 동일 회원.
5. 테스트용 새 계정으로 가입·연결·탈퇴(운영 실제 회원 삭제 없이 격리). 서버 실패/응답 유실도 함께 확인.
6. 사용자 계정 인증이 필요한 구간은 사용자가 직접 진행. 설치 전 signer/version 검증; adb uninstall/pm clear 금지.

## 완료 기준
A33와 S22에서 취소와 실패와 성공이 구분되고, 기존회원/기록 유지, 모든 소셜 연결 조합, 세션 만료·재시작·로그아웃·탈퇴·복원 시나리오가 증거와 함께 PASS. 미검증 상태는 출시 HOLD.

## 이번 검증
수정 전 인증 Flutter25 PASS. 수정 후보 인증 Flutter32 PASS. 백엔드 인증37 PASS, 백엔드 전체489 PASS. 분석 error/warning 없음(info15). Android native compileReleaseKotlin PASS. 마지막 Dart 수정 전 Flutter 전체177 PASS/1 SKIP; 마지막 수정 후 인증 Flutter33 PASS. 전체177 결과는 마지막 Dart 결과파싱 수정 전 결과이며 구분하여 보관.
운영 배포·DB변경·회원탈퇴·기기설치·commit/push 없음.

## 최종 작업 기록
```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b + dirty working tree
ISSUE FOUND: SDK 결과 손실, logout 성공 위조, 기기 공용 마음기록/탈퇴 보존
PRIORITY: P1 인증, P0 개인정보/계정 경계 추가점검
ROOT CAUSE: A33 실기기 실패 원인 미확정; 어댑터 결함은 소스/회귀로 확인
IMPLEMENTED: 프로젝트 내 라이선스 보존 포크, 취소/토큰누락 구분, 서버 검증, SDK logout 결과 전달
CHANGED FILES: pubspec.yaml/pubspec.lock, naver_login_service.dart, naver_login_service_test.dart, third_party/naver_login_flutter, 본 점검문서
TEST: 최종 인증 Flutter33 PASS; backend489 PASS; 마지막 Dart 수정 전 전체Flutter177 PASS/1 SKIP
BUILD: Android adapter compileReleaseKotlin PASS; APK/AAB/iOS NOT RUN
DEVICE: A33 OS/버전/앱 설치환경 읽기 확인; 후보 설치/로그인 E2E NOT RUN
API: 운영 변경/쓰기 NOT RUN; 서버 테스트는 격리 fixture
CI: NOT RUN - 커밋되지 않은 로컬 후보
COMMIT: NOT RUN - 기존 dirty 작업과 공동 수정파일 보존, 통합/실기기 gate 미충족
PUSH: NOT RUN
REMAINING RISKS: A33 원인 분기, 사용자별 기록 경계, 가입 응답유실/로컬저장 실패, 재인증/탈퇴/외부철회/복원
NEXT ACTION: 서명된 후보를 데이터 유지 설치 후 A33 Chrome 인증/취소 비교와 전체 회원 생애주기 E2E
```


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
