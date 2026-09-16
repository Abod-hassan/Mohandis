import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_mock_repository.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../dtos/profile_dto.dart' show ProfileDto, monogramOf;

class ProfileMockRepository implements ProfileRepository {
  ProfileMockRepository({this.latency = const Duration(milliseconds: 240)})
      : _profiles = {for (final p in _seed()) p.personId: p};

  final Duration latency;
  final Map<String, Profile> _profiles;

  Future<void> _wait() => Future<void>.delayed(latency);

  static List<Profile> _seed() => const [
        Profile(
          personId: 'me',
          // The profile screen asks the profile whether it is the caller's —
          // against the real API that flag is resolved server-side from the
          // token, so the mock has to state it too or "me" renders as a
          // stranger with a Follow button.
          isMe: true,
          displayName: 'أنت',
          about:
              'مصمم منتجات أول يركّز على تجارب مالية جديرة بالثقة. أهتم بالواجهات الهادئة والأنظمة '
              'الواضحة والعمل الذي يحترم وقت الناس وانتباههم. متاح حالياً لأدوار تصميم أولى أو قيادية.',
          industry: 'التصميم',
          openToWork: true,
          connectionCount: 842,
          followerCount: 3400,
          followingCount: 512,
          postCount: 96,
          experience: [
            Experience(
              role: 'مصمم منتجات أول',
              company: 'كوبالت المالية',
              monogram: 'ك',
              dates: '٢٠٢٢ — الآن · ٣ سنوات',
              location: 'الرياض، السعودية',
              description:
                  'المصمم الرئيسي لمنتجات التمويل والمدفوعات. بنيت نظام التصميم المستخدم اليوم في '
                  'أكثر من ٤٠ واجهة.',
            ),
            Experience(
              role: 'مصمم منتجات',
              company: 'نورثويند',
              monogram: 'ن',
              dates: '٢٠١٩ — ٢٠٢٢ · ٣ سنوات',
              location: 'جدة، السعودية',
            ),
            Experience(
              role: 'مصمم تجربة مستخدم',
              company: 'برايت لاين',
              monogram: 'ب',
              dates: '٢٠١٧ — ٢٠١٩ · سنتان',
              location: 'عن بُعد',
            ),
          ],
          education: [
            Education(
              school: 'جامعة الملك سعود',
              monogram: 'ج',
              degreeLine: 'بكالوريوس فنون، التصميم الجرافيكي',
              dates: '٢٠١٣ — ٢٠١٧',
            ),
          ],
          skills: [
            Skill(id: 1, name: 'أنظمة التصميم', endorsements: 38),
            Skill(id: 2, name: 'النماذج التفاعلية', endorsements: 27),
            Skill(id: 3, name: 'فيغما', endorsements: 52),
            Skill(id: 4, name: 'بحوث تجربة المستخدم', endorsements: 19),
            Skill(id: 5, name: 'التقنية المالية', endorsements: 14),
            Skill(id: 6, name: 'إمكانية الوصول', endorsements: 11),
          ],
        ),
        Profile(
          personId: 'amal',
          about:
              'مديرة هندسة تبني فرقاً هادئة تعمل بالتزامن المرن. أكتب كثيراً، أُطلق بثبات، وأوظّف '
              'بحثاً عن الفضول لا الشهادات.',
          industry: 'الهندسة',
          hiring: true,
          connectionCount: 1900,
          followerCount: 6200,
          followingCount: 340,
          postCount: 210,
          experience: [
            Experience(
              role: 'مديرة هندسة',
              company: 'نورثويند',
              monogram: 'ن',
              dates: '٢٠٢١ — الآن · ٤ سنوات',
              location: 'جدة، السعودية',
              description:
                  'أقود فريق منصة من ١٢ شخصاً. أعدت تصميم دورة التوظيف فقلّ زمن انتظار المرشحين ٤٠٪.',
            ),
            Experience(
              role: 'مهندسة رئيسية',
              company: 'لوب ورك',
              monogram: 'ل',
              dates: '٢٠١٨ — ٢٠٢١ · ٣ سنوات',
              location: 'عن بُعد',
            ),
          ],
          education: [
            Education(
              school: 'جامعة الملك فهد للبترول والمعادن',
              monogram: 'ف',
              degreeLine: 'ماجستير علوم حاسب',
              dates: '٢٠١٤ — ٢٠١٦',
            ),
          ],
          skills: [
            Skill(id: 7, name: 'قيادة الفرق', endorsements: 61),
            Skill(id: 8, name: 'الأنظمة الموزّعة', endorsements: 44),
            Skill(id: 9, name: 'التوظيف', endorsements: 33),
            Skill(id: 10, name: 'لغة Go', endorsements: 28),
          ],
        ),
      ];

  /// People without a hand-written profile still need a full screen, so a
  /// plausible record is derived from their directory entry.
  Profile _fallback(String personId) {
    final matches = PeopleMockRepository.seed.where((p) => p.id == personId);
    final headline = matches.isEmpty ? '' : matches.first.headline;
    final location = matches.isEmpty ? '' : matches.first.location;
    return Profile(
      personId: personId,
      about: '$headline. شغوف بالعمل الجيد مع أشخاص مميزين.',
      connectionCount: 428,
      followerCount: 1100,
      followingCount: 263,
      postCount: 37,
      experience: [
        Experience(
          role: headline.split(' · ').first,
          company: '—',
          monogram: '؟',
          dates: '٢٠٢٠ — الآن',
          location: location,
        ),
      ],
      education: const [
        Education(
          school: 'الجامعة الوطنية',
          monogram: 'ج',
          degreeLine: 'بكالوريوس',
          dates: '٢٠١٢ — ٢٠١٦',
        ),
      ],
      skills: const [
        Skill(id: 11, name: 'التواصل', endorsements: 12),
        Skill(id: 12, name: 'القيادة', endorsements: 8),
      ],
    );
  }

  @override
  Future<Result<Profile, AppException>> byPerson(String personId) async {
    await _wait();
    final known = PeopleMockRepository.seed.any((p) => p.id == personId);
    if (!known) {
      return Result.failure(NotFoundException('لا يوجد ملف بالمعرف $personId'));
    }
    return Result.success(
      _profiles.putIfAbsent(personId, () => _fallback(personId)),
    );
  }

  @override
  Future<Result<Profile, AppException>> updateMe(
    Map<String, dynamic> body,
  ) async {
    await _wait();
    final current = _profiles['me']!;
    // `specialties` arrives either as the entity's list or as the raw text the
    // edit field holds — the real repository joins both into one column, so
    // the mock has to accept both to behave the same.
    final rawSpecialties = body['specialties'];
    final next = current.copyWith(
      about: body['about'] as String?,
      industry: body['industry'] as String?,
      openToWork: body['openToWork'] as bool?,
      isPrivate: body['isPrivate'] as bool?,
      avatarUrl: body['avatarUrl'] as String?,
      coverUrl: body['coverUrl'] as String?,
      companySize: body['companySize'] as CompanySize?,
      foundedOn: body['foundedOn'] as DateTime?,
      clearFoundedOn:
          body.containsKey('foundedOn') && body['foundedOn'] == null,
      specialties: rawSpecialties == null
          ? null
          : (rawSpecialties is List
                ? rawSpecialties.cast<String>()
                : ProfileDto.specialtiesFrom('$rawSpecialties')),
    );
    _profiles['me'] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> toggleFollow(
    String personId, {
    bool? isFollowing,
  }) async {
    await _wait();
    final current = _profiles[personId] ?? _fallback(personId);
    final next = current.copyWith(following: !current.following);
    _profiles[personId] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> connect(String personId) =>
      _connectionState(personId, outgoing: true);

  @override
  Future<Result<Profile, AppException>> acceptConnection(String personId) =>
      _connectionState(personId, connected: true);

  @override
  Future<Result<Profile, AppException>> ignoreConnection(String personId) =>
      _connectionState(personId);

  @override
  Future<Result<Profile, AppException>> removeConnection(String personId) =>
      _connectionState(personId);

  Future<Result<Profile, AppException>> _connectionState(
    String personId, {
    bool connected = false,
    bool outgoing = false,
  }) async {
    await _wait();
    final current = _profiles[personId] ?? _fallback(personId);
    final next = current.copyWith(
      connected: connected,
      connectionOutgoing: outgoing,
      connectionIncoming: false,
    );
    _profiles[personId] = next;
    return Result.success(next);
  }

  /// The mock keeps no block list — nothing here reads one — so both of these
  /// succeed and change nothing. That is the honest mock: a fixture backend
  /// cannot demonstrate a block, and pretending to would hide the profile the
  /// rest of the fixtures still hand out.
  @override
  Future<Result<void, AppException>> block(String personId) async {
    await _wait();
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppException>> unblock(String personId) async {
    await _wait();
    return const Result.success(null);
  }

  @override
  Future<Result<Profile, AppException>> endorseSkill({
    required String personId,
    required int skillId,
  }) async {
    await _wait();
    final current = _profiles[personId] ?? _fallback(personId);
    final next = current.copyWith(
      skills: [
        for (final s in current.skills)
          if (s.id == skillId)
            s.copyWith(endorsements: s.endorsements + 1)
          else
            s,
      ],
    );
    _profiles[personId] = next;
    return Result.success(next);
  }

  // ── CV sections ──────────────────────────────────────────────────────────
  //
  // All of these edit the signed-in profile, which is the only one the real
  // repository can write either. Ids are handed out from a counter so a
  // freshly added row is addressable for a later edit or delete.

  int _nextRowId = 1000;

  @override
  Future<Result<Profile, AppException>> saveExperience(Experience entry) async {
    await _wait();
    final current = _profiles['me']!;
    final saved = entry.id == 0
        ? Experience(
            id: _nextRowId++,
            role: entry.role,
            company: entry.company,
            monogram: monogramOf(entry.company),
            dates: formatDateRangeArabic(
              entry.startDate,
              entry.endDate,
              entry.isCurrent,
            ),
            location: entry.location,
            description: entry.description,
            employmentType: entry.employmentType,
            startDate: entry.startDate,
            endDate: entry.endDate,
            isCurrent: entry.isCurrent,
          )
        : entry;
    final next = current.copyWith(
      experience: entry.id == 0
          ? [...current.experience, saved]
          : [
              for (final e in current.experience)
                if (e.id == entry.id) saved else e,
            ],
    );
    _profiles['me'] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> deleteExperience(int id) async {
    await _wait();
    final current = _profiles['me']!;
    final next = current.copyWith(
      experience: [
        for (final e in current.experience)
          if (e.id != id) e,
      ],
    );
    _profiles['me'] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> saveEducation(Education entry) async {
    await _wait();
    final current = _profiles['me']!;
    final saved = entry.id == 0
        ? Education(
            id: _nextRowId++,
            school: entry.school,
            monogram: monogramOf(entry.school),
            degreeLine: [
              if (entry.degree.isNotEmpty) entry.degree,
              if (entry.fieldOfStudy.isNotEmpty) entry.fieldOfStudy,
            ].join(' · '),
            dates: formatDateRangeArabic(entry.startDate, entry.endDate, false),
            degree: entry.degree,
            fieldOfStudy: entry.fieldOfStudy,
            description: entry.description,
            startDate: entry.startDate,
            endDate: entry.endDate,
          )
        : entry;
    final next = current.copyWith(
      education: entry.id == 0
          ? [...current.education, saved]
          : [
              for (final e in current.education)
                if (e.id == entry.id) saved else e,
            ],
    );
    _profiles['me'] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> deleteEducation(int id) async {
    await _wait();
    final current = _profiles['me']!;
    final next = current.copyWith(
      education: [
        for (final e in current.education)
          if (e.id != id) e,
      ],
    );
    _profiles['me'] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> saveSkill({
    required String name,
    int id = 0,
  }) async {
    await _wait();
    final current = _profiles['me']!;
    final next = current.copyWith(
      skills: id == 0
          ? [...current.skills, Skill(id: _nextRowId++, name: name.trim(), endorsements: 0)]
          : [
              for (final s in current.skills)
                if (s.id == id)
                  Skill(
                    id: s.id,
                    name: name.trim(),
                    endorsements: s.endorsements,
                    endorsedByMe: s.endorsedByMe,
                  )
                else
                  s,
            ],
    );
    _profiles['me'] = next;
    return Result.success(next);
  }

  @override
  Future<Result<Profile, AppException>> deleteSkill(int id) async {
    await _wait();
    final current = _profiles['me']!;
    final next = current.copyWith(
      skills: [
        for (final s in current.skills)
          if (s.id != id) s,
      ],
    );
    _profiles['me'] = next;
    return Result.success(next);
  }
}
