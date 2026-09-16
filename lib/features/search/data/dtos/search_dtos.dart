import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/features/shared/people/data/dtos/person_dto.dart';

import '../../domain/entities/search_results.dart';
import '../../domain/entities/trending_tag.dart';

/// Wire model for the module's `HashtagDto` — `GET Hashtags/trending` and the
/// `Hashtags` search scope both return rows of this shape.
class HashtagDto implements BaseDto<TrendingTag> {
  const HashtagDto({required this.tag, required this.postCount});

  factory HashtagDto.fromJson(Map<String, dynamic> json) => HashtagDto(
    tag: '${json['tag'] ?? ''}',
    postCount: (json['postCount'] as num?)?.toInt() ?? 0,
  );

  /// The tag **without** its `#`, lower-cased: the module's parser captures
  /// only what follows the hash (`TextParsing.HashtagRx`) and that is what the
  /// Hashtags table stores.
  final String tag;

  final int postCount;

  @override
  TrendingTag toDomain() => TrendingTag(
    // Rows render the tag verbatim, and hashtags everywhere else in the app
    // carry their `#` (posts keep it in the body text), so it is put back once
    // here rather than in each widget that shows one.
    tag: tag.startsWith('#') ? tag : '#$tag',
    postCount: postCount,
  );

  @override
  Map<String, dynamic> toJson() => {'tag': tag, 'postCount': postCount};
}

/// Wire model for `SearchResultDto` — the blended `GET /api/social/Search`.
///
/// Only the two lists the search screen can render are decoded; see
/// [SearchResults] for why `posts`, `reels` and `jobs` are left on the wire.
class SearchResultsDto implements BaseDto<SearchResults> {
  const SearchResultsDto({this.profiles = const [], this.hashtags = const []});

  factory SearchResultsDto.fromJson(Map<String, dynamic> json) =>
      SearchResultsDto(
        profiles: rowsOf(
          json['profiles'],
        ).map(PersonDto.fromJson).toList(growable: false),
        hashtags: rowsOf(
          json['hashtags'],
        ).map(HashtagDto.fromJson).toList(growable: false),
      );

  /// People arrive as `ProfileSimplifiedDto`, the same projection the people
  /// directory is built from — hence the shared [PersonDto].
  final List<PersonDto> profiles;

  final List<HashtagDto> hashtags;

  @override
  SearchResults toDomain() => SearchResults(
    people: profiles.map((p) => p.toDomain()).toList(growable: false),
    tags: hashtags.map((h) => h.toDomain()).toList(growable: false),
  );

  /// Search is read-only — nothing sends a `SearchResultDto` back — so this
  /// exists to satisfy [BaseDto], which declares `toJson` but is implemented
  /// rather than extended here and so hands down no body. Round-trips the two
  /// lists it decodes.
  @override
  Map<String, dynamic> toJson() => {
    'profiles': profiles.map((p) => p.toJson()).toList(growable: false),
    'hashtags': hashtags.map((h) => h.toJson()).toList(growable: false),
  };

  /// Reads one named list out of a `SearchResultDto` / `SearchPageDto`.
  ///
  /// **Both are objects, not arrays.** The scoped endpoint answers a
  /// `SearchPageDto` carrying one populated list per scope, so `envelope.list`
  /// would wrap the whole object into a single row instead of reading the
  /// results — every search read has to go through `envelope.object` and pick
  /// its list out by name. Trending hashtags are the one exception: that
  /// payload really is a bare array.
  static List<Map<String, dynamic>> rowsOf(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }
}
