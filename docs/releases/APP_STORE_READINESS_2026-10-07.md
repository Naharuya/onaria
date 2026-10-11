# ONARIA App Store 출시 수정 결과

이 문서는 초기 수정 시점의 기록이다. 이후 가비아 배포·실제 탈퇴 검증은 [가비아 결과](GABIA_APPLE_DEPLOYMENT_2026-10-07.md), 최신 앱 커밋·Archive·서명 상태는 [App Store 빌드 결과](APP_STORE_BUILD_2026-10-07.md)를 따른다.


기준일: 2026-10-07, 사용자 지정: 무료 출시 · 만 18세 이상 · 문의 vjsjv7003@gmail.com.

## 수정한 내용

- 소셜 가입의 이름·전화번호·교회명을 선택 입력으로 변경. 국제 형식 전화번호 허용. 서버에서 필수 약관·개인정보·성인 확인을 검증. 기존 회원 로그인은 프로필 재입력 없이 동일 회원으로 유지.
- 신규 DB는 전화번호 NULL을 허용. 기존 운영 DB는 자동 변환하지 않음. 명시적 변환 도구는 백업 후 트랜잭션으로 회원 ID·연결 계정·동의 기록·AUTOINCREMENT 순서를 보존. 알려지지 않은 스키마/사용자 정의 인덱스/트리거는 거부.
- Apple 연결 해제/탈퇴: 새로운 본인 확인과 코드 교환, 연결된 Apple 사용자 일치 검증, Apple 토큰 철회 후 회원 삭제. 철회 실패 시 회원·세션 보존. 성공 시 연결 계정들의 ONARIA 세션도 철회. Android opaque proof는 일회 소비.
- AI 전송 전에 OpenAI·전달 항목·목적·처리 한계 안내, 기본 미선택 성인 확인과 명시적 전송 허용. 거부하면 입력 유지/전송 없음. 철회 가능. 서버는 동의 누락/구버전이면 외부 모델·검색 없이 로컬 응답. 위기 대응은 외부 호출 없이 유지.
- 영어 NIV 개발용 본문을 공식 Public Domain WEB 14개 구절로 교체. 한국어 14개 구절은 공식 개역한글 원문과 대조해 혼합 표현 교정. 출처·사용 조건·체크섬 기록 및 앱 표시. 기존 저장 기록은 보존.
- 정책·약관·탈퇴 안내에 확인된 문의처와 무료·18세 이상 조건, 실제 데이터 흐름 반영. 구현되지 않은 1년 자동 파기/검증되지 않은 국외이전 없음 주장을 제거.
- iOS 기본 투명 시작 이미지 대신 ONARIA 시작 화면 사용.

## 검증

- 전체 backend: 453 PASS / 0 FAIL.
- 전체 Flutter: 145 PASS / 1 SKIP / 0 FAIL. SKIP은 운영 API가 설정돼 있어 잘못된 API 설정을 주입할 수 없는 기존 조건부 테스트.
- Flutter analyze lib test example --no-fatal-infos: 오류·경고 0, info 17.
- iOS Release unsigned Archive: PASS, 0.4.4 (10), iOS 27 SDK. 시작 이미지 경고 없음. 포함된 SDK 개인정보 매니페스트 21개 plist 파싱 정상. App Store Connect 검사·개인정보 보고서 승인을 대체하지 않음.
- Android Release APK: PASS. 최초 병행 빌드에서 테스트용 GeneratedPluginRegistrant가 섞인 실패가 있었고, 테스트 종료 후 정식 설정으로 재생성한 단독 빌드 성공.
- 공개 웹 정책 회귀: 8 PASS. 공식 한·영 말씀 원문/체크섬 대조 PASS.
- 변경 파일 git diff --check PASS. 알려진 로컬 네이버 Secret과 변경·미추적 파일 대조: 일치 0. 비밀 내용 출력 없음.

## 운영 상태와 남은 출시 조건

운영 서버는 읽기 전용으로 확인했다. 서비스 active, 외부 AI 차단, embedding local. 사용량 62일 정리는 완료된 사용량 요청 행에 적용되며 전체 개인정보·로그·백업의 62일 파기를 의미하지 않는다. 회원 세션 기본 만료는 30일. 다른 프로젝트·서비스 변경 없음.

1. Apple 인증 철회용 기존 Sign in with Apple 키와 서버 로컬 설정 준비. 안전한 로컬 입력 폴더 `/Users/ari/ARI/.private/onaria/apple/`는 권한 700으로 준비. 키 내용은 채팅·Git·로그에 넣지 않는다. [설정 설명](../APPLE_ACCOUNT_DELETION.md).
2. 유효한 App Store 배포 인증서가 현재 Mac 키체인에서 발견되지 않음(개발용 1개). 배포 서명·TestFlight 업로드·App Store Connect의 빌드번호 중복 확인 필요. Archive는 아직 서명되지 않음.
3. 운영 로그·백업 보유기간 및 삭제 절차 확정. 현재 정책 문구 개선만으로 법적 검토/전체 파기 완료로 표시하지 않음.
4. 운영 DB 변환·서버 재시작은 프로젝트 AGENTS.md 승인 경계에 따라 검토된 후보/CI artifact와 백업 준비 후 별도 승인 필요. 현재 운영 변경 없음. 서버를 앱보다 먼저 배포해야 새 AI 동의 필드가 정상 처리됨.
5. 테스트용 계정으로 iPhone/Android 재로그인·Apple 연결 해제·탈퇴 및 철회 확인. 기존 실제 회원을 삭제 테스트에 사용하지 않음.
6. App Store Connect에서 실제 App Privacy, 18세 이상 연령 등급 설문, 무료 가격, 지원 URL, 심사 계정/설명, 스크린샷 설정. 아직 콘솔 값을 변경하지 않음.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 1aef3815c8e25022a948c4307e1c755e5cc8507b
ISSUE FOUND: 개인정보 고지·필수 연락처·Apple 철회·AI 동의·성경 권리·시작 화면·배포 서명
PRIORITY: 출시 전 필수
ROOT CAUSE: 구현과 고지 불일치 및 배포/인증 외부 설정 미준비
IMPLEMENTED: 로컬 코드·정책·콘텐츠·회원 보존 변환 도구 수정
CHANGED FILES: 본문에 열거한 가입·탈퇴·동의·말씀·정책·iOS 시작 화면 및 테스트
TEST: backend 453 PASS; Flutter 145 PASS 1 SKIP; analyze 오류/경고 0
BUILD: iOS unsigned Archive PASS; Android Release APK PASS
DEVICE: NOT RUN — 운영 새 API 배포 전 설치·실계정 삭제 미실행
API: 운영 읽기 전용 설정 확인; 실제 Apple 철회 NOT RUN — 키 미설정
CI: NOT RUN — 미커밋 로컬 후보
COMMIT: NOT RUN — 기존 음성·에이전트 미커밋 작업 보존
PUSH: NOT RUN
REMAINING RISKS: Apple 키·배포 서명·운영 로그/백업 정책·운영 배포·기기 검증·스토어 콘솔
NEXT ACTION: 안전한 키 입력 및 배포 계정 준비 후 CI 후보·운영 적용 검토
```
