import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/message_thread.dart';
import '../notifiers/messaging_notifier.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final threads = ref.watch(threadsNotifierProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        title: l10n.messagesTitle,
        titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        actions: [
          RungIconButton(
            icon: Icons.edit_outlined,
            shape: BoxShape.circle,
            onPressed: () => showRungToast(context, l10n.comingSoon),
            tooltip: l10n.comingSoon,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: threads.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(threadsNotifierProvider.notifier).refresh(),
        ),
        data: (list) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: RungSearchField(
                hint: l10n.messagesSearchHint,
                height: 38,
                onTap: () => showRungToast(context, l10n.comingSoon),
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
        ),
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
                      Expanded(
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
