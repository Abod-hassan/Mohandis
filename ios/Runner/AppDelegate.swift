import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ask APNs for a device token explicitly.
    //
    // firebase_messaging does this too, from `requestPermission` — but only
    // once Dart has run and the user has answered the prompt. Asking here as
    // well costs nothing (the call is idempotent, and iOS answers on a
    // previously-authorised install without prompting) and it means the
    // token is usually waiting by the time Dart asks for it.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - APNs diagnostics
  //
  // Both overrides call `super`, which is what keeps Firebase's swizzled
  // implementation in the chain — without it FCM would never see the token.
  // They exist because a silent failure here is indistinguishable, from
  // Dart, from "APNs is just slow": `getAPNSToken()` returns null either
  // way. Apple's own error message is the one thing that says which.

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    print("[apns] device token received (\(hex.count / 2) bytes)")
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // The message to read. "no valid aps-environment entitlement string
    // found" means the entitlement did not make it into the signed binary;
    // a network error means the device could not reach Apple.
    print("[apns] registration FAILED: \(error.localizedDescription)")
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
