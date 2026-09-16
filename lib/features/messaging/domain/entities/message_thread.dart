import 'package:flutter_mobile_template/core/base/base_entity.dart';

/// `ConversationTypeEnum` — a thread is either one-to-one or a named group.
///
/// The distinction is the server's, not a guess from the title: a group can be
/// created without one, and only a group can be renamed, left, or have members
/// added.
enum ThreadKind { direct, group }

/// One member of a thread — the module's `ProfileSimplifiedDto`.
///
/// Carried on the thread rather than looked up in the people directory: that
/// directory is a single page of profiles, so a participant is as likely to be
/// missing from it as not.
class ThreadParticipant {
  const ThreadParticipant({
    required this.id,
    required this.name,
    this.username = '',
    this.headline,
    this.avatarUrl,
    this.verified = false,
    this.isOnline = false,
    this.lastSeenAt,
  });

  /// The ProfileId — the module's user key, and what every messaging call
  /// addresses people by.
  final String id;

  final String name;
  final String username;

  /// Null on every conversation read: the module builds participants from a
  /// projection that omits the headline. Never make it the only subtitle a row
  /// has.
  final String? headline;

  final String? avatarUrl;
  final bool verified;

  /// Live presence, resolved server-side per request — a snapshot, not a
  /// subscription. It goes stale the moment the response lands.
  final bool isOnline;

  /// Omitted while they are online, and null for someone who has never
  /// connected.
  final DateTime? lastSeenAt;

  /// Two-letter monogram, drawn as a seeded gradient when there is no photo —
  /// and underneath one while it loads, so a dead link degrades to initials.
  String get initials => _monogram(name);
}

/// Two-letter monogram for an avatar, mirroring `Person.initials` so a
/// participant looks the same here as anywhere else in the app.
String _monogram(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '؟';
  if (parts.length == 1) {
    final only = parts.first;
    return only.length <= 2 ? only : only.substring(0, 2);
  }
  return '${parts.first[0]}${parts.last[0]}';
}

/// A photo or video sent with a message.
class MessageAttachment {
  const MessageAttachment({
    required this.url,
    this.thumbnailUrl,
    this.isVideo = false,
    this.aspectRatio = 1,
    this.durationSeconds,
  });

  final String url;
  final String? thumbnailUrl;
  final bool isVideo;
  final double aspectRatio;
  final double? durationSeconds;
}

/// One emoji on a message, aggregated across everyone who used it.
class MessageReaction {
  const MessageReaction({
    required this.emoji,
    this.count = 0,
    this.profileIds = const [],
    this.reactedByMe = false,
  });

  final String emoji;
  final int count;
  final List<String> profileIds;

  /// Whether the signed-in user is one of them — there is one reaction per
  /// person per message, so this also means "reacting again replaces mine".
  final bool reactedByMe;
}

class Message extends BaseEntity {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.threadId = '',
    this.senderName = '',
    this.senderAvatarUrl,
    this.isMine = false,
    this.read = false,
    this.attachments = const [],
    this.reactions = const [],
    this.replyToMessageId,
    this.replyToPreview,
    this.replyToSenderId,
    this.editedAt,
    this.isRetracted = false,
    this.readByProfileIds = const [],
  });

  @override
  final String id;

  final String threadId;
  final String senderId;

  /// The sender's display name and avatar, inlined on every message by the
  /// backend. Prefer these over a directory lookup — see [ThreadParticipant].
  final String senderName;
  final String? senderAvatarUrl;

  final String text;
  final DateTime sentAt;

  /// Whether the signed-in user sent this.
  ///
  /// Stamped when the message is decoded, by comparing the sender against the
  /// caller's own ProfileId: nothing in the payload marks the viewer, and the
  /// id is not derivable from the auth token.
  final bool isMine;

  /// True once every OTHER participant has read it — the sender's double tick.
  ///
  /// Read state is derived from each participant's read position, so this is
  /// only meaningful on outbound messages and can only ever move forwards for
  /// the thread as a whole; there are no per-message receipts.
  final bool read;

  /// The participants (other than the sender) whose read position is at or
  /// past this message.
  final List<String> readByProfileIds;

  final List<MessageAttachment> attachments;
  final List<MessageReaction> reactions;

  /// Set when this message quotes another. [replyToPreview] is a short excerpt
  /// of the quoted text, inlined so a reply renders without a second fetch.
  final String? replyToMessageId;
  final String? replyToPreview;
  final String? replyToSenderId;

  /// When the sender last edited it. Prior versions are not kept.
  final DateTime? editedAt;

  /// Unsent by its sender. The row survives as a tombstone — it still anchors
  /// replies and read positions — but [text] and [attachments] arrive empty.
  final bool isRetracted;

  /// Monogram for the sender's avatar in a group thread. Derived from the name
  /// the message carries, so it resolves even for someone who has since left.
  String get senderInitials => _monogram(senderName);

  Message copyWith({
    String? text,
    bool? read,
    bool? isRetracted,
    DateTime? editedAt,
    List<MessageReaction>? reactions,
  }) {
    return Message(
      id: id,
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text ?? this.text,
      sentAt: sentAt,
      isMine: isMine,
      read: read ?? this.read,
      attachments: attachments,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId,
      replyToPreview: replyToPreview,
      replyToSenderId: replyToSenderId,
      editedAt: editedAt ?? this.editedAt,
      isRetracted: isRetracted ?? this.isRetracted,
      readByProfileIds: readByProfileIds,
    );
  }
}

class MessageThread extends BaseEntity {
  const MessageThread({
    required this.id,
    required this.participants,
    this.kind = ThreadKind.direct,
    this.title,
    this.messages = const [],
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isAdmin = false,
    this.viewerId = '',
  });

  @override
  final String id;

  final ThreadKind kind;

  /// The group's name. Always null for a direct thread — its name is the other
  /// participant's, which is what [displayTitle] resolves.
  final String? title;

  /// Everyone still in the thread, **including the signed-in user** — that is
  /// how the module returns them, and nothing in the payload marks which one
  /// is the caller. Use [counterpart] when the viewer must be excluded.
  final List<ThreadParticipant> participants;

  /// Oldest first — the order the thread renders in.
  ///
  /// Empty on the thread list: the list endpoint carries only
  /// [lastMessagePreview], and history is a separate read.
  final List<Message> messages;

  /// The server's excerpt of the newest message, kept on the conversation row
  /// so the list renders without touching the messages table.
  ///
  /// It is the text alone — nothing says who sent it, so the list cannot show
  /// a "you:" prefix until the thread itself has been opened.
  final String? lastMessagePreview;

  /// Null for a thread nobody has written in yet.
  final DateTime? lastMessageAt;

  final int unreadCount;

  /// Whether the CALLER muted this thread. Muting silences notifications
  /// only — unread counts keep accruing.
  final bool isMuted;

  /// Whether the caller may rename the thread or change its membership.
  final bool isAdmin;

  /// The signed-in user's ProfileId, stamped at decode time so [counterpart]
  /// can tell the viewer apart from everyone else.
  final String viewerId;

  bool get isGroup => kind == ThreadKind.group;

  /// The first participant who is not the signed-in user.
  ///
  /// That is the other party in a direct thread, and — for a group nobody
  /// titled — the only name [displayTitle] has to fall back on. Null only when
  /// the caller is alone in the thread.
  ThreadParticipant? get counterpart {
    for (final p in participants) {
      if (p.id != viewerId) return p;
    }
    return null;
  }

  /// What the header and the list row call this thread.
  String get displayTitle {
    final named = title?.trim() ?? '';
    if (named.isNotEmpty) return named;
    return counterpart?.name ?? '';
  }

  /// Stable seed for the monogram avatar. Only a direct thread draws one — a
  /// group has its own widget — so this is the counterpart, falling back to the
  /// thread's own id so the gradient never changes underfoot.
  String get avatarSeed => counterpart?.id ?? id;

  /// The newest message, once history has been loaded.
  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  /// One line of preview text — from loaded history when there is any, else
  /// the server's excerpt.
  String get preview => lastMessage?.text ?? lastMessagePreview ?? '';

  MessageThread copyWith({
    String? title,
    List<ThreadParticipant>? participants,
    List<Message>? messages,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isMuted,
  }) {
    return MessageThread(
      id: id,
      kind: kind,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isAdmin: isAdmin,
      viewerId: viewerId,
    );
  }
}
