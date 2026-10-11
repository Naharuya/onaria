# ONARIA App Store privacy follow-up

2026-10-11 Asia/Seoul. This final record supersedes the earlier 12-type draft and mixed-archive purge proposal. Build24 and the original dirty checkout remain unchanged.

## Verified privacy draft

Build24 archive contains 21 privacy manifests. GoogleSignIn and Kakao declarations were compared with live production schema, whitelist-only runtime settings and logging code. SDK declarations are not a complete network traffic measurement. All final 11 types are linked to identity; tracking is false, no advertising purpose is selected. Device ID purpose is Analytics only. Actual category wizard radios were corrected for user ID, device ID, other usage and other data; final detailed preview shows only linked data.

| Type | Purpose | Evidence |
|---|---|---|
| Name | Functionality | members.name / GoogleSignIn |
| Email | Functionality | GoogleSignIn declaration |
| Phone | Functionality | members.phone / GoogleSignIn |
| Coarse location | Functionality | GoogleSignIn IP fraud prevention |
| Sensitive info | Functionality | optional members.church_name |
| User ID | Analytics + Functionality | SDK and member identity |
| Device ID | Analytics | GoogleSignIn declaration |
| Other usage | Analytics + Functionality | SDK and retained quota ledger |
| Performance | Functionality | nginx request_time associated with IP |
| Other diagnostics | Analytics + Functionality | operational metadata |
| Other data | Analytics + Functionality | GoogleSignIn and Kakao declarations |

Other User Content was removed after confirming userMessage and conversationMemory are request-scoped and not persistently stored in server schemas. Optional church affiliation is covered by Sensitive Info. This supersedes the earlier incorrect generic-profile-content rationale. External AI is disabled (local mode); stable pseudonymous usage ledger is conservatively treated as linked.

## Completed retention operations

The exclusive archived journal containing 192 aged ONARIA records was removed after scope/hash/timestamp verification. Two mixed archives were rewritten through official systemd journal export/import tooling: 3,265 aged ONARIA application entries removed; all 2,284 other records retained, including 16 BEAVERS and 2,268 system/user entries. A multiset fingerprint verified every retained field and real/monotonic timestamp except regenerated journal addressing metadata (__CURSOR, __SEQNUM, __SEQNUM_ID). No other entries removed. The whole-file shared purge proposal was NOT executed and is superseded.

First apply failed EXDEV before replacing any archive. Candidate staging was moved onto the source filesystem, verified under the hardened unit, then applied successfully. Root audit: /opt/onaria-retention-releases/legacy-journal-maintenance/result.json. Exact CI artifact commit 2531cd6de9752249baef6b244a0aec0b96036c90 / run38144302570 success. Final dry-run: zero candidate removals; aged records selected by _SYSTEMD_UNIT=onaria-backend.service: zero. Daily maintenance timer is active/enabled (04:47 KST plus jitter). No backend restart for journal maintenance. Normal journal rotation sealed legacy records without deleting unrelated records. Official Ubuntu packages were downloaded and extracted privately; no package installation, listener or new remote service was activated.

## Public policy and verification

website.js deployed from exact CI artifact 33b10d60f2553c02cf3a4da6ceee1d767f4edad6 / run38143277829 success. Only website.js changed, backend restarted once, API healthy, public privacy HTTP200 with retained access-log IP/time/method/path/status/size/latency disclosure. Access format omits request body, tokens and query strings; this is not a blanket claim about all error logs. Website SHA256: 8f785eebcc1811c192b890107a75334e640cda45678b8e7dcc74129c291c5e51.

Tests: web10 PASS; journal Python7 PASS; release backend471 PASS in CI. Previous original checkout backend517 PASS is a separate prior result. No new app build or real-device test this follow-up; the user previously confirmed login on S22/A33/iPhone. Account merge remains OFF; no real member deletion test.

## App Store action boundary

Version1.0 / Build24 remains Prepare for Submission, manual release selected. Description/review notes reflect local processing, optional social membership, in-app deletion and merge OFF. Five iPhone screenshots visible.

Initial Publish attempt was rejected by automatic approval review due unverified category accuracy. Further checks and the 11-type corrections above resolved the evidence gap; a direct normal UI retry reached Apple's publication confirmation. No bypass was used. The modal explicitly states that publishing means the company agrees that the answers are accurate, comply with guidelines/applicable law and will be updated after data-practice changes. Final modal Publish is NOT clicked because accepting this agreement requires action-time user confirmation. Privacy not published; Add for Review and final review submission NOT RUN. Remaining gate: user confirmation of this precise agreement, then normal privacy publication and App Review submission.

Sources: https://developer.apple.com/app-store/app-privacy-details/ ; https://developers.google.com/identity/sign-in/ios/app-privacy ; https://systemd.io/JOURNAL_EXPORT_FORMATS/ ; https://manpages.ubuntu.com/manpages/noble/man8/systemd-journal-remote.service.8.html .
