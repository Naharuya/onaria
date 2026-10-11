# ONARIA 계정 통합 개발 지시서 — 2026-10-11
상태: 설계 및 읽기 전용 계획 검증 완료, 실행 API/기기 기록 통합 미구현, 운영 보류.
## 목적
소셜 인증 자체와 기존 회원 연결 실패를 분리한다. 이미 각각 가입된 회원은 삭제하거나 자동 연결하지 않고, 두 회원의 소유권 확인과 명시적 동의 후 통합한다.
처음 보는 소셜 계정은 기존 계정 연결 또는 신규 가입을 선택한다. 모든 소셜 로그인마다 새 회원을 생성하지 않는다.
## 현재 증거
운영 DB 읽기 전용 조회: #4 google+kakao, #5 apple, #6 naver. 이 세 계정이 같은 사용자 소유인지는 미확정.
현재 연결 API는 다른 회원 소유 identity에 409 IDENTITY_EXISTS를 반환한다. 최초 신규 가입 전 연결 실패는 별도 조사한다.
기기 기록 키: onaria.records.v2.member.<memberId>.<legacyKey>. 서버 identity만 옮기면 이전 회원의 기록은 자동으로 보이지 않는다.
## 사용자 흐름
설정 > 계정과 기록 관리 > 내 계정 통합
1. 유지할 회원으로 새 소셜 인증. 화면에 유지 계정 표시.
2. 통합할 회원의 소셜 인증. 서버가 provider+subject 소유 회원을 다시 조회한다.
3. 통합 전 요약: 유지 로그인 방식, 추가 로그인 방식, 기기에서 확인된 기록 수, 아직 확인하지 못한 다른 기기 기록.
4. 명시적 통합 동의. 동일 제공자의 다른 계정 충돌은 별도 선택 설계 전까지 차단.
5. 서버 처리 결과와 기기 기록 반영 상태를 분리해 표시. 인증 취소 시 어떤 identity도 옮기지 않는다.
소유자 불명 이전 기록/게스트 기록은 별도 수동 소유권 검증 전까지 제외.
## 서버 구현 순서
- 준비 API: 기존 세션 + 유지/출발 양쪽의 최신 provider 증명. 임의 memberId 또는 verified=true를 클라이언트에서 받아 소유권 인정하지 않음.
- 각각의 verifier로 subject/audience/issuer/expiry/nonce 등 제공자별 검증. 서버 DB identity로 회원 역조회.
- merge attempt는 난수 일회용 ID, 짧은 유효기간, 목적/양 회원/사용자 세션에 결합. 원문 provider 토큰은 영구 DB/로그/계획 결과에 저장하지 않음.
- 확인 API: attempt와 명시적 동의 및 재사용 방지. 확인 시 소유권과 충돌 재조회. 실행 요청의 targetId/sourceIds 재지정 금지.
- 회원 DB 트랜잭션에서 canonical mapping, identity 이전, 통합 영수증 기록. 출발 회원 원본을 즉시 삭제하지 않음.
- 별도 session DB와 원자 트랜잭션 불가하므로 단순 순차 실행 금지. 기존 세션 차단/재시도 가능한 작업 상태와 outbox 설계. identity 이전 후 구세션이 출발 회원을 열 수 없어야 함.
- 완료 영수증과 멱등 재시도. 응답 유실은 receipt 조회로 판별. 원복은 동시 변경/새 기록 반영 여부를 검증한 별도 작업이며 무조건 DB 복원 금지.
- 미구현 상태의 planner는 실행 권한을 주지 않는다. 운영 라우트에 연결하지 않음.
## 기기 기록 보존
- 서버가 인증된 canonical member와 허용된 원래 record owner IDs를 제공한다. 클라이언트 임의 ID 열람 금지.
- 원본 키는 유지하고 staging에 복사 후 개수/항목 체크섬/소유권 검증. record ID 충돌은 별도 보존하고 출처 owner ID를 포함해 구분.
- 복사 도중 실패해도 원본 보존, 재시도 멱등. 서버 통합 완료를 기기 복사 실패로 번복 안내하지 않음.
- 다른 기기에만 존재하는 기록은 이 기기에서 통합됐다고 표시하지 않음. 해당 기기의 로그인 후 별도 반영.
- 계정 전환 generation lease 유지. 이전 계정의 지연 비동기 저장이 새로운 통합 계정에 섞이지 않도록 검증.
- 통합 후 탈퇴/백업 파기: 모든 합법적으로 연결된 owner namespace에 적용하는 별도 정책 및 구현을 활성화 전에 완료.
## 검증 기준
두 계정 증명 누락/만료/다른 사용자/위조/재사용 거부, 동일 provider 충돌 거부, 동시 연결/탈퇴 충돌, 세션 DB 실패, 응답 유실 재시도, 복사 중 종료, record ID 충돌, 다른 회원 기록 무변경, 게스트/legacy 무변경, 모든 구세션 차단.
운영 snapshot으로 새 계정 소유자가 같은 사람이라고 판정하지 않는다.
## 현재 구현
backend/src/account_merge_plan.js: 서버 snapshot 대상의 순수 읽기 전용 계획기. 계정 존재/고아 identity/중복 identity/제공자 충돌 검증. 인증/실행 기능 없음.
backend/test/account_merge_plan.test.js: 6 PASS.
## 작업 경계
운영 migration/통합/서비스 재시작/커밋/푸시 보류 유지. 테스트 계정으로 로컬 완료 후 실제 두 계정 인증 및 통합 요약을 사용자에게 제시한다.


## Implementation update — Build24

Local executable optional merge API and client UX now implemented and tested. Earlier PLAN_ONLY entries describe the previous state. Runtime activation remains OFF. Exact behavior, limitations, test evidence and deployment gates: ONARIA_OPTIONAL_ACCOUNT_MERGE_BUILD24_2026-10-11.md.
