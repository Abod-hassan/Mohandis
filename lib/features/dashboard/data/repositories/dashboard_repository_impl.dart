import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../dtos/dashboard_summary_dto.dart';

/// The engineer panel, from `GET /api/social/Dashboard`.
///
/// Goes through [apiCall] like every other repository in the app, which is what
/// unwraps the `ResultViewModel` envelope and turns a transport failure into a
/// typed [AppException]. It did not always: the panel used to hand-roll its own
/// Dio call against `/api/dashboard`, a route that never existed, and read the
/// response body as a bare DTO. Both halves of that were wrong once the module
/// grew a real controller — the route carries the `social` prefix, and a module
/// controller answers with the envelope.
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Result<DashboardSummary, AppException>> summary() {
    return apiCall(
      EndPoints.dashboard,
      () => _api.dio.get<dynamic>(EndPoints.dashboard),
      // `envelope.object` is `data`, and an empty map decodes to a panel of
      // zeroes — which is exactly what a tenant with no catalogue should show,
      // rather than an error state over a screen that has nothing wrong with it.
      (envelope) => DashboardSummaryDto.fromJson(envelope.object).toDomain(),
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
