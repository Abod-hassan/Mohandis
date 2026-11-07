import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/message_thread.dart';

/// Messaging, as the module's `ConversationsController` exposes it.
///
/// Two shapes of the backend leak into this contract and are worth knowing
/// before reading it:
///
///   * **A thread's metadata and its messages are separate reads.** There is
///     no `GET Conversations/{id}` — the conversation row (title, members,
///     unread count) only ever arrives inside the caller's conversation list.
///     [thread] papers over that; [messages] is the endpoint itself.
///   * **Read state is a position, not a receipt.** [markRead] moves the
///     caller's read pointer to now, which is what clears an unread count;
///     `Message.read` is derived from everyone else's pointer, so it can only
///     ever be a whole-thread answer.
abstract class MessagingRepository {
  /// One page of the caller's threads, newest activity first. Carries no
  /// messages — only `lastMessagePreview`.
  Future<Result<List<MessageThread>, AppException>> threads({
    int page = 1,
    int size = 20,
  });

  /// A thread with its most recent page of history.
  Future<Result<MessageThread, AppException>> thread(String threadId);

  /// One page of history, **oldest first within the page**.
  ///
  /// Page 1 is the newest [size] messages; page 2 the [size] before those. So
  /// paging backwards means asking for a higher page and prepending it.
  Future<Result<List<Message>, AppException>> messages(
    String threadId, {
    int page = 1,
    int size = 30,
  });

  Future<Result<Message, AppException>> send({
    required String threadId,
    required String text,
    String? replyToMessageId,
  });

  /// Clears the caller's unread count for [threadId].
  Future<Result<void, AppException>> markRead(String threadId);

  /// Opens a thread with [personIds] (which must not include the caller — the
  /// server adds them), returning the existing direct thread rather than a
  /// duplicate when there already is one.
  ///
  /// One other person makes a direct thread, more than one makes a group;
  /// [title] is kept only for a group.
  Future<Result<MessageThread, AppException>> start({
    required List<String> personIds,
    String? title,
  });

  /// Mutes or unmutes notifications for the caller. Unread counts keep
  /// accruing either way.
  Future<Result<void, AppException>> setMuted(
    String threadId, {
    required bool muted,
  });

  /// Leaves a group. A direct thread cannot be left.
  Future<Result<void, AppException>> leave(String threadId);

  /// Renames a group — admin only. Returns the thread as it now stands.
  Future<Result<MessageThread, AppException>> rename(
    String threadId,
    String title,
  );

  /// Adds people to a group — admin only.
  Future<Result<MessageThread, AppException>> addParticipants(
    String threadId,
    List<String> personIds,
  );

  /// Removes someone else from a group — admin only. Use [leave] for the
  /// caller themselves.
  Future<Result<void, AppException>> removeParticipant(
    String threadId,
    String personId,
  );

  /// Edits the caller's own message. Prior versions are not kept.
  Future<Result<Message, AppException>> editMessage(
    String messageId,
    String text,
  );

  /// Unsends the caller's own message. The row survives as a tombstone, so the
  /// thread must be re-read (or the message marked retracted locally) to see
  /// the result — the endpoint answers with a bare `true`.
  Future<Result<void, AppException>> retractMessage(String messageId);

  /// Applies, replaces, or — with a null or empty [emoji] — removes the
  /// caller's reaction. There is one reaction per person per message.
  Future<Result<Message, AppException>> react(String messageId, String? emoji);
}
