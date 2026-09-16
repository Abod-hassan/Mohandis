import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardMockRepository implements DashboardRepository {
  DashboardMockRepository({this.latency = const Duration(milliseconds: 220)});

  final Duration latency;

  @override
  Future<Result<DashboardSummary, AppException>> summary() async {
    await Future<void>.delayed(latency);
    return const Result.success(
      DashboardSummary(
        progress: LearningProgress(
          courseTitle: 'أساسيات التصميم الإنشائي',
          currentLecture: 4,
          totalLectures: 8,
        ),
        activeCourses: 8,
        learningHours: 42,
        certificates: 3,
        newTheoryCount: 2,
        newPracticalCount: 2,
        newTrainingCount: 2,
      ),
    );
  }
}
