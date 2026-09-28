# ONARIA Buddhist Android — TEST_DATA_ONLY

독립 패키지 `com.onaria.buddhist`, 앱 이름 `ONARIA 불교 TEST`, 버전 `0.1.0+1`.
사용자가 별도 Buddhist Android 앱 구현과 USB 설치를 명시적으로 요청한 개발 앱이다.
기존 Christian `com.onaria.app`의 package, 데이터, 로그인, 딥링크, 알림을 공유하지 않는다.

## 구현

- 체크인 → 로컬 성찰 → Provider 인용 → 마음카드 → 기기 내 저장 → 저장·성장 화면.
- 아이보리/연녹색 테마와 모든 화면의 `TEST_DATA_ONLY` 고지.
- 읽기 전용 개발 상태: 외부 자료 `BLOCKED_EXTERNAL_REVIEW`, 가져오기 비활성.
- 공통 `packages/onaria_core`의 기존 Safety 감지기를 사용한다. 원본 감지 규칙은 변경하지 않았다.
- `packages/onaria_buddhist_pack`의 합성 자료 두 개와 Provider만 사용한다.
  Web Mock도 동일 JSON을 읽는다. 실제 경전, 번역문, 추정 인용은 없다.
- 12개 주제/감정 검색, ID/출처/라이선스 조회, 임의 Mock 조회, 정확한 인용 검증.
- Safety가 항상 검색보다 먼저 실행된다. 위기 세션에서 인용·카드·저장 카드 표시를 차단한다.
- 인터넷 권한·API 클라이언트·AI 모델 호출이 없다. 서버나 개발 포트가 필요 없다.
- 카드 저장은 이 패키지의 SharedPreferences에 Provider ID만 저장한다.
  대화 본문은 저장하지 않으며 백업은 비활성이다. 알 수 없는 ID는 복원하지 않는다.

## 검증

이 디렉터리에서:

```sh
flutter pub get --offline
flutter test --no-pub
flutter analyze lib test --no-fatal-infos
flutter build apk --release --no-pub
```

Buddhist 전용 키가 없을 때 Release 컴파일은 **서명 없는 검증용 APK**만 만든다.
Debug 키를 Release에 대신 사용하지 않는다. 이 산출물은 설치 가능한 완료본이 아니다.

사용자가 2026-09-28 Buddhist 전용 새 Release 키 생성과 설치를 승인했다.
Christian 키와 별도로 아래 파일을 사용한다:

- `apps/buddhist/android/buddhist-release.jks`
- `apps/buddhist/android/key.properties`

두 파일은 소유자만 읽고 쓸 수 있는 권한(0600)으로 저장하며 Git에서 제외한다.
공개 인증서 지문은 `apps/buddhist/android/release-certificate.sha256`에 고정한다.
이후 업데이트를 위해 키와 설정을 안전한 별도 위치에 백업해야 한다.
Christian 키는 변경하지 않는다. 비밀번호/키 내용은 채팅이나 Git에 넣지 않는다.
설치는 기존 wrapper 경로를 재사용한다:

```powershell
./scripts/install-onaria-release.ps1 -Buddhist -Device DEVICE_SERIAL
```

PowerShell이 없는 macOS에서는 위 wrapper가 호출하는 같은 Node 구현을 사용한다:

```sh
node scripts/android-release.mjs --buddhist DEVICE_SERIAL
```

설치기는 승인된 Buddhist 전용 Release 인증서, Buddhist 패키지, 버전, non-debuggable 상태,
인터넷 권한 부재, Christian 자산 부재 및 Mock 자산 존재를 검증한 뒤 `adb install -r`만 실행한다.
Debug 설치, uninstall, 데이터 초기화, 다운그레이드 우회는 하지 않는다.

## 최초 컴파일 확인 결과 — 2026-09-28 (전용 키 생성 전)

- Buddhist Flutter 테스트 6 PASS; 정적 분석 오류/경고 없음.
- Release 컴파일 PASS: `build/app/outputs/flutter-apk/app-release.apk`.
- APK 검사 PASS: `com.onaria.buddhist`, versionCode 1, 인터넷 권한 없음,
  Christian 자산 없음, Mock 자산 포함, non-debuggable.
- **서명/USB 설치 미완료**: 기존 Release keystore와 key.properties가 없어 설치기가 사전 중단했다.
- 연결된 SM-S908N은 USB 디버깅 승인 상태. 휴대폰의 기존 앱은 변경하지 않았다.
- Backend 414 PASS, Buddhist Web E2E 4 PASS, Christian Flutter 120 PASS / 기존 조건부 1 SKIP.
- Release 설치 도구 18 PASS / Windows 전용 1 SKIP.
- Christian Android Debug 및 iOS simulator 컴파일 PASS. 둘 다 기기에 설치하지 않았다.
- Christian APK의 Bible 자산 유지 및 Buddhist Mock 자산 부재 확인 PASS.
- Christian 정적 분석: 오류/경고 없음, 기존 example의 print 관련 info 4개.

실제 경전 투입, 운영 서버/DB 변경, 앱스토어 제출은 수행하지 않는다.

## 전용 키 승인 후 USB 설치 완료 — 2026-09-28

- 사용자 지시: “Buddhist 전용 새 서명키로 설치해줘”. 기존 키 재사용 규칙의 Buddhist 예외를 명시적으로 승인했다.
- Christian 키/설정은 변경하지 않고 Buddhist 전용 RSA 3072 Release 키를 생성했다.
- 설치 안전장치 21 PASS / Windows 전용 1 SKIP. Buddhist/Christian backend 회귀 32 PASS.
- 공개 인증서 지문, 패키지, 버전, non-debuggable, 인터넷 권한 없음, 자산 격리를 검사한 뒤 설치했다.
- `adb install -r` 성공: SM-S908N, `com.onaria.buddhist`, `0.1.0+1`.
- `am start -W` 실행 성공 및 앱 프로세스 확인. 기기의 versionCode 1/versionName 0.1.0을 확인했다.
- 추가 화면 캡처는 기기에서 반환되지 않아 육안 화면 검증은 미실행이다.
- 기존 Christian 앱을 교체하거나 앱 데이터를 초기화하지 않았다.
- 전용 keystore와 key.properties는 Git 제외, 권한 0600을 확인했다. 키/설정은 향후 업데이트를 위해 별도로 안전하게 백업해야 한다.
