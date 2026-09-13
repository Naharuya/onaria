# ARI Agent Ownership & De-duplication Policy v1.0

## 목적
모든 에이전트는 단일 책임과 단일 소유권을 가진다. 동일 Task를 두 에이전트가 동시에 소유하거나 같은 파일/결정을 중복 수행하지 않는다.

## 핵심 원칙
1. **Single Owner**: 모든 Task는 정확히 1명의 Primary Owner Agent만 가진다.
2. **Single Writer**: 동일 파일/리소스는 동시에 1개 Agent만 수정한다.
3. **Review != Ownership**: Review Agent는 검증만 하고 수정은 하지 않는다.
4. **Verification Core는 공통 1개**: 프로젝트마다 QA Agent를 복제하지 않는다. 각 앱은 `.ari/verification.yaml`만 가진다.
5. **Manager는 실행자가 아님**: Main/Domain Manager는 Task 분해·배정·의존성·판정만 담당한다.
6. **중복 Task 병합**: 같은 프로젝트/목표/파일 범위의 Task가 열리면 새 Task를 만들지 않고 기존 Task에 합친다.
7. **Task Lock**: `project + task_type + resource_scope`를 키로 lock을 잡아 중복 실행을 차단한다.
8. **Worktree Isolation**: 서로 다른 Coding/Repair Task는 별도 worktree/branch를 사용한다.
9. **최대 2회 Repair**: Repair Agent는 동일 실패에 최대 2회만 개입하고 이후 HUMAN_REVIEW.
10. **고위험 결정은 사람 승인**: Safety 정책, 개인정보, 법률, 가격/결제, 실거래, production/app-store는 자동 소유 금지.

## Agent별 단일 책임
- **ARI Main Manager**: 전체 Task Queue, 우선순위, 의존성, 승인 Gate, Agent 배정
- **Product Manager**: 사용자/시장 신호를 제품 Task로 변환
- **Engineering Manager**: 개발 Task 분해, 코드 영역 배정, 충돌 방지
- **Coding Agent**: 할당된 코드 범위만 구현
- **Repair Agent**: Verification 실패 원인만 최소 수정
- **Verification Core**: 공통 테스트/분석/빌드 판정. 코드 수정 금지
- **Review Agent**: 변경의 품질/정책/범위 검토. 코드 수정 금지
- **Build Agent**: 승인된 상태에서 test artifact 생성
- **Release Manager**: SERVER_PASS/CI/DEVICE_PASS/RELEASE_APPROVED Gate만 관리
- **Growth Manager**: Acquisition/Activation/Retention 병목 분석과 Growth Task 생성
- **Customer Research Agent**: 리뷰/피드백/이탈 원인 군집화
- **Competitor Agent**: 경쟁사 변화 조사 및 Build/Ignore/Watch 제안
- **Government Grant Agent**: 지원사업 탐색, 적합도, D-30/14/7/3 Task 생성
- **Finance/AI Cost Agent**: 비용/매출/마진/이상치 감시
- **Legal/IP Agent**: 법률·라이선스·IP 리스크 탐지 후 HUMAN_REVIEW 요청

## 중복 방지 Task Key
각 Task는 아래 키를 가진다.

`<project>:<task_type>:<resource_scope>:<goal_hash>`

예:
- `onaria:CODE:backend/src/crisis.js:G1-safety`
- `rami:VERIFY:deeplink:rami-v04`
- `k-stock-ai:VERIFY:kis-adapter:mock-path`

동일 키가 `PENDING|RUNNING|REPAIRING|REVIEWING`이면 새 Task 생성 금지.

## 파일 소유권
Task 시작 시 `resource_scope`를 claim한다. 다른 Agent가 겹치는 scope를 요청하면:
1. 먼저 실행 중인 Task를 기다림
2. 의존 Task로 연결
3. 충돌 없는 범위로 재분할

강제 병렬 수정 금지.

## 상태 전이
`PENDING -> CLAIMED -> RUNNING -> VERIFYING -> REVIEWING -> SERVER_PASS`

실패 시:
`VERIFYING -> REPAIRING -> VERIFYING`

2회 실패 또는 정책 판단:
`-> HUMAN_REVIEW`

## 프로젝트 공통 검증
Verification Core는 하나만 운영하며 프로젝트별 `.ari/verification.yaml`을 읽는다.
- ONARIA: Safety/RAG/Flutter/backend
- RAMI: NFC/deeplink/Flutter
- K-Stock AI: KIS/OpenDART mock, risk hard stop, live trading disabled

## 금지사항
- Manager와 Coding Agent가 같은 Task를 동시에 수정
- Verification Core가 코드 수정
- Review Agent가 수정 후 스스로 승인
- 동일 변경을 Windows와 Mac mini가 같은 branch에서 동시에 수정
- 같은 프로젝트에 중복 QA daemon 생성
- main/master 자동 merge
- production deploy/app-store publish 자동 실행

## 완료 판정
에이전트 구조가 중복되지 않는 상태는 다음을 모두 만족해야 한다.
- 동일 Task Key 동시 실행 0건
- 동일 resource_scope 동시 writer 0건
- Verification Core 인스턴스 1개
- 프로젝트별 검증 로직은 profile로만 분리
- Review와 Repair 책임 분리
- 중복 Task 발견 시 자동 병합/의존 처리
