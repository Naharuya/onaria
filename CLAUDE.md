# ONARIA

This file is the short agent entrypoint. Detailed operating rules remain in `AGENTS.md`.

## Identity
- Repository: ONARIA
- Default branch: `main`
- Local path: `~/ARI/projects/onaria`
- Production host: `ari-prod-01`
- Production path: `/opt/onaria/backend`

## Required startup
1. Read `AGENTS.md`.
2. Read `.ari/memory/PROJECT_MEMORY.md`.
3. Run `.ari/hooks/preflight.sh`.
4. Open only the skills needed for the current task.

## Hard rules
- Christian-first public product; do not reintroduce hidden multi-religion UI without explicit product decision.
- Production API must use HTTPS and approved ONARIA domains.
- Preserve crisis/safety hard stops and evidence-grounded religious content.
- Do not reset or delete existing user/app data during device updates.
- Production deployment, signing-key changes, store submission, and destructive DB operations require user approval.

## Verification
Run `.ari/hooks/verify.sh` after implementation.
Run `.ari/hooks/release-gate.sh` before any release/deployment preparation.

## Memory discipline
Do not store temporary CI failures, one-off blockers, or current progress in long-term memory.
Put changing status in PRs/issues/logs instead.

## Completion
Report changed files, tests, risks, unresolved approval gates, and next action.
