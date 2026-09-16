import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('relativeTimeArabic', () {
    final now = DateTime(2026, 8, 12, 12);

    test('uses the singular form for one unit', () {
      expect(
        relativeTimeArabic(now.subtract(const Duration(hours: 1)), now: now),
        'ساعة',
      );
      expect(
        relativeTimeArabic(now.subtract(const Duration(days: 1)), now: now),
        'يوم',
      );
    });

    test('uses the Arabic dual form for two units', () {
      expect(
        relativeTimeArabic(now.subtract(const Duration(hours: 2)), now: now),
        'ساعتان',
      );
      expect(
        relativeTimeArabic(now.subtract(const Duration(days: 2)), now: now),
        'يومان',
      );
    });

    test('falls back to the compact form from three units up', () {
      expect(
        relativeTimeArabic(now.subtract(const Duration(hours: 5)), now: now),
        '٥ س',
      );
    });

    test('collapses anything under a minute to "الآن"', () {
      expect(
        relativeTimeArabic(now.subtract(const Duration(seconds: 20)), now: now),
        'الآن',
      );
    });
  });

  group('ArabicNumbers', () {
    test('renders counts with Arabic-Indic digits', () {
      expect(ArabicNumbers.plain(42), '٤٢');
      expect(ArabicNumbers.count(4208), '٤٬٢٠٨');
      expect(ArabicNumbers.count(4208), isNot(contains(',')));
    });

    test('compact keeps small numbers exact and abbreviates large ones', () {
      expect(ArabicNumbers.compact(342), '٣٤٢');
      expect(ArabicNumbers.compact(12400), isNot(contains(RegExp(r'[0-9]'))));
    });

    test('percent rounds and appends the Arabic percent sign', () {
      expect(ArabicNumbers.percent(0.62), '٦٢٪');
    });
  });

  group('Person.initials', () {
    test('takes one letter from each of the first and last names', () {
      const person = Person(
        id: 'p',
        name: 'يوسف الحربي',
        firstName: 'يوسف',
        headline: '',
        location: '',
      );
      expect(person.initials, 'يا');
    });

    test('handles a single-word name without throwing', () {
      const person = Person(
        id: 'p',
        name: 'ريم',
        firstName: 'ريم',
        headline: '',
        location: '',
      );
      expect(person.initials, 'ري');
    });
  });
}
