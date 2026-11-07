import 'package:mohandis/core/base/base_dto.dart';
import 'package:mohandis/features/profile/data/dtos/profile_dto.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../../domain/entities/person.dart';

/// Wire model for the backend's `ProfileSimplifiedDto` — the light projection
/// `POST /api/social/Profiles` returns with `detailed=false`, and what the
/// follower / following / search lists are made of.
///
/// Field names are the module's, not the mobile entity's: the display name is
/// `displayName` and the verified flag is `isVerified`. There is no location on
/// this projection — it lives on the full `ProfileDto` — so directory entries
/// carry an empty location rather than a wrong one.
class PersonDto implements BaseDto<Person> {
  const PersonDto({
    required this.id,
    required this.displayName,
    this.username = '',
    this.headline,
    this.avatarUrl,
    this.isVerified = false,
    this.isSubscribed = false,
    this.isOnline = false,
    this.location,
    this.accountType = AccountType.individual,
  });

  factory PersonDto.fromJson(Map<String, dynamic> json) => PersonDto(
    id: '${json['id'] ?? ''}',
    displayName: '${json['displayName'] ?? ''}',
    username: '${json['username'] ?? ''}',
    headline: json['headline'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    isVerified: json['isVerified'] == true,
    isSubscribed: json['isSubscribed'] == true,
    isOnline: json['isOnline'] == true,
    // On the simplified projection as well as the detailed one — see
    // `ProfileSimplifiedDto.AccountType`. Parsed through `ProfileDto`'s
    // mapping so the name and the ordinal are both understood, and so the
    // spelling lives in one place.
    //
    // The WHOLE enum, not the "is this a business?" boolean it used to be
    // collapsed to: most screens want only the boolean (`Person.isCompany`
    // still gives it), but "may this account publish a course?" is a question
    // about the kind, and flattening here made it unanswerable.
    accountType: ProfileDto.accountTypeFromWire(json['accountType']),
    // Only present when the caller asked for the detailed projection.
    location: json['location'] as String?,
  );

  final String id;
  final String username;
  final String displayName;
  final String? headline;
  final String? avatarUrl;
  final bool isVerified;
  final bool isSubscribed;
  final bool isOnline;
  final String? location;
  final AccountType accountType;

  @override
  Person toDomain() => Person(
    id: id,
    name: displayName,
    username: username,
    // The module has no separate given name; the first token is the closest
    // thing, and it is what the story rail and toasts want.
    firstName: displayName.trim().split(RegExp(r'\s+')).first,
    headline: headline ?? '',
    location: location ?? '',
    verified: isVerified,
    subscribed: isSubscribed,
    avatarUrl: avatarUrl,
    accountType: accountType,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'headline': headline,
    'avatarUrl': avatarUrl,
    'isVerified': isVerified,
    'isSubscribed': isSubscribed,
    // The real kind now, so a cached copy read back is the account it was.
    // Nothing ships this to the server — the profile write carries the type —
    // but a contractor used to come back out of here as a company.
    'accountType': ProfileDto.accountTypeToWire(accountType),
  };
}
