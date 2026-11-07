import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

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
/// Where a course stands with the reviewer.
///
/// Declared in the SERVER's order, which puts `approved` at 0 on purpose: every
/// course written before authoring existed was an administrator's and was live,
/// so the un-migrated value has to be the harmless one.
enum CourseReviewStatus { approved, draft, submitted, rejected }

/// Where one person's purchase of one course stands. There is no payment
/// gateway — an administrator confirms that money arrived, and only `paid`
/// opens the course.
enum CoursePurchaseStatus { pending, paid, cancelled }

/// The marketplace side of a course: who wrote it, what it costs this viewer,
/// and where it stands with the reviewer.
///
/// A value object hanging off [Course] rather than a dozen more fields on it:
/// most of the app only ever reads a course's title, cover and progress, and
/// these travel together or not at all. A course an administrator wrote has
/// [author] null and the default of everything else, which is exactly the
/// catalogue as it behaved before any of this existed.
class CourseCommerce {
  const CourseCommerce({
    this.price = 0,
    this.currency = 'IQD',
    this.discountPercent = 0,
    this.priceAfterDiscount = 0,
    this.platformPercent = 0,
    this.author,
    this.isMine = false,
    this.reviewStatus = CourseReviewStatus.approved,
    this.reviewNote,
    this.isPublished = true,
    this.purchaseStatus,
    this.purchaseAmountDue,
  });

  /// What the author charges. 0 means the course is not sold at all — it is
  /// then free, or covered by a plan, like the rest of the catalogue.
  final double price;

  final String currency;

  /// The subscriber discount THIS viewer gets, already resolved by the server.
  /// Never computed on the client: the figure on the screen has to be the one
  /// the purchase is recorded at.
  final double discountPercent;

  final double priceAfterDiscount;

  /// The platform's agreed cut. Only sent to the author and to an
  /// administrator; 0 to everybody else.
  final double platformPercent;

  /// Who wrote it. Null for a course the tenant's own administrators authored.
  final Person? author;

  /// This viewer wrote it — what puts the edit and submit controls on screen.
  final bool isMine;

  final CourseReviewStatus reviewStatus;

  /// Why it was sent back, in the reviewer's words. Only ever populated for the
  /// author and for an administrator.
  final String? reviewNote;

  final bool isPublished;

  /// Where this viewer's purchase stands, or null if they never asked for one.
  final CoursePurchaseStatus? purchaseStatus;

  /// What this viewer's live purchase was STAMPED at — not [priceAfterDiscount],
  /// which is recomputed on every read. Once a request exists this is the
  /// figure to show, or a lapsed subscription between requesting and confirming
  /// leaves the screen quoting one number while the money owed is another.
  final double? purchaseAmountDue;

  bool get isSold => price > 0;

  bool get hasDiscount => discountPercent > 0 && priceAfterDiscount < price;

  bool get isPaid => purchaseStatus == CoursePurchaseStatus.paid;

  bool get isAwaitingPayment => purchaseStatus == CoursePurchaseStatus.pending;

  /// Whether the author may still change it. Mirrors the server's own rule, so
  /// the screen hides controls the server would refuse rather than offering
  /// them and reporting an error afterwards.
  bool get isEditable =>
      isMine &&
      (reviewStatus == CourseReviewStatus.draft ||
          reviewStatus == CourseReviewStatus.rejected);
}

/// One purchase, as the admin queue, the buyer's list and the author's earnings
/// all render it.
///
/// Every figure is the one the server stamped when the request was made, not a
/// recomputation from the course — a price the author raises later must not
/// rewrite what somebody already paid.
class CoursePurchase extends BaseEntity {
  const CoursePurchase({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.status,
    required this.requestedAt,
    this.coverImageUrl,
    this.buyer,
    this.author,
    this.listPrice = 0,
    this.discountPercent = 0,
    this.amountDue = 0,
    this.platformPercent = 0,
    this.platformAmount = 0,
    this.authorAmount = 0,
    this.currency = 'IQD',
    this.confirmedAt,
    this.note,
  });

  @override
  final String id;

  final String courseId;
  final String courseTitle;
  final String? coverImageUrl;
  final Person? buyer;
  final Person? author;
  final CoursePurchaseStatus status;
  final double listPrice;
  final double discountPercent;
  final double amountDue;
  final double platformPercent;
  final double platformAmount;
  final double authorAmount;
  final String currency;
  final DateTime requestedAt;
  final DateTime? confirmedAt;
  final String? note;
}

/// The two tenant-wide numbers behind the marketplace: what the review screen
/// pre-fills as a commission, and what a subscriber comes off every price.
class CourseCommerceSettings {
  const CourseCommerceSettings({
    this.commissionPercent = 0,
    this.subscriberDiscountPercent = 0,
  });

  final double commissionPercent;
  final double subscriberDiscountPercent;
}

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
    this.commerce = const CourseCommerce(),
    this.isNew = false,
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

  /// Who wrote it, what it costs this viewer, and where it stands with the
  /// reviewer. Defaults to the administrator-authored catalogue's shape.
  final CourseCommerce commerce;

  /// Recent, and not one this viewer has opened — the server's answer, not the
  /// client's. The panel's "جديد" badge counts exactly these, so working it out
  /// here from [createdAt] would let a card and the badge above it disagree.
  final bool isNew;

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
    commerce: commerce,
    isNew: isNew,
  );
}

/// What a lesson write answers with: the lesson's own id, and the course.
///
/// **The id is why this type exists.** A client that saves a lesson before its
/// video has uploaded has to come back and write the URL to THAT lesson, and
/// the course projection carries no lessons, so there was nothing in the old
/// answer — a bare [Course] — that said which row had just been created.
/// Matching afterwards by title or position is ambiguous the moment two
/// lessons share either.
class SavedLesson {
  const SavedLesson({required this.lessonId, required this.course});

  final String lessonId;

  /// The course as it now stands, lesson count and total length included.
  final Course course;
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
    this.uploadPending = false,
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

  /// Its file is being uploaded right now, or an attempt stopped before it
  /// landed.
  ///
  /// The row is saved BEFORE the transfer so the author's own lesson list shows
  /// the lesson the moment they add it rather than a minute later — see
  /// `LectureModel.UploadPending` on the server. Only ever true on the author's
  /// own read: a course cannot be submitted for review while one of these is in
  /// it, so nothing a learner can open ever carries it.
  final bool uploadPending;

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
