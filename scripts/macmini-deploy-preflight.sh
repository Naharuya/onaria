#!/bin/bash
set -euo pipefail

fail() { echo "[FAIL] $*" >&2; exit 1; }
ok() { echo "[OK] $*"; }
warn() { echo "[WARN] $*"; }

MODE="${1:---debug}"
[[ $# -le 1 ]] || fail "Usage: $0 [--debug|--release|--play-store]"
case "$MODE" in
  --debug|--release|--play-store) ;;
  *) fail "Usage: $0 [--debug|--release|--play-store]" ;;
esac

[[ "$(uname -s)" == "Darwin" ]] || fail "This preflight is for macOS."
[[ "$(uname -m)" == "arm64" ]] || fail "Apple Silicon arm64 is required for the configured runner labels."

for cmd in git node flutter; do
  command -v "$cmd" >/dev/null 2>&1 || fail "$cmd is not on PATH"
  ok "$cmd: $(command -v "$cmd")"
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$SDK" && -f android/local.properties ]]; then
  SDK="$(sed -n 's/^sdk.dir=//p' android/local.properties | head -1 | sed 's/\\:/:/g; s/\\\\/\\/g')"
fi
[[ -n "$SDK" ]] || fail "Android SDK path is unavailable. Set ANDROID_HOME/ANDROID_SDK_ROOT or android/local.properties."

ADB="$SDK/platform-tools/adb"
SIGNER="$SDK/build-tools/36.0.0/apksigner"
AAPT="$SDK/build-tools/36.0.0/aapt"
[[ -x "$ADB" ]] || fail "adb missing: $ADB"
[[ -x "$SIGNER" ]] || fail "apksigner missing: $SIGNER"
[[ -x "$AAPT" ]] || fail "aapt missing: $AAPT"
ok "Android SDK tools"

check_release_signing() {
  [[ -f android/key.properties ]] || return 1
  local alias store_file
  alias="$(sed -n 's/^keyAlias=//p' android/key.properties | head -1)"
  store_file="$(sed -n 's/^storeFile=//p' android/key.properties | head -1)"
  [[ "$alias" == "onaria-upload" && -n "$store_file" ]] || return 1
  [[ "$store_file" = /* ]] || store_file="$ROOT/android/$store_file"
  [[ -f "$store_file" ]]
}

if [[ "$MODE" != "--debug" ]]; then
  check_release_signing || fail "ONARIA release signing is not configured (key.properties must reference alias onaria-upload and an existing keystore)"
  ok "ONARIA release signing configuration exists (secrets not printed)"
elif ! check_release_signing; then
  warn "Release signing is not configured. Debug deployment only."
else
  ok "ONARIA release signing configuration exists (secrets not printed)"
fi

DEVICE_LIST="$($ADB devices | awk '$2=="device" {print $1}')"
DEVICE_COUNT="$(printf '%s\n' "$DEVICE_LIST" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$DEVICE_COUNT" == "1" ]]; then
  ok "One authorized Android device: $(printf '%s\n' "$DEVICE_LIST" | head -1)"
elif [[ "$DEVICE_COUNT" == "0" ]]; then
  warn "No authorized Android phone connected. Auto-deploy will fail until one is available."
else
  fail "More than one authorized Android device is connected. Keep exactly one for automatic deployment."
fi

node --test scripts/android-release.test.mjs
ok "Installer safety tests"

echo
ok "Mac mini preflight passed (${MODE#--} mode; build and installation not performed)."
