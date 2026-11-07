import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/features/shared/auth/presentation/notifiers/auth_notifier.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';

import '../../domain/entities/message_thread.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../dtos/message_thread_dto.dart';

/// Messaging against the RoboByte.SocialMedia module's
/// `ConversationsController`.
///
/// Three things about this API shape drive the whole class:
///
///   * **Every response is a `ResultViewModel` envelope**, unwrapped by
///     [apiCall]. A 200 can still carry `error: true` — "You are not a
///     participant of this conversation." arrives that way.
///   * **The caller is never marked in the payload.** Participants include the
///     signed-in user with nothing to distinguish them, and a message says who
///     sent it but not whether that was you. Both answers need the caller's
///     own ProfileId, which the JWT does not carry (it holds an auth
///     ContactId — a different key), so it is resolved once through
///     `currentPersonProvider` and stamped on at decode time.
///   * **There is no `GET Conversations/{id}`.** A conversation row only ever
///     comes out of the caller's own list, or out of a write that answers with
///     the conversation it just changed, which is why [thread] costs two
///     reads — see [_findConversation].
///
/// `viewerProfileId` is set server-side from the bearer token and is never
/// sent from here.
class MessagingRepositoryImpl implements MessagingRepository {
  MessagingRepositoryImpl({
    required ApiClient apiClient,
    required Future<String> Function() resolveViewerId,
  }) : _api = apiClient,
       _resolveViewerId = resolveViewerId;

  final ApiClient _api;
  final Future<String> Function() _resolveViewerId;

  /// Resolved ProfileId, held for the life of the repository — every read
  /// needs it, and it cannot change without a new session. The provider ties
  /// this instance to that session so the cache cannot outlive it.
  String? _viewerId;

  static const int _defaultThreadPageSize = 20;
  static const int _defaultMessagePageSize = 30;

  /// How far [_findConversation] will page looking for one thread's row, and
  /// how many rows it asks for at a time.
  static const int _scanPages = 5;
  static const int _scanPageSize = 50;

  // ── Threads ──────────────────────────────────────────────────────────────

  @override
  Future<Result<List<MessageThread>, AppException>> threads({
    int page = 1,
    int size = _defaultThreadPageSize,
  }) async {
    final viewer = await _viewer();
    return apiCall(
      EndPoints.conversations,
      () => _api.dio.get<dynamic>(
        EndPoints.conversations,
        queryParameters: {'page': page, 'size': size},
      ),
      (envelope) => _conversations(envelope, viewer),
    );
  }

  /// A thread plus its newest page of history.
  ///
  /// The two halves come from different endpoints and neither can serve the
  /// other's data, so both go out at once rather than in sequence — this is on
  /// the path of every thread open.
  @override
  Future<Result<MessageThread, AppException>> thread(String threadId) async {
    final viewer = await _viewer();
    final historyRequest = messages(threadId);
    final rowRequest = _findConversation(threadId, viewer);

    final history = await historyRequest;
    final row = await rowRequest;

    // Only the history is load-bearing: a thread that cannot show its messages
    // has nothing to render. A missing conversation row costs a title and an
    // unread count, which the fallback can approximate.
    final failure = history.errorOrNull;
    if (failure != null) return Result.failure(failure);

    final loaded = history.valueOrNull ?? const <Message>[];
    final found = row ?? _threadFromMessages(threadId, loaded, viewer);
    return Result.success(found.copyWith(messages: loaded));
  }

  /// Finds one conversation row by paging the caller's own list.
  ///
  /// The module has no single-conversation read: `SingleConversationAsync`
  /// exists server-side but is only ever returned from `Start`, `Rename` and
  /// `AddParticipants` — all of which need a conversation to already be in
  /// hand.
  /// The list is ordered by last activity, so a thread being opened is almost
  /// always on the first page — the scan is bounded at [_scanPages] so a
  /// pathological account cannot turn one screen open into dozens of requests.
  ///
  /// Answers `null` — never a failure — when the row does not turn up, whether
  /// because it is past the window or because the list read failed outright:
  /// [thread] degrades to a header built from the messages themselves, and
  /// surfacing this error would fail a screen that has what it needs.
  Future<MessageThread?> _findConversation(
    String threadId,
    String viewer,
  ) async {
    for (var page = 1; page <= _scanPages; page++) {
      final result = await apiCall(
        EndPoints.conversations,
        () => _api.dio.get<dynamic>(
          EndPoints.conversations,
          queryParameters: {'page': page, 'size': _scanPageSize},
        ),
        (envelope) => (
          rows: _conversations(envelope, viewer),
          // `IPagedList` paging metadata rides on the envelope, not inside
          // `data` — an exhausted list is how this loop ends early.
          hasMore: envelope.hasMore,
        ),
      );

      final slice = result.valueOrNull;
      if (slice == null) return null;

      for (final thread in slice.rows) {
        if (thread.id == threadId) return thread;
      }
      if (!slice.hasMore) break;
    }
    return null;
  }

  /// Last-resort thread header, reconstructed from the history alone.
  ///
  /// Only reached when the conversation row is beyond the scan window. The
  /// senders are the only participants that can be named, so a group nobody
  /// but one person has written in reads as a direct thread, and the caller is
  /// absent from [MessageThread.participants] — which the real payload
  /// includes. Everything the screen actually renders still resolves.
  MessageThread _threadFromMessages(
    String threadId,
    List<Message> loaded,
    String viewer,
  ) {
    final senders = <String, ThreadParticipant>{};
    for (final message in loaded) {
      if (message.senderId == viewer || senders.containsKey(message.senderId)) {
        continue;
      }
      senders[message.senderId] = ThreadParticipant(
        id: message.senderId,
        name: message.senderName,
        avatarUrl: message.senderAvatarUrl,
      );
    }
    return MessageThread(
      id: threadId,
      kind: senders.length > 1 ? ThreadKind.group : ThreadKind.direct,
      participants: senders.values.toList(growable: false),
      viewerId: viewer,
    );
  }

  @override
  Future<Result<MessageThread, AppException>> start({
    required List<String> personIds,
    String? title,
  }) async {
    final viewer = await _viewer();
    return apiCall(
      EndPoints.conversationsStart,
      () => _api.dio.post<dynamic>(
        EndPoints.conversationsStart,
        data: {
          // The caller is added server-side; sending them is harmless (they
          // are de-duplicated) but sending ONLY them is rejected.
          'participantIds': personIds,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        },
      ),
      (envelope) => _conversation(envelope, viewer),
    );
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Message>, AppException>> messages(
    String threadId, {
    int page = 1,
    int size = _defaultMessagePageSize,
  }) async {
    final viewer = await _viewer();
    final path = EndPoints.conversationMessages(threadId);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(
        path,
        queryParameters: {'page': page, 'size': size},
      ),
      (envelope) {
        // The controller builds its own `MessageFilter` and never exposes the
        // ordering, so this always comes back NEWEST FIRST — page 1 is the end
        // of the thread, reversed. Flipping it here is what lets the screen
        // render straight down the list and scroll to the bottom.
        final rows = envelope.list
            .map((j) => MessageDto.fromJson(j).toDomain(viewer))
            .toList();
        return rows.reversed.toList(growable: false);
      },
    );
  }

  @override
  Future<Result<Message, AppException>> send({
    required String threadId,
    required String text,
    String? replyToMessageId,
  }) async {
    final viewer = await _viewer();
    final path = EndPoints.conversationMessages(threadId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {
          'content': text,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        },
      ),
      (envelope) => _message(envelope, viewer),
    );
  }

  @override
  Future<Result<Message, AppException>> editMessage(
    String messageId,
    String text,
  ) async {
    final viewer = await _viewer();
    final path = EndPoints.messageEdit(messageId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, data: {'content': text}),
      (envelope) => _message(envelope, viewer),
    );
  }

  /// Answers with a bare `true`, not the tombstone — see the interface.
  @override
  Future<Result<void, AppException>> retractMessage(String messageId) {
    final path = EndPoints.messageRetract(messageId);
    return apiCall(path, () => _api.dio.post<dynamic>(path), (_) {});
  }

  @override
  Future<Result<Message, AppException>> react(
    String messageId,
    String? emoji,
  ) async {
    final viewer = await _viewer();
    final path = EndPoints.messageReact(messageId);
    return apiCall(
      path,
      // A null emoji is the documented way to take a reaction back, so it is
      // sent rather than omitted — an absent key would deserialise the same
      // way, but only by accident.
      () => _api.dio.post<dynamic>(path, data: {'emoji': emoji}),
      (envelope) => _message(envelope, viewer),
    );
  }

  // ── Read state ───────────────────────────────────────────────────────────

  /// Moves the caller's read position to now, which is the only thing that
  /// clears an unread count — marking individual messages is not a concept
  /// this backend has.
  @override
  Future<Result<void, AppException>> markRead(String threadId) {
    final path = EndPoints.conversationRead(threadId);
    return apiCall(path, () => _api.dio.post<dynamic>(path), (_) {});
  }

  // ── Membership ───────────────────────────────────────────────────────────

  @override
  Future<Result<void, AppException>> setMuted(
    String threadId, {
    required bool muted,
  }) {
    final path = EndPoints.conversationMute(threadId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, queryParameters: {'muted': muted}),
      (_) {},
    );
  }

  @override
  Future<Result<void, AppException>> leave(String threadId) {
    final path = EndPoints.conversationLeave(threadId);
    return apiCall(path, () => _api.dio.post<dynamic>(path), (_) {});
  }

  @override
  Future<Result<MessageThread, AppException>> rename(
    String threadId,
    String title,
  ) async {
    final viewer = await _viewer();
    final path = EndPoints.conversationRename(threadId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, data: {'title': title}),
      (envelope) => _conversation(envelope, viewer),
    );
  }

  @override
  Future<Result<MessageThread, AppException>> addParticipants(
    String threadId,
    List<String> personIds,
  ) async {
    final viewer = await _viewer();
    final path = EndPoints.conversationParticipants(threadId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, data: {'profileIds': personIds}),
      // Answers the conversation as it now stands, the same way `Rename` does —
      // it is not one of the void-returning membership calls.
      (envelope) => _conversation(envelope, viewer),
    );
  }

  @override
  Future<Result<void, AppException>> removeParticipant(
    String threadId,
    String personId,
  ) {
    final path = EndPoints.conversationParticipant(threadId, personId);
    return apiCall(path, () => _api.dio.delete<dynamic>(path), (_) {});
  }

  // ── Decoders ─────────────────────────────────────────────────────────────

  /// The signed-in user's ProfileId.
  ///
  /// Resolving it can fail (no profile for this account, or the network is
  /// down) — in which case an empty id is used rather than failing the read
  /// outright: a thread list where nothing is recognised as "mine" still shows
  /// every message, and the request that follows will report the real problem
  /// on its own.
  Future<String> _viewer() async {
    final cached = _viewerId;
    if (cached != null) return cached;
    try {
      final resolved = await _resolveViewerId();
      _viewerId = resolved;
      return resolved;
    } catch (_) {
      return '';
    }
  }

  List<MessageThread> _conversations(ApiEnvelope envelope, String viewer) =>
      envelope.list
          .map((j) => ConversationDto.fromJson(j).toDomain(viewer))
          .toList(growable: false);

  /// A conversation, or a failure when the envelope did not carry one.
  ///
  /// `object` answers `{}` for a `true` or a null payload, and every field
  /// then decodes to its default — an id-less thread that reads as a success
  /// all the way up to a screen with nothing to show.
  MessageThread _conversation(ApiEnvelope envelope, String viewer) {
    final json = envelope.object;
    if ('${json['id'] ?? ''}'.isEmpty) {
      throw const NotFoundException('Conversation not found');
    }
    return ConversationDto.fromJson(json).toDomain(viewer);
  }

  /// A message, or a failure when the envelope did not carry one. Same trap as
  /// [_conversation]: an empty payload decodes to a blank bubble stamped
  /// `DateTime.now()`, appended to the thread as though it had sent.
  Message _message(ApiEnvelope envelope, String viewer) {
    final json = envelope.object;
    if ('${json['id'] ?? ''}'.isEmpty) {
      throw const NotFoundException('Message not found');
    }
    return MessageDto.fromJson(json).toDomain(viewer);
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  // Rebuilt when the signed-in account changes, discarding the memoised
  // ProfileId with it. Sign out as one person and in as another and a surviving
  // instance would answer `isMine` against the first account for every message
  // the second one reads. Only the id is watched — a token refresh replaces the
  // session object without changing whose it is.
  ref.watch(authNotifierProvider.select((s) => s.valueOrNull?.user.id));
  return MessagingRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    // Read lazily rather than watched: the id is wanted at call time, and a
    // repository that rebuilt whenever the profile refreshed would drop the
    // notifiers holding it. `currentPersonProvider` caches for the session, so
    // this is one request per sign-in, not one per read.
    resolveViewerId: () async =>
        (await ref.read(currentPersonProvider.future)).id,
  );
});
