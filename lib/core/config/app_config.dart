import 'app_type.dart';
import 'environment.dart';

/// Immutable runtime configuration for the app.
///
/// Resolved once in each flavor entrypoint before `runApp`, then exposed
/// through `appConfigProvider`. Never read flavor info from env vars at
/// call sites — read from this object.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    this.appType = AppType.primary,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 20),
    this.useMockData = false,
    this.defaultTenantId = 1,
    this.cdnBaseUrl,
    bool? enableLogging,
  }) : _enableLogging = enableLogging;

  final Environment environment;
  final String apiBaseUrl;
  final String appName;
  final AppType appType;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// When true, repository providers may be overridden in `bootstrap`
  /// with in-memory mocks. Demo / design-preview builds set this to
  /// `true`; prod always leaves it `false`.
  final bool useMockData;

  /// Where stored image paths are READ from when the server-served storage
  /// zone isn't available — while its fetch is in flight, and on a deployment
  /// that has no zone row yet.
  ///
  /// **This is a public pull-zone URL, not a credential.** Uploading needs the
  /// zone's write password and that is deliberately server-side only; but every
  /// photo already on a profile is persisted host-less, so without a base to
  /// put in front of it, an upgraded app shows monograms for every existing
  /// avatar until the tenant's zone row exists. The zone still wins whenever it
  /// has answered — this only fills the gap.
  final String? cdnBaseUrl;

  /// Tenant used for anonymous writes when `GET /health` cannot supply one.
  ///
  /// The host is the authority — `TenantStore` asks it first. This only covers
  /// the host being unreachable or running a build whose `/health` predates
  /// the field; matching the deployment's real default keeps sign-up working
  /// in both cases.
  final int defaultTenantId;

  final bool? _enableLogging;

  /// True in dev/staging, false in prod — unless overridden at
  /// construction. Used to gate `LogInterceptor` and other verbose
  /// diagnostics.
  bool get enableLogging => _enableLogging ?? !environment.isProd;
}
