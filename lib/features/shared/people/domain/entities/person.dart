import 'package:mohandis/core/base/base_entity.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

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
    this.subscribed = false,
    this.accountType = AccountType.individual,
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

  /// Holds a live subscription — what draws the subscriber badge.
  ///
  /// Separate from [verified], and never folded into it. One says a human at
  /// this company decided this account is who it claims to be; the other says
  /// the account is paying. Collapsing them would quietly redefine the first
  /// claim as the second, and an account that lost its subscription would then
  /// appear to have lost its verification.
  final bool subscribed;

  /// What KIND of account this is — مهندس، شركة، مقاول، حرفي، صاحب آلية.
  ///
  /// The whole enum, not the boolean it used to be. Most surfaces only ask
  /// "is this a business?" (a business is FOLLOWED, never connected with — the
  /// two graphs mean different things and the server refuses the mismatch), and
  /// [isCompany] still answers exactly that. But some questions need the kind:
  /// only an engineer or a company may publish a course, and a contractor is a
  /// business that may not. Collapsing to a boolean here is what made those
  /// unanswerable without loading the full profile.
  final AccountType accountType;

  /// Whether this row is a business rather than a person. The coarse reading
  /// of [accountType], kept under its old name because nearly every caller
  /// wants exactly this and nothing finer.
  bool get isCompany => accountType.isBusiness;

  /// Whether this account may write and sell a course.
  ///
  /// An engineer teaches as a credential and a company as a service. The three
  /// in between — مقاول، حرفي، صاحب آلية — are businesses that hire and are
  /// hired; the server refuses a course from them, so no screen should offer
  /// one. The rule is stated here, beside the type, rather than in each screen
  /// that asks.
  bool get canPublishCourses =>
      accountType == AccountType.individual ||
      accountType == AccountType.company;

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
    bool? subscribed,
    String? avatarUrl,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      verified: verified ?? this.verified,
      subscribed: subscribed ?? this.subscribed,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      // Carried through: dropping them made a copy lose its @handle (so it
      // could no longer be mentioned) and read as a person, not a business.
      username: username,
      accountType: accountType,
    );
  }
}

extension on String {
  /// First two characters, or the whole string when shorter.
  String get characters2 => length <= 2 ? this : substring(0, 2);
}
