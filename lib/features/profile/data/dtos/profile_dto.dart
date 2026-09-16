import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';

import '../../domain/entities/profile.dart';

/// Wire model for the backend's `ProfileDto`
/// (`GET /api/social/Profiles/{id}`, `GET /api/social/Profiles/Me`,
/// `POST /api/social/Profiles` with `?detailed=true`).
///
/// The CV sections are NOT part of this payload — experience, education and
/// skills are three separate endpoints, fetched alongside and passed to
/// [toDomain]. That is why `toDomain()` takes arguments: a profile with no
/// sections is a valid partial read, not an error.
class ProfileDto implements BaseDto<Profile> {
  const ProfileDto({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.website,
    this.location,
    this.headline,
    this.industry,
    this.cvUrl,
    this.about,
    this.isOpenToWork = false,
    this.isHiring = false,
    this.isPrivate = false,
    this.isVerified = false,
    this.accountType = AccountType.individual,
    this.companySize = CompanySize.unspecified,
    this.foundedOn,
    this.specialties,
    this.followerCount = 0,
    this.followingCount = 0,
    this.connectionCount = 0,
    this.postCount = 0,
    this.isMe = false,
    this.isFollowing = false,
    this.followRequestPending = false,
    this.isConnected = false,
    this.connectionIncoming = false,
    this.connectionOutgoing = false,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) => ProfileDto(
    id: '${json['id'] ?? ''}',
    username: '${json['username'] ?? ''}',
    displayName: '${json['displayName'] ?? ''}',
    bio: json['bio'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    coverUrl: json['coverUrl'] as String?,
    website: json['website'] as String?,
    location: json['location'] as String?,
    headline: json['headline'] as String?,
    industry: json['industry'] as String?,
    cvUrl: json['cvUrl'] as String?,
    about: json['about'] as String?,
    isOpenToWork: json['isOpenToWork'] == true,
    isHiring: json['isHiring'] == true,
    isPrivate: json['isPrivate'] == true,
    isVerified: json['isVerified'] == true,
    accountType: accountTypeFromWire(json['accountType']),
    companySize: companySizeFromWire(json['companySize']),
    // A `date` column, so it arrives as "2015-03-01" with no time. Parsed
    // as a plain local date — reading it as UTC would shift it a day for any
    // viewer behind Greenwich.
    foundedOn: _dateOnly(json['foundedOn']),
    specialties: json['specialties'] as String?,
    followerCount: _int(json['followerCount']),
    followingCount: _int(json['followingCount']),
    connectionCount: _int(json['connectionCount']),
    postCount: _int(json['postCount']),
    isMe: json['isMe'] == true,
    isFollowing: json['isFollowing'] == true,
    followRequestPending: json['followRequestPending'] == true,
    isConnected: json['isConnected'] == true,
    connectionIncoming: json['connectionIncoming'] == true,
    connectionOutgoing: json['connectionOutgoing'] == true,
  );

  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String? website;
  final String? location;
  final String? headline;
  final String? industry;
  final String? cvUrl;
  final String? about;
  final bool isOpenToWork;
  final bool isHiring;
  final bool isPrivate;
  final bool isVerified;
  final AccountType accountType;

  /// Meaningful only when [accountType] is company; holds its empty value
  /// otherwise.
  final CompanySize companySize;
  final DateTime? foundedOn;

  /// Newline-separated on the wire — one column rather than a child table.
  final String? specialties;
  final int followerCount;
  final int followingCount;
  final int connectionCount;
  final int postCount;
  final bool isMe;
  final bool isFollowing;
  final bool followRequestPending;
  final bool isConnected;
  final bool connectionIncoming;
  final bool connectionOutgoing;

  @override
  Profile toDomain({
    List<Experience> experience = const [],
    List<Education> education = const [],
    List<Skill> skills = const [],
  }) => Profile(
    personId: id,
    username: username,
    displayName: displayName,
    headline: headline ?? '',
    location: location ?? '',
    avatarUrl: avatarUrl,
    coverUrl: coverUrl,
    website: website,
    verified: isVerified,
    accountType: accountType,
    isMe: isMe,
    // `about` is the professional summary and `bio` the short social one. The
    // profile screen shows a single "about" block, so fall back rather than
    // leave it blank for a profile that only filled in the social side.
    about: about ?? bio ?? '',
    industry: industry ?? '',
    cvUrl: cvUrl,
    openToWork: isOpenToWork,
    hiring: isHiring,
    isPrivate: isPrivate,
    following: isFollowing,
    followRequestPending: followRequestPending,
    connected: isConnected,
    connectionIncoming: connectionIncoming,
    connectionOutgoing: connectionOutgoing,
    connectionCount: connectionCount,
    followerCount: followerCount,
    followingCount: followingCount,
    postCount: postCount,
    experience: experience,
    education: education,
    skills: skills,
    companySize: companySize,
    foundedOn: foundedOn,
    specialties: specialtiesFrom(specialties),
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'headline': headline,
    'industry': industry,
    'cvUrl': cvUrl,
    'about': about,
    'location': location,
    'isOpenToWork': isOpenToWork,
    'isPrivate': isPrivate,
  };

  static int _int(Object? raw) => (raw as num?)?.toInt() ?? 0;

  /// `AccountTypeEnum` — by name, since the host registers Newtonsoft's
  /// `StringEnumConverter`; ordinals are accepted too. Anything unrecognised,
  /// including the null a pre-migration row returns, reads as individual.
  static AccountType accountTypeFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < AccountType.values.length
          ? AccountType.values[i]
          : AccountType.individual;
    }
    return '$raw'.toLowerCase() == 'company'
        ? AccountType.company
        : AccountType.individual;
  }

  /// Writes go through the Kernel generic engine, which takes the enum by
  /// name — the same spelling the C# member has.
  static String accountTypeToWire(AccountType type) =>
      type == AccountType.company ? 'Company' : 'Individual';

  /// `CompanySizeEnum` — same conventions as [accountTypeFromWire]: by name
  /// normally, ordinal tolerated, and anything unrecognised (including the
  /// null a pre-migration row returns) reads as "not stated".
  ///
  /// The Dart enum is declared in the server's order, so the ordinal path is a
  /// straight index — but it is bounds-checked, because a value added
  /// server-side and not yet here must degrade rather than throw.
  static CompanySize companySizeFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < CompanySize.values.length
          ? CompanySize.values[i]
          : CompanySize.unspecified;
    }
    final name = '$raw'.toLowerCase();
    for (final value in CompanySize.values) {
      if (value.name.toLowerCase() == name) return value;
    }
    return CompanySize.unspecified;
  }

  /// The member name the Kernel generic write engine expects — capitalised,
  /// matching the C# member.
  static String companySizeToWire(CompanySize size) =>
      '${size.name[0].toUpperCase()}${size.name.substring(1)}';

  /// Splits the stored blob into the chips the profile renders.
  ///
  /// Newlines are the separator the editor writes, but a company pasting a
  /// comma-separated list is the obvious mistake to absorb rather than punish,
  /// so both split.
  static List<String> specialtiesFrom(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return const [];
    return text
        .split(RegExp(r'[\n,]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }
}

/// `ExperienceDto` — `POST /api/social/Experience`.
class ExperienceDto {
  const ExperienceDto({
    required this.title,
    required this.companyName,
    this.id = 0,
    this.employmentType,
    this.location,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
  });

  factory ExperienceDto.fromJson(Map<String, dynamic> json) => ExperienceDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: '${json['title'] ?? ''}',
    companyName: '${json['companyName'] ?? ''}',
    // Nullable enum, serialised by name. Kept as the wire string rather than
    // parsed: the editor only ever hands it straight back.
    employmentType: json['employmentType'] == null
        ? null
        : '${json['employmentType']}',
    location: json['location'] as String?,
    startDate: DateTime.tryParse('${json['startDate']}'),
    endDate: DateTime.tryParse('${json['endDate']}'),
    isCurrent: json['isCurrent'] == true,
    description: json['description'] as String?,
  );

  final int id;
  final String title;
  final String companyName;
  final String? employmentType;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  Experience toDomain() => Experience(
    id: id,
    role: title,
    company: companyName,
    monogram: monogramOf(companyName),
    dates: formatDateRangeArabic(startDate, endDate, isCurrent),
    location: location ?? '',
    description: description ?? '',
    employmentType: employmentType,
    startDate: startDate,
    endDate: endDate,
    isCurrent: isCurrent,
  );
}

/// `EducationDto` — `POST /api/social/Education`.
class EducationDto {
  const EducationDto({
    required this.school,
    this.id = 0,
    this.degree,
    this.fieldOfStudy,
    this.description,
    this.startDate,
    this.endDate,
  });

  factory EducationDto.fromJson(Map<String, dynamic> json) => EducationDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    school: '${json['school'] ?? ''}',
    degree: json['degree'] as String?,
    fieldOfStudy: json['fieldOfStudy'] as String?,
    description: json['description'] as String?,
    startDate: DateTime.tryParse('${json['startDate']}'),
    endDate: DateTime.tryParse('${json['endDate']}'),
  );

  final int id;
  final String school;
  final String? degree;
  final String? fieldOfStudy;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  Education toDomain() => Education(
    id: id,
    school: school,
    monogram: monogramOf(school),
    // The row shows one line, so the field of study rides along with the
    // degree rather than claiming a line of its own.
    degreeLine: [
      if (degree != null && degree!.isNotEmpty) degree!,
      if (fieldOfStudy != null && fieldOfStudy!.isNotEmpty) fieldOfStudy!,
    ].join(' · '),
    dates: formatDateRangeArabic(startDate, endDate, false),
    degree: degree ?? '',
    fieldOfStudy: fieldOfStudy ?? '',
    description: description ?? '',
    startDate: startDate,
    endDate: endDate,
  );
}

/// `SkillDto` — `POST /api/social/Skills`.
class SkillDto {
  const SkillDto({
    required this.id,
    required this.name,
    this.endorsementCount = 0,
    this.isEndorsedByMe = false,
  });

  factory SkillDto.fromJson(Map<String, dynamic> json) => SkillDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    endorsementCount: (json['endorsementCount'] as num?)?.toInt() ?? 0,
    isEndorsedByMe: json['isEndorsedByMe'] == true,
  );

  final int id;
  final String name;
  final int endorsementCount;
  final bool isEndorsedByMe;

  Skill toDomain() => Skill(
    id: id,
    name: name,
    endorsements: endorsementCount,
    endorsedByMe: isEndorsedByMe,
  );
}

/// Two-letter monogram for the logo tile beside a company or school.
///
/// The backend stores no logo, so the tile is generated from the name — the
/// same trick the avatar uses for people.
String monogramOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '؟';
  if (parts.length == 1) {
    return parts.first.length <= 2 ? parts.first : parts.first.substring(0, 2);
  }
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}';
}

/// A `date` off the wire (`yyyy-MM-dd`), as a local midnight.
///
/// `DateTime.parse` on a bare date already yields local midnight; the guard is
/// for a host that sends a full timestamp instead, where taking the date parts
/// is what keeps the day from moving.
DateTime? _dateOnly(Object? raw) {
  if (raw == null) return null;
  final text = '$raw'.trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}
