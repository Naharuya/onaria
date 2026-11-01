# ONARIA content delivery, 2026-10-31

Status: PARTIAL — local implementation verified; production and device rollout pending.

## Implemented
- GET /v1/content/verses serves the existing bundled Korean/English verse corpus, preserving attribution.
- Corpus lives in backend/src/public_verses.json, included by existing Docker COPY src.
- SHA-256 ETag, conditional 304, public max-age=300 and stale-while-revalidate=86400.
- Endpoint contains only already-public content and does not call AI, read member data or access private storage.
- Existing /v1 account/chat/admin no-store behavior is preserved.
- Flutter displays bundled content without waiting for network/preferences. It restores public content from local storage and refreshes asynchronously with a five-second timeout.
- Refresh is coalesced and limited to once per five minutes per app process. Errors retain local content. Server content must match schema, attribution, translation and bundled verse IDs.
- Existing VerseRepository keeps its current in-memory snapshot; refreshed content becomes visible when a new repository loads. No live update during an active conversation.
- Successful non-crisis AI generation returns Server-Timing: generation;dur=... (milliseconds). No conversation text or identity is added to logging.
- Fixed examples already run locally. Dynamic personal AI answers remain generated; they are never added to the public corpus/cache.

## Verification
- Baseline feedback tests: 2 PASS before changes.
- Feedback/account-deletion/answer-example regression: 10 PASS.
- Public content integration: 1 PASS (corpus parity, 304, account no-store, zero AI calls).
- Flutter verse rotation/speech lifecycle/conversation continuation: 8 PASS.
- Flutter analysis of changed loader: no issues.
- git diff --check: PASS.

## Deployment and remaining work
- No commit, push, production restart, database migration, package build or device install executed.
- Actual delay root cause is NOT CONFIRMED. No before/after live latency measurements yet.
- This is an ONARIA implementation only. Other independent projects were not changed.
- Images/audio/video hosting and CDN changes were not made; inventory and measurement still required.
- Personalized practices were not converted into a reviewed server catalog.
- Full Flutter analysis, release builds, CI, loader-specific failure/invalidation tests, staging and real-device QA remain.
- Public-content edits must update the bundled corpus and backend corpus together; parity test enforces this.
- Serve from the approved Gabia ONARIA backend while retaining the existing HTTPS API hostname. Verify live hosting identity before deployment.
- On staging verify content 200/304, provenance, no-store on personal endpoints, offline start, cache restore and malformed response fallback.
- Compare first screen, content retrieval and AI generation durations separately over Wi-Fi and cellular.
- Roll back app loader to bundled-only and backend to prior artifact if regression occurs. No DB change needed.

PROJECT: ONARIA
CURRENT COMMIT: 40cd65851553238c426b32f5af2639e76f24f64b
ISSUE FOUND: user reports delays on internal and external networks
PRIORITY: P2 performance
ROOT CAUSE: NOT CONFIRMED
IMPLEMENTED: public verse API, local-first refresh/cache, generation timing
CHANGED FILES: backend/src/app.js; backend/src/public_content.js; backend/src/public_verses.json; backend/test/public_content.test.js; lib/app/asset_loader.dart; this report
TEST: backend 11 PASS; Flutter 8 PASS; changed-loader analysis PASS
BUILD: NOT RUN
DEVICE: NOT RUN
API: local test PASS; production NOT RUN
CI: NOT RUN
COMMIT: NOT RUN
PUSH: NOT RUN
REMAINING RISKS: deployment, device cache edge cases, live latency, remaining content types
NEXT ACTION: loader-specific QA, release builds, identify Gabia target and verify staging before rollout
