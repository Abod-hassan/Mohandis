import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/l10n/l10n.dart';
import 'package:mohandis/core/utils/formatters.dart';

import '../../data/repositories/job_repository_impl.dart';
import '../../domain/entities/job.dart';
import '../notifiers/company_jobs_notifier.dart';
import '../widgets/job_labels.dart';

/// Posts a job.
///
/// Only title and company are required — that is the server's rule, and asking
/// for more than it does would turn a two-field posting into a form people
/// abandon. Everything else narrows the listing for candidates, so it is
/// offered but never demanded.
class CompanyJobFormScreen extends ConsumerStatefulWidget {
  const CompanyJobFormScreen({super.key});

  @override
  ConsumerState<CompanyJobFormScreen> createState() =>
      _CompanyJobFormScreenState();
}

class _CompanyJobFormScreenState extends ConsumerState<CompanyJobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _requirements = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();

  EmploymentType? _employmentType;
  WorkMode? _workMode;
  bool _saving = false;
  bool _seeded = false;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _company,
      _location,
      _description,
      _requirements,
      _salaryMin,
      _salaryMax,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Fills the company name from the profile, once.
  ///
  /// `JobForm.CompanyName` is a free-text column rather than a link to the
  /// posting profile, so it has to be sent — but a company retyping its own
  /// name on every posting is busywork, and a typo there is what makes two
  /// postings look like two different employers. Still editable: a group may
  /// post under a subsidiary's name.
  void _seedCompany(String name) {
    if (_seeded || name.isEmpty) return;
    _seeded = true;
    _company.text = name;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final result = await ref
        .read(jobRepositoryProvider)
        .publish(
          title: _title.text,
          company: _company.text,
          location: _location.text,
          employmentType: _employmentType,
          workMode: _workMode,
          description: _description.text,
          requirements: _requirements.text,
          salaryMin: _parseMoney(_salaryMin.text),
          salaryMax: _parseMoney(_salaryMax.text),
          // The form has no currency field and the backend column is free
          // text, so without this a posted salary came back as a bare number
          // with no unit on it. Stamped rather than asked for: every posting
          // in this product is priced in one currency.
          currency: kCurrencyCode,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        // The list is a plain FutureProvider, so the new posting only appears
        // if it is re-read — the publish response is one job, not the list.
        ref.invalidate(companyJobsProvider);
        showRungToast(context, context.l10n.companyJobPosted);
        if (context.canPop()) context.pop();
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  /// Blank means "not stated", which is different from zero — the server
  /// stores the figures it is given and renders a range from them, so an
  /// unparseable or empty field must send nothing at all.
  static num? _parseMoney(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text.replaceAll(',', ''));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    final profile = ref.watch(profileNotifierProvider('me')).valueOrNull;
    if (profile != null) _seedCompany(profile.displayName);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.companyPostJob),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RungSpace.gutter,
            14,
            RungSpace.gutter,
            32,
          ),
          children: [
            RungField(
              label: l10n.companyJobTitle,
              controller: _title,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.companyFieldRequired
                  : null,
            ),
            const SizedBox(height: RungSpace.sm),
            RungField(
              label: l10n.companyJobCompany,
              controller: _company,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.companyFieldRequired
                  : null,
            ),
            const SizedBox(height: RungSpace.sm),
            RungField(
              label: '${l10n.companyJobLocation} ${l10n.optionalSuffix}',
              controller: _location,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: RungSpace.md),
            _ChoiceRow<EmploymentType>(
              label: l10n.companyJobEmploymentType,
              values: EmploymentType.values,
              selected: _employmentType,
              labelOf: (v) => v.label(context),
              onSelect: (v) => setState(() => _employmentType = v),
            ),
            const SizedBox(height: RungSpace.sm),
            _ChoiceRow<WorkMode>(
              label: l10n.companyJobWorkMode,
              values: WorkMode.values,
              selected: _workMode,
              labelOf: (v) => v.label(context),
              onSelect: (v) => setState(() => _workMode = v),
            ),

            const SizedBox(height: RungSpace.md),
            Row(
              children: [
                Expanded(
                  child: RungField(
                    label: l10n.companyJobSalaryMin,
                    controller: _salaryMin,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: RungSpace.sm),
                Expanded(
                  child: RungField(
                    label: l10n.companyJobSalaryMax,
                    controller: _salaryMax,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),

            const SizedBox(height: RungSpace.md),
            RungField(
              label: l10n.companyJobDescription,
              controller: _description,
              maxLines: 6,
            ),
            const SizedBox(height: RungSpace.sm),
            RungField(
              label: l10n.companyJobRequirements,
              hint: l10n.companyJobRequirementsHint,
              controller: _requirements,
              maxLines: 5,
            ),

            const SizedBox(height: RungSpace.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.companyPublishJob),
            ),
          ],
        ),
      ),
    );
  }
}

/// A wrapping row of choice chips with no "any" option — tapping the selected
/// chip clears it, which is how an optional field gets un-set without a
/// separate control.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${context.l10n.optionalSuffix}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              RungFilterChip(
                label: labelOf(value),
                selected: value == selected,
                onTap: () => onSelect(value == selected ? null : value),
              ),
          ],
        ),
      ],
    );
  }
}
