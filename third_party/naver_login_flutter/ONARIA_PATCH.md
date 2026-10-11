# ONARIA Android authentication adapter, 2026-10-11

Upstream: naver_login_flutter 4.0.0, https://github.com/toyaji/naver_login_flutter
Original Android source SHA256: 7731b07809678a250bdc0d832a7617359c2a8ca4b15e441fbefc4f8d284e93d1
License preserved in LICENSE. iOS source unchanged.

Android login returns the SDK token on successful callback; member identity is validated by ONARIA server. No client profile request gates login. Exact user_cancel is separate from success_token_missing. Failure descriptions are never forwarded. This is an uninstalled candidate; A33 E2E remains required.

SDK logout now reports failures and checks both local tokens are absent before reporting success. Removed copied Xcode user-state metadata.

Dart logout previously ignored native result and fabricated loggedOut. It now parses Android result and parses the existing iOS status map. Added a regression proving cleanup error stops login.
