import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../../data/repositories/panel_repository_impl.dart';
import '../../domain/entities/panel_entities.dart';
import '../notifiers/panel_notifiers.dart';
import '../widgets/course_bits.dart';
import '../widgets/course_status_pill.dart';
import 'courses_screen.dart';

/// A course page: what it is, who teaches it, what you'll learn, and the
/// lessons themselves.
///
/// Progress is a single position, so the lesson list is strictly sequential —
/// done, next, locked. Both locks are the server's: a course no plan covers
/// arrives with its lessons emptied of content, and so does a lesson beyond the
/// reader's position. The padlocks here are labels for decisions already made.
class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _busy = false;

  int _minutesFor(Course course, Lecture lesson) {
    if (lesson.durationMinutes > 0) return lesson.durationMinutes;
    if (course.totalLectures <= 0) return 0;
    return (course.durationMinutes / course.totalLectures).round();
  }

  /// Everything up to and including [position], in minutes.
  ///
  /// Summed from the syllabus rather than added to what the screen already
  /// shows. The server keeps the larger of the two figures, so a total derived
  /// from a position is idempotent — replaying lesson three sends the same
  /// number and changes nothing — whereas adding a delta to the running total
  /// is larger every time and would inflate the dashboard's hours on each
  /// replay.
  int _minutesThrough(Course course, List<Lecture> lessons, int position) {
    var total = 0;
    for (final lesson in lessons) {
      if (lesson.position <= position) total += _minutesFor(course, lesson);
    }
    return total;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(Course course) => _run(() async {
    final result = await ref
        .read(panelRepositoryProvider)
        .requestPurchase(course.id);

    if (!mounted) return;
    result.when(
      success: (_) {
        // The course row itself changes — `purchaseStatus` goes from null to
        // pending — so the page is re-read rather than patched, and the card
        // under the price redraws as "بانتظار التأكيد".
        ref.invalidate(courseProvider(course.id));
        ref.invalidate(courseListProvider(course.category));
        showRungToast(context, context.l10n.coursePurchaseAsked);
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  });

  Future<void> _enroll(Course course) => _run(() async {
    final result = await ref
        .read(courseListProvider(course.category).notifier)
        .enroll(course.id);
    if (!mounted) return;
    ref.invalidate(courseProvider(course.id));
    ref.invalidate(courseLecturesProvider(course.id));
    result.when(
      success: (_) => showRungToast(context, context.l10n.courseEnrolled),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  });

  Future<void> _markWatched(
    Course course,
    List<Lecture> lessons,
    Lecture lesson, {
    String? doneMessage,
  }) => _run(() async {
    final result = await ref
        .read(courseProgressControllerProvider)
        .save(
          courseId: course.id,
          currentLecture: lesson.position,
          minutesWatched: _minutesThrough(course, lessons, lesson.position),
        );
    if (!mounted) return;
    result.when(
      success: (updated) => showRungToast(
        context,
        updated.isCompleted
            ? context.l10n.courseCompleted
            : doneMessage ?? context.l10n.courseProgressSaved,
      ),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  });

  /// A lesson moves the pointer only if it is the next one — or one already
  /// behind it, where the server's forward-only rule makes the write a no-op.
  ///
  /// Previews are the case this exists for: they are openable at any position,
  /// so a free lesson eight would otherwise carry someone from lesson one
  /// straight to 8/10, marking six they never opened as done.
  bool _advancesProgress(Course course, Lecture lesson) =>
      lesson.position <= course.currentLecture + 1;

  Future<void> _openLesson(
    Course course,
    List<Lecture> lessons,
    Lecture lesson,
  ) async {
    final l10n = context.l10n;

    // A locked lesson on a locked course is the paywall, not the sequence —
    // so it goes to the plans, which is the only thing that would change it.
    if (lesson.isLocked && course.isLocked) {
      // Only when a PLAN is what opens it. A sold course is locked by the
      // purchase, so sending its buyer to the plans screen offers them
      // something that cannot unlock what they just tapped.
      if (!course.commerce.isSold) context.push('/subscription');
      return;
    }
    if (lesson.isLocked) {
      showRungToast(context, l10n.courseLectureLocked, success: false);
      return;
    }

    // Unlocked with nothing behind it. The row is still how you move past it —
    // otherwise a course whose files are not up yet can never be finished, and
    // neither can anything after it.
    if (!lesson.isOpenable) {
      if (_advancesProgress(course, lesson)) {
        await _markWatched(
          course,
          lessons,
          lesson,
          doneMessage: l10n.courseLectureMarkedDone,
        );
      }
      return;
    }

    final route = lesson.kind == LessonKind.video ? '/panel/lecture' : '/panel/lesson';
    final finished = await context.push<bool>(route, extra: lesson);
    if (!mounted || finished != true) return;
    if (!_advancesProgress(course, lesson)) return;
    await _markWatched(course, lessons, lesson);
  }

  Future<void> _rate(Course course) async {
    final stars = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(current: course.myRating),
    );
    if (stars == null || !mounted) return;

    await _run(() async {
      final result = await ref
          .read(courseProgressControllerProvider)
          .rate(courseId: course.id, stars: stars);
      if (!mounted) return;
      result.when(
        success: (_) => showRungToast(context, context.l10n.courseRated),
        failure: (e) => showRungToast(
          context,
          arabicMessageForException(e),
          success: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final course = ref.watch(courseProvider(widget.courseId));
    final lessons = ref.watch(courseLecturesProvider(widget.courseId));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.courseTitle),
      body: course.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(courseProvider(widget.courseId)),
        ),
        data: (data) => RefreshIndicator(
          // Both, and the lessons are not optional: buying a course changes
          // the course row AND unlocks its lessons, and an administrator
          // confirms the payment somewhere else entirely. A pull is the only
          // way a learner finds out, since nothing pushes at the client.
          onRefresh: () async {
            ref.invalidate(courseLecturesProvider(widget.courseId));
            await pullRefresh(
              ref.refresh(courseProvider(widget.courseId).future),
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              RungSpace.gutter,
              14,
              RungSpace.gutter,
              32,
            ),
            children: [
              CourseCover(course: data, height: 180, radius: RungRadius.md + 2),
              const SizedBox(height: RungSpace.md),

              Row(
                children: [
                  CoursePriceBadge(course: data),
                  const SizedBox(width: 8),
                  CourseRating(course: data),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                data.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${data.category.label(context)} · ${courseMeta(context, data)}',
                style: TextStyle(fontSize: 12.5, color: c.ink3),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.courseEnrolledCount(
                  ArabicNumbers.compact(data.enrolledCount),
                ),
                style: TextStyle(fontSize: 12.5, color: c.ink3),
              ),

              // A sold course and a plan course are locked for different
              // reasons, and the way out of each is different: one is bought,
              // the other is subscribed to. Offering "اشترك" on a course the
              // subscription does not open is a dead end.
              if (data.commerce.isSold) ...[
                const SizedBox(height: RungSpace.md),
                _BuyCard(
                  course: data,
                  busy: _busy,
                  onBuy: () => _buy(data),
                ),
              ] else if (data.isLocked) ...[
                const SizedBox(height: RungSpace.md),
                _LockedNotice(onSeePlans: () => context.push('/subscription')),
              ],

              if (data.isEnrolled) ...[
                const SizedBox(height: RungSpace.md),
                _ProgressCard(course: data),
              ],

              if (data.hasCertificate) ...[
                const SizedBox(height: RungSpace.md),
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 18,
                      color: c.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.courseCertificateEarned,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.gold,
                      ),
                    ),
                  ],
                ),
              ],

              // `isLocked` already covers an unpaid sold course — the server
              // computes it from the purchase, not from the subscription — so
              // this needs no second condition for the marketplace.
              if (!data.isEnrolled && !data.isLocked) ...[
                const SizedBox(height: RungSpace.lg),
                FilledButton(
                  onPressed: _busy ? null : () => _enroll(data),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _busy
                      ? const _ButtonSpinner()
                      : Text(l10n.courseEnroll),
                ),
              ],

              if (data.isEnrolled) ...[
                const SizedBox(height: RungSpace.md),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _rate(data),
                  icon: Icon(
                    data.myRating > 0 ? Icons.star_rounded : Icons.star_outline,
                    size: 18,
                  ),
                  label: Text(
                    data.myRating > 0
                        ? '${l10n.courseYourRating}: ${ArabicNumbers.plain(data.myRating)}'
                        : l10n.courseRateTitle,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],

              if (data.instructor != null) ...[
                const SizedBox(height: RungSpace.lg),
                _SectionTitle(l10n.courseInstructor),
                const SizedBox(height: RungSpace.sm),
                InstructorLine(instructor: data.instructor!),
                if ((data.instructor!.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.instructor!.bio!,
                    style: TextStyle(fontSize: 13, height: 1.6, color: c.ink3),
                  ),
                ],
              ],

              if ((data.description ?? '').isNotEmpty) ...[
                const SizedBox(height: RungSpace.lg),
                _SectionTitle(l10n.courseAbout),
                const SizedBox(height: RungSpace.sm),
                Text(
                  data.description!,
                  style: const TextStyle(fontSize: 14, height: 1.75),
                ),
              ],

              if (data.outcomes.isNotEmpty) ...[
                const SizedBox(height: RungSpace.lg),
                _SectionTitle(l10n.courseOutcomes),
                const SizedBox(height: RungSpace.sm),
                _Bullets(lines: data.outcomes, icon: Icons.check_circle_outline),
              ],

              if (data.requirements.isNotEmpty) ...[
                const SizedBox(height: RungSpace.lg),
                _SectionTitle(l10n.courseRequirements),
                const SizedBox(height: RungSpace.sm),
                _Bullets(
                  lines: data.requirements,
                  icon: Icons.radio_button_unchecked,
                ),
              ],

              const SizedBox(height: RungSpace.lg),
              _SectionTitle(l10n.courseLecturesSection),
              const SizedBox(height: RungSpace.sm),

              // The syllabus loads on its own. A spinner here rather than one
              // over the whole screen: the course is already on screen, and
              // re-hiding it every time progress is saved would flash the page.
              lessons.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(courseLecturesProvider(widget.courseId)),
                ),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          l10n.courseLecturesEmpty,
                          style: TextStyle(fontSize: 13.5, color: c.ink3),
                        ),
                      )
                    : Column(
                        children: [
                          for (final lesson in list)
                            _LessonTile(
                              lesson: lesson,
                              enabled: !_busy,
                              onTap: () => _openLesson(data, list, lesson),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.onSeePlans});

  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: RungRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.courseLockedTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.courseLockedBody,
            style: TextStyle(fontSize: 12.5, height: 1.6, color: c.ink2),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onSeePlans,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
            ),
            child: Text(l10n.courseSubscribeToOpen),
          ),
        ],
      ),
    );
  }
}

/// The price, the author, and the way to buy.
///
/// Three states, and they are NOT a spectrum: nothing bought yet (a price and
/// a button), a request in flight (an explanation and no button, because a
/// second tap achieves nothing the server does not already know), and bought
/// (a receipt). The middle one is the one worth getting right — a learner who
/// has transferred money and sees an unchanged buy button will transfer it
/// again.
class _BuyCard extends ConsumerWidget {
  const _BuyCard({
    required this.course,
    required this.busy,
    required this.onBuy,
  });

  final Course course;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final commerce = course.commerce;
    final author = commerce.author;

    return RungCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Once a request is in flight, the amount that was STAMPED — not the
          // live price, which is recomputed on every read and can drift away
          // from it when a subscription lapses or the tenant's discount moves.
          if (commerce.isAwaitingPayment && commerce.purchaseAmountDue != null)
            Text(
              courseMoney(commerce.purchaseAmountDue!, commerce.currency),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            )
          else
            CoursePrice(commerce: commerce, large: true),
          if (author != null) ...[
            const SizedBox(height: RungSpace.sm),
            Row(
              children: [
                RungAvatar(
                  seed: author.id,
                  initials: author.initials,
                  icon: author.accountType.icon,
                  imageUrl: ref.watch(imageUrlResolverProvider)(
                    author.avatarUrl,
                  ),
                  size: 30,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.courseAuthorLabel,
                        style: TextStyle(fontSize: 11, color: c.ink3),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          NameBadges(
                            verified: author.verified,
                            subscribed: author.subscribed,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: RungSpace.sm),
          if (commerce.isPaid)
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: c.green,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.coursePurchasePaid,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: c.green,
                  ),
                ),
              ],
            )
          else if (commerce.isAwaitingPayment)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.amberSoft,
                borderRadius: RungRadius.smAll,
              ),
              child: Text(
                l10n.coursePurchaseAsked,
                style: TextStyle(fontSize: 12.5, height: 1.5, color: c.ink2),
              ),
            )
          else if (!commerce.isMine)
            FilledButton(
              onPressed: busy ? null : onBuy,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(l10n.courseBuy),
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return RungCard(
      radius: RungRadius.md + 2,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Fact(
                  label: l10n.courseLecturesDone,
                  value: l10n.courseLectureOf(
                    ArabicNumbers.plain(course.currentLecture),
                    ArabicNumbers.plain(course.totalLectures),
                  ),
                ),
              ),
              Expanded(
                child: _Fact(
                  label: l10n.dashboardStatHours,
                  value: ArabicNumbers.plain(course.minutesWatched ~/ 60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: course.fraction,
              minHeight: 6,
              backgroundColor: c.surface3,
              color: course.isCompleted ? c.green : c.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.enabled,
    required this.onTap,
  });

  final Lecture lesson;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final (IconData icon, Color tint) = switch (lesson) {
      _ when lesson.isCompleted => (Icons.check_circle, c.green),
      _ when lesson.isLocked => (Icons.lock_outline, c.ink3),
      _ when lesson.isOpenable => (lesson.kind.icon, c.accent),
      _ => (Icons.schedule, c.amber),
    };

    // Only ever one of these, and in this order: a locked row says why, an
    // unlocked one with nothing behind it says so, a preview says it is free,
    // and everything else falls back to what kind of lesson it is.
    final String note = lesson.isLocked
        ? l10n.courseLectureLocked
        : !lesson.isOpenable
        ? l10n.courseLectureNoVideo
        : lesson.isPreview
        ? l10n.courseLecturePreview
        : lesson.kind.label(context);

    return RungCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Icon(icon, size: 24, color: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ArabicNumbers.plain(lesson.position)}. ${lesson.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: lesson.isLocked ? c.ink3 : c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(note, style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          if (lesson.durationMinutes > 0) ...[
            const SizedBox(width: 8),
            Text(
              l10n.courseLectureMinutes(
                ArabicNumbers.plain(lesson.durationMinutes),
              ),
              style: TextStyle(fontSize: 11.5, color: c.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Five stars and an optional comment. A sheet rather than a dialog because a
/// comment field in a dialog fights the keyboard on a short phone.
class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.current});

  final int current;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  late int _stars = widget.current == 0 ? 5 : widget.current;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(RungSpace.gutter),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RungRadius.lg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.courseRateTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: RungSpace.md),
            Row(
              // LTR on purpose: a five-star row reads left to right in every
              // locale, and mirrored it would put "one star" on the right.
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _stars = i),
                    iconSize: 34,
                    icon: Icon(
                      i <= _stars ? Icons.star_rounded : Icons.star_outline,
                      color: i <= _stars ? c.gold : c.ink3,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: RungSpace.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_stars),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.courseRateAction),
            ),
            const SizedBox(height: RungSpace.sm),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
  );
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.lines, required this.icon});

  final List<String> lines;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 17, color: c.green),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(fontSize: 13.5, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11.5, color: c.ink3)),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}
