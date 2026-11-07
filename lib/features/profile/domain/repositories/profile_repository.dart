import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/profile.dart';

/// Profiles are read by person id and only ever written for the signed-in
/// user, so this deliberately does not extend `BaseRepository` — the generic
/// CRUD surface would advertise operations the backend refuses.
abstract class ProfileRepository {
  /// The full profile: identity, counts, viewer-relative flags, and the three
  /// CV sections (experience, education, skills) fetched alongside.
  ///
  /// Pass [meSentinel] as [personId] for the signed-in user. The module keys
  /// everything by ProfileId, which the client cannot derive from its auth
  /// token, so "me" has to be resolved by the server.
  Future<Result<Profile, AppException>> byPerson(String personId);

  /// The profile id behind an `@handle`, for a tapped mention — a mention is
  /// stored as text, so the handle is all the client has. Fails with
  /// [NotFoundException] when no profile has it.
  Future<Result<String, AppException>> idForUsername(String username);

  /// The id that means "whoever is holding the bearer token".
  static const String meSentinel = 'me';

  /// Saves the signed-in user's profile edits.
  ///
  /// [body] keys: `name`, `headline`, `industry`, `location`, `about`,
  /// `website`, `avatarUrl`, `coverUrl`, `openToWork`, `isPrivate` — the keys
  /// the edit screen sends — plus `accountType`, which takes an [AccountType]
  /// value rather than a string and is set once at sign-up.
  ///
  /// Company accounts additionally send `companySize` (a [CompanySize] value),
  /// `foundedOn` (a `DateTime?`, sent as yyyy-MM-dd; an explicit null clears it) and
  /// `specialties` (either a `List<String>` or the raw newline-separated
  /// text). Only the keys present are written, so an individual saving their
  /// headline never stamps company columns onto their row.
  Future<Result<Profile, AppException>> updateMe(Map<String, dynamic> body);

  /// Writes the same fields as [updateMe] and does NOT read the profile back.
  ///
  /// For callers that only want the write to land. [updateMe] costs a read of
  /// the profile and its three CV sections afterwards, which is four requests
  /// spent on a value they would discard.
  Future<Result<void, AppException>> patchMe(Map<String, dynamic> body);

  /// Follows or unfollows [personId].
  ///
  /// [isFollowing] is the state being toggled AWAY from — the backend has
  /// separate Follow and Unfollow actions rather than one toggle, so the
  /// caller has to say which way it is going. Pass null to have the repository
  /// read the current state first (one extra round-trip).
  Future<Result<Profile, AppException>> toggleFollow(
    String personId, {
    bool? isFollowing,
  });

  /// Sends a connection request — the "add" button.
  ///
  /// Returns the profile as the server sees it afterwards, so the button can
  /// render the state that actually exists (`connectionOutgoing` for a request
  /// awaiting their answer) rather than assuming success meant "connected".
  Future<Result<Profile, AppException>> connect(String personId);

  /// Accepts an inbound request from [personId].
  Future<Result<Profile, AppException>> acceptConnection(String personId);

  /// Dismisses an inbound request from [personId].
  Future<Result<Profile, AppException>> ignoreConnection(String personId);

  /// Removes an accepted connection — and withdraws one still pending, which
  /// is what "cancel request" maps to.
  Future<Result<Profile, AppException>> removeConnection(String personId);

  /// Blocks [personId] — bidirectional, and the server tears down any follow
  /// edges in both directions as it goes.
  ///
  /// Returns nothing: after a block the target's profile is no longer readable
  /// by the caller, so re-reading it the way every other action here does
  /// would answer with a not-found and turn a success into an error.
  /// Lets [followerId] follow this (private) account —
  /// `POST Profiles/AcceptRequest?followerId=`.
  Future<Result<void, AppException>> acceptFollowRequest(String followerId);

  /// Turns down a follow request — `POST Profiles/RejectRequest?followerId=`.
  /// The server treats an already-gone request as success.
  Future<Result<void, AppException>> rejectFollowRequest(String followerId);

  Future<Result<void, AppException>> block(String personId);

  /// Lifts a block the caller placed. Does not restore the follow edges the
  /// block removed — those are gone, and either side may follow again.
  Future<Result<void, AppException>> unblock(String personId);

  /// Toggles the caller's endorsement of one skill row.
  ///
  /// Addressed by the skill's int id, not its name: names are not unique
  /// across profiles.
  Future<Result<Profile, AppException>> endorseSkill({
    required String personId,
    required int skillId,
  });

  // ── CV sections ──────────────────────────────────────────────────────────
  //
  // The module exposes reads only (`POST Experience` / `Education` / `Skills`);
  // every write goes through the Kernel's generic write engine, so these all
  // resolve the caller's own ProfileId first and answer with the reloaded
  // profile rather than the written row.

  /// Creates [entry] when its id is `0`, otherwise updates that row.
  Future<Result<Profile, AppException>> saveExperience(Experience entry);

  Future<Result<Profile, AppException>> deleteExperience(int id);

  /// Creates [entry] when its id is `0`, otherwise updates that row.
  Future<Result<Profile, AppException>> saveEducation(Education entry);

  Future<Result<Profile, AppException>> deleteEducation(int id);

  /// Adds a skill by name, or renames the row when [id] is non-zero.
  Future<Result<Profile, AppException>> saveSkill({
    required String name,
    int id = 0,
  });

  Future<Result<Profile, AppException>> deleteSkill(int id);
}
