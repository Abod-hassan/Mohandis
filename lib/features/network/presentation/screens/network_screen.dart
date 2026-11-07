import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

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
        loading: () => const PeopleListSkeleton(count: 5),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(networkNotifierProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(networkNotifierProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: RungSpace.lg),
            children: [
              // The connection-requests section used to sit here. Connections
              // were withdrawn from the app — following is the only
              // relationship it has — so the tab is the suggestions grid now.
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

/// A suggestion tile whose follow button remembers it was pressed.
///
/// [sent] comes from the notifier, not from the server: the grid is a
/// directory slice with no follow state on it, so the fact that this person
/// was followed here is held in the tab's state for the session. The profile
/// screen's button is the one that reads real server state.
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
                icon: person.accountType.icon,
                imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
                size: 60,
              ),
              const SizedBox(height: 9),
              // A centred Row, because this card stacks rather than lists:
              // the name is centre-aligned under the avatar and a badge hung
              // off the end of the Column would sit under it, not beside it.
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  NameBadges(
                    verified: person.verified,
                    subscribed: person.subscribed,
                    size: 12,
                    gap: 4,
                  ),
                ],
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
                              .follow(person.id);
                          if (!context.mounted) return;
                          result.when(
                            success: (_) => showRungToast(
                              context,
                              l10n.toastFollowing(person.firstName),
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
                  // Settled, not undoable: the button is disabled once the
                  // follow went through, so it must not offer to unfollow.
                  child: Text(
                    sent ? l10n.postSuggestedFollowing : l10n.profileFollow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
