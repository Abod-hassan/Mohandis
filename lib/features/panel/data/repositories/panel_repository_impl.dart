import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/api_client.dart';
import 'package:flutter_mobile_template/core/api/api_envelope.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/panel_entities.dart';
import '../../domain/repositories/panel_repository.dart';
import '../dtos/panel_dtos.dart';

/// The panel against the SocialMedia module.
///
/// Same three conventions as the rest of the module: list reads are POSTs with
/// a filter body (except the three that genuinely have no filter, which are
/// GETs), every response is a `ResultViewModel` unwrapped by [apiCall], and
/// enums travel by name.
class PanelRepositoryImpl implements PanelRepository {
  PanelRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  // ── Courses ──────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Course>, AppException>> courses({
    String? id,
    CourseCategory? category,
    CourseLevel? level,
    String search = '',
    bool enrolledOnly = false,
    bool freeOnly = false,
  }) {
    final query = search.trim();
    return apiCall(
      EndPoints.courses,
      () => _api.dio.post<dynamic>(
        EndPoints.courses,
        data: {
          if (id != null && id.isNotEmpty) 'id': id,
          // Omitted entirely rather than sent null: there is no "all" member on
          // the server enum, so any value narrows the list.
          if (category != null) 'category': CourseDto.categoryToWire(category),
          if (level != null) 'level': level.name[0].toUpperCase() + level.name.substring(1),
          if (query.isNotEmpty) 'search': query,
          if (enrolledOnly) 'enrolledOnly': true,
          if (freeOnly) 'freeOnly': true,
        },
        queryParameters: {'page': 1, 'size': 50},
      ),
      (envelope) => envelope.list
          .map((c) => CourseDto.fromJson(c).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Lecture>, AppException>> lectures(String courseId) {
    final path = EndPoints.courseLectures(courseId);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(path),
      (envelope) => envelope.list
          .map((l) => LectureDto.fromJson(l).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<Course, AppException>> enroll(String courseId) {
    final path = EndPoints.courseEnroll(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<Course, AppException>> rate({
    required String courseId,
    required int stars,
    String? comment,
  }) {
    final path = EndPoints.courseRate(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {
          'stars': stars,
          if ((comment ?? '').trim().isNotEmpty) 'comment': comment!.trim(),
        },
      ),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<Course, AppException>> saveProgress({
    required String courseId,
    required int currentLecture,
    required int minutesWatched,
  }) {
    final path = EndPoints.courseProgress(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {
          'currentLecture': currentLecture,
          'minutesWatched': minutesWatched,
        },
      ),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  // ── Notes ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Note>, AppException>> notes() {
    return apiCall(
      EndPoints.notes,
      () => _api.dio.get<dynamic>(EndPoints.notes),
      (envelope) => envelope.list
          .map((n) => NoteDto.fromJson(n).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<Note, AppException>> saveNote({
    int? id,
    required String title,
    required String body,
  }) {
    return apiCall(
      EndPoints.notesSave,
      () => _api.dio.post<dynamic>(
        EndPoints.notesSave,
        data: {
          if (id != null && id > 0) 'id': id,
          'title': title.trim(),
          'body': body.trim(),
        },
      ),
      (envelope) => NoteDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<bool, AppException>> deleteNote(int id) {
    final path = EndPoints.noteDelete(id);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path),
      (envelope) => envelope.data == true,
    );
  }

  // ── Reference documents ──────────────────────────────────────────────────

  @override
  Future<Result<List<ReferenceDocument>, AppException>> documents({
    required DocumentCategory category,
    String search = '',
  }) {
    final query = search.trim();
    return apiCall(
      EndPoints.documents,
      () => _api.dio.get<dynamic>(
        EndPoints.documents,
        queryParameters: {
          'category': DocumentDto.categoryToWire(category),
          if (query.isNotEmpty) 'search': query,
        },
      ),
      (envelope) => envelope.list
          .map((d) => DocumentDto.fromJson(d).toDomain())
          .toList(growable: false),
    );
  }

  // ── Legal requests ───────────────────────────────────────────────────────

  @override
  Future<Result<List<LegalRequest>, AppException>> legalRequests() {
    return apiCall(
      EndPoints.legalRequests,
      () => _api.dio.get<dynamic>(EndPoints.legalRequests),
      (envelope) => envelope.list
          .map((r) => LegalRequestDto.fromJson(r).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<LegalRequest, AppException>> submitLegalRequest({
    required String subject,
    required String body,
  }) {
    return apiCall(
      EndPoints.legalRequests,
      () => _api.dio.post<dynamic>(
        EndPoints.legalRequests,
        data: {'subject': subject.trim(), 'body': body.trim()},
      ),
      (envelope) => LegalRequestDto.fromJson(envelope.object).toDomain(),
    );
  }

  // ── Assistant ────────────────────────────────────────────────────────────

  @override
  Future<Result<List<AssistantConversation>, AppException>> conversations() {
    return apiCall(
      EndPoints.assistant,
      () => _api.dio.get<dynamic>(EndPoints.assistant),
      (envelope) => envelope.list
          .map((c) => AssistantConversationDto.fromJson(c).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<AssistantConversation, AppException>> conversation(String id) {
    final path = EndPoints.assistantConversation(id);
    return apiCall(
      path,
      () => _api.dio.get<dynamic>(path),
      (envelope) => AssistantConversationDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<AssistantConversation, AppException>> sendToAssistant({
    String? conversationId,
    required String text,
  }) {
    return apiCall(
      EndPoints.assistantSend,
      () => _api.dio.post<dynamic>(
        EndPoints.assistantSend,
        data: {
          if (conversationId != null && conversationId.isNotEmpty)
            'conversationId': conversationId,
          'text': text.trim(),
        },
      ),
      (envelope) => AssistantConversationDto.fromJson(envelope.object).toDomain(),
    );
  }
}

final panelRepositoryProvider = Provider<PanelRepository>((ref) {
  return PanelRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});
