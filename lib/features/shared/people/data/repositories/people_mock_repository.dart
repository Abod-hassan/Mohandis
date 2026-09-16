import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../domain/entities/person.dart';
import '../../domain/repositories/people_repository.dart';

/// In-memory people directory used while the backend is being built
/// (`AppConfig.useMockData`). Every other mock repository references these
/// ids, so this is the single source of truth for the demo cast.
class PeopleMockRepository implements PeopleRepository {
  PeopleMockRepository({this.latency = const Duration(milliseconds: 220)});

  final Duration latency;

  static const String meId = 'me';

  static const List<Person> seed = [
    Person(
      id: meId,
      name: 'يوسف الحربي',
      firstName: 'أنت',
      headline: 'مصمم منتجات أول · التقنية المالية',
      location: 'الرياض، السعودية',
      verified: true,
    ),
    Person(
      id: 'amal',
      name: 'أمل العتيبي',
      firstName: 'أمل',
      headline: 'مديرة هندسة في نورثويند',
      location: 'جدة، السعودية',
      verified: true,
    ),
    Person(
      id: 'dawood',
      name: 'داوود الشمري',
      firstName: 'داوود',
      headline: 'أخصائي توظيف تقني · تالنت فورج',
      location: 'عن بُعد',
    ),
    Person(
      id: 'reem',
      name: 'ريم القحطاني',
      firstName: 'ريم',
      headline: 'عالمة بيانات أولى · هيلكس بايو',
      location: 'الخبر، السعودية',
      verified: true,
    ),
    Person(
      id: 'marwan',
      name: 'مروان الزهراني',
      firstName: 'مروان',
      headline: 'مؤسس ورئيس تنفيذي، لوب ورك',
      location: 'دبي، الإمارات',
      verified: true,
    ),
    Person(
      id: 'sara',
      name: 'سارة الدوسري',
      firstName: 'سارة',
      headline: 'باحثة تجربة مستخدم · التقنية الصحية',
      location: 'المنامة، البحرين',
    ),
    Person(
      id: 'lina',
      name: 'لينا الفيصل',
      firstName: 'لينا',
      headline: 'ممارِسة تمريض · أمراض القلب',
      location: 'الدمام، السعودية',
    ),
    Person(
      id: 'kareem',
      name: 'كريم منصور',
      firstName: 'كريم',
      headline: 'مهندس مدني · البنية التحتية',
      location: 'القاهرة، مصر',
    ),
    Person(
      id: 'yara',
      name: 'يارا التميمي',
      firstName: 'يارا',
      headline: 'استراتيجية علامة تجارية · المستهلك',
      location: 'الكويت',
    ),
  ];

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<Result<List<Person>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    await _wait();
    final q = '${query?['q'] ?? ''}'.trim();
    if (q.isEmpty) return const Result.success(seed);
    return Result.success(_match(q));
  }

  @override
  Future<Result<Person, AppException>> getById(String id) async {
    await _wait();
    final match = seed.where((p) => p.id == id);
    if (match.isEmpty) {
      return Result.failure(NotFoundException('لا يوجد شخص بالمعرف $id'));
    }
    return Result.success(match.first);
  }

  @override
  Future<Result<Person, AppException>> me() async {
    await _wait();
    return Result.success(seed.firstWhere((p) => p.id == meId));
  }

  @override
  Future<Result<List<Person>, AppException>> search(String query) async {
    await _wait();
    return Result.success(_match(query));
  }

  List<Person> _match(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return seed.where((p) => p.id != meId).toList();
    return seed
        .where((p) => p.id != meId)
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.headline.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Future<Result<Person, AppException>> create(Map<String, dynamic> body) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));

  @override
  Future<Result<Person, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));

  @override
  Future<Result<void, AppException>> delete(String id) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));
}
