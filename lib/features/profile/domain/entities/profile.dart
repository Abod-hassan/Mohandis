import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

/// One work-experience entry.
///
/// Carries both the rendered form ([dates], [monogram]) and the raw columns the
/// editor writes back, because an edit round-trips through the Kernel's generic
/// write engine against `ExperienceModel` — a formatted date range cannot be
/// turned back into a `StartDate`.
class Experience {
  const Experience({
    required this.role,
    required this.company,
    required this.monogram,
    required this.dates,
    required this.location,
    this.id = 0,
    this.description = '',
    this.employmentType,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
  });

  /// The `ExperienceModel` row id. `0` means "not saved yet" — what the editor
  /// sends as a create.
  final int id;

  final String role;
  final String company;
  final String monogram;

  /// Preformatted for display ("2022 — الآن · 3 سنوات"). Derived from
  /// [startDate]/[endDate]/[isCurrent]; never sent back.
  final String dates;

  final String location;
  final String description;

  /// `EmploymentTypeEnum` by name — the host serialises enums by name, and the
  /// column is nullable.
  final String? employmentType;

  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;

  bool get hasDescription => description.trim().isNotEmpty;

  Experience copyWith({
    String? role,
    String? company,
    String? location,
    String? description,
    String? employmentType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
  }) {
    return Experience(
      id: id,
      role: role ?? this.role,
      company: company ?? this.company,
      monogram: monogram,
      dates: dates,
      location: location ?? this.location,
      description: description ?? this.description,
      employmentType: employmentType ?? this.employmentType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

/// One education entry. Same split as [Experience]: [degreeLine] is what the
/// row shows, [degree] and [fieldOfStudy] are the columns the editor writes.
class Education {
  const Education({
    required this.school,
    required this.monogram,
    required this.degreeLine,
    required this.dates,
    this.id = 0,
    this.degree = '',
    this.fieldOfStudy = '',
    this.description = '',
    this.startDate,
    this.endDate,
  });

  /// The `EducationModel` row id. `0` means "not saved yet".
  final int id;

  final String school;
  final String monogram;

  /// Degree and field joined for the single line the row renders.
  final String degreeLine;

  final String dates;
  final String degree;
  final String fieldOfStudy;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;

  Education copyWith({
    String? school,
    String? degree,
    String? fieldOfStudy,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Education(
      id: id,
      school: school ?? this.school,
      monogram: monogram,
      degreeLine: degreeLine,
      dates: dates,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// What kind of account a profile is.
///
/// Distinct from Identity's `UserTypeEnum` (SystemAdmin / Admin / User), which
/// is a permission role — this is what the account IS. Chosen at sign-up and
/// stored on the social profile, since Auth's contact record has no field for
/// it. The declaration order is the wire contract: it maps to the backend's
/// `AccountTypeEnum` ordinals.
enum AccountType {
  /// The engineer — the one kind of account that LOOKS FOR work.
  individual,
  company,

  /// مقاول — takes on work and hires for it.
  contractor,

  /// حرفي — a trade: carpenter, blacksmith, electrician.
  craftsman,

  /// صاحب آلية — owns machinery and hires it out.
  equipmentOwner;

  /// True for every account that OFFERS work rather than looking for it.
  ///
  /// This is the line the product draws, and the one nearly every branch in
  /// the app is actually asking about: a business gets the management tabs,
  /// posts jobs and receives applications; an individual applies. Written as
  /// "not individual" rather than as a list of the four, so a kind added later
  /// is a business by default — the safe side, since the alternative is a new
  /// type silently gaining the job seeker's rights.
  bool get isBusiness => this != AccountType.individual;

  /// Whether this kind picks from a list of specialties at all.
  ///
  /// An engineer picks a discipline, a craftsman a trade, a machinery owner a
  /// machine. A company and a contractor describe themselves in their own
  /// words instead — there is no list for them and asking for one returns
  /// nothing.
  bool get hasDisciplineList =>
      this == AccountType.individual ||
      this == AccountType.craftsman ||
      this == AccountType.equipmentOwner;
}

/// A company's headcount, as a band — the backend's `CompanySizeEnum`.
///
/// Bands rather than a number: nobody knows their exact headcount on the day
/// they fill the form, and an exact figure would be wrong by the afternoon,
/// while "51-200" stays true for a year and is what a candidate wants to know.
///
/// [unspecified] is what an individual account and every profile written
/// before the column read as — "not stated", not "a company of one".
enum CompanySize {
  unspecified,
  self,
  micro,
  small,
  medium,
  large,
  larger,
  huge,
  enterprise;

  bool get isStated => this != CompanySize.unspecified;
}

class Skill {
  const Skill({
    required this.name,
    required this.endorsements,
    this.id = 0,
    this.endorsedByMe = false,
  });

  /// The row's int id. Endorsing goes by id, not name — a skill name is not
  /// unique across profiles, so the name alone cannot address a row.
  final int id;

  final String name;
  final int endorsements;
  final bool endorsedByMe;

  Skill copyWith({int? endorsements, bool? endorsedByMe}) => Skill(
    id: id,
    name: name,
    endorsements: endorsements ?? this.endorsements,
    endorsedByMe: endorsedByMe ?? this.endorsedByMe,
  );
}

/// The CV-shaped record behind a profile screen. Keyed by the person's id —
/// [id] and [personId] are the same value, exposed twice so `BaseEntity`
/// equality works while call sites read naturally.
class Profile extends BaseEntity {
  const Profile({
    required this.personId,
    required this.about,
    this.username = '',
    this.displayName = '',
    this.headline = '',
    this.location = '',
    this.avatarUrl,
    this.coverUrl,
    this.website,
    this.verified = false,
    this.subscribed = false,
    this.accountType = AccountType.individual,
    this.isMe = false,
    this.followRequestPending = false,
    this.industry = '',
    this.disciplineId,
    this.disciplineName = '',
    this.disciplineIconUrl,
    this.governorateId,
    this.governorateName = '',
    this.cvUrl,
    this.openToWork = false,
    this.hiring = false,
    this.isPrivate = false,
    this.following = false,
    this.connected = false,
    this.connectionIncoming = false,
    this.connectionOutgoing = false,
    this.connectionCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.companySize = CompanySize.unspecified,
    this.foundedOn,
    this.specialties = const [],
  });

  @override
  String get id => personId;

  final String personId;

  // Identity. The backend returns these on the profile itself, so a profile
  // screen no longer depends on the people directory having this person.
  final String username;
  final String displayName;
  final String headline;
  final String location;
  final String? avatarUrl;
  final String? coverUrl;
  final String? website;
  final bool verified;

  /// Holds a live subscription — see `Person.subscribed`. A billing fact, and
  /// deliberately not folded into [verified], which is a staff decision.
  final bool subscribed;

  /// Individual or company. Defaults to individual for any profile created
  /// before the column existed, which is the safe reading of a null.
  final AccountType accountType;

  /// True when this profile belongs to the caller — resolved server-side from
  /// the bearer token, never by comparing ids client-side.
  final bool isMe;

  /// A follow request was sent to a private profile and is awaiting approval.
  /// [following] stays false until it is accepted.
  final bool followRequestPending;

  /// An accepted connection — the two profiles are connected.
  final bool connected;

  /// They asked to connect with you and are waiting on an answer. The button
  /// becomes "accept" rather than "add".
  final bool connectionIncoming;

  /// You asked them, and it hasn't been accepted yet. This is what the button
  /// must show after an add request, instead of inviting the same tap again.
  final bool connectionOutgoing;

  final String about;
  final String industry;

  /// The engineering discipline — الاختصاص — this profile chose, from the
  /// tenant's list. Null for a profile that predates the list, one that has not
  /// chosen, and every company.
  final int? disciplineId;

  /// Its Arabic name and logo, inlined by the server so a profile renders
  /// without a second request. The logo is host-less like every other upload.
  final String disciplineName;
  final String? disciplineIconUrl;

  /// The governorate — المحافظة — this profile is in, from the tenant's list,
  /// and its Arabic name. [location] carries the same text for everything that
  /// reads a location as a string.
  final int? governorateId;
  final String governorateName;

  /// The host-less path of the CV on file, or null when there is none.
  ///
  /// `ProfileModel.CvUrl` has existed server-side since the module shipped and
  /// had no Dart counterpart at all, which is why applying to a job sent no
  /// résumé: there was nothing to send. Resolve it through
  /// `imageUrlResolverProvider` like any other stored path.
  final String? cvUrl;
  final bool openToWork;
  final bool hiring;
  final bool isPrivate;

  /// True when this profile is a BUSINESS page rather than a person looking
  /// for work — a company, a contractor, a craftsman, a machinery owner.
  ///
  /// Read this instead of comparing [accountType] at call sites: the profile
  /// screen, the edit form and the shell all branch on it, and one named test
  /// is what keeps them branching on the same thing.
  ///
  /// The name is historical — there were two kinds when it was written, and
  /// renaming it across fifty call sites would have been a worse change than
  /// widening what it answers. [AccountType.isBusiness] is the same question
  /// asked of the enum itself.
  bool get isCompany => accountType.isBusiness;

  // ── Company ──────────────────────────────────────────────────────────────
  //
  // Meaningless on an individual account, where they hold their empty values.
  // Nothing hides them by account type at this layer — the screens do, because
  // they are the ones that know what is being rendered.

  final CompanySize companySize;

  /// Year founded. Null when not stated — distinct from a year of 0, which is
  /// why it is nullable rather than defaulted.
  /// The day the company was founded.
  ///
  /// A date, not a year: the server stores a `date` column, and the profile
  /// renders the whole thing. Null for a person and for a company that has not
  /// said.
  final DateTime? foundedOn;

  /// What the company does. Stored server-side as one newline-separated blob
  /// and split here, the same shape as a job's requirements.
  final List<String> specialties;

  /// Whether anything is left for the details card once the header has had
  /// its share.
  ///
  /// Industry, headcount and founding date moved up into the meta line under
  /// the company's name — they are the first facts anyone wants and they were
  /// sitting in a card below the fold. What stays down here is what does not
  /// fit on one line: the website and the list of specialties. The old
  /// `hasCompanyOverview`, which also counted size, founding and industry,
  /// would now gate a card holding nothing for a company that stated only its
  /// size — so it is gone rather than left as a second, wrong answer.
  bool get hasCompanyDetails =>
      specialties.isNotEmpty || (website?.trim().isNotEmpty ?? false);

  /// Whether the signed-in user follows this person.
  final bool following;

  final int connectionCount;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final List<Experience> experience;
  final List<Education> education;
  final List<Skill> skills;

  /// This profile as a directory [Person] — enough for a header or an avatar
  /// without a second lookup.
  Person get person => Person(
    id: personId,
    name: displayName,
    // The handle travels too: the profile header prints it above the display
    // name, and a Person built without it would fall back to repeating the
    // name it is meant to sit beside.
    username: username,
    firstName: displayName.split(RegExp(r'\s+')).first,
    headline: headline,
    location: location,
    verified: verified,
    subscribed: subscribed,
    // The kind, not the boolean: a Profile knows exactly which of the five it
    // is, and flattening it on the way out is what used to turn a contractor
    // into a company.
    accountType: accountType,
    avatarUrl: avatarUrl,
  );

  Profile copyWith({
    String? about,
    String? industry,
    int? disciplineId,
    String? disciplineName,
    String? disciplineIconUrl,
    int? governorateId,
    String? governorateName,
    String? cvUrl,
    String? displayName,
    String? headline,
    String? location,
    bool? openToWork,
    bool? isPrivate,
    bool? following,
    bool? followRequestPending,
    bool? connected,
    bool? connectionIncoming,
    bool? connectionOutgoing,
    int? followerCount,
    String? avatarUrl,
    String? coverUrl,
    List<Experience>? experience,
    List<Education>? education,
    List<Skill>? skills,
    CompanySize? companySize,
    DateTime? foundedOn,
    bool clearFoundedOn = false,
    List<String>? specialties,
  }) {
    return Profile(
      personId: personId,
      username: username,
      displayName: displayName ?? this.displayName,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      website: website,
      verified: verified,
      subscribed: subscribed,
      accountType: accountType,
      isMe: isMe,
      about: about ?? this.about,
      industry: industry ?? this.industry,
      disciplineId: disciplineId ?? this.disciplineId,
      disciplineName: disciplineName ?? this.disciplineName,
      disciplineIconUrl: disciplineIconUrl ?? this.disciplineIconUrl,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      cvUrl: cvUrl ?? this.cvUrl,
      openToWork: openToWork ?? this.openToWork,
      hiring: hiring,
      isPrivate: isPrivate ?? this.isPrivate,
      following: following ?? this.following,
      followRequestPending: followRequestPending ?? this.followRequestPending,
      connected: connected ?? this.connected,
      connectionIncoming: connectionIncoming ?? this.connectionIncoming,
      connectionOutgoing: connectionOutgoing ?? this.connectionOutgoing,
      connectionCount: connectionCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount,
      postCount: postCount,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      companySize: companySize ?? this.companySize,
      // A null `foundedOn` is ambiguous — "leave it alone" and "clear it"
      // look identical through an optional parameter — so clearing takes its
      // own flag rather than being unreachable.
      foundedOn: clearFoundedOn ? null : (foundedOn ?? this.foundedOn),
      specialties: specialties ?? this.specialties,
    );
  }
}
