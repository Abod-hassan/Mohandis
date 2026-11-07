import 'package:flutter_test/flutter_test.dart';

import 'package:mohandis/features/profile/domain/entities/profile.dart';
import 'package:mohandis/features/shared/auth/presentation/notifiers/registration_draft.dart';

RegistrationDraft _draft({String? phone, String? email}) => RegistrationDraft(
      fullName: 'Test User',
      userName: 'testuser',
      phone: phone,
      email: email,
      password: 'Passw0rd',
      accountType: AccountType.individual,
    );

void main() {
  group('RegistrationDraft channel', () {
    test('the phone carries the code when both are given', () {
      final d = _draft(phone: '+9647701234567', email: 'a@b.com');
      expect(d.hasPhone, isTrue);
      expect(d.verifiesByEmail, isFalse);
    });

    test('an e-mail-only sign-up verifies by e-mail', () {
      final d = _draft(email: 'a@b.com');
      expect(d.hasPhone, isFalse);
      expect(d.verifiesByEmail, isTrue);
    });

    test('an empty phone string counts as no phone', () {
      expect(_draft(phone: '', email: 'a@b.com').verifiesByEmail, isTrue);
    });

    test('gender is optional', () {
      expect(_draft(phone: '+9647701234567').gender, isNull);
    });
  });
}
