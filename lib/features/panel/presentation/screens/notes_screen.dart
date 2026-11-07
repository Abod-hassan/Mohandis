import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/panel_notifiers.dart';

/// The engineer's private notes.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final notes = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.dashboardNotes),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add),
      ),
      body: notes.when(
        loading: () => const CardListSkeleton(count: 6, height: 84, lines: 1),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(notesProvider)),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.notesEmpty,
                message: l10n.notesEmptyHint,
                icon: Icons.description_outlined,
              )
            : RefreshIndicator(
                onRefresh: () => pullRefresh(ref.refresh(notesProvider.future)),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 88),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
                  itemBuilder: (_, i) => _NoteRow(note: list[i]),
                ),
              ),
      ),
    );
  }
}

class _NoteRow extends ConsumerWidget {
  const _NoteRow({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.redSoft,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: RungSpace.gutter),
        child: Icon(Icons.delete_outline, color: c.red),
      ),
      // Deleted straight away rather than behind a confirm dialog: the swipe is
      // already deliberate, the notifier restores the row if the server
      // refuses, and a note is the cheapest thing in the app to retype.
      onDismissed: (_) async {
        final result = await ref
            .read(notesProvider.notifier)
            .delete(note.numericId);
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
      child: InkWell(
        onTap: () => _openEditor(context, ref, note: note),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RungSpace.gutter,
            vertical: 13,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? context.l10n.notesUntitled : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, height: 1.4, color: c.ink2),
                ),
              ],
              const SizedBox(height: 5),
              Text(
                relativeTimeArabic(note.updatedAt),
                style: TextStyle(fontSize: 11.5, color: c.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The editor, as a full-height sheet — a note is written, not filled in, so it
/// wants the keyboard and the whole screen rather than a dialog.
Future<void> _openEditor(BuildContext context, WidgetRef ref, {Note? note}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rung.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(RungRadius.lg)),
    ),
    builder: (_) => _NoteEditor(note: note),
  );
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({this.note});

  final Note? note;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.note?.title ?? '',
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.note?.body ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final result = await ref
        .read(notesProvider.notifier)
        .save(
          id: widget.note?.numericId,
          title: _title.text,
          body: _body.text,
        );

    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => Navigator.of(context).pop(),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      // Lifts the sheet above the keyboard, which is otherwise over the body
      // field the moment it is focused.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(RungSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.note == null ? l10n.notesNew : l10n.notesEdit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
            const SizedBox(height: RungSpace.sm),
            RungField(label: l10n.notesTitleLabel, controller: _title),
            const SizedBox(height: RungSpace.sm),
            RungField(
              label: l10n.notesBodyLabel,
              controller: _body,
              maxLines: 8,
              height: 180,
            ),
            const SizedBox(height: RungSpace.sm),
          ],
        ),
      ),
    );
  }
}
