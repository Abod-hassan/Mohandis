/// Indirection used by [AuthInterceptor] to request a token refresh.
///
/// The default binding is a no-op. The auth feature overrides
/// `tokenRefresherProvider` with an implementation that calls the refresh
/// endpoint and persists the new tokens. This keeps the core/api layer free
/// of any auth-feature imports.
abstract class TokenRefresher {
  Future<bool> refresh();
}

class NoopTokenRefresher implements TokenRefresher {
  const NoopTokenRefresher();

  @override
  Future<bool> refresh() async => false;
}
