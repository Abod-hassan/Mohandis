import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/jobs/data/repositories/job_repository_impl.dart';
import 'package:flutter_mobile_template/features/jobs/domain/entities/job.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/profile.dart';

/// Human label for a headcount band.
///
/// The bands are ranges of people, so they are written as digits rather than
/// translated words — `١-١٠` reads the same to anyone and needs no plural
/// agreement, which "من ١١ إلى ٥٠ موظفًا" would.
extension CompanySizeLabel on CompanySize {
  String? label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      CompanySize.unspecified => null,
      CompanySize.self => l10n.companySizeSelf,
      CompanySize.micro => l10n.companySizeRange(
        ArabicNumbers.count(2),
        ArabicNumbers.count(10),
      ),
      CompanySize.small => l10n.companySizeRange(
        ArabicNumbers.count(11),
        ArabicNumbers.count(50),
      ),
      CompanySize.medium => l10n.companySizeRange(
        ArabicNumbers.count(51),
        ArabicNumbers.count(200),
      ),
      CompanySize.large => l10n.companySizeRange(
        ArabicNumbers.count(201),
        ArabicNumbers.count(500),
      ),
      CompanySize.larger => l10n.companySizeRange(
        ArabicNumbers.count(501),
        ArabicNumbers.count(1000),
      ),
      CompanySize.huge => l10n.companySizeRange(
        ArabicNumbers.count(1001),
        ArabicNumbers.count(5000),
      ),
      CompanySize.enterprise => l10n.companySizeOver(
        ArabicNumbers.count(5000),
      ),
    };
  }
}

/// What a company states about itself that does not fit in the header: its
/// website, and what it specialises in.
///
/// Industry, headcount and founding date used to be here too. They moved up
/// into the meta line under the company's name — they are the first facts
/// anyone wants and this card sat below the fold — so what is left is the
/// website (too long for that line) and the specialty chips (too many).
///
/// Gated on `Profile.hasCompanyDetails`, not `hasCompanyOverview`: a company
/// that stated only its size would otherwise get a heading over nothing.
class CompanyOverviewSection extends StatelessWidget {
  const CompanyOverviewSection({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final website = profile.website?.trim();

    return RungSection(
      title: l10n.companyOverview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (website != null && website.isNotEmpty)
            _WebsiteRow(url: website),

          if (profile.specialties.isNotEmpty) ...[
            if (website != null && website.isNotEmpty)
              const SizedBox(height: RungSpace.sm),
            Text(
              l10n.companySpecialties,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: context.rung.ink2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final specialty in profile.specialties)
                  RungTagChip(label: specialty),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The company's website, which now actually opens.
///
/// It read as a link and did nothing — the old note here said an in-app browser
/// was a decision nobody had made. It still is: this hands the URL to the
/// device's own browser, the same way a post's document attachment does, rather
/// than embedding one.
class _WebsiteRow extends StatelessWidget {
  const _WebsiteRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: RungRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(Icons.link, size: 15, color: c.accent),
            const SizedBox(width: 9),
            // `Flexible`, not `Expanded`: forcing LTR inside a full-width
            // slot makes `TextAlign.start` resolve to LEFT while the row
            // around it is RTL, so a short URL flew to the far edge with a
            // gap between it and the link icon it belongs to. Flexible lets
            // it hug the icon and still ellipsise when it is long.
            Flexible(
              // Forced LTR: a URL is a Latin run, and in an RTL paragraph the
              // scheme and the path swap ends.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 14, color: c.ink3),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    // A company types "example.com" far more often than it types a scheme, and
    // `Uri.parse` on that yields a path with no host — which launches nothing
    // and reports success.
    final raw = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    final uri = Uri.tryParse(raw);

    final opened = uri == null || uri.host.isEmpty
        ? false
        : await launchUrl(uri, mode: LaunchMode.externalApplication)
            .catchError((_) => false);

    if (!opened && context.mounted) {
      showRungToast(context, context.l10n.companyWebsiteFailed, success: false);
    }
  }
}

/// A company's open postings, on its profile.
///
/// The point of a company page for a candidate — so it sits on the page rather
/// than only in the owner's Jobs tab, and it shows OPEN postings only: a closed
/// one is management detail its owner sees on their own tab, and a visitor
/// tapping a job they cannot apply to is a dead end.
class CompanyJobsSection extends ConsumerWidget {
  const CompanyJobsSection({
    super.key,
    required this.personId,
    required this.isMe,
  });

  final String personId;

  /// The owner sees the empty state with a prompt to post; a visitor sees
  /// nothing at all rather than "this company has no jobs".
  final bool isMe;

  /// Enough to show there is hiring going on without turning the profile into
  /// a job board — the full list is one tap away.
  static const int _maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final jobs = ref.watch(companyOpenJobsProvider(personId));

    // A failed or in-flight read renders nothing rather than an error card:
    // this is a secondary section on someone else's page, and the profile
    // above it is still perfectly readable without it.
    final list = jobs.valueOrNull;
    if (list == null) return const SizedBox.shrink();
    if (list.isEmpty && !isMe) return const SizedBox.shrink();

    return RungSection(
      // The count IN the heading, because this section now LEADS a company's
      // page: "الوظائف المتاحة" over three rows says less than "٣ وظائف
      // مفتوحة" says before you have read a single one. Count first, and
      // through the plural form — Arabic needs "وظائف" for three and "وظيفة"
      // for thirty, and a fixed label gets one of them wrong.
      title: list.isEmpty
          ? l10n.companyOpenJobs
          : '${ArabicNumbers.count(list.length)} '
                '${l10n.companyOpenJobsCount(list.length)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                l10n.companyJobsEmptyHint,
                style: TextStyle(fontSize: 13, color: context.rung.ink3),
              ),
            )
          else
            for (final job in list.take(_maxRows))
              _JobRow(job: job),

          if (list.length > _maxRows)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                // Its own root-navigator route, NOT `/company/jobs`. That one
                // is a shell branch root — pushing it would mount a second
                // StatefulNavigationShell over the live one — and it renders
                // the SIGNED-IN account's postings, so a visitor tapping this
                // on someone else's page would land on their own empty
                // management screen.
                onPressed: () => context.push('/profile/$personId/jobs'),
                child: Text(l10n.companySeeAllJobs),
              ),
            ),
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return InkWell(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            RungLogoTile(seed: job.company, monogram: job.monogram, size: 40),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (job.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      job.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.ink3),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.ink3),
          ],
        ),
      ),
    );
  }
}

/// A company's OPEN postings, by profile id.
///
/// Separate from `companyJobsProvider`, which is the owner's management list
/// and deliberately includes closed postings. This one is keyed by id because
/// it renders on anyone's company page, not just your own.
final companyOpenJobsProvider = FutureProvider.autoDispose
    .family<List<Job>, String>((ref, personId) async {
      final result = await ref.watch(jobRepositoryProvider).postedBy(personId);
      return result.when(
        success: (jobs) =>
            jobs.where((job) => job.isOpen).toList(growable: false),
        failure: (e) => throw e,
      );
    });

/// Every open posting from one company — where the profile's three-row preview
/// leads.
///
/// Reads `companyOpenJobsProvider`, so it is anyone's company page rather than
/// the signed-in company's management list, and shows open postings only.
class CompanyProfileJobsScreen extends ConsumerWidget {
  const CompanyProfileJobsScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final jobs = ref.watch(companyOpenJobsProvider(personId));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.companyOpenJobs),
      body: jobs.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(companyOpenJobsProvider(personId)),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.companyNoOpenJobs,
                icon: Icons.work_outline_rounded,
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: RungSpace.gutter,
                  vertical: 8,
                ),
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
                itemBuilder: (_, i) => _JobRow(job: list[i]),
              ),
      ),
    );
  }
}
