import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/result.dart';
import 'base_entity.dart';
import 'base_repository.dart';

/// AsyncNotifier base for screens that show a list of entities.
///
/// Subclasses provide [repository] (and optionally override [query]) — the
/// base handles loading, refreshing, optimistic create / update / delete, and
/// error propagation via `AsyncValue`.
///
/// Example:
/// ```dart
/// class ProductsNotifier extends BaseListNotifier<Product> {
///   @override
///   BaseRepository<Product> get repository =>
///       ref.read(productRepositoryProvider);
/// }
///
/// final productsNotifierProvider =
///     AsyncNotifierProvider<ProductsNotifier, List<Product>>(
///   ProductsNotifier.new,
/// );
/// ```
abstract class BaseListNotifier<T extends BaseEntity>
    extends AsyncNotifier<List<T>> {
  BaseRepository<T> get repository;

  Map<String, dynamic>? get query => null;

  @override
  Future<List<T>> build() => _load();

  Future<List<T>> _load() async {
    final result = await repository.getAll(query: query);
    return result.when(
      success: (items) => items,
      failure: (e) => throw e,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Optimistically appends [item], then reconciles with the server response.
  Future<Result<T, AppException>> createOptimistic(
    Map<String, dynamic> body,
    T optimistic,
  ) async {
    final previous = state.valueOrNull ?? <T>[];
    state = AsyncValue.data([...previous, optimistic]);

    final result = await repository.create(body);
    return result.when(
      success: (created) {
        final next = [
          for (final e in state.valueOrNull ?? previous)
            if (e.id == optimistic.id) created else e,
        ];
        state = AsyncValue.data(next);
        return Result<T, AppException>.success(created);
      },
      failure: (e) {
        state = AsyncValue.data(previous);
        return Result<T, AppException>.failure(e);
      },
    );
  }

  Future<Result<T, AppException>> updateItem(
    String id,
    Map<String, dynamic> body,
  ) async {
    final result = await repository.update(id, body);
    result.when(
      success: (updated) {
        final next = <T>[
          for (final e in state.valueOrNull ?? <T>[])
            if (e.id == id) updated else e,
        ];
        state = AsyncValue.data(next);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void, AppException>> deleteItem(String id) async {
    final previous = state.valueOrNull ?? <T>[];
    state = AsyncValue.data([
      for (final e in previous)
        if (e.id != id) e,
    ]);

    final result = await repository.delete(id);
    if (result.isFailure) {
      state = AsyncValue.data(previous);
    }
    return result;
  }
}
