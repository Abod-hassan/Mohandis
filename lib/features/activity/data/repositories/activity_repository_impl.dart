import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/activity_notification.dart';
import '../../domain/repositories/activity_repository.dart';
import '../dtos/activity_notification_dto.dart';

/// The activity centre against the module's `NotificationsController`.
///
/// Same two module conventions as the rest of the API: the inbox read is a
/// **POST with a filter body** plus `?page=&size=`, and every response is a
/// `ResultViewModel` envelope unwrapped by [apiCall] — a 200 can still carry
/// `error: true`. `viewerProfileId` is set server-side from the bearer token
/// and is overwritten if sent, so the filter only ever carries the two flags
/// the caller actually chooses.
class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Result<List<ActivityNotification>, AppException>> all({
    bool unreadOnly = false,
    int page = 1,
    int size = 30,
  }) {
    return apiCall(
      EndPoints.notifications,
      () => _api.dio.post<dynamic>(
        EndPoints.notifications,
        // `unreadOnly` is nullable server-side and only `true` narrows the
        // query, so it is omitted rather than sent as false.
        data: {if (unreadOnly) 'unreadOnly': true, 'descending': true},
        queryParameters: {'page': page, 'size': size},
      ),
      (envelope) => envelope.list
          .map((j) => ActivityNotificationDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<int, AppException>> unreadCount() {
    return apiCall(
      EndPoints.notificationsUnreadCount,
      () => _api.dio.get<dynamic>(EndPoints.notificationsUnreadCount),
      // `data` is a bare int, not an object — `envelope.object` would read it
      // as an empty map. A null payload means nothing unread, not a failure.
      (envelope) => (envelope.data as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<Result<void, AppException>> markRead(String id) {
    final path = EndPoints.notificationRead(id);
    return apiCall(path, () => _api.dio.post<dynamic>(path), (_) {});
  }

  @override
  Future<Result<void, AppException>> markAllRead() {
    return apiCall(
      EndPoints.notificationsReadAll,
      () => _api.dio.post<dynamic>(EndPoints.notificationsReadAll),
      (_) {},
    );
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
