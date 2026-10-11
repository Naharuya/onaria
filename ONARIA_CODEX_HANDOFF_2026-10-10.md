# ONARIA CODEX HANDOFF — 2026-10-10

## 현재 상태 — 이전 계획보다 우선 (2026-10-10)
- HEAD1aef3815c8e25022a948c4307e1c755e5cc8507b, branch codex/apple-android-20261006. 기존 미커밋 작업 보존.
- Android/iPhone signed Release1.0.0(18) 유지. 메뉴/로그인/실제 버전 표시/기록 보존/세션 GET200은 앞선 검증 PASS. 현재 기기 조작 보류.
- 백엔드 최종469 PASS. 영속 탈퇴·복원·독립 프로세스 경합·실제 원장 schema adapter는 격리 PASS이며 운영 연결/실제 회원-원장 association 미완성.
- 공개 저장소 PUBLIC 확인. 접속 정보는 추적 제외 SSH_ACCESS.md만 참조. 기존 호스트 키 검증을 유지한 실제 접속 성공, ONARIA 경로/서비스 확인. 키 내용·비밀번호·토큰 기록 없음.
- Apple 설정6개 존재, 참조 키0600/서비스 사용자 읽기 가능. 실제 외부 철회 미실행.
- 읽을 수 있었던 DB 사본 중 최장은10월6일, 별도10월7일 보호 사본 확인. 일부 백업 경로 접근 오류로 전체 최장/정기 주기/만료/외부 복사본 미확정.
- HEAD 통합 패치 별도 사본 PASS, origin/main 직접 적용 FAIL. 검색 자산·출처·번역 권리 미확인으로 보류.
- 1년 기산점/예외·백업30일/명부37일 미확정 및 미적용. 과거 iPhone 인증 실패 원인 미확정. 운영 Release Gate 미통과.
- 운영 변경/재시작·build18 교체/인증/삭제 조작·외부 철회·병합/리베이스·커밋/푸시/배포 보류.
- 상세 증거와 미완료 항목: docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md. 아래 PRE-FLIGHT 값과 목적은 최초 인계 당시 기록이며 현재 상태로 재사용하지 않는다.

## 목적
오늘 우선작업 1번을 안전하게 진행한다.
1) 현재 로컬 변경 63건을 분류·보존하고 GitHub main과의 분기(+5/-4)를 분석한다.
2) iPhone 15에서 ONARIA 0.4.4+10 로그인/로그아웃/계정삭제 E2E를 준비하고 로그를 수집한다.
3) Android 실기기 연결이 복구되면 동일 핵심 흐름을 검증한다.
4) Release Gate 전에는 merge/push/Production 배포/운영 DB 변경을 하지 않는다.

## PRE-FLIGHT — 반드시 첫 단계
현재 확인값:
- Project: /Users/ari/ARI/projects/onaria
- Branch: codex/apple-android-20261006
- HEAD: 1aef3815c8e2
- Tracking remote: origin/codex/login-ux-20261006
- Tracking remote 대비: 0 ahead / 0 behind
- origin/main: 3fa97ca65f3c
- origin/main 대비: 5 ahead / 4 behind
- Dirty entries: 63
- App version: 0.4.4+10
- iPhone: Xcode에서 실제 기기 인식됨 (UDID 00008120-001855410CC3A01E, iOS 26.6.1)
- Android: adb devices 기준 현재 0대

시작 즉시 위 값들을 다시 읽기 전용으로 확인하고 달라진 값이 있으면 이 문서의 값보다 실제 현재값을 우선한다.

## 절대 금지
- git reset --hard / git clean / 강제 checkout / 강제 rebase
- 미커밋 파일 삭제 또는 덮어쓰기
- origin/main 또는 다른 프로젝트 파일로 강제 동기화
- 사용자 승인 없는 merge, push, tag, release
- Production 코드 자동 배포
- 운영 DB migration/overwrite/양방향 sync
- 실제 사용자 데이터 수정
- 로그인 비밀번호/토큰/secret을 로그나 파일에 기록

## CODEX가 자동으로 진행할 작업

### A. 변경 63건 분류
git status와 diff를 읽고 아래 그룹으로 표를 만든다.
- AUTH: Apple/Google/Kakao/Naver 로그인, session, logout
- ACCOUNT: 회원가입, 개인정보, 계정삭제, optional profile, AI consent
- APP/UI: conversation, narration, launch screen, app UI
- BACKEND: app/server/schema/member store
- RAG/LICENSE: bible corpus, knowledge/vector/production corpus
- STORE/RELEASE DOCS
- TESTS
- AGENT/TOOLS
각 파일에 대해 수정/신규/삭제, 목적, 위험도, 다른 변경과의 의존성을 기록한다.

### B. main 분기 분석
- git fetch origin --prune
- HEAD...origin/main의 5개 local-only commit과 4개 main-only commit을 목록화한다.
- 충돌 예상 파일을 미리 표시한다.
- 지금은 merge/rebase/cherry-pick 하지 않는다.
- 가장 안전한 통합 전략을 제안만 한다.

### C. 로컬 검증
현재 working tree를 보존한 채 다음을 실행한다.
1. backend 테스트
2. flutter test
3. flutter analyze
4. 가능한 경우 iOS no-signing build / Android debug build
실패 시 원인을 수정할 수 있는 범위는 오늘 우선작업(AUTH/ACCOUNT/기기 검증)과 직접 관련된 변경으로 제한한다.
RAG/라이선스, 마케팅, unrelated 기능은 오늘 임의 수정하지 않는다.

### D. iPhone 15 준비
- 연결 상태, signing/team, bundle id, app version/build를 확인한다.
- 현재 소스로 iPhone 설치/실행 가능한지 검증한다.
- 앱을 실행해 사용자가 직접 조작할 수 있게 준비한다.
- 사용자가 로그인 공급자 화면에서 계정 선택/동의/비밀번호 입력을 직접 하도록 한다.
- Codex는 콘솔/네트워크 로그를 관찰하되 secret/token/password를 출력하거나 저장하지 않는다.

검증 시나리오:
1. 앱 실행 → 버전 0.4.4+10 확인
2. 로그아웃 버튼 노출 확인
3. Google 로그인 → 성공/실패와 HTTP status 기록
4. Kakao 로그인 → 성공/실패와 HTTP status 기록
5. Naver 로그인 → 성공/실패와 HTTP status 기록
6. Apple 로그인 → 성공/실패와 HTTP status 기록
7. 앱 재실행 후 session 유지 확인
8. 로그아웃 → session 폐기 확인
9. 재로그인 → 계정 중복/401 재현 여부 확인
10. 계정삭제 UI → 본인확인 → 삭제 → session 폐기 → 재로그인 결과 확인
각 결과를 PASS/FAIL/BLOCKED로 구분한다.

### E. Android
현재 adb 연결 장치가 없으므로 자동으로 기다리거나 무한 polling하지 않는다.
사용자가 Android에서 USB 디버깅 또는 무선 디버깅을 연결한 뒤 다시:
- adb devices
- 앱 version/build
- 설치/실행
- Google/Kakao/Naver 로그인
- session 유지/로그아웃
- 계정삭제 E2E
를 iPhone과 동일 기준으로 검증한다.

## 사용자에게 넘길 작업
아래는 Codex가 대신 결정/입력하지 않는다.
- iPhone/Android 잠금해제
- 로그인 공급자에서 실제 계정 선택
- 비밀번호/2FA 입력
- 개인정보·필수 동의 화면의 최종 확인
- 계정삭제 최종 확인 버튼
- Android USB/무선 디버깅 연결
- Apple Developer/App Store Connect에서 외부 계정 승인 필요 시 사용자 승인
- merge/push/Production 배포 최종 승인

## 완료 산출물
작업 종료 시 아래 파일을 만든다.
- docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md
내용:
1. preflight 실제값
2. 63개 변경 분류표
3. origin/main 분기 5/4 분석
4. local test/analyze/build 결과
5. iPhone E2E 표
6. Android E2E 표 또는 BLOCKED 이유
7. 남은 출시 차단요소
8. 추천 통합 전략
9. 'Production 배포/DB 변경 수행 안 함' 명시

## 완료 판정
다음 모두 충족 전에는 '완료'라고 쓰지 않는다.
- dirty 변경이 무엇인지 설명 가능
- local tests 결과가 실제 실행 증거로 기록됨
- iPhone 핵심 E2E가 실제 실기기 결과로 기록됨
- Android 미연결이면 BLOCKED로 정확히 기록됨
- main 분기 해결 방향이 제안됨
- Release Gate 상태가 명확함

## 시작 명령
이 파일을 읽은 뒤:
"PRE-FLIGHT부터 실행하고, 현재 working tree를 절대 잃지 말고, 승인 필요 작업 전까지만 자동 진행해. 결과는 docs/releases/ONARIA_LOCAL_REVIEW_2026-10-10.md에 계속 기록해."
