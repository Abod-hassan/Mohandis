import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/features/jobs/data/repositories/job_mock_repository.dart';
import 'package:mohandis/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:mohandis/features/jobs/domain/entities/job.dart';
import 'package:mohandis/features/jobs/domain/entities/job_application.dart';
import 'package:mohandis/features/jobs/domain/repositories/job_repository.dart';
import 'package:mohandis/features/jobs/presentation/notifiers/jobs_notifier.dart';

ProviderContainer buildContainer() {
  final container = ProviderContainer(
    overrides: [
      jobRepositoryProvider.overrideWithValue(
        JobMockRepository(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ApplicationsNotifier', () {
    test('loads seeded applications', () async {
      final container = buildContainer();

      final apps = await container.read(applicationsNotifierProvider.future);

      expect(apps, hasLength(2));
      expect(apps.map((a) => a.jobId), containsAll(['j6', 'j2']));
    });

    test('apply prepends the new application', () async {
      final container = buildContainer();
      await container.read(applicationsNotifierProvider.future);

      final result =
          await container.read(applicationsNotifierProvider.notifier).apply(
                jobId: 'j1',
                resumeUrl: 'cv/cv.pdf',
                coverLetter: 'مرحباً',
              );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, ApplicationStatus.submitted);

      final apps = container.read(applicationsNotifierProvider).valueOrNull!;
      expect(apps.first.jobId, 'j1');
      expect(container.read(applicationsByJobProvider).containsKey('j1'), isTrue);
    });

    test('applying twice to the same job is rejected', () async {
      final container = buildContainer();
      await container.read(applicationsNotifierProvider.future);

      final result =
          await container.read(applicationsNotifierProvider.notifier).apply(
                jobId: 'j6',
                resumeUrl: 'cv/cv.pdf',
              );

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ValidationException>());
    });
  });

  group('JobFilters', () {
    test('carries only what was set', () {
      // The wire translation lives in JobRepositoryImpl._filterBody now — the
      // filters object is the UI's state, not a query string.
      const empty = JobFilters();
      expect(empty.query, isEmpty);
      expect(empty.workMode, isNull);

      const set = JobFilters(query: 'مصمم', workMode: WorkMode.remote);
      expect(set.query, 'مصمم');
      expect(set.workMode, WorkMode.remote);
    });

    test('clearWorkMode resets the filter rather than keeping the old value', () {
      const filters = JobFilters(workMode: WorkMode.hybrid);
      expect(filters.copyWith(clearWorkMode: true).workMode, isNull);
    });
  });

  group('ApplicationStatus', () {
    test('accepted and rejected share the final stepper index', () {
      expect(ApplicationStatus.accepted.stepIndex, 4);
      expect(ApplicationStatus.rejected.stepIndex, 4);
      expect(ApplicationStatus.submitted.stepIndex, 0);
    });

    test('isDecided is true only for terminal outcomes', () {
      expect(ApplicationStatus.accepted.isDecided, isTrue);
      expect(ApplicationStatus.rejected.isDecided, isTrue);
      expect(ApplicationStatus.interview.isDecided, isFalse);
    });
  });
}
