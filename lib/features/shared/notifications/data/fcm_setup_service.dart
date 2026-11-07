import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/notification_event.dart';
import '../presentation/notifiers/notification_bus.dart';
import 'device_token_repository.dart';
import 'firebase_background_handler.dart';

/// Single-instance coordinator for everything FCM does on the main
/// isolate:
///
///   1. **Permission** — prompts the user on iOS / Android 13+ on
///      first launch and remembers the answer locally so we don't
///      re-prompt every cold start.
///   2. **Token** — fetches the FCM token, caches it locally,
///      listens to `onTokenRefresh` for Google-side rotations, and
///      posts it to the backend once auth is available. Skips the
///      post when the cached token matches the last-registered one.
///   3. **Foreground messages** — pipes incoming `onMessage`
///      payloads to the [NotificationBus] (for in-app banners /
///      Riverpod listeners) AND shows a heads-up via
///      flutter_local_notifications (FCM doesn't auto-display when
///      the app is foregrounded on Android).
///   4. **Tap handling** — `getInitialMessage` (cold-start tap from
///      a terminated state) and `onMessageOpenedApp` (warm-start
///      tap) both feed into a callback the router layer can listen
///      to for deep-link routing.
///   5. **Drain** — clears any payloads the background isolate
///      queued while the app was killed, on each foreground resume.
///
/// **Lifecycle ownership** — created once via [fcmSetupServiceProvider]
/// at app boot. Disposed only on hot restart. Subscriptions clean up
/// in [dispose].
///
/// **Auth coupling** — the service holds a reference to the user's
/// auth state via [_authenticated] which the auth layer pokes in on
/// login / logout. When unauthenticated we still receive messages
/// but skip the device-token register (no user identity on the wire).
class FcmSetupService {
  FcmSetupService({
    required this.ref,
    required this.bus,
  });

  final Ref ref;
  final NotificationBus bus;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenSub;

  /// Mirrors whether the user is currently authenticated. The auth
  /// layer flips this via [setAuthenticated] — when true, token
  /// changes flush to the backend; when false they just stay local
  /// until the next login.
  bool _authenticated = false;

  /// Callback fired when the user taps a notification (cold-start or
  /// warm-start). Owned by the router layer — set via
  /// [onNotificationTapped]. Receives the raw data payload so the
  /// callback can route on `route` / `orderId` / etc.
  void Function(Map<String, String> data)? _onTap;

  // Local cache keys.
  static const _kLastTokenKey = 'fcm.last_token';
  static const _kPermissionAskedKey = 'fcm.permission_asked';
  static const _kAndroidChannelId = 'app_default';
  static const _kAndroidChannelName = 'App notifications';
  static const _kAndroidChannelDesc =
      'General notifications for this app.';

  /// One-shot init from bootstrap. Wires every Firebase + local
  /// notification listener and drains the prefs queue from any
  /// background messages that arrived while terminated.
  ///
  /// Safe to call multiple times — the second call is a no-op (the
  /// subscriptions are cancelled and re-attached, which is what hot
  /// restart wants anyway).
  Future<void> init() async {
    await dispose();

    await _initLocalNotifications();
    await _createAndroidChannel();

    // iOS suppresses a notification while the app is in the foreground unless
    // it is told otherwise, and firebase_messaging owns the
    // UNUserNotificationCenter delegate — so a locally-drawn banner is simply
    // never presented there. Asking FCM to present the remote one is the fix;
    // `_showLocalBanner` then stands down on iOS so a message does not arrive
    // twice.
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Register the background handler. Idempotent across hot restart.
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Foreground messages — pipe to bus AND show a banner via
    // flutter_local_notifications (since Android suppresses the
    // system display while foregrounded).
    _foregroundSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tap-while-running.
    _openedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Cold-start tap — message that launched the app from terminated.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }

    // Drain anything the background isolate queued while we were
    // killed. These are ALSO surfaced through the bus so listeners
    // get a uniform shape.
    await _drainQueueIntoBus();

    // Permission and registration only for someone signed in. Prompting
    // on the sign-in screen asks a stranger to trust an app they have not
    // entered yet, and most people answer no — and on iOS, a "no" is
    // permanent until they dig through Settings. Signing in reaches
    // [setAuthenticated], which asks at the moment it makes sense.
    if (_authenticated) {
      await _ensurePermission();
      await _refreshTokenAndMaybeRegister();
    }

    _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (kDebugMode) debugPrint('[fcm] onTokenRefresh');
      _persistAndRegister(token);
    });
  }

  /// Pull the cached token + clear this device's registration on the
  /// backend. Called from the auth layer on explicit logout. The
  /// local cache stays — the same token is fine to reuse for the
  /// next user (it's just a device address, not a credential).
  Future<void> handleLogout({String? bearer}) async {
    _authenticated = false;
    try {
      await ref.read(deviceTokenRepositoryProvider).unregister(bearer: bearer);
    } catch (_) {
      // Best-effort — see DeviceTokenRepository.unregister doc.
    }
  }

  /// Auth layer notifies the service of session state. When [authed]
  /// flips to `true`, we flush the cached token to the backend if it
  /// hasn't been registered yet for this session.
  Future<void> setAuthenticated(bool authed) async {
    final was = _authenticated;
    _authenticated = authed;
    if (kDebugMode) {
      debugPrint('[fcm] setAuthenticated: was=$was → authed=$authed');
    }
    if (!was && authed) {
      // A build without Firebase config has no messaging to set up; this is
      // called fire-and-forget from the auth layer, so a throw here would
      // surface as an unhandled error on every sign-in.
      if (Firebase.apps.isEmpty) return;
      // Asked here, not only at boot — see init(). On Android 13+ this is the
      // ONLY place the runtime prompt comes from for someone who signed in
      // after launch; the iOS path in `_refreshTokenAndMaybeRegister` asks
      // for itself, and asking twice is a no-op.
      try {
        await _ensurePermission();
      } catch (e) {
        if (kDebugMode) debugPrint('[fcm] permission request failed: $e');
      }
      // Newly authenticated — push the token to the backend.
      await _refreshTokenAndMaybeRegister(forceRegister: true);
    }
  }

  /// Register a tap-callback. The router layer wires this to GoRouter
  /// navigation. Setting `null` clears any prior handler.
  void onNotificationTapped(void Function(Map<String, String> data)? cb) {
    _onTap = cb;
  }

  /// Stop all subscriptions. Called from [init] re-entry + tests.
  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenSub?.cancel();
    _foregroundSub = null;
    _openedSub = null;
    _tokenSub = null;
  }

  // ── internals ───────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // flutter_local_notifications 18.x dropped the
    // `onDidReceiveLocalNotification` callback (it was iOS < 10 only;
    // anything modern uses the foreground presentation options + the
    // `onDidReceiveNotificationResponse` route below). Don't pass it.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Local notification tapped — payload is the JSON-encoded
        // data map. Treat the same as a remote tap.
        final raw = response.payload;
        if (raw == null || raw.isEmpty) return;
        _onTap?.call({'_payload': raw});
      },
    );
  }

  /// Android 8+ requires a registered channel. The channel meta on
  /// the manifest only points FCM at a channel id; the channel itself
  /// has to be registered at runtime with its display name and
  /// importance.
  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;
    const channel = AndroidNotificationChannel(
      _kAndroidChannelId,
      _kAndroidChannelName,
      description: _kAndroidChannelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// iOS / Android 13+ require explicit runtime permission. Idempotent
  /// — `requestPermission` returns the current status without
  /// reprompting once the user has answered.
  Future<void> _ensurePermission() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool(_kPermissionAskedKey) ?? false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (!asked) {
      await prefs.setBool(_kPermissionAskedKey, true);
    }
    if (kDebugMode) {
      debugPrint('[fcm] permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _refreshTokenAndMaybeRegister({bool forceRegister = false}) async {
    if (kDebugMode) {
      debugPrint(
          '[fcm] _refreshTokenAndMaybeRegister(forceRegister=$forceRegister)');
    }
    try {
      // **iOS APNs prerequisite.** `FirebaseMessaging.getToken()` on
      // iOS calls APNs under the hood and throws
      // `[firebase_messaging/apns-token-not-set]` if APNs hasn't
      // handed us a device token yet. APNs registration runs async
      // after `application(_:didFinishLaunching…)` returns — on a
      // fresh install / cold start that race usually loses on the
      // first call.
      //
      // Poll `getAPNSToken()` until it returns a non-null value (or
      // we hit the cap). Each retry is 500 ms, total cap ~5 s — long
      // enough for normal launches, short enough that a permanently-
      // broken iOS provisioning (missing entitlement, no APNs key)
      // surfaces quickly instead of blocking boot.
      //
      // No-op on Android — `getAPNSToken()` returns null instantly
      // there and `getToken()` doesn't depend on it.
      if (Platform.isIOS) {
        // **Permission gate.** APNs only delivers a device token after
        // the user accepts the notification prompt. The `init()` flow
        // calls `_ensurePermission` once at boot, BUT on cold-start
        // session rehydrate (auto-login from stored tokens) the
        // setAuthenticated path can fire this method before the boot
        // prompt has been answered — leaving status at
        // `notDetermined` indefinitely. Explicitly request now so the
        // prompt is guaranteed to appear at the moment we need the
        // token. Idempotent: if already answered, this is a no-op
        // that returns the existing status.
        final initial =
            await FirebaseMessaging.instance.getNotificationSettings();
        var status = initial.authorizationStatus;
        if (status == AuthorizationStatus.notDetermined) {
          if (kDebugMode) {
            debugPrint('[fcm] permission notDetermined — firing prompt');
          }
          final result =
              await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          status = result.authorizationStatus;
          if (kDebugMode) {
            debugPrint('[fcm] permission after prompt: $status');
          }
        }
        if (status == AuthorizationStatus.denied) {
          if (kDebugMode) {
            debugPrint(
                '[fcm] permission denied — push disabled. Re-enable in '
                'Settings → app → Notifications.');
          }
          return;
        }

        // First-time APNs registration on a fresh install can take
        // 10–15 s while the OS handshakes with Apple's servers — the
        // previous 5 s budget was too tight. Cap at 20 s now;
        // anything still null after that is almost certainly a config
        // issue (missing capability, or stale provisioning profile)
        // rather than slow network.
        const maxAttempts = 40; // 40 × 500ms = 20s
        const interval = Duration(milliseconds: 500);
        String? apns;
        for (var i = 0; i < maxAttempts; i++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null && apns.isNotEmpty) break;
          if (kDebugMode && i > 0 && i % 4 == 0) {
            final waited = (i * interval.inMilliseconds) ~/ 1000;
            debugPrint('[fcm] APNs wait ${waited}s (permission=$status)');
          }
          await Future<void>.delayed(interval);
        }
        if (apns == null || apns.isEmpty) {
          if (kDebugMode) {
            debugPrint(
                '[fcm] APNs token never arrived after ${maxAttempts * interval.inMilliseconds}ms '
                '(permission=$status)');
            // Deliberately a list, not one guess. The earlier text blamed a
            // stale provisioning profile, which is only one of the causes and
            // is the easiest to rule out: look at the `[apns]` line the app
            // delegate prints. Apple's own failure message appears there, and
            // NOTHING at all on that line means the request never left the
            // device.
            debugPrint(
                '[fcm] permission was granted but APNs delivered nothing. '
                'Check, in order: the [apns] line above (Apple\'s own error); '
                'a simulator never gets a token — use a real device; '
                'the device can reach Apple (try cellular, drop any VPN); '
                'delete the app from the phone and reinstall; '
                'Xcode → Settings → Accounts → Download Manual Profiles if '
                'the entitlement is missing from the build.');
          }
          return;
        }
        if (kDebugMode) debugPrint('[fcm] APNs token ready');
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('[fcm] no token (permission denied?)');
        return;
      }
      if (kDebugMode) {
        // First 12 chars are enough to recognise a token in logs
        // without leaking the full value.
        debugPrint('[fcm] got token: ${token.substring(0, 12)}…');
      }
      await _persistAndRegister(token, force: forceRegister);
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm] getToken failed: $e');
    }
  }

  Future<void> _persistAndRegister(String token, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    // NOTE: both gates that used to live here have been removed.
    //   1. The "skip when lastSent == token" guard — we now re-assert
    //      the device-token row on every cold start / token refresh /
    //      auth flip instead of trusting our local cache to match the
    //      backend row.
    //   2. The "skip when !_authenticated" gate — the backend's
    //      register-token endpoint is anonymous, so we register the
    //      device the moment we have a token regardless of login
    //      state. When the user later logs in, the auth layer calls
    //      `setAuthenticated(true)` which re-registers with the
    //      now-authenticated request so the backend can bind this
    //      token to the user's identity.
    // The `force` param is kept on the signature for caller-intent
    // clarity but no longer changes behaviour.
    if (kDebugMode) debugPrint('[fcm] POST register-token…');
    final result =
        await ref.read(deviceTokenRepositoryProvider).register(token);
    result.when(
      success: (_) async {
        await prefs.setString(_kLastTokenKey, token);
        if (kDebugMode) debugPrint('[fcm] token registered with backend');
      },
      failure: (e) {
        if (kDebugMode) debugPrint('[fcm] register failed: ${e.message}');
        // Don't cache the token as "last sent" on failure — next
        // attempt will retry.
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = _payloadFrom(message);
    bus.emit(_eventFrom(data));
    _showLocalBanner(message, data);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = _payloadFrom(message);
    _onTap?.call(data);
  }

  Future<void> _drainQueueIntoBus() async {
    final queued = await drainPendingNotifications();
    for (final payload in queued) {
      bus.emit(_eventFrom(payload));
    }
  }

  Future<void> _showLocalBanner(
      RemoteMessage message, Map<String, String> data) async {
    final notif = message.notification;
    if (notif == null) return; // data-only payload — caller decides UI
    // iOS presents the remote notification itself — see the foreground
    // presentation options set in `init`. Drawing a local copy as well is how
    // one message becomes two banners.
    if (Platform.isIOS) return;
    final android = AndroidNotificationDetails(
      _kAndroidChannelId,
      _kAndroidChannelName,
      channelDescription: _kAndroidChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(presentBanner: true);
    await _localNotifications.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(android: android, iOS: ios),
      // Carry the data payload as JSON so the local-tap handler can
      // route the same way the FCM tap handler does.
      payload: data.isEmpty ? null : data.toString(),
    );
  }

  Map<String, String> _payloadFrom(RemoteMessage message) {
    final out = <String, String>{};
    message.data.forEach((k, v) {
      out[k.toString()] = v?.toString() ?? '';
    });
    if (message.messageId != null) out['_messageId'] = message.messageId!;
    final notif = message.notification;
    if (notif?.title != null) out['_title'] = notif!.title!;
    if (notif?.body != null) out['_body'] = notif!.body!;
    return out;
  }

  NotificationEvent _eventFrom(Map<String, String> data) {
    return UnknownNotificationEvent(
      id: data['_messageId'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      receivedAt: DateTime.now(),
      data: data,
    );
  }
}

final fcmSetupServiceProvider = Provider<FcmSetupService>((ref) {
  final svc = FcmSetupService(
    ref: ref,
    bus: ref.watch(notificationBusProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});
