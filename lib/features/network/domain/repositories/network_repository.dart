import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../entities/connection_request.dart';
import '../entities/people_list_kind.dart';

abstract class NetworkRepository {
  /// Inbound connection requests. `GET /Connections/requests`.
  ///
  /// Split out of the old `overview()` because the bottom-nav badge needs this
  /// number on EVERY launch, while the suggestions grid below it is only ever
  /// looked at on the Network tab. Fused together, one integer on a nav bar
  /// cost four requests at startup — this call plus the three [suggestions]
  /// makes — for a tab the user had not opened.
  Future<Result<List<ConnectionRequest>, AppException>> requests();

  /// "People you may know". Three requests; call it only when the grid is
  /// about to be rendered.
  ///
  /// [exclude] is the set of ids already spoken for — normally the requesters
  /// from [requests], since someone with a pending request is not a suggestion.
  Future<List<Person>> suggestions({required Set<String> exclude});

  Future<Result<void, AppException>> accept(String personId);

  /// Dismisses an inbound request. Idempotent — dismissing twice succeeds.
  Future<Result<void, AppException>> ignore(String personId);

  /// Sends an outbound connection request.
  Future<Result<void, AppException>> connect(String personId);

  /// One page of a profile's connections, followers or following.
  ///
  /// [profileId] is a real ProfileId, never the `me` sentinel — the three
  /// module endpoints behind this all take the id in the path or the body and
  /// none of them resolves "the caller". The profile screen already holds it,
  /// which is where every entry point to these lists is.
  Future<Result<List<Person>, AppException>> people({
    required PeopleListKind kind,
    required String profileId,
    int page = 1,
    int size = 100,
  });

  /// Tears down an accepted connection. `POST Connections/Remove`.
  ///
  /// `ProfileRepository.removeConnection` does the same thing and then re-reads
  /// the whole profile, because the button it serves has to render the state
  /// that resulted. A list row does not: it removes itself, and paying for a
  /// full `ProfileDto` plus its three CV sections per tap would be absurd.
  Future<Result<void, AppException>> removeConnection(String personId);

  /// Drops a follow edge. `POST Profiles/Unfollow`. Same reasoning as
  /// [removeConnection] for why this does not answer with a profile.
  Future<Result<void, AppException>> unfollow(String personId);
}
