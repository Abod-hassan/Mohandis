import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../../data/repositories/network_repository_impl.dart';
import '../../domain/entities/people_list_kind.dart';

/// One profile's connections, followers or following.
///
/// `autoDispose`, deliberately. These rows are a relationship snapshot taken at
/// fetch time, and the relationships are exactly what this screen exists to
/// change — keeping the list alive after the user backs out would show a
/// connection they removed two taps ago, the same trap `savedJobsProvider`
/// documents. It also keeps the list off `AuthNotifier._dropSessionCaches`,
/// since an autoDispose provider drops itself at sign-out.
class PeopleListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Person>, PeopleListArgs> {
  /// True once this notifier's current build has been torn down.
  ///
  /// `revoke` and `refresh` both write `state` AFTER awaiting the network, and
  /// this provider is autoDispose — so backing out of the screen while a
  /// Remove is in flight tears the notifier down before that write lands, and
  /// writing `state` then throws. The tap is exactly the moment someone is
  /// likely to leave, so it is a real crash rather than a theoretical one.
  ///
  /// Reset at the top of every [build], because `onDispose` callbacks
  /// registered during a build also fire when Riverpod REBUILDS — not only on
  /// final disposal. Left unreset, the first rebuild would latch this true and
  /// silently stop every later write.
  bool _disposed = false;

  @override
  Future<List<Person>> build(PeopleListArgs arg) async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return _fetch();
  }

  /// The read itself, shared by [build] and [refresh].
  ///
  /// [refresh] must not call [build]: that would register a second
  /// `onDispose` callback on every pull-to-refresh, one per refresh, for the
  /// life of the screen.
  Future<List<Person>> _fetch() async {
    final result = await ref
        .read(networkRepositoryProvider)
        .people(kind: arg.kind, profileId: arg.profileId);
    return result.when(success: (rows) => rows, failure: (e) => throw e);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final next = await AsyncValue.guard(_fetch);
    if (_disposed) return;
    state = next;
  }

  /// Removes the connection or follow edge behind [personId] and drops the row.
  ///
  /// Optimistic, then reverted on failure. The alternative — waiting on the
  /// round-trip — leaves a row the user already decided about sitting under
  /// their finger, and a refetch afterwards costs a second request to learn
  /// something the response already confirmed.
  ///
  /// Refuses on [PeopleListKind.followers]: that edge belongs to the other
  /// person and neither endpoint would do anything a viewer expects.
  Future<Result<void, AppException>> revoke(String personId) async {
    if (!arg.kind.isRevocable) {
      return Result.failure(
        const UnknownException('This list has no revocable edge.'),
      );
    }

    final before = state.valueOrNull;
    if (before == null) {
      return Result.failure(const UnknownException('List is not loaded.'));
    }

    state = AsyncValue.data(
      before.where((p) => p.id != personId).toList(growable: false),
    );

    final repo = ref.read(networkRepositoryProvider);
    final result = arg.kind == PeopleListKind.connections
        ? await repo.removeConnection(personId)
        : await repo.unfollow(personId);

    if (result.isFailure && !_disposed) {
      // Put the row back exactly where it was. `before` is the pre-edit list,
      // so order is preserved without having to re-sort or refetch.
      state = AsyncValue.data(before);
    }
    return result;
  }
}

final peopleListProvider =
    AsyncNotifierProvider.autoDispose
        .family<PeopleListNotifier, List<Person>, PeopleListArgs>(
          PeopleListNotifier.new,
        );
