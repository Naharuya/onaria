# ARI Autonomous Company OS v1.0 — Mac mini 설치·검증 보고서

최종 판정: **HUMAN_REVIEW**

- 기록 시각: 2026-09-14T05:50:34.128490+09:00
- 요청: https://github.com/Naharuya/soul-bible/issues/7
- 설치 대상 브랜치: `automation/server-agent-platform-v0.1`
- fetch/checkout한 HEAD: `ae039988684369f73e70fd2560c88969a30f088a`
- OS 설치·엔진 검증: **SERVER_PASS**. ONARIA 앱 프로필: **FAIL**. 아래 미해결 항목 때문에 Issue 전체를 완료/PASS로 처리하지 않는다.
- main/master 직접 수정, 자동 merge, production 배포, 앱마켓 등록, 실거래, 실제 사용자 데이터 접근, secrets 출력은 수행하지 않았다.

## 설치 위치와 보존 범위

| 항목 | 실제 경로/값 |
|---|---|
| OS 소스 | `/Users/server/ari-company-os-worktree/server/ari-company-os` |
| Node | `/opt/homebrew/bin/node`, v24.20.0 |
| macOS | 26.6.2 (25G83), ARM Mac mini |
| 런타임 | `/Users/server/ari-server/runtime/ari-company-os` |
| 영속 queue | `/Users/server/ari-server/runtime/ari-company-os/state/tasks.json` |
| PID lock | `/Users/server/ari-server/runtime/ari-company-os/state/daemon.lock` |
| 재시작용 변경 감지 상태 | `/Users/server/ari-server/runtime/ari-company-os/state/watcher.json` |
| LaunchAgent | `/Users/server/Library/LaunchAgents/com.ari.company-os.plist` |
| 증거 자료 | `/Users/server/ari-server/runtime/ari-company-os/evidence/` |

기존 ONARIA main(`e58a0a8`), RAMI main(`1b2e462`), K-Stock master(`33d380a`) 작업 트리는 보존했다. 원본 ONARIA의 미커밋 5개 항목, K-Stock의 미커밋 21개 항목(전체 파일 집계), RAMI의 clean 상태를 최종 관리 검사에서 확인했다. 관리 저장소의 기존 변경도 유지했다. 원본 미커밋 코드를 새 작업 트리에 복사하지 않았다.

실제 프로젝트의 commit/push 또는 GitHub Issue 댓글/상태 변경은 하지 않았다. 자동화 브랜치 변경과 보고서는 로컬 미커밋 상태다. 회귀 테스트의 임시 Git 저장소에는 fixture 초기화용 commit만 있다.

## 프로젝트 registry 및 프로필

기존 registry는 Git clone 상위 폴더를 가리켰고, 실제 세 원본 `source/.ari/verification.yaml`은 모두 없었다. 원본 main/master에 파일을 추가하지 않고 아래 automation 작업 트리에 프로필을 구성했다.

| 프로젝트 | 코드 검증·수정 대상 | HEAD | 프로필 |
|---|---|---|---|
| ONARIA | `/Users/server/ari-company-os-worktree` | `ae03998` | `.ari/verification.yaml` VALID |
| RAMI | `/Users/server/ari-company-os-projects/rami` | `1b2e462` | `.ari/verification.yaml` VALID |
| K-Stock AI | `/Users/server/ari-company-os-projects/k-stock-ai` | `33d380a` | `.ari/verification.yaml` VALID |

RAMI/K-Stock 작업 트리 브랜치는 `automation/ari-company-os-validation`이다. 이들의 프로필 사본은 OS의 `config/profiles/`에도 보관했다.

`config/projects.yaml`의 `dir`는 검증 작업 트리, `sourceDir`는 `/Users/server/ari-server/projects/<project>/source` 원본을 가리킨다. 세 검증 작업 트리는 코드 내용 해시로 감시하며, 세 원본은 파일명·크기·mtime·ctime 메타데이터만 감시한다. 원본 변경 시 코드 내용을 읽거나 복사하지 않고 `source_changed_requires_worktree_sync_review` HUMAN_REVIEW 작업을 만든다. 따라서 원본 미커밋 코드가 검증되었다고 간주하면 안 된다. 원본에서 검증 작업 트리로의 자동 동기화는 없다.

ONARIA의 기존 profile에 있던 shell 문자열 명령을 `id`, `command`, `args`, `cwd`로 명확히 분리했다. Safety 검사는 실제 존재하는 `test/safety_invariants.test.js`를 실행하며, 기존 `allow_no_match`를 사용하지 않는다. 빈/잘못된 profile은 PASS가 아니라 HUMAN_REVIEW다. profile의 build 항목은 수동 단계이며 이번에는 APK를 생성하지 않았다.

## 구현·수정 사항

- 반복 편집에도 감지되는 watcher, 마지막 변경 기준 quiet window, 재시작 중 변경을 찾는 영속 fingerprint. 검증이 생성한 evaluation/results 및 .ari/reports는 감시에서 제외하여 자기 재실행 순환을 방지한다.
- 기본 quiet window 1,200,000ms(20분), poll 15,000ms. 테스트용 400/600ms 값은 격리 프로세스에만 적용.
- 독립 런타임 상태, PID 중복 실행 방지, 죽은 PID lock 복구, 중단된 IN_PROGRESS 작업의 HUMAN_REVIEW 전환.
- queue 원자적 파일 교체와 쓰기 lock. lock 충돌은 실패로 차단하며 무한 재시도하지 않는다.
- profile 유효성 검사, 현재 Git 브랜치 재확인, command 실행 오류/timeout 처리, 출력 대신 종료 코드·사유 저장.
- repair 작업 전체에서 최대 2회. 수정 후 앞서 통과한 검사까지 전체 profile을 다시 실행.
- 안전/보안/법률/개인정보/실거래/배포/종교/Safety 관련 검사 실패는 HUMAN_REVIEW. 현재 앱 프로필은 모두 `repairable: false`이며, 민감한 backend/Safety/RAG/K-Stock 검사는 `humanReviewOnFail: true`다.
- Codex adapter는 `codex exec --ignore-user-config --ephemeral --sandbox read-only`와 JSON schema로 수정안을 받는다. 명시적인 `repairFiles` allowlist의 작은 `src/` 일반 파일만 적용하고, 테스트/정책/설정/인증 관련 경로·경로 이탈·동시 편집은 차단한다. CLI 실패/timeout/불명확한 결과는 HUMAN_REVIEW다. Codex 원시 출력은 저장하지 않는다.
- adapter 연결은 launchd에서 활성화했지만, 실제 앱 자동 repair에는 profile의 명시적 허용과 파일 allowlist가 추가로 필요하다. 현재 실제 앱 코드 자동수정은 하지 않는다.
- 검증 자식 프로세스에 `KSTOCK_LIVE_TRADING_ENABLED=false`를 강제하고, K-Stock profile은 `KSTOCK_AI_MODE=mock`으로 실행한다.
- manager 로그는 파일당 5MiB 기준으로 `.1` 한 개를 유지한다. launchd stdout/stderr는 bootstrap 오류용 별도 파일이다.

## 실제 실행 결과

| 검증 | 결과 | 근거 |
|---|---|---|
| OS npm install | PASS | YAML 의존성 설치, lockfile 생성, 최초 audit 0 vulnerabilities |
| OS npm test | PASS | 19 tests, 19 pass, 0 fail, 0 skipped |
| daemon dry-run | SERVER_PASS | 세 profile VALID, 세 automation 브랜치 확인, quietMs=1200000 |
| 세 fixture 변경→debounce→task→검증 | SERVER_PASS | 각 1개 task COMPLETED, 반복 변경 후 마지막 quiet window 적용 |
| 세 실제 검증 작업 트리 변경→debounce→task | SERVER_PASS | 임시 `.ari/installation-probe.js`로 검증, 600ms 이후 각 1개 PENDING 생성; `--enqueue-only`, probe 정리 완료 |
| 실제 Codex repair→reverify | SERVER_PASS | 격리 fixture `src/value.cjs` 값 1→2, 최초 exit 1, 1회 수정 후 동일 검사 exit 0 |
| FAIL 상태 | 확인 | nonrepairable fixture 실패 및 실제 ONARIA analyze 실패 |
| HUMAN_REVIEW 상태 | 확인 | 민감 실패·실제 브랜치 불일치·빈 profile·2회 repair 한도 tests |
| 정상 서비스 재시작 | PASS | launchctl kickstart -k 후 새 PID, running |
| 비정상 종료 자동 복구 | PASS | 전용 ARI daemon SIGKILL 후 KeepAlive 재시작, runs=3 및 Killed:9 증거 |
| 중복 실행 방지 | PASS | 동일 ARI_STATE_ROOT의 두 번째 daemon exit 1, daemon_already_running |
| 실제 Mac 전원 재부팅 | NOT RUN | 사용자 세션/다른 서비스를 중단하지 않았다. bootstrap/재시작과 구분 |
| 관리 구조 검사 | PASS | validate-structure.sh, project-status.sh exit 0 |
| diff 공백 검사 | PASS | git diff --check |

실제 Codex 호출 결과는 `fixture-validation.json`, 최종 엔진 fixture는 `fixture-final.json`, 실제 작업 트리 감시 결과는 `actual-project-watches.json`, 테스트는 `npm-test.txt`, dry-run은 `daemon-dry-run.json`에 기록했다.

## 앱별 profile 실행 결과

실제 프로젝트 테스트는 격리된 위 HEAD에서 실행했으며 원본 미커밋 코드, production, 사용자 DB는 포함하지 않는다. backend/npm 의존성을 설치했고 Flutter는 기존 캐시로 `pub get --offline`을 수행했다.

| 프로젝트 | 실행한 검사 | 결과 |
|---|---|---|
| ONARIA | git diff --check, backend npm test, Safety regression, RAG retrieval, flutter test | 모두 PASS |
| ONARIA | flutter analyze | **FAIL**, exit 1 |
| RAMI | git diff --check, flutter test, flutter analyze | **SERVER_PASS** |
| K-Stock AI | git diff --check, npm test, npm run smoke (mock) | **SERVER_PASS** |

ONARIA 실패는 `example/main.dart:23:5`, `42:5`, `43:36`, `44:5`의 `avoid_print` 정보 수준 진단 4건이다. 기존 `flutter analyze` 기준을 그대로 유지했다. `--no-fatal-infos` 추가, 테스트 삭제/skip/기준 완화는 하지 않았다. 이 설치 작업에서 예제 앱 코드까지 수정하지 않았다. 앱 profile 상세 종료 코드는 `project-verification.json`에 있다.

RAG 검증이 만든 추적 결과 파일은 evidence의 `onaria-expert-review.json`으로 보관하고 새 작업 트리의 해당 파일을 실행 전 HEAD 내용으로 복원했다. 원본 사용자 변경을 복원/삭제한 것이 아니다.

## release gate

| 입력(server, CI, device, approval) | 결과 |
|---|---|
| true, false, false, false | NOT_READY |
| true, true, false, false | WAITING_DEVICE_PASS |
| true, true, true, false | WAITING_RELEASE_APPROVAL |
| true, true, true, true | RELEASE_APPROVED (정책 함수 값만 확인) |

마지막 행은 합성 boolean 입력 테스트이며 실제 DEVICE_PASS나 사용자 release 승인을 얻었다는 뜻이 아니다. SERVER_PASS만으로 release할 수 없고, 이 OS에는 배포/마켓 publish를 실행하는 task handler를 추가하지 않았다. 실제 CI 확인·기기 테스트·서명·release·배포는 NOT RUN이다.

## 최종 launchd 상태 및 로그

```text
state = running
ARI_POLL_INTERVAL_MS => 15000
KSTOCK_LIVE_TRADING_ENABLED => false
ARI_QUIET_WINDOW_MS => 1200000
runs = 5
pid = 1814
last exit code = 0
state = active
state = active
properties = keepalive | runatload | inferred program
```

- `RunAtLoad=true`, `KeepAlive=true`, `ThrottleInterval=10`, `ExitTimeOut=30`.
- 사용자 `gui/501` LaunchAgent다. 해당 사용자 로그인 때 시작하며, 로그인 전 무인 부팅용 system LaunchDaemon은 아니다.
- 일반 로그: `/Users/server/ari-server/logs/ari-company-os/manager.log`
- 오류 로그: `/Users/server/ari-server/logs/ari-company-os/manager.err.log`
- launchd 로그: `/Users/server/ari-server/logs/ari-company-os/launchd.stdout.log`, `launchd.stderr.log`
- 현재 실행 확인: `launchctl print gui/501/com.ari.company-os`
- 실제 queue 확인: OS 폴더에서 `ARI_STATE_ROOT=/Users/server/ari-server/runtime/ari-company-os node bin/ari-manager.js status`
- 재현 스크립트: `scripts/install-launchd.py`, `validate-installation.js`, `validate-project-watches.js`, `verify-projects.js`. fixture/live Codex 검증은 `node scripts/validate-installation.js --codex`.

## 남은 리스크와 사람 판단

1. ONARIA `flutter analyze` 4건 해결 및 동일 profile 재검증이 필요하다. 현재 ONARIA를 SERVER_PASS로 사용할 수 없다.
2. 원본 main/master의 미커밋 변경을 어느 automation 브랜치에 옮길지는 별도 검토가 필요하다. 원본 변경 감시 task는 HUMAN_REVIEW로 차단한다.
3. 실제 앱 repair 허용 범위/파일 allowlist는 아직 열지 않았다. fixture에서 adapter를 검증한 사실이 모든 실제 앱 오류를 안전하게 자동수정함을 보증하지 않는다. 변경 의미에 대한 독립 리뷰가 여전히 필요하다.
4. 실제 전원 재부팅, 로그인 전 자동 시작, 검증 subprocess 실행 중 강제 종료 복구, 장시간 부하·장기간 로그 운영은 NOT RUN이다. 강제 종료 복구는 daemon이 idle일 때 검증했다.
5. queue 잠금 경합은 안전하게 오류를 반환하지만 자동 재시도/대규모 병렬 작업 처리는 이번 검증 범위 밖이다. 현재 daemon은 순차 실행한다.
6. 20분 설정은 코드/실제 launchd 환경에서 확인했고 debounce 동작은 짧은 환경변수로 검증했다. 실제 20분을 기다리는 실시간 타이밍 검사는 하지 않았다.
7. 실제 GitHub CI, DEVICE_PASS, RELEASE_APPROVED는 확보하지 않았다. production 배포/마켓 등록/실거래는 요청 범위에서 계속 금지다.

설치와 엔진 검증은 완료했지만 위 앱 실패·미검증 항목이 남아 최종 상태를 **HUMAN_REVIEW**로 기록한다.
