import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../entities/story.dart';

abstract class StoryRepository extends BaseRepository<Story> {
  /// Records that the signed-in user viewed [storyId]. The rail turns the
  /// ring neutral off the returned story rather than guessing locally.
  ///
  /// Viewing your own story is a no-op server-side, so the story that comes
  /// back is still unseen — the author's ring never dims.
  Future<Result<Story, AppException>> markSeen(String storyId);

  /// Who has watched [storyId], newest first.
  ///
  /// **Author-only.** Anyone else gets "Only the author can see viewers." as a
  /// [ServerException]; there is no viewer-count-only variant of this call —
  /// `Story.viewCount` is where a non-author gets the number.
  Future<Result<List<Person>, AppException>> viewers(
    String storyId, {
    int page,
    int size,
  });

  /// Likes [storyId] or takes the like back. Answers the new state and count.
  Future<Result<({bool liked, int likeCount}), AppException>> toggleLike(
    String storyId,
  );

  /// Replies to [storyId] — a direct message to its author. Answers the
  /// conversation it landed in, so the app can offer to open it.
  Future<Result<String, AppException>> reply(String storyId, String text);
}
