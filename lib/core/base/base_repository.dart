import '../error/app_exception.dart';
import '../error/result.dart';
import 'base_entity.dart';

/// Generic CRUD contract every repository should satisfy.
///
/// Features may extend this with feature-specific methods (e.g. `archive`,
/// `markAsRead`) — the base just covers the universal operations so common
/// notifiers can target it generically.
abstract class BaseRepository<T extends BaseEntity> {
  Future<Result<List<T>, AppException>> getAll({
    Map<String, dynamic>? query,
  });

  Future<Result<T, AppException>> getById(String id);

  Future<Result<T, AppException>> create(Map<String, dynamic> body);

  Future<Result<T, AppException>> update(
    String id,
    Map<String, dynamic> body,
  );

  Future<Result<void, AppException>> delete(String id);
}
