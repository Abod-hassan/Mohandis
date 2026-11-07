import 'package:mohandis/core/base/base_repository.dart';
import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';

import '../entities/person.dart';

/// Directory of people. Every social surface resolves author / participant /
/// suggestion ids through this repository rather than embedding a copy of
/// the person record in its own payload.
abstract class PeopleRepository extends BaseRepository<Person> {
  /// The signed-in user. Distinct from [getById] because the backend
  /// resolves it from the bearer token, not an id.
  Future<Result<Person, AppException>> me();

  /// Free-text search across name and headline, optionally limited to one
  /// kind of account.
  Future<Result<List<Person>, AppException>> search(
    String query, {
    AccountType? accountType,
  });
}
