# Google Play Policy Release Gate — 2026-09-21

Status: PRE-RELEASE / HUMAN APPROVAL REQUIRED FOR PLAY CONSOLE SUBMISSION

## P0 automated engineering gates
- [ ] Verify Android target API >= 36 for every Play submission after 2026-08-31.
- [ ] Add an in-app reporting/flagging path for AI-generated responses.
- [ ] Test crisis/safety routing and prohibited-content handling.
- [ ] Audit Android permissions; retain only permissions used by shipped features.
- [ ] Verify HTTPS-only production API and third-party AI data disclosure.
- [ ] Verify account deletion implementation if in-app account creation ships.

## P0 Play Console / policy declarations
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
1. Production Android applicationId.
2. Legal/business identity, contact details, retention periods, international transfer/AI-provider disclosures in the final privacy policy.
3. Play Console Health apps declaration and Data safety answers.
4. Store listing claims/screenshots.
5. Final production release / rollout.

## Sources checked
- Google Play Target API level requirements (2026-08-31: new apps and updates target Android 16 / API 36+).
- Google Play Health apps declaration.
- Google Play AI-Generated Content policy.
- Google Play User Data / account deletion requirements.
- Google Play July 15, 2026 policy announcement clarifying third-party AI integrations remain subject to User Data requirements.
