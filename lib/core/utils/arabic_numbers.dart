import 'package:intl/intl.dart';

/// Arabic-Indic digit rendering, matching the design's numerals (٦٢٪, ٤٬٢٠٨).
///
/// `intl`'s `ar` locale formats with Western digits, so the digit and
/// separator substitution is done here rather than relying on the locale's
/// numbering system. Counts in the UI go through these helpers rather than
/// `toString()` so a switch back to Western digits is a one-file change.
class ArabicNumbers {
  ArabicNumbers._();

  static final NumberFormat _decimal = NumberFormat.decimalPattern('ar');
  static final NumberFormat _compact = NumberFormat.compact(locale: 'ar');

  static const String _arabicThousandsSeparator = '٬';
  static const int _arabicZero = 0x0660;
  static const int _asciiZero = 0x30;

  /// `4208` → `٤٬٢٠٨`.
  static String count(num value) => _localizeDigits(_decimal.format(value));

  /// `12400` → `١٢ ألف`. Used for like counts and view counts.
  static String compact(num value) => value.abs() < 1000
      ? count(value)
      : _localizeDigits(_compact.format(value));

  /// `0.62` → `٦٢٪`.
  static String percent(double fraction) =>
      '${plain((fraction * 100).round())}٪';

  /// `4` → `٤`. Plain digits with no grouping — badges, steppers, dates.
  static String plain(int value) => _localizeDigits(value.toString());

  static String _localizeDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= _asciiZero && rune <= _asciiZero + 9) {
        buffer.writeCharCode(_arabicZero + (rune - _asciiZero));
      } else if (rune == 0x2C) {
        // ASCII comma → the Arabic thousands separator.
        buffer.write(_arabicThousandsSeparator);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
