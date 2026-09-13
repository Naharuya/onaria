# Ari Verification Core v0.1

## 목적
Mac mini의 `/Users/server/ari-server`에 공통 코드 검증 엔진 1개를 두고, 각 프로젝트는 `.ari/verification.yaml`만 가진다. 공통 로직을 프로젝트마다 복제하지 않는다.

## 대상
- ONARIA/SoulBible: `/Users/server/ari-server/projects/onaria` 또는 현재 실제 clone 경로
- RAMI
- K-Stock AI

## 동작 원칙
1. 각 프로젝트의 Git HEAD/working tree 변화를 감시한다.
2. 마지막 코드 변경 후 20분(1200초) 동안 추가 변경이 없을 때 검증을 시작한다.
3. 새 변경이 생기면 기존 타이머를 취소하고 다시 20분을 센다(debounce).
4. 프로젝트별 `.ari/verification.yaml`을 읽어 검증 명령을 실행한다.
5. 실패 시 실패 로그를 요약해 Ari Main Manager에 전달한다.
6. 자동수정 가능 오류면 Codex repair worker를 호출해 최대 2회까지만 수정한다.
7. 수정 후 동일 검증을 다시 수행한다.
8. 2회 실패, 정책 변경 필요, 보안/안전/실거래 관련 이슈는 `HUMAN_REVIEW`로 중단한다.
9. protected branch(main/master)는 자동수정/직접 commit 금지. repair 전용 브랜치에서만 변경한다.
10. main/master 자동 merge, production deploy, 앱마켓 publish는 금지한다.

## 상태
- `IDLE`
- `DEBOUNCING`
- `VERIFYING`
- `REPAIRING`
- `REVERIFYING`
- `SERVER_PASS`
- `FAIL`
- `HUMAN_REVIEW`

## 공통 검증
- git diff/check
- secret scan(출력에는 secret 값 금지)
- project profile command runner
- test/analyze/lint
- build 가능 여부
- 결과 JSON + Markdown report

## 프로젝트별 핵심 규칙
### ONARIA
- Safety/Crisis 우선
- 위험 입력에서 Psychology/Religion/OpenAI downstream 호출 0
- Bible RAG/Citation regression
- Flutter test/analyze
- PASS 시 debug APK 생성 가능

### RAMI
- Flutter test/analyze
- NFC NDEF parsing
- initial/warm deep link
- duplicate URI/scan protection
- invalid URI fallback
- ContentScreen navigation
- PASS 시 debug APK 생성 가능

### K-Stock AI
- npm test + smoke
- KIS/OpenDART는 mock/stub 검증 우선
- `KSTOCK_LIVE_TRADING_ENABLED=true`이면 즉시 HUMAN_REVIEW/FAIL
- 실주문/무제어 외부 요청 금지

## 자동수정 정책
자동수정 허용:
- 컴파일/타입/린트 오류
- 테스트로 명확히 재현되는 회귀
- deterministic parser/routing 오류
- 누락된 guard/test 보강

자동수정 금지:
- Safety 정책 완화
- 개인정보/보관정책 변경
- 결제/가격/실거래 활성화
- API key/secret 변경
- production deploy
- 앱마켓 배포

## Codex repair worker
- 실패 로그와 변경 diff만 전달한다.
- 해당 프로젝트와 실패 범위 밖의 파일 변경을 최소화한다.
- 테스트 삭제/skip/기준 완화로 PASS를 만들지 않는다.
- 매 repair마다 commit을 분리한다.
- 최대 2회.

## 보고
각 실행 결과:
- project
- start/end
- triggering commit
- checks
- failures
- repairs attempted
- final state
- artifact path
- human decision needed

보고서는 `/Users/server/ari-server/reports/<project>/`와 프로젝트 내부 `.ari/reports/` 중 적절한 위치에 저장한다.

## macOS 서비스
- `launchd`로 verifier daemon을 부팅 시 자동 시작
- 비정상 종료 시 재시작
- 중복 인스턴스 방지 lock
- 로그 rotation
- Codex rate-limit/로그인 실패 시 코드 변경 없이 HUMAN_REVIEW

## 완료조건
- 세 프로젝트를 한 개 Verification Core가 관리
- 코드 변경 후 20분 quiet window 검증
- 새 변경 시 debounce 재시작
- 실패 시 최대 2회 bounded repair
- 재검증 성공 시 SERVER_PASS
- 실패 시 FAIL/HUMAN_REVIEW
- protected branch 직접 수정 없음
- 실거래/production/app-store 자동행위 없음
