import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/jobs/data/repositories/job_mock_repository.dart';
import 'package:flutter_mobile_template/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:flutter_mobile_template/features/jobs/domain/entities/job.dart';
import 'package:flutter_mobile_template/features/jobs/domain/entities/job_application.dart';
import 'package:flutter_mobile_template/features/jobs/domain/repositories/job_repository.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/screens/jobs_screen.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/widgets/job_card.dart';

import '../../support/pump_rung.dart';

/// Repository whose every read fails — drives the error branch.
class _FailingJobRepository implements JobRepository {
  static const _error = ServerException('down');

  @override
  Future<Result<List<Job>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async =>
      const Result.failure(_error);

  @override
  Future<Result<List<Job>, AppException>> search(JobFilters filters) async =>
      const Result.failure(_error);

  @override
  Future<Result<Job, AppException>> getById(String id) async =>
      const Result.failure(_error);

  @override
  Future<Result<List<JobApplication>, AppException>> applications() async =>
      const Result.failure(_error);

  @override
  Future<Result<List<Job>, AppException>> saved() async =>
      const Result.failure(_error);

  @override
  Future<Result<Job, AppException>> toggleSave(String jobId) async =>
      const Result.failure(_error);

  @override
  Future<Result<JobApplication, AppException>> apply({
    required String jobId,
    String? resumeUrl,
    String coverLetter = '',
  }) async =>
      const Result.failure(_error);

  @override
  Future<Result<List<Job>, AppException>> postedBy(String profileId) async =>
      const Result.failure(_error);

  @override
  Future<Result<List<JobApplication>, AppException>> applicants(
    String jobId,
  ) async =>
      const Result.failure(_error);

  @override
  Future<Result<bool, AppException>> setApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async =>
      const Result.failure(_error);

  @override
  Future<Result<Job, AppException>> publish({
    required String title,
    required String company,
    String? location,
    EmploymentType? employmentType,
    WorkMode? workMode,
    String description = '',
    String? requirements,
    num? salaryMin,
    num? salaryMax,
    String? currency,
  }) async =>
      const Result.failure(_error);

  @override
  Future<Result<Job, AppException>> create(Map<String, dynamic> body) async =>
      const Result.failure(_error);

  @override
  Future<Result<Job, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      const Result.failure(_error);

  @override
  Future<Result<void, AppException>> delete(String id) async =>
      const Result.failure(_error);
}

void main() {
  group('JobsScreen', () {
    testWidgets('renders the loading branch before results land',
        (tester) async {
      await pumpRung(
        tester,
        const JobsScreen(),
        overrides: [
          jobRepositoryProvider.overrideWithValue(
            JobMockRepository(latency: const Duration(milliseconds: 50)),
          ),
        ],
      );

      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);

      // Let the pending repository future settle before the test ends.
      await tester.pumpAndSettle();
    });

    testWidgets('renders the data branch as job cards', (tester) async {
      await pumpRung(
        tester,
        const JobsScreen(),
        overrides: [
          jobRepositoryProvider.overrideWithValue(
            JobMockRepository(latency: Duration.zero),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(JobCard), findsWidgets);
      expect(find.text('مصمم منتجات أول'), findsOneWidget);
      expect(find.text('الوظائف'), findsOneWidget);
    });

    testWidgets('renders the error branch with a retry affordance',
        (tester) async {
      await pumpRung(
        tester,
        const JobsScreen(),
        overrides: [
          jobRepositoryProvider.overrideWithValue(_FailingJobRepository()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      // Raw backend text must never surface (ARCHITECTURE.md §9.6).
      expect(find.text('down'), findsNothing);
    });

    testWidgets('work-mode chips filter the list', (tester) async {
      await pumpRung(
        tester,
        const JobsScreen(),
        overrides: [
          jobRepositoryProvider.overrideWithValue(
            JobMockRepository(latency: Duration.zero),
          ),
        ],
      );
      await tester.pumpAndSettle();

      final beforeCount = tester.widgetList(find.byType(JobCard)).length;

      // "عن بُعد" also appears as a card tag, so scope the tap to the chip row.
      await tester.tap(
        find.descendant(
          of: find.byType(RungFilterChip),
          matching: find.text('عن بُعد'),
        ),
      );
      await tester.pumpAndSettle();

      final remote = tester.widgetList<JobCard>(find.byType(JobCard));
      expect(remote, isNotEmpty);
      expect(remote.length, lessThan(beforeCount));
      expect(
        remote.every((card) => card.job.workMode == WorkMode.remote),
        isTrue,
      );
    });
  });
}
