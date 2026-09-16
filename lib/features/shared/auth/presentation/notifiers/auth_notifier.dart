import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/services/storage_zone.dart';
import 'package:flutter_mobile_template/core/services/tenant_store.dart';
import 'package:flutter_mobile_template/features/activity/presentation/notifiers/activity_notifier.dart';
import 'package:flutter_mobile_template/features/dashboard/presentation/notifiers/dashboard_notifier.dart';
import 'package:flutter_mobile_template/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/notifiers/jobs_notifier.dart';
import 'package:flutter_mobile_template/features/messaging/presentation/notifiers/messaging_notifier.dart';
import 'package:flutter_mobile_template/features/network/presentation/notifiers/network_notifier.dart';
import 'package:flutter_mobile_template/features/panel/presentation/notifiers/panel_notifiers.dart';
import 'package:flutter_mobile_template/features/posts/presentation/notifiers/feed_notifier.dart';
import 'package:flutter_mobile_template/features/reels/presentation/notifiers/reels_notifier.dart';
import 'package:flutter_mobile_template/features/shared/notifications/data/fcm_setup_service.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/stories/presentation/notifiers/stories_notifier.dart';
import 'package:flutter_mobile_template/features/subscription/presentation/notifiers/subscription_notifier.dart';

import 'package:flutter_mobile_template/features/profile/data/profile_setup_store.dart';
import 'package:flutter_mobile_template/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_mobile_template/features/profile/domain/entities/profile.dart';
import 'package:flutter_mobile_template/features/profile/presentation/notifiers/profile_notifier.dart';

import '../../data/dtos/mobile_auth_result_dto.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
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

  @override
  Future<AuthSession?> build() async {
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
        // Transient failure. Keep the user signed in only if the token we hold
        // has a chance of being accepted — otherwise this hands them a feed
        // that cannot load and no way back to the login screen.
        if (!stillValid) return null;

        final refresh = await tokens.readRefreshToken();
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
    state = result.when(
      success: AsyncValue.data,
      failure: (e) => AsyncValue.error(e, StackTrace.current),
    );
    if (result.isSuccess) {
      // ignore: unawaited_futures
      ref.read(fcmSetupServiceProvider).setAuthenticated(true);
    }
  }

  /// Creates an account and signs into it. See [AuthRepository.register] —
  /// this is three backend calls, and the account type is applied afterwards.
  Future<void> register({
    required String fullName,
    required String userName,
    required String phone,
    required String password,
    required AccountType accountType,
    required Gender? gender,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref
        .read(authRepositoryProvider)
        .register(
          fullName: fullName,
          userName: userName,
          phone: phone,
          password: password,
          accountType: accountType,
          gender: gender,
          imageUrl: imageUrl,
        );
    if (result.isSuccess) {
      // Set BEFORE the session lands, so the router's first evaluation as an
      // authed user already sends this person to the profile step rather than
      // flashing the feed on the way there.
      await ref.read(profileSetupPendingProvider.notifier).markPending();
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

  Future<void> logout() async {
    // Drop the FCM registration on the backend BEFORE clearing local
    // tokens — the unregister call needs the JWT to identify the
    // user. Best-effort: a transport failure here still proceeds with
    // local logout so the user isn't stuck on a corrupt session.
    // ignore: unawaited_futures
    ref.read(fcmSetupServiceProvider).handleLogout();
    await ref.read(authRepositoryProvider).logout();
    // Onboarding belongs to the account that was registered here, not to the
    // device — leaving it set would drop the NEXT person to sign in on this
    // phone into a profile step for a profile they already have.
    await ref.read(profileSetupPendingProvider.notifier).complete();
    _dropSessionCaches();
    state = const AsyncValue.data(null);
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
  /// This is why the auth feature reaches across into the others: sign-out is
  /// the one event that invalidates all of them at once, and there is nowhere
  /// else that knows it happened. Anything added later that caches per-account
  /// data outside an autoDispose provider belongs on this list.
  void _dropSessionCaches() {
    ref.invalidate(currentPersonProvider);
    ref.invalidate(peopleDirectoryProvider);
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(feedNotifierProvider);
    ref.invalidate(storiesNotifierProvider);
    ref.invalidate(reelsNotifierProvider);
    ref.invalidate(networkNotifierProvider);
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
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);
