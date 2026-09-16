import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_event.dart';

/// In-process event bus for notification payloads.
///
/// Background handlers must NOT touch Riverpod — they queue events into
/// SharedPreferences. The foreground calls `drainPendingNotifications()` on
/// resume and pushes parsed events through `NotificationBus.emit`. Widgets
/// listen with `ref.listen(notificationBusProvider, …)` and cancel in
/// `ref.onDispose`.
class NotificationBus {
  NotificationBus() : _controller = StreamController<NotificationEvent>.broadcast();

  final StreamController<NotificationEvent> _controller;

  Stream<NotificationEvent> get stream => _controller.stream;

  void emit(NotificationEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}

final notificationBusProvider = Provider<NotificationBus>((ref) {
  final bus = NotificationBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final notificationStreamProvider =
    StreamProvider<NotificationEvent>((ref) {
  return ref.watch(notificationBusProvider).stream;
});
