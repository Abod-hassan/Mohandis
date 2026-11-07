import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/presentation/widgets/account_type_labels.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/message_thread.dart';
import '../notifiers/messaging_notifier.dart';

/// What the search box above the conversation list holds. Filters the list
/// already on screen by name — it used to answer "coming soon".
final _threadQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final threads = ref.watch(threadsNotifierProvider);
    final query = ref.watch(_threadQueryProvider).trim().toLowerCase();

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        title: l10n.messagesTitle,
        titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        actions: [
          // No "new message" button yet: a conversation is started from a
          // person's profile (مراسلة). A button that only answers "coming
          // soon" reads as an unfinished app.
        ],
      ),
      body: threads.when(
        loading: () => const PeopleListSkeleton(count: 8, hasAction: false),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(threadsNotifierProvider.notifier).refresh(),
        ),
        data: (all) {
          final list = query.isEmpty
              ? all
              : [
                  for (final t in all)
                    if (t.displayTitle.toLowerCase().contains(query)) t,
                ];
          return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: RungSearchField(
                hint: l10n.messagesSearchHint,
                height: 38,
                onChanged: (value) =>
                    ref.read(_threadQueryProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(threadsNotifierProvider.notifier).refresh(),
                child: list.isEmpty
                    ? const _EmptyThreads()
                    : ListView.builder(
                        // A list shorter than the viewport does not overscroll
                        // on its own, and refresh is a pull away either way.
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (context, i) =>
                            _ThreadRow(thread: list[i]),
                      ),
              ),
            ),
          ],
          );
        },
      ),
    );
  }
}

/// The empty state, laid out inside a scrollable.
///
/// A pull needs something to pull on, and an empty list is exactly when
/// someone reaches for one. Stretched to the viewport so it still centres.
class _EmptyThreads extends StatelessWidget {
  const _EmptyThreads();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: EmptyView(
            title: context.l10n.emptyTitle,
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends ConsumerWidget {
  const _ThreadRow({required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final title = thread.displayTitle;
    final last = thread.lastMessage;
    final at = thread.lastMessageAt;
    final hasUnread = thread.unreadCount > 0;

    // The thread list carries the newest message's text but not its sender, so
    // the "you:" prefix can only be shown once the thread has been opened and
    // its history loaded.
    final preview = last == null
        ? thread.preview
        : '${last.isMine ? l10n.messagesYouPrefix : ''}${last.text}';

    return InkWell(
      // Reading is marked by the thread screen once it has loaded — a tap that
      // never arrives there must not clear the badge.
      onTap: () => context.push('/messages/${thread.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            if (thread.isGroup)
              const RungGroupAvatar()
            else
              RungAvatar(
                seed: thread.avatarSeed,
                initials: thread.counterpart?.initials ?? '؟',
                icon: thread.counterpart?.accountType.icon,
                size: 50,
                imageUrl: ref.watch(imageUrlResolverProvider)(
                  thread.counterpart?.avatarUrl,
                ),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Only a one-to-one thread. `displayTitle` is the GROUP'S
                      // own name on a group row, and a group does not subscribe
                      // to anything — badging it would attach one member's
                      // standing to a name that is not theirs.
                      if (!thread.isGroup)
                        NameBadges(
                          verified: thread.counterpart?.verified ?? false,
                          subscribed: thread.counterpart?.subscribed ?? false,
                          size: 13,
                        ),
                      const Spacer(),
                      const SizedBox(width: 8),
                      Text(
                        at == null ? '' : relativeTimeArabic(at),
                        style: TextStyle(fontSize: 11.5, color: c.ink3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread ? c.ink : c.ink3,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        RungCountBadge(
                          count: thread.unreadCount,
                          background: c.accent,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
