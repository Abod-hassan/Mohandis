import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/router/app_router.dart';
import 'package:mohandis/features/shared/auth/presentation/notifiers/auth_notifier.dart';

import '../data/fcm_setup_service.dart';

/// Starts push notifications once, for the life of the app.
///
/// `FcmSetupService` was complete — permission, the Android channel,
/// foreground banners, cold- and warm-start taps, token rotation — and
/// nothing ever called its `init()`. So no permission prompt, no channel, no
/// listener, and a tap that launched the app went nowhere. Watching this from
/// `App` is what finally switches it on.
///
/// A no-op until Firebase is configured for the build (see bootstrap), so the
/// app keeps running exactly as before on a machine without the config files.
final pushSetupProvider = FutureProvider<void>((ref) async {
  if (Firebase.apps.isEmpty) {
    if (kDebugMode) {
      debugPrint('[push] Firebase is not configured for this build — skipped');
    }
    return;
  }

  final fcm = ref.read(fcmSetupServiceProvider);
  final router = ref.read(appRouterProvider);

  // Before init(): init() handles the cold-start tap itself, and a handler
  // registered afterwards would miss the one tap that launched the app.
  fcm.onNotificationTapped(
    (data) => _openWhenReady(ref, router, appRouteFor(data)),
  );
  await fcm.init();
});

/// Where a notification's payload should take the person.
///
/// The server addresses routes in ITS vocabulary (`SocialNotifier.RouteFor`),
/// which is not this app's: `/posts/{id}` lives under the feed here,
/// `/profiles/{id}` is singular, and `/conversations` is `/messages`.
/// Anything unrecognised opens the notifications inbox rather than nothing —
/// a tap that does nothing reads as a broken app.
@visibleForTesting
String appRouteFor(Map<String, String> data) {
  final raw = (data['route'] ?? data['Route'] ?? '').trim();
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.pathSegments.isEmpty) return '/notifications';

  final segments = uri.pathSegments;
  final query = uri.hasQuery ? '?${uri.query}' : '';

  switch (segments.first) {
    case 'posts' when segments.length >= 2:
      return '/feed/posts/${segments[1]}$query';
    case 'profiles' when segments.length >= 2:
      return '/profile/${segments[1]}';
    case 'conversations':
      return segments.length >= 2 ? '/messages/${segments[1]}' : '/messages';
    case 'notifications':
      return '/notifications';
    default:
      return '/notifications';
  }
}

/// Navigates once the app is somewhere a notification can be opened FROM.
///
/// A tap that cold-starts the app arrives while the router is still on
/// `/splash` and the session is still being restored. Splash then calls
/// `go('/feed')` on its own, which would silently throw away anything pushed
/// before it — so the navigation waits for a signed-in person on an ordinary
/// screen. `push`, not `go`, so back returns to the app rather than closing it.
///
/// Gives up after a minute: a tap that could not be honoured by then — the
/// person was signed out and did not sign back in — should not pop up in the
/// middle of whatever they are doing later.
void _openWhenReady(Ref ref, GoRouter router, String route) {
  bool ready() {
    final authed = ref.read(authNotifierProvider).valueOrNull != null;
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    return authed &&
        loc != '/splash' &&
        loc != '/auth' &&
        !loc.startsWith('/auth/') &&
        loc != '/onboarding/profile';
  }

  if (ready()) {
    router.push(route);
    return;
  }

  late final VoidCallback listener;
  Timer? expiry;
  void stop() {
    router.routerDelegate.removeListener(listener);
    expiry?.cancel();
  }

  listener = () {
    if (!ready()) return;
    stop();
    // After the frame: this runs inside the delegate's own notification,
    // and navigating from there re-enters it.
    WidgetsBinding.instance.addPostFrameCallback((_) => router.push(route));
  };
  router.routerDelegate.addListener(listener);
  expiry = Timer(const Duration(minutes: 1), stop);
}
