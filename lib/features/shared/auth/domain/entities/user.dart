/// A person's gender on the Auth contact.
///
/// The server's `GenderEnum` also has an `Unspecified` member; the app does not
/// offer it — sign-up asks for a choice and sends one of these two.
///
/// The names, not the ordinals, are what go on the wire. That matters: the
/// Kernel enum leads with `Unspecified`, which is where `Male` used to sit
/// before the enum moved out of the Auth module, so anything sending the
/// number would now be recording the wrong thing.
enum Gender {
  male,
  female;

  /// The C# member name. Newtonsoft's `StringEnumConverter` is registered on
  /// the host, so this is what binds.
  String get wireName => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
  };
}

/// Pure domain entity — no annotations, no JSON, no Flutter.
///
/// Mirrors the user fields returned by the backend's `MobileAuthResultDto`:
/// the backend identifies a user by Guid, the user's primary identifier is
/// their phone number (kept as `userName`), and a free-form `displayName`
/// shown in the UI.
class User {
  const User({
    required this.id,
    required this.name,
    this.userName,
    this.email,
    this.roles = const [],
  });

  /// Backend user id (Guid).
  final String id;

  /// Display name — what we show in the UI.
  final String name;

  /// Backend `userName` — for our market this is the phone number.
  final String? userName;

  /// May be null on phone-first signups.
  final String? email;

  /// Identity role names attached to the user (e.g. `Customer`, `Salesperson`).
  final List<String> roles;
}
