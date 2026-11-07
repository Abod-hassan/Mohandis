import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../../domain/entities/user.dart';

/// Everything the sign-up form collected, held between the form and the
/// verification screen.
///
/// Registration is two round-trips with a screen in between: the form cannot
/// create anything until an identity has been proved, and the verify screen
/// cannot prove anything without knowing which identifiers were offered. A
/// provider rather than a route argument because `go_router`'s `extra` does
/// not survive a deep link or a restore, and landing on the verify screen with
/// a null draft is a dead end with no way back to the data.
class RegistrationDraft {
  const RegistrationDraft({
    required this.fullName,
    required this.userName,
    this.phone,
    required this.password,
    required this.accountType,
    this.email,
    this.gender,
    this.imageUrl,
  });

  final String fullName;
  final String userName;

  /// E.164, or null for an e-mail-only sign-up. When present it is the channel
  /// the code goes to, and [email] is offered afterwards as a second factor.
  final String? phone;

  final String password;
  final AccountType accountType;

  /// Optional second channel, and never an alternative to the phone: sign-up
  /// proves the number, and this address is offered afterwards as the second
  /// factor. See `VerifyScreen` for why both cannot be proved at once.
  final String? email;

  final Gender? gender;

  /// Host-less storage path from `MediaUploadService`, already uploaded by the
  /// time a draft exists — the photo is the one part of the form that cannot
  /// be replayed, since the picked file may be gone by the verify screen.
  final String? imageUrl;

  bool get hasEmail => (email ?? '').isNotEmpty;

  bool get hasPhone => (phone ?? '').isNotEmpty;

  /// Where the confirmation code goes: the phone when there is one.
  bool get verifiesByEmail => !hasPhone && hasEmail;
}

/// The draft in flight, or null when no registration is underway.
///
/// Cleared on success and on an explicit abandon — never left behind, because
/// it holds a plaintext password for as long as it exists.
class RegistrationDraftNotifier extends Notifier<RegistrationDraft?> {
  @override
  RegistrationDraft? build() => null;

  void start(RegistrationDraft draft) => state = draft;

  void clear() => state = null;
}

final registrationDraftProvider =
    NotifierProvider<RegistrationDraftNotifier, RegistrationDraft?>(
      RegistrationDraftNotifier.new,
    );
