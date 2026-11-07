import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

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
        '5 س',
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
    // The app shows Western ("English") digits everywhere.
    test('renders counts with Western digits', () {
      expect(ArabicNumbers.plain(42), '42');
      expect(ArabicNumbers.count(4208), '4,208');
      expect(ArabicNumbers.count(4208), isNot(contains(RegExp(r'[٠-٩]'))));
    });

    test('compact keeps small numbers exact and abbreviates large ones', () {
      expect(ArabicNumbers.compact(342), '342');
      expect(ArabicNumbers.compact(12400), contains('12'));
      expect(ArabicNumbers.compact(12400), isNot(contains(RegExp(r'[٠-٩]'))));
    });

    test('percent rounds and appends a percent sign', () {
      expect(ArabicNumbers.percent(0.62), '62%');
    });
  });

  group('toWesternDigits', () {
    test('converts Arabic-Indic and Persian digits and separators', () {
      expect(toWesternDigits('٤٬٢٠٨'), '4,208');
      expect(toWesternDigits('۱۲۳'), '123');
      expect(toWesternDigits('٦٢٪'), '62%');
      expect(toWesternDigits('٣٫٥'), '3.5');
    });

    test('leaves letters and Western digits alone', () {
      expect(toWesternDigits('منذ 5 س'), 'منذ 5 س');
      expect(toWesternDigits('abc 123'), 'abc 123');
    });
  });

  group('date formatters', () {
    test('month and day use Western digits, zero-padded', () {
      expect(formatMonthYearArabic(DateTime(2022, 3)), '03/2022');
      expect(formatDayArabic(DateTime(2015, 3, 1)), '01/03/2015');
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
