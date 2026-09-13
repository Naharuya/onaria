#!/bin/bash
set -euo pipefail
# Run locally with sudo only after reviewing the generated system plist.
if [ "$(id -u)" -ne 0 ]; then
  echo 'Administrator authentication required; run this script with sudo in a local terminal.' >&2
  exit 1
fi
ARI_OS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARI_SYSTEM_PLIST=/Library/LaunchDaemons/com.ari.company-os.plist
if [ -e "$ARI_SYSTEM_PLIST" ]; then
  echo 'Existing system plist preserved; manual reconciliation required.' >&2
  exit 1
fi
/usr/bin/plutil -lint "$ARI_OS_ROOT/launchd/com.ari.company-os.system.plist"
/usr/bin/install -o root -g wheel -m 644 "$ARI_OS_ROOT/launchd/com.ari.company-os.system.plist" "$ARI_SYSTEM_PLIST"
# Remove only the same service from the user domain to retain a single instance.
/bin/launchctl bootout gui/501/com.ari.company-os 2>/dev/null || true
/bin/launchctl bootstrap system "$ARI_SYSTEM_PLIST"
/bin/launchctl print system/com.ari.company-os
