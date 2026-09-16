import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../data/repositories/network_repository_impl.dart';
import '../../domain/entities/connection_request.dart';

class NetworkNotifier extends AsyncNotifier<NetworkOverview> {
  @override
  Future<NetworkOverview> build() async {
    final result = await ref.read(networkRepositoryProvider).overview();
    return result.when(success: (o) => o, failure: (e) => throw e);
  }

  Future<void> refresh() async {
    // Requests already answered this session are kept: the reload replaces the
    // rows, and there is no outbound-request endpoint to rebuild `sentTo` from.
    final sent = state.valueOrNull?.sentTo ?? const <String>{};
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(networkRepositoryProvider).overview();
      final overview = result.when(success: (o) => o, failure: (e) => throw e);
      return overview.copyWith(sentTo: sent);
    });
  }

  Future<Result<void, AppException>> accept(String personId) =>
      _resolveRequest(personId, ref.read(networkRepositoryProvider).accept);

  Future<Result<void, AppException>> ignore(String personId) =>
      _resolveRequest(personId, ref.read(networkRepositoryProvider).ignore);

  /// Sends an outbound request and records it.
  ///
  /// The id is remembered rather than the tile being removed: `Connect` only
  /// raises a pending edge, so the person is still someone you may know — the
  /// button just has nothing left to do.
  Future<Result<void, AppException>> connect(String personId) async {
    final result = await ref.read(networkRepositoryProvider).connect(personId);
    final current = state.valueOrNull;
    if (result.isSuccess && current != null) {
      state = AsyncValue.data(
        current.copyWith(sentTo: {...current.sentTo, personId}),
      );
    }
    return result;
  }

  /// Accept and ignore both remove the row; the only difference is the call
  /// and the toast the screen shows afterwards.
  Future<Result<void, AppException>> _resolveRequest(
    String personId,
    Future<Result<void, AppException>> Function(String) call,
  ) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncValue.data(
        previous.copyWith(
          requests: previous.requests
              .where((r) => r.personId != personId)
              .toList(growable: false),
        ),
      );
    }

    final result = await call(personId);
    if (result.isFailure && previous != null) {
      state = AsyncValue.data(previous);
    }
    return result;
  }
}

final networkNotifierProvider =
    AsyncNotifierProvider<NetworkNotifier, NetworkOverview>(NetworkNotifier.new);

/// Pending-request count for the bottom-nav badge. Reads the same notifier so
/// accepting a request clears the badge without a refetch.
final pendingRequestCountProvider = Provider<int>((ref) {
  return ref.watch(networkNotifierProvider).valueOrNull?.requests.length ?? 0;
});
