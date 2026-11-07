import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

/// A 24-hour story.
///
/// The backend's story is media-first: `mediaUrl` is required server-side
/// ("A story needs media.") and [caption] is the optional text laid over it.
/// The design's text-over-gradient card is what renders when there is no image
/// to show — a fixture, a video (the app has no player yet), or a URL that
/// fails to load.
class Story extends BaseEntity {
  const Story({
    required this.id,
    required this.authorId,
    required this.createdAt,
    this.expiresAt,
    this.authorName = '',
    this.authorAvatarUrl,
    this.mediaUrl,
    this.isVideo = false,
    this.caption = '',
    this.viewCount = 0,
    this.seen = false,
    this.likeCount = 0,
    this.liked = false,
  });

  @override
  final String id;

  final String authorId;

  /// Denormalized by the backend onto every story row, exactly as on a post,
  /// so the rail renders without a lookup per author. May be empty on a
  /// fixture — fall back to the people directory.
  final String authorName;
  final String? authorAvatarUrl;

  final DateTime createdAt;

  /// The instant the story leaves the rail. The server computes it as
  /// `createdAt + 24h` and sends it explicitly, so the client never has to
  /// know the lifetime; [expired] falls back to that arithmetic only for rows
  /// that carry no value.
  final DateTime? expiresAt;

  final String? mediaUrl;

  /// The backend's `MediaKindEnum` — image or video.
  final bool isVideo;

  final String caption;

  /// Public on every story; the viewer *list* behind it is author-only.
  final int viewCount;

  /// `viewedByMe` on the wire. The server never records the author's view of
  /// their own story, so an author's own ring stays unseen by design.
  final bool seen;

  /// How many people liked it, and whether the viewer is one of them.
  final int likeCount;
  final bool liked;

  bool get expired => DateTime.now().isAfter(
    expiresAt ?? createdAt.add(const Duration(hours: 24)),
  );

  /// The author as a [Person], assembled from the fields the backend inlines.
  ///
  /// Thinner than a directory entry — a story payload has no headline — so
  /// prefer a directory hit and use this as the fallback that keeps the rail
  /// from rendering blank.
  Person get author => Person(
    id: authorId,
    name: authorName,
    firstName: authorName.split(RegExp(r'\s+')).first,
    headline: '',
    location: '',
    avatarUrl: authorAvatarUrl,
  );

  Story copyWith({bool? seen, int? viewCount, int? likeCount, bool? liked}) =>
      Story(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    createdAt: createdAt,
    expiresAt: expiresAt,
    mediaUrl: mediaUrl,
    isVideo: isVideo,
    caption: caption,
    viewCount: viewCount ?? this.viewCount,
    seen: seen ?? this.seen,
    likeCount: likeCount ?? this.likeCount,
    liked: liked ?? this.liked,
  );
}
