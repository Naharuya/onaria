#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "PRECHECK FAIL: not inside a git repository" >&2
  exit 2
fi
cd "$ROOT"

echo "PROJECT=ONARIA"
echo "ROOT=$ROOT"
echo "BRANCH=$(git branch --show-current)"
echo "HEAD=$(git rev-parse --short HEAD)"
echo "REMOTE=$(git remote get-url origin 2>/dev/null | sed -E 's#(https?://)[^/@]+@#\1***@#')"
echo "DIRTY_COUNT=$(git status --porcelain | wc -l | tr -d ' ')"

test -f CLAUDE.md || { echo "PRECHECK FAIL: CLAUDE.md missing" >&2; exit 3; }
test -f AGENTS.md || { echo "PRECHECK FAIL: AGENTS.md missing" >&2; exit 4; }

echo "PRECHECK PASS"
