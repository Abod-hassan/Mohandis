/// Identifies the app variant when a single codebase ships multiple apps.
///
/// Sent on every request as the `X-App-Type` header via
/// `DeviceHeaderInterceptor`. This is a template — edit the enum values
/// and header strings to match your product, or delete this file
/// entirely if the codebase only ever ships a single app.
///
/// Wire additional variants in `lib/flavors/<app>/main.dart`.
enum AppType {
  primary,
  secondary;

  String get header => switch (this) {
        AppType.primary => 'primary',
        AppType.secondary => 'secondary',
      };

  bool get isPrimary => this == AppType.primary;
}
