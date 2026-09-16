/// Country used by the phone-code picker on Auth screens (login,
/// registration, forgot-password).
///
/// Kept intentionally small — Iraq is our home market so we don't need
/// the full ISO list here, just the countries our expat + diaspora users
/// realistically dial from. Add rows as customer support tickets tell
/// us what's missing.
class Country {
  const Country({
    required this.iso,
    required this.dialCode,
    required this.name,
    required this.nameAr,
    required this.flag,
  });

  /// ISO 3166-1 alpha-2 code (e.g., `IQ`, `US`). Never shown to users;
  /// used only for equality + persistence (if we ever remember the
  /// user's choice across launches).
  final String iso;

  /// `+` prefix + dial code, ready to concatenate with the user's
  /// digits to form an E.164 number (e.g., `+964` → `+9647701234567`).
  final String dialCode;

  /// English name — kept for search matching in the picker.
  final String name;

  /// Arabic display name shown in the picker row.
  final String nameAr;

  /// Emoji flag. Renders as a real flag on modern iOS/Android; on
  /// mismatched font stacks it degrades to the two-letter ISO glyphs,
  /// which is still readable.
  final String flag;

  @override
  bool operator ==(Object other) =>
      other is Country && other.iso == iso;

  @override
  int get hashCode => iso.hashCode;
}

/// Curated list of countries. Order
/// matches the picker's default sort — Iraq first, Arab League next,
/// then diaspora hotspots. Add rows when a real customer asks for it,
/// don't pre-populate the world.
class Countries {
  Countries._();

  /// Iraq — the default selection everywhere in the app.
  static const iraq = Country(
    iso: 'IQ',
    dialCode: '+964',
    name: 'Iraq',
    nameAr: 'العراق',
    flag: '🇮🇶',
  );

  /// All supported countries. `[0]` is [iraq] — the picker treats it as
  /// the default when no explicit selection is made.
  static const List<Country> all = [
    iraq,
    Country(iso: 'SA', dialCode: '+966', name: 'Saudi Arabia', nameAr: 'السعودية', flag: '🇸🇦'),
    Country(iso: 'AE', dialCode: '+971', name: 'UAE', nameAr: 'الإمارات', flag: '🇦🇪'),
    Country(iso: 'KW', dialCode: '+965', name: 'Kuwait', nameAr: 'الكويت', flag: '🇰🇼'),
    Country(iso: 'QA', dialCode: '+974', name: 'Qatar', nameAr: 'قطر', flag: '🇶🇦'),
    Country(iso: 'BH', dialCode: '+973', name: 'Bahrain', nameAr: 'البحرين', flag: '🇧🇭'),
    Country(iso: 'OM', dialCode: '+968', name: 'Oman', nameAr: 'عُمان', flag: '🇴🇲'),
    Country(iso: 'JO', dialCode: '+962', name: 'Jordan', nameAr: 'الأردن', flag: '🇯🇴'),
    Country(iso: 'LB', dialCode: '+961', name: 'Lebanon', nameAr: 'لبنان', flag: '🇱🇧'),
    Country(iso: 'SY', dialCode: '+963', name: 'Syria', nameAr: 'سوريا', flag: '🇸🇾'),
    Country(iso: 'PS', dialCode: '+970', name: 'Palestine', nameAr: 'فلسطين', flag: '🇵🇸'),
    Country(iso: 'EG', dialCode: '+20', name: 'Egypt', nameAr: 'مصر', flag: '🇪🇬'),
    Country(iso: 'YE', dialCode: '+967', name: 'Yemen', nameAr: 'اليمن', flag: '🇾🇪'),
    Country(iso: 'MA', dialCode: '+212', name: 'Morocco', nameAr: 'المغرب', flag: '🇲🇦'),
    Country(iso: 'DZ', dialCode: '+213', name: 'Algeria', nameAr: 'الجزائر', flag: '🇩🇿'),
    Country(iso: 'TN', dialCode: '+216', name: 'Tunisia', nameAr: 'تونس', flag: '🇹🇳'),
    Country(iso: 'LY', dialCode: '+218', name: 'Libya', nameAr: 'ليبيا', flag: '🇱🇾'),
    Country(iso: 'SD', dialCode: '+249', name: 'Sudan', nameAr: 'السودان', flag: '🇸🇩'),
    Country(iso: 'TR', dialCode: '+90', name: 'Turkey', nameAr: 'تركيا', flag: '🇹🇷'),
    Country(iso: 'IR', dialCode: '+98', name: 'Iran', nameAr: 'إيران', flag: '🇮🇷'),
    Country(iso: 'US', dialCode: '+1', name: 'United States', nameAr: 'الولايات المتحدة', flag: '🇺🇸'),
    Country(iso: 'CA', dialCode: '+1', name: 'Canada', nameAr: 'كندا', flag: '🇨🇦'),
    Country(iso: 'GB', dialCode: '+44', name: 'United Kingdom', nameAr: 'المملكة المتحدة', flag: '🇬🇧'),
    Country(iso: 'DE', dialCode: '+49', name: 'Germany', nameAr: 'ألمانيا', flag: '🇩🇪'),
    Country(iso: 'FR', dialCode: '+33', name: 'France', nameAr: 'فرنسا', flag: '🇫🇷'),
    Country(iso: 'SE', dialCode: '+46', name: 'Sweden', nameAr: 'السويد', flag: '🇸🇪'),
    Country(iso: 'NL', dialCode: '+31', name: 'Netherlands', nameAr: 'هولندا', flag: '🇳🇱'),
    Country(iso: 'AU', dialCode: '+61', name: 'Australia', nameAr: 'أستراليا', flag: '🇦🇺'),
    Country(iso: 'IN', dialCode: '+91', name: 'India', nameAr: 'الهند', flag: '🇮🇳'),
    Country(iso: 'PK', dialCode: '+92', name: 'Pakistan', nameAr: 'باكستان', flag: '🇵🇰'),
  ];

  /// Reverse-lookup a country from an E.164 phone (e.g.
  /// `"+9647701234567"` → [iraq]). Longest-prefix match so shared
  /// codes like `+1` (US + Canada) at least pick a valid country;
  /// caller must accept that some ambiguity is unavoidable when two
  /// countries share a dial code. Returns null when no prefix matches
  /// — caller usually falls back to [iraq].
  static Country? findByDialCode(String e164) {
    if (e164.isEmpty) return null;
    final sorted = List<Country>.from(all)
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    for (final c in sorted) {
      if (e164.startsWith(c.dialCode)) return c;
    }
    return null;
  }

  /// Case-insensitive substring match across [Country.name] +
  /// [Country.nameAr] + [Country.dialCode]. Empty query returns the
  /// full list unchanged.
  static List<Country> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.nameAr.contains(query.trim()) ||
          c.dialCode.contains(q);
    }).toList(growable: false);
  }
}
