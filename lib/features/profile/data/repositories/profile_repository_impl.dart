import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../dtos/profile_dto.dart';

/// Profiles against the RoboByte.SocialMedia module.
///
/// A profile screen is four endpoints, not one: the profile itself plus
/// experience, education and skills. They are issued together and the CV
/// sections degrade to empty on failure — a skills outage should not blank a
/// profile.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Result<Profile, AppException>> byPerson(String personId) async {
    final isMe = personId == ProfileRepository.meSentinel;
    final path = isMe ? EndPoints.profilesMe : EndPoints.profileById(personId);

    final result = await apiCall(
      path,
      () => _api.dio.get<dynamic>(path),
      // Both endpoints answer through the same paged read, so the profile
      // arrives as a one-element list rather than a bare object.
      (envelope) {
        final rows = envelope.list;
        if (rows.isEmpty) {
          throw const NotFoundException('لم يُعثر على هذا الملف الشخصي');
        }
        return ProfileDto.fromJson(rows.first);
      },
    );

    return result.flatMapAsync((dto) async {
      final sections = await _sections(dto.id);
      return Result.success(
        dto.toDomain(
          experience: sections.experience,
          education: sections.education,
          skills: sections.skills,
        ),
      );
    });
  }

  @override
  Future<Result<String, AppException>> idForUsername(String username) {
    // The server lower-cases the filter and matches exactly.
    final handle = username.trim().replaceFirst(RegExp('^@'), '');
    return apiCall(
      EndPoints.profiles,
      () => _api.dio.post<dynamic>(
        EndPoints.profiles,
        data: {'username': handle},
        queryParameters: {'page': 1, 'size': 1},
      ),
      (envelope) {
        final rows = envelope.list;
        if (handle.isEmpty || rows.isEmpty) {
          throw const NotFoundException('لم يُعثر على هذا الملف الشخصي');
        }
        return '${rows.first['id']}';
      },
    );
  }

  /// The three CV lists, in flight together.
  Future<_CvSections> _sections(String profileId) async {
    final experience = _section(
      EndPoints.experience,
      profileId,
      (j) => ExperienceDto.fromJson(j).toDomain(),
    );
    final education = _section(
      EndPoints.education,
      profileId,
      (j) => EducationDto.fromJson(j).toDomain(),
    );
    final skills = _section(
      EndPoints.skills,
      profileId,
      (j) => SkillDto.fromJson(j).toDomain(),
    );

    return _CvSections(
      experience: await experience,
      education: await education,
      skills: await skills,
    );
  }

  /// One CV section. Failures come back as an empty list on purpose: the
  /// profile is still worth showing without its skills.
  Future<List<T>> _section<T>(
    String path,
    String profileId,
    T Function(Map<String, dynamic> json) map,
  ) async {
    final result = await apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {'profileId': profileId},
        queryParameters: {'page': 1, 'size': 100},
      ),
      (envelope) => envelope.list.map(map).toList(growable: false),
    );
    return result.valueOrNull ?? <T>[];
  }

  @override
  Future<Result<Profile, AppException>> toggleFollow(
    String personId, {
    bool? isFollowing,
  }) async {
    var following = isFollowing;
    if (following == null) {
      final current = await byPerson(personId);
      if (current.isFailure) return current;
      following = current.valueOrNull!.following;
    }

    final path = following
        ? EndPoints.profileUnfollow
        : EndPoints.profileFollow;

    // The response is a `FollowStateDto` — `{ isFollowing, pending,
    // followerCount }` — not a profile, so the profile is re-read afterwards
    // rather than patched from a partial payload.
    final acted = await apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        queryParameters: {'targetId': personId},
      ),
      (envelope) => envelope.object,
    );

    return acted.flatMapAsync((_) => byPerson(personId));
  }

  @override
  Future<Result<Profile, AppException>> connect(String personId) =>
      _connectionAction(EndPoints.connectionsConnect, 'targetId', personId);

  @override
  Future<Result<Profile, AppException>> acceptConnection(String personId) =>
      // The parameter is the REQUESTER here, not the target — accepting is
      // answering someone else's request.
      _connectionAction(EndPoints.connectionsAccept, 'requesterId', personId);

  @override
  Future<Result<Profile, AppException>> ignoreConnection(String personId) =>
      _connectionAction(EndPoints.connectionsIgnore, 'requesterId', personId);

  @override
  Future<Result<Profile, AppException>> removeConnection(String personId) =>
      _connectionAction(EndPoints.connectionsRemove, 'targetId', personId);

  /// Runs one connection action and re-reads the profile.
  ///
  /// The endpoints answer a `ConnectionStateDto` — `{ connected, incoming,
  /// outgoing, connectionCount }` — not a profile, so rather than patching a
  /// partial payload into the screen's model the profile is read back. It also
  /// keeps the counts honest, since connecting moves `connectionCount` too.
  Future<Result<Profile, AppException>> _connectionAction(
    String path,
    String parameter,
    String personId,
  ) async {
    final acted = await apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        queryParameters: {parameter: personId},
      ),
      (envelope) => envelope.object,
    );
    return acted.flatMapAsync((_) => byPerson(personId));
  }

  @override
  Future<Result<void, AppException>> acceptFollowRequest(String followerId) =>
      _followerAction(EndPoints.profileAcceptRequest, followerId);

  @override
  Future<Result<void, AppException>> rejectFollowRequest(String followerId) =>
      _followerAction(EndPoints.profileRejectRequest, followerId);

  Future<Result<void, AppException>> _followerAction(
    String path,
    String followerId,
  ) async {
    final result = await apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        queryParameters: {'followerId': followerId},
      ),
      (_) {},
    );
    return result.map<void>((_) {});
  }

  @override
  Future<Result<void, AppException>> block(String personId) =>
      _blockAction(EndPoints.profileBlock, personId);

  @override
  Future<Result<void, AppException>> unblock(String personId) =>
      _blockAction(EndPoints.profileUnblock, personId);

  /// Unlike [_connectionAction] this deliberately does NOT re-read the profile.
  /// A block hides the target from the caller's reads, so the follow-up would
  /// come back empty and report a failure for an action that succeeded.
  Future<Result<void, AppException>> _blockAction(
    String path,
    String personId,
  ) {
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        queryParameters: {'targetId': personId},
      ),
      (_) {},
    );
  }

  @override
  Future<Result<Profile, AppException>> endorseSkill({
    required String personId,
    required int skillId,
  }) async {
    final acted = await apiCall(
      EndPoints.skillsEndorse,
      () => _api.dio.post<dynamic>(
        EndPoints.skillsEndorse,
        queryParameters: {'skillId': skillId},
      ),
      (envelope) => envelope.data,
    );
    return acted.flatMapAsync((_) => byPerson(personId));
  }

  /// The caller's ProfileId, and nothing else.
  ///
  /// `byPerson` would answer the same question, but it costs FOUR requests —
  /// the profile plus its experience, education and skills — and a write needs
  /// one GUID. Registration alone was spending nine requests to stamp a single
  /// column this way.
  Future<Result<String, AppException>> _myProfileId() => apiCall(
    EndPoints.profilesMe,
    () => _api.dio.get<dynamic>(EndPoints.profilesMe),
    (envelope) {
      final rows = envelope.list;
      if (rows.isEmpty) {
        throw const NotFoundException('لم يُعثر على هذا الملف الشخصي');
      }
      return ProfileDto.fromJson(rows.first).id;
    },
  );

  /// Writes the named fields and stops there.
  ///
  /// [updateMe] re-reads the whole profile afterwards because its callers
  /// publish the result; the ones that do not — registration stamping an
  /// account type, say — were paying four requests for an answer they threw
  /// away.
  @override
  Future<Result<void, AppException>> patchMe(Map<String, dynamic> body) async {
    final fields = _writableFields(body);
    if (fields.isEmpty) return const Result.success(null);

    final id = await _myProfileId();
    if (id.isFailure) {
      return Result.failure(id.errorOrNull!);
    }

    final saved = await _write(id.valueOrNull!, fields);
    return saved.map<void>((_) {});
  }

  /// The module exposes no profile-update endpoint — profile rows are written
  /// through the Kernel's generic write engine.
  ///
  /// Two consequences worth knowing: the row id has to be resolved first
  /// (hence the `Me` read), and `GenericWrite` writes exactly the columns it
  /// is given with no module-level validation, so only edited fields are sent
  /// and the column names must match `ProfileModel` — not the DTO.
  ///
  /// Reads the profile back afterwards because callers publish the result.
  /// Use [patchMe] when they do not.
  @override
  Future<Result<Profile, AppException>> updateMe(
    Map<String, dynamic> body,
  ) async {
    final fields = _writableFields(body);
    // Nothing to write: skip straight to the read, rather than resolving an id
    // for a request that is not going to happen.
    if (fields.isEmpty) return byPerson(ProfileRepository.meSentinel);

    final id = await _myProfileId();
    if (id.isFailure) return Result.failure(id.errorOrNull!);

    final saved = await _write(id.valueOrNull!, fields);
    if (saved.isFailure) return Result.failure(saved.errorOrNull!);
    return byPerson(ProfileRepository.meSentinel);
  }

  /// The body's app-side keys translated to `ProfileModel` column names.
  ///
  /// Column names, NOT the DTO's: `GenericWrite` writes exactly what it is
  /// given with no module-level validation, so a wrong name is a silent no-op.
  Map<String, dynamic> _writableFields(Map<String, dynamic> body) {
    return <String, dynamic>{
      if (body.containsKey('name')) 'DisplayName': body['name'],
      if (body.containsKey('headline')) 'Headline': body['headline'],
      if (body.containsKey('industry')) 'Industry': body['industry'],
      // The structured الاختصاص. The client writes the discipline's NAME into
      // Industry alongside it, so search and "people in your field" — which
      // compare industries — keep working without knowing about the table.
      if (body.containsKey('disciplineId')) 'DisciplineId': body['disciplineId'],
      // Same shape as the discipline: the structured المحافظة, with its NAME
      // written into Location beside it.
      if (body.containsKey('governorateId'))
        'GovernorateId': body['governorateId'],
      if (body.containsKey('location')) 'Location': body['location'],
      if (body.containsKey('about')) 'About': body['about'],
      if (body.containsKey('bio')) 'Bio': body['bio'],
      if (body.containsKey('website')) 'Website': body['website'],
      if (body.containsKey('avatarUrl')) 'AvatarUrl': body['avatarUrl'],
      if (body.containsKey('coverUrl')) 'CoverUrl': body['coverUrl'],
      if (body.containsKey('cvUrl')) 'CvUrl': body['cvUrl'],
      if (body.containsKey('openToWork')) 'IsOpenToWork': body['openToWork'],
      if (body.containsKey('isPrivate')) 'IsPrivate': body['isPrivate'],
      if (body['accountType'] is AccountType)
        'AccountType': ProfileDto.accountTypeToWire(
          body['accountType'] as AccountType,
        ),
      // Company fields. Only sent when the caller names them, so an individual
      // saving their headline never writes a company size onto their row.
      if (body['companySize'] is CompanySize)
        'CompanySize': ProfileDto.companySizeToWire(
          body['companySize'] as CompanySize,
        ),
      // Sent as yyyy-MM-dd: the column is a `date`, and a full ISO timestamp
      // would hand it an hour to round off in whatever zone the server runs in.
      if (body.containsKey('foundedOn'))
        'FoundedOn': (body['foundedOn'] as DateTime?)
            ?.toIso8601String()
            .split('T')
            .first,
      // Joined back into the one newline-separated column the server keeps.
      // A caller may pass either the list the entity holds or a raw string
      // straight from a text field.
      if (body.containsKey('specialties'))
        'Specialties': body['specialties'] is List
            ? (body['specialties']! as List).join('\n')
            : body['specialties'],
    };

  }

  /// One `GenericWrite` update against `ProfileModel`.
  Future<Result<dynamic, AppException>> _write(
    String profileId,
    Map<String, dynamic> fields,
  ) {
    return apiCall(
      EndPoints.genericWriteSave,
      () => _api.dio.post<dynamic>(
        EndPoints.genericWriteSave,
        data: [
          {
            // The Kernel README's example uses a fully-qualified type name,
            // but the module's own writes pass the simple one
            // (`nameof(PostModel)`) to the same service, so it resolves. If a
            // Kernel upgrade ever tightens that, this becomes
            // 'RoboByte.SocialMedia.Domain.Entities.Profile.ProfileModel'.
            'model': 'ProfileModel',
            'id': profileId,
            // Sent BY NAME, and WriteTypeEnum is 1-based (Create = 1), so the
            // ordinal for "update" would be 2 — send the name and neither trap
            // applies. Getting this wrong inserts a profile instead of editing
            // one.
            'writeType': 'Update',
            'fields': {'Id': profileId, ...fields},
          },
        ],
      ),
      (envelope) => envelope.data,
    );
  }

  // ── CV sections ──────────────────────────────────────────────────────────

  @override
  Future<Result<Profile, AppException>> saveExperience(Experience entry) {
    return _writeRow(
      model: 'ExperienceModel',
      id: entry.id,
      fields: (profileId) => {
        'ProfileId': profileId,
        'Title': entry.role,
        'CompanyName': entry.company,
        // Nullable column: an empty choice must clear it, not write "".
        'EmploymentType': entry.employmentType,
        'Location': entry.location,
        // StartDate is NOT nullable on the model, so a missing one would be
        // written as the epoch. The editor requires it.
        'StartDate': entry.startDate?.toUtc().toIso8601String(),
        // An ongoing role has no end date, and leaving a stale one behind
        // would render "2022 — 2023" under a "current" badge.
        'EndDate': entry.isCurrent
            ? null
            : entry.endDate?.toUtc().toIso8601String(),
        'IsCurrent': entry.isCurrent,
        'Description': entry.description,
      },
    );
  }

  @override
  Future<Result<Profile, AppException>> deleteExperience(int id) =>
      _deleteRow(model: 'ExperienceModel', id: id);

  @override
  Future<Result<Profile, AppException>> saveEducation(Education entry) {
    return _writeRow(
      model: 'EducationModel',
      id: entry.id,
      fields: (profileId) => {
        'ProfileId': profileId,
        'School': entry.school,
        'Degree': entry.degree,
        'FieldOfStudy': entry.fieldOfStudy,
        'Description': entry.description,
        'StartDate': entry.startDate?.toUtc().toIso8601String(),
        'EndDate': entry.endDate?.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<Result<Profile, AppException>> deleteEducation(int id) =>
      _deleteRow(model: 'EducationModel', id: id);

  @override
  Future<Result<Profile, AppException>> saveSkill({
    required String name,
    int id = 0,
  }) {
    return _writeRow(
      model: 'SkillModel',
      id: id,
      // EndorsementCount is deliberately absent: it is owned by
      // `Skills/Endorse`, and sending it here would reset it to whatever the
      // client happened to be holding.
      fields: (profileId) => {'ProfileId': profileId, 'Name': name.trim()},
    );
  }

  @override
  Future<Result<Profile, AppException>> deleteSkill(int id) =>
      _deleteRow(model: 'SkillModel', id: id);

  /// Creates or updates one CV row through `GenericWrite`.
  ///
  /// [fields] is a callback because every one of these tables is keyed by the
  /// caller's ProfileId, which costs a `Me` read to resolve — done once here
  /// rather than at each call site.
  Future<Result<Profile, AppException>> _writeRow({
    required String model,
    required int id,
    required Map<String, dynamic> Function(String profileId) fields,
  }) async {
    final me = await byPerson(ProfileRepository.meSentinel);
    if (me.isFailure) return me;
    final profileId = me.valueOrNull!.personId;

    final isCreate = id == 0;
    final saved = await apiCall(
      EndPoints.genericWriteSave,
      () => _api.dio.post<dynamic>(
        EndPoints.genericWriteSave,
        data: [
          {
            'model': model,
            if (!isCreate) 'id': id,
            // By name — `WriteTypeEnum` is 1-based, so ordinals are off by one
            // from what anyone would guess.
            'writeType': isCreate ? 'Create' : 'Update',
            'fields': {if (!isCreate) 'Id': id, ...fields(profileId)},
          },
        ],
      ),
      (envelope) => envelope.data,
    );

    return saved.flatMapAsync((_) => byPerson(ProfileRepository.meSentinel));
  }

  /// Removes one CV row.
  ///
  /// `SoftDelete`, not `PermanentDelete`: every read in the module filters on
  /// `IsDeleted`, and the unique indexes are filtered the same way, so a soft
  /// delete disappears from the profile while leaving the row for audit.
  Future<Result<Profile, AppException>> _deleteRow({
    required String model,
    required int id,
  }) async {
    if (id == 0) {
      return const Result.failure(
        ValidationException('لا يمكن حذف عنصر لم يُحفظ بعد'),
      );
    }

    final saved = await apiCall(
      EndPoints.genericWriteSave,
      () => _api.dio.post<dynamic>(
        EndPoints.genericWriteSave,
        data: [
          {
            'model': model,
            'id': id,
            'writeType': 'SoftDelete',
            'fields': {'Id': id},
          },
        ],
      ),
      (envelope) => envelope.data,
    );

    return saved.flatMapAsync((_) => byPerson(ProfileRepository.meSentinel));
  }
}

class _CvSections {
  const _CvSections({
    required this.experience,
    required this.education,
    required this.skills,
  });

  final List<Experience> experience;
  final List<Education> education;
  final List<Skill> skills;
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
