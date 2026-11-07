import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../data/repositories/discipline_repository.dart';
import '../../domain/entities/profile.dart';

/// The field that replaced the free-text الاختصاص: tap it, choose a discipline
/// from the tenant's list, see its logo.
///
/// Reports BOTH the id and the name. The id is the structured answer that goes
/// in its own column; the name is written into the old `industry` field beside
/// it, so everything that compares industries — search, "people in your field"
/// — goes on working for profiles saved either way.
class DisciplineField extends ConsumerWidget {
  const DisciplineField({
    super.key,
    required this.label,
    required this.selectedId,
    this.accountType = AccountType.individual,
    required this.selectedName,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final String label;

  /// Which list to offer — the engineering branches, the trades, or the
  /// machinery. The field is the same control either way; only its rows and
  /// its label change.
  final AccountType accountType;

  final int? selectedId;

  /// What to show when the id is not in the list — a profile saved before the
  /// list existed still has its typed text, and blanking it would look like
  /// data loss.
  final String selectedName;

  final void Function(Discipline? discipline) onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final disciplines = ref.watch(disciplinesProvider(accountType)).valueOrNull;

    final selected = _find(disciplines, selectedId);
    final text = selected?.nameAr ?? (selectedName.isEmpty ? '' : selectedName);
    final logo = ref.watch(imageUrlResolverProvider)(selected?.iconUrl);

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
                _DisciplineMark(
                  seed: '${selected?.id ?? 0}',
                  name: text,
                  logoUrl: logo,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.isEmpty ? (hint ?? l10n.disciplinePickerHint) : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: text.isEmpty ? FontWeight.w400 : FontWeight.w600,
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

  /// The chosen row, or null while the list has not loaded or no longer
  /// carries that id (a discipline the admin withdrew).
  static Discipline? _find(List<Discipline>? rows, int? id) {
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
      builder: (_) =>
          _DisciplineSheet(selectedId: selectedId, accountType: accountType),
    );
    if (chosen == null) return;
    onChanged(chosen.discipline);
  }
}

/// What the sheet hands back. A wrapper rather than the discipline itself so
/// "cleared" (null discipline) is distinguishable from "dismissed" (no result).
class _Choice {
  const _Choice(this.discipline);
  final Discipline? discipline;
}

class _DisciplineSheet extends ConsumerStatefulWidget {
  const _DisciplineSheet({
    required this.selectedId,
    required this.accountType,
  });

  final int? selectedId;
  final AccountType accountType;

  @override
  ConsumerState<_DisciplineSheet> createState() => _DisciplineSheetState();
}

class _DisciplineSheetState extends ConsumerState<_DisciplineSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(disciplinesProvider(widget.accountType));

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
                    l10n.disciplinePickerTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RungSpace.sm),
                  RungSearchField(
                    hint: l10n.disciplinePickerSearch,
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.when(
                loading: () => const PeopleListSkeleton(count: 6),
                // With a retry: the provider outlives this sheet, so one
                // failed fetch would otherwise leave every picker in the
                // session empty with no way back.
                error: (e, __) => ListView(
                  controller: controller,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(RungSpace.gutter),
                      child: Column(
                        children: [
                          Text(
                            l10n.disciplinePickerFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.5, color: c.ink3),
                          ),
                          const SizedBox(height: RungSpace.sm),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(
                                  disciplinesProvider(widget.accountType),
                                ),
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
                    for (final d in rows)
                      if (query.isEmpty ||
                          d.nameAr.toLowerCase().contains(query) ||
                          d.nameEn.toLowerCase().contains(query))
                        d,
                  ];

                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.only(bottom: RungSpace.lg),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.line),
                    itemBuilder: (_, i) {
                      // The way out: somebody who is not an engineer, or who
                      // picked by mistake, has to be able to empty the field.
                      if (i == visible.length) {
                        return ListTile(
                          leading: Icon(Icons.close_rounded, color: c.ink3),
                          title: Text(
                            l10n.disciplinePickerClear,
                            style: TextStyle(fontSize: 14, color: c.ink2),
                          ),
                          onTap: () =>
                              Navigator.of(context).pop(const _Choice(null)),
                        );
                      }

                      final d = visible[i];
                      final selected = d.id == widget.selectedId;
                      return ListTile(
                        leading: _DisciplineMark(
                          seed: '${d.id}',
                          name: d.nameAr,
                          logoUrl: ref.watch(imageUrlResolverProvider)(
                            d.iconUrl,
                          ),
                          size: 38,
                        ),
                        title: Text(
                          d.nameAr,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: d.nameEn.isEmpty
                            ? null
                            : Text(
                                d.nameEn,
                                style: TextStyle(fontSize: 11.5, color: c.ink3),
                              ),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: c.accent)
                            : null,
                        onTap: () => Navigator.of(context).pop(_Choice(d)),
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

/// A discipline's logo, or its first letters while nobody has uploaded one.
class _DisciplineMark extends StatelessWidget {
  const _DisciplineMark({
    required this.seed,
    required this.name,
    required this.logoUrl,
    required this.size,
  });

  final String seed;
  final String name;
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 4;
    final url = logoUrl;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // The monogram is a LAYER beneath the image, not an else-branch: as an
        // either/or it would be unreachable while the logo is in flight, and
        // the row would flash an empty square on every build.
        child: Stack(
          fit: StackFit.expand,
          children: [
            RungLogoTile(
              seed: seed,
              monogram: _monogram(name),
              size: size,
              radius: radius,
            ),
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  /// The first letter of the SECOND word where there is one: every discipline
  /// here starts with "هندسة", so the first letter alone would give every one
  /// of them the same mark.
  static String _monogram(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '—';
    final word = words.length > 1 ? words[1] : words.first;
    return word.isEmpty ? '—' : word.substring(0, 1);
  }
}
