# ONARIA optional account merge — Build24 local review (2026-10-11 KST)

## Implemented behavior
Account management offers an optional merge entry. Independent signup/login remains unchanged; matching name/phone never merges users. SMS verification was explicitly excluded.
1. Authenticated current ONARIA session; verify the current account's provider credential.
2. Verify the other social credential and resolve the registered member on the server.
3. Under an immediate member-DB transaction, recheck both exact provider subjects' ownership and the still-live session. Prepare a random, hashed-at-rest attempt bound to that session for 120 seconds.
4. Display providers, original-record preservation, session replacement, no automatic cross-device transfer, no unmerge, and merged-family deletion scope. Confirm requires explicit consent.
5. Recheck ownership snapshot under an immediate transaction; revoke both members' old sessions synchronously before identity reassignment. Preserve original source member rows and original record-owner IDs as aliases. Never overwrite profile or record content.
6. Issue a new target session. If the merge commits but session issuance or response delivery fails, the UI requests normal login and authoritative account review; it does not repeat confirmation or delete records.

Same-provider different-subject conflicts, missing proofs, absent consent, wrong sessions, expired/reused attempts, ownership changes and deleted members fail closed. Another prepare replaces a pending prompt for that session. Raw provider credentials and ONARIA tokens are never stored in merge tables or logged.
Merged source aliases are excluded from legacy identity backfill and admin member counts. Detaching the original primary identity now clears its legacy subject so restart cannot resurrect the detached identity.
Completed attempt metadata is removed with member-family deletion; old attempt metadata is pruned opportunistically during prepares. This is not a verified scheduled retention/purge guarantee.

## Records and deletion
- No record copy/overwrite/delete occurs during merge; source namespaces remain untouched.
- The read-only previous-record screen obtains the owner map from fresh authenticated GET account; rejects account/session changes; reads only mapped original owners. Supports mind cards, stored drafts, saved/recent verses, journey entries and emotion selection counts. Other original preferences remain preserved. Damaged records are retained and flagged as unreadable.
- This is not cloud synchronization, automatic aggregation into the current editable record store, or legal-person identity verification.
- Account deletion atomically records every canonical/source owner in the durable deletion manifest before member-family removal. Restoring a pre-merge member backup and replaying the manifest cannot resurrect a deleted original source.
- After confirmed server deletion, the client durably queues all mapped owners before local cleanup. Retry after restart processes remaining owners. Legacy, guest and unrelated members are excluded. Storage failures remain separately reported; no lost/failed server response authorizes local deletion.

## Runtime gate and deployment boundary
- createApp defaults accountMergeEnabled=false.
- server.js reads ONARIA_ACCOUNT_MERGE_ENABLED exactly 'true'; no local or production environment file was enabled.
- Availability also requires deletionManifest.recordMany, merge store, verifier and identity-wide session revocation.
- Old production account responses safely default to mergeAvailable=false and current-owner-only record mapping.
- Existing user hold on production deployment, migrations/restart, commit/push remains effective. Production DB and accounts were not merged.
- Before activation: reviewed backend deployment artifact, backup/restore rehearsal on the production-equivalent schema, existing optional-profile/social-identity migration gates, policy/deletion-web/store disclosures, real Apple/Naver credentials using dedicated test accounts, and cross-device record checks.
- Preparing an app candidate is not App Store/Google Play approval. Do not publish the disabled/unfinished feature as a completed production capability.

## Validation
- Backend final full npm test: 509 PASS / 0 FAIL.
- Executable merge API regression file: 11 PASS (part of full 509).
- Flutter full suite: 195 PASS / 1 SKIP / 0 FAIL.
- After adding small-screen/text-scale regression: focused account merge suite 8 PASS / 0 FAIL; full suite was not redundantly rerun for the test-only addition.
- Analyze lib test example --no-fatal-infos: exit 0, 0 errors, 0 warnings, 48 informational style findings.
- git diff --check PASS; high-confidence secret-pattern scan of changed source/test files: no matches. This is not a comprehensive security certification.
- Android signed release Build24 and iOS signed release Build24 PASS.
- S22 and A33: official release-certificate/package/non-debuggable/no-downgrade checks and adb install -r PASS; cold startup and home PASS; original Naver (S22) / Apple (A33) sessions restored; optional entry visible and disabled against unchanged production; recent new-process unhandled exception marker count 0.
- iPhone15: bundle/build metadata, codesign and provisioning PASS; install and process launch PASS; installed build verified 24. Real social UI/login/merge test NOT RUN.
- Real-member merge, real source-record preservation, provider revocation/deletion on production, store submission and CI: NOT RUN.
- No uninstall, data clear, real account deletion, production restart, commit or push.

## Source files
backend/src/account_merge_store.js
backend/src/member_store.js
backend/src/app.js
backend/src/server.js
backend/src/privacy/deletion_manifest.js
backend/test/account_merge.test.js
lib/src/api/provider_auth_api_client.dart
lib/features/privacy_page.dart
lib/features/account_merge_page.dart
lib/features/merged_records_page.dart
lib/app/merged_record_reader.dart
lib/app/member_record_cleanup.dart
test/account_merge_test.dart

Previous dirty changes were preserved; a git diff against HEAD also includes earlier auth work and must not be mistaken for only this turn's patch.
Current HEAD: 1aef3815c8e25022a948c4307e1c755e5cc8507b
Source pubspec remains +21; Build24 used explicit build-number overrides; installed app information uses actual package metadata.
Release Gate: HOLD pending production activation and real-provider end-to-end verification.
