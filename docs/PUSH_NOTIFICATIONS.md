# Push notifications — connecting Firebase

The app and the server are both wired for push. What is missing is the
Firebase project that connects them, and that has to be created in your
Google and Apple accounts. Four steps, about twenty minutes.

App identifiers (already set in the project):

| Platform | Identifier |
|---|---|
| iOS bundle ID | `com.robobyte.mohandis` |
| Android package | `com.robobyte.mohandis` |

---

## 1. Create the Firebase project

1. Open <https://console.firebase.google.com> → **Add project** → name it
   `Mohandis`. Google Analytics is optional.
2. Nothing else in the console yet — step 2 registers the apps for you.

## 2. Connect the Flutter app (one command)

On the Mac, in the `MohandisApp` folder:

```bash
dart pub global activate flutterfire_cli
firebase login                      # once; install with: npm i -g firebase-tools
flutterfire configure --project=<your-firebase-project-id> \
  --platforms=ios,android \
  --ios-bundle-id=com.robobyte.mohandis \
  --android-package-name=com.robobyte.mohandis
```

This registers both apps in Firebase and writes:

- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`
- `lib/firebase_options.dart`
- the Google Services Gradle plugin in `android/settings.gradle.kts` and
  `android/app/build.gradle.kts`

No code change is needed after it runs — `bootstrap.dart` already calls
`Firebase.initializeApp()`, which picks up the two config files.

## 3. Apple Push (iOS only)

iOS delivers pushes through Apple (APNs), and Firebase needs a key to talk to it.

1. <https://developer.apple.com/account> → **Certificates, Identifiers &
   Profiles** → **Keys** → **+** → tick **Apple Push Notifications service
   (APNs)** → download the `.p8` file (it can only be downloaded once) and note
   the **Key ID**. Your **Team ID** is `4M59KCDBT9`.
2. Firebase console → ⚙ **Project settings** → **Cloud Messaging** → **Apple
   app configuration** → **APNs Authentication Key** → upload the `.p8`, Key ID
   and Team ID.
3. Open `ios/Runner.xcworkspace` in Xcode → **Runner** target → **Signing &
   Capabilities**. The project already references `Runner/Runner.entitlements`
   with the Push capability and Background Modes → Remote notifications; Xcode
   should show both. If it offers to "fix" the provisioning profile, accept.

Push does **not** work in the iOS Simulator on older macOS — test on a real
iPhone.

## 4. Give the server its Firebase key

The Notification module reads its Firebase credentials from the database,
table `notification."FirebaseSettings"` (not from `appsettings.json`).

1. Firebase console → ⚙ **Project settings** → **Service accounts** →
   **Generate new private key** → a JSON file downloads. **This is a secret**:
   do not commit it, do not paste it into chat.
2. Check the table's exact columns first:

   ```sql
   SELECT column_name, data_type
   FROM information_schema.columns
   WHERE table_schema = 'notification' AND table_name = 'FirebaseSettings'
   ORDER BY ordinal_position;
   ```

3. Insert one row for tenant 1 (adjust to the columns step 2 printed):

   ```sql
   INSERT INTO notification."FirebaseSettings"
     ("Id", "ProjectId", "ServiceAccountJson", "ChannelId", "ChannelName",
      "TenantId", "IsDeleted", "IsDisabled", "NeedApprove", "IsApproved",
      "CreateDate", "LastModifiedDate")
   VALUES
     (gen_random_uuid(), '<your-firebase-project-id>', '<entire JSON file contents>',
      'app_default', 'App notifications',
      1, false, false, false, true, now(), now());
   ```

   `ChannelId` must stay `app_default` — the Android app creates that channel.

4. Restart the API.

The e-mail sender lives next door in `notification."EmailSettings"`
(`Host`, `Port`, `User`, `Password`, `FromAddress`, `FromName`, `UseSsl`).
That empty table is why e-mail codes failed with *"not in the form required
for an e-mail address"* — the From address was blank.

---

## Checking it works

1. Run the app on a real device, sign in, and accept the notification prompt.
   The log should show `[fcm] permission: authorized` and a
   `POST /api/Notification/UpdateNID` that returns 200.
2. The server has a test endpoint: `POST /api/Notification/TestNotification`
   with the signed-in user's bearer. A banner should arrive.
3. From a second account, like one of the first account's posts. Within five
   minutes the first device gets the push, and tapping it opens that post.
   Five minutes is the server's dispatch sweep (`*/5 * * * *` in
   `RoboByteSocialMediaExtensions.cs`) — pushes are queued with the like and
   delivered in batches, so a like never fails because Firebase is slow.

## What the app does with a push

| Server route | Opens |
|---|---|
| `/posts/{id}` (likes, comments, mentions) | the post |
| `/profiles/{id}` (follows, connections) | that person's profile |
| `/conversations` (messages) | messages |
| anything else | the notifications inbox |

The prompt is shown after sign-in, not on first launch — asking before the
person is inside the app gets refused far more often, and on iOS a refusal is
permanent until they change it in Settings.
