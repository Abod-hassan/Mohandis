import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';
import 'cv_section_editor.dart';

/// The skills list, editable. Always the `me` profile — see
/// [EditExperienceScreen] for why.
class EditSkillsScreen extends ConsumerWidget {
  const EditSkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(profileNotifierProvider('me'));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.profileEditSkills),
      body: state.when(
        loading: () => const FormSkeleton(fields: 3),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider('me').notifier).refresh(),
        ),
        data: (profile) => CvSectionList(
          isEmpty: profile.skills.isEmpty,
          addLabel: l10n.profileAddSkill,
          onAdd: () => _openForm(context, null),
          children: [
            for (final skill in profile.skills)
              CvEntryRow(
                title: skill.name,
                // Endorsements are other people's, not the owner's to edit —
                // shown so a skill worth keeping is obvious before deleting it.
                subtitle: l10n.profileEndorsements(
                  ArabicNumbers.count(skill.endorsements),
                ),
                onEdit: () => _openForm(context, skill),
                onDelete: () => deleteCvEntry(
                  context,
                  () => ref
                      .read(profileNotifierProvider('me').notifier)
                      .deleteSkill(skill.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Skill? existing) {
    return showCvFormSheet(
      context,
      (context) => _SkillForm(existing: existing),
    );
  }
}

class _SkillForm extends ConsumerStatefulWidget {
  const _SkillForm({required this.existing});

  final Skill? existing;

  @override
  ConsumerState<_SkillForm> createState() => _SkillFormState();
}

class _SkillFormState extends ConsumerState<_SkillForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final result = await ref
        .read(profileNotifierProvider('me').notifier)
        .saveSkill(name: _name.text.trim(), id: widget.existing?.id ?? 0);

    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        if (context.canPop()) context.pop();
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CvFormScaffold(
      title: widget.existing == null
          ? l10n.profileAddSkill
          : l10n.profileEditSkills,
      saving: _saving,
      onSave: _save,
      formKey: _formKey,
      children: [
        RungField(
          label: l10n.fieldSkillName,
          controller: _name,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
        ),
        const SizedBox(height: RungSpace.sm),
      ],
    );
  }
}
