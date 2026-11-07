import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';
import 'cv_section_editor.dart';

/// The education list, editable. Always the `me` profile — see
/// [EditExperienceScreen] for why.
class EditEducationScreen extends ConsumerWidget {
  const EditEducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(profileNotifierProvider('me'));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.profileEditEducation),
      body: state.when(
        loading: () => const FormSkeleton(fields: 4),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider('me').notifier).refresh(),
        ),
        data: (profile) => CvSectionList(
          isEmpty: profile.education.isEmpty,
          addLabel: l10n.profileAddEducation,
          onAdd: () => _openForm(context, null),
          children: [
            for (final item in profile.education)
              CvEntryRow(
                title: item.school,
                subtitle: item.degreeLine,
                meta: item.dates,
                onEdit: () => _openForm(context, item),
                onDelete: () => deleteCvEntry(
                  context,
                  () => ref
                      .read(profileNotifierProvider('me').notifier)
                      .deleteEducation(item.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Education? existing) {
    return showCvFormSheet(
      context,
      (context) => _EducationForm(existing: existing),
    );
  }
}

class _EducationForm extends ConsumerStatefulWidget {
  const _EducationForm({required this.existing});

  final Education? existing;

  @override
  ConsumerState<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends ConsumerState<_EducationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _school;
  late final TextEditingController _degree;
  late final TextEditingController _fieldOfStudy;
  late final TextEditingController _description;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _school = TextEditingController(text: e?.school ?? '');
    // The raw columns, not the joined line the row renders — editing
    // "بكالوريوس · هندسة" as one string would write it back into `Degree`.
    _degree = TextEditingController(text: e?.degree ?? '');
    _fieldOfStudy = TextEditingController(text: e?.fieldOfStudy ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _startDate = e?.startDate;
    _endDate = e?.endDate;
  }

  @override
  void dispose() {
    for (final controller in [
      _school,
      _degree,
      _fieldOfStudy,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final entry = Education(
      id: widget.existing?.id ?? 0,
      school: _school.text.trim(),
      monogram: '',
      degreeLine: '',
      dates: '',
      degree: _degree.text.trim(),
      fieldOfStudy: _fieldOfStudy.text.trim(),
      description: _description.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );

    final result = await ref
        .read(profileNotifierProvider('me').notifier)
        .saveEducation(entry);

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
          ? l10n.profileAddEducation
          : l10n.profileEditEducation,
      saving: _saving,
      onSave: _save,
      formKey: _formKey,
      children: [
        RungField(
          label: l10n.fieldSchool,
          controller: _school,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
        ),
        const SizedBox(height: RungSpace.sm),
        RungField(label: l10n.fieldDegree, controller: _degree),
        const SizedBox(height: RungSpace.sm),
        RungField(label: l10n.fieldFieldOfStudy, controller: _fieldOfStudy),
        const SizedBox(height: RungSpace.sm),
        CvDateField(
          label: l10n.fieldStartDate,
          value: _startDate,
          onChanged: (d) => setState(() => _startDate = d),
        ),
        const SizedBox(height: RungSpace.sm),
        CvDateField(
          label: l10n.fieldEndDate,
          value: _endDate,
          onChanged: (d) => setState(() => _endDate = d),
        ),
        const SizedBox(height: RungSpace.sm),
        RungField(
          label: l10n.fieldDescription,
          controller: _description,
          maxLines: 4,
        ),
      ],
    );
  }
}
