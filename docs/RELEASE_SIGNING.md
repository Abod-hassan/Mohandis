# Android release signing (Google Play)

Release builds are signed with the **upload key**. Google Play re-signs the app
with its own app-signing key (Play App Signing), so the upload key only proves
an upload came from us.

## Where things live

| What | Where | In git? |
|---|---|---|
| Keystore | `android/app/upload-keystore.jks` (alias `upload`) | No — git-ignored (`**/*.jks`) |
| Passwords + path | `android/key.properties` | No — git-ignored |
| Gradle wiring | `android/app/build.gradle.kts` (`signingConfigs.release`) | Yes |

`key.properties` format:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks   # relative to android/app
```

Without `key.properties` the release build falls back to the debug key and logs
a warning. Play rejects debug-signed bundles, so such a build cannot be
uploaded by accident.

## Back it up

The keystore is git-ignored, so deleting the project, a fresh clone, or
`git clean -xdf` loses it. Keep a copy outside the project.

Copy the `.jks` file and its password to a password manager or another safe
place. If the upload key is lost, a new one can be registered through Play
Console support, but that takes days. Without Play App Signing, losing the
key means the app can never be updated.

## Build for upload

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Release mode runs
the prod flavor (`lib/main.dart` → `main_prod.dart`).

Before each upload, raise the build number in `pubspec.yaml`
(`version: 0.1.0+1` → `0.1.0+2`). Play refuses a `versionCode` it has
already seen.

## Fingerprints

Print the upload certificate (asks for the store password):

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

If a Google API is ever restricted by SHA-1 (Firebase Auth, Maps, Google
Sign-In), register both this upload SHA-1 and the **app signing** SHA-1 from
Play Console → Setup → App signing.
