# Google Play Policy Release Gate — 2026-09-21

Status: PRE-RELEASE / HUMAN APPROVAL REQUIRED FOR PLAY CONSOLE SUBMISSION

## P0 automated engineering gates
- [ ] Verify Android target API >= 36 for every Play submission after 2026-08-31.
- [ ] Add an in-app reporting/flagging path for AI-generated responses.
- [ ] Test crisis/safety routing and prohibited-content handling.
- [ ] Audit Android permissions; retain only permissions used by shipped features.
- [ ] Verify HTTPS-only production API and third-party AI data disclosure.
- [ ] Verify account deletion implementation if in-app account creation ships.

## Deferred / excluded from current automatic work
- Business/operator identity, contact details, retention periods and other final operating information.
- Play Console form submission, store submission, rollout and public release.

## P0 Play Console / policy declarations (prepare only; do not submit)
- [ ] Complete Health apps declaration. ONARIA includes emotion/stress/mental-wellbeing features; declaration must match shipped behavior.
- [ ] Complete Data safety form based on actual collection, sharing, retention, deletion, microphone, and AI-provider flows.
- [ ] Confirm content rating questionnaire.
- [ ] Provide production privacy-policy URL.
- [ ] If account creation ships, provide both in-app deletion path and external web deletion URL.

## Current repository findings
- Android applicationId is currently `com.example.bible_mind_core`. Production ID must be approved before store release because changing it after publication creates a different app identity.
- Android manifest currently requests RECORD_AUDIO, INTERNET, RECEIVE_BOOT_COMPLETED, BLUETOOTH (<=30), BLUETOOTH_ADMIN (<=30), and BLUETOOTH_CONNECT. Bluetooth permissions require a shipped-feature justification or removal.
- Website privacy/terms pages explicitly describe themselves as pre-release notices and must be finalized before public store submission.
- ONARIA already states that it does not replace medical diagnosis/treatment or professional counseling; preserve this positioning.
- Production backend/API uses HTTPS. Keep plaintext development exceptions out of release builds.

## Human approval gates
1. Final operating/legal information is deferred by user instruction.
2. Play Console submission and public release are deferred by user instruction.

## applicationId analysis
- `applicationId` itself is REQUIRED; deleting the property without a replacement is not a valid cleanup strategy because Android/Google Play require a stable unique app identity.
- `com.example.bible_mind_core` is a development placeholder and should NOT be the ONARIA production identity.
- Repository search shows this identifier is referenced by Android/release/app-link assets and documentation, so migration must be atomic rather than a one-line deletion.
- Candidate derived from the owned service domain is `kr.ai.onaria`, but changing the ID changes Android app identity and can affect already-installed test builds/data. Perform the migration as a dedicated tested change before first Play publication, not as an unreviewed deletion.

## Sources checked
- Google Play Target API level requirements (2026-08-31: new apps and updates target Android 16 / API 36+).
- Google Play Health apps declaration.
- Google Play AI-Generated Content policy.
- Google Play User Data / account deletion requirements.
- Google Play July 15, 2026 policy announcement clarifying third-party AI integrations remain subject to User Data requirements.
