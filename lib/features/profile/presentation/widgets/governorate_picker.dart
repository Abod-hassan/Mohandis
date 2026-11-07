import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/governorate_repository.dart';

/// The field that replaced the free-text address: tap it, choose a governorate.
///
/// Reports BOTH the id and the name. The id is the structured answer in its own
/// column; the name goes into the old `location` field beside it, so every
/// screen and filter that reads a location as text — the profile header, people
/// rows, search — keeps working for profiles saved either way.
class GovernorateField extends ConsumerWidget {
  const GovernorateField({
    super.key,
    required this.label,
    required this.selectedId,
    required this.selectedName,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final int? selectedId;

  /// What to show when the id is not in the list — a profile saved before the
  /// list existed still has its typed address, and blanking it would look like
  /// data loss.
  final String selectedName;

  final void Function(Governorate? governorate) onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final rows = ref.watch(governoratesProvider).valueOrNull;

    final selected = _find(rows, selectedId);
    final text = selected?.nameAr ?? selectedName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? () => _open(context) : null,
          borderRadius: RungRadius.mdAll,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled ? c.surface : c.surface2,
              borderRadius: RungRadius.mdAll,
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: c.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text.isEmpty ? (hint ?? l10n.governoratePickerHint) : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                      color: text.isEmpty ? c.ink3 : c.ink,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 20, color: c.ink3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The chosen row, or null while the list has not loaded or no longer carries
  /// that id (a governorate the admin withdrew).
  static Governorate? _find(List<Governorate>? rows, int? id) {
    if (rows == null || id == null) return null;
    for (final row in rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await showModalBottomSheet<_Choice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GovernorateSheet(selectedId: selectedId),
    );
    if (chosen == null) return;
    onChanged(chosen.governorate);
  }
}

/// What the sheet hands back. A wrapper so "cleared" (null) is distinguishable
/// from "dismissed" (no result at all).
class _Choice {
  const _Choice(this.governorate);
  final Governorate? governorate;
}

class _GovernorateSheet extends ConsumerStatefulWidget {
  const _GovernorateSheet({required this.selectedId});

  final int? selectedId;

  @override
  ConsumerState<_GovernorateSheet> createState() => _GovernorateSheetState();
}

class _GovernorateSheetState extends ConsumerState<_GovernorateSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(governoratesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RungRadius.lg),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RungSpace.gutter,
                RungSpace.sm,
                RungSpace.gutter,
                RungSpace.sm,
              ),
              child: Column(
                children: [
                  Text(
                    l10n.governoratePickerTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RungSpace.sm),
                  RungSearchField(
                    hint: l10n.governoratePickerSearch,
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.when(
                loading: () => const PeopleListSkeleton(count: 6),
                // With a retry: the provider outlives this sheet, so one failed
                // fetch would otherwise leave every picker empty for the whole
                // session with no way back.
                error: (e, __) => ListView(
                  controller: controller,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(RungSpace.gutter),
                      child: Column(
                        children: [
                          Text(
                            l10n.governoratePickerFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.5, color: c.ink3),
                          ),
                          const SizedBox(height: RungSpace.sm),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(governoratesProvider),
                            child: Text(l10n.actionRetry),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (rows) {
                  final query = _query.toLowerCase();
                  final visible = [
                    for (final g in rows)
                      if (query.isEmpty ||
                          g.nameAr.toLowerCase().contains(query) ||
                          g.nameEn.toLowerCase().contains(query))
                        g,
                  ];

                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.only(bottom: RungSpace.lg),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.line),
                    itemBuilder: (_, i) {
                      // The way out, for somebody who would rather not say.
                      if (i == visible.length) {
                        return ListTile(
                          leading: Icon(Icons.close_rounded, color: c.ink3),
                          title: Text(
                            l10n.governoratePickerClear,
                            style: TextStyle(fontSize: 14, color: c.ink2),
                          ),
                          onTap: () =>
                              Navigator.of(context).pop(const _Choice(null)),
                        );
                      }

                      final g = visible[i];
                      final selected = g.id == widget.selectedId;
                      return ListTile(
                        leading: Icon(
                          Icons.place_outlined,
                          color: selected ? c.accent : c.ink3,
                        ),
                        title: Text(
                          g.nameAr,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: g.nameEn.isEmpty
                            ? null
                            : Text(
                                g.nameEn,
                                style: TextStyle(fontSize: 11.5, color: c.ink3),
                              ),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: c.accent)
                            : null,
                        onTap: () => Navigator.of(context).pop(_Choice(g)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
