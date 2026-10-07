# Android Apple 로그인 연결

앱 0.4.3+9에 Android 웹 인증과 앱 복귀 경로를 추가했다. iOS의 기존 네이티브 audience는 유지하고 Android Services ID의 audience/nonce를 별도로 검증한다.

## Apple Developer에서 필요한 실제 설정

기존 Sign in with Apple App ID에 연결된 Services ID에서 웹 인증을 구성한다.

- Domain: `api.onaria.ai.kr`
- Return URL: `https://api.onaria.ai.kr/v1/auth/apple/android/callback`
- 서버 환경 변수: `ONARIA_APPLE_SERVICE_ID=<실제 등록한 Services ID>`
- 선택적 환경 변수: `ONARIA_APPLE_REDIRECT_URI=https://api.onaria.ai.kr/v1/auth/apple/android/callback`

Services ID는 비밀키가 아니지만 실제 등록값이어야 한다. 기존 `ONARIA_APPLE_CLIENT_ID=com.onaria.app`은 iOS용으로 유지한다. 현재 운영 서버에 Services ID가 없어 challenge는 503으로 응답한다. Apple 계정 페이지는 이번 연결에서 열리지 않아 외부 등록을 완료하지 못했다. 등록값을 서버에 적용하면 설치된 앱이 설정을 받아 사용하므로 다시 설치할 필요가 없다.

## 구현과 운영

- POST challenge에서 5분 state/nonce를 발급하고 callback에서 1회만 사용한다.
- Apple 서명, issuer, Services ID audience, nonce를 검증한다.
- Apple JWT/인증 코드/이메일/이름은 앱 딥링크에 넣지 않는다. 검증 결과를 5분 임시 증명으로 교환해 기존 로그인/신규 가입 API에 전달한다.
- 임시 증명은 기존 로그인 조회 후 신규 가입에 재사용 가능하다. 메모리 상태는 서버 재시작 시 폐기되며 기존 회원 세션에는 영향을 주지 않는다. 다중 프로세스 운영에는 공유 저장소 또는 고정 라우팅이 필요하다.
- form 크기와 상태 저장 개수를 제한하고 no-store/no-referrer를 적용한다.
- `signinwithapple://callback`의 host를 Android intent filter에 지정한다.
- 운영 코드의 기존 변경을 보존해 관련 경로만 배포했다. 백업은 서버 `.backups/apple-android-20261006`에 보관했다.
- 설치 스크립트의 인증서 기준을 실제 설치 APK와 기존 업로드 keystore에서 모두 확인한 동일 인증서로 갱신했다. 키 교체 없이 `adb install -r`만 사용한다.
- 로컬 로그인 define 파일을 릴리스 빌드에 반영하면서 공식 API 설정을 마지막 인수로 고정한다. 파일은 Git에서 제외하고 비밀값은 출력하지 않는다.

## 검증 결과

```yaml
PROJECT: ONARIA
CURRENT COMMIT: ae999eae6f548ad47e7d9d36b384dca97b18c148
ISSUE FOUND: Android Apple 웹 인증 콜백과 앱 복귀 연결 누락
PRIORITY: P1 인증
ROOT CAUSE: Android Services ID 설정과 callback 구현이 없음
IMPLEMENTED: challenge/callback, 서명·nonce 검증, 임시 증명, Android 복귀, 릴리스 설치 설정
CHANGED FILES: Android Manifest; backend app/server/auth/test; Flutter signup/client/test; release script/test; pubspec; gitignore; 문서
TEST: backend 432 PASS; Flutter 132 PASS 및 기존 1 SKIP; analyze 오류·경고 0 및 기존 info 16; installer 15 PASS 및 Windows 1 SKIP
BUILD: 최초 manifest path 오류 수정 후 Android release APK PASS
DEVICE: SM_S908N 0.4.3+9 설치 및 앱 실행 PASS; 인증서·패키지·버전 검증 후 adb install -r; 기존 데이터 삭제 없음
API: 운영 health 200; challenge 503 (실제 Services ID 미설정); callback 코드 배포 및 서버 재시작 완료
CI: 게시 후 정확한 커밋 확인 예정
COMMIT: 검증된 변경을 후속 커밋에 기록
PUSH: 기존 검토용 PR에 후속 커밋 게시
REMAINING RISKS: 실제 Apple Services ID 등록·설정; 사용자 Apple 로그인 E2E와 iOS 실기기 검증 NOT RUN
NEXT ACTION: 릴리스 설치 확인 후 Apple Developer 실제 Services ID 설정
```


## Services ID 적용 완료 — 2026-10-06 18:33 KST

사용자가 Apple Developer에서 `com.onaria.web.login`과 ONARIA 기본 앱, 도메인 및 Return URL 설정 저장을 완료했다고 확인했다. 운영 서버의 해당 Services ID와 HTTPS redirect만 적용하고 기존 iOS/client 및 다른 환경 설정을 보존했다. 환경 파일 백업은 접근이 제한된 기존 배포 백업 폴더에 보관했다.

- 공개 HTTPS health: 200.
- POST challenge: 200, no-store; clientId/redirectUri 및 state/nonce 형식 확인 PASS.
- 발급한 테스트 state의 access_denied form callback: 303, 고정 ONARIA package 앱 복귀 확인 PASS.
- Android 0.4.3+9 재설치 불필요: 서버 설정을 동적으로 받아 사용한다.
- 실제 사용자 Apple 로그인, 앱 내 세션 복원/로그아웃/재로그인 및 iOS 실기기 테스트는 아직 NOT RUN. 사용자 계정 인증으로 최종 확인 필요.
