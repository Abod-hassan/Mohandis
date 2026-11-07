import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../entities/panel_entities.dart';

/// Which purchases a read is asking for.
///
/// Three different lists come off one table and they are NOT interchangeable:
/// [mine] is what this viewer bought, [earnings] is what they were owed for
/// courses they wrote, and [all] is the administrator's queue over the whole
/// tenant. Named rather than passed as a pair of nullable ids, so a caller
/// cannot accidentally ask for the third by leaving both blank.
enum PurchaseScope { mine, earnings, all }

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

  // ── The course marketplace ───────────────────────────────────────────────

  /// This viewer's own courses, whatever state they are in — drafts and
  /// rejections included, which is the point of the list.
  Future<Result<List<Course>, AppException>> myCourses({
    CourseReviewStatus? status,
  });

  /// ONE of this viewer's own courses, by id.
  ///
  /// Separate from the catalogue's get-one because the catalogue deliberately
  /// cannot see a draft or a rejection — and those are exactly the courses the
  /// editor is opened on. Reading this one through the catalogue returns an
  /// empty list and the editor reports "not found" for a course the author is
  /// looking at in their own list.
  Future<Result<Course, AppException>> myCourse(String id);

  /// The review queue. Admin only, refused server-side for anybody else.
  Future<Result<List<Course>, AppException>> coursesForReview({
    CourseReviewStatus status = CourseReviewStatus.submitted,
  });

  /// Creates a course when [id] is null, edits it otherwise. The server refuses
  /// an edit to a course that is with the reviewer or already approved.
  Future<Result<Course, AppException>> saveMyCourse({
    String? id,
    required String title,
    String? summary,
    String? description,
    required CourseCategory category,
    required CourseLevel level,
    String? coverImageUrl,
    required double price,
    List<String> outcomes,
    List<String> requirements,
  });

  /// Adds a lesson when [lessonId] is null, edits it otherwise. [position] 0
  /// appends; anything else moves it there and renumbers the rest server-side.
  /// Writes a lesson and answers with its id — see [SavedLesson].
  ///
  /// [uploadPending] saves the row WITHOUT its file, which is otherwise
  /// refused for a video or a PDF. It is how a lesson exists while its video is
  /// still going up: the author sees it in the list straight away, the server
  /// refuses to submit the course for review while it is set, and the write
  /// that finally carries [contentUrl] clears it.
  Future<Result<SavedLesson, AppException>> saveLesson({
    required String courseId,
    String? lessonId,
    required String title,
    required LessonKind kind,
    String? contentUrl,
    String? articleBody,
    required int durationMinutes,
    bool isPreview,
    int position,
    bool uploadPending,
  });

  Future<Result<Course, AppException>> deleteLesson({
    required String courseId,
    required String lessonId,
  });

  /// Hands it to the reviewer. From here the author cannot edit it until a
  /// decision comes back.
  Future<Result<Course, AppException>> submitCourse(String courseId);

  /// Admin only. [platformPercent] is the platform's cut of everything this
  /// course earns, fixed now and copied onto every purchase.
  Future<Result<Course, AppException>> approveCourse({
    required String courseId,
    required double platformPercent,
    String? note,
  });

  /// Admin only. [note] is required — a rejection with no reason is one the
  /// author cannot act on.
  Future<Result<Course, AppException>> rejectCourse({
    required String courseId,
    required String note,
  });

  /// Asks to buy. Creates a pending request; an administrator confirms the
  /// money separately, and only that opens the course.
  Future<Result<CoursePurchase, AppException>> requestPurchase(String courseId);

  /// Purchases, for one of three readers. [scope] picks which.
  Future<Result<List<CoursePurchase>, AppException>> purchases({
    required PurchaseScope scope,
    CoursePurchaseStatus? status,
  });

  /// Admin only. Records that the money arrived, which is what opens the
  /// course for the buyer.
  Future<Result<CoursePurchase, AppException>> confirmPurchase({
    required String id,
    String? note,
  });

  /// Admin only. Turns down a pending request; a confirmed one is refused.
  Future<Result<CoursePurchase, AppException>> cancelPurchase({
    required String id,
    String? note,
  });

  /// The commission default and the subscriber discount. Readable by anyone
  /// signed in — the discount is the subscription's selling point.
  Future<Result<CourseCommerceSettings, AppException>> courseCommerce();

  /// Admin only.
  Future<Result<CourseCommerceSettings, AppException>> saveCourseCommerce({
    required double commissionPercent,
    required double subscriberDiscountPercent,
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
