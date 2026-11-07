import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/api/session_expiry.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/services/storage_zone.dart';
import 'package:mohandis/core/services/tenant_store.dart';
import 'package:mohandis/features/activity/presentation/notifiers/activity_notifier.dart';
import 'package:mohandis/features/dashboard/presentation/notifiers/dashboard_notifier.dart';
import 'package:mohandis/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:mohandis/features/jobs/presentation/notifiers/jobs_notifier.dart';
import 'package:mohandis/features/messaging/presentation/notifiers/messaging_notifier.dart';
import 'package:mohandis/features/network/presentation/notifiers/network_notifier.dart';
import 'package:mohandis/features/posts/presentation/notifiers/suggested_action_notifier.dart';
import 'package:mohandis/features/panel/presentation/notifiers/panel_notifiers.dart';
import 'package:mohandis/features/posts/presentation/notifiers/feed_notifier.dart';
import 'package:mohandis/features/reels/presentation/notifiers/reels_notifier.dart';
import 'package:mohandis/features/shared/notifications/data/fcm_setup_service.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/features/stories/presentation/notifiers/stories_notifier.dart';
import 'package:mohandis/features/subscription/presentation/notifiers/subscription_notifier.dart';

import 'package:mohandis/features/profile/data/profile_setup_store.dart';
import 'package:mohandis/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';

import '../../data/dtos/mobile_auth_result_dto.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import 'pending_email.dart';
import 'registration_draft.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Feature-scoped provider for the auth repository. Bootstrap may override
/// this with a mock implementation when `AppConfig.useMockData` is true.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    // Only for stamping the account type after sign-up — that field lives on
    // the social profile, which auth knows nothing else about.
    profileRepository: ref.watch(profileRepositoryProvider),
    // Awaited inside the auth calls rather than read: a tenant that hasn't
    // landed yet means a request the server refuses outright, so it is worth
    // one round-trip to be sure.
    resolveTenantId: () => ref.read(tenantProvider.notifier).resolve(),
  );
});

/// Holds the currently authenticated session (or `null` if signed out).
///
/// On startup, checks for a stored access token and validates it against the
/// backend. Login / logout mutate state through dedicated methods rather than
/// reassigning `state` externally.
///
/// **Session guardrail (ARCHITECTURE.md §8.3):**
/// * A definitive `UnauthorizedException` clears the session.
/// * A network / 5xx / timeout error keeps whatever tokens are on disk and
///   hydrates a partial session — the user is NOT signed out, and the next
///   real request triggers interceptor-driven refresh.
///
/// That second rule only applies to a token that *could still work*. A stored
/// value that is not a JWT, or one whose `exp` has passed, is not a session
/// worth defending: hydrating from it strands the app on the feed with
/// credentials the server will never accept. This is exactly what a leftover
/// `mock-access-token` from a demo build does — it survives the flavour switch
/// in the Keychain, and with the API unreachable the transient-failure branch
/// would treat it as a live session.
class AuthNotifier extends AsyncNotifier<AuthSession?> {
  /// How long cold start waits for the backend to confirm the stored token.
  ///
  /// Shorter than the Dio connect timeout on purpose: splash is blocked on
  /// this, and a user staring at a logo for 15 seconds because the API host
  /// isn't running is a worse answer than falling back to the local decision.
  static const _probeTimeout = Duration(seconds: 6);

  /// How long sign-in waits for the new account's own profile before opening
  /// the app anyway.
  ///
  /// Shorter than [_probeTimeout] because the stakes are lower: cold start has
  /// nothing to show without an answer, whereas this one only decides whether
  /// the name and photo are on the first frame or the third. Past this the app
  /// opens and the profile catches up — see [_hydrateIdentity].
  static const _identityTimeout = Duration(seconds: 5);

  /// The [SessionExpiry.tick] this notifier has already acted on.
  ///
  /// Riverpod re-runs `build` on the SAME notifier instance when the provider
  /// is invalidated, re-registering the listener each time, so this survives
  /// exactly as long as it should: one sign-out per expiry, however many 401s
  /// raised it and however many times the notifier has been rebuilt since.
  int _handledExpiry = 0;

  @override
  Future<AuthSession?> build() async {
    // Registered FIRST, before any await: `ref.listen` has to run in the
    // synchronous part of build.
    //
    // This is the whole fix for "an expired token shows an error page". The
    // interceptor clears the dead tokens and signals here; without a listener
    // the app kept its AuthSession object, the router kept the person inside
    // the shell, and every tab under it rendered an error view with a retry
    // button that could only ever fail again.
    ref.listen<SessionExpiry>(sessionExpiryProvider, (previous, next) {
      if (next.tick <= _handledExpiry) return;
      _handledExpiry = next.tick;
      // ignore: unawaited_futures
      _endExpiredSession();
    });

    final tokens = ref.read(tokenStorageProvider);
    final access = await tokens.readAccessToken();
    if (access == null || access.isEmpty) return null;

    // Not a token this backend issued — a demo build's leftover, or something
    // corrupt. Clear it so the app stops trying at every cold start.
    if (!MobileAuthResultDto.isJwt(access)) {
      await tokens.clear();
      return null;
    }

    final expiry = MobileAuthResultDto.expiryFromJwt(access);
    final stillValid =
        expiry == null || expiry.isAfter(DateTime.now().toUtc());

    final result = await ref
        .read(authRepositoryProvider)
        .currentSession()
        .timeout(
          _probeTimeout,
          onTimeout: () => const Result.failure(
            NetworkException('تعذّر التحقق من الجلسة'),
          ),
        );

    final session = await result.when(
      success: (s) async => s,
      failure: (e) async {
        if (e is UnauthorizedException) return null;

        // **Transient failure — and the refresh token is the credential.**
        //
        // This used to sign out whenever the ACCESS token had expired, and
        // that was the refresh bug. A cold start a day after login is exactly
        // the case where the access token has expired, and there the probe
        // above is not one round trip but three in a row: `Profiles/Me` → 401
        // → `PUT Refresh-Token` on its own bare Dio → `Profiles/Me` again on
        // the retry client, each on a fresh connection. Against the remote
        // host on a phone that easily runs past [_probeTimeout] — and then the
        // timeout landed here, saw an expired access token, and signed out.
        //
        // Nothing reported it, because nothing had failed: the refresh was
        // still in flight, and usually SUCCEEDED a moment later, storing a
        // fresh pair for an app that was already on the login screen. No
        // refusal, no session-expiry signal, no `[refresh]` line.
        //
        // So: keep the session whenever there is a refresh token to try. The
        // shell's first requests 401, share the refresh already in flight, and
        // replay. If that refresh is REFUSED, the interceptor signals expiry
        // and the listener above ends the session properly, with a reason. A
        // timeout is not a verdict, and must not be treated as one.
        final refresh = await tokens.readRefreshToken();
        final canRefresh = refresh != null && refresh.isNotEmpty;
        if (!stillValid && !canRefresh) return null;

        return AuthSession(
          user: User(
            id: await tokens.readUserId() ?? '',
            name: await tokens.readDisplayName() ?? '',
            userName: await tokens.readUserName(),
          ),
          accessToken: access,
          refreshToken: refresh ?? '',
          accessTokenExpiresAt: expiry,
          refreshTokenExpiresAt: await tokens.readRefreshTokenExpiresAt(),
        );
      },
    );
    if (session != null) {
      // ignore: unawaited_futures
      ref.read(fcmSetupServiceProvider).setAuthenticated(true);
    }
    return session;
  }

  Future<void> login({
    required String userName,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref
        .read(authRepositoryProvider)
        .login(userName: userName, password: password);
    if (result.isSuccess) {
      // Sign-IN drops the same caches sign-OUT does, and it has to.
      //
      // Logout's pass runs while the shell is still mounted, so every
      // `invalidate` there immediately REBUILDS a watched provider — and by
      // then the tokens are already gone. Those rebuilds 401, and because
      // none of these providers are autoDispose the error `AsyncValue` is
      // latched for the rest of the process. The next account to sign in on
      // this device inherits both that error on every tab and, through
      // `currentPersonProvider`, the previous account's name and avatar.
      //
      // Here the router is still on /auth and nothing is watching them, so
      // the invalidate is a plain drop: the shell builds them fresh against
      // the session that was just persisted. This must stay BEFORE `state`
      // is published, because that is what releases the redirect to /feed.
      _dropSessionCaches();
      // Then pull this account's identity back in before anyone can look at
      // it. Still inside the spinner — see [_hydrateIdentity].
      await _hydrateIdentity();
    }
    state = result.when(
      success: AsyncValue.data,
      failure: (e) => AsyncValue.error(e, StackTrace.current),
    );
    if (result.isSuccess) {
      // ignore: unawaited_futures
      ref.read(fcmSetupServiceProvider).setAuthenticated(true);
    }
  }

  /// Step 2 of registration: spends a proved-identity token to create the
  /// account, and publishes the session it returns.
  ///
  /// The form cannot do this itself. Creating the account is the moment the
  /// app gains a session, and that means dropping the previous account's
  /// caches and publishing `state` — both of which belong here for the same
  /// reasons `login` documents.
  Future<Result<AuthSession, AppException>> completeRegistration({
    required RegistrationDraft draft,
    required String registrationToken,
  }) async {
    state = const AsyncValue.loading();

    final result = await ref
        .read(authRepositoryProvider)
        .createWithContact(
          registrationToken: registrationToken,
          fullName: draft.fullName,
          userName: draft.userName,
          phone: draft.phone,
          password: draft.password,
          accountType: draft.accountType,
          gender: draft.gender,
          imageUrl: draft.imageUrl,
        );

    await _adopt(result, freshAccount: true);
    return result;
  }

  /// Publishes a session that arrived from somewhere other than `login` —
  /// today, a verification that turned out to belong to an existing account.
  ///
  /// Someone who forgot they had an account types their number into the
  /// sign-up form and proves it; the server answers with a session rather than
  /// a registration token, and the right response is to let them in rather
  /// than to refuse a duplicate.
  Future<void> adoptSession(AuthSession session) =>
      _adopt(Result.success(session), freshAccount: false);

  /// The shared tail of every way of arriving at a session.
  ///
  /// [freshAccount] marks the profile step pending BEFORE `state` is
  /// published, so the router's first evaluation as an authed user already
  /// sends this person to the profile step rather than flashing the feed on
  /// the way there.
  Future<void> _adopt(
    Result<AuthSession, AppException> result,
    {required bool freshAccount}
  ) async {
    if (result.isSuccess) {
      if (freshAccount) {
        await ref.read(profileSetupPendingProvider.notifier).markPending();
      }
      // The draft holds a plaintext password; it goes the moment it is spent.
      ref.read(registrationDraftProvider.notifier).clear();
      // Same reason as in `login` — this device may have held another account.
      _dropSessionCaches();
    }

    state = result.when(
      success: AsyncValue.data,
      failure: (e) => AsyncValue.error(e, StackTrace.current),
    );

    if (result.isSuccess) {
      // ignore: unawaited_futures
      ref.read(fcmSetupServiceProvider).setAuthenticated(true);
    }
  }

  /// Ends a session the server has stopped accepting.
  ///
  /// This is not [logout]. Logout is a decision; this is an eviction, and the
  /// two differ in what is safe to do:
  ///
  /// * **No backend calls.** The reason we are here is that the token is dead,
  ///   so `Auth/Logout` and the FCM unregister would both answer 401 — which
  ///   the interceptor would raise as another expiry, chasing the first one in
  ///   a circle. The device's push registration is dropped locally instead and
  ///   the server's copy goes stale, which it already does on an uninstall.
  ///
  /// * **No cache invalidation**, for the same reason [logout] avoids it: the
  ///   shell is still mounted at this moment, so invalidating a watched
  ///   provider refetches it immediately — with no credentials — and every one
  ///   of those refetches 401s, which is a fresh burst of expiry signals. The
  ///   caches are dropped on the next sign-IN, where nothing is watching.
  ///
  /// Publishing `state` is the last line and the one that matters: it releases
  /// the router's redirect to `/auth`, which tears the shell down and takes
  /// the error views with it.
  Future<void> _endExpiredSession() async {
    // One sign-out per expiry. A screenful of parallel reads all fail at once
    // and every one of them signals, and this also covers the ordinary case of
    // a 401 arriving when there was no session to lose: cold start against a
    // stale token, or a stray request landing after a deliberate logout.
    if (state.valueOrNull == null) return;

    ref.read(loggerProvider).d('[auth] session expired — signing out');

    await ref.read(tokenStorageProvider).clear();
    // Onboarding belongs to the account, not the device — same reasoning as
    // `logout`, and leaving it set would drop the next person to sign in on
    // this phone into a profile step for a profile they already have.
    await ref.read(profileSetupPendingProvider.notifier).complete();
    // And the unconfirmed address it was offering, for the same reason.
    ref.read(pendingEmailProvider.notifier).dismiss();
    // ignore: unawaited_futures
    ref.read(fcmSetupServiceProvider).setAuthenticated(false);

    state = const AsyncValue.data(null);
  }

  /// Deletes the account on the server, then signs out locally.
  ///
  /// The sign-out only follows a success: on a failure the person is still
  /// signed in, looking at the same screen, and can try again.
  Future<Result<void, AppException>> deleteAccount() async {
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    if (result.isSuccess) await logout();
    return result;
  }

  Future<void> logout() async {
    // **The tokens are deleted FIRST, before anything goes to the network.**
    //
    // They used to be deleted last, in the `finally` after `POST Logout`
    // answered — so for that whole round trip the old session was still in
    // storage, and everything still mounted kept using it: the shell's
    // providers, the push unregister, and the interceptor, which now refreshes
    // a token that is about to expire. A refresh in that window rotated the
    // OLD session into a brand-new pair just as the person was signing out of
    // it. Clearing first closes the window outright: from the moment the
    // button is tapped there is nothing left to send or to refresh.
    //
    // The server still has to hear about it — revoke the refresh token,
    // release this phone's device slot, drop its push registration — so the
    // two credentials are snapshotted just before the clear and handed to
    // those calls explicitly.
    final tokens = ref.read(tokenStorageProvider);
    final access = await tokens.readAccessToken();
    final refresh = await tokens.readRefreshToken();
    await tokens.clear();

    // Both best-effort, both AWAITED. Not fire-and-forget: a `Logout` still in
    // flight when the person signs straight back in would release the device
    // slot the NEW session had just claimed — and that session's next refresh
    // would come back `device_revoked`. Awaiting keeps the old session's
    // cleanup strictly before the new one can begin.
    await Future.wait<void>([
      ref
          .read(fcmSetupServiceProvider)
          .handleLogout(bearer: access)
          .catchError((Object _) {}),
      ref
          .read(authRepositoryProvider)
          .logout(refreshToken: refresh, accessToken: access)
          .then((_) {}, onError: (Object _) {}),
    ]);
    // Onboarding belongs to the account that was registered here, not to the
    // device — leaving it set would drop the NEXT person to sign in on this
    // phone into a profile step for a profile they already have.
    await ref.read(profileSetupPendingProvider.notifier).complete();
    // Same reasoning, one screen further on: an unconfirmed address belongs to
    // the account that offered it. A plain setter, not an invalidate — see the
    // note below on what invalidating a watched provider costs here.
    ref.read(pendingEmailProvider.notifier).dismiss();
    // Whatever expiry notice may be pending belongs to a session that is now
    // being ended on purpose. Left set, the auth screen would greet someone
    // who just tapped "sign out" with "your session expired".
    ref.read(sessionExpiryProvider.notifier).acknowledge();
    // NOT dropped here — see `login`, which drops instead.
    //
    // `invalidate` on a provider that is still being WATCHED rebuilds it
    // immediately, and at this point the shell is still mounted and the tokens
    // are already gone. Dropping here fired about fifteen refetches with no
    // bearer, each answered `400 User ID not found in claims.`, in the second
    // after sign-out. Useless traffic, and it left every one of those providers
    // holding an error.
    //
    // Sign-in is the safe moment to drop: the router is still on /auth, nothing
    // is watching, so the invalidate is a plain drop and the new shell builds
    // each provider fresh against the session that was just persisted.
    state = const AsyncValue.data(null);
  }

  /// Loads the signed-in account's own profile into the container before the
  /// session is published.
  ///
  /// `state = AsyncValue.data(session)` is what releases the router's redirect
  /// off `/auth`, so whatever has not been fetched by that line is fetched
  /// while the user is already looking at the app. `GET Profiles/Me` is the
  /// answer to "who am I" that the feed composer, the stories rail, the
  /// dashboard header, the profile tab and `resolveAuthor` all read through
  /// [currentPersonProvider] — and every one of them renders a blank name and
  /// a placeholder avatar until it lands. Awaiting it here moves that gap into
  /// the sign-in spinner, which is time the user has already accepted.
  ///
  /// [storageZoneProvider] rides along because an avatar path off `Profiles/Me`
  /// is a bare key, not a URL: `imageUrlResolverProvider` needs the zone to
  /// turn it into something an `Image.network` can fetch. Without it the name
  /// would arrive on the first frame and the photo a beat later, which is the
  /// more noticeable half of the flicker. The two calls are independent, so
  /// they cost one round-trip, not two.
  ///
  /// Nothing here can fail the sign-in. The credentials are already good — the
  /// account is signed in whether or not its profile could be read — so a
  /// failure leaves [currentPersonProvider] to surface it on the screens that
  /// actually need a profile, and a timeout just means the app opens now and
  /// the profile lands in a moment: the request is NOT cancelled, and the
  /// provider settles from it normally.
  Future<void> _hydrateIdentity() async {
    try {
      await Future.wait<Object?>([
        ref.read(currentPersonProvider.future),
        ref.read(storageZoneProvider.future),
      ]).timeout(_identityTimeout);
    } catch (e) {
      // Deliberately swallowed — see above. Logged rather than silent, because
      // "my name is blank right after login" is otherwise invisible from here.
      ref.read(loggerProvider).d('[auth] identity prefetch skipped: $e');
    }
  }

  /// Throws away every provider holding data that belonged to the account
  /// that just signed out.
  ///
  /// None of these are autoDispose — they are tab-level state kept alive by
  /// the shell's IndexedStack, which is right while one person is signed in
  /// and wrong the moment a second one signs in on the same device. Without
  /// this, the next account's feed, threads, notifications and — through
  /// [currentPersonProvider], which every "me" surface reads — its own
  /// identity are all the previous account's, until the app is restarted.
  ///
  /// Called on sign-IN, not sign-out. Sign-out looks like the natural moment
  /// and is the wrong one: the shell is still mounted then, so invalidating a
  /// watched provider refetches it immediately, with the tokens already
  /// cleared. Sign-in runs while the router is still on /auth, where nothing
  /// is watching, so the same call is a plain drop.
  ///
  /// This is why the auth feature reaches across into the others: a session
  /// change is the one event that invalidates all of them at once, and there is
  /// nowhere else that knows it happened. Anything added later that caches
  /// per-account data outside an autoDispose provider belongs on this list.
  void _dropSessionCaches() {
    ref.invalidate(currentPersonProvider);
    ref.invalidate(peopleDirectoryProvider);
    ref.invalidate(profileNotifierProvider);
    // Which tab set the bottom bar shows. It caches the last answer an actual
    // profile gave, in a plain field, precisely so a momentary reload does not
    // flip the nav bar — which means that without this it would carry the
    // PREVIOUS account's answer into the new session, and an engineer signing
    // in after a company would get the company's tabs until `Profiles/Me`
    // landed. `_hydrateIdentity` makes that window short; this closes it.
    ref.invalidate(isCompanyAccountProvider);
    ref.invalidate(feedNotifierProvider);
    ref.invalidate(storiesNotifierProvider);
    ref.invalidate(reelsNotifierProvider);
    ref.invalidate(networkNotifierProvider);
    // "Request sent" on a suggested post is this session's memory of an edge it
    // raised, not something the server echoes back on the next feed read — so
    // the next account on this device would otherwise inherit it.
    ref.invalidate(suggestedActionsProvider);
    ref.invalidate(activityNotifierProvider);
    ref.invalidate(threadsNotifierProvider);
    ref.invalidate(applicationsNotifierProvider);
    ref.invalidate(jobsDirectoryProvider);
    ref.invalidate(jobFiltersProvider);

    // The engineer panel. All four cache per-account state outside an
    // autoDispose provider — the subscription one worst of all: left alone, the
    // next person to sign in on this device inherits the previous account's
    // answer to "may I open the panel", in whichever direction is wrong for
    // them. The panel's other reads (courses, documents) are autoDispose and
    // drop themselves.
    ref.invalidate(subscriptionProvider);
    ref.invalidate(dashboardNotifierProvider);
    ref.invalidate(notesProvider);
    ref.invalidate(legalRequestsProvider);
    ref.invalidate(assistantConversationsProvider);

    // The tenant and the storage zone are per-deployment rather than
    // per-person, which is exactly why they are easy to forget here — and the
    // zone carries a write password. Left alone, the next account on this
    // device would upload into the previous tenant's zone with the previous
    // tenant's key, and read its avatars back through the previous tenant's
    // pull zone. Dropping the tenant too is what makes the re-fetch resolve
    // afresh instead of reusing the resolved-once value.
    ref.invalidate(tenantProvider);
    ref.invalidate(storageZoneProvider);

    // An unconfirmed address belongs to the account that offered it. Safe
    // here even though registration parks one moments later: `VerifyScreen`
    // offers it AFTER `completeRegistration` has returned, and this runs
    // inside that call. A setter rather than an invalidate — see the note
    // above on what invalidating a watched provider costs at this moment.
    ref.read(pendingEmailProvider.notifier).dismiss();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);
