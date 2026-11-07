import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/panel_notifiers.dart';

/// A conversation with the panel's assistant.
///
/// [conversationId] is empty for a new one — the first send is what creates it
/// server-side, so the screen opens on an empty transcript rather than on a
/// request for something that does not exist.
///
/// **Replies are a server-side placeholder** until a model is wired in. The
/// banner says so rather than letting an engineer take a stand-in answer to a
/// legal or engineering question as advice.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.conversationId = ''});

  final String conversationId;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    // Cleared before the round trip: the message is already committed from the
    // person's point of view, and a field that empties on success feels like a
    // lag when the reply is slow.
    _input.clear();

    final result = await ref
        .read(assistantChatProvider(widget.conversationId).notifier)
        .send(text);

    if (!mounted) return;
    setState(() => _sending = false);

    result.when(
      success: (_) => _scrollToEnd(),
      failure: (e) {
        // Put the text back so it is not lost to a failed send.
        _input.text = text;
        showRungToast(context, arabicMessageForException(e), success: false);
      },
    );
  }

  void _scrollToEnd() {
    // After the frame the new turns are laid out in, or it scrolls to where the
    // list used to end.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final chat = ref.watch(assistantChatProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.dashboardEngy),
      body: Column(
        children: [
          _StubBanner(),
          Expanded(
            child: chat.when(
              loading: () => const CardListSkeleton(count: 4, height: 84, lines: 1),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(assistantChatProvider(widget.conversationId)),
              ),
              data: (conversation) {
                final messages = conversation?.messages ?? const <AssistantMessage>[];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(RungSpace.lg),
                      child: Text(
                        l10n.dashboardEngyGreeting,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.5, color: c.ink3),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: RungSpace.gutter,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(message: messages[i]),
                );
              },
            ),
          ),
          _Composer(
            controller: _input,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

/// Says plainly that the assistant is not connected. Permanent rather than
/// dismissible: an engineer arriving at a consulting assistant should not have
/// to remember a banner they closed a week ago.
class _StubBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: RungSpace.gutter,
        vertical: 10,
      ),
      color: c.amberSoft,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: c.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.assistantStubNotice,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: c.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final mine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: mine ? c.accent : c.surface2,
                borderRadius: BorderRadius.circular(RungRadius.md),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: mine ? Colors.white : c.ink,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: RungSpace.gutter,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: TextStyle(fontSize: 14, color: c.ink),
                decoration: InputDecoration(
                  hintText: context.l10n.assistantHint,
                  filled: true,
                  fillColor: c.surface2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: RungRadius.pill,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
