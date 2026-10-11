# ONARIA Build24 source and main integration

Scope: user authorized commit, push and main integration after Apple submission. Original branch codex/apple-android-20261006 at1aef381 had188 status entries. Isolation base origin/main3fa97ca. Candidate includes original Build24 client source and latest retention branch76fcd1d, preserving local excluded artifacts listed in ONARIA_MAIN_INTEGRATION_EXCLUSIONS_2026-10-11.json.

Client lib/assets/test/vendored Naver source hashes match the original release source. Pubspec now1.0.0+24; previous local pubspec21 was overridden to24 during release builds. No submitted binary rebuilt or replaced. Runtime merge remains disabled; integration does not deploy server or migrate production DB.

Latest public access-log disclosure retained. Operational journal cleanup and final privacy publication/submission records retained. Backend auth/optional-merge code retained with default merge disabled. Vendored Naver license retained; no local credentials, signing key, databases or app binaries included.

Reproduction fixes found during integration: external HTTPS policy links were incorrectly tested as local fixture paths; E2E now validates external HTTPS separately and still requests all internal routes. CI build fixtures now include required Kakao native config. Trusted manual release helper now copies ignored Kakao config privately with0600 permissions. These tooling fixes do not alter the submitted client behavior.

Local verification: backend519 PASS; journal Python7 PASS; Flutter196 PASS/1skip; analyzer0errors/0warnings/49infos under --no-fatal-infos; API override regressions3+3 PASS; installer/config18 PASS/1Windows-only skip. Web20 PASS after correcting external-link test. Lighthouse3samples: performance99/100/100; accessibility, best-practices, SEO100 each. Secret-pattern scan reviewed four unchanged pre-existing synthetic test literals; forbidden-file/symlink check passed. Main CI and native compilation are required before final integration. No force push, original reset/stash, service restart, member deletion, deployment or device install.
