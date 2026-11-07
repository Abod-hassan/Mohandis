import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/dashboard/presentation/notifiers/dashboard_notifier.dart';

import '../../data/repositories/panel_repository_impl.dart';
import '../../domain/entities/panel_entities.dart';

/// Courses in one section of the panel.
///
/// autoDispose and keyed by category: three sections would otherwise hold three
/// lists for the whole session, and every one of them carries the viewer's own
/// progress — which goes stale the moment they watch anything.
class CourseListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Course>, CourseCategory> {
  @override
  Future<List<Course>> build(CourseCategory category) async {
    final result = await ref
        .watch(panelRepositoryProvider)
        .courses(category: category);
    return result.when(success: (list) => list, failure: (e) => throw e);
  }

  Future<Result<Course, AppException>> enroll(String courseId) async {
    // This provider is autoDispose: popping the screen mid-request tears the
    // notifier down, and writing `state` afterwards throws a StateError that
    // escapes into the caller's `result.when`.
    var alive = true;
    ref.onDispose(() => alive = false);

    final result = await ref.read(panelRepositoryProvider).enroll(courseId);
    if (!alive) return result;
    result.when(success: _replace, failure: (_) {});
    return result;
  }

  /// Replaces one row with the server's copy.
  ///
  /// The server is the authority on progress — it clamps both figures forward
  /// and derives completion — so the list takes what came back rather than
  /// patching optimistically and then disagreeing.
  void _replace(Course updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final c in current)
        if (c.id == updated.id) updated else c,
    ]);
  }
}

final courseListProvider =
    AsyncNotifierProvider.autoDispose
        .family<CourseListNotifier, List<Course>, CourseCategory>(
          CourseListNotifier.new,
        );

/// One course, for the detail screen.
final courseProvider = FutureProvider.autoDispose.family<Course, String>((
  ref,
  id,
) async {
  // There is no get-one route, so the filter is asked for exactly this id —
  // the same read the list uses, which keeps the viewer-relative fields
  // identical between a card and the screen it opens. Scanning an unfiltered
  // page instead would miss any course past the first 50.
  final result = await ref.watch(panelRepositoryProvider).courses(id: id);
  final list = result.when(success: (l) => l, failure: (e) => throw e);
  if (list.isEmpty) {
    throw const NotFoundException('لم يتم العثور على الدورة');
  }
  return list.first;
});

/// The lectures of one course.
///
/// Separate from [courseProvider] rather than folded into it: the catalogue read
/// returns a page of courses and would carry every syllabus with it, and the
/// unlock state moves on every progress write while the course row does not.
final courseLecturesProvider = FutureProvider.autoDispose
    .family<List<Lecture>, String>((ref, courseId) async {
      final result = await ref.watch(panelRepositoryProvider).lectures(courseId);
      return result.when(success: (list) => list, failure: (e) => throw e);
    });

/// Progress writes, kept out of the list notifier so the detail screen can call
/// them without owning a list.
class CourseProgressController {
  const CourseProgressController(this.ref);

  final Ref ref;

  /// Rates a course. Invalidates the same reads a progress write does, minus the
  /// syllabus — a rating moves the card's average and this viewer's own star
  /// row, and nothing about which lessons are open.
  Future<Result<Course, AppException>> rate({
    required String courseId,
    required int stars,
    String? comment,
  }) async {
    final result = await ref
        .read(panelRepositoryProvider)
        .rate(courseId: courseId, stars: stars, comment: comment);
    result.when(
      success: (course) {
        ref.invalidate(courseProvider(courseId));
        ref.invalidate(courseListProvider(course.category));
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Course, AppException>> save({
    required String courseId,
    required int currentLecture,
    required int minutesWatched,
  }) async {
    final result = await ref
        .read(panelRepositoryProvider)
        .saveProgress(
          courseId: courseId,
          currentLecture: currentLecture,
          minutesWatched: minutesWatched,
        );
    result.when(
      success: (course) {
        // The dashboard's continue-learning card, hours and certificate count
        // all read from this — so finishing a lecture has to move the panel
        // behind you, not just this screen.
        ref.invalidate(courseProvider(courseId));
        // The next lecture just unlocked, so the list the screen is showing is
        // already wrong — the lock is decided server-side and cannot be patched
        // in place from here.
        ref.invalidate(courseLecturesProvider(courseId));
        ref.invalidate(courseListProvider(course.category));
        ref.invalidate(dashboardNotifierProvider);
      },
      failure: (_) {},
    );
    return result;
  }
}

final courseProgressControllerProvider = Provider<CourseProgressController>(
  CourseProgressController.new,
);

/// The engineer's own notes.
class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final result = await ref.watch(panelRepositoryProvider).notes();
    return result.when(success: (list) => list, failure: (e) => throw e);
  }

  Future<Result<Note, AppException>> save({
    int? id,
    required String title,
    required String body,
  }) async {
    final result = await ref
        .read(panelRepositoryProvider)
        .saveNote(id: id, title: title, body: body);
    // Re-read rather than splice: the list is ordered by modified date, so a
    // save reorders it and an in-place patch would leave it wrong.
    result.when(success: (_) => ref.invalidateSelf(), failure: (_) {});
    return result;
  }

  Future<Result<bool, AppException>> delete(int id) async {
    final previous = state.valueOrNull;
    // Optimistic: the row leaves immediately and comes back if the server
    // refuses. A delete that pauses on a spinner reads as a broken tap.
    if (previous != null) {
      state = AsyncValue.data([
        for (final n in previous)
          if (n.numericId != id) n,
      ]);
    }
    final result = await ref.read(panelRepositoryProvider).deleteNote(id);
    result.when(
      success: (_) {},
      failure: (_) {
        if (previous != null) state = AsyncValue.data(previous);
      },
    );
    return result;
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

/// Reference documents for one shelf.
final documentsProvider = FutureProvider.autoDispose
    .family<List<ReferenceDocument>, DocumentCategory>((ref, category) async {
      final result = await ref
          .watch(panelRepositoryProvider)
          .documents(category: category);
      return result.when(success: (list) => list, failure: (e) => throw e);
    });

/// The engineer's legal requests.
class LegalRequestsNotifier extends AsyncNotifier<List<LegalRequest>> {
  @override
  Future<List<LegalRequest>> build() async {
    final result = await ref.watch(panelRepositoryProvider).legalRequests();
    return result.when(success: (list) => list, failure: (e) => throw e);
  }

  Future<Result<LegalRequest, AppException>> submit({
    required String subject,
    required String body,
  }) async {
    final result = await ref
        .read(panelRepositoryProvider)
        .submitLegalRequest(subject: subject, body: body);
    result.when(
      success: (request) {
        final current = state.valueOrNull;
        // Newest first, so the new request goes on the front — no refetch for
        // a row the server just handed back in full.
        state = AsyncValue.data([request, ...?current]);
      },
      failure: (_) {},
    );
    return result;
  }
}

final legalRequestsProvider =
    AsyncNotifierProvider<LegalRequestsNotifier, List<LegalRequest>>(
      LegalRequestsNotifier.new,
    );

/// Assistant conversations, most recent first.
final assistantConversationsProvider =
    FutureProvider<List<AssistantConversation>>((ref) async {
      final result = await ref.watch(panelRepositoryProvider).conversations();
      return result.when(success: (list) => list, failure: (e) => throw e);
    });

/// One conversation and its transcript.
///
/// The family argument is the conversation id, or an empty string for a
/// conversation that has not been created yet — the first send is what creates
/// it, so the screen opens on an empty transcript rather than on a request.
class AssistantChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<AssistantConversation?, String> {
  @override
  Future<AssistantConversation?> build(String conversationId) async {
    if (conversationId.isEmpty) return null;
    final result = await ref
        .watch(panelRepositoryProvider)
        .conversation(conversationId);
    return result.when(success: (c) => c, failure: (e) => throw e);
  }

  Future<Result<AssistantConversation, AppException>> send(String text) async {
    // autoDispose, and the chat screen is its only listener — leaving mid-send
    // disposes this notifier, and both the `state` write and the invalidate
    // below would throw into the screen's own error handling.
    var alive = true;
    ref.onDispose(() => alive = false);

    final existing = state.valueOrNull;
    final result = await ref
        .read(panelRepositoryProvider)
        .sendToAssistant(conversationId: existing?.id, text: text);
    if (!alive) return result;

    result.when(
      success: (conversation) {
        // The response carries the whole transcript, reply included, so there
        // is nothing to merge.
        state = AsyncValue.data(conversation);
        ref.invalidate(assistantConversationsProvider);
      },
      failure: (_) {},
    );
    return result;
  }
}

final assistantChatProvider =
    AsyncNotifierProvider.autoDispose
        .family<AssistantChatNotifier, AssistantConversation?, String>(
          AssistantChatNotifier.new,
        );
