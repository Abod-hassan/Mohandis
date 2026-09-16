# Getting started

Fresh clone of this template. Get the app running, then wire your backend.

## 1. Prerequisites

- Flutter 3.9+ (`flutter --version`)
- Xcode + CocoaPods (for iOS builds)
- Android Studio or command-line SDK (for Android builds)
- A device / emulator / simulator to run on

## 2. Install dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 3. Rename the package (do this once, at the start)

The template ships as `flutter_mobile_template` / `com.example.flutter_mobile_template`. Before you go further:

1. Pick your Dart package name (lowercase, snake_case). Example: `acme_ordering`.
2. Pick your Android/iOS bundle id. Example: `com.acme.ordering`.
3. Search-and-replace across the repo:

```bash
# Dart package name
grep -rl "flutter_mobile_template" --include="*.dart" --include="*.yaml" . \
  | xargs sed -i '' 's|flutter_mobile_template|acme_ordering|g'

# Android bundle
grep -rl "com.example.flutter_mobile_template" \
  android/app/build.gradle.kts android/app/src \
  | xargs sed -i '' 's|com.example.flutter_mobile_template|com.acme.ordering|g'
```

Then adjust `ios/Runner.xcodeproj/project.pbxproj` `PRODUCT_BUNDLE_IDENTIFIER` values via Xcode or a targeted sed.

## 4. Set your API base URLs

Edit `lib/flavors/main_dev.dart` / `main_staging.dart` / `main_prod.dart` and replace the placeholder `apiBaseUrl` values with your backend hostnames.

## 5. Set the shared client secret

Open [`lib/core/api/client_key.dart`](../lib/core/api/client_key.dart) and replace `REPLACE_WITH_YOUR_SHARED_CLIENT_SECRET` with the shared static secret your backend team gives you. See ARCHITECTURE.md §11 for what this signature is defending against.

The **per-device** signing secret is provisioned at runtime via `/api/auth/signing-bootstrap` — no action needed here.

## 6. Wire Firebase (or disable it)

The template ships with `firebase_core` + `firebase_messaging` + `flutter_local_notifications` preinstalled, and `bootstrap.dart` calls `Firebase.initializeApp()`. Drop your config files into place:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

If you don't need push notifications yet, the `Firebase.initializeApp()` call is already wrapped in a `try/catch` — the app boots without Firebase, and you can strip out the deps + FCM feature later.

## 7. Run

```bash
flutter run --target lib/flavors/main_dev.dart
```

Or the default entrypoint (which routes to dev):

```bash
flutter run
```

You'll see a splash → login screen. The template ships with placeholder API URLs — the login attempt will fail against your real backend until you complete step 4.

## 8. Wire per-environment flavors on the native side

The Dart-side flavor split works out of the box via `--target`. Split bundle IDs, icons, and Firebase configs per environment require native config:

- **Android:** add `productFlavors` in `android/app/build.gradle.kts` — see ARCHITECTURE.md §10.5.
- **iOS:** add per-env schemes in Xcode (Runner-dev, Runner-staging, Runner-prod) with their own `.plist` overrides.

See ARCHITECTURE.md §10 for the full flavor contract.

## 9. Build your first feature

Follow the 7-step recipe in [ADDING_A_FEATURE.md](ADDING_A_FEATURE.md) — pick a real endpoint you need and scaffold entity → DTO → repository → notifier → screen → endpoint constant → tests.
