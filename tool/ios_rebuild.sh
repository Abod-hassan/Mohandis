#!/usr/bin/env bash
# Clean iOS rebuild in the correct order, after the switch from Swift Package
# Manager back to CocoaPods.
#
# Fixes: "Module 'file_picker' not found" in GeneratedPluginRegistrant.m
#
# Why that happens: the pod integration itself is fine - file_picker is in
# FRAMEWORK_SEARCH_PATHS and OTHER_LDFLAGS and has a valid modulemap. But
# @import file_picker resolves against file_picker.framework, which the
# Pods project has to BUILD first. Two leftovers from the SPM era stop that:
#
#   1. ios/Flutter/Generated.xcconfig still sets
#      FLUTTER_FRAMEWORK_SWIFT_PACKAGE_PATH to a directory that no longer
#      exists (ios/Flutter/ephemeral/Packages/.packages/FlutterFramework).
#      It is only rewritten by a flutter build, not by pub get or pod install.
#   2. DerivedData still holds the old Pods project, which had 3 pod targets.
#      file_picker.framework is never produced, so Runner compiles against a
#      module that was never built.
#
# Order matters: flutter build --config-only must run BEFORE pod install, so
# pod install reads a correct Generated.xcconfig.
#
#   bash tool/ios_rebuild.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "==> project: $ROOT"

if pgrep -x Xcode >/dev/null 2>&1; then
  echo "!! Xcode is running. Quit it (Cmd-Q) first."
  echo "   It is holding the old Pods project; pod install cannot replace it"
  echo "   underneath a running Xcode and the stale one wins."
  exit 1
fi

echo "==> 1/6 clearing build output that predates the CocoaPods switch"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
rm -rf build/ios ios/build

echo "==> 2/6 flutter pub get"
flutter pub get || { echo "!! flutter pub get failed"; exit 1; }

echo "==> 3/6 flutter build ios --config-only  (rewrites Generated.xcconfig + GeneratedPluginRegistrant.m)"
flutter build ios --config-only --no-codesign || { echo "!! config-only build failed"; exit 1; }

if grep -q FLUTTER_FRAMEWORK_SWIFT_PACKAGE_PATH ios/Flutter/Generated.xcconfig; then
  echo "   note: Generated.xcconfig still references the SPM framework path."
  echo "   That is only a problem if the path is missing - checking:"
  P=$(grep FLUTTER_FRAMEWORK_SWIFT_PACKAGE_PATH ios/Flutter/Generated.xcconfig | cut -d= -f2-)
  [ -d "$P" ] && echo "   ok, it exists: $P" || echo "   !! MISSING: $P  <- report this back"
else
  echo "   ok: SPM framework path is gone from Generated.xcconfig"
fi

echo "==> 4/6 pod install"
( cd ios && pod install ) 2>&1 | tee tool/pod_install.log
[ "${PIPESTATUS[0]}" -ne 0 ] && { echo "!! pod install failed - see tool/pod_install.log"; exit 1; }

echo "==> 5/6 verifying the sandbox check will pass"
diff -q ios/Podfile.lock ios/Pods/Manifest.lock >/dev/null \
  && echo "   ok: Podfile.lock == Pods/Manifest.lock" \
  || { echo "!! locks differ"; exit 1; }

echo "==> 6/6 confirming file_picker is wired into the Runner target"
grep -q 'framework "file_picker"' "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig" \
  && echo "   ok: -framework file_picker present" \
  || echo "   !! file_picker missing from Pods-Runner.debug.xcconfig"

cat <<'MSG'

Done. Build from the command line first - it sequences the Pods targets
correctly, which is the thing Xcode was getting wrong:

    flutter run

Only open ios/Runner.xcworkspace afterwards, if you need Xcode for signing.
If Xcode still says "Module 'file_picker' not found" after a successful
flutter run, it is DerivedData again: Product > Clean Build Folder
(Shift-Cmd-K), then build.
MSG
