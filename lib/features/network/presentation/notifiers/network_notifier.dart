import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/features/profile/data/repositories/profile_repository_impl.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../../data/repositories/network_repository_impl.dart';
import '../../domain/entities/connection_request.dart';

/// The Network tab: a "people you may know" grid, and nothing else.
///
/// Connections were withdrawn from the app — following is the only
/// relationship it has — so the inbound-request list that used to sit above
/// the grid is gone, and with it the `Connections/requests` call this notifier
/// made on every build. Follow requests to a private account are answered from
/// the notifications centre instead.
class NetworkNotifier extends AsyncNotifier<NetworkOverview> {
  @override
  Future<NetworkOverview> build() async =>
      NetworkOverview(suggestions: await _suggestions());

  Future<void> refresh() async {
    // People followed this session are kept: the reload replaces the grid, and
    // the server keeps suggesting someone you already follow for a while.
    final sent = state.valueOrNull?.sentTo ?? const <String>{};
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => NetworkOverview(suggestions: await _suggestions(), sentTo: sent),
    );
  }

  Future<List<Person>> _suggestions() => ref
      .read(networkRepositoryProvider)
      .suggestions(exclude: const <String>{});

  /// Follows somebody from the suggestions grid and remembers it.
  ///
  /// The id is remembered rather than the tile being removed: they are still
  /// someone you may know, the button just has nothing left to do. A private
  /// account answers with a REQUEST rather than a follow, which is the same
  /// thing as far as this tile is concerned.
  Future<Result<void, AppException>> follow(String personId) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .toggleFollow(personId, isFollowing: false);
    final current = state.valueOrNull;
    if (result.isSuccess && current != null) {
      state = AsyncValue.data(
        current.copyWith(sentTo: {...current.sentTo, personId}),
      );
    }
    return result.map<void>((_) {});
  }
}

final networkNotifierProvider =
    AsyncNotifierProvider<NetworkNotifier, NetworkOverview>(NetworkNotifier.new);
