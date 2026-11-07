import 'package:intl/intl.dart';

/// Number rendering for the UI — Western ("English") digits throughout:
/// `4,208`, `62%`, `12 ألف`.
///
/// The app used to print Arabic-Indic digits (٤٬٢٠٨, ٦٢٪). It now uses Western
/// digits everywhere, and every count in the UI still goes through these
/// helpers rather than `toString()`, so the choice stays a one-file change.
///
/// `intl`'s `ar` locale already formats with Western digits, so only the
/// separators and words come from the locale.
class ArabicNumbers {
  ArabicNumbers._();

  static final NumberFormat _decimal = NumberFormat.decimalPattern('ar');
  static final NumberFormat _compact = NumberFormat.compact(locale: 'ar');

  /// `4208` → `4,208`.
  static String count(num value) => _westernize(_decimal.format(value));

  /// `12400` → `12 ألف`. Used for like counts and view counts.
  static String compact(num value) => value.abs() < 1000
      ? count(value)
      : _westernize(_compact.format(value));

  /// `0.62` → `62%`.
  static String percent(double fraction) =>
      '${plain((fraction * 100).round())}%';

  /// `4` → `4`. Plain digits with no grouping — badges, steppers, dates.
  static String plain(int value) => value.toString();

  /// Whatever the locale data does, the output is Western digits and ASCII
  /// separators — some `ar` regional data still carries Arabic-Indic digits
  /// and the Arabic thousands separator, and this keeps one row from mixing
  /// the two.
  static String _westernize(String input) => toWesternDigits(input);
}

/// `٤٬٢٠٨ ٪` → `4,208 %`. Arabic-Indic (U+0660–0669) and Extended
/// Arabic-Indic (U+06F0–06F9, Persian/Urdu keyboards) digits become ASCII, as
/// do the Arabic thousands (٬), decimal (٫) and percent (٪) signs.
String toWesternDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + rune - 0x06F0);
    } else if (rune == 0x066C) {
      buffer.write(',');
    } else if (rune == 0x066B) {
      buffer.write('.');
    } else if (rune == 0x066A) {
      buffer.write('%');
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
