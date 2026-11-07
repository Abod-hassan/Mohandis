import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/api/api_envelope.dart';
import 'package:mohandis/core/api/endpoints.dart';
import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/posts/domain/repositories/post_repository.dart';
import 'package:mohandis/l10n/l10n.dart';

/// What is being reported — `ReportTargetTypeEnum` on the server.
enum ReportTarget {
  post(0),
  reel(1),
  comment(2),
  message(3),
  story(4),
  profile(5),
  reelComment(6);

  const ReportTarget(this.wire);

  final int wire;
}

/// Asks why, sends the report to the moderation queue, and thanks the person.
///
/// One sheet for everything people can publish — posts, reels, comments,
/// messages, stories and profiles. App Store guideline 1.2 requires every kind
/// of user content to be reportable, not just posts.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  if (sent != true || !context.mounted) return;
  showRungToast(context, context.l10n.toastPostReported);
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final TextEditingController _details = TextEditingController();
  PostReportReason? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n, PostReportReason reason) =>
      switch (reason) {
        PostReportReason.spam => l10n.reportReasonSpam,
        PostReportReason.harassment => l10n.reportReasonHarassment,
        PostReportReason.hateSpeech => l10n.reportReasonHateSpeech,
        PostReportReason.violence => l10n.reportReasonViolence,
        PostReportReason.nudity => l10n.reportReasonNudity,
        PostReportReason.misinformation => l10n.reportReasonMisinformation,
        PostReportReason.selfHarm => l10n.reportReasonSelfHarm,
        PostReportReason.impersonation => l10n.reportReasonImpersonation,
        PostReportReason.intellectualProperty =>
          l10n.reportReasonIntellectualProperty,
        PostReportReason.other => l10n.reportReasonOther,
      };

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;

    setState(() => _sending = true);
    final details = _details.text.trim();
    final api = ref.read(apiClientProvider);
    final result = await apiCall(
      EndPoints.reports,
      () => api.dio.post<dynamic>(
        EndPoints.reports,
        data: {
          'targetType': widget.target.wire,
          'targetId': widget.targetId,
          'reason': reason.wire,
          if (details.isNotEmpty) 'details': details,
        },
      ),
      (_) => true,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    result.when(
      success: (_) => Navigator.of(context).pop(true),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return Padding(
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
              l10n.postReportTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: RungSpace.sm),
            // Wrapped rather than a list: ten reasons as full-width rows is a
            // sheet you have to scroll to see the button of.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in PostReportReason.values)
                  ChoiceChip(
                    label: Text(_label(l10n, reason)),
                    selected: _reason == reason,
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: RungSpace.sm),
            TextField(
              controller: _details,
              maxLines: 3,
              minLines: 2,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: c.ink),
              decoration: InputDecoration(
                hintText: l10n.postReportDetailsHint,
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
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancel),
                ),
                const Spacer(),
                FilledButton(
                  // No reason picked is not a report — the queue needs to know
                  // what it is looking at.
                  onPressed: _reason == null || _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.postReportSend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
