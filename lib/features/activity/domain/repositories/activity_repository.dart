import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/activity_notification.dart';

/// The notification centre's inbox, served by the module's
/// `NotificationsController`.
abstract class ActivityRepository {
  /// One page of the caller's notifications, newest first.
  ///
  /// Paged, not "everything": the inbox grows without bound, so the screen
  /// shows the first page and nothing may assume an id will be in it.
  Future<Result<List<ActivityNotification>, AppException>> all({
    bool unreadOnly = false,
    int page = 1,
    int size = 30,
  });

  /// How many are unread, without pulling the inbox itself — one cached COUNT
  /// server-side, which is what the badge on other surfaces reads.
  Future<Result<int, AppException>> unreadCount();

  /// Marks one notification read. Idempotent: a row already read is a no-op,
  /// not an error.
  Future<Result<void, AppException>> markRead(String id);

  Future<Result<void, AppException>> markAllRead();
}
