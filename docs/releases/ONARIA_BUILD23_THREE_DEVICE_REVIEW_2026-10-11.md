# ONARIA Build23 three-device verification — 2026-10-11

## Outcome
- S22, A33 and iPhone15: signed release 1.0.0+23 installed and launched.
- Android updates used scripts/android-release.mjs exported updateRelease, the implementation delegated to by scripts/install-onaria-release.ps1. Its build command received explicit build-number 23 because pubspec retains +21. Package, non-debuggable flag, current/new release certificate and no-downgrade checks ran before adb install -r.
- iOS app bundle identifier/build number, codesign and device provisioning were verified before devicectl installation.
- No uninstall, app data clear, production migration/restart, actual member merge, commit or push occurred.

## Finding and correction
Build22 cold startup produced two unhandled StateErrors on each Android device. CheckInPage loaded DailyUsageStore and EmotionCardStore during the unverified/changed record scope.
- OnariaApp holds the record home until MemberRecordScope is verified; account menu remains available.
- AccountMenuButton disables record-related routes while record access is locked.
- CheckInPage discards asynchronous loads belonging to a previous account generation and handles the expected StateError on account transition.
- DailyUsageStore validates its captured record lease after both asynchronous reads, including an empty-date result.
- Added a widget regression for locked startup and transition to a verified account.
Changed files: lib/app/onaria_app.dart, lib/app/mind_card_store.dart, lib/features/check_in_page.dart, lib/features/account_menu.dart, test/widget_test.dart. Prior dirty changes were preserved.

## Verification
| Device | Installed | Launch | Restored session | New-process exception scan |
|---|---|---|---|---|
| S22 | 1.0.0+23 | PASS | Naver; server-verified account menu status | 0 unhandled markers in recent app logs |
| A33 | 1.0.0+23 | PASS | Apple; server-verified account menu status | 0 unhandled markers in recent app logs |
| iPhone15 | 1.0.0+23 | PASS | NOT RUN | NOT RUN |

Android smoke tests force-stopped only the app process and launched it again. They did not delete records or log out the user. They read fixed UI status labels only. Restored sessions are not fresh provider authorization or proof of account-link/merge success. The log scan is a limited startup smoke test, not a whole-app crash-free claim.
- Backend: 498 PASS / 0 FAIL, including six read-only merge-plan tests.
- Flutter relevant auth/record/menu/widget regressions: 44 PASS.
- Analyze lib test example --no-fatal-infos: exit 0; 0 errors, 0 warnings, 36 informational existing/style findings.
- Android signed release Build23: PASS; iOS signed release Build23: PASS.
- git diff --check: PASS; high-confidence secret patterns in changed files: 0 matches.
- CI: NOT RUN — no new commit or push.

## Account-merge scope and remaining work
The installed app does NOT execute an account merge. account_merge_plan.js remains a read-only plan; its tests must not be described as an executable merge or ownership-proof test.
The requested no-SMS flow is still: authenticate each social account separately, verify control of both accounts on the server, display exact merge scope and obtain explicit consent, then transfer identities transactionally while preserving record-owner mapping. Matching name/phone never authorizes a merge.
Remaining implementation: merge prepare/confirm API, expiring one-use attempts, canonical member/record-owner mappings, revocation/recovery across session and member databases, durable receipts, client merge UX, preservation/collision handling and deletion/backup semantics across all source owners.
Real Apple/Naver fresh authentication, existing-account merge, real record preservation across all three devices and account deletion are NOT RUN. Physical owner authentication is required; destructive account tests must use dedicated fixtures. Production API and DB changes remain HOLD under prior user instruction and AGENTS.md.
Release Gate: HOLD. Build23 is a local authentication/startup review candidate, not approval to release account merge.
