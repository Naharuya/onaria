# ONARIA CODEX 작업지시서
## 소셜 로그인 · 기존회원 계정연결 구조 정상화 / Build 20

작성일: 2026-10-10
대상 프로젝트: ONARIA
프로젝트 경로: /Users/ari/ARI/projects/onaria
현재 앱 버전 후보: 1.0.0+20
Android package / iOS bundle: com.onaria.app

---

## 0. 최우선 원칙

이번 작업은 임시 우회가 아니라 회원 인증 구조를 정식으로 바로잡는 작업이다.

반드시 다음 원칙을 지킨다.

1. 다른 프로젝트(BEAVERS, K-Stock AI, RAMI, RealTrip, BONUI 등)에 절대 접근하거나 수정하지 않는다.
2. ONARIA 작업 전 현재 repo / branch / git status / 대상 파일을 먼저 확인한다.
3. 현재 working tree는 매우 dirty 상태이므로 reset, clean, checkout ., restore ., stash, 강제 덮어쓰기를 금지한다.
4. 기존 변경사항을 삭제하거나 되돌리지 않는다.
5. Production DB를 수정하기 전 반드시 별도 백업과 integrity_check를 수행한다.
6. 운영 회원 데이터의 수동 삭제, 임의 병합, 임의 provider identity 변경을 금지한다.
7. 이름, 전화번호, 교회명은 회원 인증 수단으로 사용하지 않는다.
8. 소셜 provider가 검증해 준 provider_user_id만 로그인 identity로 취급한다.
9. secret, OAuth token, Kakao/Naver/Google/Apple key, signing key, SSH key를 출력/로그/커밋하지 않는다.
10. Production 작업은 검증 가능한 최소 단위로 진행하고 각 단계마다 health / DB integrity / 테스트 결과를 기록한다.
11. App Store 심사 제출, Play Store 출시/프로덕션 공개는 하지 않는다.
12. 안전한 로컬 개발/테스트/빌드는 자동 진행한다. Production 변경 직전에는 현재 상태와 rollback 경로를 다시 확인한 뒤 진행한다.
13. 사용자에게 중간 선택을 묻지 말고 명확한 기술 판단이 가능한 부분은 스스로 판단하여 끝까지 진행한다.
14. 단, 비가역적 회원 데이터 변경, 스토어 제출, 외부 유료 서비스 변경이 필요하면 중지하고 보고한다.

---

## 1. 문제 정의

Galaxy S22 Ultra에서는 소셜 로그인한 기존 ONARIA 회원이 정상 로그인되었지만,
다른 Galaxy A33에서 같은 사용자가 다른 소셜 제공자로 인증하면 소셜 인증 자체는 성공하나
ONARIA 서버가 해당 provider identity를 기존 회원과 연결하지 못하고 신규회원으로 판단한다.

기존 흐름:

소셜 인증 성공
→ provider_user_id 조회
→ 연결 identity 없음
→ 신규회원 처리
→ 이름/전화번호/교회 입력
→ 기존 phone UNIQUE 충돌
→ PHONE_EXISTS 409
→ 가입/로그인 중단

이 문제를 “같은 전화번호면 자동 병합”으로 해결하면 안 된다.
전화번호는 현재 OTP 등 독립 검증을 하지 않으므로 계정 소유권 증거가 아니다.

---

## 2. 목표 구조

Canonical identity:

- 회원: members.id
- 인증 identity: member_identities(member_id, provider, provider_user_id)
- 프로필: name / phone / church_name
- 프로필 정보는 로그인 또는 계정 병합의 인증 근거로 사용 금지

원하는 최종 흐름:

### A. 기존에 연결된 소셜 계정
provider 인증
→ POST /v1/auth/provider/session
→ provider + provider_user_id로 member 검색
→ 세션 발급
→ 로그인 완료

### B. 처음 보는 소셜 계정
provider 인증
→ /provider/session 결과 PROVIDER_IDENTITY_NOT_FOUND
→ 앱에서 두 선택지 제공

1) 기존 ONARIA 계정에 연결
2) 새 계정 만들기

### C. 기존 ONARIA 계정에 연결
새 provider credential을 임시 보관
→ 사용자가 기존에 ONARIA에 연결했던 다른 소셜 provider로 다시 인증
→ 기존 provider로 ONARIA member session 발급
→ 인증된 member session + 새 provider credential을
  POST /v1/account/providers 로 전송
→ 서버가 새 provider identity를 기존 member_id에 연결
→ 새 provider 기준 session 재발급
→ 기존 session revoke
→ 이후 새 기기에서도 새 provider로 직접 로그인 가능

### D. 새 계정 만들기
provider credential + 필수 약관/연령 동의
→ POST /v1/auth/provider/signup
→ 신규 members row
→ member_identities row 생성
→ session 발급

---

## 3. 반드시 유지할 보안 규칙

다음은 모두 fail-closed여야 한다.

- 전화번호가 같아도 자동 병합 금지
- 이름이 같아도 자동 병합 금지
- 교회명이 같아도 자동 병합 금지
- provider credential 검증 없이 identity 연결 금지
- ONARIA member session 없이 provider 추가 연결 금지
- 다른 회원이 소유한 provider identity 연결 금지
- 동일 member에 동일 provider의 서로 다른 provider_user_id가 중복 연결되지 않도록 서버/DB 양쪽에서 차단
- 마지막 로그인 수단 unlink 금지
- 현재 로그인 provider unlink 금지
- 삭제된 member generation이 backup restore 후 부활하지 않도록 기존 deletion-manifest 설계 유지
- raw token/provider payload를 로그에 기록하지 않는다.

---

## 4. DB 최종 스키마 요구사항

### members

phone은 프로필 필드다.

최종적으로:
- phone nullable
- phone UNIQUE 제약 제거
- phone에 소유권 의미 부여 금지

기존 Production 상태 확인 결과:
- members: 1
- member_identities: 1
- provider: google 1
- phone nullable
- 하지만 sqlite_autoindex_members_1 에 의해 phone UNIQUE가 남아 있음

따라서 Production migration이 필요하다.

### member_identities

최소 다음 UNIQUE 규칙이 필요하다.

- UNIQUE(provider, provider_user_id)
- UNIQUE(member_id, provider)

의미:
- 하나의 소셜 identity는 한 회원에게만 속한다.
- 한 회원은 provider별 최대 한 계정만 연결한다.

동일 provider에서 다른 계정으로 바꾸는 기능은 이번 Build 20 범위에서 자동 병합하지 않는다.
향후 별도 re-auth + replace flow로 구현할 수 있다.

---

## 5. API 책임 분리

### POST /v1/auth/provider/session
역할: 로그인만 담당

입력:
- provider
- credential

성공:
- 201
- opaque ONARIA member session

미등록 provider identity:
- 404
- code: PROVIDER_IDENTITY_NOT_FOUND

### POST /v1/auth/provider/signup
역할: 신규 회원가입만 담당

이미 등록된 provider identity가 들어오면:
- 로그인으로 바꾸지 말 것
- 409
- code: IDENTITY_ALREADY_REGISTERED

신규 회원 생성 성공:
- 201

### POST /v1/account/providers
역할: 이미 로그인된 ONARIA 회원에 새 provider identity 연결

필수:
- X-Onaria-Member-Session
- provider
- credential

검증:
1. session 유효
2. current member 존재
3. 새 provider credential 서버 검증
4. provider identity가 다른 member 소유인지 확인
5. current member에 동일 provider가 이미 연결됐는지 확인
6. 문제 없을 때만 attach

충돌:
- IDENTITY_EXISTS
- PROVIDER_ALREADY_LINKED

성공:
- member
- 새 sessionToken
- expiresInSeconds
- linked=true/false

기존 session은 성공 후 revoke한다.

### DELETE /v1/account/providers/:provider
기존 규칙 유지:
- 마지막 로그인 수단 제거 금지
- 현재 로그인 provider 제거 금지
- Apple unlink 시 기존 revoke 절차 유지

---

## 6. 앱 UX

SignUpPage를 단순 signup page가 아니라 identity resolution 화면으로 동작시킨다.

상태 예시:

- idle
- chooseAction
- signUp
- linkExisting

미등록 social identity 인증 후 바로 회원정보 폼을 열지 않는다.

먼저:

“이 계정은 아직 ONARIA에 연결되어 있지 않아요.”

버튼:
- 기존 ONARIA 계정에 연결
- 새 계정 만들기

### 기존 계정 연결 선택

안내:
“위 로그인 버튼에서 예전에 ONARIA에 연결했던 다른 소셜 계정으로 본인 확인해 주세요.”

기존 provider 로그인 성공
→ 기존 member session 발급
→ pending new provider credential을 dedicated account link API에 전달
→ 성공하면 로그인 완료

### 새 계정 만들기 선택

그때만:
- 이름 선택
- 전화번호 선택
- 교회명 선택
- 만 18세 이상 필수
- 이용약관 필수
- 개인정보 처리 동의 필수

회원정보는 account merge 판단에 사용하지 않는다.

---

## 7. Production migration

현재 rollback backup 경로:

/opt/onaria-backups/social-identity-20261010-200210

Codex는 실제 작업 직전에 이 백업이 존재하고 읽을 수 있는지 확인한다.
필요하면 신규 timestamp backup을 하나 더 만든다.

운영 DB 예상 경로:

/opt/onaria/backend/data/members.sqlite

Migration 절차:

1. onaria-backend 상태/health 확인
2. members.sqlite 파일 크기/권한 확인
3. sqlite integrity_check
4. foreign_key_check
5. member 수 / identity 수 aggregate 기록
6. 최신 timestamp backup 생성
7. 서비스를 안전하게 stop
8. migration 실행
9. phone UNIQUE 제거 확인
10. member_identities에 UNIQUE(member_id, provider) 적용
11. integrity_check
12. foreign_key_check
13. 기존 member count 동일 확인
14. 기존 identity count 동일 확인
15. service start
16. local /health 확인
17. public https://api.onaria.ai.kr/health 확인
18. 기존 Google 회원 login smoke test
19. 실패하면 즉시 rollback 후 service 복구

Production 회원 row를 테스트용으로 직접 바꾸거나 삭제하지 않는다.

---

## 8. Migration 구현 조건

SQLite table rebuild 시 반드시 보존:

members:
- id
- name
- phone
- church_name
- login_provider
- provider_user_id
- created_at
- updated_at
- terms_version
- privacy_version
- consented_at
- AUTOINCREMENT sequence

member_identities:
- id
- member_id
- provider
- provider_user_id
- created_at

검증:
- PRAGMA integrity_check = ok
- PRAGMA foreign_key_check = empty
- sqlite_sequence 보존
- 기존 member IDs 불변
- 기존 provider identity ownership 불변

Migration은:
- 명시적 --check
- 명시적 --apply + backup path
- 서버 시작 시 자동 migration 금지
- migration 파일은 재실행 안전 또는 이미 완료 시 no-op

---

## 9. 테스트 필수 항목

Backend 전체 테스트는 최소 현재 기준보다 줄어들면 안 된다.

현재 기준:
- backend full: 483 PASS / 0 FAIL

추가/유지 테스트:

1. registered provider → provider/session login
2. unknown provider → 404 PROVIDER_IDENTITY_NOT_FOUND
3. provider/signup은 기존 provider identity를 로그인 처리하지 않고 409
4. 신규 provider signup 성공
5. 같은 phone으로 서로 다른 member 생성 가능
6. phone/profile만으로 자동 account merge 불가
7. authenticated account provider linking 성공
8. invalid member session linking 실패
9. identity owned by another member → 409
10. same member same provider different identity → PROVIDER_ALREADY_LINKED
11. duplicate same identity idempotent 또는 명시적 safe response
12. unlink final identity 차단
13. unlink current provider 차단
14. member delete 시 linked identity 전부 정리
15. backup/restore 후 identity ownership 유지
16. deletion manifest 회귀 없음

Flutter:
- login layout
- unknown identity → chooseAction
- create new → signup form
- link existing → 기존 계정 인증 안내
- successful link → member session 저장
- failed existing provider verification → pending new provider 유지
- small screen / large text overflow 없음
- Android/iOS provider order 유지

flutter analyze:
- error 0
- warning 0

---

## 10. Build 20

pubspec.yaml:
version: 1.0.0+20

서버 health / release log에도:
version 1.0.0
build 20

Android:
- release APK
- release AAB
- package com.onaria.app
- versionCode 20
- versionName 1.0.0
- targetSdk 기존 설정 유지
- signing 변경 금지
- protected Kakao dart-define 사용
- key 값 출력 금지

iOS:
- Version 1.0.0
- Build 20
- bundle com.onaria.app
- 기존 signing team 유지
- App Store Connect 업로드는 사용자가 별도 승인하기 전 금지

---

## 11. Android 실기기 교차 검증

현재 연결 가능한 대상:

1. Galaxy S22 Ultra
   - model SM-S908N
   - serial R3CT10BVG6V

2. Galaxy A33
   - model SM-A336N
   - serial RFCW1178RRE

둘 다 현재 1.0.0(19)이 설치된 상태에서 시작한다.

Build 20을 설치할 때:
- 가능하면 data 유지 upgrade install 먼저
- 기존 로그인 session 파괴 여부 확인
- 필요할 경우 별도 fresh-install 시나리오도 진행
- 테스트 전에 회원 DB를 임의 초기화하지 않는다.

필수 시나리오:

### Scenario 1
기존 Google identity
- S22 Google 로그인
- A33 동일 Google 로그인
- 둘 다 기존 동일 ONARIA member로 로그인
- 신규 회원 row 생성 금지

### Scenario 2
기존 Google 회원 → Naver 연결
- A33 Naver 인증
- unknown identity 확인
- “기존 ONARIA 계정에 연결”
- 기존 Google 인증
- Naver attach
- 앱 로그아웃
- A33에서 Naver 직접 로그인
- 기존 동일 member 확인

### Scenario 3
Kakao 동일 방식

### Scenario 4
Apple 동일 방식

Apple Android flow는 기존 challenge/state/nonce 검증을 유지한다.

각 성공 후:
- member count 예상값
- identity count 예상값
- provider 목록
을 개인정보 없이 aggregate로 검증한다.

---

## 12. iPhone 회귀 테스트

Android 완료 후 현재 연결된 iPhone 15에서도 Build 20 로컬 signed release를 검증한다.

- Apple
- Google
- Naver
- Kakao
- 기존 회원 로그인
- 연결 계정 표시
- 로그아웃
- 재로그인
- 앱 재실행 session persistence

기존 Build 19에서 통과했던 계정삭제 흐름도 최소 회귀 테스트한다.
실제 destructive delete는 disposable account만 사용한다.

---

## 13. 절대 하지 말 것

- 기존 운영 회원을 테스트 편의상 삭제
- 기존 운영 identity를 직접 SQL UPDATE
- 전화번호 기준 자동 병합
- phone UNIQUE만 제거하고 account-link UX/API를 미완성 상태로 배포
- app만 Build 20으로 올리고 backend 구버전 유지
- backend만 올리고 Build 19 앱으로 최종 PASS 선언
- dirty working tree reset/clean
- unrelated file formatting
- 다른 프로젝트 접근
- secret 출력
- GitHub main merge
- App Store / Play production 제출

---

## 14. Git / 브랜치

현재 dirty root를 직접 정리하려 하지 않는다.

가능하면 origin/main 또는 가장 적절한 검증된 release base에서 별도 worktree/branch를 만든 뒤
이번 social identity 관련 변경만 선별하여 옮긴다.

권장 브랜치:
release/social-identity-build20-20261010

선별 대상 예:
- backend/src/app.js
- backend/src/member_store.js
- backend/src/optional_profile_migration.js
- backend/scripts/migrate_optional_profiles.js
- 관련 backend tests
- lib/features/signup_page.dart
- lib/src/api/member_api_client.dart
- 관련 Flutter tests
- pubspec.yaml
- release documentation

하지만 기존 deletion manifest / Apple auth / current web parity 의존성이 있으면 먼저 diff를 분석하고 필요한 의존 파일을 명시적으로 포함한다.

사용자의 별도 승인 없이 main merge 금지.
커밋/푸시는 기존 승인 범위가 불명확하면 작업 완료 후 준비 상태까지만 만들고 보고한다.

---

## 15. 완료 판정

아래가 모두 PASS일 때만 “해결 완료”라고 보고한다.

- Production DB migration 성공
- Production health 정상
- 기존 회원/identity 수 보존
- phone UNIQUE 제거 확인
- member_identities ownership constraints 확인
- backend full tests PASS
- Flutter focused/full relevant tests PASS
- analyze error/warning 0
- Build 20 APK/AAB 생성
- S22 Build 20
- A33 Build 20
- 두 기기 기존 Google 로그인 PASS
- Naver 계정 연결 후 새 기기 직접 로그인 PASS
- Kakao 계정 연결 후 새 기기 직접 로그인 PASS
- Apple 계정 연결 후 새 기기 직접 로그인 PASS
- 신규회원 생성 오염 없음
- 다른 회원 계정 자동병합 불가 확인
- release log 업데이트

실기기에서 사용자 입력이 필요한 공급자 로그인/2FA/동의 화면이 나오면 그 지점에서만:
- 현재 화면
- 눌러야 할 항목
- 기대 결과
를 짧게 보고하고 기다린다.

---

## 16. 최종 보고 형식

최종 보고는 다음 순서로 작성한다.

1. 원인
2. 변경한 아키텍처
3. DB migration 결과
4. Backend test 결과
5. Flutter test/analyze 결과
6. Build 20 artifact 결과
7. S22 4-provider 결과
8. A33 4-provider 결과
9. iPhone 회귀 결과
10. Production health
11. Git 상태 / branch / commit 여부
12. 남은 blocker
13. 최종 판정: PASS / BLOCKED

PASS가 아닌 항목을 PASS라고 쓰지 않는다.
미확인 항목은 반드시 “미확인”으로 표기한다.
