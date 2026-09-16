import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/message_thread.dart';
import '../notifiers/messaging_notifier.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _markedRead = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final result =
        await ref.read(threadNotifierProvider(widget.threadId).notifier).send(text);
    if (!mounted) return;
    setState(() => _sending = false);

    result.when(
      success: (_) {
        _controller.clear();
        _scrollToNewest();
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  /// Brings the newest message back into view after sending from further up
  /// the history. The list is reversed, so that end is offset zero.
  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: RungMotion.fast,
        curve: RungMotion.easing,
      );
    });
  }

  /// Clears the unread badge once the thread has actually loaded.
  ///
  /// The list row's tap is not the only way in — a `/messages/:threadId` deep
  /// link and a notification tap both land here directly — and marking on the
  /// way in would zero the badge for a navigation that never arrived.
  void _markReadOnce(AsyncValue<MessageThread> state) {
    if (_markedRead || !state.hasValue) return;
    _markedRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(threadsNotifierProvider.notifier).markRead(widget.threadId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final state = ref.watch(threadNotifierProvider(widget.threadId));
    _markReadOnce(state);

    return Scaffold(
      backgroundColor: c.bg,
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref
              .read(threadNotifierProvider(widget.threadId).notifier)
              .refresh(),
        ),
        data: (thread) => Column(
          children: [
            _ThreadHeader(thread: thread),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                // Anchored at the newest message, which is the one the thread
                // was opened for: against the real backend a page is 30
                // messages, so starting at the top of the page starts a full
                // screen or more away from it.
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                itemCount: thread.messages.length,
                itemBuilder: (context, i) {
                  final index = thread.messages.length - 1 - i;
                  final message = thread.messages[index];
                  final previous =
                      index == 0 ? null : thread.messages[index - 1];
                  final bubble = _Bubble(
                    message: message,
                    showSender: thread.isGroup && !message.isMine,
                    showReadReceipt: i == 0 && message.isMine && message.read,
                  );
                  // "اليوم" belongs above the first message actually sent
                  // today, not above the top of the loaded page — a thread
                  // last active a month ago has nothing today to label.
                  final opensToday = _isToday(message.sentAt) &&
                      (previous == null || !_isToday(previous.sentAt));
                  if (!opensToday) return bubble;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          context.l10n.threadToday,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.ink3,
                          ),
                        ),
                      ),
                      bubble,
                    ],
                  );
                },
              ),
            ),
            _Composer(
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadHeader extends ConsumerWidget {
  const _ThreadHeader({required this.thread});

  final MessageThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final counterpart = thread.counterpart;
    final title = thread.displayTitle;
    // Conversation reads never fill the headline in, so the username is the
    // subtitle that actually renders — falling through to it rather than
    // leaving the line blank.
    final subtitle = thread.isGroup
        ? context.l10n
            .threadMembers(ArabicNumbers.count(thread.participants.length))
        : counterpart?.headline ?? _handle(counterpart?.username);

    return RungAppBar(
      background: c.surface,
      titleWidget: Row(
        children: [
          if (thread.isGroup)
            const RungGroupAvatar(size: 38)
          else
            RungAvatar(
              seed: thread.avatarSeed,
              initials: counterpart?.initials ?? '؟',
              size: 38,
              imageUrl: ref.watch(imageUrlResolverProvider)(
                counterpart?.avatarUrl,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether [moment] falls on the viewer's current calendar day. Compared in
/// local time: timestamps arrive as UTC, and a message sent this evening is
/// still "today" to the person reading it.
bool _isToday(DateTime moment) {
  final now = DateTime.now();
  final local = moment.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

/// `@username` for the header's second line, or nothing when the profile has
/// no username to show.
String _handle(String? username) {
  final name = username?.trim() ?? '';
  return name.isEmpty ? '' : '@$name';
}

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.message,
    required this.showSender,
    required this.showReadReceipt,
  });

  final Message message;
  final bool showSender;
  final bool showReadReceipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final mine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showSender) ...[
            RungAvatar(
              seed: message.senderId,
              // Every message names its own sender, so a group bubble never
              // waits on a directory lookup that may not have them.
              initials: message.senderInitials,
              size: 26,
              imageUrl: ref.watch(imageUrlResolverProvider)(
                message.senderAvatarUrl,
              ),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.74,
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, right: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.ink3,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: mine ? c.accent : c.surface,
                    // The squared corner points back at the sender: bottom
                    // start for me, bottom end for them.
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomRight: Radius.circular(mine ? 16 : 4),
                      bottomLeft: Radius.circular(mine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: mine ? Colors.white : c.ink,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTimeArabic(message.sentAt),
                        style: TextStyle(fontSize: 10, color: c.ink3),
                      ),
                      if (showReadReceipt) ...[
                        const SizedBox(width: 4),
                        Text(
                          '✓✓ ${context.l10n.threadRead}',
                          style: TextStyle(fontSize: 10, color: c.accent),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            RungIconButton(
              icon: Icons.add,
              shape: BoxShape.circle,
              foreground: c.accent,
              onPressed: () => showRungToast(context, context.l10n.comingSoon),
              tooltip: context.l10n.comingSoon,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: RungRadius.pill,
                  border: Border.all(color: c.line2),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(fontSize: 14, color: c.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    hintText: context.l10n.threadInputHint,
                    hintStyle: TextStyle(fontSize: 14, color: c.ink3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            RungIconButton(
              icon: Icons.send_rounded,
              size: 40,
              shape: BoxShape.circle,
              // Nulling onPressed alone leaves it painted as an accent button,
              // which reads as tappable and invites a second send.
              background: sending ? c.surface2 : c.accent,
              foreground: sending ? c.ink3 : Colors.white,
              onPressed: sending ? null : onSend,
              tooltip: context.l10n.actionSend,
            ),
          ],
        ),
      ),
    );
  }
}
