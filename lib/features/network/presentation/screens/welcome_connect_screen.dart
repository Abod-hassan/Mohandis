import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../notifiers/network_notifier.dart';

/// Shown once, straight after the profile step: people worth connecting to.
///
/// A network with nobody in it has nothing to show — the home feed of a brand
/// new account is a short strip of suggested posts and little else — so this is
/// the one moment where handing somebody a list of people is worth a whole
/// screen. Same pool as the Network tab's grid, which now orders people in the
/// viewer's own field first, so "the same job as me" is what tops this list
/// when the directory holds anyone who matches.
///
/// Skippable and never shown again: it is not a step, and the profile flag is
/// already cleared by the time this renders — the only thing standing between
/// here and the feed is one tap.
class WelcomeConnectScreen extends ConsumerWidget {
  const WelcomeConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final overview = ref.watch(networkNotifierProvider);

    void leave() => context.go('/feed');

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        showBack: false,
        title: l10n.welcomeConnectTitle,
        actions: [
          TextButton(
            onPressed: leave,
            style: TextButton.styleFrom(foregroundColor: c.ink2),
            child: Text(l10n.setupSkip),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RungSpace.gutter,
              8,
              RungSpace.gutter,
              14,
            ),
            child: Text(
              l10n.welcomeConnectBody,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink2),
            ),
          ),
          Expanded(
            child: overview.when(
              loading: () => const PeopleListSkeleton(count: 6),
              // No error screen. A failed suggestion read must not strand
              // somebody on the last step of sign-up — the feed is one tap away
              // and the Network tab will try again.
              error: (_, __) => _Empty(onContinue: leave),
              data: (data) => data.suggestions.isEmpty
                  ? _Empty(onContinue: leave)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        RungSpace.gutter,
                        0,
                        RungSpace.gutter,
                        RungSpace.lg,
                      ),
                      itemCount: data.suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PersonRow(
                        person: data.suggestions[i],
                        sent: data.hasSentTo(data.suggestions[i].id),
                      ),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RungSpace.gutter,
                vertical: RungSpace.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: leave,
                  child: Text(l10n.welcomeConnectContinue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          context.l10n.welcomeConnectEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink3),
        ),
      ),
    );
  }
}

class _PersonRow extends ConsumerStatefulWidget {
  const _PersonRow({required this.person, required this.sent});

  final Person person;
  final bool sent;

  @override
  ConsumerState<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends ConsumerState<_PersonRow> {
  /// Local, because this screen never re-reads the overview. Connecting from
  /// here should flip the one button that was pressed, not reload a list the
  /// person is still working down.
  bool _sent = false;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final person = widget.person;
    final sent = _sent || widget.sent;

    // The whole row opens the profile — deciding whether to connect with
    // somebody starts with reading their profile, and the avatar alone was the
    // only way to it. The Connect button keeps its own tap.
    return InkWell(
      onTap: () => context.push('/profile/${person.id}'),
      child: Row(
        children: [
          RungAvatar(
            seed: person.id,
            initials: person.initials,
            icon: person.accountType.icon,
            imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    NameBadges(
                      verified: person.verified,
                      subscribed: person.subscribed,
                      size: 13,
                    ),
                  ],
                ),
                if (person.headline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.ink2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: sent || _sending ? null : _connect,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: Size.zero,
              ),
              child: _sending
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    )
                  : Text(
                      // Disabled once sent, so it says what is true rather
                      // than offering an action it refuses to take.
                      sent ? l10n.postSuggestedFollowing : l10n.profileFollow,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _sending = true);
    // Follows, not connects: the app has one relationship now.
    final result = await ref
        .read(networkNotifierProvider.notifier)
        .follow(widget.person.id);
    if (!mounted) return;

    setState(() => _sending = false);
    result.when(
      success: (_) => setState(() => _sent = true),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }
}
