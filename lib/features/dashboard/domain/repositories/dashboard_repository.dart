import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Result<DashboardSummary, AppException>> summary();
}
