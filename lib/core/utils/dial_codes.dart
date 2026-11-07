/// The countries the sign-up form offers a dial code for.
///
/// Deliberately short. A world list is 240 rows of which this audience uses
/// thirteen, and a picker that long needs a search box, which is a second
/// interaction on a field that should cost one tap. Iraq leads because it is
/// the default; the rest run Gulf, then Levant, then Egypt.
class DialCode {
  const DialCode({
    required this.iso,
    required this.dial,
    required this.arabicName,
    required this.flag,
    required this.minNsnLength,
  });

  /// ISO 3166-1 alpha-2, used as the stored preference key.
  final String iso;

  /// Country calling code, digits only, no `+`.
  final String dial;

  final String arabicName;

  /// Emoji flag. Renders on both platforms without shipping an image per
  /// country, which for thirteen rows is the whole asset budget saved.
  final String flag;

  /// Shortest national significant number — the digits AFTER the trunk zero —
  /// that this country issues. The sign-up field's length check reads this
  /// rather than one hard-coded floor, which used to let a Kuwaiti number
  /// through at seven digits and an Iraqi one at seven of its ten.
  ///
  /// A floor, not an exact length: landlines are shorter than mobiles in
  /// several of these, and a form that refuses a real number is a worse
  /// failure than one that lets a short number reach the server.
  final int minNsnLength;

  String get display => '+$dial';
}

/// What the phone field starts on.
///
/// Named separately rather than taken as `kDialCodes.first`: a list's `.first`
/// is a method call, so it is not a constant expression and cannot initialise
/// a `const`. Both references below are the same `const` expression, which
/// Dart canonicalises to one object, so identity comparisons still hold.
const DialCode kDefaultDialCode = DialCode(
  iso: 'IQ',
  dial: '964',
  arabicName: 'العراق',
  flag: '🇮🇶',
  minNsnLength: 10,
);

/// Iraq first — it is the default.
const List<DialCode> kDialCodes = [
  kDefaultDialCode,
  DialCode(iso: 'SA', dial: '966', arabicName: 'السعودية', flag: '🇸🇦', minNsnLength: 9),
  DialCode(iso: 'AE', dial: '971', arabicName: 'الإمارات', flag: '🇦🇪', minNsnLength: 9),
  DialCode(iso: 'KW', dial: '965', arabicName: 'الكويت', flag: '🇰🇼', minNsnLength: 8),
  DialCode(iso: 'QA', dial: '974', arabicName: 'قطر', flag: '🇶🇦', minNsnLength: 8),
  DialCode(iso: 'BH', dial: '973', arabicName: 'البحرين', flag: '🇧🇭', minNsnLength: 8),
  DialCode(iso: 'OM', dial: '968', arabicName: 'عُمان', flag: '🇴🇲', minNsnLength: 8),
  DialCode(iso: 'JO', dial: '962', arabicName: 'الأردن', flag: '🇯🇴', minNsnLength: 9),
  DialCode(iso: 'SY', dial: '963', arabicName: 'سوريا', flag: '🇸🇾', minNsnLength: 9),
  DialCode(iso: 'LB', dial: '961', arabicName: 'لبنان', flag: '🇱🇧', minNsnLength: 8),
  DialCode(iso: 'PS', dial: '970', arabicName: 'فلسطين', flag: '🇵🇸', minNsnLength: 9),
  DialCode(iso: 'YE', dial: '967', arabicName: 'اليمن', flag: '🇾🇪', minNsnLength: 9),
  DialCode(iso: 'EG', dial: '20', arabicName: 'مصر', flag: '🇪🇬', minNsnLength: 10),
];

/// Everything the phone field needs to turn what someone typed into one
/// canonical string.
abstract final class PhoneFormat {
  /// The digits of [local], with the national trunk zero removed.
  ///
  /// People type their number the way they say it — `0770 182 7031` — and that
  /// leading zero is a domestic dialling prefix, not part of the number. Left
  /// on, it produces `+9640770…`, which is not a phone number anywhere.
  ///
  /// ONE zero, not every leading zero. `00770…` is a typo, and silently
  /// repairing it into a valid-looking number is how a wrong number gets
  /// registered; stripping one leaves it short enough for the length check to
  /// catch.
  static String nsn(String local) {
    final digits = local.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0') ? digits.substring(1) : digits;
  }

  /// The subscriber's own digits for [local] under [code] — everything that
  /// goes after the `+<dial>`.
  ///
  /// The validator and [e164] both read this, and that is the point: a form
  /// that length-checks one normalisation and transmits another will happily
  /// pass a number it then mangles.
  ///
  /// Tolerates a number that already carries its country code. The field
  /// strips everything but digits, so an OS autofill or a paste of
  /// `+964 770 182 7031` arrives here as `9647701827031` with no `+` left to
  /// recognise it by — and naively prefixing would register
  /// `+9649647701827031`. An international prefix (`00`) or a leading copy of
  /// the selected dial code is removed first, then the trunk zero.
  static String national(DialCode code, String local) {
    var digits = local.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith(code.dial)) {
      digits = digits.substring(code.dial.length);
    }
    return nsn(digits);
  }

  /// `+<dial><national>` — the one shape that goes on the wire.
  ///
  /// Empty when there is nothing to format, so a caller can treat "no number"
  /// and "no valid number" the same way.
  static String e164(DialCode code, String local) {
    final subscriber = national(code, local);
    return subscriber.isEmpty ? '' : '+${code.dial}$subscriber';
  }
}
