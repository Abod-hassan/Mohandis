import 'package:flutter_mobile_template/core/base/base_dto.dart';
import 'package:flutter_mobile_template/features/shared/people/data/dtos/person_dto.dart';

import '../../domain/entities/connection_request.dart';

/// Wire model for one row of `GET /api/social/Connections/requests`.
///
/// The module does not have a "connection request" DTO: `ConnectionService`
/// resolves the pending edges to their requesters and projects those to
/// `ProfileSimplifiedDto`, so a row here *is* a profile. This type exists to
/// keep that fact in one place rather than scattering `PersonDto` through the
/// network repository.
class ConnectionRequestDto implements BaseDto<ConnectionRequest> {
  const ConnectionRequestDto({required this.person});

  factory ConnectionRequestDto.fromJson(Map<String, dynamic> json) =>
      ConnectionRequestDto(person: PersonDto.fromJson(json));

  final PersonDto person;

  @override
  ConnectionRequest toDomain() =>
      ConnectionRequest(person: person.toDomain());

  @override
  Map<String, dynamic> toJson() => person.toJson();
}
