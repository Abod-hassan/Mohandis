import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../notifiers/post_detail_notifier.dart';

/// A post's poll: tap a choice to vote, the same choice again to take the
/// vote back, another to move it. Results show once you have voted or the
/// poll has closed.
class PostPoll extends ConsumerStatefulWidget {
  const PostPoll({super.key, required this.postId, required this.poll});

  final String postId;
  final Poll poll;

  @override
  ConsumerState<PostPoll> createState() => _PostPollState();
}

class _PostPollState extends ConsumerState<PostPoll> {
  /// The poll as this card last knew it — ahead of [PostPoll.poll] while a
  /// vote is in flight, and kept when the post shown is a copy no notifier
  /// owns (a profile grid, a hashtag list).
  late Poll _poll = widget.poll;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant PostPoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.poll, widget.poll) && !_busy) {
      _poll = widget.poll;
    }
  }

  Future<void> _vote(PollOption option) async {
    if (_busy || _poll.closed) return;
    final before = _poll;
    setState(() {
      _busy = true;
      _poll = before.vote(option.id);
    });

    final result = await ref
        .read(postRepositoryProvider)
        .votePoll(before.id, option.id);
    if (!mounted) return;
    result.when(
      success: (server) {
        setState(() {
          _busy = false;
          _poll = server;
        });
        ref.read(feedNotifierProvider.notifier).applyPoll(widget.postId, server);
        if (ref.exists(postDetailNotifierProvider(widget.postId))) {
          ref
              .read(postDetailNotifierProvider(widget.postId).notifier)
              .applyPoll(server);
        }
      },
      failure: (_) {
        setState(() {
          _busy = false;
          _poll = before;
        });
        showRungToast(context, context.l10n.pollVoteFailed, success: false);
      },
    );
  }

  String _footer(BuildContext context) {
    final l10n = context.l10n;
    final votes = l10n.pollVotes('${_poll.totalVotes}');
    if (_poll.closed) return '$votes · ${l10n.pollClosed}';
    final left = _poll.endsAt.difference(DateTime.now());
    final String remaining;
    if (left.inDays >= 1) {
      remaining = l10n.pollLeftDays('${left.inDays}');
    } else if (left.inHours >= 1) {
      remaining = l10n.pollLeftHours('${left.inHours}');
    } else {
      remaining = l10n.pollLeftMinutes(
        '${left.inMinutes < 1 ? 1 : left.inMinutes}',
      );
    }
    return '$votes · $remaining';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final results = _poll.showResults;
    // The leader is marked once the poll is over, so a closed poll says who won.
    final top = _poll.options.isEmpty
        ? 0
        : _poll.options.map((o) => o.votes).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RungSpace.gutter,
        RungSpace.sm,
        RungSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in _poll.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionRow(
                option: option,
                results: results,
                share: _poll.shareOf(option),
                mine: _poll.myOptionId == option.id,
                leading: _poll.closed && top > 0 && option.votes == top,
                enabled: !_poll.closed && !_busy,
                onTap: () => _vote(option),
              ),
            ),
          Text(
            _footer(context),
            style: TextStyle(color: c.ink3, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.results,
    required this.share,
    required this.mine,
    required this.leading,
    required this.enabled,
    required this.onTap,
  });

  final PollOption option;
  final bool results;
  final double share;
  final bool mine;
  final bool leading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final strong = mine || leading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: RungRadius.mdAll,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: RungRadius.mdAll,
            border: Border.all(
              color: results ? (mine ? c.accent : c.line) : c.accent,
              width: mine ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: RungRadius.mdAll,
            child: Stack(
              children: [
                if (results)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      widthFactor: share.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(
                        color: strong ? c.accentSoft2 : c.surface3,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: results ? TextAlign.start : TextAlign.center,
                          style: TextStyle(
                            color: results ? c.ink : c.accent,
                            fontSize: 13.5,
                            fontWeight: strong || !results
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (results) ...[
                        if (mine) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: c.accent,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${(share * 100).round()}%',
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 13,
                            fontWeight: strong
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
