import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../data/repositories/panel_repository_impl.dart';
import '../../domain/entities/panel_entities.dart';
import '../../domain/repositories/panel_repository.dart';
import 'panel_notifiers.dart';

/// The courses this viewer WROTE — "دوراتي".
///
/// Its own provider rather than a filter on [courseListProvider]: that one is
/// keyed by section and only ever holds the published catalogue, while this
/// list is mostly things the catalogue deliberately cannot show — drafts, and
/// courses the reviewer sent back.
class MyCoursesNotifier extends AutoDisposeAsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    final result = await ref.watch(panelRepositoryProvider).myCourses();
    return result.when(
      // Filtered again on `isMine`, which the SERVER computes, even though the
      // request already asked for `mineOnly`. Not belt-and-braces for its own
      // sake: this list is defined as "courses I wrote", and a server that
      // ignores the filter — an older build, a filter field it does not know —
      // otherwise fills the author's own shelf with the whole catalogue, each
      // row offering to edit something somebody else wrote. Failing to an
      // empty list is the honest version of that failure.
      success: (list) => [for (final c in list) if (c.commerce.isMine) c],
      failure: (e) => throw e,
    );
  }

  /// Every author write goes through here, so the one place that has to
  /// remember to refresh the list is this one.
  ///
  /// The whole list is re-read rather than the returned row patched in: a save
  /// can create a course, a submit changes its state, and a lesson write moves
  /// figures the card renders — patching would cover one of those three.
  Future<Result<Course, AppException>> run(
    Future<Result<Course, AppException>> Function(PanelRepository repo) write,
  ) async {
    final result = await write(ref.read(panelRepositoryProvider));
    result.when(
      success: (course) {
        ref.invalidateSelf();
        // The catalogue too: an approval publishes into a section, and a
        // section list already on screen would otherwise not show it.
        ref.invalidate(courseListProvider(course.category));
        ref.invalidate(courseProvider(course.id));
        ref.invalidate(myCourseProvider(course.id));
      },
      failure: (_) {},
    );
    return result;
  }
}

final myCoursesProvider =
    AsyncNotifierProvider.autoDispose<MyCoursesNotifier, List<Course>>(
      MyCoursesNotifier.new,
    );

/// ONE of this viewer's own courses — what the editor opens on.
///
/// NOT [courseProvider]: that one reads the catalogue, which by design cannot
/// see a draft or a course the reviewer sent back — and those are the two the
/// editor exists for.
final myCourseProvider = FutureProvider.autoDispose.family<Course, String>((
  ref,
  id,
) async {
  final result = await ref.watch(panelRepositoryProvider).myCourse(id);
  return result.when(success: (course) => course, failure: (e) => throw e);
});

/// The admin review queue, in one state.
///
/// Keyed by state rather than fixed to `submitted` so the same screen can look
/// at what it has already approved or sent back — the alternative is a decision
/// an administrator cannot review after making it.
final coursesForReviewProvider = FutureProvider.autoDispose
    .family<List<Course>, CourseReviewStatus>((ref, status) async {
      final result = await ref
          .watch(panelRepositoryProvider)
          .coursesForReview(status: status);
      return result.when(success: (list) => list, failure: (e) => throw e);
    });

/// Purchases, for whichever of the three readers asked — see [PurchaseScope].
final coursePurchasesProvider = FutureProvider.autoDispose
    .family<List<CoursePurchase>, PurchaseScope>((ref, scope) async {
      final result = await ref
          .watch(panelRepositoryProvider)
          .purchases(scope: scope);
      return result.when(success: (list) => list, failure: (e) => throw e);
    });

/// The tenant's commission default and subscriber discount.
///
/// NOT autoDispose: the course detail screen reads it to draw a discount badge,
/// and re-fetching two numbers on every card would be a request per course.
final courseCommerceProvider = FutureProvider<CourseCommerceSettings>((
  ref,
) async {
  final result = await ref.watch(panelRepositoryProvider).courseCommerce();
  return result.when(success: (s) => s, failure: (e) => throw e);
});
