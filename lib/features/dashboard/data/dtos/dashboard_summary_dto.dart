import 'package:flutter_mobile_template/core/base/base_dto.dart';

import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryDto implements BaseDto<DashboardSummary> {
  const DashboardSummaryDto({
    required this.courseTitle,
    required this.currentLecture,
    required this.totalLectures,
    required this.activeCourses,
    required this.learningHours,
    required this.certificates,
    required this.newTheoryCount,
    required this.newPracticalCount,
    required this.newTrainingCount,
    required this.libraryAvailable,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    final p = progress is Map<String, dynamic> ? progress : const {};
    return DashboardSummaryDto(
      courseTitle: '${p['courseTitle'] ?? ''}',
      currentLecture: (p['currentLecture'] as num?)?.toInt() ?? 0,
      totalLectures: (p['totalLectures'] as num?)?.toInt() ?? 0,
      activeCourses: (json['activeCourses'] as num?)?.toInt() ?? 0,
      learningHours: (json['learningHours'] as num?)?.toInt() ?? 0,
      certificates: (json['certificates'] as num?)?.toInt() ?? 0,
      newTheoryCount: (json['newTheoryCount'] as num?)?.toInt() ?? 0,
      newPracticalCount: (json['newPracticalCount'] as num?)?.toInt() ?? 0,
      newTrainingCount: (json['newTrainingCount'] as num?)?.toInt() ?? 0,
      libraryAvailable: json['libraryAvailable'] == true,
    );
  }

  final String courseTitle;
  final int currentLecture;
  final int totalLectures;
  final int activeCourses;
  final int learningHours;
  final int certificates;
  final int newTheoryCount;
  final int newPracticalCount;
  final int newTrainingCount;
  final bool libraryAvailable;

  @override
  DashboardSummary toDomain() => DashboardSummary(
        progress: LearningProgress(
          courseTitle: courseTitle,
          currentLecture: currentLecture,
          totalLectures: totalLectures,
        ),
        activeCourses: activeCourses,
        learningHours: learningHours,
        certificates: certificates,
        newTheoryCount: newTheoryCount,
        newPracticalCount: newPracticalCount,
        newTrainingCount: newTrainingCount,
        libraryAvailable: libraryAvailable,
      );

  @override
  Map<String, dynamic> toJson() => {
        'progress': {
          'courseTitle': courseTitle,
          'currentLecture': currentLecture,
          'totalLectures': totalLectures,
        },
        'activeCourses': activeCourses,
        'learningHours': learningHours,
        'certificates': certificates,
        'newTheoryCount': newTheoryCount,
        'newPracticalCount': newPracticalCount,
        'newTrainingCount': newTrainingCount,
        'libraryAvailable': libraryAvailable,
      };
}
