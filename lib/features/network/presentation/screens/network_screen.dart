import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/connection_request.dart';
import '../notifiers/network_notifier.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final overview = ref.watch(networkNotifierProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(
        title: l10n.networkTitle,
        showBack: false,
        titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      body: overview.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(networkNotifierProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(networkNotifierProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: RungSpace.lg),
            children: [
              RungSection(
                title:
                    '${l10n.networkRequests} (${ArabicNumbers.count(data.requests.length)})',
                child: data.requests.isEmpty
                    ? Text(
                        l10n.emptyTitle,
                        style: TextStyle(fontSize: 13, color: c.ink3),
                      )
                    : Column(
                        children: [
                          for (final request in data.requests)
                            _RequestRow(request: request),
                        ],
                      ),
              ),
              // Hidden rather than shown empty: the grid is a directory slice,
              // and an empty one says nothing worth a heading.
              if (data.suggestions.isNotEmpty)
                RungSection(
                  title: l10n.networkSuggestions,
                  gapBelow: 0,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                    children: [
                      for (final person in data.suggestions)
                        _SuggestionCard(
                          person: person,
                          sent: data.hasSentTo(person.id),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({required this.request});

  final ConnectionRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final notifier = ref.read(networkNotifierProvider.notifier);
    // The requester's profile rides along with the request, so this never has
    // to fall back to the directory.
    final person = request.person;

    // The whole row opens the profile — deciding on a request usually starts
    // with looking at who sent it, and the avatar alone was the only way
    // through. Accept and Ignore sit inside it and still take their own taps:
    // the deeper target wins the gesture arena.
    return InkWell(
      onTap: () => context.push('/profile/${request.personId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            RungAvatar(
              seed: request.personId,
              initials: person.initials,
              imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
              size: 52,
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
                  // Two lines here, not three: the module's request projection
                  // carries no mutual-connection count, and a "0 mutual" line
                  // would be a number nobody computed.
                  Text(
                    person.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RoundAction(
              icon: Icons.close,
              outlined: true,
              tooltip: l10n.actionIgnore,
              onTap: () async {
                final result = await notifier.ignore(request.personId);
                if (!context.mounted) return;
                // The row is removed optimistically and restored on failure —
                // without this it would vanish and reappear with no reason given.
                result.when(
                  success: (_) {},
                  failure: (e) => showRungToast(
                    context,
                    arabicMessageForException(e),
                    success: false,
                  ),
                );
              },
            ),
            const SizedBox(width: 7),
            _RoundAction(
              icon: Icons.check,
              outlined: false,
              tooltip: l10n.actionAccept,
              onTap: () async {
                final name = person.firstName;
                final result = await notifier.accept(request.personId);
                if (!context.mounted) return;
                result.when(
                  success: (_) => showRungToast(context, l10n.toastConnected(name)),
                  failure: (e) => showRungToast(
                    context,
                    arabicMessageForException(e),
                    success: false,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.outlined,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool outlined;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outlined ? null : c.accent,
            border: outlined ? Border.all(color: c.line2, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: outlined ? c.ink3 : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// A suggestion tile whose add button remembers it was pressed.
///
/// [sent] comes from the notifier, not from the server: `Connect` raises a
/// pending edge and the module exposes no list of *outgoing* requests to read
/// it back from, so the fact is held in the tab's state for the session. The
/// profile screen's button is the one that reads real server state.
class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.person, required this.sent});

  final Person person;
  final bool sent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    // The WHOLE tile opens the profile, not just the avatar. Everything on it
    // — the photo, the name, the headline — is about one person, so the card is
    // the target; a 60px circle inside it was a small bullseye on a large area
    // that looked tappable and was not. The Connect button below keeps its own
    // tap: it is a different action, and nesting it inside this one is fine
    // because the deeper target wins the gesture arena.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(RungRadius.md + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/profile/${person.id}'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RungRadius.md + 2),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              RungAvatar(
                seed: person.id,
                initials: person.initials,
                imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
                size: 60,
              ),
              const SizedBox(height: 9),
              Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  person.headline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, height: 1.35, color: c.ink2),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton(
                  // Disabled once sent: the tile has no way to withdraw a
                  // request, and a second tap would just raise a duplicate.
                  onPressed: sent
                      ? null
                      : () async {
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
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(sent ? l10n.networkAddSent : l10n.networkAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
