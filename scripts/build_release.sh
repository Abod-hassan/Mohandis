#!/usr/bin/env bash
# Release builds for the App Store and Google Play.
#
# Always obfuscated: without --obfuscate a Flutter release keeps every Dart
# class and library name readable inside the binary, which is part of what an
# automated "same binary as another app" check (App Store guideline 4.3) can
# match on. The symbol maps go to build/symbols — keep them (one folder per
# release) to read crash stack traces later; they are NOT shipped in the app.
#
# Usage:  ./scripts/build_release.sh ios|android|both
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="lib/flavors/main_prod.dart"
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
SYMBOLS="build/symbols/$VERSION"
mkdir -p "$SYMBOLS"

flutter pub get

build_ios() {
  flutter build ipa --release -t "$TARGET" \
    --obfuscate --split-debug-info="$SYMBOLS/ios"
  echo "IPA: build/ios/ipa/  — upload with Transporter or Xcode Organizer."
}

build_android() {
  flutter build appbundle --release -t "$TARGET" \
    --obfuscate --split-debug-info="$SYMBOLS/android"
  echo "AAB: build/app/outputs/bundle/release/app-release.aab"
}

case "${1:-both}" in
  ios) build_ios ;;
  android) build_android ;;
  both) build_ios; build_android ;;
  *) echo "usage: $0 ios|android|both" >&2; exit 1 ;;
esac
echo "Symbols for this version: $SYMBOLS (keep them)."
