#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "== ONARIA verification =="
flutter analyze lib test example --no-fatal-infos
flutter test
cd backend && npm test
echo "VERIFY PASS"
