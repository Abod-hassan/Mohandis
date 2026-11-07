import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import 'package:mohandis/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';

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

  /// Clears the inbox because the person has OPENED it — badge, server rows and
  /// the highlights on screen, all three.
  ///
  /// It used to leave the local `unread` flags alone, so that "which of these
  /// are new?" stayed answerable for the visit. That reasoning assumed a next
  /// load would clear them; this provider is NOT autoDispose, so there is no
  /// next load — the same highlighted rows came back on every visit for the
  /// rest of the session, over a badge that said zero. A screen that
  /// contradicts itself is worse than one that forgets which rows were new.
  ///
  /// Optimistic, and rolled back on failure, because the highlight is now a
  /// claim about the server's state rather than a private note to the reader.
  ///
  /// Still a no-op when nothing is unread: this runs on every open, and the
  /// round-trip is only worth making when it would change something.
  Future<void> markAllReadOnOpen() async {
    final previous = state.valueOrNull;
    if (previous == null || !previous.any((n) => n.unread)) return;

    state = AsyncValue.data(
      [for (final n in previous) n.copyWith(unread: false)],
    );

    final result = await ref.read(activityRepositoryProvider).markAllRead();
    if (result.isFailure) {
      state = AsyncValue.data(previous);
    } else {
      _invalidateBadge();
    }
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

  /// Accepts the follow request behind an inline notification. The row turns
  /// into a plain entry and loses its buttons.
  ///
  /// Every actionable row is a follow request: connection rows never reach
  /// this list — see `ActivityNotificationDto.isHidden`.
  ///
  /// A request that has ALREADY been answered — from the Network screen,
  /// another device, or a sender who withdrew it — comes back "Request not
  /// found." That is not a failure worth a red toast: the outcome the person
  /// wanted may well have happened already, and the row was only showing
  /// buttons because it was stale. It is settled like a success and reported
  /// as [RequestOutcome.alreadyHandled].
  Future<Result<RequestOutcome, AppException>> acceptRequest(
    ActivityNotification item, {
    required String acceptedText,
  }) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .acceptFollowRequest(item.actorId);

    if (result.isSuccess) {
      await _resolveRequestRow(item.id, text: acceptedText);
      ref.invalidate(profileNotifierProvider);
      return const Result.success(RequestOutcome.done);
    }
    if (_isGone(result.errorOrNull)) {
      await _resolveRequestRow(item.id);
      return const Result.success(RequestOutcome.alreadyHandled);
    }
    return Result.failure(result.errorOrNull!);
  }

  /// Declines the request behind an inline notification. The row keeps its
  /// text — there is nothing new to say — but loses its buttons, so it cannot
  /// be answered twice. A request that is already gone is simply settled.
  Future<Result<RequestOutcome, AppException>> declineRequest(
    ActivityNotification item,
  ) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .rejectFollowRequest(item.actorId);

    if (result.isSuccess || _isGone(result.errorOrNull)) {
      await _resolveRequestRow(item.id);
      return Result.success(
        result.isSuccess ? RequestOutcome.done : RequestOutcome.alreadyHandled,
      );
    }
    return Result.failure(result.errorOrNull!);
  }

  /// The server's wording for a request that no longer exists.
  static bool _isGone(AppException? e) =>
      e != null && e.toString().toLowerCase().contains('request not found');

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

/// Re-reads the unread count — for screens that show the badge and want it
/// current after a pull-to-refresh or on coming back from the inbox, since
/// nothing pushes a new count to the client.
void refreshUnreadActivityCount(WidgetRef ref) =>
    ref.invalidate(_serverUnreadCountProvider);

/// How answering a request ended, when it did not fail.
enum RequestOutcome {
  /// This tap answered it.
  done,

  /// It had already been answered — elsewhere, earlier, or by its sender
  /// withdrawing it. The row is settled either way.
  alreadyHandled,
}
