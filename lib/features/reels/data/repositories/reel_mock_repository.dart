import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../domain/entities/reel.dart';
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

  Future<void> _wait() => Future<void>.delayed(latency);

  static DateTime _ago({int hours = 0}) =>
      DateTime.now().subtract(Duration(hours: hours));

  static List<Reel> _seed() => [
        Reel(
          id: 'rl1',
          authorId: 'sara',
          createdAt: _ago(hours: 5),
          caption: '٣ أساليب بحث يجب أن يعرفها كل مدير منتج 🎯',
          tags: const ['#تجربة_المستخدم', '#البحث'],
          playCount: 89000,
          viewCount: 91500,
          likeCount: 12400,
        ),
        Reel(
          id: 'rl2',
          authorId: 'marwan',
          createdAt: _ago(hours: 14),
          caption: 'كيف انتقلنا من صفر إلى ٥٠ موظفاً دون أن نفقد ثقافتنا',
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
          caption: 'شاهد بناء هذا الجسر في ٤٥ ثانية',
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
}
