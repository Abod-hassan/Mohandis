import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/activity_notification.dart';
import '../notifiers/activity_notifier.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final activity = ref.watch(activityNotifierProvider);
    final directory = ref.watch(peopleDirectoryProvider).valueOrNull;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        title: l10n.notificationsTitle,
        titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await ref
                  .read(activityNotifierProvider.notifier)
                  .markAllRead();
              if (!context.mounted) return;
              // The optimistic clear rolls back on failure; without this the
              // dots simply reappear a second later with no explanation.
              result.when(
                success: (_) {},
                failure: (e) => showRungToast(
                  context,
                  arabicMessageForException(e),
                  success: false,
                ),
              );
            },
            child: Text(
              l10n.notificationsMarkAllRead,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: activity.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(activityNotifierProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? EmptyView(
                title: l10n.emptyTitle,
                icon: Icons.notifications_none_rounded,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(activityNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => _NotificationRow(
                    item: items[i],
                    actor: directory?[items[i].actorId],
                  ),
                ),
              ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item, required this.actor});

  final ActivityNotification item;

  /// The actor from the people directory, when that page happened to contain
  /// them. Against the real backend a miss is the normal case, so nothing here
  /// may depend on it — [ActivityNotification.actorName] is what the row
  /// actually renders when it is absent.
  final Person? actor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final (iconColor, icon) = _visuals(context, item.type);
    final name = actor?.name ?? item.actorName;

    return InkWell(
      onTap: () => _open(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: item.unread ? c.accentSoft : Colors.transparent,
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                RungAvatar(
                  seed: item.actorId,
                  initials: actor?.initials ?? _monogram(name),
                  // The directory is one page, so it misses often; the
                  // notification's own inlined photo is what makes the row
                  // render an actual face rather than a monogram.
                  imageUrl: ref.watch(imageUrlResolverProvider)(
                    actor?.avatarUrl ?? item.actorAvatarUrl,
                  ),
                  size: 46,
                ),
                PositionedDirectional(
                  bottom: -3,
                  end: -3,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 14, color: iconColor),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        // The module leaves `Text` null for everything except
                        // a job application, so for almost every row the
                        // sentence has to be composed here from the kind.
                        TextSpan(
                          text: ' ${item.text.isNotEmpty ? item.text : _predicate(l10n, item.type)}',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relativeTimeArabic(item.createdAt),
                    style: TextStyle(fontSize: 11.5, color: c.ink3),
                  ),
                  if (item.actionable) ...[
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () async {
                            final firstName =
                                actor?.firstName ?? _firstWord(name);
                            final result = await ref
                                .read(activityNotifierProvider.notifier)
                                .acceptConnection(
                                  item.id,
                                  item.actorId,
                                  l10n.notificationsNowConnected,
                                );
                            if (!context.mounted) return;
                            // The row keeps its buttons when the accept fails,
                            // so the toast must agree with it — otherwise the
                            // same frame says both "connected" and "not yet".
                            result.when(
                              success: (_) => showRungToast(
                                context,
                                l10n.toastConnected(firstName),
                              ),
                              failure: (e) => showRungToast(
                                context,
                                arabicMessageForException(e),
                                success: false,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(l10n.actionAccept),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final result = await ref
                                .read(activityNotifierProvider.notifier)
                                .ignoreConnection(item.id, item.actorId);
                            if (!context.mounted) return;
                            result.when(
                              success: (_) {},
                              failure: (e) => showRungToast(
                                context,
                                arabicMessageForException(e),
                                success: false,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            side: BorderSide(color: c.line2, width: 1.5),
                            foregroundColor: c.ink2,
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(l10n.actionIgnore),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (item.unread)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: RungDot(color: c.accent),
              ),
          ],
        ),
      ),
    );
  }

  /// Opens what the notification is about: the post when it names one — likes,
  /// comments, replies, mentions and shares all do — and the actor's profile
  /// otherwise.
  ///
  /// The read call is deliberately not awaited: the row already shows itself
  /// as read, and navigation must not wait on the network.
  void _open(BuildContext context, WidgetRef ref) {
    ref.read(activityNotifierProvider.notifier).markRead(item.id);

    final postId = item.postId;
    if (postId != null && postId.isNotEmpty) {
      context.push('/feed/posts/$postId');
    } else if (item.actorId.isNotEmpty) {
      context.push('/profile/${item.actorId}');
    }
    // Neither — the actor's profile is gone and there is no post — leaves the
    // row with nowhere to go, so the tap only marks it read.
  }

  /// What the actor did, as a phrase that follows their name.
  ///
  /// Only `JobApplication` carries server-side text, so every other kind reads
  /// as a bare name without this — see the note at the call site.
  String _predicate(AppLocalizations l10n, ActivityType type) {
    return switch (type) {
      ActivityType.connect => l10n.activityConnectRequested,
      ActivityType.like => l10n.activityLiked,
      ActivityType.accepted => l10n.activityConnectAccepted,
      ActivityType.comment => l10n.activityCommented,
      ActivityType.job => l10n.activityApplied,
      ActivityType.mention => l10n.activityMentioned,
      ActivityType.follow => l10n.activityFollowed,
      ActivityType.share => l10n.activityShared,
      ActivityType.message => l10n.activityMessaged,
      ActivityType.call => l10n.activityCalled,
      ActivityType.other => l10n.activityOther,
    };
  }

  (Color, IconData) _visuals(BuildContext context, ActivityType type) {
    final c = context.rung;
    return switch (type) {
      ActivityType.connect => (c.accent, Icons.person_add_alt_1_outlined),
      ActivityType.like => (c.accent, Icons.thumb_up_alt_outlined),
      ActivityType.accepted => (c.green, Icons.check_rounded),
      ActivityType.comment => (c.accent, Icons.mode_comment_outlined),
      ActivityType.job => (c.amber, Icons.work_outline_rounded),
      ActivityType.mention => (c.accent, Icons.alternate_email),
      ActivityType.follow => (c.accent, Icons.person_outline_rounded),
      ActivityType.share => (c.green, Icons.repeat_rounded),
      ActivityType.message => (c.accent, Icons.mail_outline_rounded),
      ActivityType.call => (c.accent, Icons.call_outlined),
      ActivityType.other => (c.ink3, Icons.notifications_none_rounded),
    };
  }
}

/// Avatar fallback for an actor the directory couldn't resolve.
///
/// `Person.initials` builds a two-name monogram; a notification carries only
/// the display name the module denormalised onto it, so one letter is all
/// there is to work with.
String _monogram(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '؟' : trimmed.substring(0, 1);
}

String _firstWord(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}
