import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../domain/entities/message_thread.dart';
import '../../domain/repositories/messaging_repository.dart';

/// In-memory messaging used while the backend is unreachable
/// (`AppConfig.useMockData`).
///
/// Mirrors the real backend's shape rather than a convenient one: participant
/// lists include the signed-in user, history is stored oldest-first, and read
/// state is a whole-thread position — the same rules the screens are written
/// against.
class MessagingMockRepository implements MessagingRepository {
  MessagingMockRepository({this.latency = const Duration(milliseconds: 200)})
    : _threads = _seed();

  final Duration latency;
  final List<MessageThread> _threads;

  int _sequence = 0;

  /// The demo cast's id for the signed-in user — `PeopleMockRepository.meId`.
  static const String _meId = 'me';

  Future<void> _wait() => Future<void>.delayed(latency);

  static const ThreadParticipant _me = ThreadParticipant(
    id: _meId,
    name: 'يوسف الحربي',
    username: 'yousef',
    headline: 'مصمم منتجات أول · التقنية المالية',
    verified: true,
  );

  static const Map<String, ThreadParticipant> _cast = {
    'amal': ThreadParticipant(
      id: 'amal',
      name: 'أمل العتيبي',
      username: 'amal',
      headline: 'مديرة هندسة في نورثويند',
      verified: true,
      isOnline: true,
    ),
    'dawood': ThreadParticipant(
      id: 'dawood',
      name: 'داوود الشمري',
      username: 'dawood',
      headline: 'أخصائي توظيف تقني · تالنت فورج',
    ),
    'reem': ThreadParticipant(
      id: 'reem',
      name: 'ريم القحطاني',
      username: 'reem',
      headline: 'عالمة بيانات أولى · هيلكس بايو',
      verified: true,
    ),
    'sara': ThreadParticipant(
      id: 'sara',
      name: 'سارة الدوسري',
      username: 'sara',
      headline: 'باحثة تجربة مستخدم · التقنية الصحية',
    ),
    'yara': ThreadParticipant(
      id: 'yara',
      name: 'يارا التميمي',
      username: 'yara',
      headline: 'استراتيجية علامة تجارية · المستهلك',
    ),
  };

  static List<MessageThread> _seed() {
    final now = DateTime.now();

    Message m(
      String id,
      String from,
      String text,
      Duration ago, {
      bool read = true,
    }) {
      final sender = from == _meId ? _me : _cast[from];
      return Message(
        id: id,
        senderId: from,
        senderName: sender?.name ?? '',
        text: text,
        sentAt: now.subtract(ago),
        isMine: from == _meId,
        read: read,
      );
    }

    MessageThread thread({
      required String id,
      required List<String> others,
      required List<Message> messages,
      String? title,
      int unreadCount = 0,
    }) {
      final last = messages.last;
      return MessageThread(
        id: id,
        kind: others.length > 1 ? ThreadKind.group : ThreadKind.direct,
        title: title,
        participants: [_me, for (final o in others) _cast[o]!],
        messages: messages,
        lastMessagePreview: last.text,
        lastMessageAt: last.sentAt,
        unreadCount: unreadCount,
        // The demo user opened the demo group, so the management calls have
        // something to succeed against.
        isAdmin: others.length > 1,
        viewerId: _meId,
      );
    }

    return [
      thread(
        id: 't1',
        others: const ['amal'],
        unreadCount: 2,
        messages: [
          m(
            't1m1',
            'amal',
            'أهلاً يوسف! أعجبني منشورك عن أنظمة التصميم.',
            const Duration(hours: 5),
          ),
          m(
            't1m2',
            'amal',
            'هل لديك وقت لمحادثة قصيرة هذا الأسبوع؟ لدينا دور قد يناسبك تماماً.',
            const Duration(hours: 5),
          ),
          m(
            't1m3',
            _meId,
            'بالتأكيد — الخميس بعد الظهر يناسبني.',
            const Duration(hours: 4),
          ),
          m(
            't1m4',
            'amal',
            'ممتاز. سأرسل الدعوة. 🎉',
            const Duration(hours: 4),
            read: false,
          ),
        ],
      ),
      thread(
        id: 't2',
        others: const ['dawood'],
        messages: [
          m(
            't2m1',
            'dawood',
            'متابعة بخصوص وظيفة الواجهات — هل ما زلت مهتماً؟',
            const Duration(days: 1, hours: 2),
          ),
          m(
            't2m2',
            _meId,
            'نعم! قدّمت للتو. متحمس للفريق.',
            const Duration(days: 1, hours: 1),
          ),
        ],
      ),
      thread(
        id: 't3',
        others: const ['reem'],
        messages: [
          m(
            't3m1',
            _meId,
            'تلك التصورات كانت مذهلة 🔥',
            const Duration(days: 3, hours: 5),
          ),
          m(
            't3m2',
            'reem',
            'شكراً لك!! يسعدني مشاركة الدفتر البرمجي إن كان مفيداً.',
            const Duration(days: 3, hours: 4),
          ),
        ],
      ),
      thread(
        id: 'tg',
        others: const ['sara', 'yara'],
        title: 'مجلس المصممين ✦',
        unreadCount: 5,
        messages: [
          m(
            'tgm1',
            'sara',
            'من سيحضر اللقاء يوم الخميس؟',
            const Duration(hours: 7),
          ),
          m(
            'tgm2',
            'yara',
            'أنا! سأحجز المقاعد.',
            const Duration(hours: 6),
            read: false,
          ),
        ],
      ),
    ];
  }

  // ── Threads ──────────────────────────────────────────────────────────────

  @override
  Future<Result<List<MessageThread>, AppException>> threads({
    int page = 1,
    int size = 20,
  }) async {
    await _wait();
    final start = (page - 1) * size;
    if (start >= _threads.length) return const Result.success([]);
    final end = start + size;
    return Result.success(
      _threads.sublist(start, end > _threads.length ? _threads.length : end),
    );
  }

  @override
  Future<Result<MessageThread, AppException>> thread(String threadId) async {
    await _wait();
    return _onThread(threadId, (i) => Result.success(_threads[i]));
  }

  @override
  Future<Result<MessageThread, AppException>> start({
    required List<String> personIds,
    String? title,
  }) async {
    await _wait();
    final others = personIds.where((id) => id != _meId).toSet().toList();
    if (others.isEmpty) {
      return const Result.failure(
        ValidationException('أضف مشاركاً واحداً على الأقل'),
      );
    }
    final unknown = others.where((id) => !_cast.containsKey(id));
    if (unknown.isNotEmpty) {
      return Result.failure(
        NotFoundException('لا يوجد شخص بالمعرف ${unknown.first}'),
      );
    }

    // A direct thread is never duplicated — the existing one is handed back.
    if (others.length == 1) {
      for (final t in _threads) {
        if (!t.isGroup && t.counterpart?.id == others.first) {
          return Result.success(t);
        }
      }
    }

    final created = MessageThread(
      id: 'local-t${++_sequence}',
      kind: others.length > 1 ? ThreadKind.group : ThreadKind.direct,
      title: others.length > 1 ? title : null,
      participants: [_me, for (final id in others) _cast[id]!],
      // Whoever opened a group owns it.
      isAdmin: others.length > 1,
      viewerId: _meId,
    );
    _threads.insert(0, created);
    return Result.success(created);
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Message>, AppException>> messages(
    String threadId, {
    int page = 1,
    int size = 30,
  }) async {
    await _wait();
    return _onThread(threadId, (i) {
      // Page 1 is the NEWEST page, as it is on the real backend, so paging
      // walks backwards from the end of the stored (oldest-first) history.
      final all = _threads[i].messages;
      final end = all.length - (page - 1) * size;
      if (end <= 0) return const Result.success(<Message>[]);
      return Result.success(all.sublist(end - size < 0 ? 0 : end - size, end));
    });
  }

  @override
  Future<Result<Message, AppException>> send({
    required String threadId,
    required String text,
    String? replyToMessageId,
  }) async {
    await _wait();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(
        ValidationException('لا يمكن إرسال رسالة فارغة'),
      );
    }
    return _onThread(threadId, (i) {
      final thread = _threads[i];
      final quoted = _messageIn(thread, replyToMessageId);
      final message = Message(
        id: 'local-m${++_sequence}',
        threadId: threadId,
        senderId: _meId,
        senderName: _me.name,
        text: trimmed,
        sentAt: DateTime.now(),
        isMine: true,
        replyToMessageId: replyToMessageId,
        replyToPreview: quoted?.text,
        replyToSenderId: quoted?.senderId,
      );
      _threads[i] = thread.copyWith(
        messages: [...thread.messages, message],
        lastMessagePreview: message.text,
        lastMessageAt: message.sentAt,
      );
      return Result.success(message);
    });
  }

  @override
  Future<Result<Message, AppException>> editMessage(
    String messageId,
    String text,
  ) async {
    await _wait();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(
        ValidationException('لا يمكن إرسال رسالة فارغة'),
      );
    }
    return _replaceMessage(
      messageId,
      (m) => m.copyWith(text: trimmed, editedAt: DateTime.now()),
    );
  }

  @override
  Future<Result<void, AppException>> retractMessage(String messageId) async {
    await _wait();
    // A tombstone, not a deletion: the row still anchors replies.
    return _replaceMessage(
      messageId,
      (m) => m.copyWith(text: '', isRetracted: true),
    ).map<void>((_) {});
  }

  @override
  Future<Result<Message, AppException>> react(
    String messageId,
    String? emoji,
  ) async {
    await _wait();
    return _replaceMessage(messageId, (m) {
      // One reaction per person: mine comes out wherever it was before it goes
      // back in under the new emoji.
      final without = <MessageReaction>[
        for (final r in m.reactions)
          if (!r.reactedByMe)
            r
          else if (r.count > 1)
            MessageReaction(
              emoji: r.emoji,
              count: r.count - 1,
              profileIds: r.profileIds.where((id) => id != _meId).toList(),
            ),
      ];
      if (emoji == null || emoji.trim().isEmpty) {
        return m.copyWith(reactions: without);
      }
      MessageReaction? existing;
      for (final r in without) {
        if (r.emoji == emoji) {
          existing = r;
          break;
        }
      }
      return m.copyWith(
        reactions: [
          for (final r in without)
            if (r.emoji != emoji) r,
          MessageReaction(
            emoji: emoji,
            count: (existing?.count ?? 0) + 1,
            profileIds: [...?existing?.profileIds, _meId],
            reactedByMe: true,
          ),
        ],
      );
    });
  }

  // ── Read state ───────────────────────────────────────────────────────────

  @override
  Future<Result<void, AppException>> markRead(String threadId) async {
    await _wait();
    return _onThread<void>(threadId, (i) {
      _threads[i] = _threads[i].copyWith(unreadCount: 0);
      return const Result.success(null);
    });
  }

  // ── Membership ───────────────────────────────────────────────────────────

  @override
  Future<Result<void, AppException>> setMuted(
    String threadId, {
    required bool muted,
  }) async {
    await _wait();
    return _onThread<void>(threadId, (i) {
      _threads[i] = _threads[i].copyWith(isMuted: muted);
      return const Result.success(null);
    });
  }

  @override
  Future<Result<void, AppException>> leave(String threadId) async {
    await _wait();
    return _onThread<void>(threadId, (i) {
      if (!_threads[i].isGroup) {
        return const Result.failure(
          ValidationException('لا يمكن مغادرة محادثة فردية'),
        );
      }
      _threads.removeAt(i);
      return const Result.success(null);
    });
  }

  @override
  Future<Result<MessageThread, AppException>> rename(
    String threadId,
    String title,
  ) async {
    await _wait();
    return _onThread(threadId, (i) {
      final guard = _adminGuard(_threads[i]);
      if (guard != null) return Result.failure(guard);
      _threads[i] = _threads[i].copyWith(title: title);
      return Result.success(_threads[i]);
    });
  }

  @override
  Future<Result<MessageThread, AppException>> addParticipants(
    String threadId,
    List<String> personIds,
  ) async {
    await _wait();
    return _onThread(threadId, (i) {
      final thread = _threads[i];
      final guard = _adminGuard(thread);
      if (guard != null) return Result.failure(guard);
      final known = thread.participants.map((p) => p.id).toSet();
      final added = [
        for (final id in personIds)
          if (!known.contains(id) && _cast.containsKey(id)) _cast[id]!,
      ];
      _threads[i] = thread.copyWith(
        participants: [...thread.participants, ...added],
      );
      return Result.success(_threads[i]);
    });
  }

  @override
  Future<Result<void, AppException>> removeParticipant(
    String threadId,
    String personId,
  ) async {
    await _wait();
    return _onThread<void>(threadId, (i) {
      final thread = _threads[i];
      final guard = _adminGuard(thread);
      if (guard != null) return Result.failure(guard);
      if (personId == _meId) {
        return const Result.failure(
          ValidationException('استخدم المغادرة لإزالة نفسك'),
        );
      }
      _threads[i] = thread.copyWith(
        participants: thread.participants
            .where((p) => p.id != personId)
            .toList(growable: false),
      );
      return const Result.success(null);
    });
  }

  // ── Lookups ──────────────────────────────────────────────────────────────

  /// Runs [body] against the index of [id] in [_threads] — an index rather
  /// than the thread itself, because every write here replaces the row.
  Result<R, AppException> _onThread<R>(
    String id,
    Result<R, AppException> Function(int index) body,
  ) {
    final index = _threads.indexWhere((t) => t.id == id);
    if (index == -1) {
      return Result.failure(NotFoundException('لا توجد محادثة بالمعرف $id'));
    }
    return body(index);
  }

  Message? _messageIn(MessageThread thread, String? messageId) {
    if (messageId == null) return null;
    for (final message in thread.messages) {
      if (message.id == messageId) return message;
    }
    return null;
  }

  AppException? _adminGuard(MessageThread thread) {
    if (!thread.isGroup) {
      return const ValidationException('لا يمكن إدارة محادثة فردية');
    }
    if (!thread.isAdmin) {
      return const ForbiddenException('يمكن للمشرف وحده القيام بذلك');
    }
    return null;
  }

  /// Rewrites one message wherever it lives, keeping the thread's stored
  /// history in place.
  Result<Message, AppException> _replaceMessage(
    String messageId,
    Message Function(Message current) edit,
  ) {
    for (var i = 0; i < _threads.length; i++) {
      final thread = _threads[i];
      final index = thread.messages.indexWhere((m) => m.id == messageId);
      if (index == -1) continue;
      final updated = edit(thread.messages[index]);
      final messages = [...thread.messages];
      messages[index] = updated;
      _threads[i] = thread.copyWith(messages: messages);
      return Result.success(updated);
    }
    return Result.failure(
      NotFoundException('لا توجد رسالة بالمعرف $messageId'),
    );
  }
}
