import 'package:flutter/material.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';

/// Where a course stands with the reviewer, as a pill.
///
/// The four states carry the same colours they do everywhere else in the app:
/// grey for "nothing has happened yet", amber for "waiting on somebody", red
/// for "needs your attention", green for "done". The author reads this on a
/// list of ten and has to be able to tell which one needs them without reading
/// four words.
class CourseStatusPill extends StatelessWidget {
  const CourseStatusPill({super.key, required this.status, this.dense = false});

  final CourseReviewStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final (label, fg, bg, icon) = switch (status) {
      CourseReviewStatus.draft => (
        l10n.courseStatusDraft,
        c.ink3,
        c.surface2,
        Icons.edit_note_rounded,
      ),
      CourseReviewStatus.submitted => (
        l10n.courseStatusSubmitted,
        c.amber,
        c.amberSoft,
        Icons.hourglass_top_rounded,
      ),
      CourseReviewStatus.rejected => (
        l10n.courseStatusRejected,
        c.red,
        c.redSoft,
        Icons.error_outline_rounded,
      ),
      CourseReviewStatus.approved => (
        l10n.courseStatusApproved,
        c.green,
        c.greenSoft,
        Icons.check_circle_outline_rounded,
      ),
    };

    return RungStatusPill(
      label: label,
      foreground: fg,
      background: bg,
      dense: dense,
      leading: Icon(icon, size: dense ? 12 : 14, color: fg),
    );
  }
}

/// A price with its subscriber discount, if this viewer gets one.
///
/// The struck-through original is kept beside the discounted figure rather than
/// replaced by it: the discount is the subscription's selling point, and a
/// price that is simply lower says nothing about why.
class CoursePrice extends StatelessWidget {
  const CoursePrice({super.key, required this.commerce, this.large = false});

  final CourseCommerce commerce;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    if (!commerce.isSold) {
      return Text(
        l10n.courseFree,
        style: TextStyle(
          fontSize: large ? 16 : 13,
          fontWeight: FontWeight.w800,
          color: c.green,
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          _money(commerce.priceAfterDiscount, commerce.currency),
          style: TextStyle(
            fontSize: large ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: c.ink,
          ),
        ),
        if (commerce.hasDiscount) ...[
          Text(
            _money(commerce.price, commerce.currency),
            style: TextStyle(
              fontSize: large ? 13 : 11.5,
              color: c.ink3,
              decoration: TextDecoration.lineThrough,
              decorationColor: c.ink3,
            ),
          ),
          RungTagChip(
            label: l10n.courseSubscriberDiscount(
              ArabicNumbers.plain(commerce.discountPercent.round()),
            ),
            emphasis: RungTagEmphasis.accent,
          ),
        ],
      ],
    );
  }
}

/// An amount with its currency, in Arabic-Indic digits and grouped.
///
/// `count`, deliberately, not `compact`: compact would render 12,400 دينار as
/// "12 ألف", and an abbreviated PRICE is one somebody will argue about. Shared
/// by every screen that shows money here, so a price on a card and the same
/// price on the purchase queue cannot be formatted two ways.
String _money(double amount, String currency) =>
    '${ArabicNumbers.count(amount)} $currency';

/// The public spelling of [_money], for the screens that show an amount off a
/// purchase row rather than off a course.
String courseMoney(double amount, String currency) => _money(amount, currency);
