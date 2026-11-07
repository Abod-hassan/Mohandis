#!/usr/bin/env bash
# Finishes a CocoaPods install that stopped partway, which is what produces
#   "The sandbox is not in sync with the Podfile.lock."
#
# That message comes from the [CP] Check Pods Manifest.lock build phase. It
# diffs ios/Podfile.lock against ios/Pods/Manifest.lock. pod install writes
# BOTH at the very end, so if it is interrupted you get pods on disk and no
# Manifest.lock, and every build fails on that check until pod install
# completes once.
#
# This deliberately does NOT delete ios/Pods: pod install reuses whatever is
# already downloaded there, and Firebase is a large download to repeat.
#
#   bash tool/fix_ios_pods.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
LOG="$ROOT/tool/pod_install.log"
echo "==> project: $ROOT"

if pgrep -x Xcode >/dev/null 2>&1; then
  echo "!! Xcode is running. Quit it (Cmd-Q) first, then re-run."
  echo "   Building while pod install works is what interrupted it last time."
  exit 1
fi

echo "==> 1/3 flutter pub get (refreshes ios/Flutter/Generated.xcconfig)"
flutter pub get || { echo "!! flutter pub get failed"; exit 1; }

echo "==> 2/3 pod install   (log: tool/pod_install.log)"
echo "    Let this run to the end. It can take several minutes on the first"
echo "    CocoaPods install of Firebase. Do not Ctrl-C it."
( cd ios && pod install ) 2>&1 | tee "$LOG"
POD_STATUS=${PIPESTATUS[0]}

echo
echo "==> 3/3 verifying"
if [ "$POD_STATUS" -ne 0 ]; then
  echo "!! pod install exited $POD_STATUS - see tool/pod_install.log (last 20 lines):"
  tail -20 "$LOG"
  exit 1
fi
if [ ! -f ios/Pods/Manifest.lock ]; then
  echo "!! Pods/Manifest.lock still missing - pod install did not finish."
  exit 1
fi
if ! diff -q ios/Podfile.lock ios/Pods/Manifest.lock >/dev/null; then
  echo "!! Podfile.lock and Pods/Manifest.lock still differ:"
  diff ios/Podfile.lock ios/Pods/Manifest.lock
  exit 1
fi

echo "OK - Podfile.lock and Pods/Manifest.lock match. The sandbox check will pass."
echo "   $(grep -c '^  - ' ios/Podfile.lock) pod entries installed."
echo
echo "Now build:   flutter run"
echo "or open:     ios/Runner.xcworkspace   (the .xcworkspace, not Runner.xcodeproj)"
