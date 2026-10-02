# Preflight Skill

Use before any code, config, deployment, or document change.

1. Confirm current directory and repository identity.
2. Read CLAUDE.md and AGENTS.md.
3. Run `.ari/hooks/preflight.sh`.
4. Inspect git status and preserve existing dirty work.
5. Confirm target branch, remote, and deployment target.
6. Stop if repo/path/remote do not match expected project identity.
7. Never use destructive reset/stash automatically to make the tree clean.
8. Before designing or changing a feature, read `docs/feature-architecture/README.md`, the relevant feature document, and prior failure/change notes. Do not rely on chat memory as the source of truth.
9. Reuse the BONUI planning traceability chain for every feature: `REQ -> FLOW -> UI -> API -> DB -> TC`. Identify which links already exist before adding code.
10. Benchmark before implementation when UX, platform policy, authentication, privacy, payments, device integration, or a recurring failure is involved. Prefer current official documentation, then trusted expert/community cases; verify version/environment compatibility before applying a fix.
11. For an existing feature, trace from the user-visible end state backward to its entry point, storage, API, and dependencies before modifying it.
12. Define acceptance criteria, error/empty/loading/permission states, privacy/data lifecycle, and rollback/recovery behavior before coding.
13. After implementation, run static/unit/widget/API tests first, then Android/iOS real-device tests where applicable, then regression tests. The user performs final acceptance only after agent/device QA passes.
14. If a test installs a temporary/debug app, restore the verified user-facing Release build afterward and verify version + independent launch.
15. Update the relevant feature architecture and failure history before closing the baseline; commit/push only after tests and secret/diff checks pass.
