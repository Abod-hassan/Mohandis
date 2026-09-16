import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';

/// Labels the three course enums in one place, so a card and a course page can
/// never word the same value differently.
extension CourseLevelLabel on CourseLevel {
  String label(BuildContext context) => switch (this) {
    CourseLevel.beginner => context.l10n.courseLevelBeginner,
    CourseLevel.intermediate => context.l10n.courseLevelIntermediate,
    CourseLevel.advanced => context.l10n.courseLevelAdvanced,
  };
}

extension LessonKindLabel on LessonKind {
  String label(BuildContext context) => switch (this) {
    LessonKind.video => context.l10n.lessonKindVideo,
    LessonKind.pdf => context.l10n.lessonKindPdf,
    LessonKind.article => context.l10n.lessonKindArticle,
  };

  IconData get icon => switch (this) {
    LessonKind.video => Icons.play_circle_fill,
    LessonKind.pdf => Icons.picture_as_pdf_outlined,
    LessonKind.article => Icons.article_outlined,
  };
}

/// Course artwork, with the section's own tint as the fallback.
///
/// A placeholder rather than an empty box: a catalogue where half the cards
/// have no image reads as broken, while a tinted panel with an icon reads as a
/// course nobody has uploaded art for yet.
class CourseCover extends ConsumerWidget {
  const CourseCover({
    super.key,
    required this.course,
    this.height = 150,
    this.radius = RungRadius.md,
    this.topOnly = false,
  });

  final Course course;
  final double height;
  final double radius;

  /// Rounds only the top corners. A card cover sits flush against the card's
  /// own bottom edge, so rounding all four notches the artwork inward against
  /// the surface underneath it.
  final bool topOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final resolved = ref.watch(imageUrlResolverProvider)(course.coverImageUrl);

    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: c.accentSoft,
      alignment: Alignment.center,
      child: Icon(Icons.school_outlined, size: 34, color: c.accent),
    );

    return ClipRRect(
      borderRadius: topOnly
          ? BorderRadius.vertical(top: Radius.circular(radius))
          : BorderRadius.circular(radius),
      child: resolved == null
          ? placeholder
          : Image.network(
              resolved,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// "٤٫٦ (٢٣)", or the no-ratings line. Never a lone star on zero reviews — an
/// average of nothing is not a rating of zero.
class CourseRating extends StatelessWidget {
  const CourseRating({super.key, required this.course, this.compact = false});

  final Course course;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    if (!course.hasRating) {
      return Text(
        l10n.courseNoRatings,
        style: TextStyle(fontSize: compact ? 11.5 : 12.5, color: c.ink3),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: compact ? 14 : 16, color: c.gold),
        const SizedBox(width: 3),
        Text(
          l10n.courseRatingOf(
            ArabicNumbers.count(course.ratingAverage),
            ArabicNumbers.plain(course.ratingCount),
          ),
          style: TextStyle(
            fontSize: compact ? 11.5 : 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
      ],
    );
  }
}

/// The price-shaped badge: free, locked, or "included" for a paid course this
/// viewer can already open.
class CoursePriceBadge extends StatelessWidget {
  const CoursePriceBadge({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final (String text, Color tint, IconData? icon) = course.isFree
        ? (l10n.courseFree, c.green, null)
        : course.isLocked
        ? (l10n.courseLockedBadge, c.ink3, Icons.lock_outline)
        : (l10n.subscriptionTitle, c.accent, Icons.workspace_premium_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

/// "٢٤ محاضرة · ١٨ ساعة · متوسط" — the one-line spec every card and page shows.
String courseMeta(BuildContext context, Course course) {
  final l10n = context.l10n;
  final parts = <String>[
    l10n.courseLectureCount(ArabicNumbers.plain(course.totalLectures)),
    if (course.durationMinutes > 0)
      l10n.courseHours(ArabicNumbers.count(course.durationMinutes / 60)),
    course.level.label(context),
  ];
  return parts.join(' · ');
}
