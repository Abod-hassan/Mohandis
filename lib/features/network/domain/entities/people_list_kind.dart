/// Which relationship a people list is showing.
///
/// Three lists, three different edges, and the module keeps them apart on
/// purpose — a connection is bidirectional and negotiated (request → accept),
/// a follow is one-way and unilateral. That is also why the row action differs
/// per kind rather than being one "remove" button: only [connections] can be
/// torn down with `Connections/Remove`, only [following] with
/// `Profiles/Unfollow`, and [followers] is somebody else's edge — the viewer
/// cannot undo it at all, they can only block.
enum PeopleListKind {
  /// Accepted connections. `POST /api/social/Connections`.
  connections,

  /// People who follow this profile. `GET /api/social/Profiles/followers/{id}`.
  followers,

  /// People this profile follows. `GET /api/social/Profiles/following/{id}`.
  following;

  /// Everything that is not `followers` reads as [following] — including the
  /// old `connections` spelling. The app no longer has connections, and an old
  /// bookmark or a typo'd deep link must not be the one door left open onto a
  /// screen that can tear one down.
  static PeopleListKind fromWire(String? raw) => switch (raw?.trim()) {
    'followers' => PeopleListKind.followers,
    _ => PeopleListKind.following,
  };

  String get wire => name;

  /// True when the viewer, looking at their OWN list, can undo the edge.
  ///
  /// False for [followers]: those rows are other people's follows. Offering an
  /// "unfollow" there would be a button that either does nothing or silently
  /// unfollows someone the viewer never followed.
  bool get isRevocable => this != PeopleListKind.followers;
}

/// Key for the people-list provider family.
///
/// A record rather than a class so the structural equality Riverpod needs for
/// family caching comes for free.
typedef PeopleListArgs = ({PeopleListKind kind, String profileId});
