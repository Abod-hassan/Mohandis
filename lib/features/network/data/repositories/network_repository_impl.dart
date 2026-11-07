import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/features/shared/people/data/dtos/person_dto.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../../domain/entities/connection_request.dart';
import '../../domain/entities/people_list_kind.dart';
import '../../domain/repositories/network_repository.dart';
import '../dtos/connection_request_dto.dart';

/// The network tab, served by the module's `ConnectionsController`.
///
/// Connections are the LinkedIn-style bidirectional edge (request → accept),
/// which is a different relation from following — `ProfilesController` owns
/// that one. The two must not be crossed: accepting a connection does not
/// follow anybody.
class NetworkRepositoryImpl implements NetworkRepository {
  NetworkRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// How many profiles to draw on for the suggestions grid. Larger than the
  /// grid needs, because the pool is filtered down client-side.
  static const int _suggestionPoolSize = 40;

  /// How many tiles the grid shows once filtering is done.
  static const int _suggestionLimit = 8;

  @override
  Future<Result<List<Person>, AppException>> people({
    required PeopleListKind kind,
    required String profileId,
    int page = 1,
    int size = 100,
  }) {
    final query = {'page': page, 'size': size};

    // Connections is a POST with a filter body; the two follow lists are GETs
    // with the id in the path. All three answer `ProfileSimplifiedDto[]`, so
    // one parser covers them.
    return switch (kind) {
      PeopleListKind.connections => apiCall(
        EndPoints.connections,
        () => _api.dio.post<dynamic>(
          EndPoints.connections,
          // `pending: false` — accepted edges only. Without it the list mixes
          // in requests that were never answered, and "remove" on one of those
          // reads as removing a connection the viewer never had.
          data: {'profileId': profileId, 'pending': false},
          queryParameters: query,
        ),
        _people,
      ),
      PeopleListKind.followers => apiCall(
        EndPoints.profileFollowers(profileId),
        () => _api.dio.get<dynamic>(
          EndPoints.profileFollowers(profileId),
          queryParameters: query,
        ),
        _people,
      ),
      PeopleListKind.following => apiCall(
        EndPoints.profileFollowing(profileId),
        () => _api.dio.get<dynamic>(
          EndPoints.profileFollowing(profileId),
          queryParameters: query,
        ),
        _people,
      ),
    };
  }

  static List<Person> _people(ApiEnvelope envelope) => envelope.list
      .map((j) => PersonDto.fromJson(j).toDomain())
      .toList(growable: false);

  @override
  Future<Result<void, AppException>> removeConnection(String personId) =>
      _act(EndPoints.connectionsRemove, personId);

  @override
  Future<Result<void, AppException>> unfollow(String personId) =>
      _act(EndPoints.profileUnfollow, personId);

  /// Both endpoints take `targetId` and answer a small state object the list
  /// has no use for, so the payload is discarded and only success is kept.
  Future<Result<void, AppException>> _act(String path, String personId) async {
    final result = await apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        queryParameters: {'targetId': personId},
      ),
      (envelope) => null,
    );
    return result.map<void>((_) {});
  }

  @override
  Future<Result<List<ConnectionRequest>, AppException>> requests() => apiCall(
    EndPoints.connectionRequests,
    () => _api.dio.get<dynamic>(
      EndPoints.connectionRequests,
      queryParameters: {'page': 1, 'size': 50},
    ),
    (envelope) => envelope.list
        .map((j) => ConnectionRequestDto.fromJson(j).toDomain())
        .toList(growable: false),
  );

  /// "People you may know", assembled client-side.
  ///
  /// The module has **no recommender** — `ConnectionsController` exposes the
  /// edges and the inbound requests and nothing that proposes people — so this
  /// is the profile directory with everyone already spoken for removed: me,
  /// the people I already follow, and anyone followed earlier this session.
  ///
  /// What it CAN do is order them. The read is `detailed: true`, which answers
  /// `ProfileDto` rows carrying `industry` and `headline`, and people in the
  /// viewer's own field come first. That is not a recommender, but "someone who
  /// does what I do" is the single strongest signal a professional network has,
  /// and reading it costs the same request as the unordered slice did.
  ///
  /// Best-effort by design: a failure here yields an empty grid, never an
  /// error screen — the Network tab is the grid, and half a grid beats a red
  /// page.
  @override
  Future<List<Person>> suggestions({required Set<String> exclude}) async {
    // ONE read of `Me`, for both the id and the field. `ProfilesController.Me`
    // always projects a full `ProfileDto` — there is no lighter variant — so a
    // second call for `industry` was the same request twice.
    final me = await apiCall(
      EndPoints.profilesMe,
      () => _api.dio.get<dynamic>(EndPoints.profilesMe),
      (envelope) {
        final rows = envelope.list;
        if (rows.isEmpty) return (id: '', industry: '');
        return (
          id: '${rows.first['id'] ?? ''}',
          industry: '${rows.first['industry'] ?? ''}'.trim().toLowerCase(),
        );
      },
    );
    final myId = me.valueOrNull?.id ?? '';
    final mine = me.valueOrNull?.industry ?? '';
    if (myId.isEmpty) return const [];

    // People already followed — the one thing a "people you may know" grid
    // must never show. This used to read `Connections`; the app follows now,
    // so the edge to exclude is the follow.
    final followedCall = apiCall(
      EndPoints.profileFollowing(myId),
      () => _api.dio.get<dynamic>(
        EndPoints.profileFollowing(myId),
        queryParameters: {'page': 1, 'size': 200},
      ),
      (envelope) => envelope.list.map((j) => '${j['id'] ?? ''}').toSet(),
    );

    // `detailed: true` so the rows carry `industry`. `PersonDto` reads the
    // subset it needs out of the same payload — a ProfileDto is a superset of
    // the simplified projection, so nothing needs a second parser.
    final poolCall = apiCall(
      EndPoints.profiles,
      () => _api.dio.post<dynamic>(
        EndPoints.profiles,
        data: const <String, dynamic>{},
        queryParameters: {
          'detailed': true,
          'page': 1,
          'size': _suggestionPoolSize,
        },
      ),
      (envelope) => [
        for (final row in envelope.list)
          (
            person: PersonDto.fromJson(row).toDomain(),
            // Only on the DETAILED projection, which is why this read asks for
            // one. `accountType` is on both and comes through `Person`.
            industry: '${row['industry'] ?? ''}'.trim().toLowerCase(),
          ),
      ],
    );

    final followed = (await followedCall).valueOrNull ?? const <String>{};
    final pool = (await poolCall).valueOrNull ?? const [];

    final candidates = pool
        .where(
          (row) =>
              row.person.id.isNotEmpty &&
              row.person.id != myId &&
              // Companies belong here now: the tile follows, and a company is
              // followed like anyone else. It only had to be excluded while
              // the tile sent a CONNECT request, which the server refused.
              !followed.contains(row.person.id) &&
              !exclude.contains(row.person.id),
        )
        .toList();

    // Stable within each half: `sort` is not guaranteed stable in Dart, so the
    // two groups are partitioned rather than sorted — which also keeps the
    // server's own ordering inside each.
    if (mine.isNotEmpty) {
      final sameField = [
        for (final row in candidates)
          if (row.industry == mine) row.person,
      ];
      final rest = [
        for (final row in candidates)
          if (row.industry != mine) row.person,
      ];
      return [...sameField, ...rest].take(_suggestionLimit).toList(
            growable: false,
          );
    }

    return candidates
        .map((row) => row.person)
        .take(_suggestionLimit)
        .toList(growable: false);
  }


  // Accept and Ignore take the REQUESTER's id — answering someone else's
  // request — while Connect takes the TARGET's. Same id in this feature, but
  // the parameter names are not interchangeable server-side.
  @override
  Future<Result<void, AppException>> accept(String personId) =>
      _action(EndPoints.connectionsAccept, 'requesterId', personId);

  @override
  Future<Result<void, AppException>> ignore(String personId) =>
      _action(EndPoints.connectionsIgnore, 'requesterId', personId);

  @override
  Future<Result<void, AppException>> connect(String personId) =>
      _action(EndPoints.connectionsConnect, 'targetId', personId);

  /// Runs one connection action. The responses differ — `Connect` answers a
  /// `ConnectionStateDto`, the rest answer a bare `true` — and none of them is
  /// worth reading here: the tab reloads the rows it changed.
  Future<Result<void, AppException>> _action(
    String path,
    String parameter,
    String personId,
  ) {
    return apiCall<void>(
      path,
      () => _api.dio.post<dynamic>(
        path,
        queryParameters: {parameter: personId},
      ),
      (_) {},
    );
  }
}

final networkRepositoryProvider = Provider<NetworkRepository>((ref) {
  return NetworkRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
