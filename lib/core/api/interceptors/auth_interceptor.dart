import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';
import '../../utils/jwt_claims.dart';
import '../token_refresher.dart';

/// Attaches `Authorization: Bearer <access>` to outgoing requests and, on a
/// 401, refreshes the session once and replays the request.
///
/// What a failed refresh does depends on WHY it failed — see [RefreshOutcome].
/// A server that said no ends the session; a server that could not be reached
/// leaves it alone.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Future<RefreshOutcome> Function() refreshAccessToken,
    required Future<Response<dynamic>> Function(RequestOptions) retry,
    this.onSessionExpired,
    this.unauthenticatedPaths = const {'/auth/login', '/auth/refresh'},
  }) : _tokens = tokenStorage,
       _refresh = refreshAccessToken,
       _retry = retry;

  final TokenStorage _tokens;
  final Future<RefreshOutcome> Function() _refresh;

  /// Sends a request a second time. Supplied by `ApiClient` — see
  /// `ApiClient._retryClient` for why it is not the main Dio.
  final Future<Response<dynamic>> Function(RequestOptions) _retry;

  /// Marks a request that has already been replayed once after a refresh. A
  /// second 401 on it is not an invitation to refresh again: the token is
  /// brand new, so whatever the server objects to, another rotation will not
  /// fix it — and refreshing in a loop is how a bug becomes a lockout.
  static const _retriedKey = 'auth.retried';

  /// Marks a request whose Authorization header the CALLER set — today, only
  /// `CreateWithContact`, carrying a registration token. Its 401 means that
  /// token was refused, and nothing this interceptor owns can fix it: the
  /// stored session belongs to someone else (or to nobody), so "refreshing"
  /// would at best do nothing and at worst replay the request as a different
  /// account, and a failed refresh would then announce an expiry for a
  /// session this request never used.
  static const _explicitKey = 'auth.explicit';

  /// Fired once the server has rejected this device's session and refreshing
  /// it did not work.
  ///
  /// Clearing the tokens is not enough on its own, and that was the bug:
  /// `AuthNotifier` went on holding a session object nobody could use, so the
  /// router kept the person inside the signed-in shell while every screen
  /// under it rendered an error view. This is how the network layer says
  /// "sign them out" without importing the auth feature — see
  /// `SessionExpiryNotifier`, which is what gets wired in here.
  final void Function()? onSessionExpired;

  final Set<String> unauthenticatedPaths;

  Future<RefreshOutcome>? _inflight;

  bool _isPublic(RequestOptions options) =>
      unauthenticatedPaths.contains(options.path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // An Authorization header the caller set by hand wins. Registration's
    // second step carries a short-lived registration token that is
    // deliberately NOT in storage — it is not a session — and overwriting it
    // with whatever happens to be stored (nothing, or a previous account's
    // leftover) is how `CreateWithContact` ends up unauthenticated.
    final alreadySet = options.headers['Authorization'];
    final hasExplicit = alreadySet is String && alreadySet.isNotEmpty;
    // Remembered for onError. A hand-set bearer is not this device's session,
    // so a 401 on it is not ours to refresh or to replay — see onError.
    if (hasExplicit) options.extra[_explicitKey] = true;

    if (!_isPublic(options) && !hasExplicit) {
      // Wrapped whole: this is a QueuedInterceptor, so an `onRequest` that
      // throws never calls its handler and every later request waits behind
      // it for good. Storage can throw (a locked keychain) and so can the
      // refresh, and either must end in `handler.next`, exactly once.
      try {
        final token = await _bearerFor();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Sent without a bearer: the server treats it as a guest and the
        // session is untouched. Better than hanging every request.
      }
    }
    handler.next(options);
  }

  /// The access token to send — refreshed FIRST if it has already expired.
  ///
  /// **Why not just wait for a 401.** That is what this interceptor did, and
  /// against this backend it never worked: the social module has no
  /// `[Authorize]`, so a token JwtBearer rejects is not refused, it is quietly
  /// demoted to an anonymous visitor. Reads answer 200 with a guest's view,
  /// writes answer `400 User ID not found in claims.`, and the 401 that would
  /// have triggered a refresh never comes. The session just rotted.
  ///
  /// The token says when it dies — `exp` is right there in the payload — so
  /// the app does not need the server's permission to notice. The 401 path in
  /// [onError] stays, for what this cannot see: a token revoked early, or a
  /// device clock that runs slow.
  Future<String?> _bearerFor() async {
    final token = await _tokens.readAccessToken();
    if (token == null || token.isEmpty) return null;
    if (!_expired(token)) return token;

    // A token this refresh just produced is never refreshed again on sight.
    // If the phone's clock runs far ahead, a brand-new token can look expired
    // already, and without this every request would rotate the session.
    if (token == _issuedByLastRefresh) return token;

    final outcome = await (_inflight ??= _runRefresh());
    switch (outcome) {
      case RefreshOutcome.refreshed:
        final fresh = await _tokens.readAccessToken();
        _issuedByLastRefresh = fresh;
        return fresh;

      case RefreshOutcome.rejected:
        // Same verdict as the 401 path below, reached sooner: the server will
        // not extend this session, so it ends here, with its reason.
        try {
          await _tokens.clear();
        } finally {
          onSessionExpired?.call();
        }
        return null;

      case RefreshOutcome.unavailable:
        // Never reached the server. Send what we have and let it decide —
        // signing out over a tunnel is the one thing this must not do.
        return token;
    }
  }

  /// The access token this interceptor got from its most recent refresh.
  String? _issuedByLastRefresh;

  /// Expired, or within [_refreshEarly] of it, by the token's own `exp`.
  ///
  /// A token with no readable `exp` is not "expired" — this only acts on what
  /// it can see, and leaves the rest to the server's 401.
  static bool _expired(String token) {
    final exp = jwtClaims(token)?['exp'];
    if (exp is! num) return false;
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiresAt.subtract(_refreshEarly));
  }

  /// Refreshed slightly before `exp`, so a request does not leave with a token
  /// that dies while it is in flight.
  static const _refreshEarly = Duration(seconds: 30);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;
    if (status != 401 || _isPublic(options)) return handler.next(err);

    // Already replayed once with a fresh token. See [_retriedKey].
    if (options.extra[_retriedKey] == true) return handler.next(err);
    // Not our bearer. See [_explicitKey].
    if (options.extra[_explicitKey] == true) return handler.next(err);

    // Everything below touches secure storage and the network, and any of it
    // can throw — the iOS keychain refuses reads while the device is locked,
    // which is exactly when a background refresh tends to fire. This is a
    // QueuedInterceptor: an `onError` that throws never calls its handler,
    // and every later error on the main Dio waits behind it for good. The
    // app's networking would hang until it was killed. So a throw anywhere
    // below ends in `handler.next(err)`, and exactly once.
    try {
      await _handle401(err, handler);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<void> _handle401(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    // A request that left WITHOUT a bearer has no session to refresh. Its 401
    // is a screen asking for something it was never entitled to, or a probe
    // racing a sign-out that already happened.
    final sent = _bearerOf(options);
    if (sent == null) return handler.next(err);

    // Someone else already refreshed. This matters more than it looks: the
    // backend ROTATES refresh tokens, and this interceptor is queued, so a
    // burst of requests that all went out on the old token come back as a
    // burst of 401s processed one after another — after the first has already
    // finished refreshing and cleared `_inflight`. Without this check, each
    // of them would rotate the pair again, one full round trip apiece.
    final stored = await _tokens.readAccessToken();
    if (stored != null && stored.isNotEmpty && stored != sent) {
      return _replay(options, stored, handler, err);
    }

    final outcome = await (_inflight ??= _runRefresh());

    switch (outcome) {
      case RefreshOutcome.refreshed:
        final fresh = await _tokens.readAccessToken();
        if (fresh == null || fresh.isEmpty) return handler.next(err);
        return _replay(options, fresh, handler, err);

      case RefreshOutcome.rejected:
        // The server has refused the session outright. Clearing the tokens
        // alone is not enough — see [onSessionExpired].
        //
        // The signal goes out even if clearing storage throws: a keychain
        // hiccup must not leave the person inside a shell whose every request
        // is going to fail.
        try {
          await _tokens.clear();
        } finally {
          onSessionExpired?.call();
        }
        return handler.next(err);

      case RefreshOutcome.unavailable:
        // The refresh never got an answer. The session is kept: this request
        // fails as the network error it really is, and the next one tries
        // again. Signing out here would log someone out for going through a
        // tunnel.
        return handler.next(err);
    }
  }

  Future<void> _replay(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _retry(options));
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(original);
    }
  }

  /// The bearer this request actually left with, or null.
  ///
  /// Read off the attempt itself rather than off storage, because by the time
  /// a 401 comes back the tokens may already have been replaced — or cleared
  /// by the request in front of it.
  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    final token = header.substring('Bearer '.length).trim();
    return token.isEmpty ? null : token;
  }

  Future<RefreshOutcome> _runRefresh() async {
    try {
      return await _refresh();
    } finally {
      _inflight = null;
    }
  }
}
