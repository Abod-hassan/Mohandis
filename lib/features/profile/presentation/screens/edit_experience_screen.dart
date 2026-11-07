import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/utils/formatters.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';
import '../notifiers/profile_notifier.dart';
import 'cv_section_editor.dart';

/// The work-experience list, editable.
///
/// Always operates on the `me` profile: the module's generic-write path keys
/// every row by the caller's own ProfileId, so there is no such thing as
/// editing someone else's CV.
class EditExperienceScreen extends ConsumerWidget {
  const EditExperienceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final state = ref.watch(profileNotifierProvider('me'));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.profileEditExperience),
      body: state.when(
        loading: () => const FormSkeleton(fields: 4),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(profileNotifierProvider('me').notifier).refresh(),
        ),
        data: (profile) => CvSectionList(
          isEmpty: profile.experience.isEmpty,
          addLabel: l10n.profileAddExperience,
          onAdd: () => _openForm(context, ref, null),
          children: [
            for (final item in profile.experience)
              CvEntryRow(
                title: item.role,
                subtitle: item.company,
                meta: item.dates,
                onEdit: () => _openForm(context, ref, item),
                onDelete: () => deleteCvEntry(
                  context,
                  () => ref
                      .read(profileNotifierProvider('me').notifier)
                      .deleteExperience(item.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Experience? existing,
  ) {
    return showCvFormSheet(
      context,
      (context) => _ExperienceForm(existing: existing),
    );
  }
}

class _ExperienceForm extends ConsumerStatefulWidget {
  const _ExperienceForm({required this.existing});

  final Experience? existing;

  @override
  ConsumerState<_ExperienceForm> createState() => _ExperienceFormState();
}

class _ExperienceFormState extends ConsumerState<_ExperienceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _role;
  late final TextEditingController _company;
  late final TextEditingController _location;
  late final TextEditingController _description;

  String? _employmentType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _role = TextEditingController(text: e?.role ?? '');
    _company = TextEditingController(text: e?.company ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _employmentType = e?.employmentType;
    _startDate = e?.startDate;
    _endDate = e?.endDate;
    _isCurrent = e?.isCurrent ?? false;
  }

  @override
  void dispose() {
    for (final controller in [_role, _company, _location, _description]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // `StartDate` is non-nullable on ExperienceModel, so a missing one would be
    // written as the epoch rather than rejected.
    if (_startDate == null) {
      showRungToast(context, context.l10n.fieldRequired, success: false);
      return;
    }

    setState(() => _saving = true);
    final entry = Experience(
      id: widget.existing?.id ?? 0,
      role: _role.text.trim(),
      company: _company.text.trim(),
      monogram: '',
      dates: '',
      location: _location.text.trim(),
      description: _description.text.trim(),
      employmentType: _employmentType,
      startDate: _startDate,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
    );

    final result = await ref
        .read(profileNotifierProvider('me').notifier)
        .saveExperience(entry);

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
          ? l10n.profileAddExperience
          : l10n.profileEditExperience,
      saving: _saving,
      onSave: _save,
      formKey: _formKey,
      children: [
        RungField(
          label: l10n.fieldRole,
          controller: _role,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
        ),
        const SizedBox(height: RungSpace.sm),
        RungField(
          label: l10n.fieldCompany,
          controller: _company,
          validator: (v) =>
              (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
        ),
        const SizedBox(height: RungSpace.sm),
        CvChoiceField(
          label: l10n.fieldEmploymentType,
          // Nullable column, so "not set" is a real choice and must clear it.
          value: _employmentType == null
              ? null
              : employmentTypeLabel(l10n, _employmentType),
          options: [
            for (final wire in kEmploymentTypes)
              CvChoice(value: wire, label: employmentTypeLabel(l10n, wire)),
          ],
          onSelected: (wire) => setState(() => _employmentType = wire),
          onCleared: () => setState(() => _employmentType = null),
        ),
        const SizedBox(height: RungSpace.sm),
        RungField(label: l10n.fieldLocation, controller: _location),
        const SizedBox(height: RungSpace.sm),
        CvDateField(
          label: l10n.fieldStartDate,
          value: _startDate,
          onChanged: (d) => setState(() => _startDate = d),
        ),
        const SizedBox(height: RungSpace.sm),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _isCurrent,
          onChanged: (v) => setState(() => _isCurrent = v),
          title: Text(
            l10n.fieldCurrentRole,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        // Hidden rather than disabled while current: an end date that is set
        // but not sent reads as data loss when the row comes back without it.
        if (!_isCurrent)
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
