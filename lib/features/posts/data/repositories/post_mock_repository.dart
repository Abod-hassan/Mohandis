import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../domain/entities/comment.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

/// In-memory feed used while the backend is being built. Mutations persist
/// for the lifetime of the provider so likes, saves, reposts, comments, and
/// newly published posts survive navigation the way they will in production.
class PostMockRepository implements PostRepository {
  PostMockRepository({this.latency = const Duration(milliseconds: 260)})
      : _posts = _seed();

  final Duration latency;
  final List<Post> _posts;

  int _sequence = 0;

  Future<void> _wait() => Future<void>.delayed(latency);

  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      DateTime.now().subtract(
        Duration(days: days, hours: hours, minutes: minutes),
      );

  static List<Post> _seed() => [
        Post(
          id: 'p1',
          authorId: 'amal',
          createdAt: _ago(hours: 2),
          visibility: PostVisibility.public,
          text:
              'بعد ٣ أشهر من المقابلات، أطلق فريقنا إعادة تصميم لدورة التوظيف قلّصت زمن انتظار المرشحين ٤٠٪. '
              'السر لم يكن أداة فاخرة — بل توثيق كل شيء كتابةً. التوظيف غير المتزامن ينجح فعلاً.',
          tags: ['#التوظيف', '#الهندسة'],
          likeCount: 342,
          repostCount: 28,
          commentCount: 2,
          comments: [
            Comment(
              id: 'c1',
              authorId: 'dawood',
              text: 'هذا هو الطريق. التقارير المكتوبة غيّرت كل شيء في دوراتنا.',
              createdAt: _ago(hours: 1),
              likeCount: 18,
              replies: [
                Comment(
                  id: 'c1r1',
                  authorId: 'amal',
                  text:
                      '@داوود الشمري تماماً — التوثيق المكتوب يزيل الكثير من انحياز الانطباع الأخير.',
                  createdAt: _ago(minutes: 52),
                  likeCount: 4,
                ),
              ],
            ),
            Comment(
              id: 'c2',
              authorId: 'reem',
              text: 'كيف تعاملتم مع الجدولة عبر المناطق الزمنية؟',
              createdAt: _ago(minutes: 40),
              likeCount: 6,
            ),
          ],
        ),
        Post(
          id: 'p2',
          authorId: 'reem',
          createdAt: _ago(hours: 5),
          visibility: PostVisibility.followers,
          text:
              'قضيت نهاية الأسبوع في تصوير بيانات طي البروتين لعشر سنوات. أحياناً أكثر ما يمكنك فعله '
              'احترافيةً هو أن تجعل المعقّد يبدو بسيطاً. 🧬',
          tags: ['#علم_البيانات'],
          media: [
            PostMedia(id: 'p2m1', aspectRatio: 4 / 3),
            PostMedia(id: 'p2m2', aspectRatio: 4 / 3),
          ],
          likeCount: 198,
          liked: true,
          saved: true,
          repostCount: 14,
          commentCount: 1,
          comments: [
            Comment(
              id: 'c3',
              authorId: 'sara',
              text: 'رائعة جداً! بأي أداة أنتجتِها؟',
              createdAt: _ago(hours: 2),
              likeCount: 9,
            ),
          ],
        ),
        Post(
          id: 'p3',
          authorId: 'marwan',
          createdAt: _ago(hours: 8),
          visibility: PostVisibility.public,
          text:
              'نبحث عن مهندس واجهات أمامية في لوب ورك. إن كنت تهتم بالحرفية وإمكانية الوصول والإطلاق '
              'السريع ضمن فريق صغير — هذه الفرصة مميزة. أعد النشر لتصل لمن يستحقها. 👇',
          likeCount: 521,
          repostCount: 143,
          jobId: 'j3',
        ),
        Post(
          id: 'p4',
          authorId: 'yara',
          createdAt: _ago(days: 1),
          visibility: PostVisibility.public,
          text:
              'أفضل نصيحة مهنية تلقيتها: شبكتك ليست من تعرفهم، بل من يزكّونك حين لا تكون في الغرفة. '
              'استثمر في النوع الثاني.',
          tags: ['#المسار_المهني'],
          likeCount: 874,
          repostCount: 210,
          repostedById: 'dawood',
        ),
        Post(
          id: 'p5',
          authorId: 'lina',
          createdAt: _ago(days: 1, hours: 3),
          visibility: PostVisibility.public,
          text:
              'تذكير بأن الرعاية الصحية مهنة قائمة على الثقة — تماماً كأي شبكة تستحق الانتماء إليها. '
              'ممتنة للمرشدين الذين منحوني الفرصة. الاقتباس أدناه ما زال صحيحاً 👇',
          likeCount: 156,
          repostCount: 9,
          quoted: QuotedPost(
            authorId: 'kareem',
            text:
                'عشر سنوات في الهندسة علّمتني: من يسأل السؤال «الساذج» مبكراً يوفّر على الفريق '
                'شهراً كاملاً لاحقاً.',
            createdAt: _ago(days: 2),
          ),
        ),
      ];

  @override
  Future<Result<List<Post>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    await _wait();
    final authorId = query?['authorId'] as String?;
    if (authorId == null) return Result.success(List.unmodifiable(_posts));
    return Result.success(
      _posts.where((p) => p.authorId == authorId).toList(growable: false),
    );
  }

  @override
  Future<Result<List<Post>, AppException>> byAuthor(
    String personId, {
    int page = 1,
    int size = 20,
  }) => getAll(query: {'authorId': personId});

  @override
  Future<Result<List<Comment>, AppException>> commentsByAuthor(
    String personId, {
    int page = 1,
    int size = 20,
  }) async {
    await _wait();
    return Result.success([
      for (final post in _posts)
        for (final comment in post.comments)
          if (comment.authorId == personId) comment,
    ]);
  }

  /// The mock feed is a single page — everything is already in memory, so
  /// there is nothing to page through.
  @override
  Future<Result<FeedPage, AppException>> homeFeed({
    FeedCursor cursor = FeedCursor.first,
    int pageSize = 10,
  }) async {
    await _wait();
    if (!cursor.isFirstPage) {
      return const Result.success(FeedPage.empty);
    }
    return Result.success(
      FeedPage(
        posts: List.unmodifiable(_posts),
        next: FeedCursor.first,
        hasMore: false,
      ),
    );
  }

  @override
  Future<Result<bool, AppException>> hideFromFeed(
    String postId, {
    bool wholeAuthor = false,
  }) async {
    await _wait();
    _posts.removeWhere(
      (p) => wholeAuthor
          ? p.authorId == _posts.firstWhere((x) => x.id == postId).authorId
          : p.id == postId,
    );
    return const Result.success(true);
  }

  @override
  Future<Result<bool, AppException>> markViewed(String postId) async =>
      const Result.success(true);

  @override
  Future<Result<Post, AppException>> getById(String id) async {
    await _wait();
    return _find(id);
  }

  @override
  Future<Result<Post, AppException>> toggleLike(String postId) =>
      _mutate(postId, (p) => p.toggleLike());

  @override
  Future<Result<Post, AppException>> toggleSave(String postId) =>
      _mutate(postId, (p) => p.toggleSave());

  @override
  Future<Result<List<Post>, AppException>> saved({
    int page = 1,
    int size = 20,
  }) async {
    await _wait();
    return Result.success(
      _posts.where((p) => p.saved).toList(growable: false),
    );
  }

  @override
  Future<Result<Post, AppException>> toggleRepost(String postId) =>
      _mutate(postId, (p) => p.toggleRepost());

  @override
  Future<Result<Post, AppException>> share({
    required String postId,
    String? text,
    PostVisibility visibility = PostVisibility.public,
  }) => _mutate(postId, (p) => p.toggleRepost());

  @override
  Future<Result<Comment, AppException>> toggleCommentLike(
    String commentId,
  ) async {
    await _wait();
    for (final post in _posts) {
      for (final comment in post.comments) {
        if (comment.id == commentId) {
          return Result.success(
            comment.copyWith(
              liked: !comment.liked,
              likeCount: comment.likeCount + (comment.liked ? -1 : 1),
            ),
          );
        }
      }
    }
    return Result.failure(NotFoundException('لا يوجد تعليق بالمعرف $commentId'));
  }

  @override
  Future<Result<Post, AppException>> publish({
    required String text,
    required PostVisibility visibility,
    List<PostMedia> media = const [],
  }) async {
    await _wait();
    final trimmed = text.trim();
    // Matches the server's rule ("A post needs text or media"), so a
    // photo-only post behaves the same against the mock as against the API.
    if (trimmed.isEmpty && media.isEmpty) {
      return const Result.failure(
        ValidationException('لا يمكن نشر منشور فارغ'),
      );
    }
    final post = Post(
      id: 'local-${++_sequence}',
      authorId: 'me',
      createdAt: DateTime.now(),
      visibility: visibility,
      text: trimmed,
      media: media,
    );
    _posts.insert(0, post);
    return Result.success(post);
  }

  @override
  Future<Result<List<Comment>, AppException>> comments(
    String postId, {
    int page = 1,
    int size = 50,
  }) async {
    await _wait();
    return _find(postId).map((p) => p.comments);
  }

  @override
  Future<Result<Comment, AppException>> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    await _wait();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(ValidationException('لا يمكن إرسال تعليق فارغ'));
    }
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return Result.failure(NotFoundException('لا يوجد منشور بالمعرف $postId'));
    }
    final comment = Comment(
      id: 'local-c${++_sequence}',
      authorId: 'me',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final post = _posts[index];
    _posts[index] = post.copyWith(
      comments: [...post.comments, comment],
      commentCount: post.commentCount + 1,
    );
    return Result.success(comment);
  }

  @override
  Future<Result<Post, AppException>> create(Map<String, dynamic> body) =>
      publish(
        text: '${body['text'] ?? ''}',
        visibility: PostVisibility.values.firstWhere(
          (v) => v.name == '${body['visibility']}',
          orElse: () => PostVisibility.public,
        ),
      );

  @override
  Future<Result<Post, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) =>
      _mutate(id, (p) => p.copyWith(text: '${body['text'] ?? p.text}'));

  @override
  Future<Result<void, AppException>> delete(String id) async {
    await _wait();
    final before = _posts.length;
    _posts.removeWhere((p) => p.id == id);
    if (_posts.length == before) {
      return Result.failure(NotFoundException('لا يوجد منشور بالمعرف $id'));
    }
    return const Result.success(null);
  }

  Future<Result<Post, AppException>> _mutate(
    String id,
    Post Function(Post) transform,
  ) async {
    await _wait();
    final index = _posts.indexWhere((p) => p.id == id);
    if (index == -1) {
      return Result.failure(NotFoundException('لا يوجد منشور بالمعرف $id'));
    }
    final next = transform(_posts[index]);
    _posts[index] = next;
    return Result.success(next);
  }

  Result<Post, AppException> _find(String id) {
    final match = _posts.where((p) => p.id == id);
    if (match.isEmpty) {
      return Result.failure(NotFoundException('لا يوجد منشور بالمعرف $id'));
    }
    return Result.success(match.first);
  }
}
