#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

bash .ari/hooks/preflight.sh
bash .ari/hooks/verify.sh

if git grep -nE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|sk-[A-Za-z0-9_-]{20,})' -- ':!package-lock.json' ':!*.md' >/tmp/ari-secret-scan.$$ 2>/dev/null; then
  cat /tmp/ari-secret-scan.$$
  rm -f /tmp/ari-secret-scan.$$
  echo "RELEASE GATE FAIL: potential secret detected" >&2
  exit 11
fi
rm -f /tmp/ari-secret-scan.$$ 2>/dev/null || true

echo "RELEASE GATE PASS"
