import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/features/shared/people/data/dtos/person_dto.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import '../../domain/entities/connection_request.dart';
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
  Future<Result<NetworkOverview, AppException>> overview() async {
    // The requests list is the tab. If it fails the screen fails — there is
    // nothing honest to render in its place.
    final requests = await apiCall(
      EndPoints.connectionRequests,
      () => _api.dio.get<dynamic>(
        EndPoints.connectionRequests,
        queryParameters: {'page': 1, 'size': 50},
      ),
      (envelope) => envelope.list
          .map((j) => ConnectionRequestDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
    if (requests.isFailure) {
      return Result.failure(requests.errorOrNull!);
    }

    final rows = requests.valueOrNull!;
    final suggestions = await _suggestions(
      exclude: {for (final r in rows) r.personId},
    );

    return Result.success(
      NetworkOverview(requests: rows, suggestions: suggestions),
    );
  }

  /// "People you may know", assembled client-side.
  ///
  /// The module has **no recommender** — `ConnectionsController` exposes the
  /// edges and the inbound requests and nothing that proposes people — so this
  /// is the profile directory with everyone already spoken for removed: me, my
  /// accepted connections, and anyone whose request is already sitting in the
  /// list above.
  ///
  /// What it CAN do is order them. The read is `detailed: true`, which answers
  /// `ProfileDto` rows carrying `industry` and `headline`, and people in the
  /// viewer's own field come first. That is not a recommender, but "someone who
  /// does what I do" is the single strongest signal a professional network has,
  /// and reading it costs the same request as the unordered slice did.
  ///
  /// Best-effort by design: a failure here yields an empty grid, never an error
  /// screen. Losing the suggestions is a much smaller loss than losing the
  /// requests they sit under.
  Future<List<Person>> _suggestions({required Set<String> exclude}) async {
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

    // Existing connections — already-connected people are the one thing a
    // "people you may know" grid must never show.
    final connectedCall = apiCall(
      EndPoints.connections,
      () => _api.dio.post<dynamic>(
        EndPoints.connections,
        data: {'profileId': myId, 'pending': false},
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

    final connected = (await connectedCall).valueOrNull ?? const <String>{};
    final pool = (await poolCall).valueOrNull ?? const [];

    final candidates = pool
        .where(
          (row) =>
              row.person.id.isNotEmpty &&
              row.person.id != myId &&
              // A company is followed, not connected to — and every tile in
              // this grid sends a CONNECT request, which the server refuses.
              !row.person.isCompany &&
              !connected.contains(row.person.id) &&
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
