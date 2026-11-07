#!/usr/bin/env bash
# Repairs "Missing package product 'FlutterGeneratedPluginSwiftPackage'".
#
# Cause: ios/Flutter/ephemeral/ (which holds the generated Swift package) was
# regenerated underneath Xcode, while Xcode kept a resolved package graph from
# before that. Xcode then cannot find the product and fails at the very start
# of the build. This resets every cached copy of that graph and rebuilds it.
#
# Run from anywhere:  bash tool/fix_ios_spm.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "==> project: $ROOT"

if pgrep -x Xcode >/dev/null 2>&1; then
  echo "!! Xcode is running. Quit it (Cmd-Q) and re-run this script."
  echo "   Xcode holds the stale package graph in memory; the reset will not stick."
  exit 1
fi

echo "==> 1/6 removing Xcode's resolved package graph"
rm -f  ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
rm -f  ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved
rm -rf ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/configuration
rm -rf ios/Runner.xcworkspace/xcshareddata/swiftpm/configuration
rm -rf ios/Runner.xcodeproj/project.xcworkspace/xcuserdata
rm -rf ios/Runner.xcworkspace/xcuserdata

echo "==> 2/6 removing DerivedData for Runner"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo "==> 3/6 clearing the shared SwiftPM cache"
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm

echo "==> 4/6 flutter clean + pub get  (regenerates ios/Flutter/ephemeral)"
flutter clean
flutter pub get

echo "==> 5/6 pod install"
( cd ios && pod install )   # do NOT rm -rf Pods: pod install reuses them

echo "==> 6/6 warming the iOS build"
flutter build ios --config-only --no-codesign || true

cat <<'MSG'

Done. Now:
  1. open ios/Runner.xcworkspace        <-- the .xcworkspace, NOT Runner.xcodeproj
  2. wait for "Resolving Package Graph" in the toolbar to finish
  3. if it still complains: File > Packages > Reset Package Caches, then
     File > Packages > Resolve Package Versions
  4. Product > Build

Or just run:  flutter run -d <your-device>
MSG
