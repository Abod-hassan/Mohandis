import 'package:flutter_mobile_template/core/base/base_entity.dart';

/// A person on Rung. Deliberately thin — it carries only what the feed,
/// messaging, search, and network surfaces render. The full CV-style record
/// lives in the profile feature's `Profile` entity.
class Person extends BaseEntity {
  const Person({
    required this.id,
    required this.name,
    required this.firstName,
    required this.headline,
    this.username = '',
    required this.location,
    this.verified = false,
    this.isCompany = false,
    this.avatarUrl,
  });

  @override
  final String id;

  final String name;

  /// The handle, without the leading `@`.
  ///
  /// Carried on this thin entity because a mention is written as `@username`
  /// and the server parses it back out of the text — so the composer has to
  /// insert the EXACT handle, and a near-miss silently becomes plain words with
  /// no notification sent. Empty on a row whose source did not send one.
  final String username;

  /// Short form used in toasts and story labels ("أمل").
  final String firstName;

  final String headline;
  final String location;
  final bool verified;

  /// True when this row is a company rather than a person.
  ///
  /// A company is FOLLOWED, never connected with — the two graphs mean
  /// different things and the server refuses the mismatch — so every surface
  /// that offers a Connect button has to know which it is looking at. Carried
  /// on `ProfileSimplifiedDto` for exactly that reason.
  final bool isCompany;

  /// The photo as the server stores it — a host-less path, not a URL.
  ///
  /// Every surface that renders a person goes through `imageUrlResolverProvider`
  /// to make it loadable. It lives on this thin entity rather than only on the
  /// full `Profile` because the feed, search, messages and notifications all
  /// draw an avatar and none of them loads a profile to do it.
  final String? avatarUrl;

  /// Two-letter monogram for the avatar, derived from the display name.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.characters2;
    return '${parts.first.characters2[0]}${parts.last.characters2[0]}';
  }

  Person copyWith({
    String? name,
    String? firstName,
    String? headline,
    String? location,
    bool? verified,
    String? avatarUrl,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      verified: verified ?? this.verified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

extension on String {
  /// First two characters, or the whole string when shorter.
  String get characters2 => length <= 2 ? this : substring(0, 2);
}
