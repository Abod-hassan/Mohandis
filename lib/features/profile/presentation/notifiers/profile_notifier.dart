import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';

import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// One profile screen's state, keyed by person id.
class ProfileNotifier extends FamilyAsyncNotifier<Profile, String> {
  @override
  Future<Profile> build(String personId) => _read(personId);

  /// Re-reads the profile, publishing a loading state first.
  ///
  /// For pull-to-refresh and for the error view's retry, where the placeholder
  /// that replaces the content IS the feedback that something is happening.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _read(arg));
  }

  /// Re-reads the profile WITHOUT publishing a loading state.
  ///
  /// For a caller already showing its own placeholder — the profile screen
  /// does, on every entry, so that it never paints the copy it cached on an
  /// earlier visit.
  ///
  /// Skipping the loading publish matters because this provider is not
  /// autoDispose and is not read only by the screen in front of you:
  /// `companyJobsNotifier` watches `me`'s future, and the apply, job-detail
  /// and company-job-form screens read it. A loading state broadcast from here
  /// suspends every one of them — `companyJobsNotifier` would re-run and
  /// refetch the company's whole job list — over a re-read that is none of
  /// their business. This way they keep the profile they have until the new
  /// one lands.
  Future<void> reload() async {
    state = await AsyncValue.guard(() => _read(arg));
  }

  /// The read itself: the profile plus its three CV sections.
  ///
  /// Takes the id rather than reading `arg`, so `build` — the one caller that
  /// runs before `arg` is anybody's to rely on — passes its own parameter.
  Future<Profile> _read(String personId) async {
    final result =
        await ref.read(profileRepositoryProvider).byPerson(personId);
    return result.when(success: (p) => p, failure: (e) => throw e);
  }

  Future<Result<Profile, AppException>> toggleFollow() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(following: !current.following));
    }
    // The backend has separate Follow and Unfollow actions rather than one
    // toggle, so the direction is passed explicitly — and from the state
    // BEFORE the optimistic flip above, not after it.
    final result = await ref
        .read(profileRepositoryProvider)
        .toggleFollow(arg, isFollowing: current?.following);
    result.when(
      success: (p) => state = AsyncValue.data(p),
      failure: (_) {
        if (current != null) state = AsyncValue.data(current);
      },
    );
    return result;
  }

  /// Sends a connection request.
  ///
  /// Optimistic on the way out — the button flips to "request sent" on tap —
  /// and reconciled with whatever the server reports, which for a private or
  /// already-connected profile may not be `outgoing` at all.
  Future<Result<Profile, AppException>> connect() => _connectionAction(
    (repository) => repository.connect(arg),
    optimistic: (p) => p.copyWith(connectionOutgoing: true),
  );

  Future<Result<Profile, AppException>> acceptConnection() =>
      _connectionAction(
        (repository) => repository.acceptConnection(arg),
        optimistic: (p) =>
            p.copyWith(connected: true, connectionIncoming: false),
      );

  Future<Result<Profile, AppException>> ignoreConnection() =>
      _connectionAction(
        (repository) => repository.ignoreConnection(arg),
        optimistic: (p) => p.copyWith(connectionIncoming: false),
      );

  /// Removes a connection, or withdraws a request that hasn't been answered.
  Future<Result<Profile, AppException>> removeConnection() =>
      _connectionAction(
        (repository) => repository.removeConnection(arg),
        optimistic: (p) =>
            p.copyWith(connected: false, connectionOutgoing: false),
      );

  Future<Result<Profile, AppException>> _connectionAction(
    Future<Result<Profile, AppException>> Function(ProfileRepository) call, {
    required Profile Function(Profile) optimistic,
  }) async {
    final current = state.valueOrNull;
    if (current != null) state = AsyncValue.data(optimistic(current));

    final result = await call(ref.read(profileRepositoryProvider));
    result.when(
      success: (p) => state = AsyncValue.data(p),
      failure: (_) {
        if (current != null) state = AsyncValue.data(current);
      },
    );
    return result;
  }

  /// Endorses one skill row. Addressed by the row's int id — a skill name is
  /// not unique across profiles.
  Future<Result<Profile, AppException>> endorse(int skillId) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .endorseSkill(personId: arg, skillId: skillId);
    result.when(
      success: (p) => state = AsyncValue.data(p),
      failure: (_) {},
    );
    return result;
  }

  // ── CV sections ──────────────────────────────────────────────────────────
  //
  // Every one of these answers with the reloaded profile, so the section
  // rebuilds from the server rather than from a patched local copy. Nothing is
  // optimistic: a CV edit is a deliberate, low-frequency action where being
  // right matters more than being instant.

  Future<Result<Profile, AppException>> saveExperience(Experience entry) =>
      _sectionWrite((r) => r.saveExperience(entry));

  Future<Result<Profile, AppException>> deleteExperience(int id) =>
      _sectionWrite((r) => r.deleteExperience(id));

  Future<Result<Profile, AppException>> saveEducation(Education entry) =>
      _sectionWrite((r) => r.saveEducation(entry));

  Future<Result<Profile, AppException>> deleteEducation(int id) =>
      _sectionWrite((r) => r.deleteEducation(id));

  Future<Result<Profile, AppException>> saveSkill({
    required String name,
    int id = 0,
  }) => _sectionWrite((r) => r.saveSkill(name: name, id: id));

  Future<Result<Profile, AppException>> deleteSkill(int id) =>
      _sectionWrite((r) => r.deleteSkill(id));

  Future<Result<Profile, AppException>> _sectionWrite(
    Future<Result<Profile, AppException>> Function(ProfileRepository) call,
  ) async {
    final result = await call(ref.read(profileRepositoryProvider));
    result.when(
      success: (p) => state = AsyncValue.data(p),
      failure: (_) {},
    );
    return result;
  }

  /// Saves the signed-in user's edits. Only valid on the `me` profile.
  ///
  /// A successful save also drops the two people caches. They are what the
  /// feed, search, messages and notifications draw an avatar and a name from —
  /// none of them reads a `Profile` — so without this the person changes their
  /// photo, sees it on their own profile, and goes back to a home page still
  /// showing the old one until the app restarts.
  ///
  /// Invalidating rather than patching: `updateMe` returns the whole profile,
  /// but `Person` is a different projection of a different endpoint, and
  /// hand-merging one into the other is how the two drift apart. A refetch of
  /// two small reads is the cheaper thing to get right. Riverpod carries the
  /// previous value through the reload, so nothing flashes empty meanwhile.
  Future<Result<Profile, AppException>> save(Map<String, dynamic> body) async {
    final result = await ref.read(profileRepositoryProvider).updateMe(body);
    result.when(
      success: (p) {
        state = AsyncValue.data(p);
        ref.invalidate(currentPersonProvider);
        ref.invalidate(peopleDirectoryProvider);
      },
      failure: (_) {},
    );
    return result;
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider.family<ProfileNotifier, Profile, String>(
  ProfileNotifier.new,
);


/// Whether the signed-in account is a company.
///
/// **False while the profile is still loading**, and that is deliberate: this
/// decides which tab bar the shell draws, and briefly showing the individual
/// set is far less jarring than an empty bar or a spinner where the navigation
/// should be. The profile is a single small read that the shell triggers on
/// first build, so the window is brief.
///
/// **A failed read keeps whatever was decided last**, which is the reason this
/// is a `Notifier` rather than two lines over `valueOrNull`. Riverpod reports
/// an error with no value, so reading the type straight off the AsyncValue
/// would drop a company back to the individual tabs the moment one profile
/// request fails — taking away, among others, the tab holding the retry. The
/// last known answer survives until a successful read replaces it.
///
/// The account type lives on the social profile, not on the auth contact, so it
/// has to come from the server — but it does NOT need the full profile.
///
/// This used to watch `profileNotifierProvider('me')`, which the shell builds on
/// every launch to decide which tab set to show. `byPerson` fetches the profile
/// AND its three CV sections, so one boolean on a nav bar cost four requests:
/// `Profiles/Me`, `Experience`, `Education`, `Skills`.
///
/// `currentPersonProvider` answers the same question from `Profiles/Me` alone —
/// `ProfileSimplifiedDto` carries `accountType`, which is what `Person.isCompany`
/// is parsed from — and the feed's top bar already watches it for the avatar, so
/// on the launch path this is now free.
class IsCompanyAccount extends Notifier<bool> {
  /// The last answer an actual profile gave.
  ///
  /// A plain field rather than a read of `state`: `build` cannot read the
  /// state it is in the middle of producing, and Riverpod re-runs `build` on
  /// the *same* notifier instance when a watched provider changes — so this
  /// survives exactly as long as the answer should. A full invalidation
  /// disposes the notifier and resets it to false, which is right: that means
  /// "start over".
  bool _last = false;

  @override
  bool build() {
    final resolved = ref.watch(currentPersonProvider).valueOrNull;
    if (resolved != null) {
      _last = resolved.isCompany;
    }
    return _last;
  }
}

final isCompanyAccountProvider = NotifierProvider<IsCompanyAccount, bool>(
  IsCompanyAccount.new,
);
