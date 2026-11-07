import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';

/// The shared chrome behind the three CV editors (experience, education,
/// skills). They differ only in their fields, so everything that isn't a field
/// lives here rather than being copied three times.

/// A section's list of entries plus its "add" button.
class CvSectionList extends StatelessWidget {
  const CvSectionList({
    super.key,
    required this.children,
    required this.isEmpty,
    required this.addLabel,
    required this.onAdd,
  });

  final List<Widget> children;
  final bool isEmpty;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.only(bottom: RungSpace.lg),
      children: [
        RungSection(
          gapBelow: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: RungSpace.md),
                  child: Text(
                    l10n.profileSectionEmpty,
                    style: TextStyle(fontSize: 13, color: c.ink3),
                  ),
                )
              else
                ...children,
              const SizedBox(height: RungSpace.sm),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(addLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One editable entry: what it says, plus edit and delete.
class CvEntryRow extends StatelessWidget {
  const CvEntryRow({
    super.key,
    required this.title,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.meta,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12.5, color: c.ink2),
                  ),
                if (meta != null && meta!.isNotEmpty)
                  Text(
                    meta!,
                    style: TextStyle(fontSize: 11.5, color: c.ink3),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: l10n.actionEdit,
            color: c.ink2,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 19),
            tooltip: l10n.actionDelete,
            color: c.red,
          ),
        ],
      ),
    );
  }
}

/// Confirms, then runs [delete], reporting whatever the server says.
///
/// Deleting a CV row is not undoable from the app — `SoftDelete` hides it and
/// nothing re-surfaces it — so it asks first.
Future<void> deleteCvEntry(
  BuildContext context,
  Future<Result<Profile, AppException>> Function() delete,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.profileDeleteEntryTitle),
      content: Text(l10n.profileDeleteEntryBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final result = await delete();
  if (!context.mounted) return;
  result.when(
    success: (_) {},
    failure: (e) =>
        showRungToast(context, arabicMessageForException(e), success: false),
  );
}

/// Opens a CV form as a sheet sized to leave the list visible behind it.
Future<void> showCvFormSheet(
  BuildContext context,
  WidgetBuilder builder,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// The sheet a CV form renders inside: title, save button, scrolling fields,
/// and the keyboard inset the fields would otherwise sit under.
class CvFormScaffold extends StatelessWidget {
  const CvFormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    required this.saving,
    required this.formKey,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final bool saving;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
      // The sheet is above the keyboard, not behind it — without this the
      // field being typed into is the one covered up.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RungRadius.lg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RungSpace.gutter,
                  RungSpace.md,
                  RungSpace.sm,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: saving ? null : onSave,
                      child: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.actionSave),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    RungSpace.gutter,
                    RungSpace.sm,
                    RungSpace.gutter,
                    RungSpace.lg,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A month picker rendered as a tappable field.
class CvDateField extends StatelessWidget {
  const CvDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          // A CV can reach back a working lifetime, and an end date can be in
          // the future for a contract already signed.
          firstDate: DateTime(now.year - 60),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(RungRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null ? l10n.fieldNotSet : formatMonthYearArabic(value!),
          style: TextStyle(
            fontSize: 14,
            color: value == null ? c.ink3 : c.ink,
          ),
        ),
      ),
    );
  }
}

/// `EmploymentTypeEnum` member names, in the order the picker offers them.
///
/// Sent and read BY NAME — the host serialises enums by name, and an ordinal
/// would silently shift the moment a member is inserted server-side.
const List<String> kEmploymentTypes = [
  'FullTime',
  'PartTime',
  'Contract',
  'Internship',
  'Freelance',
  'SelfEmployed',
  'Temporary',
];

/// The display label for an `EmploymentTypeEnum` wire name.
///
/// Falls back to the raw name so a member added server-side renders as
/// something rather than as a blank.
String employmentTypeLabel(AppLocalizations l10n, String? wire) {
  return switch (wire) {
    'FullTime' => l10n.employmentFullTime,
    'PartTime' => l10n.employmentPartTime,
    'Contract' => l10n.employmentContract,
    'Internship' => l10n.employmentInternship,
    'Freelance' => l10n.employmentFreelance,
    'SelfEmployed' => l10n.employmentSelfEmployed,
    'Temporary' => l10n.employmentTemporary,
    _ => wire ?? '',
  };
}

/// One option in a [CvChoiceField].
class CvChoice {
  const CvChoice({required this.value, required this.label});

  final String value;
  final String label;
}

/// A single-select field backed by a menu, with a "clear" entry for the
/// nullable columns.
class CvChoiceField extends StatelessWidget {
  const CvChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.onCleared,
  });

  final String label;

  /// The already-localised label of the current choice, or null for "not set".
  final String? value;

  final List<CvChoice> options;
  final ValueChanged<String> onSelected;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      onSelected: (v) => v.isEmpty ? onCleared() : onSelected(v),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(value: option.value, child: Text(option.label)),
        PopupMenuItem(value: '', child: Text(l10n.fieldNotSet)),
      ],
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value ?? l10n.fieldNotSet,
          style: TextStyle(
            fontSize: 14,
            color: value == null ? c.ink3 : c.ink,
          ),
        ),
      ),
    );
  }
}
