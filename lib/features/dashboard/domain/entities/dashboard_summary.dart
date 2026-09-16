import 'package:flutter_mobile_template/core/base/base_entity.dart';

/// The lecture the engineer last left off in, shown as the continue-learning
/// card at the top of the panel.
class LearningProgress {
  const LearningProgress({
    required this.courseTitle,
    required this.currentLecture,
    required this.totalLectures,
  });

  final String courseTitle;
  final int currentLecture;
  final int totalLectures;

  /// 0–1, guarded against a zero total so a malformed payload can't divide
  /// by zero inside the progress bar.
  double get fraction =>
      totalLectures <= 0 ? 0 : (currentLecture / totalLectures).clamp(0, 1);
}

/// Engineer-panel summary: the continue-learning card, the headline stats,
/// and the per-section "new item" counts that drive the row badges.
class DashboardSummary extends BaseEntity {
  const DashboardSummary({
    required this.progress,
    required this.activeCourses,
    required this.learningHours,
    required this.certificates,
    this.newTheoryCount = 0,
    this.newPracticalCount = 0,
    this.newTrainingCount = 0,
    this.libraryAvailable = false,
  });

  @override
  String get id => 'dashboard';

  final LearningProgress progress;
  final int activeCourses;
  final int learningHours;
  final int certificates;
  final int newTheoryCount;
  final int newPracticalCount;
  final int newTrainingCount;

  /// The engineering library ships later; until then the row renders in a
  /// disabled "قريباً" state.
  final bool libraryAvailable;
}
