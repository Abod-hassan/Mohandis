import 'package:mohandis/core/base/base_dto.dart';
import 'package:mohandis/features/posts/data/dtos/post_dto.dart';

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
    this.isFollowRequest = false,
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
      // The server says whether the request is STILL pending (`isActionable`,
      // computed from the live follow row). Deciding from the type alone is
      // what kept Accept buttons on requests already answered from another
      // device — and pressing one came back as a red "Request not found."
      // An older server without the field falls back to the type. It says
      // `followrequest`, not `connectionrequest`: connection rows are dropped
      // by [isHidden], so a connection fallback could never light up a row.
      actionable: json.containsKey('isActionable')
          ? json['isActionable'] == true
          : _wireName(rawType) == 'followrequest',
      isFollowRequest: _wireName(rawType) == 'followrequest',
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
  final bool isFollowRequest;

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
    isFollowRequest: isFollowRequest,
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
    'storylike',
    'reelcomment',
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

  /// Whether this build shows the row at all.
  ///
  /// Connections were withdrawn from the app — following is the only
  /// relationship it has — so the two connection kinds are dropped at the edge
  /// rather than rendered as rows whose buttons lead nowhere. The server still
  /// writes them for anything else reading its inbox.
  static bool isHidden(Object? rawType) {
    final wire = _wireName(rawType);
    return wire == 'connectionrequest' || wire == 'connectionaccepted';
  }

  /// Maps the module's sixteen kinds onto the twelve the centre renders.
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
      'storylike' => ActivityType.storyLike,
      'reelcomment' => ActivityType.reelComment,
      _ => ActivityType.other,
    };
  }
}
