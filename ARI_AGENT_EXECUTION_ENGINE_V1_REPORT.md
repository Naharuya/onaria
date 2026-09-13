# ARI Agent Execution Engine v1 Report

최종 상태: **PARTIAL**

기록 시각: 2026-09-14T06:50:21.767056+09:00

실행 엔진·로컬 Trigger·단위/통합 검증은 PASS다. 외부 데이터 연결은 요청한 1차 범위대로 미연결 처리했다. 실제 앱 profile은 아래 사유로 HUMAN_REVIEW이고, 로그인 전 system LaunchDaemon 설치는 Mac 관리자 인증이 없어 미완료다. 이 상태를 회사 전체 자동 운영 또는 release 승인으로 해석하지 않는다.

## 기준과 Inventory

- 저장소: `Naharuya/soul-bible`
- 작업/배포 금지 경계: `automation/server-agent-platform-v0.1`에서만 구현·commit·push. main/master merge, production deploy, 앱마켓 publish, 실제 사용자 데이터 접근, K-Stock 실거래는 수행하지 않는다.
- fetch 후 적용한 기준: `8951fcea60160227c19195a5b1888dd25b0a9136` (Registry v2 및 Ownership Policy 포함).
- 확인 문서: `server/ari-company-os/AGENT_REGISTRY.md`(요청한 Registry의 실제 위치), `AGENT_OWNERSHIP_POLICY.md`, `SERVER_AGENT_AUTOMATION_SPEC.md`, `SERVER_VERIFICATION_CORE_SPEC.md`, OS source/config, 세 `.ari/verification.yaml`, 기존 Runtime Agents와 `.github/agents/`, Issue [#6](https://github.com/Naharuya/soul-bible/issues/6), [#7](https://github.com/Naharuya/soul-bible/issues/7) 및 ownership/registry 댓글.
- 파일별 Inventory와 재사용 판정: `server/ari-company-os/ENGINE_INVENTORY.md`.
- 이전 설치 변경과 상태/launchd 백업: `/Users/server/ari-server/runtime/ari-company-os/backups/engine-v1-20260914-061205/`.

## Registry-first 판정

| 기존 canonical owner | 판정 | 이번 작업 |
|---|---|---|
| ari-main-manager | EXTEND_EXISTING | Registry 배정, Queue 상태/의존성, Scheduler, daily report capability |
| product-manager | EXTEND_EXISTING | 근거 있는 요청 중복 제거, 영향/Risk/우선순위/AC, 승인 전 Development Task |
| coding-agent | EXTEND_EXISTING | 승인 검사, task 전용 worktree, 기존 Codex adapter 재사용, focused test, diff, Verification handoff |
| verification-core | EXTEND_EXISTING | 공통 1개, 코드 수정/repair 호출 분리, secret scan·단계별 profile·coverage·revision 검사 |
| repair-agent | EXTEND_EXISTING | 실패 후 별도 작업/소유권/worktree, lineage 전체 최대 2회, 동일 profile 재검증 요청 |
| release-manager | EXTEND_EXISTING | 실제 Test Build와 commit/fingerprint가 일치하는 Gate |
| growth-agent | EXTEND_EXISTING | 계약/월요일 Scheduler, 미연결 차단 |
| customer-research-agent | EXTEND_EXISTING | 계약/월요일 및 이벤트 Scheduler, 미연결 차단 |
| competitor-agent | EXTEND_EXISTING | 계약/수요일 Scheduler, BUILD은 Product Manager로만 |
| government-grant-agent | EXTEND_EXISTING | 예비창업자 계약/평일 Scheduler, D-30/14/7/3, 사업자등록 영향은 HUMAN_REVIEW |
| finance-agent | EXTEND_EXISTING | 계약/매일 Scheduler, 미연결 차단 |
| ONARIA Runtime Agents 15개 | REUSE_EXISTING | Safety/Psychology/Orchestrator/Router/Integrity/Integrator/Citation 2개/Religion 7개 원본 보존 |
| RAMI Audio Manager | REUSE_EXISTING | `.github/agents/rami-audio-manager.agent.md` canonical specialist; coding capability 공유 |

**NEW_AGENT_REQUIRED: 0. 신규 Agent ID 생성: 0.** 운영 owner 11개와 기존 Runtime/specialist 참조 16개다. qa-agent/test-agent/verification-agent는 공통 verification-core로 resolve한다. 후보의 inputs/outputs/domain/authority/successKpi 중 2개가 겹치면 EXTEND_EXISTING을 제안한다. 미등록 역할은 자동 생성하지 않고 HUMAN_REVIEW로 넘긴다. 기존 K-Stock 제품 내부 분석 모듈도 변경하거나 회사 운영 Agent로 복제하지 않았다.

`config/agents.yaml` v3의 모든 운영 owner에 다음 17개 필드를 정의·검사했다: id, mission, trigger, schedule, inputs, preconditions, procedure, outputs, completionCriteria, nextTasks, retryPolicy, escalationPolicy, approvalRequired, dedupeKey, concurrencyGroup, enabled. RAMI specialist에도 기존 coding 계약을 적용하고 canonical path/identity를 유지했다.

## 구현 범위

1. Persistent Task Queue: PENDING → READY → IN_PROGRESS → VERIFYING → COMPLETED, 예외 BLOCKED/FAILED/HUMAN_REVIEW/CANCELLED. 허용되지 않는 상태 건너뛰기 차단, dependency 완료 전 실행 금지, 활성 dedupeKey 중복 생성 금지. HUMAN_REVIEW도 dedupe 활성 상태에 포함.
2. Queue transaction: PID lock과 원자적 교체. 완료 결과와 후속 Task를 하나의 transaction으로 저장. 기존 상태는 백업 후 schema v3로 이관하며 소유권을 추론한 기록에는 `migration: true` 표시. 이관이 과거 실행을 새 Agent 실행으로 바꾸지는 않는다.
3. Concurrency: 같은 프로젝트는 다른 concurrencyGroup을 주어도 동시 실행 불가. Coding/Repair는 공유 Git 경로 writer lock과 Task UUID별 automation branch/worktree 사용. 현재 Main Manager 실행은 순차 처리한다.
4. Main Manager: queue/dependency → READY → Registry → owner 배정 → 실행 → retry 판단 → VERIFYING → 결과/후속 Task 저장 → HUMAN_REVIEW 분리. 제품 코드를 직접 수정하지 않는다.
5. Coding: owner 승인과 AC 확인 → 격리 worktree → 허용된 기존 소스 파일 최소 수정 → focused test → diff 저장 → 별도 verification-core Task. 원본 미커밋 변경을 자동 복사하지 않는다. 현재 adapter는 명시적 allowlist의 작은 기존 src/lib/backend/src 파일에 한정된다.
6. Verification: profile → git diff/check → secret scan → lint/analyze → unit → integration/smoke → 프로젝트 risk → 가능한 test build → 결과. 코드/테스트를 수정하지 않고 repair worker를 호출하지 않는다. 시작/종료 fingerprint 비교로 변경 중 검증 PASS를 차단한다.
7. Repair: 자동수정 가능한 FAIL에서 별도 repair-agent Task 생성. 동일 lineage 최대 2회, 매번 다른 격리 worktree, 수정 후 같은 profile을 독립 Verification에 전달. Safety/개인정보/법률/라이선스/가격/결제/production/마켓/실거래/secrets 관련 scope/failure는 HUMAN_REVIEW.
8. Diagnostics: command 종료 코드·bounded redacted stdout/stderr, task별 JSON, scoped diff 저장. credential 모양/민감 필드가 있는 출력 줄은 제거한다. Codex 원시 출력은 보관하지 않는다.
9. Product Manager: 실제 입력 후보의 문제/사용자 영향/사업 영향/Risk/AC/scope가 있어야 Development Task 생성. 일일 임의 기능 생성 없음. 데이터 부족은 DATA_INSUFFICIENT.
10. Business agents: 계약·스케줄만 실행 가능하며 연결되지 않은 데이터는 DATA_SOURCE_NOT_CONNECTED/BLOCKED. 수익/비용/경쟁사/지원금 지표를 만들어내지 않는다.
11. Release: SERVER_PASS → GitHub CI PASS → 존재/hash가 맞는 Test Build → DEVICE_PASS → owner RELEASE_APPROVED. 모든 evidence가 commit/fingerprint와 일치해야 한다. Gate 결과만 저장하며 merge/deploy/publish handler는 없다.
12. Daily report: 오늘 완료/진행 중/repair/test/유효한 SERVER_PASS/문제·Risk/다음 Task/owner 결정. 비용과 공고 등 미확인 값은 UNVERIFIED. 오래된 PASS fingerprint를 현재 PASS로 표시하지 않는다.
13. GitHub CI: OS 전용 workflow 추가, 프로젝트·브랜치 concurrency와 cancel-in-progress, SHA별 artifact 이름. 기존 backend/web CI에도 branch별 concurrency 추가. 제품 runtime 코드/테스트는 수정하지 않았다.
14. K-Stock: live trading true 즉시 HUMAN_REVIEW; 자식 환경은 false. mock Node 실행에 standard HTTP/HTTPS/net/tls/DNS/fetch 외부 요청 차단 guard 적용. 이는 OS 전체 네트워크 sandbox나 임의 악성 프로그램 방어를 보증하지 않는다.

## 실제 Trigger 및 KST 스케줄

| Owner/capability | Trigger |
|---|---|
| Main Manager | 기본 900000ms = 15분. queue-file event 시 즉시 추가 cycle |
| 업무보고 | 평일 05:00 KST |
| Finance | 매일 05:20 KST |
| Customer Research | 월요일 05:30 및 Beta/Support/Review/Churn 이벤트 |
| Growth | 월요일 06:00 KST |
| Competitor | 수요일 05:30 KST |
| Government Grant | 평일 06:00 KST; 예비창업자 상태 |
| Verification | Coding handoff 즉시 또는 마지막 감지 변경 후 quiet 1200000ms |
| Repair | eligible FAIL 후 즉시 후속 Task |
| Release Manager | SERVER_PASS 후 즉시 Gate Task |
| 고위험 이벤트 | 다음 cycle을 기다리지 않고 HUMAN_REVIEW Task를 즉시 영속화 |

프로젝트 watcher는 별도 15000ms poll이다. 15분 Manager poll과 20분 debounce를 혼동하지 않는다. native file watch 제한 시 queue 변경 감지는 250ms stat fallback을 사용한다. Scheduler 재시작 시 오늘의 지난 slot만 catch-up하고, 영속 날짜/owner key로 중복을 차단한다. 매일/매주 스케줄은 fake clock 단위 테스트로 경계 시각·요일을 검증했으며 실제 일주일을 기다린 결과가 아니다.

## 테스트 및 실제 통합 결과

```text
ℹ tests 51
ℹ suites 0
ℹ pass 51
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 2964.523084
```

기존 테스트를 삭제하거나 skip하지 않았다. 기존 repair 동작 테스트는 새 Repair workflow를 대상으로 같은 assertion을 유지했고, release 테스트에는 필수 Test Build 입력을 추가했다. 새로운 독립성/빌드 누락 테스트를 별도로 추가했다.

검증 항목: dedupe/restart, Registry alias/중복 후보, dependency 성공/실패 차단, 상태 전이, cancellation/미래 Task, 20분 기본값·repeated edit debounce, repair 2회, main/master 차단, Verification writer 호출 0, secret redaction, K-Stock live/외부 요청 차단, 즉시 HUMAN_REVIEW, KST schedule, project concurrency, worktree isolation, stale report/evidence, 실제 Build 존재, release evidence 재개, legacy migration, 결과+후속 Task transaction.

- 실제 Codex Coding daemon integration: **SERVER_PASS**. Main Manager poll=900000ms에서도 배정 약 **115ms**. 승인 Task → CODED → 독립 SERVER_PASS → WAITING_GITHUB_CI. 원본 fixture 파일 보존.
- 실제 Codex Repair integration: **SERVER_PASS**, 1회 수정 후 같은 검사 성공. 가짜 provider가 아닌 설치된 Codex CLI 호출. 대상은 실제 사용자 데이터 없는 임시 fixture다.
- 세 fixture: 변경 → debounce → Verification Task → SERVER_PASS 확인. 실제 제품 성공으로 해석하지 않는다.
- 세 실제 automation 작업 트리: 임시 probe로 변경 → 600ms debounce → 각 Task 생성 확인, probe 정리. 테스트 override는 상시 launchd에 적용하지 않는다.
- Dry-run: 11 계약 로드, 세 profile VALID, 15분/15초/20분 설정 확인.
- GitHub CI: **BLOCKED_BILLING — job did not start; tests NOT RUN**. 검증 code commit: `19d70b848212929e0c8038172527a6afc5750e75`. 실행 링크: https://github.com/Naharuya/soul-bible/actions/runs/34784920803.

## 실제 프로젝트 profile 결과

| 프로젝트 | 실제 대상/HEAD | 결과 |
|---|---|---|
| ONARIA | `/Users/server/ari-company-os-worktree`, `8951fce` 기준 로컬 구현 | HUMAN_REVIEW: secret scan에서 기존 test fixture 파일 2개의 credential 형태 문자열 감지 |
| RAMI | `/Users/server/ari-company-os-projects/rami`, `1b2e462` | analyze/test/NDEF·invalid parser PASS. initial/warm deep link·duplicate·audio 회귀 coverage 부족으로 HUMAN_REVIEW |
| K-Stock AI | `/Users/server/ari-company-os-projects/k-stock-ai`, `33d380a` | npm test/mock smoke/risk hard stop PASS. KIS/OpenDART adapter mock/stub coverage 부족으로 HUMAN_REVIEW |

ONARIA 검출 경로는 `backend/test/cost_preflight.test.js`, `test/safety_parity_test.dart`다. 해당 테스트는 mock/preflight/error-leak 검증에 문자열을 사용하지만, 이번 작업에서 secret 정책 예외를 자동 추가하지 않았다. 값은 출력·보고서에 포함하지 않았다. 새 pipeline은 여기서 멈췄으므로 이번 실행의 analyze·backend·APK 단계는 NOT RUN이다. 이전 설치 검증의 `example/main.dart` avoid_print 4건은 해결하지 않았으며 별도 기존 리스크다.

ONARIA profile은 기존 Safety/downstream 0·Psychology·Bible RAG/Citation 테스트와 debug APK를 명시한다. RAMI/K-Stock은 존재하지 않는 위험 테스트를 generic test PASS로 대체하지 않는다. profile 사본은 `server/ari-company-os/config/profiles/`에 저장했다. RAMI/K-Stock 다른 저장소의 profile은 로컬 automation worktree에만 설치했으며 해당 저장소에 commit/push하지 않았다.

## 실제 생성 Task 예제

오늘 startup catch-up으로 생성된 실제 Task다. 외부 데이터가 분석되었다는 뜻이 아니다.

| ID | Type | Status | Owner | Result |
|---|---|---|---|---|
| `task-6dd6b6cb-8901-4d53-be78-b06561a14b4d` | DAILY_REPORT | COMPLETED | ari-main-manager | REPORT_CREATED |
| `task-3c767c06-6d23-4eb4-932e-e2f9a96979d4` | GROWTH | BLOCKED | growth-agent | DATA_SOURCE_NOT_CONNECTED |
| `task-312abef2-08d5-4caa-b8e9-ae20ffb7491d` | CUSTOMER_RESEARCH | BLOCKED | customer-research-agent | DATA_SOURCE_NOT_CONNECTED |
| `task-2c8e58fd-8440-4647-bf20-e87ee16d617d` | GOVERNMENT_GRANT | BLOCKED | government-grant-agent | DATA_SOURCE_NOT_CONNECTED |
| `task-79751b2a-c8ae-4784-874e-58e4e2382129` | FINANCE | BLOCKED | finance-agent | DATA_SOURCE_NOT_CONNECTED |

실제 Codex fixture의 development/high-risk/verification/release Task 상태 이력은 `real-codex-daemon.json`에 있다. Scheduler/업무보고는 로컬 파일만 생성하며 Slack/email/댓글을 전송하지 않았다.

## launchd 및 운영 경로

```text
state = running
ARI_WATCH_POLL_INTERVAL_MS => 15000
ARI_POLL_INTERVAL_MS => 900000
KSTOCK_LIVE_TRADING_ENABLED => false
ARI_QUIET_WINDOW_MS => 1200000
runs = 3
pid = 62027
last exit code = 0
state = active
state = active
properties = keepalive | runatload | inferred program
```

- 실행 서비스: `gui/501/com.ari.company-os` (사용자 LaunchAgent).
- plist: `/Users/server/Library/LaunchAgents/com.ari.company-os.plist`.
- Node: `/opt/homebrew/bin/node` (v24.20.0), macOS 26.6.2.
- 실행 코드: `/Users/server/ari-company-os-worktree/server/ari-company-os`.
- Queue/lock: `/Users/server/ari-server/runtime/ari-company-os/state/`.
- 로그: `/Users/server/ari-server/logs/ari-company-os/manager.log`, `manager.err.log`, `launchd.stdout.log`, `launchd.stderr.log`.
- task/daily 보고서: `/Users/server/ari-server/runtime/ari-company-os/reports/`.
- 이번 증거 자료: `/Users/server/ari-server/runtime/ari-company-os/evidence/engine-v1/`.
- 정상 재시작, 이전 설치의 idle 강제 종료 자동 복구, PID lock 중복 차단을 확인했다. 실제 전원 재부팅과 실행 중 자식프로세스 강제 종료 복구는 NOT RUN.

사용자 LaunchAgent는 **로그인 후 시작**한다. 로그인 전 부팅 자동 시작을 위한 system plist `server/ari-company-os/launchd/com.ari.company-os.system.plist`와 설치 스크립트 `scripts/install-system-launchd.sh`를 준비하고 plist 문법을 검증했다. `sudo -n true`는 `a password is required`로 실패했으므로 system 서비스는 설치하지 않았다. 자동 승인 심사가 거절한 것이 아니라 로컬 sudo 인증이 없는 상태다. 비밀번호를 수집/저장하거나 자동 로그인 설정을 바꾸지 않았다.

관리자가 파일을 검토한 뒤 Mac 로컬 터미널에서 다음 명령으로 설치할 수 있다. 스크립트는 기존 system plist가 있으면 보존하고 중단하며, 설치 시 같은 user 서비스만 내린다.

```sh
sudo /bin/bash /Users/server/ari-company-os-worktree/server/ari-company-os/scripts/install-system-launchd.sh
```

## Commit / Push 및 보존

기존 main/master 작업 트리와 미커밋 사용자 파일은 보존했다. 작업 브랜치의 이전 설치 결과까지 포함한 실행 엔진 code commit `19d70b848212929e0c8038172527a6afc5750e75`를 지정 브랜치로 push 완료했다. 이 보고서의 CI/운영 결과 갱신은 별도 문서 commit으로 push한다. 보고서 전용 후속 commit은 검증한 code commit과 구분한다. 이번 작업에서 실제 앱/repair workflow 자체가 사용자 코드 commit/merge/push를 자동 수행하도록 만들지는 않았다.

## 남은 Risk / 다음 단계

GitHub Actions는 계정 billing 잠금 때문에 job 자체가 시작하지 못했다. 원격 테스트는 NOT RUN이며 로컬 테스트 통과와 구분한다. 계정 상태 복구 후 같은 code commit의 CI 재실행이 필요하다.

1. 로컬 관리자 인증으로 system LaunchDaemon 설치 후 로그인 전 부팅을 실제 검증해야 한다. 현재 충족 범위는 로그인 시 자동 시작이다.
2. ONARIA의 기존 credential 형태 test marker를 사람이 확인해야 한다. 자동 allowlist나 Safety/테스트 기준 완화는 하지 않았다. 이후 기존 analyze 4건과 profile/APK 전체 재검증이 필요하다.
3. RAMI의 initial/warm/de-dup/audio 테스트와 K-Stock KIS/OpenDART adapter tests를 실제 canonical 코드에 연결해야 한다. 새 QA/Audio/Safety Agent 생성으로 해결하지 않는다.
4. Customer/Growth/Competitor/Grant/Finance 실제 소스와 접근 범위를 별도로 연결해야 한다. 현재 외부 데이터 결과는 없음. DATA_SOURCE_NOT_CONNECTED를 성공 지표로 해석하지 않는다.
5. Coding v1은 작고 명시적인 기존 파일 수정만 지원한다. 새 파일/복잡한 build 환경/종속성 구성/다중 언어의 광범위 수정은 HUMAN_REVIEW다. 자동 repair는 실제 앱 profile에서 아직 모두 비활성화되어 있다.
6. 로컬 Queue/이벤트/승인 파일은 신뢰된 운영자 인터페이스다. 공개 API 인증, 분산 lease, Windows와 Mac 간 전역 lock, hostile test의 완전 OS sandbox는 이번 범위에 구현하지 않았다. task 전용 branch/worktree와 CI concurrency는 각각 로컬/CI 경계의 충돌을 줄인다.
7. 실제 GitHub 제품 CI·Test Build·DEVICE_PASS·지니 RELEASE_APPROVED를 확보하지 않았다. Engine CI 통과는 제품 release 승인이 아니다.
8. Main Manager는 하나로 운용하고, sourceDir 원본의 변경은 메타데이터 감시 후 HUMAN_REVIEW로 넘긴다. 원본 main/master 미커밋 내용을 검증 worktree에 자동 동기화하지 않는다.
