# Content delivery implementation report
2026-10-31 KST

```yaml
PROJECT: "onaria"
CURRENT COMMIT: "40cd65851553238c426b32f5af2639e76f24f64b"
ISSUE FOUND: "shared user request for local-first content and independent server delivery"
PRIORITY: "P2 performance"
ROOT CAUSE: "actual reported delays NOT CONFIRMED by end-to-end measurements"
IMPLEMENTED: "see docs/CONTENT_DELIVERY_STANDARD.md for this project's exact scope and runtime switches"
CHANGED FILES: "AGENTS.md; docs/CONTENT_DELIVERY_STANDARD.md; this report; project-owned content route/cache/client/tests (see code diff)"
TEST: "backend 11 PASS; Flutter 8 PASS"
ANALYSIS: "changed-code analysis recorded in prior task"
BUILD: "NOT RUN / no new build in this scope"
DEVICE: "NOT RUN — no installation or device update"
API: "local integration PASS; new production content endpoints not deployed"
CI: "NOT RUN — no commit/push"
COMMIT: "NOT RUN"
PUSH: "NOT RUN"
REMAINING RISKS: "staging/production rollout, independent endpoint configuration, live before/after latency and device validation"
NEXT ACTION: "verify builds and stage the project-owned content API, then validate the TEST client against that same app"
```

Implementation and ownership:
- Four apps have their own copy of the content-delivery standard referenced from AGENTS.md.
- Never merge religious catalogs, private member records, credentials or runtime dependencies.
- Keep source/rights/draft status and existing release gates.
- ONARIA changes were implemented and tested in the preceding task; this task adds its common policy reference.
- Buddhist conditional representations require fresh authorization/publication/rights validation. There is no stale offline quote fallback.
- Catholic/Philosophy public caches are in memory. Their existing bundled content remains usable after restart, and public network refresh is opt-in.
- No image/audio/video corpus migration, CDN deployment, database migration, server restart, app store release or production performance claim is included.
- Web compilation uses the TEST channel and --no-wasm-dry-run (JavaScript build); Android compilation is TEST-labelled Debug only, never installed. iOS/release/store builds were not run.
- Full lib/test analysis exits successfully with --no-fatal-infos; pre-existing informational lints remain in inherited sources.
- Verification commands: flutter analyze --no-pub lib test --no-fatal-infos; python3 scripts/build-app-channel.py test web --no-pub --no-wasm-dry-run; python3 scripts/build-app-channel.py test apk --debug --no-pub.
- Buddhist tests: node --test test/content_cache.test.js test/content_publish.test.js test/safety_invariants.test.js (backend); flutter test --no-pub test/published_content_test.dart test/published_content_cache_test.dart.
- Catholic tests: node --test test/public_content_cache.test.js test/daily_draft.test.js (backend); Flutter flow_navigation, flow_session, emotion_end_to_end_matrix, draft_catalog and public_catalog_cache test files.
- Philosophy tests: npm test in backend; flutter test --no-pub at project root.
- The optional Wasm diagnostic in the first Buddhist Web attempt was stopped before the successful JS-only build; it was not a source compile error.
- Baseline user changes were preserved. Philosophy has no initial Git commit; no remote was invented.
- Public health probes from the Mac succeeded for the known ONARIA, Buddhist and maeon hosts. Health-only timing is not chat/content performance proof.
- Read-only probes returned 404 for new ONARIA and maeon content paths, confirming deployment remains outstanding.
