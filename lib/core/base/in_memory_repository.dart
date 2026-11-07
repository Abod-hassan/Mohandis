import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import 'base_entity.dart';
import 'base_repository.dart';

/// In-memory implementation of [BaseRepository]. Used by dev / mock mode and
/// in unit tests so notifiers can drive realistic flows without a backend.
///
/// The seed list is mutable per instance — `create`, `update`, `delete` mutate
/// it so the notifier's optimistic flows behave like a real repository would.
class InMemoryRepository<T extends BaseEntity> implements BaseRepository<T> {
  InMemoryRepository(
    Iterable<T> seed, {
    this.delay = const Duration(milliseconds: 120),
    T Function(Map<String, dynamic> body)? buildFromBody,
    T Function(T existing, Map<String, dynamic> body)? applyUpdate,
  })  : _items = [...seed],
        _buildFromBody = buildFromBody,
        _applyUpdate = applyUpdate;

  final List<T> _items;
  final Duration delay;
  final T Function(Map<String, dynamic> body)? _buildFromBody;
  final T Function(T existing, Map<String, dynamic> body)? _applyUpdate;

  /// Read-only view of the seeded items — handy for tests.
  List<T> get items => List.unmodifiable(_items);

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<Result<List<T>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    await _wait();
    return Result.success(List.unmodifiable(_items));
  }

  @override
  Future<Result<T, AppException>> getById(String id) async {
    await _wait();
    final match = _items.where((e) => e.id == id).toList();
    if (match.isEmpty) {
      return Result.failure(NotFoundException('Not found: $id'));
    }
    return Result.success(match.first);
  }

  @override
  Future<Result<T, AppException>> create(Map<String, dynamic> body) async {
    await _wait();
    if (_buildFromBody == null) {
      return Result.failure(
        const UnknownException('InMemoryRepository.create not configured'),
      );
    }
    final created = _buildFromBody(body);
    _items.add(created);
    return Result.success(created);
  }

  @override
  Future<Result<T, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    await _wait();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) {
      return Result.failure(NotFoundException('Not found: $id'));
    }
    if (_applyUpdate == null) {
      return Result.failure(
        const UnknownException('InMemoryRepository.update not configured'),
      );
    }
    final updated = _applyUpdate(_items[idx], body);
    _items[idx] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<void, AppException>> delete(String id) async {
    await _wait();
    final removed = _items.length;
    _items.removeWhere((e) => e.id == id);
    if (_items.length == removed) {
      return Result.failure(NotFoundException('Not found: $id'));
    }
    return const Result.success(null);
  }
}
