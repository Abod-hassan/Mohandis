import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../dtos/dashboard_summary_dto.dart';
import 'dashboard_mock_repository.dart';

/// The HTTP dashboard repository — **not wired up yet, on purpose.**
///
/// The engineer panel is the one surface in the app with no backend behind it:
/// the SocialMedia module exposes no aggregate endpoint, and `EndPoints.dashboard`
/// names a route that does not exist. This class is the shape the screen will
/// take the day it does; until then [dashboardRepositoryProvider] serves the
/// mock, because a 404 on every launch is worse than obviously placeholder
/// numbers.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Result<DashboardSummary, AppException>> summary() async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(EndPoints.dashboard);
      return Result.success(
        DashboardSummaryDto.fromJson(res.data ?? const {}).toDomain(),
      );
    } on DioException catch (e) {
      final mapped = e.error;
      if (mapped is AppException) return Result.failure(mapped);
      final status = e.response?.statusCode;
      return Result.failure(
        UnknownException(
          'Dashboard request failed [${e.type.name}${status != null ? ' · $status' : ''}] ${EndPoints.dashboard}',
          cause: e,
        ),
      );
    } catch (e, s) {
      return Result.failure(
        UnknownException('Dashboard parse failed', cause: e, stackTrace: s),
      );
    }
  }
}

/// Serves [DashboardMockRepository] deliberately — see the note on
/// [DashboardRepositoryImpl]. Swap the body to `DashboardRepositoryImpl(
/// apiClient: ref.watch(apiClientProvider))` the moment the module grows an
/// engineer-panel endpoint; nothing else has to change.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardMockRepository();
});
