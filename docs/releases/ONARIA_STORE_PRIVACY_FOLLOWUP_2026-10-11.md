# ONARIA App Store privacy follow-up

2026-10-11 Asia/Seoul. Build24 and original dirty checkout preserved.

## Observed evidence

Build24 archive contains 21 privacy manifests. GoogleSignIn declares name, email, phone, coarse location and user ID for functionality, and user ID/device ID/other usage/other data for analytics; Kakao auth declares linked other data for functionality. No SDK manifest declares tracking. These are provider declarations, not complete traffic measurements. Google official guidance additionally describes OAuth user identifiers and IP-derived fraud prevention location.

Apple definitions: third-party SDK collection is part of the app label; IP use determines classification; retained diagnostic timing associated with IP is linked. Generic free-form collected content is other user content, while the optional church field additionally warrants sensitive religious information.

App Store draft corrections saved and observed: Other User Content linked=true (member-linked optional profile text); Performance Data linked=true (nginx retained request time with IP). Tracking remains false, advertising purposes unchecked. Global Publish and final App Review submission NOT RUN. Other 10 existing categories were reviewed against deployed SDK declarations, member data, pseudonymous ledger and diagnostic logs. Raw dialogue is request processing, not claimed persistently stored; external AI remains disabled.

## Historical journal cleanup

One archived journal contained only 192 ONARIA records, all older than 14 days. Complete file scope and timestamps were verified before unlink; count and source hash recorded in a root-only server audit file. No real member deletion test.

Two remaining immutable archives (8 MiB each) contain 3,265 ONARIA records, 16 BEAVERS records and 2,268 system/user records. All 5,549 records exceed 14 days. These files were NOT deleted; deleting them crosses the ONARIA-only project boundary. No global vacuum, other-project restart or live journal deletion.

## Prepared public disclosure

website.js adds retained access-log fields (IP, time, method/path, response status/size/time), stability/performance/security purposes and omission of body/token/query from the access-log format. Syntax check and existing onaria_web test suite: 10 PASS / 0 FAIL. Patch not deployed; current production website hash e466e748ee67423e8b6545415d2c86c2214b48a7b66bddd2079c37a4e64359f1.

## Required scope decision

Approve deleting exactly the two aged mixed archives (including 16 BEAVERS and 2,268 system/user records), then verify no aged ONARIA records remain. Other journal files, application code/data and service settings are excluded. App Store submission remains HOLD until historical retention and public disclosure match operational facts. The project AGENTS.md requires approval for data deletion and forbids unauthorized changes to other projects.

Sources: https://developer.apple.com/app-store/app-privacy-details/ and https://developers.google.com/identity/sign-in/ios/app-privacy .
