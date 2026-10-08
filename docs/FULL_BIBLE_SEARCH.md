# Full Bible search — 2026-10-08

Home → menu → 성경 검색. Choose 개역한글 or WEB · 영어, enter a word or a full book name and chapter/verse (`요한복음 3:16`, `John 3:16`), and press search. Tap a result to read its full chapter. Search is offline, case-insensitive for English, and returns up to 100 results. Abbreviated book names are not supported in this first version.

## Sources and integrity

- Korean: Korean Revised Version 1952/1961, Zefania KorRV public distribution, 66 books / 1,189 chapters / 31,084 verse records. Source: https://sourceforge.net/projects/zefania-sharp/files/Bibles/KOR/Korean%20Revised%20Version%201952-1961/ . Archive rights metadata: Public Domain. This is **not a direct official Korean Bible Society export**, and whole-corpus comparison against their official text has not been performed. Korean Bible Society copyright FAQ: https://www.bskorea.or.kr/bbs/board.php?bo_table=copyright_faq&wr_id=5 . The screen labels it as a public distribution.
- English: World English Bible Protestant edition (engwebp), 66 books / 1,189 chapters / 31,103 verse records. Source: https://ebible.org/Scriptures/engwebp_vpl.zip . Copyright notice: https://ebible.org/engwebp/copyright.htm . Public domain; the text is preserved, not retranslated or paraphrased.

The converter pins the original XML SHA256, preserves the verse text (only trims outside whitespace), rejects duplicate references, and checks chapter completeness. The assets retain source hashes and edition names. Translation verse totals differ; no verses are invented to make counts equal.

Rebuild: `python3 scripts/build_full_bible_assets.py /path/to/reviewed/source/directory` with `korrv-complete.xml` and `web-complete.xml`. Both app assets are committed; no network download is required in CI or while using the app. Uncompressed assets add approximately 8.8 MiB.

## Scope and release

Existing emotion-selected Bible catalog, AI evidence, authentication, provider keys, production DB and backend remain unchanged. Original source files remain separately stored on Mac `/Users/ari/ARI/data/onaria/bibles/2026-10-08/` and Gabia `/opt/onaria/data/bibles/2026-10-08/`. The server files are archives, not a deployed search API.

This change requires a new app build; installed/TestFlight build 12 does not gain the feature through server file storage. Release builds and direct Android/iPhone installation completed as version 1.0.0 build 13 on 2026-10-08. Interactive search checks and TestFlight upload are separate. No review submission or production service restart is performed by this task.

Base commit: a3281e0 (includes the pending authentication recovery and three-second game changes). Branch: codex/full-bible-search-20261008. Changes should follow those PR dependencies rather than discard them.

## Executed validation

- Full Flutter suite: 156 passed, 1 existing skipped test.
- Additional search screen → full chapter navigation widget test: 1 passed.
- New source and tests targeted static analysis: no issues. Whole-project analysis: no errors or warnings, 18 pre-existing informational lints.
- All converted Korean and English verse strings compared with original XML: equal in original order.
- iOS simulator debug compile: passed using local ignored empty provider settings; this is not a signed release or provider-login verification.
- Android signed Release compile and data-preserving install: passed, 1.0.0+13; launch passed. iPhone signed Release compile, signature/profile/Apple-sign-in entitlement checks and direct device install: passed, 1.0.0(13). Full Bible assets verified in both binaries. Interactive search remains pending user unlock; iPhone launch blocked by device lock. TestFlight remains build 12 until a separate upload.

Device-install evidence: `/Users/ari/ARI/deploy-artifacts/onaria-bible-search-20261008/`. Direct installation does not update the App Store Connect/TestFlight build. No uninstall, app-data clear or server deployment was performed.
