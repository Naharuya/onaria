#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT/android/onaria-upload.jks"
PROPERTIES="$ROOT/android/key.properties"

if [[ -e "$KEYSTORE" || -e "$PROPERTIES" ]]; then
  echo "Signing files already exist. Refusing to overwrite."
  exit 1
fi

: "${ONARIA_KEY_ALIAS:?Set ONARIA_KEY_ALIAS}"
: "${ONARIA_STORE_PASSWORD:?Set ONARIA_STORE_PASSWORD}"
: "${ONARIA_KEY_PASSWORD:?Set ONARIA_KEY_PASSWORD}"

KEYTOOL="${KEYTOOL:-keytool}"
command -v "$KEYTOOL" >/dev/null 2>&1 || {
  echo "keytool not found. Install/use the JDK bundled with Android Studio."
  exit 1
}

"$KEYTOOL" -genkeypair   -v   -keystore "$KEYSTORE"   -alias "$ONARIA_KEY_ALIAS"   -keyalg RSA   -keysize 2048   -validity 10000   -storepass "$ONARIA_STORE_PASSWORD"   -keypass "$ONARIA_KEY_PASSWORD"   -dname "CN=ONARIA Upload, OU=Mobile, O=ONARIA, L=Seoul, C=KR"

cat > "$PROPERTIES" <<EOF
storePassword=$ONARIA_STORE_PASSWORD
keyPassword=$ONARIA_KEY_PASSWORD
keyAlias=$ONARIA_KEY_ALIAS
storeFile=onaria-upload.jks
EOF

chmod 600 "$KEYSTORE" "$PROPERTIES"
echo "Created local Android upload signing files."
echo "They are ignored by Git. Back them up securely before store submission."
