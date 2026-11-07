import 'package:mohandis/core/base/base_entity.dart';

/// Notification kinds the centre knows how to render.
///
/// Deliberately narrower than the module's `NotificationTypeEnum`: several
/// server-side kinds share one visual treatment here (a reply IS a comment to
/// the reader, and both call kinds are one "call" row). Anything the backend
/// adds later falls back to [ActivityType.like]'s neutral treatment rather
/// than crashing an older client — see `ActivityNotificationDto.typeFromWire`.
enum ActivityType {
  connect,
  like,
  accepted,
  comment,
  job,
  mention,
  follow,
  share,
  message,
  call,

  /// Somebody liked your story.
  storyLike,

  /// Somebody commented on your reel (or replied to your comment on one).
  reelComment,

  /// A kind the server added that this build has no rendering for. Kept
  /// distinct so an unknown notification reads as "sent you a notification"
  /// with a neutral bell, rather than being mislabelled as a like.
  other,
}

class ActivityNotification extends BaseEntity {
  const ActivityNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.text,
    required this.createdAt,
    this.actorName = '',
    this.actorAvatarUrl,
    this.postId,
    this.unread = true,
    this.actionable = false,
    this.isFollowRequest = false,
  });

  @override
  final String id;

  final ActivityType type;

  /// The person who caused the notification.
  final String actorId;

  /// The actor's display name as the notification itself carries it.
  ///
  /// The people directory is only one page against the real backend, so an
  /// actor is often missing from it; the row renders this instead of a blank
  /// name. Empty when the actor's profile was deleted.
  final String actorName;

  /// The actor's photo as the notification itself carries it — a host-less
  /// path, resolved for display like every other stored image.
  ///
  /// Here for the same reason as [actorName]: the people directory is one page,
  /// so the actor is often missing from it, and without this the row falls back
  /// to a monogram for everyone the directory happens not to hold.
  final String? actorAvatarUrl;

  /// Server-composed predicate ("و341 آخرون أعجبوا بمنشورك"). Rendered after
  /// the actor's bolded name.
  ///
  /// **Usually empty against the real backend** — the module only fills it for
  /// job applications; every other kind composes its sentence at push time and
  /// never stores it. Rendering the predicate per [type] needs a string per
  /// kind, which the app does not have yet.
  final String text;

  /// The post this notification is about, when there is one — likes, comments,
  /// replies, mentions and shares all carry it, and it is what the row opens.
  final String? postId;

  final DateTime createdAt;
  final bool unread;

  /// True while the request behind this row can still be answered, which is
  /// when it carries accept/ignore buttons. Decided by the SERVER from the
  /// live request — see [ActivityNotificationDto].
  final bool actionable;

  /// A request to follow a private account, as opposed to a connection
  /// request. Both render as the same row with the same two buttons, but they
  /// are answered by different endpoints: Profiles/AcceptRequest for this one,
  /// Connections/Accept for the other. Sending one to the other's endpoint is
  /// a guaranteed "Request not found."
  final bool isFollowRequest;

  ActivityNotification copyWith({
    String? text,
    bool? unread,
    bool? actionable,
  }) {
    return ActivityNotification(
      id: id,
      type: type,
      actorId: actorId,
      actorName: actorName,
      actorAvatarUrl: actorAvatarUrl,
      text: text ?? this.text,
      postId: postId,
      createdAt: createdAt,
      unread: unread ?? this.unread,
      actionable: actionable ?? this.actionable,
      isFollowRequest: isFollowRequest,
    );
  }
}
