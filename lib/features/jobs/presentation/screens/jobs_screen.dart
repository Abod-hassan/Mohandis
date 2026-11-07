import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';
import '../notifiers/jobs_notifier.dart';
import '../widgets/job_card.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(jobFiltersProvider).query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final filters = ref.watch(jobFiltersProvider);
    final jobs = ref.watch(jobsSearchProvider);
    final applied = ref.watch(applicationsByJobProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                RungSpace.gutter,
                14,
                RungSpace.gutter,
                12,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.jobsTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/jobs/applications'),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(l10n.jobsMyApplications),
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RungSearchField(
                    hint: l10n.jobsSearchHint,
                    controller: _controller,
                    onChanged: (value) => ref
                        .read(jobFiltersProvider.notifier)
                        .update((f) => f.copyWith(query: value)),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _modeChip(context, ref, null, l10n.jobsFilterAll, filters),
                        for (final mode in WorkMode.values)
                          _modeChip(
                            context,
                            ref,
                            mode,
                            switch (mode) {
                              WorkMode.remote => l10n.jobsFilterRemote,
                              WorkMode.hybrid => l10n.jobsFilterHybrid,
                              WorkMode.onsite => l10n.jobsFilterOnsite,
                            },
                            filters,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: jobs.when(
                loading: () => const CardListSkeleton(height: 120, lines: 3),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(jobsSearchProvider),
                ),
                data: (list) => list.isEmpty
                    ? EmptyView(
                        title: l10n.jobsEmpty,
                        icon: Icons.work_outline_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, i) => JobCard(
                          job: list[i],
                          applied: applied.containsKey(list[i].id),
                          onTap: () => context.push('/jobs/${list[i].id}'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(
    BuildContext context,
    WidgetRef ref,
    WorkMode? mode,
    String label,
    JobFilters filters,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 7),
      child: RungFilterChip(
        label: label,
        selected: filters.workMode == mode,
        onTap: () => ref.read(jobFiltersProvider.notifier).update(
              (f) => mode == null
                  ? f.copyWith(clearWorkMode: true)
                  : f.copyWith(workMode: mode),
            ),
      ),
    );
  }
}
