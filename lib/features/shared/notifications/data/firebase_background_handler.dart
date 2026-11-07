import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohandis/firebase_options.dart';

/// Background message handler for `firebase_messaging`.
///
/// **Wiring** — registered ONCE from `bootstrap()` via
/// `FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler)`.
/// Must be a top-level function (not a method or closure) because
/// Android executes it in a separate isolate via the Flutter engine's
/// background-isolate entrypoint.
///
/// **Isolation rules** — the handler runs in a **separate Dart
/// isolate** with no access to the main isolate's memory:
///   * Riverpod providers are unreachable — every `ref.read` would
///     hit a fresh ProviderContainer with default state.
///   * GoRouter / Navigator are unreachable — there is no widget tree.
///   * Any `Firebase.initializeApp()` made on the main side hasn't
///     propagated; we re-init here as a no-op (idempotent).
///
/// The handler's only job is to **persist the payload** to
/// SharedPreferences (a process-wide store), and trust the main
/// isolate to drain it via [drainPendingNotifications] on next
/// foreground resume.
///
/// **Pragma is required** — `@pragma('vm:entry-point')` keeps the
/// function from being tree-shaken in release builds; without it the
/// Flutter engine can't find the entrypoint when starting the
/// background isolate and the handler silently never fires.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Re-init Firebase — required because each background isolate boots
  // cold. `Firebase.initializeApp` is idempotent when called against
  // an already-initialised default app, so this is safe to call
  // unconditionally.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[fcm-bg] Firebase.initializeApp failed: $e');
    }
    // Continue — the queue write below is the critical side effect
    // and doesn't depend on Firebase being initialised.
  }
  await queuePendingPayload(_payloadFromMessage(message));
}

/// Flatten a RemoteMessage's user-data + notification metadata into a
/// single `Map<String, String>` that survives JSON encoding. Drops the
/// `notification` block from the data side once we've extracted the
/// title/body (Android shows the system notification on its own when
/// the payload includes a `notification` block, so we just record
/// what was shown for the foreground drain).
Map<String, String> _payloadFromMessage(RemoteMessage message) {
  final out = <String, String>{};
  // Server-supplied data fields take precedence.
  message.data.forEach((key, value) {
    out[key.toString()] = value?.toString() ?? '';
  });
  // Always carry the message id so the foreground side can de-dupe.
  out['_messageId'] = message.messageId ?? '';
  // Best-effort capture of the notification block when the server
  // sent one — useful for the foreground drain to render a banner
  // even if the data side was empty.
  final notif = message.notification;
  if (notif != null) {
    if (notif.title != null) out['_title'] = notif.title!;
    if (notif.body != null) out['_body'] = notif.body!;
  }
  // sentTime helps the main isolate decide whether a queued message
  // is stale enough to skip.
  if (message.sentTime != null) {
    out['_sentAt'] = message.sentTime!.toUtc().toIso8601String();
  }
  return out;
}

// ── Queue (process-wide, isolate-safe) ──────────────────────────────

const _kPendingKey = 'notifications.pending';

Future<void> queuePendingPayload(Map<String, String> data) async {
  final prefs = await SharedPreferences.getInstance();
  final pending = prefs.getStringList(_kPendingKey) ?? <String>[];
  pending.add(jsonEncode(data));
  await prefs.setStringList(_kPendingKey, pending);
}

/// Pull every queued payload + clear the queue. Called from the main
/// isolate on foreground resume (`AppLifecycleState.resumed`) and once
/// during bootstrap to handle the cold-start case where messages
/// arrived while the app was completely terminated.
Future<List<Map<String, String>>> drainPendingNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_kPendingKey) ?? <String>[];
  await prefs.remove(_kPendingKey);
  return raw.map((s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return <String, String>{};
  }).toList(growable: false);
}
