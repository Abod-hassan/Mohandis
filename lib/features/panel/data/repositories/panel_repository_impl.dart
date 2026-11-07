import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_client.dart';
import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/providers.dart';

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

  // ── The course marketplace ───────────────────────────────────────────────

  @override
  Future<Result<List<Course>, AppException>> myCourses({
    CourseReviewStatus? status,
  }) => _courseList({
    'mineOnly': true,
    if (status != null) 'reviewStatus': reviewStatusToWire(status),
  });

  @override
  Future<Result<Course, AppException>> myCourse(String id) async {
    final result = await _courseList({'id': id, 'mineOnly': true});

    return result.when<Result<Course, AppException>>(
      // The server says "not found" for somebody else's course by returning
      // nothing, so an empty page is the refusal, not a missing feature.
      success: (rows) => rows.isEmpty
          ? const Result<Course, AppException>.failure(
              NotFoundException('الدورة غير موجودة'),
            )
          : Result<Course, AppException>.success(rows.first),
      failure: (e) => Result<Course, AppException>.failure(e),
    );
  }

  @override
  Future<Result<List<Course>, AppException>> coursesForReview({
    CourseReviewStatus status = CourseReviewStatus.submitted,
  }) => _courseList({'reviewStatus': reviewStatusToWire(status)});

  /// The catalogue read with a different filter body. Shares the route, because
  /// on the server these are three readers of one list, separated by what the
  /// filter says and what the caller's token allows — not three endpoints.
  Future<Result<List<Course>, AppException>> _courseList(
    Map<String, Object?> filter,
  ) => apiCall(
    EndPoints.courses,
    () => _api.dio.post<dynamic>(
      EndPoints.courses,
      data: filter,
      queryParameters: {'page': 1, 'size': 50},
    ),
    (envelope) => envelope.list
        .map((c) => CourseDto.fromJson(c).toDomain())
        .toList(growable: false),
  );

  @override
  Future<Result<Course, AppException>> saveMyCourse({
    String? id,
    required String title,
    String? summary,
    String? description,
    required CourseCategory category,
    required CourseLevel level,
    String? coverImageUrl,
    required double price,
    List<String> outcomes = const [],
    List<String> requirements = const [],
  }) => apiCall(
    EndPoints.courseSaveMine,
    () => _api.dio.post<dynamic>(
      EndPoints.courseSaveMine,
      data: {
        if (id != null && id.isNotEmpty) 'id': id,
        'title': title.trim(),
        'summary': summary?.trim(),
        'description': description?.trim(),
        'category': CourseDto.categoryToWire(category),
        'level': CourseDto.levelToWire(level),
        'coverImageUrl': coverImageUrl,
        'price': price,
        // Sent whole every time, blanks dropped: the server rewrites both lists
        // from what arrives, so an omitted list would silently clear it.
        'outcomes': [
          for (final line in outcomes)
            if (line.trim().isNotEmpty) line.trim(),
        ],
        'requirements': [
          for (final line in requirements)
            if (line.trim().isNotEmpty) line.trim(),
        ],
      },
    ),
    (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
  );

  @override
  Future<Result<SavedLesson, AppException>> saveLesson({
    required String courseId,
    String? lessonId,
    required String title,
    required LessonKind kind,
    String? contentUrl,
    String? articleBody,
    required int durationMinutes,
    bool isPreview = false,
    int position = 0,
    bool uploadPending = false,
  }) {
    final path = EndPoints.courseLessons(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {
          if (lessonId != null && lessonId.isNotEmpty) 'id': lessonId,
          'title': title.trim(),
          'kind': LectureDto.kindToWire(kind),
          'contentUrl': contentUrl,
          'articleBody': articleBody,
          'durationMinutes': durationMinutes,
          'isPreview': isPreview,
          'position': position,
          'uploadPending': uploadPending,
        },
      ),
      (envelope) {
        final json = envelope.object;
        final course = json['course'];
        return SavedLesson(
          lessonId: '${json['lessonId'] ?? ''}',
          course: CourseDto.fromJson(
            course is Map
                ? course.cast<String, dynamic>()
                : const <String, dynamic>{},
          ).toDomain(),
        );
      },
    );
  }

  @override
  Future<Result<Course, AppException>> deleteLesson({
    required String courseId,
    required String lessonId,
  }) {
    final path = EndPoints.courseLesson(courseId, lessonId);
    return apiCall(
      path,
      () => _api.dio.delete<dynamic>(path),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<Course, AppException>> submitCourse(String courseId) {
    final path = EndPoints.courseSubmit(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<Course, AppException>> approveCourse({
    required String courseId,
    required double platformPercent,
    String? note,
  }) {
    final path = EndPoints.courseApprove(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {'platformPercent': platformPercent, 'note': note?.trim()},
      ),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<Course, AppException>> rejectCourse({
    required String courseId,
    required String note,
  }) {
    final path = EndPoints.courseReject(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, data: {'note': note.trim()}),
      (envelope) => CourseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<CoursePurchase, AppException>> requestPurchase(
    String courseId,
  ) {
    final path = EndPoints.coursePurchase(courseId);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path),
      (envelope) => CoursePurchaseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<List<CoursePurchase>, AppException>> purchases({
    required PurchaseScope scope,
    CoursePurchaseStatus? status,
  }) {
    final path = switch (scope) {
      PurchaseScope.mine => EndPoints.coursePurchasesMine,
      PurchaseScope.earnings => EndPoints.coursePurchaseEarnings,
      PurchaseScope.all => EndPoints.coursePurchases,
    };
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(
        path,
        data: {
          if (status != null) 'status': purchaseStatusToWire(status),
        },
        queryParameters: {'page': 1, 'size': 50},
      ),
      (envelope) => envelope.list
          .map((p) => CoursePurchaseDto.fromJson(p).toDomain())
          .toList(growable: false),
    );
  }

  @override
  Future<Result<CoursePurchase, AppException>> confirmPurchase({
    required String id,
    String? note,
  }) {
    final path = EndPoints.coursePurchaseConfirm(id);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, data: {'note': note?.trim()}),
      (envelope) => CoursePurchaseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<CoursePurchase, AppException>> cancelPurchase({
    required String id,
    String? note,
  }) {
    final path = EndPoints.coursePurchaseCancel(id);
    return apiCall(
      path,
      () => _api.dio.post<dynamic>(path, data: {'note': note?.trim()}),
      (envelope) => CoursePurchaseDto.fromJson(envelope.object).toDomain(),
    );
  }

  @override
  Future<Result<CourseCommerceSettings, AppException>> courseCommerce() =>
      apiCall(
        EndPoints.courseCommerce,
        () => _api.dio.get<dynamic>(EndPoints.courseCommerce),
        (envelope) => _commerceSettings(envelope.object),
      );

  @override
  Future<Result<CourseCommerceSettings, AppException>> saveCourseCommerce({
    required double commissionPercent,
    required double subscriberDiscountPercent,
  }) => apiCall(
    EndPoints.courseCommerce,
    () => _api.dio.put<dynamic>(
      EndPoints.courseCommerce,
      data: {
        'commissionPercent': commissionPercent,
        'subscriberDiscountPercent': subscriberDiscountPercent,
      },
    ),
    (envelope) => _commerceSettings(envelope.object),
  );

  static CourseCommerceSettings _commerceSettings(Map<String, dynamic> json) =>
      CourseCommerceSettings(
        commissionPercent: _percent(json['commissionPercent']),
        subscriberDiscountPercent: _percent(json['subscriberDiscountPercent']),
      );

  /// A `numeric` column, which some decimal converters serialise as a string —
  /// so this parses rather than casts, exactly like the DTOs do.
  static double _percent(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw') ?? 0;
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
