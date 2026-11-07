import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';

import '../../domain/entities/connection_request.dart';
import '../../domain/entities/people_list_kind.dart';
import '../../domain/repositories/network_repository.dart';

class NetworkMockRepository implements NetworkRepository {
  NetworkMockRepository({this.latency = const Duration(milliseconds: 220)})
      : _requests = _seed();

  final Duration latency;
  final List<ConnectionRequest> _requests;

  /// Nobody here also has a pending request in [_seed]: the real repository
  /// removes pending requesters from the pool, and a mock that shows the same
  /// person as both a request row and an "add" tile would be rehearsing a
  /// state the backend cannot produce.
  static const List<Person> _suggestions = [
    Person(
      id: 'dawood',
      name: 'داوود العلي',
      firstName: 'داوود',
      headline: 'مهندس مدني',
      location: 'دمشق',
    ),
    Person(
      id: 'reem',
      name: 'ريم حداد',
      firstName: 'ريم',
      headline: 'مهندسة معمارية',
      location: 'حلب',
    ),
    Person(
      id: 'yara',
      name: 'يارا منصور',
      firstName: 'يارا',
      headline: 'مهندسة برمجيات',
      location: 'اللاذقية',
    ),
    Person(
      id: 'nour',
      name: 'نور الدين حلاق',
      firstName: 'نور',
      headline: 'مهندس ميكانيك',
      location: 'طرطوس',
    ),
  ];

  Future<void> _wait() => Future<void>.delayed(latency);

  static List<ConnectionRequest> _seed() {
    return const [
      ConnectionRequest(
        person: Person(
          id: 'sara',
          name: 'سارة خليل',
          firstName: 'سارة',
          headline: 'مهندسة مدنية',
          location: 'دمشق',
        ),
      ),
      ConnectionRequest(
        person: Person(
          id: 'lina',
          name: 'لينا يوسف',
          firstName: 'لينا',
          headline: 'مديرة مشاريع',
          location: 'حلب',
        ),
      ),
      ConnectionRequest(
        person: Person(
          id: 'kareem',
          name: 'كريم سعيد',
          firstName: 'كريم',
          headline: 'مهندس كهرباء',
          location: 'حمص',
        ),
      ),
    ].toList();
  }

  @override
  Future<Result<List<ConnectionRequest>, AppException>> requests() async {
    await _wait();
    return Result.success(List.unmodifiable(_requests));
  }

  @override
  Future<List<Person>> suggestions({required Set<String> exclude}) async {
    await _wait();
    return _suggestions.where((p) => !exclude.contains(p.id)).toList();
  }

  @override
  Future<Result<void, AppException>> accept(String personId) => _remove(personId);

  @override
  Future<Result<void, AppException>> ignore(String personId) => _remove(personId);

  @override
  Future<Result<void, AppException>> connect(String personId) async {
    await _wait();
    return const Result.success(null);
  }

  Future<Result<void, AppException>> _remove(String personId) async {
    await _wait();
    _requests.removeWhere((r) => r.personId == personId);
    return const Result.success(null);
  }

  /// Seeded from [_suggestions] so every kind has rows to render. The mock
  /// keeps its own removable copy per kind — otherwise unfollowing in the
  /// design preview would mutate the suggestions grid as a side effect.
  final Map<PeopleListKind, List<Person>> _people = {
    for (final k in PeopleListKind.values) k: List<Person>.of(_suggestions),
  };

  @override
  Future<Result<List<Person>, AppException>> people({
    required PeopleListKind kind,
    required String profileId,
    int page = 1,
    int size = 100,
  }) async {
    await Future<void>.delayed(latency);
    return Result.success(List<Person>.unmodifiable(_people[kind]!));
  }

  @override
  Future<Result<void, AppException>> removeConnection(String personId) async {
    await Future<void>.delayed(latency);
    _people[PeopleListKind.connections]!.removeWhere((p) => p.id == personId);
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppException>> unfollow(String personId) async {
    await Future<void>.delayed(latency);
    _people[PeopleListKind.following]!.removeWhere((p) => p.id == personId);
    return const Result.success(null);
  }
}
