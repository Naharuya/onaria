# ONARIA Markdown audit and legacy signup repair — 2026-10-24

Baseline: main `40cd65851553238c426b32f5af2639e76f24f64b`, pubspec1.0.0+24. Existing dirty roadmap/untracked plans preserved. No commit, push, merge, device install, key access/change, store action, live provider call or production mutation.

## Before → After → Why → Impact

| Topic | Before | After | Why / impact |
| --- | --- | --- | --- |
| Legacy signup trust | `/v1/auth/signup` accepted loginProvider and arbitrary providerUserId without verifying provider credentials; memberStore created the social identity | Dedicated legacyMemberSchema accepts phone only and forbids supplied providerUserId before store mutation; verified provider signup unchanged | Enforces Build20 social identity security contract. Legacy phone profile compatibility retained; callers attempting unverified social registration receive400 |
| Current entry docs | README/STATUS called0.4.1+6 current, OAuth pending, old host current, selected text a development summary; tests guide regenerated platforms | Current source1.0.0+24 distinguished from Sep11 snapshot and dated release evidence; verified social path/source14verse catalog described; QA compiles existing platforms; Release update gate retained | Prevents stale reports being used as operational/current test evidence and prevents unsafe platform regeneration/update instructions |
| Signing guide | AGENTS pointed to obsolete filename; old certificate presented as current | Existing configured approved key and unchanged installer alias/certificate pin are authoritative; old fingerprints explicitly historical | Existing Oct6/Oct19 same-key provenance resolves documentation drift. No keys read or changed |
| Catholic product scope | Oct12 combined Protestant/Catholic choice appeared active alongside separate-service philosophy | Oct24 user decision: Catholic remains separate app. Old plan preserved as superseded; roadmap/multilingual scope aligned | No functional faith-selection, API, DB, identity or content mixing introduced |
| Feedback purpose | Optional aggregate existed, user-described repetitive-phrase additional storage purpose not recorded in app policy Markdown | [Canonical local policy](../FEEDBACK_ADAPTIVE_PHRASE_POLICY_2026-10-24.md) records purpose, current code matrix, and unverified connection to additional phrase storage | User requested Markdown/future-policy direction. No new collection, fixed retention promise, public policy publication or automatic learning introduced |
| Play status header | Header said no console input while later Oct22 section records draft saves | Header points to Oct22 partial Alpha/Data safety draft saves; submission/test start unexecuted in record | Preserves chronology without claiming fresh console verification |

## Acceptance and current local tests

- Existing full backend baseline: `npm test`525PASS/0FAIL.
- New mocked legacy signup regression failed2of3 before repair (201 instead400); fixed suite3PASS. Four social providers tested with/without subject, phone with subject/empty/null rejected without store/verification/session calls, valid phone201, verified provider signup uses verifier identity despite spoofed input.
- Full backend after repair: `npm test`528PASS/0FAIL/0SKIP.
- Existing feedback regression2PASS after retrying sandbox localhost listen EPERM with authorized localhost-only execution; no external service.
- Targeted orchestrator/retention15PASS earlier in audit; included in full suite later.
- Changed JS syntax and git diff --check PASS. Relative Markdown links/focused version/package/release/decision assertions/credential-pattern scan performed on documentation changes. Independent QA is queued by orchestrator; self-tests do not substitute independent verification.
- Flutter/analyzer/native build/device/liveAPI/currentCI: NOT RUN, backend/docs-only repair. Historical release records are dated evidence, not current execution proof.

## Deferred work and prerequisites

| Item | Status / reason | Prerequisite / target |
| --- | --- | --- |
| Other ONARIA worktree copies of vulnerable legacy route | AFFECTED, intentionally not edited or merged | main-integration75579ed and retention76fcd1d are other branches of this repository. Review branch-specific patch/release purpose; no automatic canonical choice/merge |
| Legacy phone registration authentication/deletion | Existing compatible route preserved; no provider proof/session issued | Product/API compatibility review of old clients and safe verified owner deletion. Do not claim phone registration verifies ownership |
| Feedback→additional phrase storage | User purpose ACCEPTED, actual connection UNVERIFIED in inspected app source | Locate existing module/tool and trace aggregate→candidate→validation→active response. Keep current transmission scope until data contract is established |
| Feedback public notice | SOURCE DISCLOSURE GAP; review proposal prepared, no website.js mutation | Exact dataflow and legal-policy review/authorization before public policy change; memory lifecycle distinct from log14day/usage62day jobs |
| Answer-specific AI reporting | Fixed-category feedback is not per-answer report workflow | Approved payload minimization, moderation handling/owner, retention/deletion and user notice; no arbitrary conversation collection under audit scope |
| i18n structure | Planned next-version preparation; request schema currently literal ko-KR, no Flutter localization delegates found | Scope/locale resources + safety/content/license review; preserve Korean release |
| Persistent conversation memory | HTTP chat uses request-scoped conversationMemory/conversationSummary; standalone memory_store Map is not imported by current runtime. Cards/session DBs are separate | Explicit retention/owner isolation/delete contract and restart tests before adding durable conversation content |
| D7/PoC/Premium/CAC-LTV | Goals or unverified measurements, not current completion | Cohort/event definitions and observed data; deployment/payment/business gates remain separate |
| Shared invitation links | Intentionally postlaunch | Launch confirmation, actual install URLs, domain certificates and approved runtime activation |
| Play final gate | Oct22 drafts saved historically; no fresh console check | Android SDK/dataflow/health/access answers, Play app-signing/provider registration, actual Android screenshots and16KB runtime; no submit/deploy under audit |

## Audit coverage limit

Inventory includes all349 Markdown copies found across onaria/main-integration/retention/christian, deduplicated to128 initial SHA256 contents. Coverage JSON distinguishes fully read/partial/hash-link-only. All authored active and historical Markdown has now been semantically read, including archive/phase reports and the 241,105-byte local-review transcript (delegated reviewer evidence records all 1,831 lines and matching SHA256). With three new audit records, coverage is 352 copies / 131 initial-or-added content hashes: 129 fully read; the generated file index and vendored upstream README remain separately classified mechanical scans. No historical success report was promoted to current proof. Detailed machine-readable manifest, duplicate groups, patches and logs are in the authorized orchestrator audit workspace `.agent/all-app-audit/onaria-family` (Beavers repository), not runtime dependencies.

Next: independent VERIFY; complete remaining semantic audit; review affected preserved branches and approved-but-unimplemented prerequisites above.
