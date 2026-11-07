import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
// The profile's own state: a delete changes its post count and its grid.
import 'package:mohandis/features/profile/presentation/notifiers/profile_activity_notifier.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/features/shared/moderation/report_sheet.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';


/// The "⋯" sheet on a post card.
///
/// Two different menus behind one button: your own post can be edited or
/// deleted, somebody else's can be saved or reported. They are deliberately
/// disjoint — there is nothing to report about your own post, and the sheet
/// saying so would only be a row that argues with the person who tapped it.
///
/// [onChanged] is called after a successful edit; [onDeleted] after a delete,
/// so the list that owns the card can drop the row rather than leave a card on
/// screen that no longer exists. Both are optional: a screen that reloads on
/// its own needs neither.
Future<void> showPostOptions(
  BuildContext context,
  WidgetRef ref, {
  required Post post,
  required bool isMine,
  ValueChanged<Post>? onChanged,
  VoidCallback? onDeleted,
  VoidCallback? onSaveToggled,
}) {
  final l10n = context.l10n;

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final c = sheetContext.rung;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine) ...[
              ListTile(
                leading: Icon(Icons.edit_outlined, color: c.ink),
                title: Text(l10n.postOptionsEdit),
                onTap: () {
                  // The sheet closes FIRST: what follows is a dialog or another
                  // sheet, and stacking one on a sheet that is being dismissed
                  // takes the second one down with it.
                  Navigator.of(sheetContext).pop();
                  _editPost(context, ref, post: post, onChanged: onChanged);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: c.red),
                title: Text(
                  l10n.postOptionsDelete,
                  style: TextStyle(color: c.red),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(context, ref, post: post, onDeleted: onDeleted);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(
                  post.saved ? Icons.bookmark : Icons.bookmark_border,
                  color: c.ink,
                ),
                title: Text(
                  post.saved ? l10n.postOptionsUnsave : l10n.postOptionsSave,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleSave(
                    context,
                    ref,
                    post: post,
                    onChanged: onChanged,
                    onSaveToggled: onSaveToggled,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: c.red),
                title: Text(
                  l10n.postOptionsReport,
                  style: TextStyle(color: c.red),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showReportSheet(
                    context,
                    target: ReportTarget.post,
                    targetId: post.id,
                  );
                },
              ),
            ],
          ],
        ),
      );
    },
  );
}

Future<void> _toggleSave(
  BuildContext context,
  WidgetRef ref, {
  required Post post,
  ValueChanged<Post>? onChanged,
  VoidCallback? onSaveToggled,
}) async {
  final l10n = context.l10n;
  final result = await ref.read(postRepositoryProvider).toggleSave(post.id);
  if (!context.mounted) return;
  result.when(
    success: (updated) {
      onChanged?.call(updated);
      onSaveToggled?.call();
      // Only a save is worth saying out loud, and the SERVER's answer decides:
      // the endpoint is a toggle, so the local flag is a guess. Unsaving is
      // silent everywhere else in the app, and "Remove from saved" is a menu
      // label, not something that happened.
      if (updated.saved) showRungToast(context, l10n.toastSavedToItems);
    },
    failure: (e) =>
        showRungToast(context, arabicMessageForException(e), success: false),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref, {
  required Post post,
  VoidCallback? onDeleted,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.postDeleteConfirm),
      content: Text(l10n.postDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            l10n.actionDelete,
            style: TextStyle(color: dialogContext.rung.red),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final result = await ref.read(postRepositoryProvider).delete(post.id);
  if (!context.mounted) return;
  result.when(
    success: (_) {
      _refreshAuthorProfile(ref, post.authorId);
      onDeleted?.call();
      showRungToast(context, l10n.toastPostDeleted);
    },
    failure: (e) =>
        showRungToast(context, arabicMessageForException(e), success: false),
  );
}

/// Re-reads the author's profile after one of their posts is deleted.
///
/// The header prints a post COUNT, and the server decrements it as part of the
/// delete — so without this the profile keeps showing the old number until
/// something else happens to refetch it, and the grid keeps a tile for a post
/// that is gone. Both keys are invalidated because the same profile is cached
/// under two: `me` on your own page, the real id everywhere else.
void _refreshAuthorProfile(WidgetRef ref, String authorId) {
  ref.invalidate(profileNotifierProvider(authorId));
  ref.invalidate(profileNotifierProvider('me'));
  ref.invalidate(profileActivityFeedProvider(authorId));
}

Future<void> _editPost(
  BuildContext context,
  WidgetRef ref, {
  required Post post,
  ValueChanged<Post>? onChanged,
}) async {
  final updated = await showModalBottomSheet<Post>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _EditPostSheet(post: post),
  );
  if (updated == null || !context.mounted) return;
  onChanged?.call(updated);
  showRungToast(context, context.l10n.toastPostUpdated);
}

/// Text only — see [PostRepository.edit] for why the media stays as published.
class _EditPostSheet extends ConsumerStatefulWidget {
  const _EditPostSheet({required this.post});

  final Post post;

  @override
  ConsumerState<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends ConsumerState<_EditPostSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.post.text);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final text = _controller.text.trim();
    // A post with pictures may legitimately have no words; one without them
    // cannot, and the server refuses it — better to say so here than to send a
    // request that can only fail.
    if (text.isEmpty && widget.post.media.isEmpty) {
      showRungToast(context, l10n.postEditEmpty, success: false);
      return;
    }

    setState(() => _saving = true);
    final result = await ref
        .read(postRepositoryProvider)
        .edit(widget.post.id, text: text);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (updated) => Navigator.of(context).pop(updated),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
      // The keyboard's height, so the field is never under it.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(RungSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.postEditTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: RungSpace.sm),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 6,
              minLines: 3,
              style: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
              decoration: InputDecoration(
                hintText: l10n.postEditHint,
                filled: true,
                fillColor: c.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RungRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: RungSpace.sm),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.actionSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
