import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_comment.dart';
import '../../domain/entities/reel_page.dart';
import '../../domain/repositories/reel_repository.dart';

/// In-memory reel wall used while running on mock data. Likes and saves
/// persist for the lifetime of the provider so the rail's state survives
/// swiping away and back, the way it will in production.
class ReelMockRepository implements ReelRepository {
  ReelMockRepository({this.latency = const Duration(milliseconds: 200)})
      : _reels = _seed();

  final Duration latency;
  final List<Reel> _reels;
  final List<ReelComment> _comments = [];

  Future<void> _wait() => Future<void>.delayed(latency);

  static DateTime _ago({int hours = 0}) =>
      DateTime.now().subtract(Duration(hours: hours));

  static List<Reel> _seed() => [
        Reel(
          id: 'rl1',
          authorId: 'sara',
          createdAt: _ago(hours: 5),
          caption: '3 أساليب بحث يجب أن يعرفها كل مدير منتج 🎯',
          tags: const ['#تجربة_المستخدم', '#البحث'],
          playCount: 89000,
          viewCount: 91500,
          likeCount: 12400,
        ),
        Reel(
          id: 'rl2',
          authorId: 'marwan',
          createdAt: _ago(hours: 14),
          caption: 'كيف انتقلنا من صفر إلى 50 موظفاً دون أن نفقد ثقافتنا',
          tags: const ['#الشركات_الناشئة', '#القيادة'],
          playCount: 112000,
          viewCount: 118300,
          likeCount: 8100,
          saveCount: 640,
          liked: true,
          saved: true,
        ),
        Reel(
          id: 'rl3',
          authorId: 'reem',
          createdAt: _ago(hours: 30),
          caption: 'شرح الشبكة العصبية بمثال المقهى ☕',
          tags: const ['#علم_البيانات', '#الذكاء_الاصطناعي'],
          playCount: 340000,
          viewCount: 356000,
          likeCount: 23700,
        ),
        Reel(
          id: 'rl4',
          authorId: 'kareem',
          createdAt: _ago(hours: 52),
          caption: 'شاهد بناء هذا الجسر في 45 ثانية',
          tags: const ['#الهندسة'],
          playCount: 61000,
          viewCount: 63400,
          likeCount: 5600,
        ),
      ];

  /// The seed is a single page, so `hasMore` is always false — page 2 of the
  /// mock wall is empty, which is what a notifier paging against it should
  /// see.
  @override
  Future<Result<ReelPage, AppException>> wall({
    Map<String, dynamic>? query,
  }) async {
    await _wait();
    final rows = query?['onlySaved'] == true
        ? _reels.where((r) => r.saved).toList(growable: false)
        : List<Reel>.unmodifiable(_reels);
    final page = (query?['page'] as num?)?.toInt() ?? 1;
    return Result.success(
      ReelPage(reels: page > 1 ? const [] : rows, hasMore: false),
    );
  }

  @override
  Future<Result<List<Reel>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    final page = await wall(query: query);
    return page.when(
      success: (p) => Result.success(p.reels),
      failure: (e) => Result.failure(e),
    );
  }

  @override
  Future<Result<Reel, AppException>> getById(String id) async {
    await _wait();
    final match = _reels.where((r) => r.id == id);
    if (match.isEmpty) {
      return Result.failure(NotFoundException('لا يوجد ريل بالمعرف $id'));
    }
    return Result.success(match.first);
  }

  @override
  Future<Result<Reel, AppException>> toggleLike(String reelId) =>
      _mutate(reelId, (r) => r.toggleLike());

  @override
  Future<Result<Reel, AppException>> toggleSave(String reelId) =>
      _mutate(reelId, (r) => r.toggleSave());

  @override
  Future<Result<Reel, AppException>> toggleShare(String reelId) =>
      _mutate(reelId, (r) => r.toggleShare());

  /// The fixtures' counters are fixed — there is nothing to increment — but
  /// the call still has to answer so the player's play hook behaves as it will
  /// against the backend.
  @override
  Future<Result<bool, AppException>> markPlayed(String reelId) async {
    await _wait();
    return Result.success(_reels.any((r) => r.id == reelId));
  }

  Future<Result<Reel, AppException>> _mutate(
    String id,
    Reel Function(Reel) transform,
  ) async {
    await _wait();
    final index = _reels.indexWhere((r) => r.id == id);
    if (index == -1) {
      return Result.failure(NotFoundException('لا يوجد ريل بالمعرف $id'));
    }
    final next = transform(_reels[index]);
    _reels[index] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Reel, AppException>> create(Map<String, dynamic> body) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));

  @override
  Future<Result<Reel, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));

  @override
  Future<Result<void, AppException>> delete(String id) async {
    await _wait();
    _reels.removeWhere((r) => r.id == id);
    return const Result.success(null);
  }

  @override
  Future<Result<List<ReelComment>, AppException>> comments(
    String reelId, {
    int page = 1,
    int size = 50,
  }) async {
    await _wait();
    final rows = _comments.where((c) => c.reelId == reelId).toList();
    final from = ((page - 1) * size).clamp(0, rows.length);
    final to = (from + size).clamp(0, rows.length);
    return Result.success(rows.sublist(from, to));
  }

  @override
  Future<Result<ReelComment, AppException>> addComment(
    String reelId,
    String text, {
    String? parentCommentId,
  }) async {
    await _wait();
    final comment = ReelComment(
      id: 'rc${DateTime.now().microsecondsSinceEpoch}',
      reelId: reelId,
      authorId: 'me',
      authorName: 'أنا',
      text: text.trim(),
      parentCommentId: parentCommentId,
      createdAt: DateTime.now(),
    );
    _comments.add(comment);
    return Result.success(comment);
  }

  @override
  Future<Result<void, AppException>> deleteComment(String commentId) async {
    await _wait();
    _comments.removeWhere(
      (c) => c.id == commentId || c.parentCommentId == commentId,
    );
    return const Result.success(null);
  }
}
