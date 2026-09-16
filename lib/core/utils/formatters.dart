import 'package:intl/intl.dart';

/// Money formatter. Defaults to USD with no decimals — override
/// [currencyCode] / [decimals] per locale as needed.
///
/// Example: `formatCurrency(1250)` → `"USD 1,250"`.
/// Example: `formatCurrency(1250, currencyCode: 'د.ع', decimals: 0)` →
/// `"د.ع 1,250"`.
String formatCurrency(
  num amount, {
  String currencyCode = 'USD',
  int decimals = 0,
}) {
  final fmt = NumberFormat.currency(
    symbol: '$currencyCode ',
    decimalDigits: decimals,
  );
  return fmt.format(amount).trim();
}

/// Compact money like "8.9M" / "240K" — used in KPI tiles.
String formatCompactMoney(num amount) {
  if (amount.abs() >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount.abs() >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }
  return amount.toStringAsFixed(0);
}

String formatDate(DateTime date) =>
    DateFormat.yMMMd().format(date.toLocal());

String formatDateTime(DateTime date) =>
    DateFormat.yMMMd().add_jm().format(date.toLocal());

/// Hour-only time, e.g. "09:30".
String formatTime(DateTime date) => DateFormat.Hm().format(date.toLocal());

/// Clock time in Arabic with an ص/م marker — used for message timestamps.
String formatTimeArabic(DateTime date) =>
    DateFormat('h:mm a', 'ar').format(date.toLocal());

/// Relative age in Arabic, honouring the dual form Arabic needs
/// ("ساعتان", "يومان") that a plain "{n} hours" template gets wrong.
///
/// Returns the bare quantity — callers wrap it in "قبل {time}" via the
/// localized `jobPostedAgo` / `storyPostedAgo` strings.
String relativeTimeArabic(DateTime moment, {DateTime? now}) {
  final delta = (now ?? DateTime.now()).difference(moment);

  if (delta.inMinutes < 1) return 'الآن';
  if (delta.inMinutes < 60) return _quantity(delta.inMinutes, 'د', 'دقيقة', 'دقيقتان');
  if (delta.inHours < 24) return _quantity(delta.inHours, 'س', 'ساعة', 'ساعتان');
  if (delta.inDays < 7) return _quantity(delta.inDays, 'ي', 'يوم', 'يومان');
  if (delta.inDays < 30) {
    return _quantity(delta.inDays ~/ 7, 'أ', 'أسبوع', 'أسبوعان');
  }
  if (delta.inDays < 365) {
    return _quantity(delta.inDays ~/ 30, 'ش', 'شهر', 'شهران');
  }
  return _quantity(delta.inDays ~/ 365, 'سنة', 'سنة', 'سنتان');
}

/// Arabic counts inflect three ways: one, two (dual), and many. `abbrev` is
/// used from 3 upward where the design shows compact forms like "٥ س".
String _quantity(int value, String abbrev, String singular, String dual) {
  if (value == 1) return singular;
  if (value == 2) return dual;
  return '${_arabicDigits(value)} $abbrev';
}

String _arabicDigits(int value) => value
    .toString()
    .split('')
    .map((d) => String.fromCharCode(d.codeUnitAt(0) + 0x0660 - 0x30))
    .join();

/// A single month, as the CV editors' date pickers show it — "٠٣/٢٠٢٢".
///
/// Numeric on purpose: month NAMES differ between Levantine and Gulf Arabic
/// (آذار vs مارس) and picking one would be wrong for half the audience, while
/// a zero-padded number reads the same everywhere.
String formatMonthYearArabic(DateTime value) {
  final month = _arabicDigits(value.month).padLeft(2, '٠');
  return '$month/${_arabicDigits(value.year)}';
}

/// A full day — "٠١/٠٣/٢٠١٥".
///
/// Numeric for the same reason [formatMonthYearArabic] is: month names differ
/// between Levantine and Gulf Arabic, and a zero-padded number reads the same
/// to everyone. Day-first, which is how a date is written across the region.
String formatDayArabic(DateTime value) {
  final day = _arabicDigits(value.day).padLeft(2, '٠');
  final month = _arabicDigits(value.month).padLeft(2, '٠');
  return '$day/$month/${_arabicDigits(value.year)}';
}

/// Arabic date range for a CV row — "٠٦/٢٠٢٤ — الآن · سنتان و٣ أشهر".
///
/// The backend stores experience and education as raw `startDate` / `endDate` /
/// `isCurrent`, so both the range and the duration phrasing are the client's
/// job. Month precision on both halves: a CV reads as a sequence, and two roles
/// in the same year are indistinguishable without it.
String formatDateRangeArabic(DateTime? start, DateTime? end, bool isCurrent) {
  if (start == null) return isCurrent ? 'الآن' : '';

  final from = formatMonthYearArabic(start);
  final to = isCurrent || end == null ? 'الآن' : formatMonthYearArabic(end);
  final until = isCurrent || end == null ? DateTime.now() : end;

  final duration = _arabicDuration(start, until);
  return duration.isEmpty ? '$from — $to' : '$from — $to · $duration';
}

/// "سنتان و٣ أشهر" — years and months together, each dropped when zero.
///
/// Whole months, counted from the day: a role started on the 28th has not run
/// a month on the 3rd of the next one, and rounding it up would inflate every
/// CV on the platform by up to a month.
String _arabicDuration(DateTime start, DateTime until) {
  var months = (until.year - start.year) * 12 + (until.month - start.month);
  if (until.day < start.day) months -= 1;
  if (months < 0) months = 0;

  final years = months ~/ 12;
  final remainder = months % 12;

  // Under a month reads as one month rather than as nothing: "الآن — الآن"
  // with no duration looks like missing data, not like a role that just began.
  if (years == 0 && remainder == 0) return _arabicMonths(1);
  if (years == 0) return _arabicMonths(remainder);
  if (remainder == 0) return _arabicYears(years);
  return '${_arabicYears(years)} و${_arabicMonths(remainder)}';
}

/// Arabic counts inflect by band, not by singular/plural: one, two (dual),
/// 3–10 (plural of paucity), then 11+ back to the singular form.
String _arabicYears(int value) => switch (value) {
  1 => 'سنة',
  2 => 'سنتان',
  <= 10 => '${_arabicDigits(value)} سنوات',
  _ => '${_arabicDigits(value)} سنة',
};

String _arabicMonths(int value) => switch (value) {
  1 => 'شهر',
  2 => 'شهران',
  <= 10 => '${_arabicDigits(value)} أشهر',
  _ => '${_arabicDigits(value)} شهراً',
};
