import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/activity_notification.dart';

/// Wire model for the module's `NotificationDto`
/// (`POST /api/social/Notifications`).
///
/// Field names follow the C# DTO, not the mobile entity: the read flag is
/// `isRead` (the entity inverts it to `unread`), and the actor's name and
/// avatar are denormalised onto the row rather than resolved from a profile.
class ActivityNotificationDto implements BaseDto<ActivityNotification> {
  const ActivityNotificationDto({
    required this.id,
    required this.type,
    required this.createdAt,
    this.actorId = '',
    this.actorName = '',
    this.actorAvatarUrl,
    this.postId,
    this.commentId,
    this.text = '',
    this.isRead = false,
    this.actionable = false,
  });

  factory ActivityNotificationDto.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    return ActivityNotificationDto(
      id: '${json['id'] ?? ''}',
      type: typeFromWire(rawType),
      // `ActorId` is nullable — a system notification has no actor, and so does
      // one whose actor has since been deleted.
      actorId: '${json['actorId'] ?? ''}',
      actorName: '${json['actorName'] ?? ''}',
      actorAvatarUrl: json['actorAvatarUrl'] as String?,
      postId: json['postId'] as String?,
      commentId: json['commentId'] as String?,
      text: '${json['text'] ?? ''}',
      isRead: json['isRead'] == true,
      createdAt: PostDto.parseDate(json['createdAt']),
      // Only a CONNECTION request gets accept/ignore buttons. A follow
      // request looks the same to the reader but is resolved by
      // `Profiles/AcceptRequest`, a different flow the centre does not run —
      // those rows stay a plain tap through to the profile.
      //
      // Nothing on the row says whether the request is still pending: once it
      // has been answered elsewhere the buttons remain, and accepting again
      // comes back as a rejected request rather than a duplicate connection.
      actionable: _wireName(rawType) == 'connectionrequest',
    );
  }

  final String id;
  final ActivityType type;
  final String actorId;
  final String actorName;

  final String? actorAvatarUrl;

  final String? postId;

  /// The comment a Comment/Reply/Mention notification points at. Not carried
  /// into the entity either — the post detail route has no comment anchor, so
  /// the row opens the post and the reader scrolls.
  final String? commentId;

  final String text;
  final bool isRead;
  final DateTime createdAt;
  final bool actionable;

  @override
  ActivityNotification toDomain() => ActivityNotification(
    id: id,
    type: type,
    actorId: actorId,
    actorName: actorName,
    actorAvatarUrl: actorAvatarUrl,
    text: text,
    postId: postId,
    createdAt: createdAt,
    unread: !isRead,
    actionable: actionable,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'actorId': actorId,
    'actorName': actorName,
    'actorAvatarUrl': actorAvatarUrl,
    'postId': postId,
    'commentId': commentId,
    'text': text,
    'isRead': isRead,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  // ── Wire helpers ─────────────────────────────────────────────────────────

  /// `NotificationTypeEnum` in ordinal order.
  ///
  /// The host registers Newtonsoft's `StringEnumConverter`, so the type
  /// normally arrives as its NAME — this table is the fallback for a host
  /// configured without it, which sends the bare ordinal instead. Never
  /// reorder it: the positions are the C# enum's explicit values.
  static const List<String> _wireNames = [
    'follow',
    'followrequest',
    'followaccepted',
    'like',
    'comment',
    'mention',
    'message',
    'reply',
    'connectionrequest',
    'connectionaccepted',
    'jobapplication',
    'share',
    'incomingcall',
    'missedcall',
  ];

  /// Normalises either spelling of the enum to a lower-case name. An ordinal
  /// this build has no name for yields `''`, which no case below matches.
  static String _wireName(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < _wireNames.length ? _wireNames[i] : '';
    }
    return '$raw'.toLowerCase();
  }

  /// Maps the module's fourteen kinds onto the ten the centre renders.
  ///
  /// The buckets are chosen so nothing is dropped: a reply reads as a comment,
  /// an accepted follow reads like an accepted connection, and both call kinds
  /// share one row. An unknown value degrades to [ActivityType.other] — a kind
  /// added server-side must never crash an old client, and must never be
  /// mislabelled as one this build happens to know.
  static ActivityType typeFromWire(Object? raw) {
    return switch (_wireName(raw)) {
      'follow' => ActivityType.follow,
      'followrequest' || 'connectionrequest' => ActivityType.connect,
      'followaccepted' || 'connectionaccepted' => ActivityType.accepted,
      'like' => ActivityType.like,
      'comment' || 'reply' => ActivityType.comment,
      'mention' => ActivityType.mention,
      'message' => ActivityType.message,
      'jobapplication' => ActivityType.job,
      'share' => ActivityType.share,
      'incomingcall' || 'missedcall' => ActivityType.call,
      _ => ActivityType.other,
    };
  }
}
