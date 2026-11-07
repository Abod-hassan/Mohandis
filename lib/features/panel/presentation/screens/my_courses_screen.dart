import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/course_market_notifiers.dart';
import '../widgets/course_status_pill.dart';

/// "دوراتي" — the courses this viewer wrote, in every state.
///
/// Deliberately NOT a tab of the catalogue: almost everything on this list is
/// something the catalogue is built to hide — a draft, or a course the reviewer
/// sent back — and the questions asked of a row here ("what does it still need
/// from me?") are not the questions asked of a catalogue card.
class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final rows = ref.watch(myCoursesProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(title: l10n.myCoursesTitle, showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/panel/courses/mine/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.myCoursesNew),
      ),
      body: rows.when(
        loading: () => const PeopleListSkeleton(count: 5),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myCoursesProvider)),
        data: (courses) => RefreshIndicator(
          onRefresh: () => pullRefresh(ref.refresh(myCoursesProvider.future)),
          child: courses.isEmpty
              // A scroll view even when empty: RefreshIndicator needs something
              // scrollable under it, and an empty state you cannot pull on is
              // an empty state with no way to find out it is wrong.
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: EmptyView(
                        title: l10n.myCoursesTitle,
                        message: l10n.myCoursesEmpty,
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    RungSpace.gutter,
                    RungSpace.sm,
                    RungSpace.gutter,
                    96,
                  ),
                  children: [
                    RungNavRow(
                      icon: Icons.payments_outlined,
                      iconColor: c.green,
                      iconBackground: c.greenSoft,
                      title: l10n.myCoursesEarnings,
                      subtitle: l10n.purchaseAuthorShare,
                      onTap: () => context.push('/panel/courses/earnings'),
                    ),
                    const SizedBox(height: RungSpace.sm),
                    for (final course in courses) ...[
                      _Row(course: course),
                      const SizedBox(height: RungSpace.sm),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final commerce = course.commerce;

    return RungCard(
      onTap: () => context.push('/panel/courses/mine/${course.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CourseStatusPill(status: commerce.reviewStatus, dense: true),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.play_circle_outline, size: 15, color: c.ink3),
              const SizedBox(width: 4),
              Text(
                ArabicNumbers.plain(course.totalLectures),
                style: TextStyle(fontSize: 12, color: c.ink3),
              ),
              const SizedBox(width: 12),
              Expanded(child: CoursePrice(commerce: commerce)),
            ],
          ),

          // The reviewer's note, on the list and not only inside the course.
          // A sent-back course whose reason is one tap away is a course the
          // author reads the state of and does nothing about.
          if (commerce.reviewStatus == CourseReviewStatus.rejected &&
              commerce.reviewNote != null) ...[
            const SizedBox(height: RungSpace.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.redSoft,
                borderRadius: RungRadius.smAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.courseReviewNote,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: c.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    commerce.reviewNote!,
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: c.ink2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
