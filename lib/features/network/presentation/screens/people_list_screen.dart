import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/people/domain/entities/person.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';

import '../../domain/entities/people_list_kind.dart';
import '../notifiers/people_list_notifier.dart';

/// One profile's connections, followers or following — one screen, three
/// routes, because the three lists differ only in where the rows come from and
/// what the trailing button does.
///
/// [isMe] gates the destructive button rather than [PeopleListKind] alone:
/// these routes are reachable from anybody's profile, and `Connections/Remove`
/// and `Profiles/Unfollow` both act on the CALLER's edges. On someone else's
/// list the button would either fail or, worse, quietly tear down one of the
/// viewer's own relationships with a person they happened to be looking at.
class PeopleListScreen extends ConsumerWidget {
  const PeopleListScreen({
    super.key,
    required this.kind,
    required this.profileId,
    required this.isMe,
  });

  final PeopleListKind kind;
  final String profileId;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final args = (kind: kind, profileId: profileId);
    final people = ref.watch(peopleListProvider(args));

    final title = switch (kind) {
      PeopleListKind.connections => l10n.peopleConnectionsTitle,
      PeopleListKind.followers => l10n.peopleFollowersTitle,
      PeopleListKind.following => l10n.peopleFollowingTitle,
    };

    return Scaffold(
      // `surface`, not `bg`: the rows are a plain list with no cards, so the
      // page reads as one white sheet (and the dark theme's own sheet colour)
      // rather than grey showing between them.
      backgroundColor: c.surface,
      appBar: RungAppBar(title: title),
      body: people.when(
        loading: () => PeopleListSkeleton(hasAction: isMe && kind.isRevocable),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(peopleListProvider(args).notifier).refresh(),
        ),
        data: (rows) => rows.isEmpty
            ? EmptyView(
                title: l10n.peopleEmpty,
                icon: Icons.people_outline,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(peopleListProvider(args).notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    indent: RungSpace.gutter + 52 + 12,
                    color: c.line,
                  ),
                  itemBuilder: (context, i) => _PersonRow(
                    person: rows[i],
                    // Only the owner of the edge can undo it, and `followers`
                    // is never the viewer's edge to undo.
                    showAction: isMe && kind.isRevocable,
                    kind: kind,
                    onRevoke: () => _revoke(context, ref, args, rows[i]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    PeopleListArgs args,
    Person person,
  ) async {
    final l10n = context.l10n;
    final isConnection = args.kind == PeopleListKind.connections;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(
          isConnection
              ? l10n.peopleRemoveConfirm(person.name)
              : l10n.peopleUnfollowConfirm(person.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              isConnection ? l10n.peopleRemove : l10n.profileUnfollow,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result =
        await ref.read(peopleListProvider(args).notifier).revoke(person.id);
    if (!context.mounted) return;

    result.when(
      success: (_) => showRungToast(
        context,
        isConnection ? l10n.toastConnectionRemoved : l10n.toastUnfollowed,
      ),
      // The row is already back — `revoke` restores it before returning — so
      // this only has to say why.
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const _PersonRow({
    required this.person,
    required this.showAction,
    required this.kind,
    required this.onRevoke,
  });

  final Person person;
  final bool showAction;
  final PeopleListKind kind;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;

    return InkWell(
      onTap: () => context.push('/profile/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 10,
        ),
        child: Row(
          children: [
            RungAvatar(
              seed: person.id,
              initials: person.initials,
              icon: person.accountType.icon,
              imageUrl: ref.watch(imageUrlResolverProvider)(person.avatarUrl),
              size: 52,
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      NameBadges(
                        verified: person.verified,
                        subscribed: person.subscribed,
                      ),
                    ],
                  ),
                  if (person.headline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      person.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.ink3),
                    ),
                  ],
                ],
              ),
            ),
            if (showAction) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onRevoke,
                style: OutlinedButton.styleFrom(
                  // MUST be set. The app's outlinedButtonTheme uses
                  // `Size.fromHeight(48)`, which is `Size(double.infinity, 48)`
                  // — an infinite MINIMUM width. In a bounded parent that is
                  // harmless: `enforce` clamps it down to the parent's width,
                  // which is exactly how every full-width button in this app
                  // gets its width. Here the parent is a Row, and a Row hands
                  // its non-flex children an UNBOUNDED width, so nothing clamps
                  // it: the button asks to be laid out at `minWidth: Infinity`,
                  // `BoxConstraints.debugAssertIsValid` throws, and layout dies
                  // there — taking the rest of the form with it, un-laid-out
                  // and unpaintable for the life of the screen.
                  //
                  // This is the bug that made the followers and connections
                  // lists throw `!semantics.parentDataDirty` once a frame: the
                  // rows laid out, this button did not, and everything after it
                  // was abandoned mid-layout.
                  //
                  // A height floor rather than zero, so the target stays
                  // tappable; only the infinite WIDTH has to go.
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: c.line),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(
                  kind == PeopleListKind.connections
                      ? l10n.peopleRemove
                      : l10n.profileUnfollow,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
