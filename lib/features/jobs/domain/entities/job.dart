import 'package:mohandis/core/base/base_entity.dart';

/// Where the work happens — the backend's `WorkplaceTypeEnum`.
///
/// The declaration order is the order of the jobs-list chip row, and it is
/// deliberately NOT the server's (`OnSite = 0, Remote = 1, Hybrid = 2`).
/// Nothing may convert between the two by index; `JobDto.workModeFromWire`
/// maps them explicitly.
enum WorkMode { remote, hybrid, onsite }

/// The backend's `EmploymentTypeEnum`.
///
/// All seven server members are carried even though the design only ever drew
/// four labels. Dropping the other three would mean a freelance posting came
/// back as "full-time" and then, if it were ever sent back in a filter, moved
/// itself into the wrong bucket. `EmploymentTypeLabel` handles the missing
/// copy instead — display degrades, the value does not.
enum EmploymentType {
  fullTime,
  partTime,
  contract,
  internship,
  freelance,
  selfEmployed,
  temporary,
}

class Job extends BaseEntity {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.postedAt,
    required this.applicantCount,
    this.workMode,
    this.employmentType,
    this.salaryLabel = '',
    this.description = '',
    this.requirements = const [],
    this.isOpen = true,
    this.applied = false,
    this.saved = false,
  });

  @override
  final String id;

  final String title;
  final String company;

  /// Free text as the poster typed it; `null` on the wire, empty here.
  final String location;

  /// Both are optional on the posting form, so both are optional here — a card
  /// hides the chip rather than inventing "on-site" / "full-time" for a job
  /// that never said so.
  final WorkMode? workMode;
  final EmploymentType? employmentType;

  /// Rendered from `salaryMin` / `salaryMax` / `currency` by [JobDto], because
  /// the backend stores three loose numbers and no display string. Empty when
  /// the posting gave no figures at all — every widget that shows it must
  /// check, or an empty chip appears on most rows.
  final String salaryLabel;

  final DateTime postedAt;
  final int applicantCount;
  final String description;

  /// The server keeps requirements as one free-text blob; [JobDto] splits it
  /// back into the bullet list the detail screen renders.
  final List<String> requirements;

  /// A closed posting still resolves by id (it stays visible from an existing
  /// application or a shared post), it just cannot be applied to.
  final bool isOpen;

  /// The server's `hasApplied`, evaluated for the calling profile. Distinct
  /// from the locally held applications list: this is authoritative on a cold
  /// start, the local list is the only thing that knows about an application
  /// submitted seconds ago. Widgets should treat either one as "applied".
  final bool applied;

  /// The viewer has bookmarked this posting. Private to them — there is no
  /// counter and the poster is never told.
  final bool saved;

  /// Logo monogram. There is no such column on the server — this used to be
  /// declared as a backend-supplied field and never was one — so it is derived
  /// from the company name: the first character of each of the first two
  /// words. Arabic is caseless, so nothing is upper-cased.
  String get monogram {
    final words = company
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '؟';
    // `runes`, not `[0]`: a company name starting with an emoji or any other
    // astral character would otherwise be cut mid-surrogate-pair.
    return words
        .take(2)
        .map((word) => String.fromCharCodes(word.runes.take(1)))
        .join();
  }

  /// Only the two viewer-relative flags are settable.
  ///
  /// Everything else on a job belongs to the poster and reaches the app one
  /// way — from the server. A general-purpose copyWith here would be an
  /// invitation to patch a title or a salary locally and have the next read
  /// silently disagree.
  Job copyWith({bool? applied, bool? saved}) => Job(
    id: id,
    title: title,
    company: company,
    location: location,
    postedAt: postedAt,
    applicantCount: applicantCount,
    workMode: workMode,
    employmentType: employmentType,
    salaryLabel: salaryLabel,
    description: description,
    requirements: requirements,
    isOpen: isOpen,
    applied: applied ?? this.applied,
    saved: saved ?? this.saved,
  );
}
