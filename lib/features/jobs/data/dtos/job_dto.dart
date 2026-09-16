import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/features/posts/data/dtos/post_dto.dart';

import '../../domain/entities/job.dart';

/// Wire model for the backend's `JobDto` (`POST /api/social/Jobs`,
/// `GET Jobs/{id}`, `Jobs/Publish`).
///
/// Field names follow the C# DTO, not the mobile entity: the company is
/// `companyName`, the workplace mode is `workplaceType`, the applicant tally
/// is `applicationCount`, and `requirements` is one free-text blob rather than
/// a list. Three things the old client-side model assumed simply do not exist
/// here — a logo monogram, a skills/tags array, and a preformatted salary
/// string — so [toDomain] derives what it can and drops the rest.
class JobDto implements BaseDto<Job> {
  const JobDto({
    required this.id,
    required this.postedById,
    required this.title,
    required this.companyName,
    required this.description,
    required this.createdAt,
    this.postedByName = '',
    this.postedByAvatarUrl,
    this.location,
    this.employmentType,
    this.workplaceType,
    this.requirements,
    this.salaryMin,
    this.salaryMax,
    this.currency,
    this.isOpen = true,
    this.applicationCount = 0,
    this.closesAt,
    this.hasApplied = false,
    this.isSaved = false,
  });

  factory JobDto.fromJson(Map<String, dynamic> json) => JobDto(
    id: '${json['id'] ?? ''}',
    postedById: '${json['postedById'] ?? ''}',
    postedByName: '${json['postedByName'] ?? ''}',
    postedByAvatarUrl: json['postedByAvatarUrl'] as String?,
    title: '${json['title'] ?? ''}',
    companyName: '${json['companyName'] ?? ''}',
    location: json['location'] as String?,
    employmentType: employmentTypeFromWire(json['employmentType']),
    workplaceType: workModeFromWire(json['workplaceType']),
    description: '${json['description'] ?? ''}',
    requirements: json['requirements'] as String?,
    salaryMin: json['salaryMin'] as num?,
    salaryMax: json['salaryMax'] as num?,
    currency: json['currency'] as String?,
    // `IsOpen` is non-nullable server-side; the `!= false` shape only guards a
    // payload that omitted it entirely.
    isOpen: json['isOpen'] != false,
    applicationCount: PostDto.asInt(json['applicationCount']),
    closesAt: json['closesAt'] == null
        ? null
        : PostDto.parseDate(json['closesAt']),
    createdAt: PostDto.parseDate(json['createdAt']),
    hasApplied: json['hasApplied'] == true,
    isSaved: json['isSaved'] == true,
  );

  final String id;
  final String postedById;
  final String postedByName;
  final String? postedByAvatarUrl;
  final String title;
  final String companyName;
  final String? location;
  final EmploymentType? employmentType;
  final WorkMode? workplaceType;
  final String description;
  final String? requirements;
  final num? salaryMin;
  final num? salaryMax;
  final String? currency;
  final bool isOpen;
  final int applicationCount;
  final DateTime? closesAt;
  final DateTime createdAt;
  final bool hasApplied;
  final bool isSaved;

  @override
  Job toDomain() => Job(
    id: id,
    title: title,
    company: companyName,
    location: location ?? '',
    workMode: workplaceType,
    employmentType: employmentType,
    salaryLabel: salaryLabelFrom(salaryMin, salaryMax, currency),
    postedAt: createdAt,
    applicantCount: applicationCount,
    description: description,
    requirements: requirementsFrom(requirements),
    isOpen: isOpen,
    applied: hasApplied,
    saved: isSaved,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'postedById': postedById,
    'postedByName': postedByName,
    'postedByAvatarUrl': postedByAvatarUrl,
    'title': title,
    'companyName': companyName,
    'location': location,
    if (employmentType != null)
      'employmentType': employmentTypeToWire(employmentType!),
    if (workplaceType != null) 'workplaceType': workModeToWire(workplaceType!),
    'description': description,
    'requirements': requirements,
    'salaryMin': salaryMin,
    'salaryMax': salaryMax,
    'currency': currency,
    'isOpen': isOpen,
    'applicationCount': applicationCount,
    'closesAt': closesAt?.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'hasApplied': hasApplied,
    'isSaved': isSaved,
  };

  // ── Wire helpers ─────────────────────────────────────────────────────────

  /// `WorkplaceTypeEnum` — `OnSite` / `Remote` / `Hybrid`, nullable on the
  /// posting form.
  ///
  /// Null survives as null: a posting that never stated a mode must not be
  /// labelled "من المقر". An unrecognised value is treated the same way — a
  /// mode this client has never heard of is exactly "unknown", not on-site.
  ///
  /// The int branch is the server's ordinals (`OnSite = 0`), which are NOT
  /// [WorkMode]'s declaration order, so `WorkMode.values[i]` would relabel
  /// every remote job as hybrid.
  static WorkMode? workModeFromWire(Object? raw) {
    if (raw == null) return null;
    if (raw is num) {
      return switch (raw.toInt()) {
        0 => WorkMode.onsite,
        1 => WorkMode.remote,
        2 => WorkMode.hybrid,
        _ => null,
      };
    }
    return switch ('$raw'.toLowerCase()) {
      'onsite' => WorkMode.onsite,
      'remote' => WorkMode.remote,
      'hybrid' => WorkMode.hybrid,
      _ => null,
    };
  }

  /// The exact `WorkplaceTypeEnum` member name. `StringEnumConverter` is
  /// registered host-side, so filters and forms travel by name.
  static String workModeToWire(WorkMode mode) => switch (mode) {
    WorkMode.onsite => 'OnSite',
    WorkMode.remote => 'Remote',
    WorkMode.hybrid => 'Hybrid',
  };

  /// `EmploymentTypeEnum` — seven members, also nullable on the form.
  static EmploymentType? employmentTypeFromWire(Object? raw) {
    if (raw == null) return null;
    if (raw is num) {
      return switch (raw.toInt()) {
        0 => EmploymentType.fullTime,
        1 => EmploymentType.partTime,
        2 => EmploymentType.contract,
        3 => EmploymentType.internship,
        4 => EmploymentType.freelance,
        5 => EmploymentType.selfEmployed,
        6 => EmploymentType.temporary,
        _ => null,
      };
    }
    return switch ('$raw'.toLowerCase()) {
      'fulltime' => EmploymentType.fullTime,
      'parttime' => EmploymentType.partTime,
      'contract' => EmploymentType.contract,
      'internship' => EmploymentType.internship,
      'freelance' => EmploymentType.freelance,
      'selfemployed' => EmploymentType.selfEmployed,
      'temporary' => EmploymentType.temporary,
      _ => null,
    };
  }

  static String employmentTypeToWire(EmploymentType type) => switch (type) {
    EmploymentType.fullTime => 'FullTime',
    EmploymentType.partTime => 'PartTime',
    EmploymentType.contract => 'Contract',
    EmploymentType.internship => 'Internship',
    EmploymentType.freelance => 'Freelance',
    EmploymentType.selfEmployed => 'SelfEmployed',
    EmploymentType.temporary => 'Temporary',
  };

  /// Builds the salary line the cards show.
  ///
  /// The backend stores `SalaryMin` / `SalaryMax` / `Currency` and nothing
  /// preformatted, and all three are optional — most postings carry none of
  /// them, which is why the result is allowed to be empty and every caller
  /// hides its chip when it is.
  ///
  /// Digits go through [ArabicNumbers] like every other number in this feature.
  /// The currency stays as the poster typed it ("USD", "SAR", "د.إ"): it is
  /// free text server-side, so there is nothing to look up and guessing a
  /// symbol would put the wrong one on the row.
  static String salaryLabelFrom(num? min, num? max, String? currency) {
    if (min == null && max == null) return '';
    final code = (currency ?? '').trim();
    // An open-ended posting ("from 90k") and one that quotes a single figure
    // both collapse to one number rather than showing "٩٠٬٠٠٠ – ٩٠٬٠٠٠".
    final range = (min != null && max != null && min != max)
        ? '${ArabicNumbers.count(min)} – ${ArabicNumbers.count(max)}'
        : ArabicNumbers.count(min ?? max!);
    return code.isEmpty ? range : '$range $code';
  }

  /// Splits `Requirements` — one free-text column — into the bullet list the
  /// detail screen renders.
  ///
  /// Posters type these as lines, often already bulleted, so the leading
  /// marker is stripped to avoid rendering "• ‑ خبرة…" next to the tick icon.
  static List<String> requirementsFrom(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceFirst(RegExp(r'^\s*[-*•·–—]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }
}
