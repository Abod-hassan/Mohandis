import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../domain/entities/activity_notification.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityMockRepository implements ActivityRepository {
  ActivityMockRepository({this.latency = const Duration(milliseconds: 200)})
      : _items = _seed();

  final Duration latency;
  final List<ActivityNotification> _items;

  Future<void> _wait() => Future<void>.delayed(latency);

  static List<ActivityNotification> _seed() {
    final now = DateTime.now();
    ActivityNotification n(
      String id,
      ActivityType type,
      String actor,
      String text,
      Duration ago, {
      bool unread = false,
      bool actionable = false,
    }) =>
        ActivityNotification(
          id: id,
          type: type,
          actorId: actor,
          text: text,
          createdAt: now.subtract(ago),
          unread: unread,
          actionable: actionable,
        );

    // `actorName` is left empty on purpose: the seeded actor ids all exist in
    // the people mock, so mock mode keeps exercising the directory lookup the
    // row falls back to.
    return [
      n('n1', ActivityType.connect, 'sara', 'طلب متابعتك',
          const Duration(minutes: 12),
          unread: true, actionable: true),
      n('n2', ActivityType.like, 'amal', 'و341 آخرون أعجبوا بمنشورك',
          const Duration(hours: 1),
          unread: true),
      n('n3', ActivityType.accepted, 'marwan', 'قبل طلب المتابعة',
          const Duration(hours: 3),
          unread: true),
      n('n4', ActivityType.comment, 'reem', 'علّقت: «كيف تعاملتم مع الجدولة…»',
          const Duration(hours: 4)),
      n('n5', ActivityType.job, 'dawood', 'تمت مراجعة طلبك في لوب ورك',
          const Duration(hours: 6)),
      n('n6', ActivityType.mention, 'yara', 'أشارت إليك في تعليق',
          const Duration(days: 1)),
      n('n7', ActivityType.message, 'sara', 'أرسلت لك رسالة',
          const Duration(days: 1, hours: 2)),
      n('n8', ActivityType.follow, 'lina', 'بدأت متابعتك',
          const Duration(days: 1, hours: 4)),
      n('n9', ActivityType.share, 'kareem', 'أعاد نشر تحديثك',
          const Duration(days: 2)),
    ];
  }

  @override
  Future<Result<List<ActivityNotification>, AppException>> all({
    bool unreadOnly = false,
    int page = 1,
    int size = 30,
  }) async {
    await _wait();
    final matching = unreadOnly
        ? _items.where((n) => n.unread).toList(growable: false)
        : _items;
    final start = (page - 1) * size;
    if (start < 0 || start >= matching.length) {
      return const Result.success([]);
    }
    final end = start + size < matching.length ? start + size : matching.length;
    return Result.success(matching.sublist(start, end));
  }

  @override
  Future<Result<int, AppException>> unreadCount() async {
    await _wait();
    return Result.success(_items.where((n) => n.unread).length);
  }

  @override
  Future<Result<void, AppException>> markRead(String id) async {
    await _wait();
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) _items[i] = _items[i].copyWith(unread: false);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppException>> markAllRead() async {
    await _wait();
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(unread: false);
    }
    return const Result.success(null);
  }
}
