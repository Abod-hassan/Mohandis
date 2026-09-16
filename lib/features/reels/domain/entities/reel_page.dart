import 'reel.dart';

/// One page of the reel wall.
///
/// `ReelFilter` is page-numbered, not cursor-paged, so the page index is all
/// the caller has to carry — [hasMore] is what says whether there is another
/// one. The row count is not: the server can answer with fewer rows than the
/// size it was asked for.
class ReelPage {
  const ReelPage({required this.reels, required this.hasMore});

  static const ReelPage empty = ReelPage(reels: [], hasMore: false);

  final List<Reel> reels;

  /// `IPagedList.HasNextPage`, off the envelope rather than out of `data`.
  final bool hasMore;
}
