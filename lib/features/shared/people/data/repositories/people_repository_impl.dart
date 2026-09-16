import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/person.dart';
import '../../domain/repositories/people_repository.dart';
import '../dtos/person_dto.dart';

/// The people directory, served by the module's `ProfilesController`.
///
/// There is no separate "people" API — a person IS a profile in its light
/// projection, so this is `POST /api/social/Profiles` with `detailed=false`.
class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// One page of profiles.
  ///
  /// [query] accepts `search` (free text over name/username) and `page`/`size`.
  /// Note this is genuinely paged — it is NOT "every person on the platform",
  /// so nothing may assume an id will be in the result.
  @override
  Future<Result<List<Person>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) {
    final search = query?['search'] ?? query?['q'];
    return apiCall(
      EndPoints.profiles,
      () => _api.dio.post<dynamic>(
        EndPoints.profiles,
        data: {if (search != null) 'search': '$search'},
        queryParameters: {
          'detailed': false,
          'page': query?['page'] ?? 1,
          'size': query?['size'] ?? 50,
        },
      ),
      (envelope) => envelope.list
          .map((j) => PersonDto.fromJson(j).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<Person, AppException>> getById(String id) {
    final path = EndPoints.profileById(id);
    return apiCall(path, () => _api.dio.get<dynamic>(path), (envelope) {
      final rows = envelope.list;
      if (rows.isEmpty) throw const NotFoundException('Person not found');
      return PersonDto.fromJson(rows.first).toDomain();
    });
  }

  @override
  Future<Result<Person, AppException>> me() {
    return apiCall(
      EndPoints.profilesMe,
      () => _api.dio.get<dynamic>(EndPoints.profilesMe),
      (envelope) {
        final rows = envelope.list;
        if (rows.isEmpty) {
          throw const UnauthorizedException(
            'No profile for the signed-in user',
          );
        }
        return PersonDto.fromJson(rows.first).toDomain();
      },
    );
  }

  @override
  Future<Result<List<Person>, AppException>> search(String query) =>
      getAll(query: {'search': query});

  @override
  Future<Result<Person, AppException>> create(Map<String, dynamic> body) async =>
      const Result.failure(
        ForbiddenException('People are not created from the mobile client'),
      );

  @override
  Future<Result<Person, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async => const Result.failure(
    ForbiddenException('Use ProfileRepository.updateMe to edit a profile'),
  );

  @override
  Future<Result<void, AppException>> delete(String id) async =>
      const Result.failure(
        ForbiddenException('People are not deleted from the mobile client'),
      );
}

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return PeopleRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// The signed-in person, resolved once and cached for the session. Every
/// surface that renders "me" (top bar avatar, composer header, apply review)
/// reads this rather than threading a user object through arguments.
///
/// This is also how the app learns its own **ProfileId**: the JWT carries an
/// auth ContactId, which is a different key, and the module translates between
/// them server-side.
final currentPersonProvider = FutureProvider<Person>((ref) async {
  final result = await ref.watch(peopleRepositoryProvider).me();
  return result.when(success: (p) => p, failure: (e) => throw e);
});

/// Id → [Person] lookup for surfaces that render an author, participant or
/// actor name.
///
/// **Only the first page.** Against the mock backend this was the whole cast;
/// against the real one it is one page of profiles, so a miss is normal and
/// every caller must have a fallback — posts, comments and messages all carry
/// their author's name inline for exactly this reason. Never gate rendering on
/// a hit here.
final peopleDirectoryProvider = FutureProvider<Map<String, Person>>((ref) async {
  final result = await ref.watch(peopleRepositoryProvider).getAll();
  return result.when(
    success: (people) => {for (final p in people) p.id: p},
    failure: (e) => throw e,
  );
});


/// The best [Person] record available for [id], newest first.
///
/// Three sources, in order:
///
///   1. **The viewer's own record.** They can change their photo or name and
///      come straight back to a screen whose posts, stories and reels were
///      loaded before the change; the copy inlined on those rows is stale and
///      nothing refetches them. `currentPersonProvider` is invalidated on save,
///      so preferring it keeps every surface showing the same person to
///      themselves without a refetch.
///   2. **The directory**, which carries the headline and location that a post,
///      story or reel payload does not — and is refreshed by the same
///      invalidation. It holds one page, so a miss is ordinary.
///   3. **[inline]**, the author the backend denormalises onto every row. Always
///      present, never stale on first load, and the reason a card never has to
///      wait on a lookup.
///
/// Read it with a `ref` that is already in a build; it watches, so a refreshed
/// cache rebuilds the caller.
Person resolveAuthor(WidgetRef ref, String id, Person inline) {
  final me = ref.watch(currentPersonProvider).valueOrNull;
  if (me != null && me.id == id) return me;
  return ref.watch(peopleDirectoryProvider).valueOrNull?[id] ?? inline;
}
