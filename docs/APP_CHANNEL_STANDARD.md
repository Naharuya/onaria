# 앱 표시 채널 — 2026-10-31 사용자 공통 기준

DEV: `ONARIA DEV` / TEST: `ONARIA TEST` / 정식 배포 이름: `ONARIA`.
이름은 빌드할 때 고정한다. Release/Debug, 서버 환경, Play 내부/비공개 트랙은 서로 다른 개념이다. 설치 경로나 트랙을 이름으로 자동 감지하지 않는다. TEST가 테스트 서버 연결이나 데이터 격리를 보장하지 않는다.

모바일 루트 `onaria`에서:
```sh
python3 scripts/build-app-channel.py dev apk --dry-run
python3 scripts/build-app-channel.py test apk -- --release
python3 scripts/build-app-channel.py prod appbundle -- --release
python3 scripts/build-app-channel.py test ios -- --release --no-codesign
```
기존 필수 빌드 인자·API URL·서명 검증을 추가 인자로 유지한다. ONARIA 등 기존 release helper의 인증서/버전/manifest 검증도 생략하지 않는다. 이 helper는 빌드만 하며 설치/삭제/배포/푸시를 실행하지 않는다. iOS가 없는 프로젝트는 iOS 명령을 사용하지 않는다. 정식 이름 선택은 스토어 등록·출시 승인이나 실제 마켓 설치를 증명하지 않는다.

기존 package/bundle ID, 서명, OAuth callback, 서버·DB·버전을 변경하지 않았다. 동일 ID의 세 빌드는 동시 설치되는 별도 앱이 아니라 업데이트 시 이름이 바뀌는 방식이다. 동시 설치가 필요하면 별도 ID·로그인·데이터 격리를 별도 검증한다. 기존 Debug suffix는 그대로 둔다. 기존 기기의 이름은 다음 승인된 업데이트부터 변경된다.

Android: Gradle `ariAppChannel` 속성으로 manifest label을 결정한다. 직접 Debug 빌드는 DEV, 채널 미지정 Release는 기존 기본 이름이다. 로컬 기기 테스트 Release는 반드시 helper의 test/dev 채널을 사용한다. iOS: Info.plist build setting과 XCODE_XCCONFIG_FILE override를 사용한다. 기존 override가 있으면 자동 덮어쓰지 않고 중단한다. Web 빌드는 출력 manifest/title을 바꾸며 새로 설치하는 PWA 기준이고 기존 홈화면 바로가기는 재추가/브라우저 갱신이 필요할 수 있다.

실기기 설치·앱마켓 제출·운영 배포·커밋·푸시는 이번 설정 작업에 포함하지 않았다. 플랫폼별 실제 빌드/설치 검증 결과는 별도 증거 문서를 따른다.

## 이번 검증 결과
- DEV/TEST/PROD 이름 선택과 잘못된 채널 거절·native XML/plist 정적 검사 PASS.
- 기존 앱 식별자·서명 설정·OAuth/딥링크의 비이름 부분 보존 검사 PASS.
- 실제 네이티브 검증은 ONARIA Gradle manifest 및 Xcode 설정 조회 시간 초과로 미완료. 다른 앱 네이티브 작업 반복은 중단. 실기기·서버·스토어 변경 없음.
- 자세한 범위: APP_CHANNEL_VALIDATION_2026-10-31.json. 설정 적용은 실제 APK/IPA 설치 검증을 뜻하지 않는다.
