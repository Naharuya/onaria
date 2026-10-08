# ONARIA Repository Housekeeping — 2026-09-20

## Purpose
Non-development housekeeping only. No production deployment, release submission, branch deletion, merge, credential change, or live-service mutation is authorized by this document.

## Current repository state
- Default branch: `main`
- `main` HEAD: `a110a7479accf73630a947a0b588ab7d9c5e42ef`
- Store candidate branch: `release/store-readiness-20260915`
- Store candidate HEAD: `7e7be64cc37ae84ee2a17ab541734609bccc0800`
- Store candidate is 2 commits ahead and 6 commits behind `main`; histories have diverged.
- Open draft PR #13: `Integrate ONARIA candidate with privacy and content approval gates`
- Recovery branch: `recovery/windows-onaria-20260919` is 1 commit ahead and 24 commits behind `main`.
- Other visible branches include:
  - `automation/server-agent-platform-v0.1`
  - `chore/repo-cleanup-ari-nodes`
  - `fix/rc1-feedback-api`
  - `fix/request-errors-20260914`
  - `onaria-https-migration-20260908`

## Safe housekeeping queue
These tasks may proceed without changing runtime behavior.
- Maintain a canonical branch/PR/release-candidate inventory.
- Group dated QA evidence and release reports consistently.
- Flag duplicate/outdated docs for later approval instead of deleting them.
- Keep licensing/content-approval evidence separate from app source.
- Keep privacy/consent/release-blocker evidence easy to audit.
- Track recovery branches as recovery-only; do not treat them as active development branches.
- Keep one canonical launch-readiness summary that points to detailed evidence.
- Record stale PR/branch retirement candidates without closing or deleting them automatically.

## Approval-required queue
Do not execute without Genie present.
- Merge PR #13 or reconcile the divergent release branch into `main`.
- Close/delete old PRs or branches.
- Approve scripture/content licensing or legal/privacy statements.
- Submit to Google Play/App Store.
- Deploy production changes.
- Change production secrets, domains, signing, billing, payment, or user data.
- Perform actual member deletion or other irreversible user-data operations.

## Current release blockers to preserve
- Operator/contact/retention/transfer privacy information incomplete.
- 15 content approvals were pending in the store-candidate evidence.
- Real-device validation and signed iOS archive still require completion.
- Remote CI previously had a NOT RUN condition caused by account/billing lock and needs a clean rerun when appropriate.

## Next housekeeping checks
1. Reconcile which dated QA folders remain authoritative.
2. Build a candidate archive list for superseded reports and recovery artifacts.
3. Produce a branch-retirement proposal with exact keep/delete reasons.
4. Keep release-blocker evidence centralized.
5. Avoid new feature work until release/Closed Beta priorities are explicitly reopened.
