import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    final result = await ref.read(dashboardRepositoryProvider).summary();
    return result.when(success: (s) => s, failure: (e) => throw e);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(dashboardRepositoryProvider).summary();
      return result.when(success: (s) => s, failure: (e) => throw e);
    });
  }
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(
  DashboardNotifier.new,
);
