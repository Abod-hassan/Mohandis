import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/features/profile/data/dtos/profile_dto.dart';
import 'package:flutter_mobile_template/features/profile/domain/entities/profile.dart';

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
    this.isOnline = false,
    this.location,
    this.isCompany = false,
  });

  factory PersonDto.fromJson(Map<String, dynamic> json) => PersonDto(
    id: '${json['id'] ?? ''}',
    displayName: '${json['displayName'] ?? ''}',
    username: '${json['username'] ?? ''}',
    headline: json['headline'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    isVerified: json['isVerified'] == true,
    isOnline: json['isOnline'] == true,
    // On the simplified projection as well as the detailed one — see
    // `ProfileSimplifiedDto.AccountType`. Parsed through `ProfileDto`'s
    // mapping so the name and the ordinal are both understood, and so the
    // spelling lives in one place.
    isCompany:
        ProfileDto.accountTypeFromWire(json['accountType']) ==
        AccountType.company,
    // Only present when the caller asked for the detailed projection.
    location: json['location'] as String?,
  );

  final String id;
  final String username;
  final String displayName;
  final String? headline;
  final String? avatarUrl;
  final bool isVerified;
  final bool isOnline;
  final String? location;
  final bool isCompany;

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
    avatarUrl: avatarUrl,
    isCompany: isCompany,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'headline': headline,
    'avatarUrl': avatarUrl,
    'isVerified': isVerified,
    'accountType': ProfileDto.accountTypeToWire(
      isCompany ? AccountType.company : AccountType.individual,
    ),
  };
}
