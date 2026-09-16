import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Result<DashboardSummary, AppException>> summary();
}
