import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../entities/connection_request.dart';

abstract class NetworkRepository {
  Future<Result<NetworkOverview, AppException>> overview();

  Future<Result<void, AppException>> accept(String personId);

  /// Dismisses an inbound request. Idempotent — dismissing twice succeeds.
  Future<Result<void, AppException>> ignore(String personId);

  /// Sends an outbound connection request.
  Future<Result<void, AppException>> connect(String personId);
}
