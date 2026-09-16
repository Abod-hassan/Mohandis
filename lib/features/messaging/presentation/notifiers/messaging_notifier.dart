import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../data/repositories/messaging_repository_impl.dart';
import '../../domain/entities/message_thread.dart';

class ThreadsNotifier extends AsyncNotifier<List<MessageThread>> {
  @override
  Future<List<MessageThread>> build() async {
    final result = await ref.read(messagingRepositoryProvider).threads();
    return result.when(success: (t) => t, failure: (e) => throw e);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(messagingRepositoryProvider).threads();
      return result.when(success: (t) => t, failure: (e) => throw e);
    });
  }

  /// Clears the unread badge as soon as the thread opens, then confirms with
  /// the server. A failed receipt leaves the badge cleared locally — an
  /// unread count that reappears mid-read is worse than a stale one.
  Future<void> markRead(String threadId) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data([
        for (final t in current)
          if (t.id == threadId) t.copyWith(unreadCount: 0) else t,
      ]);
    }
    await ref.read(messagingRepositoryProvider).markRead(threadId);
  }

  /// Moves one row's preview to the message just sent.
  ///
  /// Only the preview fields are touched. The thread screen's copy is not a
  /// substitute for the list's row: it still carries the unread count from
  /// before the thread was opened, and when the conversation row was past the
  /// scan window it is a header synthesised from the messages — no title, no
  /// admin flag. Splicing that in whole loses a group's name.
  void applyLastMessage(String threadId, Message message) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final t in current)
        if (t.id == threadId)
          t.copyWith(
            lastMessagePreview: message.text,
            lastMessageAt: message.sentAt,
          )
        else
          t,
    ]);
  }
}

final threadsNotifierProvider =
    AsyncNotifierProvider<ThreadsNotifier, List<MessageThread>>(
  ThreadsNotifier.new,
);

/// Total unread messages across every conversation — drives the top-bar dot.
final unreadThreadCountProvider = Provider<int>((ref) {
  final threads = ref.watch(threadsNotifierProvider).valueOrNull;
  if (threads == null) return 0;
  return threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
});

class ThreadNotifier
    extends AutoDisposeFamilyAsyncNotifier<MessageThread, String> {
  @override
  Future<MessageThread> build(String threadId) async {
    final result = await ref.read(messagingRepositoryProvider).thread(threadId);
    return result.when(success: (t) => t, failure: (e) => throw e);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(messagingRepositoryProvider).thread(arg);
      return result.when(success: (t) => t, failure: (e) => throw e);
    });
  }

  Future<Result<Message, AppException>> send(String text) async {
    final result = await ref
        .read(messagingRepositoryProvider)
        .send(threadId: arg, text: text);
    result.when(
      success: (message) {
        final current = state.valueOrNull;
        if (current == null) return;
        // History is oldest-first, so a new message goes on the end. The
        // preview fields move with it here and on the list's own row: neither
        // is going to re-read to catch up.
        final next = current.copyWith(
          messages: [...current.messages, message],
          lastMessagePreview: message.text,
          lastMessageAt: message.sentAt,
        );
        state = AsyncValue.data(next);
        ref
            .read(threadsNotifierProvider.notifier)
            .applyLastMessage(arg, message);
      },
      failure: (_) {},
    );
    return result;
  }
}

/// Disposed with the last screen watching it, so reopening a thread re-reads
/// its history. Kept alive it would serve the page loaded on the first open
/// for the life of the app — every message that arrived in between missing.
final threadNotifierProvider =
    AsyncNotifierProvider.autoDispose
        .family<ThreadNotifier, MessageThread, String>(ThreadNotifier.new);
