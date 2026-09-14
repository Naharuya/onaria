# ARI Company OS execution engine

This extends the canonical operating agents in `AGENT_REGISTRY.md`; it does not create per-project QA/Safety/Psychology agents. `config/agents.yaml` is the executable registry. Existing project/runtime agents are reused first.

## Local operation

Node >=20. `npm ci --ignore-scripts`, then `npm test`.

```sh
export ARI_STATE_ROOT=/Users/server/ari-server/runtime/ari-company-os
node bin/ari-manager.js daemon --dry-run
node bin/ari-manager.js status
node bin/ari-manager.js registry
node bin/ari-manager.js dashboard
```

The task/event CLI is a trusted local operator interface. The dashboard is a read-only HTTP listener bound to `127.0.0.1` by default; it has no mutation API and must not be exposed to the public Internet. `approve-development <task-id>` records explicit development approval only and never grants release approval.

Main Manager runs every 900000ms (15 minutes). Scheduler deadlines and queue events wake it immediately. Project scanning defaults to 15000ms; verification starts after a fresh 600000ms (10 minute) quiet window. If source changes again during the quiet window, the timer resets. Coding Agent and Repair completion hand off to Verification immediately without waiting for the quiet window.

Task lifecycle: `PENDING → READY → IN_PROGRESS → VERIFYING → COMPLETED`; exceptions `BLOCKED`, `FAILED`, `HUMAN_REVIEW`, `CANCELLED`. Dependencies require COMPLETED predecessors. Active dedupe includes human-review tasks. Concurrency serializes project work. Writer workflows lock the shared Git directory and use task-specific automation worktrees.

## Local-first AI Router

`src/ai_router.js` is infrastructure, not a new business agent identity.

- Local lane: Ollama at `http://127.0.0.1:11434`, default model from `ARI_LOCAL_AI_MODEL` (fallback `qwen3.5:4b-mlx`).
- Local-first examples: report summarization, classification, customer/competitor/growth/finance/grant analysis when evidence is already available.
- External-first examples: DEVELOPMENT, REPAIR, architecture/security work.
- High-risk safety/privacy/legal/payment/release/live-trading/security scopes never silently route to Local AI; they require external review and/or HUMAN_REVIEW.
- If Local AI fails, optional external escalation is allowed only when an explicit external adapter is configured.
- No API key is stored in telemetry or dashboard data.

Ollama returns `prompt_eval_count` and `eval_count`; those are stored as measured input/output tokens. Codex CLI currently does not expose reliable token counts through this adapter, so its exact call frequency is recorded while tokens are explicitly marked `UNAVAILABLE` rather than estimated.

## AI usage telemetry

`state/ai-usage.jsonl` records one line per AI invocation:

- timestamp
- local/external lane
- provider/model
- agent/task type
- success/failure
- measured input/output/total tokens when available
- token measurement state
- duration
- escalation flag
- externally supplied cost estimate when available

`AiUsageStore.summary()` calculates Local AI rate, external call frequency, measured token totals, token-measurement coverage, escalation count, and per-agent/provider totals. Unknown token usage is never treated as zero.

## Operations dashboard

The daemon starts the dashboard unless `ARI_DASHBOARD_ENABLED=false`.

Default link on the Mac mini:

`http://127.0.0.1:8787/`

Environment options:

- `ARI_DASHBOARD_HOST` default `127.0.0.1`
- `ARI_DASHBOARD_PORT` default `8787`

The UI shows:

- active/completed/HUMAN_REVIEW task counts
- Agent activity
- Local vs External AI call frequency
- Local processing rate
- measured tokens and token coverage
- recorded external cost estimates
- recent tasks and AI calls

It refreshes every 30 seconds. It is read-only. Do not bind it to a public interface without adding authentication and network controls first.

## Coding / repair

The Codex adapter supports small existing files under explicit `src/`, `lib/`, `backend/src/` allowlists. Runtime agent/policy/security/test/config paths are not automatically writable. New files, broad refactors, dependency provisioning and uncertain scopes terminate in HUMAN_REVIEW. Worktrees and diffs are retained for review. Automatic coding/repair commits, merges and pushes are not performed by the daemon.

Codex coding/repair invocation frequency is written to the same AI telemetry store. Because the CLI adapter does not currently provide authoritative token counts, those events have `tokenState=UNAVAILABLE`.

## Verification Core

Verification Core owns profile loading, diff/secret checks, analyze/lint, unit, integration/smoke, risk checks, optional debug APK and revision-bound reports. It cannot invoke a repair worker. Repair has a maximum lineage count of two and requests a separate verification task.

Profiles record required capability coverage. Missing required capability tests stop at HUMAN_REVIEW. Successful generic tests do not substitute for missing audio, lifecycle/deep-link, KIS or OpenDART adapter tests.

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
| Verification | Coding/Repair handoff immediately, or code quiet for 10 minutes |
| Repair / Release gate / high risk | Immediately on their respective events |

External business-data adapters remain deliberately disconnected until a real source is configured. Their tasks return `DATA_SOURCE_NOT_CONNECTED`; reports label unavailable facts `UNVERIFIED`.

## Release evidence

`SERVER_PASS → matching GitHub CI PASS → actual matching Test Build → DEVICE_PASS → owner's RELEASE_APPROVED`.

Evidence is revision-bound. Stale evidence is rejected. Even a fully satisfied gate never executes merge/deploy/publish automatically.

## launchd and validation

`scripts/install-launchd.py --replace-managed` updates only the managed user service. A reviewed system plist and installer exist for login-independent startup; do not run duplicate user/system copies.

Validation:

```sh
npm test
node scripts/validate-installation.js
node scripts/validate-project-watches.js
node scripts/verify-projects.js
```

After deployment verify `quietMs=600000` in daemon status/logs, check `http://127.0.0.1:8787/api/health`, and confirm the dashboard displays real queue data without exposing secrets.
