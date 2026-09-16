import 'package:flutter_mobile_template/core/base/base_entity.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

/// An inbound request to connect, keyed by the requesting person.
///
/// The person is carried inline rather than looked up in the directory: the
/// module answers `GET /api/social/Connections/requests` with the requesters'
/// own `ProfileSimplifiedDto` rows, so the name and headline always resolve —
/// where a directory lookup only covers the first page of profiles and misses
/// anyone past it.
///
/// There is no `mutualCount` or `requestedAt` here on purpose. The module
/// projects requests down to a profile and keeps neither the edge's timestamp
/// nor a mutual-connection count in that projection, and inventing either
/// would put a number on screen that no server ever said.
class ConnectionRequest extends BaseEntity {
  const ConnectionRequest({required this.person});

  @override
  String get id => person.id;

  final Person person;

  /// The requester's ProfileId — what `Accept` and `Ignore` take as
  /// `requesterId`.
  String get personId => person.id;
}

/// The network tab's full payload: pending requests plus suggestions.
class NetworkOverview {
  const NetworkOverview({
    required this.requests,
    required this.suggestions,
    this.sentTo = const <String>{},
  });

  final List<ConnectionRequest> requests;

  /// The "people you may know" grid.
  final List<Person> suggestions;

  /// Ids this session has raised an outbound request to.
  ///
  /// The module has no endpoint listing *outgoing* pending requests — only
  /// incoming ones — so a sent request cannot be re-read on the next load. It
  /// is held here, rather than in the tile's own [State], so the card keeps
  /// showing "sent" across a scroll or a rebuild.
  final Set<String> sentTo;

  bool hasSentTo(String personId) => sentTo.contains(personId);

  NetworkOverview copyWith({
    List<ConnectionRequest>? requests,
    List<Person>? suggestions,
    Set<String>? sentTo,
  }) {
    return NetworkOverview(
      requests: requests ?? this.requests,
      suggestions: suggestions ?? this.suggestions,
      sentTo: sentTo ?? this.sentTo,
    );
  }
}
