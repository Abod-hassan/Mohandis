/// How a refresh attempt ended.
///
/// Three outcomes, not two, because "it did not work" has two meanings that
/// call for opposite responses:
///
/// * [rejected] — the server answered and said no: the refresh token is
///   unknown, expired, revoked, or the device was removed. The session is
///   over, and the right thing is to sign out.
/// * [unavailable] — the server never gave an answer: no connection, a
///   timeout, a TLS failure, a 5xx. The session may be perfectly valid. Signing
///   out here is how a person on a train loses their login going through a
///   tunnel, so the session is KEPT and the request simply fails like any other
///   network error.
enum RefreshOutcome {
  refreshed,
  rejected,
  unavailable,
}

/// Indirection used by [AuthInterceptor] to request a token refresh.
///
/// The default binding is a no-op. The auth feature overrides
/// `tokenRefresherProvider` with an implementation that calls the refresh
/// endpoint and persists the new tokens. This keeps the core/api layer free
/// of any auth-feature imports.
abstract class TokenRefresher {
  Future<RefreshOutcome> refresh();

  /// Why the most recent [refresh] answered [RefreshOutcome.rejected], in the
  /// server's own words — the status and body, or "nothing stored".
  ///
  /// The session-expiry signal carries it to the login screen. Without it an
  /// ended session was one generic sentence whichever of half a dozen refusals
  /// produced it, and those refusals are different problems: a token the
  /// server cannot find, one past its expiry, a device removed from the
  /// account, or a phone that never stored a refresh token at all.
  String? get lastRefusal;
}

class NoopTokenRefresher implements TokenRefresher {
  const NoopTokenRefresher();

  /// Nothing can refresh, so a 401 means what it says.
  @override
  Future<RefreshOutcome> refresh() async => RefreshOutcome.rejected;

  @override
  String? get lastRefusal => 'no token refresher is configured';
}
