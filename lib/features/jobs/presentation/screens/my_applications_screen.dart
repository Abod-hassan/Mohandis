import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../notifiers/jobs_notifier.dart';
import '../widgets/job_labels.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final applications = ref.watch(applicationsNotifierProvider);
    final jobs = ref.watch(jobsDirectoryProvider).valueOrNull;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.myApplicationsTitle),
      body: applications.when(
        loading: () => const CardListSkeleton(height: 110),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(applicationsNotifierProvider.notifier).refresh(),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.myApplicationsEmpty,
                icon: Icons.assignment_outlined,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(applicationsNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _ApplicationCard(
                    application: list[i],
                    job: jobs?[list[i].jobId],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.job});

  final JobApplication application;
  final Job? job;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final status = application.status;

    final statusColor = switch (status) {
      ApplicationStatus.accepted => c.green,
      ApplicationStatus.rejected => c.red,
      ApplicationStatus.shortlisted ||
      ApplicationStatus.interview =>
        c.accent,
      _ => c.amber,
    };

    return RungCard(
      margin: const EdgeInsets.symmetric(horizontal: RungSpace.sm, vertical: 8),
      radius: RungRadius.md + 2,
      onTap: job == null ? null : () => context.push('/jobs/${job!.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RungLogoTile(
                seed: job?.company ?? application.jobId,
                monogram: job?.monogram ?? '؟',
                size: 46,
                radius: 11,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${job?.company ?? ''} · ${job?.location ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status.label(context),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StatusStepper(
            labels: applicationStepLabels(context),
            currentIndex: status.stepIndex,
            decisionColor: status.isDecided ? statusColor : null,
          ),
        ],
      ),
    );
  }
}
