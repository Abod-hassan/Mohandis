import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/shared/moderation/report_sheet.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/reel_repository_impl.dart';
import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_comment.dart';

/// Opens a reel's comments over the player.
///
/// [onCountChanged] is told how many comments were added (positive) or
/// removed (negative) each time it happens, so the rail's count follows the
/// sheet without refetching the wall.
Future<void> showReelCommentsSheet(
  BuildContext context, {
  required Reel reel,
  required bool reelIsMine,
  required ValueChanged<int> onCountChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReelCommentsSheet(
      reel: reel,
      reelIsMine: reelIsMine,
      onCountChanged: onCountChanged,
    ),
  );
}

class _ReelCommentsSheet extends ConsumerStatefulWidget {
  const _ReelCommentsSheet({
    required this.reel,
    required this.reelIsMine,
    required this.onCountChanged,
  });

  final Reel reel;
  final bool reelIsMine;
  final ValueChanged<int> onCountChanged;

  @override
  ConsumerState<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends ConsumerState<_ReelCommentsSheet> {
  static const _pageSize = 50;

  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<ReelComment> _comments = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  Object? _error;
  bool _sending = false;

  /// The comment being answered, when the composer is in reply mode.
  ReelComment? _replyTo;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final page = more ? _page + 1 : 1;
    final result = await ref
        .read(reelRepositoryProvider)
        .comments(widget.reel.id, page: page, size: _pageSize);
    if (!mounted) return;
    result.when(
      success: (rows) => setState(() {
        _comments = more ? [..._comments, ...rows] : rows;
        _page = page;
        _hasMore = rows.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      }),
      failure: (e) => setState(() {
        if (!more) _error = e;
        _loading = false;
        _loadingMore = false;
      }),
    );
  }

  /// Top-level comments oldest first, each followed by its replies.
  List<ReelComment> get _threaded {
    final tops = _comments.where((c) => !c.isReply).toList();
    final ids = tops.map((c) => c.id).toSet();
    final out = <ReelComment>[];
    for (final top in tops) {
      out.add(top);
      out.addAll(_comments.where((c) => c.parentCommentId == top.id));
    }
    // A reply whose parent is on a later page still shows, at the end.
    out.addAll(
      _comments.where((c) => c.isReply && !ids.contains(c.parentCommentId)),
    );
    return out;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final replyTo = _replyTo;
    final result = await ref
        .read(reelRepositoryProvider)
        .addComment(
          widget.reel.id,
          text,
          // Replies hang off the top-level comment, one level deep.
          parentCommentId: replyTo == null
              ? null
              : (replyTo.parentCommentId ?? replyTo.id),
        );
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      success: (comment) {
        setState(() {
          _comments = [..._comments, comment];
          _replyTo = null;
        });
        _controller.clear();
        widget.onCountChanged(1);
      },
      failure: (e) => showRungToast(
        context,
        arabicMessageForException(e),
        success: false,
      ),
    );
  }

  void _startReply(ReelComment comment) {
    setState(() => _replyTo = comment);
    final handle = comment.authorUsername;
    if (handle != null && handle.isNotEmpty && _controller.text.isEmpty) {
      _controller.text = '@$handle ';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    _focus.requestFocus();
  }

  Future<void> _delete(ReelComment comment) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reelCommentDeleteTitle),
        content: Text(l10n.reelCommentDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.reelCommentDelete,
              style: TextStyle(color: ctx.rung.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final result = await ref
        .read(reelRepositoryProvider)
        .deleteComment(comment.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        final gone = _comments
            .where((c) => c.id == comment.id || c.parentCommentId == comment.id)
            .length;
        setState(() {
          _comments = [
            for (final c in _comments)
              if (c.id != comment.id && c.parentCommentId != comment.id) c,
          ];
          if (_replyTo?.id == comment.id) _replyTo = null;
        });
        widget.onCountChanged(-gone);
        showRungToast(context, l10n.reelCommentDeleted);
      },
      failure: (e) => showRungToast(
        context,
        arabicMessageForException(e),
        success: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final myId = ref.watch(currentPersonProvider).valueOrNull?.id.toLowerCase();
    final rows = _threaded;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    final Widget list;
    if (_loading) {
      list = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      list = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              arabicMessageForException(_error!),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink2, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(l10n.reelCommentsRetry)),
          ],
        ),
      );
    } else if (rows.isEmpty) {
      list = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mode_comment_outlined, size: 40, color: c.ink3),
              const SizedBox(height: 10),
              Text(
                l10n.reelCommentsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.ink2, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    } else {
      list = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 200) _load(more: true);
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rows.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= rows.length) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final comment = rows[i];
            final mine =
                myId != null && comment.authorId.toLowerCase() == myId;
            return _CommentRow(
              comment: comment,
              canDelete: mine || widget.reelIsMine,
              canReport: !mine,
              onReply: () => _startReply(comment),
              onDelete: () => _delete(comment),
              onReport: () => showReportSheet(
                context,
                target: ReportTarget.reelComment,
                targetId: comment.id,
              ),
            );
          },
        ),
      );
    }

    final canSend = _controller.text.trim().isNotEmpty && !_sending;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.line2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.reelCommentsTitle,
                style: TextStyle(
                  color: c.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Divider(height: 1, color: c.line),
            Expanded(child: list),
            Divider(height: 1, color: c.line),
            if (_replyTo != null)
              Container(
                color: c.surface2,
                padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.reelCommentReplyingTo(_replyTo!.authorName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.ink2, fontSize: 12.5),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _replyTo = null),
                      icon: Icon(Icons.close_rounded, size: 18, color: c.ink3),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(color: c.ink, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.reelCommentHint,
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: c.surface2,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: canSend ? _send : null,
                            tooltip: l10n.storyReplySend,
                            icon: Icon(
                              Icons.send_rounded,
                              color: canSend ? c.accent : c.ink3,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends ConsumerWidget {
  const _CommentRow({
    required this.comment,
    required this.canDelete,
    required this.canReport,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  final ReelComment comment;
  final bool canDelete;
  final bool canReport;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final author = resolveAuthor(ref, comment.authorId, comment.author);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        comment.isReply ? 56 : 16,
        8,
        4,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${comment.authorId}'),
            child: RungAvatar(
              seed: comment.authorId,
              initials: author.initials,
              imageUrl: ref.watch(imageUrlResolverProvider)(
                author.avatarUrl ?? comment.authorAvatarUrl,
              ),
              size: comment.isReply ? 28 : 34,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author.name.isNotEmpty ? author.name : comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    NameBadges(
                      verified: author.verified,
                      subscribed: author.subscribed,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      relativeTimeArabic(comment.createdAt),
                      style: TextStyle(color: c.ink3, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.text,
                  style: TextStyle(color: c.ink, fontSize: 13.5, height: 1.45),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onReply,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      l10n.reelCommentReply,
                      style: TextStyle(
                        color: c.ink3,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canDelete || canReport)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, size: 18, color: c.ink3),
              padding: EdgeInsets.zero,
              onSelected: (v) => v == 'delete' ? onDelete() : onReport(),
              itemBuilder: (_) => [
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.reelCommentDelete,
                      style: TextStyle(color: c.red),
                    ),
                  ),
                if (canReport)
                  PopupMenuItem(
                    value: 'report',
                    child: Text(l10n.reelCommentReport),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
