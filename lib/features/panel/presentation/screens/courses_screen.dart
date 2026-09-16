import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/panel_notifiers.dart';
import '../widgets/course_bits.dart';

/// Labels for the three panel sections, so the list and its heading always
/// agree with the dashboard row that opened them.
extension CourseCategoryLabel on CourseCategory {
  String label(BuildContext context) => switch (this) {
    CourseCategory.theory => context.l10n.dashboardTheory,
    CourseCategory.practical => context.l10n.dashboardPractical,
    CourseCategory.training => context.l10n.dashboardTraining,
  };

  /// The wire name, used as the route segment so a deep link is readable.
  String get slug => switch (this) {
    CourseCategory.theory => 'theory',
    CourseCategory.practical => 'practical',
    CourseCategory.training => 'training',
  };

  static CourseCategory fromSlug(String slug) => switch (slug) {
    'practical' => CourseCategory.practical,
    'training' => CourseCategory.training,
    _ => CourseCategory.theory,
  };
}

/// One section of the catalogue.
///
/// Every published course is listed, locked ones included: filtering the list
/// down to what somebody has already paid for would leave a non-subscriber
/// staring at an empty screen with no reason to subscribe. A locked card wears
/// a padlock and opens a page that explains what a plan costs.
class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key, required this.category});

  final CourseCategory category;

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  bool _freeOnly = false;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final courses = ref.watch(courseListProvider(widget.category));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: widget.category.label(context)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RungSpace.gutter,
              10,
              RungSpace.gutter,
              4,
            ),
            child: Row(
              children: [
                RungFilterChip(
                  label: l10n.coursesFilterAll,
                  selected: !_freeOnly,
                  onTap: () => setState(() => _freeOnly = false),
                ),
                const SizedBox(width: 8),
                RungFilterChip(
                  label: l10n.coursesFilterFree,
                  selected: _freeOnly,
                  onTap: () => setState(() => _freeOnly = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: courses.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(courseListProvider(widget.category)),
              ),
              data: (list) {
                // Filtered here rather than re-asked of the server: the section
                // is one page, and a round trip to hide a handful of cards
                // would blank the list on every chip tap.
                final shown = _freeOnly
                    ? list.where((course) => course.isFree).toList()
                    : list;

                if (shown.isEmpty) {
                  return EmptyView(
                    icon: Icons.school_outlined,
                    title: l10n.coursesEmpty,
                    message: l10n.coursesEmptyHint,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    RungSpace.gutter,
                    6,
                    RungSpace.gutter,
                    28,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _CourseCard(course: shown[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final instructor = course.instructor;

    return RungCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      radius: RungRadius.md + 2,
      onTap: () => context.push('/panel/course/${course.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CourseCover(
                course: course,
                radius: RungRadius.md + 2,
                topOnly: true,
              ),
              PositionedDirectional(
                top: 8,
                start: 8,
                child: CoursePriceBadge(course: course),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((course.summary ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: c.ink3,
                    ),
                  ),
                ],
                if (instructor != null) ...[
                  const SizedBox(height: 9),
                  _InstructorLine(instructor: instructor, compact: true),
                ],
                const SizedBox(height: 9),
                Text(
                  courseMeta(context, course),
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    CourseRating(course: course, compact: true),
                    const Spacer(),
                    Text(
                      context.l10n.courseEnrolledCount(
                        ArabicNumbers.compact(course.enrolledCount),
                      ),
                      style: TextStyle(fontSize: 11.5, color: c.ink3),
                    ),
                  ],
                ),
                if (course.isEnrolled) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: course.fraction,
                      minHeight: 5,
                      backgroundColor: c.surface3,
                      color: course.isCompleted ? c.green : c.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The byline. Shared between the card and the course page so a renamed
/// instructor cannot read two ways on two screens.
class _InstructorLine extends ConsumerWidget {
  const _InstructorLine({required this.instructor, this.compact = false});

  final Instructor instructor;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final resolved = ref.watch(imageUrlResolverProvider)(instructor.avatarUrl);
    final size = compact ? 22.0 : 44.0;

    return Row(
      children: [
        RungAvatar(
          seed: instructor.id,
          initials: instructor.initials,
          size: size,
          imageUrl: resolved,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instructor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 14.5,
                  fontWeight: FontWeight.w700,
                  color: compact ? c.ink2 : c.ink,
                ),
              ),
              if (!compact && (instructor.title ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  instructor.title!,
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Exported so the course page can draw the same byline.
class InstructorLine extends StatelessWidget {
  const InstructorLine({super.key, required this.instructor});

  final Instructor instructor;

  @override
  Widget build(BuildContext context) => _InstructorLine(instructor: instructor);
}
