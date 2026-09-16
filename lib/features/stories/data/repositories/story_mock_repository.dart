import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';

/// In-memory story rail used while running on mock data. The fixtures carry no
/// media: a caption over the design's gradient card is what a story looks like
/// with nothing to load, which is also the live fallback for a video.
class StoryMockRepository implements StoryRepository {
  StoryMockRepository({this.latency = const Duration(milliseconds: 180)})
      : _stories = _seed();

  final Duration latency;
  final List<Story> _stories;

  Future<void> _wait() => Future<void>.delayed(latency);

  static List<Story> _seed() {
    final now = DateTime.now();
    Story s(String id, String author, int hoursAgo, String caption, int views) {
      final createdAt = now.subtract(Duration(hours: hoursAgo));
      return Story(
        id: id,
        authorId: author,
        createdAt: createdAt,
        expiresAt: createdAt.add(const Duration(hours: 24)),
        caption: caption,
        viewCount: views,
      );
    }

    return [
      s('s1', 'amal', 4, 'ممتنة لهذا المجتمع. المزيد قريباً 🙌', 48),
      s('s2', 'reem', 6, 'نُشرت الورقة البحثية! الرابط في الملف.', 112),
      s('s3', 'marwan', 8, 'يوم إطلاق. الفريق أنجز عملاً استثنائياً.', 76),
      s('s4', 'sara', 10, 'ثلاث جلسات بحث اليوم — الرؤى قادمة غداً.', 39),
      s('s5', 'lina', 12, 'مناوبة طويلة، لكن كل دقيقة تستحق.', 27),
      s('s6', 'kareem', 16, 'صبّة الخرسانة اكتملت في الموقع الشمالي.', 64),
      s('s7', 'yara', 20, 'هوية العلامة الجديدة جاهزة للعرض.', 91),
    ];
  }

  @override
  Future<Result<List<Story>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    await _wait();
    return Result.success(
      _stories.where((s) => !s.expired).toList(growable: false),
    );
  }

  @override
  Future<Result<Story, AppException>> getById(String id) async {
    await _wait();
    final match = _stories.where((s) => s.id == id);
    if (match.isEmpty) {
      return Result.failure(NotFoundException('لا توجد قصة بالمعرف $id'));
    }
    return Result.success(match.first);
  }

  @override
  Future<Result<Story, AppException>> markSeen(String storyId) async {
    await _wait();
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index == -1) {
      return Result.failure(NotFoundException('لا توجد قصة بالمعرف $storyId'));
    }
    final story = _stories[index];
    final next = story.copyWith(
      seen: true,
      viewCount: story.seen ? story.viewCount : story.viewCount + 1,
    );
    _stories[index] = next;
    return Result.success(next);
  }

  /// The fixtures keep no view ledger — only the counter — so there is nobody
  /// to list.
  @override
  Future<Result<List<Person>, AppException>> viewers(
    String storyId, {
    int page = 1,
    int size = 20,
  }) async {
    await _wait();
    return const Result.success(<Person>[]);
  }

  @override
  Future<Result<Story, AppException>> create(Map<String, dynamic> body) async {
    await _wait();
    final createdAt = DateTime.now();
    final story = Story(
      id: 'local-s${_stories.length + 1}',
      authorId: 'me',
      createdAt: createdAt,
      expiresAt: createdAt.add(const Duration(hours: 24)),
      mediaUrl: body['mediaUrl'] as String?,
      isVideo: body['isVideo'] == true,
      caption: '${body['caption'] ?? ''}',
      seen: true,
    );
    _stories.insert(0, story);
    return Result.success(story);
  }

  @override
  Future<Result<Story, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      const Result.failure(ForbiddenException('القصص غير قابلة للتعديل'));

  /// The live backend has no delete action — a story only leaves the rail by
  /// expiring — but the fixtures drop it locally so a demo can still tidy up
  /// without inventing an error message the app has no translation for.
  @override
  Future<Result<void, AppException>> delete(String id) async {
    await _wait();
    _stories.removeWhere((s) => s.id == id);
    return const Result.success(null);
  }
}
