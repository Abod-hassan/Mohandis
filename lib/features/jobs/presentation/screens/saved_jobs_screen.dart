import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../notifiers/saved_jobs_notifier.dart';
import '../widgets/job_card.dart';

/// The jobs this person bookmarked.
///
/// Reads `onlySaved` with `openOnly: false`, so a posting that has closed since
/// it was saved still appears — the detail screen is what says it is closed,
/// and dropping it from this list silently would read as a lost bookmark.
class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final saved = ref.watch(savedJobsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.savedJobsTitle),
      body: saved.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(savedJobsProvider),
        ),
        data: (jobs) => jobs.isEmpty
            ? EmptyView(
                title: l10n.savedJobsEmpty,
                icon: Icons.bookmark_border,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(savedJobsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: jobs.length,
                  itemBuilder: (context, i) => JobCard(
                    job: jobs[i],
                    onTap: () => context.push('/jobs/${jobs[i].id}'),
                  ),
                ),
              ),
      ),
    );
  }
}
