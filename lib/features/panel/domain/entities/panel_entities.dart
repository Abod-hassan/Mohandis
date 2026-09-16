import 'package:flutter_mobile_template/core/base/base_entity.dart';

/// Which section of the panel a course belongs to — the backend's
/// `CourseCategoryEnum`, in the same order.
enum CourseCategory { theory, practical, training }

/// How hard a course is — the backend's `CourseLevelEnum`.
enum CourseLevel { beginner, intermediate, advanced }

/// What a lesson actually is — the backend's `LessonKindEnum`. Per lesson, so
/// one course can mix a video, a worksheet and a written summary.
enum LessonKind { video, pdf, article }

/// Who teaches a course. Flattened onto it, so a card never needs a second read.
class Instructor extends BaseEntity {
  const Instructor({
    required this.id,
    required this.name,
    this.title,
    this.bio,
    this.avatarUrl,
  });

  @override
  final String id;

  final String name;
  final String? title;
  final String? bio;

  /// Host-less; resolve it through `imageUrlResolverProvider`.
  final String? avatarUrl;

  /// The monogram under the photo, by the same rule `Person` uses — so an
  /// instructor who is also a member does not get two different fallbacks.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
  }
}

/// A course in the catalogue, with the viewer's own progress and lock folded in.
class Course extends BaseEntity {
  const Course({
    required this.id,
    required this.title,
    required this.category,
    this.summary,
    this.description,
    this.level = CourseLevel.beginner,
    this.coverImageUrl,
    this.instructor,
    this.totalLectures = 0,
    this.durationMinutes = 0,
    this.isFree = false,
    this.isLocked = false,
    this.enrolledCount = 0,
    this.ratingCount = 0,
    this.ratingAverage = 0,
    this.isEnrolled = false,
    this.currentLecture = 0,
    this.minutesWatched = 0,
    this.isCompleted = false,
    this.hasCertificate = false,
    this.myRating = 0,
    this.outcomes = const [],
    this.requirements = const [],
  });

  @override
  final String id;

  final String title;
  final String? summary;
  final String? description;
  final CourseCategory category;
  final CourseLevel level;

  /// Host-less. Null means draw the section's placeholder, not a broken image.
  final String? coverImageUrl;

  final Instructor? instructor;

  /// Both derived server-side from the lesson rows, never stored.
  final int totalLectures;
  final int durationMinutes;

  /// Open to everyone, subscription or not.
  final bool isFree;

  /// This viewer has no plan covering it. A locked course is still LISTED —
  /// that is how a catalogue sells — but its lessons arrive without content
  /// and every write against it is refused server-side.
  final bool isLocked;

  final int enrolledCount;
  final int ratingCount;
  final double ratingAverage;

  /// All resolved for the caller server-side, so a list row shows a progress
  /// bar without asking again per card.
  final bool isEnrolled;
  final int currentLecture;
  final int minutesWatched;
  final bool isCompleted;
  final bool hasCertificate;

  /// 1-5, or 0 when this viewer has not rated it.
  final int myRating;

  final List<String> outcomes;
  final List<String> requirements;

  /// 0–1, guarded against a course with no lessons so a malformed row cannot
  /// divide by zero inside a progress bar.
  double get fraction =>
      totalLectures <= 0 ? 0 : (currentLecture / totalLectures).clamp(0, 1);

  bool get hasRating => ratingCount > 0;

  Course copyWith({
    bool? isEnrolled,
    int? currentLecture,
    int? minutesWatched,
    bool? isCompleted,
    int? myRating,
  }) => Course(
    id: id,
    title: title,
    summary: summary,
    description: description,
    category: category,
    level: level,
    coverImageUrl: coverImageUrl,
    instructor: instructor,
    totalLectures: totalLectures,
    durationMinutes: durationMinutes,
    isFree: isFree,
    isLocked: isLocked,
    enrolledCount: enrolledCount,
    ratingCount: ratingCount,
    ratingAverage: ratingAverage,
    isEnrolled: isEnrolled ?? this.isEnrolled,
    currentLecture: currentLecture ?? this.currentLecture,
    minutesWatched: minutesWatched ?? this.minutesWatched,
    isCompleted: isCompleted ?? this.isCompleted,
    hasCertificate: hasCertificate,
    myRating: myRating ?? this.myRating,
    outcomes: outcomes,
    requirements: requirements,
  );
}

/// One lesson of a course — the thing you actually open.
///
/// [contentUrl] and [articleBody] being null covers two different situations
/// the screen draws differently: the lesson is locked and the server withheld
/// it, or nobody has uploaded the file yet. [isLocked] tells them apart — and
/// the lock is enforced by the read, so ignoring it gains nothing to open.
class Lecture extends BaseEntity {
  const Lecture({
    required this.id,
    required this.position,
    required this.title,
    this.kind = LessonKind.video,
    this.durationMinutes = 0,
    this.isPreview = false,
    this.contentUrl,
    this.articleBody,
    this.isLocked = false,
    this.isCompleted = false,
  });

  @override
  final String id;

  /// 1-based, and the same number [Course.currentLecture] counts to.
  final int position;

  final String title;
  final LessonKind kind;
  final int durationMinutes;

  /// Openable without paying, on an otherwise paid course.
  final bool isPreview;

  /// Host-less; resolve it through `imageUrlResolverProvider`. Null for an
  /// article, and for anything withheld or not yet uploaded.
  final String? contentUrl;

  /// The text of an article lesson.
  final String? articleBody;

  final bool isLocked;
  final bool isCompleted;

  /// Openable right now. A lesson with nothing behind it is not locked — it
  /// simply has nothing to show — so the two states need separate copy.
  bool get isOpenable {
    if (isLocked) return false;
    return kind == LessonKind.article
        ? (articleBody ?? '').isNotEmpty
        : (contentUrl ?? '').isNotEmpty;
  }
}

/// A private note.
class Note extends BaseEntity {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  @override
  final String id;

  final String title;
  final String body;
  final DateTime updatedAt;

  /// The int the server keys notes by. [id] is its string form so `BaseEntity`
  /// equality works unchanged.
  int get numericId => int.tryParse(id) ?? 0;
}

/// Which shelf a reference document sits on.
enum DocumentCategory { library, legalAffairs }

/// A reference document — a library entry or a legal-affairs one.
class ReferenceDocument extends BaseEntity {
  const ReferenceDocument({
    required this.id,
    required this.title,
    required this.category,
    this.summary,
    this.fileUrl,
    this.isLocked = false,
  });

  @override
  final String id;

  final String title;
  final String? summary;
  final DocumentCategory category;

  /// Host-less; resolve it before opening. Null for an entry that is a
  /// reference in itself, with no file behind it — and withheld entirely when
  /// [isLocked], because the lock is the server's, not this screen's.
  final String? fileUrl;

  /// No plan this viewer holds covers this shelf. The entry is still listed
  /// with its title and summary; that is what makes the shelf worth paying for.
  final bool isLocked;

  bool get hasFile => (fileUrl ?? '').isNotEmpty;
}

/// A legal request's place in the pipeline. Declared in progression order, so
/// unlike `ApplicationStatus` the index IS the stepper position.
enum LegalRequestStatus {
  submitted,
  inReview,
  answered,
  closed;

  int get stepIndex => index;
  bool get isAnswered =>
      this == LegalRequestStatus.answered || this == LegalRequestStatus.closed;
}

/// A request for legal advice, and its answer once there is one.
class LegalRequest extends BaseEntity {
  const LegalRequest({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.response,
    this.respondedAt,
  });

  @override
  final String id;

  final String subject;
  final String body;
  final LegalRequestStatus status;
  final DateTime createdAt;

  /// Null until someone answers.
  final String? response;
  final DateTime? respondedAt;

  bool get hasResponse => (response ?? '').trim().isNotEmpty;
}

/// Who said it in an assistant conversation.
enum AssistantRole { user, assistant }

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final AssistantRole role;
  final String text;
  final DateTime createdAt;

  bool get isMine => role == AssistantRole.user;
}

/// One conversation with the panel's assistant.
class AssistantConversation extends BaseEntity {
  const AssistantConversation({
    required this.id,
    required this.title,
    required this.lastMessageAt,
    this.messages = const [],
  });

  @override
  final String id;

  final String title;
  final DateTime lastMessageAt;

  /// Empty on the list read, filled on the detail read — one model, two depths.
  final List<AssistantMessage> messages;
}
