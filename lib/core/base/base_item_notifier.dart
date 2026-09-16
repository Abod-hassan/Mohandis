import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/result.dart';
import 'base_entity.dart';
import 'base_repository.dart';

/// AsyncNotifier base for a single-entity detail screen.
///
/// Subclass with the entity's [id] passed via `family`, override [repository],
/// and the base will load / refresh / update / delete.
///
/// Example:
/// ```dart
/// class ProductNotifier extends BaseItemNotifier<Product, String> {
///   @override
///   BaseRepository<Product> get repository =>
///       ref.read(productRepositoryProvider);
/// }
///
/// final productNotifierProvider = AsyncNotifierProvider.family<
///     ProductNotifier, Product, String>(ProductNotifier.new);
/// ```
abstract class BaseItemNotifier<T extends BaseEntity, A>
    extends FamilyAsyncNotifier<T, A> {
  BaseRepository<T> get repository;

  String idFromArg(A arg) => arg.toString();

  @override
  Future<T> build(A arg) async {
    final id = idFromArg(arg);
    final result = await repository.getById(id);
    return result.when(
      success: (item) => item,
      failure: (e) => throw e,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await repository.getById(idFromArg(arg));
      return result.when(
        success: (item) => item,
        failure: (e) => throw e,
      );
    });
  }

  Future<Result<T, AppException>> save(Map<String, dynamic> body) async {
    final result = await repository.update(idFromArg(arg), body);
    result.when(
      success: (updated) => state = AsyncValue.data(updated),
      failure: (_) {},
    );
    return result;
  }
}
