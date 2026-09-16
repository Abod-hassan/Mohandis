import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

import 'trending_tag.dart';

/// One blended search response — `GET /api/social/Search`, the "landing page"
/// shape with a few of every kind at once.
///
/// The endpoint also returns matching posts, reels and jobs. They are
/// deliberately not carried here: the search screen has no row that can render
/// a post or a reel, and a `Job` is built by the jobs feature's repository so
/// that there is one place it comes from. Add them when there is a card to put
/// them in — the wire already has them.
class SearchResults {
  const SearchResults({this.people = const [], this.tags = const []});

  final List<Person> people;
  final List<TrendingTag> tags;
}
