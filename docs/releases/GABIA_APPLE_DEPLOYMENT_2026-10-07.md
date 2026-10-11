# 가비아 Apple 탈퇴 배포 결과 (2026-10-07)

운영 대상은 `ari-prod-01`, `/opt/onaria/backend`, `onaria-backend.service`이다. 사용자의 운영 적용 요청 및 PR #38 main 병합 명시 승인을 받아 진행했다.

## 운영 적용

- 제공된 Apple 키의 형식과 ES256 서명/검증을 확인하고 ONARIA 전용 보호 폴더(700)/키 파일(600)에 배치했다. 기존 환경 파일 보호 백업 후 Team ID·Key ID·키 경로를 설정했다. 키·Secret·회원 토큰은 출력하거나 Git에 넣지 않았다.
- Apple 인증 서버에 잘못된 테스트 refresh 값으로 사전 점검: iOS/Android 모두 HTTP 400 `invalid_grant`, `invalid_client` 없음. 실제 회원 토큰을 사용하지 않았으며 실제 탈퇴 성공을 의미하지 않는다.
- [PR #38](https://github.com/Naharuya/onaria/pull/38) 병합 main `454cb6be2ee7de82abff9130b65900b6a1ec076c`. QA `37576571983`/Web `37576571988` 성공. 패키지 실행 `37577488245`, artifact `11462463878`.
- CI ZIP SHA256 `71cc29b1c5e9e7c87201203868e51bcc5ef48340260d84cc5a337f179344a974`; source commit·checksum·허용 경로 확인. 키·DB·runtime data 제외.
- 서비스를 중지한 상태에서 회원/세션 SQLite를 보호 백업하고 선택 연락처 변환을 실행했다. 기존 회원 1개·연결 계정 4개·세션 4개의 전체 행 내용이 변환 전후 및 배포 후 동일하다. foreign_key_check 오류 0.
- CI 제공 rollback 배포 스크립트로 적용/재시작 성공. 코드 복구 백업 `/opt/onaria-backups/deploy-20261007-144143-XjqYn3/previous`, DB 보호 백업 `/opt/onaria/rollout-20261007-GqWM9Q/db-before-rollout`. 백업에는 개인정보가 포함되어 보호 권한을 유지한다.
- 서버의 런타임 139개 파일은 CI ZIP과 모두 일치한다. 서비스 active. 재시작 프로세스의 Apple 설정 로딩 및 키 파일 600 확인.
- 공개 HTTPS `/health` 200/status ok, 미인증 `/v1/account` 401, 개인정보/약관/탈퇴 안내 페이지 200 및 최신 Gmail 문의처 확인. 비개인 테스트로 AI 동의 없는 응답 200 및 위기 단계 응답 200 확인.

## 앱 및 실제 탈퇴

Apple 재인증/철회 이후 계정 삭제와 모든 연결 세션 무효화, 실패 시 기존 계정/세션 보존을 구현했다. 앱은 삭제 직전 fresh 계정 조회로 Apple 연결을 확인하며, 서버 삭제 성공 시 로그인 표시를 정리한다. 마음카드와 임시문장은 보존한다.

backend 453 PASS, Web 브라우저 20 PASS, Flutter 150 PASS / 1 조건부 SKIP. 분석 오류/경고 0. 두 플랫폼 서명된 Release 0.4.4+10 준비. 두 기기 데이터 보존 업데이트 설치 성공. Android 공식 스크립트의 인증서/버전 검증 및 adb install -r 완료, 실행 정상. iPhone devicectl 설치 및 앱 목록 확인 완료, 원격 실행은 deviceLocked로 차단되어 잠금 해제 후 확인 필요.

기존 ONARIA 회원 계정으로 진행하도록 사용자 명시 승인을 받았다. iPhone 잠금 해제 후 앱 실행 성공, 사용자가 Apple 본인 인증을 거쳐 앱의 ‘회원탈퇴가 완료되었어요’ 표시를 보고했다. 이후 가비아 DB 읽기 전용 확인: 회원 1→0, 연결 계정 4→0, 회원 세션 4→0. 두 DB 외래키 오류 0, 공개 health 200/status ok. 앱 완료 표시는 사용자 확인이며 서버 삭제 및 세션 제거는 직접 검증했다. Apple 철회 API 원문 응답과 기존 토큰을 이용한 별도 401 재요청은 수집하지 않았다. 삭제 전 보호 백업은 별도로 남아 있으며 이번 검증은 활성 DB 삭제를 확인한 것이다. Android에서 탈퇴 후 재가입/재로그인은 아직 검증하지 않았다. 키·Secret·토큰·회원 데이터는 출력하지 않았다.

```yaml
PROJECT: ONARIA
CURRENT COMMIT: 454cb6be2ee7de82abff9130b65900b6a1ec076c (운영 백엔드)
ISSUE FOUND: Apple 철회 운영 설정 및 탈퇴 후 앱 표시 갱신 필요
PRIORITY: 출시 전 필수
ROOT CAUSE: 운영 키 미설정과 탈퇴 후 앱 상태 갱신 누락
IMPLEMENTED: Apple 키 보호 적용·연락처 선택 스키마 변환·CI 코드 배포·앱 표시 수정
CHANGED FILES: PR #38 백엔드 및 로컬 개인정보 화면·탈퇴 테스트
TEST: backend 453 PASS; Web 20 PASS; Flutter 150 PASS / 1 SKIP
BUILD: iOS/Android Release 서명 PASS
DEVICE: Android 설치/실행 PASS; iPhone 설치/실행 PASS, 탈퇴 완료 화면 사용자 확인
API: 운영 health/정책/미인증 차단/로컬 및 위기 응답 PASS; iPhone 탈퇴 후 회원·연결·세션 모두 0 확인 PASS
CI: main backend/Web/Android/iOS 및 배포 패키지 PASS
COMMIT: 백엔드 main 병합 완료; 로컬 앱 추가 수정 미커밋
PUSH: PR #38 main 병합·가비아 배포 완료
REMAINING RISKS: Android 탈퇴 이후 재가입/재로그인 미검증; 삭제 전 보호 백업 별도 보존
NEXT ACTION: 두 기기의 재가입/재로그인 검증 및 백업 보유 정책 확인
```
