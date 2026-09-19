# ONARIA 명칭 및 로컬 경로 전환

사용자 표시명은 **ONARIA**, 기술명·로컬 폴더명은 **onaria**다.
Mac 작업 경로는 `$ARI_ROOT/projects/onaria`다.
Git origin은 기존 `https://github.com/Naharuya/soul-bible.git`을 유지한다.
원격 저장소 이름 변경과 Git 이력 재작성은 수행하지 않는다.

## 설정 호환성

Node 설정은 `ONARIA_*`를 우선 사용한다. `backend/src/brand_env.js`가 동일한
접미사의 `SOUL_*`, 그 다음 `MIND_*`를 한시적으로 읽는다. 신규 이름의 빈 값도
명시적인 설정으로 취급하며 이전 값으로 되돌리지 않는다. process.env를 수정하거나
설정 값을 로그에 출력하지 않는다. 예를 들어 `SOUL_USAGE_DB_PATH`의 신규 이름은
`ONARIA_USAGE_DB_PATH`, `SOUL_EXTERNAL_API_DISABLED`는
`ONARIA_EXTERNAL_API_DISABLED`다. 실제 설정 파일은 자동으로 수정하지 않는다.

운영자가 별도 승인된 설정 변경 시 기존 보안 저장소에서 신규 변수 이름으로 설정을
옮겨야 한다. 기존 값, DB 경로, 인증 issuer/audience는 변경하지 않는다. 모든 호출자가
전환되기 전에는 호환 읽기를 제거하지 않는다. 기존 앱의 Dart 빌드 설정은 이미
`ONARIA_API_BASE_URL`, `ONARIA_APP_TOKEN`, `ONARIA_PREMIUM_MEMBER`를 우선하고
각 `SOUL_BIBLE_*` 이름을 fallback으로 지원하므로 이를 유지한다.

## 저장 데이터와 운영 경로 보존

아래 명칭은 화면 표시명이 아닌 기존 데이터·배포 계약이므로 유지한다.

- SharedPreferences의 `soul_bible.mind_cards.v1`,
  `soul_bible.daily_usage.date.v1`, `soul_bible.daily_usage.count.v1`,
  `soul_bible.engagement.v1`, `soul_bible.reminders.v1`.
- 저장된 마음카드, 대화 요약, 사용자 설정, 알림 설정의 기존 스키마와 키.
  이름 변경만으로 데이터를 복사·삭제하지 않는다. 기존 키로 저장한 레코드를
  신규 ONARIA 코드가 읽는 회귀 테스트를 추가했다.
- 기존 SQLite 파일 `data/ai_usage.sqlite`, `data/members.sqlite`와 테이블,
  Docker의 `soul-bible-cost-data` 볼륨 및 `soul-bible-backend` 서비스.
  로컬 프로젝트 상위 폴더를 이동해도 이 데이터의 상대경로는 유지된다.
- 운영 `/opt/soul-bible`, systemd 서비스, SSH 별칭 `soul-bible-server`,
  Apache 설정·로그 이름 및 Cafe24 스크립트의 원격 대상 경로.
  로컬 템플릿만 `script/onaria-backend.service`, `script/onaria-http.conf`로
  이름을 바꾸며 원격 서비스 설치 이름과 명령 동작은 유지한다. 배포하지 않는다.
- 이전 Admin 인증 잔여물을 정리하는 `soulBibleAdminToken` 키와
  Service Worker의 구 캐시 식별 문자열은 기존 보안 정리 코드의 호환 동작이다.
- docs/archive 및 이전 릴리즈 기록, 백업·검토 보고서는 역사적 기록으로 보존한다.

이미지 내보내기 내부 MethodChannel은 Dart·Android·iOS·테스트를 함께
`onaria/image_export`로 변경했다. 이 채널은 외부 앱 URL scheme이 아니다.

## MANUAL_ACTION_REQUIRED: 앱 및 외부 서비스 식별자

현재 외부 등록 상태를 확정할 자료가 없어 다음 식별자를 자동 변경하지 않는다.

| 대상 | 유지한 정확한 값 | 별도 확인할 서비스 |
| --- | --- | --- |
| Android applicationId / namespace | `com.example.bible_mind_core` | Google Play Console, Firebase Android 앱, OAuth Android 클라이언트 |
| iOS bundle identifier | `com.example.bibleMindCore` | App Store Connect, Apple Developer App ID, Firebase iOS 앱, OAuth iOS 클라이언트 |
| iOS 테스트 bundle | `com.example.bibleMindCore.RunnerTests` | 로컬 Xcode 테스트 대상 |
| HTTPS 앱 링크 | `https://api.onaria.ai.kr/app/open` | 기존 Android assetlinks 및 Apple association 설정 |
| Custom URL | `onaria://app/open` | 기존 OAuth/앱 리디렉션 등록 |
| iOS associated domain | `applinks:api.onaria.ai.kr` | Apple Developer 및 기존 도메인 association |
| 서명 파일 | `android/soul-bible-release.jks`, `android/key.properties` | 기존 릴리즈 서명 관리 절차 |
| GitHub origin | `https://github.com/Naharuya/soul-bible.git` | GitHub 저장소 설정; 이번 작업에서 원격 이름은 유지 |

macOS 앱 대상과 Firebase GoogleService-Info.plist/google-services.json은 조사 범위에서
발견되지 않았다. 이는 외부 등록이 없다는 뜻이 아니다. 서명·인증서·provisioning
profile·실제 환경 파일·외부 성경 승인 상태·production/Cafe24는 변경하지 않는다.
