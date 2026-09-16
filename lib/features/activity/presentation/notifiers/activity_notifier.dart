import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/features/network/presentation/notifiers/network_notifier.dart';

import '../../data/repositories/activity_repository_impl.dart';
import '../../domain/entities/activity_notification.dart';

class ActivityNotifier extends AsyncNotifier<List<ActivityNotification>> {
  @override
  Future<List<ActivityNotification>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<ActivityNotification>> _load() async {
    final result = await ref.read(activityRepositoryProvider).all();
    return result.when(success: (items) => items, failure: (e) => throw e);
  }

  /// Marks one row read. Called when a notification is opened, which is the
  /// only way a single row is ever read — there is no per-row control.
  Future<Result<void, AppException>> markRead(String id) async {
    final previous = state.valueOrNull;
    if (previous == null) return const Result.success(null);
    // Already read: the server call is a no-op, so skip the round-trip rather
    // than firing one on every tap through to a profile or post.
    if (!previous.any((n) => n.id == id && n.unread)) {
      return const Result.success(null);
    }
    state = AsyncValue.data(_patch(previous, id, unread: false));

    final result = await ref.read(activityRepositoryProvider).markRead(id);
    if (result.isFailure) {
      state = AsyncValue.data(previous);
    } else {
      _invalidateBadge();
    }
    return result;
  }

  Future<Result<void, AppException>> markAllRead() async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(
        [for (final n in previous) n.copyWith(unread: false)],
      );
    }
    final result = await ref.read(activityRepositoryProvider).markAllRead();
    if (result.isFailure && previous != null) {
      state = AsyncValue.data(previous);
    } else if (result.isSuccess) {
      _invalidateBadge();
    }
    return result;
  }

  /// Accepts the connection request behind an inline notification. The row
  /// turns into a plain "now connected" entry and the network tab's pending
  /// list is refreshed so its badge stays truthful.
  Future<Result<void, AppException>> acceptConnection(
    String notificationId,
    String actorId,
    String connectedText,
  ) async {
    final result =
        await ref.read(networkNotifierProvider.notifier).accept(actorId);
    if (result.isSuccess) {
      await _resolveRequestRow(notificationId, text: connectedText);
    }
    return result;
  }

  /// Dismisses the request behind an inline notification. The row keeps its
  /// text — there is nothing new to say — but loses its buttons, so it cannot
  /// be answered twice.
  Future<Result<void, AppException>> ignoreConnection(
    String notificationId,
    String actorId,
  ) async {
    final result =
        await ref.read(networkNotifierProvider.notifier).ignore(actorId);
    if (result.isSuccess) await _resolveRequestRow(notificationId);
    return result;
  }

  /// Settles an answered request row: read, no longer actionable, and read on
  /// the server too — answering a request IS seeing it, and the row would
  /// otherwise keep its unread dot until the whole inbox was cleared.
  Future<void> _resolveRequestRow(String notificationId, {String? text}) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        _patch(
          current,
          notificationId,
          unread: false,
          actionable: false,
          text: text,
        ),
      );
    }
    await ref.read(activityRepositoryProvider).markRead(notificationId);
    _invalidateBadge();
  }

  List<ActivityNotification> _patch(
    List<ActivityNotification> items,
    String id, {
    bool? unread,
    bool? actionable,
    String? text,
  }) {
    return [
      for (final n in items)
        if (n.id == id)
          n.copyWith(unread: unread, actionable: actionable, text: text)
        else
          n,
    ];
  }

  /// The badge is served by its own endpoint, so read-state changes here have
  /// to tell it to refetch — nothing derives it from this list any more.
  void _invalidateBadge() => ref.invalidate(_serverUnreadCountProvider);
}

final activityNotifierProvider =
    AsyncNotifierProvider<ActivityNotifier, List<ActivityNotification>>(
  ActivityNotifier.new,
);

/// `GET Notifications/unread-count` — a single cached COUNT server-side.
///
/// Kept apart from [activityNotifierProvider] so the badge does not drag the
/// whole inbox down with it: the dashboard shows the dot without ever opening
/// the notifications screen.
final _serverUnreadCountProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(activityRepositoryProvider).unreadCount();
  return result.when(success: (count) => count, failure: (e) => throw e);
});

/// Unread count for the top-bar dot. Zero until the count has loaded, and
/// zero if it failed — a badge is not worth an error state.
final unreadActivityCountProvider = Provider<int>((ref) {
  return ref.watch(_serverUnreadCountProvider).valueOrNull ?? 0;
});
