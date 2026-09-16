import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/error_messages.dart';
import 'package:flutter_mobile_template/core/utils/formatters.dart';
import 'package:flutter_mobile_template/core/widgets/empty_view.dart';
import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/panel_notifiers.dart';

extension LegalRequestStatusLabel on LegalRequestStatus {
  String label(BuildContext context) => switch (this) {
    LegalRequestStatus.submitted => context.l10n.legalStatusSubmitted,
    LegalRequestStatus.inReview => context.l10n.legalStatusInReview,
    LegalRequestStatus.answered => context.l10n.legalStatusAnswered,
    LegalRequestStatus.closed => context.l10n.legalStatusClosed,
  };
}

/// Requests for legal advice, and their answers.
class LegalRequestsScreen extends ConsumerWidget {
  const LegalRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final requests = ref.watch(legalRequestsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: l10n.dashboardLegalRequest),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.legalNewRequest),
      ),
      body: requests.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(legalRequestsProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.legalEmpty,
                message: l10n.legalEmptyHint,
                icon: Icons.support_agent_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(legalRequestsProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 88),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _RequestCard(request: list[i]),
                ),
              ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final color = switch (request.status) {
      LegalRequestStatus.answered => c.green,
      LegalRequestStatus.closed => c.ink3,
      LegalRequestStatus.inReview => c.accent,
      LegalRequestStatus.submitted => c.amber,
    };

    return RungCard(
      margin: const EdgeInsets.symmetric(horizontal: RungSpace.sm),
      radius: RungRadius.md + 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: RungRadius.pill,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Text(
                  request.status.label(context),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, height: 1.5, color: c.ink2),
          ),
          const SizedBox(height: 6),
          Text(
            relativeTimeArabic(request.createdAt),
            style: TextStyle(fontSize: 11.5, color: c.ink3),
          ),

          // The answer, once there is one. Separated by a rule rather than a
          // second card so it reads as a reply to what is above it.
          if (request.hasResponse) ...[
            const SizedBox(height: RungSpace.sm),
            Divider(height: 1, color: c.line),
            const SizedBox(height: RungSpace.sm),
            Text(
              l10n.legalResponse,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: c.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.response!,
              style: TextStyle(fontSize: 13.5, height: 1.55, color: c.ink),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openForm(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rung.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(RungRadius.lg)),
    ),
    builder: (_) => const _RequestForm(),
  );
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm();

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final result = await ref
        .read(legalRequestsProvider.notifier)
        .submit(subject: _subject.text, body: _body.text);

    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        Navigator.of(context).pop();
        showRungToast(context, context.l10n.legalSubmitted);
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(RungSpace.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.legalNewRequest,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: RungSpace.md),
              RungField(
                label: l10n.legalSubjectLabel,
                controller: _subject,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.companyFieldRequired
                    : null,
              ),
              const SizedBox(height: RungSpace.sm),
              RungField(
                label: l10n.legalBodyLabel,
                controller: _body,
                maxLines: 6,
                // No `height`: RungField drops its fixed height when a
                // validator is present precisely so the error line has room,
                // and an explicit one puts the cage back and clips it — the
                // form would then refuse to submit with nothing on screen
                // saying why.
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.companyFieldRequired
                    : null,
              ),
              const SizedBox(height: RungSpace.md),
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
                    : Text(l10n.legalSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
