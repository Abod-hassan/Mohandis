import 'package:mohandis/features/posts/data/dtos/post_dto.dart';
import 'package:mohandis/features/shared/people/data/dtos/person_dto.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../../domain/entities/panel_entities.dart';

/// Wire models for the engineer panel.
///
/// **Every enum travels BY NAME.** The host registers Newtonsoft's
/// `StringEnumConverter`, and each `…FromWire` below tolerates an ordinal as
/// well — but the Dart enums are declared in the server's order, so an ordinal
/// is only ever a fallback, never the contract.
class InstructorDto {
  const InstructorDto({
    required this.id,
    required this.name,
    this.title,
    this.bio,
    this.avatarUrl,
  });

  factory InstructorDto.fromJson(Map<String, dynamic> json) => InstructorDto(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    title: _text(json['title']),
    bio: _text(json['bio']),
    avatarUrl: _text(json['avatarUrl']),
  );

  final String id;
  final String name;
  final String? title;
  final String? bio;
  final String? avatarUrl;

  Instructor toDomain() => Instructor(
    id: id,
    name: name,
    title: title,
    bio: bio,
    avatarUrl: avatarUrl,
  );
}

/// Null for an absent, empty or whitespace-only string, so the widgets can test
/// one thing instead of three.
String? _text(Object? raw) {
  if (raw == null) return null;
  final value = '$raw'.trim();
  return value.isEmpty ? null : value;
}

/// A JSON array of strings. Type-TESTED rather than cast: a cast throws a
/// TypeError that `apiCall` does not catch, which would take down the whole
/// catalogue read because one field arrived as text instead of a list.
List<String> _lines(Object? raw) => raw is! List
    ? const []
    : raw
          .map((e) => '$e'.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

/// A number off the wire, whichever shape it took. Some decimal converters
/// serialise `numeric` columns as strings, and a rating that decoded as a
/// TypeError would fail every card on the page rather than one figure.
double _number(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw') ?? 0;
}

/// The marketplace block of a course row, lifted out of the flat JSON.
///
/// Built from the top-level fields rather than a nested object, because the
/// server sends them flat on `CourseDto` — the grouping is the app's idea of
/// what belongs together, not the wire's.
CourseCommerce _commerce(Map<String, dynamic> json) {
  final author = json['author'];
  return CourseCommerce(
    price: _number(json['price']),
    currency: _text(json['currency']) ?? 'IQD',
    discountPercent: _number(json['discountPercent']),
    priceAfterDiscount: _number(json['priceAfterDiscount']),
    platformPercent: _number(json['platformPercent']),
    author: author is Map<String, dynamic>
        ? PersonDto.fromJson(author).toDomain()
        : null,
    isMine: json['isMine'] == true,
    reviewStatus: _reviewStatusFromWire(json['reviewStatus']),
    reviewNote: _text(json['reviewNote']),

    // Absent means the old catalogue shape, which was always live. Defaulting
    // this to false instead would hide every existing course behind a
    // "withdrawn" state the server never asked for.
    isPublished: json['isPublished'] != false,
    purchaseStatus: _purchaseStatusFromWire(json['purchaseStatus']),
    purchaseAmountDue: json['purchaseAmountDue'] == null
        ? null
        : _number(json['purchaseAmountDue']),
  );
}

/// By name, with the ordinal tolerated — see the note at the top of this file.
/// An unrecognised value reads as `approved`, matching the server's own zero.
CourseReviewStatus _reviewStatusFromWire(Object? raw) {
  if (raw is num) {
    final i = raw.toInt();
    return i >= 0 && i < CourseReviewStatus.values.length
        ? CourseReviewStatus.values[i]
        : CourseReviewStatus.approved;
  }
  return switch ('$raw'.trim().toLowerCase()) {
    'draft' => CourseReviewStatus.draft,
    'submitted' => CourseReviewStatus.submitted,
    'rejected' => CourseReviewStatus.rejected,
    _ => CourseReviewStatus.approved,
  };
}

String reviewStatusToWire(CourseReviewStatus status) => switch (status) {
  CourseReviewStatus.approved => 'Approved',
  CourseReviewStatus.draft => 'Draft',
  CourseReviewStatus.submitted => 'Submitted',
  CourseReviewStatus.rejected => 'Rejected',
};

/// Null on absence, which is what "this viewer never asked to buy it" is — as
/// opposed to any of the three states, each of which draws something different.
CoursePurchaseStatus? _purchaseStatusFromWire(Object? raw) {
  if (raw == null) return null;
  if (raw is num) {
    final i = raw.toInt();
    return i >= 0 && i < CoursePurchaseStatus.values.length
        ? CoursePurchaseStatus.values[i]
        : null;
  }
  return switch ('$raw'.trim().toLowerCase()) {
    'pending' => CoursePurchaseStatus.pending,
    'paid' => CoursePurchaseStatus.paid,
    'cancelled' => CoursePurchaseStatus.cancelled,
    _ => null,
  };
}

String purchaseStatusToWire(CoursePurchaseStatus status) => switch (status) {
  CoursePurchaseStatus.pending => 'Pending',
  CoursePurchaseStatus.paid => 'Paid',
  CoursePurchaseStatus.cancelled => 'Cancelled',
};

/// A timestamp off the wire, or now.
///
/// A purchase row without a date is not worth failing a whole queue over; the
/// row still says who bought what and for how much, which is what the screen is
/// for.
DateTime _when(Object? raw) =>
    DateTime.tryParse('$raw')?.toLocal() ?? DateTime.now();

DateTime? _whenOrNull(Object? raw) =>
    raw == null ? null : DateTime.tryParse('$raw')?.toLocal();

/// Wire model for the backend's `CoursePurchaseDto`.
class CoursePurchaseDto {
  const CoursePurchaseDto({
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

  factory CoursePurchaseDto.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'];
    final author = json['author'];
    return CoursePurchaseDto(
      id: '${json['id'] ?? ''}',
      courseId: '${json['courseId'] ?? ''}',
      courseTitle: '${json['courseTitle'] ?? ''}',
      coverImageUrl: _text(json['coverImageUrl']),
      buyer: buyer is Map<String, dynamic>
          ? PersonDto.fromJson(buyer).toDomain()
          : null,
      author: author is Map<String, dynamic>
          ? PersonDto.fromJson(author).toDomain()
          : null,
      status: _purchaseStatusFromWire(json['status']) ??
          CoursePurchaseStatus.pending,
      listPrice: _number(json['listPrice']),
      discountPercent: _number(json['discountPercent']),
      amountDue: _number(json['amountDue']),
      platformPercent: _number(json['platformPercent']),
      platformAmount: _number(json['platformAmount']),
      authorAmount: _number(json['authorAmount']),
      currency: _text(json['currency']) ?? 'IQD',
      requestedAt: _when(json['requestedAt']),
      confirmedAt: _whenOrNull(json['confirmedAt']),
      note: _text(json['note']),
    );
  }

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

  CoursePurchase toDomain() => CoursePurchase(
    id: id,
    courseId: courseId,
    courseTitle: courseTitle,
    coverImageUrl: coverImageUrl,
    buyer: buyer,
    author: author,
    status: status,
    listPrice: listPrice,
    discountPercent: discountPercent,
    amountDue: amountDue,
    platformPercent: platformPercent,
    platformAmount: platformAmount,
    authorAmount: authorAmount,
    currency: currency,
    requestedAt: requestedAt,
    confirmedAt: confirmedAt,
    note: note,
  );
}

class CourseDto {
  const CourseDto({
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

  factory CourseDto.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    return CourseDto(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      summary: _text(json['summary']),
      description: _text(json['description']),
      category: categoryFromWire(json['category']),
      level: levelFromWire(json['level']),
      coverImageUrl: _text(json['coverImageUrl']),
      instructor: instructor is Map<String, dynamic>
          ? InstructorDto.fromJson(instructor)
          : null,
      totalLectures: (json['totalLectures'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      isFree: json['isFree'] == true,
      isLocked: json['isLocked'] == true,
      enrolledCount: (json['enrolledCount'] as num?)?.toInt() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      ratingAverage: _number(json['ratingAverage']),
      isEnrolled: json['isEnrolled'] == true,
      currentLecture: (json['currentLecture'] as num?)?.toInt() ?? 0,
      minutesWatched: (json['minutesWatched'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      hasCertificate: json['hasCertificate'] == true,
      myRating: (json['myRating'] as num?)?.toInt() ?? 0,
      outcomes: _lines(json['outcomes']),
      requirements: _lines(json['requirements']),
      commerce: _commerce(json),
      isNew: json['isNew'] == true,
    );
  }

  final String id;
  final String title;
  final String? summary;
  final String? description;
  final CourseCategory category;
  final CourseLevel level;
  final String? coverImageUrl;
  final InstructorDto? instructor;
  final int totalLectures;
  final int durationMinutes;
  final bool isFree;
  final bool isLocked;
  final int enrolledCount;
  final int ratingCount;
  final double ratingAverage;
  final bool isEnrolled;
  final int currentLecture;
  final int minutesWatched;
  final bool isCompleted;
  final bool hasCertificate;
  final int myRating;
  final List<String> outcomes;
  final List<String> requirements;
  final CourseCommerce commerce;
  final bool isNew;

  Course toDomain() => Course(
    id: id,
    title: title,
    summary: summary,
    description: description,
    category: category,
    level: level,
    coverImageUrl: coverImageUrl,
    instructor: instructor?.toDomain(),
    totalLectures: totalLectures,
    durationMinutes: durationMinutes,
    isFree: isFree,
    isLocked: isLocked,
    enrolledCount: enrolledCount,
    ratingCount: ratingCount,
    ratingAverage: ratingAverage,
    isEnrolled: isEnrolled,
    currentLecture: currentLecture,
    minutesWatched: minutesWatched,
    isCompleted: isCompleted,
    hasCertificate: hasCertificate,
    myRating: myRating,
    outcomes: outcomes,
    requirements: requirements,
    commerce: commerce,
    isNew: isNew,
  );

  static CourseCategory categoryFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < CourseCategory.values.length
          ? CourseCategory.values[i]
          : CourseCategory.theory;
    }
    return switch ('$raw'.toLowerCase()) {
      'practical' => CourseCategory.practical,
      'training' => CourseCategory.training,
      _ => CourseCategory.theory,
    };
  }

  static String categoryToWire(CourseCategory c) => switch (c) {
    CourseCategory.theory => 'Theory',
    CourseCategory.practical => 'Practical',
    CourseCategory.training => 'Training',
  };

  static CourseLevel levelFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < CourseLevel.values.length
          ? CourseLevel.values[i]
          : CourseLevel.beginner;
    }
    return switch ('$raw'.toLowerCase()) {
      'intermediate' => CourseLevel.intermediate,
      'advanced' => CourseLevel.advanced,
      _ => CourseLevel.beginner,
    };
  }

  static String levelToWire(CourseLevel l) => switch (l) {
    CourseLevel.beginner => 'Beginner',
    CourseLevel.intermediate => 'Intermediate',
    CourseLevel.advanced => 'Advanced',
  };
}

class LectureDto {
  const LectureDto({
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

  factory LectureDto.fromJson(Map<String, dynamic> json) => LectureDto(
    id: '${json['id'] ?? ''}',
    position: (json['position'] as num?)?.toInt() ?? 0,
    title: '${json['title'] ?? ''}',
    kind: kindFromWire(json['kind']),
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    isPreview: json['isPreview'] == true,
    // Null for a locked lesson, for one with no file yet, AND always for an
    // article — the server sends the same absence for all three, and `isLocked`
    // plus `kind` is what separates them.
    contentUrl: _text(json['contentUrl']),
    articleBody: _text(json['articleBody']),
    isLocked: json['isLocked'] == true,
    isCompleted: json['isCompleted'] == true,
    uploadPending: json['uploadPending'] == true,
  );

  final String id;
  final int position;
  final String title;
  final LessonKind kind;
  final int durationMinutes;
  final bool isPreview;
  final String? contentUrl;
  final String? articleBody;
  final bool isLocked;
  final bool isCompleted;
  final bool uploadPending;

  Lecture toDomain() => Lecture(
    id: id,
    position: position,
    title: title,
    kind: kind,
    durationMinutes: durationMinutes,
    isPreview: isPreview,
    contentUrl: contentUrl,
    articleBody: articleBody,
    isLocked: isLocked,
    isCompleted: isCompleted,
    uploadPending: uploadPending,
  );

  static String kindToWire(LessonKind k) => switch (k) {
    LessonKind.video => 'Video',
    LessonKind.pdf => 'Pdf',
    LessonKind.article => 'Article',
  };

  static LessonKind kindFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < LessonKind.values.length
          ? LessonKind.values[i]
          : LessonKind.video;
    }
    return switch ('$raw'.toLowerCase()) {
      'pdf' => LessonKind.pdf,
      'article' => LessonKind.article,
      _ => LessonKind.video,
    };
  }
}

class NoteDto {
  const NoteDto({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  factory NoteDto.fromJson(Map<String, dynamic> json) => NoteDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: '${json['title'] ?? ''}',
    body: '${json['body'] ?? ''}',
    updatedAt: PostDto.parseDate(json['updatedAt']),
  );

  final int id;
  final String title;
  final String body;
  final DateTime updatedAt;

  Note toDomain() => Note(
    id: '$id',
    title: title,
    body: body,
    updatedAt: updatedAt,
  );
}

class DocumentDto {
  const DocumentDto({
    required this.id,
    required this.title,
    required this.category,
    this.summary,
    this.fileUrl,
    this.isLocked = false,
  });

  factory DocumentDto.fromJson(Map<String, dynamic> json) => DocumentDto(
    id: '${json['id'] ?? ''}',
    title: '${json['title'] ?? ''}',
    summary: _text(json['summary']),
    category: categoryFromWire(json['category']),
    fileUrl: _text(json['fileUrl']),
    isLocked: json['isLocked'] == true,
  );

  final String id;
  final String title;
  final String? summary;
  final DocumentCategory category;
  final String? fileUrl;
  final bool isLocked;

  ReferenceDocument toDomain() => ReferenceDocument(
    id: id,
    title: title,
    summary: summary,
    category: category,
    fileUrl: fileUrl,
    isLocked: isLocked,
  );

  static DocumentCategory categoryFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < DocumentCategory.values.length
          ? DocumentCategory.values[i]
          : DocumentCategory.library;
    }
    return '$raw'.toLowerCase() == 'legalaffairs'
        ? DocumentCategory.legalAffairs
        : DocumentCategory.library;
  }

  static String categoryToWire(DocumentCategory c) =>
      c == DocumentCategory.legalAffairs ? 'LegalAffairs' : 'Library';
}

class LegalRequestDto {
  const LegalRequestDto({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.response,
    this.respondedAt,
  });

  factory LegalRequestDto.fromJson(Map<String, dynamic> json) =>
      LegalRequestDto(
        id: '${json['id'] ?? ''}',
        subject: '${json['subject'] ?? ''}',
        body: '${json['body'] ?? ''}',
        status: statusFromWire(json['status']),
        response: json['response'] as String?,
        respondedAt: json['respondedAt'] == null
            ? null
            : PostDto.parseDate(json['respondedAt']),
        createdAt: PostDto.parseDate(json['createdAt']),
      );

  final String id;
  final String subject;
  final String body;
  final LegalRequestStatus status;
  final String? response;
  final DateTime? respondedAt;
  final DateTime createdAt;

  LegalRequest toDomain() => LegalRequest(
    id: id,
    subject: subject,
    body: body,
    status: status,
    response: response,
    respondedAt: respondedAt,
    createdAt: createdAt,
  );

  /// `LegalRequestStatusEnum` is declared in progression order on both sides,
  /// so the ordinal path is a straight index — bounds-checked so a value added
  /// server-side degrades rather than throwing.
  static LegalRequestStatus statusFromWire(Object? raw) {
    if (raw is num) {
      final i = raw.toInt();
      return i >= 0 && i < LegalRequestStatus.values.length
          ? LegalRequestStatus.values[i]
          : LegalRequestStatus.submitted;
    }
    return switch ('$raw'.toLowerCase()) {
      'inreview' => LegalRequestStatus.inReview,
      'answered' => LegalRequestStatus.answered,
      'closed' => LegalRequestStatus.closed,
      _ => LegalRequestStatus.submitted,
    };
  }
}

class AssistantMessageDto {
  const AssistantMessageDto({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory AssistantMessageDto.fromJson(Map<String, dynamic> json) =>
      AssistantMessageDto(
        id: (json['id'] as num?)?.toInt() ?? 0,
        role: roleFromWire(json['role']),
        text: '${json['text'] ?? ''}',
        createdAt: PostDto.parseDate(json['createdAt']),
      );

  final int id;
  final AssistantRole role;
  final String text;
  final DateTime createdAt;

  AssistantMessage toDomain() => AssistantMessage(
    id: id,
    role: role,
    text: text,
    createdAt: createdAt,
  );

  static AssistantRole roleFromWire(Object? raw) {
    if (raw is num) return raw.toInt() == 1 ? AssistantRole.assistant : AssistantRole.user;
    return '$raw'.toLowerCase() == 'assistant'
        ? AssistantRole.assistant
        : AssistantRole.user;
  }
}

class AssistantConversationDto {
  const AssistantConversationDto({
    required this.id,
    required this.title,
    required this.lastMessageAt,
    this.messages = const [],
  });

  factory AssistantConversationDto.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    return AssistantConversationDto(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      lastMessageAt: PostDto.parseDate(json['lastMessageAt']),
      messages: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (m) => AssistantMessageDto.fromJson(
                    m.cast<String, dynamic>(),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String title;
  final DateTime lastMessageAt;
  final List<AssistantMessageDto> messages;

  AssistantConversation toDomain() => AssistantConversation(
    id: id,
    title: title,
    lastMessageAt: lastMessageAt,
    messages: messages.map((m) => m.toDomain()).toList(growable: false),
  );
}
