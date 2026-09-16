import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../entities/panel_entities.dart';

/// Everything behind the engineer panel's rows.
///
/// One repository rather than five: the areas share no data but they share a
/// surface, they are always wired together, and five files of four methods each
/// would be ceremony rather than separation.
abstract class PanelRepository {
  // ── Courses ──────────────────────────────────────────────────────────────

  /// The catalogue. [category] null means all three sections.
  ///
  /// [id] narrows to one course — the server has no get-one route, and asking
  /// the filter is what keeps the detail screen's viewer-relative fields
  /// identical to the list's rather than scanning a page that may not contain
  /// the row at all.
  Future<Result<List<Course>, AppException>> courses({
    String? id,
    CourseCategory? category,
    CourseLevel? level,
    String search,
    bool enrolledOnly,
    bool freeOnly,
  });

  /// The course's lectures, in order.
  ///
  /// Access is decided server-side: a lecture this caller may not watch comes
  /// back with `isLocked` set and no `videoUrl` at all.
  Future<Result<List<Lecture>, AppException>> lectures(String courseId);

  /// Idempotent — enrolling twice returns the existing row rather than failing.
  Future<Result<Course, AppException>> enroll(String courseId);

  /// Rates a course, or edits this viewer's own rating. Enrolment is required
  /// — the server refuses a rating from somebody who never opened the course,
  /// because the average on a card has to survive being looked at.
  Future<Result<Course, AppException>> rate({
    required String courseId,
    required int stars,
    String? comment,
  });

  /// Records an ABSOLUTE position, not a delta. The server only ever moves both
  /// figures forward, so a retry or a stale screen cannot rewind progress, and
  /// completion plus the certificate are derived there rather than declared
  /// here.
  Future<Result<Course, AppException>> saveProgress({
    required String courseId,
    required int currentLecture,
    required int minutesWatched,
  });

  // ── Notes ────────────────────────────────────────────────────────────────

  Future<Result<List<Note>, AppException>> notes();

  /// Creates when [id] is null, updates otherwise.
  Future<Result<Note, AppException>> saveNote({
    int? id,
    required String title,
    required String body,
  });

  Future<Result<bool, AppException>> deleteNote(int id);

  // ── Reference documents ──────────────────────────────────────────────────

  /// The library and the legal-affairs shelf, told apart by [category].
  Future<Result<List<ReferenceDocument>, AppException>> documents({
    required DocumentCategory category,
    String search,
  });

  // ── Legal requests ───────────────────────────────────────────────────────

  Future<Result<List<LegalRequest>, AppException>> legalRequests();

  Future<Result<LegalRequest, AppException>> submitLegalRequest({
    required String subject,
    required String body,
  });

  // ── Assistant ────────────────────────────────────────────────────────────

  /// Conversations, most recent first. Their `messages` are empty here.
  Future<Result<List<AssistantConversation>, AppException>> conversations();

  Future<Result<AssistantConversation, AppException>> conversation(String id);

  /// Sends a turn and returns the whole conversation, reply included — one
  /// round trip rather than send-then-refetch. A null [conversationId] starts a
  /// new conversation titled from the message.
  ///
  /// **The reply is a server-side placeholder** until a model is wired in.
  Future<Result<AssistantConversation, AppException>> sendToAssistant({
    String? conversationId,
    required String text,
  });
}
