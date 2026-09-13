# ARI Company OS execution engine

This extends the eleven canonical operating agents in `AGENT_REGISTRY.md`; it does not create per-project QA/Safety/Psychology agents. `config/agents.yaml` is the executable registry, including complete execution contracts and references to existing runtime/specialist owners. `ENGINE_INVENTORY.md` records the registry-first decisions.

## Local operation

Node >=20. `npm ci --ignore-scripts`, then `npm test`.

```sh
export ARI_STATE_ROOT=/Users/server/ari-server/runtime/ari-company-os
node bin/ari-manager.js daemon --dry-run
node bin/ari-manager.js status
node bin/ari-manager.js registry
node bin/ari-manager.js enqueue /path/to/reviewed-task.json
node bin/ari-manager.js event /path/to/reviewed-event.json
```

The task/event CLI is a trusted, local operator interface, not an authenticated public API. No network listener is exposed. Do not put credentials or personal data in task payloads. `approve-development <task-id>` records the local owner's explicit approval for a development task awaiting review. It never grants release approval.

Main Manager runs every 900000ms (15 minutes). Scheduler deadlines and queue-file events wake it immediately, independently of that periodic cycle. The queue watcher uses native events with a 250ms stat fallback. Project scanning defaults to 15000ms; verification starts after a fresh 1200000ms quiet window. Poll/debounce overrides are only for controlled tests. The installed service explicitly restores production-independent local defaults.

Task lifecycle: `PENDING → READY → IN_PROGRESS → VERIFYING → COMPLETED`; exceptions `BLOCKED`, `FAILED`, `HUMAN_REVIEW`, `CANCELLED`. Dependencies require COMPLETED predecessors. Result and followup creation are one queue transaction. Active dedupe includes human-review tasks. Concurrency serializes each project's work even when supplied group names differ. Writer workflows additionally lock the shared Git directory and create task-specific automation worktrees. No cross-host distributed lease is implemented.

## Approved development payload

```json
{
  "type": "DEVELOPMENT",
  "project": "fixture",
  "projectDir": "/path/to/isolated/repository",
  "goal": "Return the expected value",
  "resourceScope": ["src/value.cjs"],
  "acceptanceCriteria": ["The exported value equals 2"],
  "approval": {"approved": true, "by": "owner"},
  "focusedChecks": [{"id":"value", "command":"node", "args":["--test","test/value.test.cjs"]}]
}
```

V1's Codex adapter supports small existing files under explicit `src/`, `lib/`, `backend/src/` allowlists. Runtime agent/policy/security/test/config paths are not automatically writable. New files, broad refactors, dependency provisioning and uncertain scopes terminate in HUMAN_REVIEW. A coding worktree starts from a committed revision; uncommitted source edits are not silently imported. A repair worktree copies only the previous failing scope and preserves that lineage. Worktrees and diffs are retained for review. Automatic coding/repair commits, merges and pushes are not performed by the daemon.

Verification Core owns profile loading, diff/secret checks, analyze/lint, unit, integration/smoke, risk checks, optional debug APK and immutable revision-bound reports. It cannot invoke a repair worker. The existing repair-agent workflow receives eligible FAIL results, has a maximum lineage count of two and requests a separate verification task. `VerificationWorkflow` is a compatibility/integration driver for that separation, not a new agent identity.

Profiles record required capability coverage. Empty mappings stop at HUMAN_REVIEW; successful generic tests do not substitute for missing audio, lifecycle/deep-link, KIS or OpenDART adapter tests. Secret-pattern findings are not automatically allowlisted, even in existing tests.

## Schedules (Asia/Seoul)

| Existing owner/capability | Schedule |
|---|---|
| Main Manager | Every 15 minutes and immediate task events |
| Main Manager daily report | Weekdays 05:00 |
| Finance | Daily 05:20 |
| Customer Research | Monday 05:30 |
| Growth | Monday 06:00 |
| Competitor | Wednesday 05:30 |
| Government Grant | Weekdays 06:00; pre-founder status |
| Verification | Coding handoff immediately, or code quiet for 20 minutes |
| Repair / Release gate / high risk | Immediately on their respective events |

On startup the scheduler catches up only today's due slots. Persistent date/owner keys prevent repeat processing after restart. Older missed days are not fabricated. External data adapters are deliberately unconnected: Finance/Growth/Customer/Competitor/Grant tasks block with DATA_SOURCE_NOT_CONNECTED. Reports label external facts UNVERIFIED. Grant deadline helper supports D-30/14/7/3 and escalates registration eligibility.

## Release evidence

SERVER_PASS → matching GitHub CI PASS → actual matching Test Build → DEVICE_PASS → owner's RELEASE_APPROVED. A local `CI_RESULT`, `TEST_BUILD`, `DEVICE_RESULT` or `RELEASE_APPROVAL` event identifies an existing blocked `releaseTaskId` and supplies `evidence` with matching commit/fingerprint. All evidence remains local and operator-supplied; no CI/device connector is implied. Actual build existence/hash is checked. Stale evidence is HUMAN_REVIEW. Even a fully satisfied gate never executes merge/deploy/publish.

## launchd and validation

`scripts/install-launchd.py --replace-managed` backs up and updates only this managed user service. User LaunchAgent starts at login. A reviewed system plist and `scripts/install-system-launchd.sh` are supplied for an administrator to install login-independent startup; do not run a user and system copy together. No automatic login or system security settings are changed.

Tests: `npm test`; `node scripts/validate-installation.js`; `node scripts/validate-project-watches.js`. The latter creates/removes only uniquely controlled probe files in automation worktrees. Real Codex fixture validation: `node scripts/validate-engine-daemon.js`, or `node scripts/validate-installation.js --codex`. These are isolated fixtures and are never evidence of connected business data. `scripts/verify-projects.js` executes actual registered profiles and may return HUMAN_REVIEW/FAIL.
