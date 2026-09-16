import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../error/app_exception.dart';
import '../error/result.dart';
import 'base_dto.dart';
import 'base_entity.dart';
import 'base_repository.dart';

/// Default REST implementation of [BaseRepository].
///
/// Given a [basePath] and a DTO factory, exposes the five CRUD operations.
/// Most features can use this directly via composition; if you need
/// feature-specific endpoints, extend the class and add methods that call
/// `apiClient.dio` the same way.
///
/// Example:
/// ```dart
/// final productRepositoryProvider = Provider<RestRepository<Product, ProductDto>>(
///   (ref) => RestRepository(
///     apiClient: ref.watch(apiClientProvider),
///     basePath: '/products',
///     fromJson: ProductDto.fromJson,
///   ),
/// );
/// ```
class RestRepository<T extends BaseEntity, D extends BaseDto<T>>
    implements BaseRepository<T> {
  RestRepository({
    required ApiClient apiClient,
    required String basePath,
    required D Function(Map<String, dynamic> json) fromJson,
    String listKey = 'data',
  })  : _api = apiClient,
        _basePath = basePath,
        _fromJson = fromJson,
        _listKey = listKey;

  final ApiClient _api;
  final String _basePath;
  final D Function(Map<String, dynamic> json) _fromJson;
  final String _listKey;

  String _itemPath(String id) =>
      _basePath.endsWith('/') ? '$_basePath$id' : '$_basePath/$id';

  @override
  Future<Result<List<T>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _api.dio.get<dynamic>(
        _basePath,
        queryParameters: query,
      );
      final raw = _extractList(res.data);
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map((j) => _fromJson(j).toDomain())
          .toList(growable: false);
      return Result.success(items);
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  @override
  Future<Result<T, AppException>> getById(String id) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(_itemPath(id));
      return Result.success(_fromJson(res.data ?? const {}).toDomain());
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  @override
  Future<Result<T, AppException>> create(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post<Map<String, dynamic>>(
        _basePath,
        data: body,
      );
      return Result.success(_fromJson(res.data ?? const {}).toDomain());
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  @override
  Future<Result<T, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _api.dio.put<Map<String, dynamic>>(
        _itemPath(id),
        data: body,
      );
      return Result.success(_fromJson(res.data ?? const {}).toDomain());
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  @override
  Future<Result<void, AppException>> delete(String id) async {
    try {
      await _api.dio.delete<void>(_itemPath(id));
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(_asAppException(e));
    } catch (e, s) {
      return Result.failure(UnknownException('$e', cause: e, stackTrace: s));
    }
  }

  List<dynamic> _extractList(Object? body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final inner = body[_listKey];
      if (inner is List) return inner;
    }
    return const [];
  }

  AppException _asAppException(DioException e) {
    final mapped = e.error;
    if (mapped is AppException) return mapped;
    return UnknownException(e.message ?? 'Request failed', cause: e);
  }
}
