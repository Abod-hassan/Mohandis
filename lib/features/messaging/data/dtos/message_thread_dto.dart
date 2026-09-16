import 'package:flutter_mobile_template/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/message_thread.dart';

/// Wire models for the module's `ConversationsController`.
///
/// These deliberately do NOT implement `BaseDto`: every row has to be read
/// against the caller's own ProfileId — it decides which participant is "me"
/// and which bubbles sit on the right — and nothing in the payload marks it.
/// So `toDomain` takes the viewer's id, which `BaseDto.toDomain()` cannot.
///
/// Dates go through [PostDto.parseDate]: an ASP.NET `DateTime` comes back UTC
/// **without a `Z`**, and reading it as device-local shifts every timestamp by
/// the device's offset.
class ConversationDto {
  const ConversationDto({
    required this.id,
    required this.type,
    this.title,
    this.participants = const [],
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isAdmin = false,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      ConversationDto(
        id: '${json['id'] ?? ''}',
        type: kindFromWire(json['type']),
        title: json['title'] as String?,
        participants: participantsFrom(json['participants']),
        lastMessagePreview: json['lastMessagePreview'] as String?,
        lastMessageAt: optionalDate(json['lastMessageAt']),
        unreadCount: PostDto.asInt(json['unreadCount']),
        isMuted: json['isMuted'] == true,
        isAdmin: json['isAdmin'] == true,
      );

  final String id;
  final ThreadKind type;

  /// Null on a direct thread — those are named after the other participant.
  final String? title;

  /// Everyone still in the thread, the caller included.
  final List<ThreadParticipantDto> participants;

  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isMuted;
  final bool isAdmin;

  /// [viewerProfileId] is the signed-in user's ProfileId — see the class doc.
  MessageThread toDomain(String viewerProfileId) => MessageThread(
    id: id,
    kind: type,
    title: title,
    participants: participants
        .map((p) => p.toDomain())
        .toList(growable: false),
    lastMessagePreview: lastMessagePreview,
    lastMessageAt: lastMessageAt,
    unreadCount: unreadCount,
    isMuted: isMuted,
    isAdmin: isAdmin,
    viewerId: viewerProfileId,
  );

  /// `ConversationTypeEnum` — `0` Direct, `1` Group.
  ///
  /// The host registers Newtonsoft's `StringEnumConverter`, so this arrives as
  /// the NAME (`"Group"`); the ordinal is accepted too, because a host that
  /// drops the converter would otherwise turn every group into a direct thread
  /// and hide its title.
  static ThreadKind kindFromWire(Object? raw) {
    if (raw is num) {
      return raw.toInt() == ThreadKind.group.index
          ? ThreadKind.group
          : ThreadKind.direct;
    }
    return '$raw'.toLowerCase() == 'group'
        ? ThreadKind.group
        : ThreadKind.direct;
  }

  static List<ThreadParticipantDto> participantsFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ThreadParticipantDto.fromJson)
        .toList(growable: false);
  }

  /// [PostDto.parseDate] answers "now" for anything unparseable, which is the
  /// right call for a required timestamp and the wrong one for a nullable
  /// field — a thread nobody has written in would sort to the top.
  static DateTime? optionalDate(Object? raw) =>
      raw == null ? null : PostDto.parseDate(raw);
}

/// Wire model for `ProfileSimplifiedDto` as messaging returns it.
///
/// `headline` is declared on the C# DTO but the conversation reads never fill
/// it in — the projection behind them selects id/username/name/avatar/verified
/// and presence only. It is read here anyway so a future server-side fix needs
/// no client change.
class ThreadParticipantDto {
  const ThreadParticipantDto({
    required this.id,
    this.username = '',
    this.displayName = '',
    this.headline,
    this.avatarUrl,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory ThreadParticipantDto.fromJson(Map<String, dynamic> json) =>
      ThreadParticipantDto(
        id: '${json['id'] ?? ''}',
        username: '${json['username'] ?? ''}',
        displayName: '${json['displayName'] ?? ''}',
        headline: json['headline'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        isVerified: json['isVerified'] == true,
        isOnline: json['isOnline'] == true,
        lastSeenAt: ConversationDto.optionalDate(json['lastSeenAt']),
      );

  final String id;
  final String username;
  final String displayName;
  final String? headline;
  final String? avatarUrl;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeenAt;

  ThreadParticipant toDomain() => ThreadParticipant(
    id: id,
    // Falling back to the username keeps a row from rendering as a blank name
    // if a profile was created without a display name.
    name: displayName.isNotEmpty ? displayName : username,
    username: username,
    headline: headline,
    avatarUrl: avatarUrl,
    verified: isVerified,
    isOnline: isOnline,
    lastSeenAt: lastSeenAt,
  );
}

class MessageDto {
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.sentAt,
    this.senderName = '',
    this.senderAvatarUrl,
    this.content = '',
    this.attachments = const [],
    this.reactions = const [],
    this.replyToMessageId,
    this.replyToPreview,
    this.replyToSenderId,
    this.editedAt,
    this.isRetracted = false,
    this.readByProfileIds = const [],
    this.isReadByAll = false,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
    id: '${json['id'] ?? ''}',
    conversationId: '${json['conversationId'] ?? ''}',
    senderId: '${json['senderId'] ?? ''}',
    senderName: '${json['senderName'] ?? ''}',
    senderAvatarUrl: json['senderAvatarUrl'] as String?,
    // Null once the message is retracted, and on an attachment-only message.
    content: '${json['content'] ?? ''}',
    sentAt: PostDto.parseDate(json['sentAt']),
    attachments: attachmentsFrom(json['attachments']),
    reactions: reactionsFrom(json['reactions']),
    replyToMessageId: json['replyToMessageId'] as String?,
    replyToPreview: json['replyToPreview'] as String?,
    replyToSenderId: json['replyToSenderId'] as String?,
    // A `DateTimeOffset`, unlike every other timestamp here — it carries its
    // own offset and `parseDate` honours it as sent.
    editedAt: ConversationDto.optionalDate(json['editedAt']),
    isRetracted: json['isRetracted'] == true,
    readByProfileIds: idsFrom(json['readByProfileIds']),
    isReadByAll: json['isReadByAll'] == true,
  );

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime sentAt;
  final List<MessageAttachment> attachments;
  final List<MessageReaction> reactions;
  final String? replyToMessageId;
  final String? replyToPreview;
  final String? replyToSenderId;
  final DateTime? editedAt;
  final bool isRetracted;
  final List<String> readByProfileIds;
  final bool isReadByAll;

  /// [viewerProfileId] is the signed-in user's ProfileId — see the
  /// [ConversationDto] class doc.
  Message toDomain(String viewerProfileId) => Message(
    id: id,
    threadId: conversationId,
    senderId: senderId,
    senderName: senderName,
    senderAvatarUrl: senderAvatarUrl,
    text: content,
    sentAt: sentAt,
    isMine: senderId == viewerProfileId,
    read: isReadByAll,
    readByProfileIds: readByProfileIds,
    attachments: attachments,
    reactions: reactions,
    replyToMessageId: replyToMessageId,
    replyToPreview: replyToPreview,
    replyToSenderId: replyToSenderId,
    editedAt: editedAt,
    isRetracted: isRetracted,
  );

  /// Already ordered by `position` server-side, so the row order is the order
  /// the sender arranged.
  static List<MessageAttachment> attachmentsFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((a) {
      final w = (a['width'] as num?)?.toDouble();
      final h = (a['height'] as num?)?.toDouble();
      return MessageAttachment(
        url: '${a['url'] ?? ''}',
        thumbnailUrl: a['thumbnailUrl'] as String?,
        // `MediaKindEnum` — by name from this host, by ordinal from a host
        // without the string converter.
        isVideo: PostDto.isVideoKind(a['kind']),
        aspectRatio: (w != null && h != null && h > 0) ? w / h : 1,
        durationSeconds: (a['durationSeconds'] as num?)?.toDouble(),
      );
    }).toList(growable: false);
  }

  /// Already ordered by descending count server-side.
  static List<MessageReaction> reactionsFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (r) => MessageReaction(
            emoji: '${r['emoji'] ?? ''}',
            count: PostDto.asInt(r['count']),
            profileIds: idsFrom(r['profileIds']),
            reactedByMe: r['reactedByMe'] == true,
          ),
        )
        .toList(growable: false);
  }

  /// Guid arrays come back as strings; anything else is stringified rather
  /// than dropped so an id is never silently lost.
  static List<String> idsFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => '$e').toList(growable: false);
  }
}
