import 'auth_session.dart';

/// What `GET /api/Auth/Exists` says about the identifiers a sign-up form is
/// collecting.
///
/// One call answers all three, and each flag is only meaningful for a field
/// that was actually asked about — omit a parameter and its flag comes back
/// false, which reads as "free" rather than "unknown". Callers must not
/// interpret a flag for something they did not send.
class IdentityAvailability {
  const IdentityAvailability({
    this.userNameTaken = false,
    this.phoneTaken = false,
    this.emailTaken = false,
  });

  factory IdentityAvailability.fromJson(Map<String, dynamic> json) {
    return IdentityAvailability(
      userNameTaken: json['userNameTaken'] == true,
      phoneTaken: json['phoneTaken'] == true,
      emailTaken: json['emailTaken'] == true,
    );
  }

  final bool userNameTaken;
  final bool phoneTaken;

  /// Only a CONFIRMED address counts as taken server-side — an unconfirmed one
  /// cannot sign in, so it must not block a new account.
  final bool emailTaken;
}

/// The result of proving a phone or an e-mail address.
///
/// The backend answers both cases with the same `LoginResultDto` shape, which
/// is the trap this type exists to close: a registration token looks exactly
/// like a session apart from one boolean, and storing one as the other leaves
/// the app holding a bearer that every endpoint but `CreateWithContact`
/// rejects.
sealed class VerificationOutcome {
  const VerificationOutcome();
}

/// The channel already belonged to an account — the person is now signed in,
/// and there is nothing left to register.
///
/// Reachable from the sign-up flow, not only from sign-in: somebody who
/// forgot they had an account types the number, proves it, and the right
/// answer is to let them in rather than to refuse a duplicate.
class VerifiedSession extends VerificationOutcome {
  const VerifiedSession(this.session);

  final AuthSession session;
}

/// Which channel someone is proving.
///
/// Not used by registration any more — that is phone-only. This is password
/// recovery, where either channel is a legitimate way back into an account
/// that already exists.
enum VerifyChannel {
  phone,
  email;

  bool get isPhone => this == VerifyChannel.phone;
}

/// The channel is proved but has no account behind it yet.
class RegistrationToken extends VerificationOutcome {
  const RegistrationToken({required this.token, this.email});

  /// Authorises exactly one call — `CreateWithContact` — and expires in 30
  /// minutes. It carries no ContactId, so every contact-scoped endpoint
  /// refuses it until it has been traded for a real session.
  final String token;

  /// The address this token proved, when the channel was e-mail. The server
  /// confirms it on the account automatically; nothing needs to re-send it.
  final String? email;
}

