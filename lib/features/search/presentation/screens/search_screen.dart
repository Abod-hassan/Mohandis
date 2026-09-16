import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/network/presentation/notifiers/network_notifier.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/widgets/job_card.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/trending_tag.dart';
import '../notifiers/search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final tab = ref.watch(searchTabProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/feed'),
                    icon: const Icon(Icons.chevron_left, size: 24),
                    color: c.ink,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  Expanded(
                    child: RungSearchField(
                      hint: l10n.searchHint,
                      controller: _controller,
                      autofocus: true,
                      height: 38,
                      radius: 19,
                      onChanged: (value) =>
                          ref.read(searchQueryProvider.notifier).state = value,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in [
                    (SearchTab.top, l10n.searchTabTop),
                    (SearchTab.people, l10n.searchTabPeople),
                    (SearchTab.jobs, l10n.searchTabJobs),
                    (SearchTab.tags, l10n.searchTabTags),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: RungFilterChip(
                        label: entry.$2,
                        selected: tab == entry.$1,
                        outlined: false,
                        onTap: () => ref.read(searchTabProvider.notifier).state =
                            entry.$1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _Results(tab: tab)),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.tab});

  final SearchTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // With no query the tag sections are the trending list, not matches, and
    // the header has to say so — off the debounced query, so the header never
    // describes a search the rows under it are not showing yet.
    final searching =
        ref.watch(debouncedSearchQueryProvider).trim().isNotEmpty;
    final tagsHeader =
        searching ? l10n.searchTabTags : l10n.searchTrendingTags;

    return ListView(
      padding: const EdgeInsets.only(bottom: RungSpace.lg),
      children: [
        // Top is served by a single blended call — both of its sections read
        // the same provider rather than firing one request each.
        if (tab == SearchTab.top) ...[
          _SectionHeader(label: tagsHeader),
          ..._rows(
            ref.watch(searchResultsProvider),
            (results) => [
              ..._tagRows(results.tags, l10n),
              _SectionHeader(label: l10n.searchSectionPeople, withTopGap: true),
              ..._personRows(results.people, l10n),
            ],
            onRetry: () => ref.invalidate(searchResultsProvider),
          ),
        ],
        if (tab == SearchTab.tags) ...[
          _SectionHeader(label: tagsHeader),
          ..._rows(
            ref.watch(searchTagsProvider),
            (tags) => _tagRows(tags, l10n),
            onRetry: () => ref.invalidate(searchTagsProvider),
          ),
        ],
        if (tab == SearchTab.people) ...[
          _SectionHeader(label: l10n.searchSectionPeople),
          ..._rows(
            ref.watch(searchPeopleProvider),
            (people) => _personRows(people, l10n),
            onRetry: () => ref.invalidate(searchPeopleProvider),
          ),
        ],
        if (tab == SearchTab.jobs)
          ..._rows(
            ref.watch(searchJobsProvider),
            (jobs) => jobs.isEmpty
                ? [_EmptyRow(label: l10n.searchNoResults)]
                : [
                    for (final job in jobs)
                      JobCard(
                        job: job,
                        onTap: () => context.push('/jobs/${job.id}'),
                      ),
                  ],
            onRetry: () => ref.invalidate(searchJobsProvider),
          ),
      ],
    );
  }

  /// One section's rows plus the loading and failed states every tab shares.
  ///
  /// A settled keystroke rebuilds the provider rather than refreshing it, so
  /// `skipLoadingOnReload` is what keeps the previous rows on screen; the
  /// spinner underneath them is the only sign of the request in flight.
  List<Widget> _rows<T>(
    AsyncValue<T> value,
    List<Widget> Function(T data) rows, {
    required VoidCallback onRetry,
  }) {
    return [
      ...value.when(
        skipLoadingOnReload: true,
        data: rows,
        error: (e, _) => <Widget>[ErrorView(error: e, onRetry: onRetry)],
        loading: () => const <Widget>[_RowsPlaceholder()],
      ),
      if (value.isLoading && value.hasValue) const _RowsPlaceholder(),
    ];
  }

  List<Widget> _tagRows(List<TrendingTag> tags, AppLocalizations l10n) {
    if (tags.isEmpty) return [_EmptyRow(label: l10n.searchNoResults)];
    return [for (final tag in tags) _TagRow(tag: tag)];
  }

  List<Widget> _personRows(List<Person> people, AppLocalizations l10n) {
    if (people.isEmpty) return [_EmptyRow(label: l10n.searchNoResults)];
    return [for (final person in people) _PersonRow(person: person)];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.withTopGap = false});

  final String label;
  final bool withTopGap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: double.infinity,
      decoration: withTopGap
          ? BoxDecoration(
              border: Border(top: BorderSide(color: c.bg, width: 8)),
            )
          : null,
      padding: const EdgeInsets.fromLTRB(RungSpace.gutter, 12, RungSpace.gutter, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: c.ink3,
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag});

  final TrendingTag tag;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return InkWell(
      onTap: () => showRungToast(context, context.l10n.comingSoon),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 11,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.accent,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag.tag,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    context.l10n
                        .searchPostsCount(ArabicNumbers.count(tag.postCount)),
                    style: TextStyle(fontSize: 12, color: c.ink3),
                  ),
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

class _PersonRow extends ConsumerWidget {
  const _PersonRow({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    // The same set the network tab's suggestion tiles read, so a request sent
    // from either surface disables the button on both.
    final sent =
        ref.watch(networkNotifierProvider).valueOrNull?.hasSentTo(person.id) ??
            false;
    // The whole row opens the profile. A result you cannot open by tapping is
    // not a result — and the avatar alone was the only way through.
    return InkWell(
      onTap: () => context.push('/profile/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 9,
        ),
        child: Row(
          children: [
            RungAvatar(
              seed: person.id,
              initials: person.initials,
              imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    person.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.ink2),
                  ),
                ],
              ),
            ),
            // A company row has no Connect: a company is followed, and the
            // server refuses the request. People search is the one list that
            // mixes the two — the network grid filters companies out entirely,
            // and a profile page knows what it is showing.
            if (!person.isCompany) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: sent
                  ? null
                  : () async {
                      final l10n = context.l10n;
                      final result = await ref
                          .read(networkNotifierProvider.notifier)
                          .connect(person.id);
                      if (!context.mounted) return;
                      result.when(
                        success: (_) => showRungToast(
                          context,
                          l10n.toastConnectRequestSent(person.firstName),
                        ),
                        failure: (e) => showRungToast(
                          context,
                          arabicMessageForException(e),
                          success: false,
                        ),
                      );
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                sent
                    ? context.l10n.networkAddSent
                    : context.l10n.profileConnect,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RungSpace.lg),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: context.rung.ink3),
      ),
    );
  }
}

class _RowsPlaceholder extends StatelessWidget {
  const _RowsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(RungSpace.lg),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
