import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';
import '../../theme/rung_tokens.dart';

/// Shimmering placeholder blocks shown while a surface's first page loads.
///
/// A spinner says "something is happening". A skeleton says "this is what is
/// coming, and roughly how much of it" — which is the difference between an
/// app that feels stuck and one that feels fast, on exactly the screens that
/// have the most to fetch.
///
/// Every shape here is sized to the real widget it stands in for, so nothing
/// jumps when the data lands.
class RungSkeleton extends StatefulWidget {
  const RungSkeleton({super.key, required this.child});

  /// Any subtree of [SkeletonBox]es. One controller drives all of them, so a
  /// screenful of blocks is a single animation rather than a dozen.
  final Widget child;

  @override
  State<RungSkeleton> createState() => _RungSkeletonState();
}

class _RungSkeletonState extends State<RungSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No ExcludeSemantics here. It looks like the obvious thing to add — a
    // screen reader has no use for placeholder blocks — but it is a semantics
    // boundary that HIDES its subtree via visitChildrenForSemantics, and the
    // framework then never assigns parent data to the render objects beneath
    // it. Over a scrolling viewport that is what produced the repeating
    // `!semantics.parentDataDirty` assertion on the followers and connections
    // lists. It is also unnecessary: a SkeletonBox is a bare CustomPaint with
    // no child and no semantics config, so it contributes nothing to the
    // semantics tree to begin with.
    return _SkeletonPulse(
      animation: _controller,
      child: widget.child,
    );
  }
}

/// Inherited so a [SkeletonBox] anywhere below can read the shared animation
/// without it being threaded through every constructor.
class _SkeletonPulse extends InheritedWidget {
  const _SkeletonPulse({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SkeletonPulse>()
      ?.animation;

  @override
  bool updateShouldNotify(_SkeletonPulse oldWidget) =>
      oldWidget.animation != animation;
}

/// One placeholder block. Put these inside a [RungSkeleton].
///
/// The pulse is painted, never rebuilt. An earlier version wrapped a
/// [Container] in an [AnimatedBuilder], which reconstructed the widget — and
/// so re-marked the subtree's semantics — on every one of the ~60 frames a
/// second the controller ticks. Under a scrolling viewport that tripped the
/// framework's `!semantics.parentDataDirty` assertion on the people lists.
/// A [CustomPaint] whose painter takes the animation as its `repaint` signal
/// does the same thing visually while touching only the paint phase.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  /// Null means "as wide as the parent allows" — see [build], which turns it
  /// into `double.infinity` rather than leaving the box unconstrained.
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final pulse = _SkeletonPulse.maybeOf(context);

    return SizedBox(
      // `double.infinity`, NOT null. A Column hands its children LOOSE
      // constraints, so a box with a null width and no child shrinks to
      // nothing — every full-width line in these skeletons would render zero
      // pixels wide. Infinity resolves to the parent's maxWidth instead.
      //
      // Safe because every null-width box here sits in a width-bounded parent
      // (a ListView child, an Expanded, or a padded Container). A box inside a
      // horizontally scrolling list must pass an explicit width, as the
      // stories rail does.
      width: width ?? double.infinity,
      height: height,
      child: CustomPaint(
        painter: _SkeletonBoxPainter(
          // No controller above us — a lone box outside a RungSkeleton still
          // renders, just frozen mid-pulse, instead of throwing.
          pulse: pulse,
          // Between the two neutral surfaces, so the pulse reads in light and
          // dark without either end going invisible against the page.
          base: c.surface3,
          peak: c.line2,
          radius: radius,
          circle: shape == BoxShape.circle,
        ),
      ),
    );
  }
}

/// Paints one pulsing block.
///
/// Passing [pulse] to `super.repaint` is the whole point: the render object
/// listens to the controller directly and schedules a repaint, so no widget,
/// element or render object above it is ever marked dirty.
class _SkeletonBoxPainter extends CustomPainter {
  _SkeletonBoxPainter({
    required this.pulse,
    required this.base,
    required this.peak,
    required this.radius,
    required this.circle,
  }) : super(repaint: pulse);

  final Animation<double>? pulse;
  final Color base;
  final Color peak;
  final double radius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = pulse == null ? 0.35 : 0.15 + pulse!.value * 0.5;
    final paint = Paint()..color = Color.lerp(base, peak, t)!;
    final rect = Offset.zero & size;

    if (circle) {
      canvas.drawOval(rect, paint);
      return;
    }
    // RungRadius.full is a deliberately oversized 999; clamping here keeps a
    // short box a stadium instead of leaving the clamp to the rasteriser.
    final maxR = size.shortestSide / 2;
    final double r = radius < 0 ? 0 : (radius > maxR ? maxR : radius);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), paint);
  }

  @override
  bool shouldRepaint(_SkeletonBoxPainter old) =>
      old.pulse != pulse ||
      old.base != base ||
      old.peak != peak ||
      old.radius != radius ||
      old.circle != circle;

  /// These blocks stand in for content that is not there yet; there is nothing
  /// for a screen reader to read.
  @override
  bool shouldRebuildSemantics(_SkeletonBoxPainter old) => false;
}

/// A post card's silhouette: avatar, two header lines, three text lines and a
/// media block.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key, this.hasMedia = true});

  final bool hasMedia;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.xs,
        RungSpace.gutter,
        RungSpace.xs,
      ),
      padding: const EdgeInsets.all(RungSpace.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(RungRadius.md),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 44, height: 44, shape: BoxShape.circle),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 130, height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 11),
                ],
              ),
            ],
          ),
          const SizedBox(height: RungSpace.sm),
          const SkeletonBox(height: 11),
          const SizedBox(height: 7),
          const SkeletonBox(height: 11),
          const SizedBox(height: 7),
          const SkeletonBox(width: 180, height: 11),
          if (hasMedia) ...[
            const SizedBox(height: RungSpace.sm),
            const SkeletonBox(height: 168, radius: RungRadius.sm),
          ],
        ],
      ),
    );
  }
}

/// The stories rail: a row of circles with a caption under each.
class StoriesRailSkeleton extends StatelessWidget {
  const StoriesRailSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(vertical: RungSpace.sm),
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: RungSpace.gutter),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Column(
            children: const [
              SkeletonBox(width: 60, height: 60, shape: BoxShape.circle),
              SizedBox(height: 8),
              SkeletonBox(width: 46, height: 9),
            ],
          ),
        ),
      ),
    );
  }
}

/// A person row: avatar, name, headline, and the trailing action button.
class PersonRowSkeleton extends StatelessWidget {
  const PersonRowSkeleton({super.key, this.hasAction = true});

  final bool hasAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RungSpace.gutter,
        vertical: 10,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 52, height: 52, shape: BoxShape.circle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 13),
                SizedBox(height: 7),
                SkeletonBox(width: 100, height: 11),
              ],
            ),
          ),
          if (hasAction) ...[
            const SizedBox(width: 10),
            const SkeletonBox(width: 76, height: 30, radius: RungRadius.full),
          ],
        ],
      ),
    );
  }
}

/// The feed's first paint: rail, composer row, then cards.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return RungSkeleton(
      child: ListView(
        // The real feed scrolls; matching that stops the scroll position from
        // resetting when the list swaps in under the user.
        padding: const EdgeInsets.only(bottom: RungSpace.lg),
        children: [
          const StoriesRailSkeleton(),
          const SizedBox(height: RungSpace.sectionGap),
          Container(
            color: c.surface,
            padding: const EdgeInsets.all(RungSpace.sm),
            child: Row(
              children: const [
                SkeletonBox(width: 40, height: 40, shape: BoxShape.circle),
                SizedBox(width: 10),
                Expanded(
                  child: SkeletonBox(height: 38, radius: RungRadius.full),
                ),
              ],
            ),
          ),
          const SizedBox(height: RungSpace.sectionGap),
          const PostCardSkeleton(),
          const PostCardSkeleton(hasMedia: false),
          const PostCardSkeleton(),
        ],
      ),
    );
  }
}

/// A plain list of [PersonRowSkeleton]s, for the people lists and the network
/// tab's request rows.
class PeopleListSkeleton extends StatelessWidget {
  const PeopleListSkeleton({super.key, this.count = 7, this.hasAction = true});

  final int count;
  final bool hasAction;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: count,
        itemBuilder: (_, __) => PersonRowSkeleton(hasAction: hasAction),
      ),
    );
  }
}

/// A stack of post cards — the saved-posts list and a profile's activity feed.
class PostListSkeleton extends StatelessWidget {
  const PostListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: RungSpace.xs),
        itemCount: count,
        // Alternating media keeps the placeholder from looking like a printed
        // pattern, which is what a column of identical blocks reads as.
        itemBuilder: (_, i) => PostCardSkeleton(hasMedia: i.isEven),
      ),
    );
  }
}

/// A short stack of lesson rows, while a course's lessons load.
///
/// **A Column, not a ListView** — and that is the whole point of it existing.
/// This sits inside a section inside the course editor's own scroll view,
/// where a scrollable with its own viewport is handed unbounded height, throws
/// on every layout pass, and buries the console in
/// `!semantics.parentDataDirty` asserts. Same reason [GridTabSkeleton] exists.
class LessonListSkeleton extends StatelessWidget {
  const LessonListSkeleton({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SkeletonBox(width: 14, height: 14),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 12),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The profile's posts/reels grid, while it loads.
///
/// `shrinkWrap`, because this sits in a `SliverToBoxAdapter` inside the
/// profile's one scroll view — a scrollable with its own viewport would be
/// handed unbounded height there and throw.
class GridTabSkeleton extends StatelessWidget {
  const GridTabSkeleton({super.key, this.count = 9, this.aspectRatio = 1});

  final int count;

  /// 1 for the square posts grid, 0.72 for the taller reel tiles.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: GridView.builder(
        padding: const EdgeInsets.all(1),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: aspectRatio,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const SkeletonBox(radius: 0),
      ),
    );
  }
}

/// Generic stacked cards, for every list whose rows are a titled block:
/// jobs, applications, courses, documents, notes, legal requests.
class CardListSkeleton extends StatelessWidget {
  const CardListSkeleton({
    super.key,
    this.count = 5,
    this.height = 96,
    this.lines = 2,
  });

  final int count;

  /// Match the real card's height so the list does not resize under the user.
  ///
  /// A MINIMUM, not a fixed size. As a fixed height the card overflowed
  /// whenever its own contents came to more than it — 38px of avatar row plus
  /// the gaps plus [lines] of text — and every caller had to work that sum out
  /// by hand to pick a number. Growing past it costs a slightly taller
  /// placeholder; the alternative is yellow stripes across a loading screen.
  final double height;

  /// Text lines drawn inside each card, under the title.
  final int lines;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return RungSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: RungSpace.sm,
        ),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          constraints: BoxConstraints(minHeight: height),
          margin: const EdgeInsets.only(bottom: RungSpace.sm),
          padding: const EdgeInsets.all(RungSpace.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(RungRadius.md),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Only as tall as its contents; the card's own minHeight does the
            // rest. Without this the Column tried to fill a box it could
            // already be taller than.
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  SkeletonBox(width: 38, height: 38, radius: RungRadius.sm),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 13)),
                ],
              ),
              const SizedBox(height: RungSpace.sm),
              for (var i = 0; i < lines; i++) ...[
                if (i > 0) const SizedBox(height: 7),
                SkeletonBox(width: i.isEven ? null : 160, height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification rows: a small round icon and two lines of text.
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.count = 8});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return RungSkeleton(
      child: ListView.separated(
        itemCount: count,
        separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RungSpace.gutter,
            vertical: 12,
          ),
          child: Row(
            children: const [
              SkeletonBox(width: 40, height: 40, shape: BoxShape.circle),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12),
                    SizedBox(height: 7),
                    SkeletonBox(width: 120, height: 10),
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

/// A detail page: title block, meta row, then a body of paragraph lines.
/// Job detail, course detail, a single post.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key, this.hasHero = true, this.paragraphs = 3});

  /// A cover image or video poster above the title.
  final bool hasHero;
  final int paragraphs;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(RungSpace.gutter),
        children: [
          if (hasHero) ...[
            const SkeletonBox(height: 180, radius: RungRadius.md),
            const SizedBox(height: RungSpace.md),
          ],
          const SkeletonBox(width: 220, height: 20, radius: 8),
          const SizedBox(height: RungSpace.sm),
          Row(
            children: const [
              SkeletonBox(width: 36, height: 36, shape: BoxShape.circle),
              SizedBox(width: 10),
              SkeletonBox(width: 120, height: 12),
              SizedBox(width: 12),
              SkeletonBox(width: 70, height: 12),
            ],
          ),
          const SizedBox(height: RungSpace.lg),
          for (var p = 0; p < paragraphs; p++) ...[
            const SkeletonBox(height: 11),
            const SizedBox(height: 8),
            const SkeletonBox(height: 11),
            const SizedBox(height: 8),
            const SkeletonBox(width: 200, height: 11),
            const SizedBox(height: RungSpace.md),
          ],
        ],
      ),
    );
  }
}

/// A form: a label and an input per field, then a submit button.
/// The edit-profile, CV-section and job-application screens.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key, this.fields = 5});

  final int fields;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(RungSpace.gutter),
        children: [
          for (var i = 0; i < fields; i++) ...[
            const SkeletonBox(width: 90, height: 11),
            const SizedBox(height: RungSpace.xs),
            const SkeletonBox(height: 46, radius: RungRadius.sm),
            const SizedBox(height: RungSpace.md),
          ],
          const SizedBox(height: RungSpace.xs),
          const SkeletonBox(height: 50, radius: RungRadius.full),
        ],
      ),
    );
  }
}

/// A profile page: cover, the avatar overhanging it, name, stats, then cards.
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    // Laid out like the real profile — top bar, avatar beside three counts,
    // name and bio lines, the two buttons, the tab strip, then the grid — so
    // nothing jumps sideways when the data lands.
    return RungSkeleton(
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Top bar: back arrow, handle, menu.
          Container(
            color: c.surface,
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: const SizedBox(
              height: 52,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: RungSpace.gutter),
                child: Row(
                  children: [
                    SkeletonBox(width: 18, height: 18, radius: 4),
                    SizedBox(width: RungSpace.sm),
                    SkeletonBox(width: 130, height: 14),
                    Spacer(),
                    SkeletonBox(width: 18, height: 18, radius: 4),
                  ],
                ),
              ),
            ),
          ),
          // The cover banner. Full-bleed and square-cornered, same as the real
          // one — a profile with no cover still draws a gradient there, so the
          // block is never absent and leaving it out would move everything
          // below it 140pt the moment the data arrived.
          // Cover, mark and counts, laid out exactly as the real header lays
          // them: the mark crossing the cover's bottom edge and the counts
          // indented past it. Mirrors ProfileBanner.height and _avatarSlot —
          // this file is core and must not import a feature, so the numbers
          // are repeated rather than shared, and a change there wants a
          // change here.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SkeletonBox(height: 140, radius: 0),
                  Container(
                    color: c.surface,
                    padding: const EdgeInsets.fromLTRB(
                      RungSpace.gutter,
                      RungSpace.sm,
                      RungSpace.gutter,
                      RungSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 88 + RungSpace.sm,
                          ),
                          child: Row(
                            children: [
                              // Posts / followers / following.
                              for (var i = 0; i < 3; i++)
                                const Expanded(
                                  child: Column(
                                    children: [
                                      SkeletonBox(
                                        width: 34,
                                        height: 15,
                                        radius: 6,
                                      ),
                                      SizedBox(height: 6),
                                      SkeletonBox(width: 48, height: 10),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: RungSpace.md),
                        const SkeletonBox(width: 170, height: 15, radius: 7),
                        const SizedBox(height: RungSpace.xs),
                        const SkeletonBox(width: 220, height: 11),
                        const SizedBox(height: 7),
                        const SkeletonBox(height: 11),
                        const SizedBox(height: 7),
                        const SkeletonBox(width: 190, height: 11),
                        const SizedBox(height: RungSpace.md),
                        const Row(
                          children: [
                            Expanded(child: SkeletonBox(height: 34, radius: 9)),
                            SizedBox(width: RungSpace.xs),
                            Expanded(child: SkeletonBox(height: 34, radius: 9)),
                            SizedBox(width: RungSpace.xs),
                            SkeletonBox(width: 40, height: 34, radius: 9),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const PositionedDirectional(
                start: RungSpace.gutter,
                top: 140 - 44,
                child: SkeletonBox(
                  width: 88,
                  height: 88,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          // The tab strip.
          Container(
            color: c.surface,
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: RungSpace.gutter),
            child: const Row(
              children: [
                Expanded(
                  child: Center(child: SkeletonBox(width: 54, height: 11)),
                ),
                Expanded(
                  child: Center(child: SkeletonBox(width: 54, height: 11)),
                ),
                Expanded(
                  child: Center(child: SkeletonBox(width: 54, height: 11)),
                ),
              ],
            ),
          ),
          // The posts grid: three across, square, one-pixel gutters.
          GridView.builder(
            padding: const EdgeInsets.all(1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 9,
            // The grid constrains each cell tightly, so the box fills it
            // whatever height it asks for.
            itemBuilder: (_, __) => const SkeletonBox(radius: 0),
          ),
        ],
      ),
    );
  }
}

/// A conversation: bubbles alternating sides.
class MessageThreadSkeleton extends StatelessWidget {
  const MessageThreadSkeleton({super.key, this.count = 7});

  final int count;

  @override
  Widget build(BuildContext context) {
    // Widths vary so it reads as speech rather than as a column of bars.
    const widths = <double>[170, 120, 220, 96, 190, 140, 210];
    return RungSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(RungSpace.sm),
        itemCount: count,
        itemBuilder: (_, i) => Align(
          alignment: i.isEven
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: SkeletonBox(
              width: widths[i % widths.length],
              height: 38,
              radius: RungRadius.md,
            ),
          ),
        ),
      ),
    );
  }
}

/// The dashboard's tile grid.
class TileGridSkeleton extends StatelessWidget {
  const TileGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RungSkeleton(
      child: GridView.builder(
        padding: const EdgeInsets.all(RungSpace.gutter),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: RungSpace.sm,
          crossAxisSpacing: RungSpace.sm,
          childAspectRatio: 1.35,
        ),
        itemCount: count,
        itemBuilder: (_, __) =>
            const SkeletonBox(height: double.infinity, radius: RungRadius.md),
      ),
    );
  }
}

/// Reels is a full-bleed dark surface, so it gets its own greys rather than the
/// theme's — the page neutrals are tuned for a light background and would read
/// as bright panels over black.
class ReelsSkeleton extends StatelessWidget {
  const ReelsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B0B0F),
      child: Stack(
        children: [
          const Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF3A3A44),
              ),
            ),
          ),
          PositionedDirectional(
            start: RungSpace.gutter,
            end: 72,
            bottom: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _dark(36, 36, circle: true),
                    const SizedBox(width: 10),
                    _dark(120, 12),
                  ],
                ),
                const SizedBox(height: RungSpace.sm),
                _dark(double.infinity, 10),
                const SizedBox(height: 7),
                _dark(180, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dark(double w, double h, {bool circle = false}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFF23232B),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(6),
    ),
  );
}
