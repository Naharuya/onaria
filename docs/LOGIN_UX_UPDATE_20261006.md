# ONARIA 로그인 UX 변경

- 모바일 버튼 순서: Apple → Google → 네이버 → 카카오.
- 세로 배치, 최소 높이 52, 간격 12, 모서리 12. Google 흰색, 네이버 초록, 카카오 노랑, Apple 검정 바탕과 Apple 아이콘, 글자 확대 시 버튼 높이 증가.
- 처음 화면에서는 계정 선택에 집중하고, 기존대로 신규 계정 인증 후에만 가입 정보와 동의를 표시한다.
- 인증 중 모든 로그인 버튼의 재입력을 차단하고 진행 안내를 표시한다.
- 작은 화면은 기존 스크롤과 SafeArea를 유지한다.
- 메뉴를 계정·로그아웃·회원탈퇴로 표시하고 계정 화면의 로그인 상태·로그아웃 영역을 기록 삭제 기능보다 위로 이동한다. 실기기에서 세션 복원과 로그아웃 성공은 별도 검증해야 한다.

## 남은 검증

Android Apple 인증은 저장소에 웹 인증 Service ID/redirect 연결이 없다. 버튼은 표시하되 준비 안내를 제공하며, 실제 Android Apple 인증은 완료되지 않았다. iOS는 기존 인증 경로를 유지한다. 웹 로그인 UI는 이번 변경 범위에 포함하지 않는다.

Mac의 최신 미커밋 코드와 먼저 비교하고 이 파일과 signup_page.dart 변경만 적용한다. Flutter 분석/테스트 후 두 기기에서 순서, 큰 글자, 인증 취소/실패, 로그인·로그아웃·재로그인 검증이 필요하다.

## 작업 결과

```yaml
PROJECT: ONARIA
CURRENT COMMIT: c09844f03588f11f43a20c127985dd194accef1d
ISSUE FOUND: iOS 전용 Apple 버튼 및 요청과 다른 버튼 순서
PRIORITY: P2 UI/UX
ROOT CAUSE: 플랫폼 조건과 별도 버튼 구현
IMPLEMENTED: 모바일 4개 버튼 순서·간격·크기·인증 중 안내 정리
CHANGED FILES: signup/check_in/privacy/records 페이지, signup/account 배치 테스트, signup_validation_test, 이 문서
TEST: 전체 Flutter 테스트 130개 통과, 1개 기존 skip; 관련 테스트 12개 통과; 정적 순서/배치 및 git diff --check 통과
BUILD: NOT RUN (Android SDK/Xcode 없음); Flutter 3.47.2 설치 완료
DEVICE: NOT RUN (실기기 연결 없음)
API: NOT RUN (인증 API 변경 없음)
CI: 검토용 PR 생성 후 확인 예정
COMMIT: 검증 완료; GitHub 검토용 브랜치에 기록
PUSH: 검토용 브랜치 게시 예정
REMAINING RISKS: Android Apple 인증 연결 필요; 최신 Mac 작업과 비교 필요
NEXT ACTION: 검토용 PR의 Android/iOS CI 확인, 최신 Mac 코드 비교 및 release 실기기 테스트
```

## Android Apple 로그인 연결 준비사항

현재 iOS 네이티브 인증과 서버 identity token 검증은 유지한다. Android를 활성화하려면 실제 Apple Services ID와 HTTPS Return URL이 필요하다. App ID와 Services ID는 서로 다른 audience이므로 기존 iOS audience를 Android 값으로 덮어쓰면 안 된다. 서버에서 두 경로를 분리하거나 명시적인 허용 목록을 검증해야 한다.

- Apple Developer: 기존 ONARIA App ID에 연결된 Services ID, 도메인, Return URL 확인.
- 앱: WebAuthenticationOptions의 실제 clientId/redirectUri 설정 및 Android callback activity 추가.
- 서버: 제한된 form POST callback, 고정 ONARIA package intent redirect, 인증 응답 검증·state/nonce 일치 확인.
- iOS 기존 성공 경로와 Android 취소·복귀·인증 실패 경로를 모두 재검증한 후 활성화.

참고: https://github.com/aboutyou/dart_packages/blob/master/packages/sign_in_with_apple/sign_in_with_apple/README.md

기존 macmini-phone-deploy.yml은 debug 설치 경로라 현재 AGENTS.md의 release 설치 지침과 맞지 않는다. 이번 작업에서 실행하지 않는다.

정적 분석: `flutter analyze lib test example --no-fatal-infos --no-pub` 종료 코드 0, 오류·경고 없음, 기존 스타일 info 16개.
