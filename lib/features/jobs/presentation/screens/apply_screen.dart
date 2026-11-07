import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/services/media_upload_service.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/domain/entities/profile.dart';
import 'package:mohandis/features/profile/domain/repositories/profile_repository.dart';
import 'package:mohandis/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:mohandis/features/subscription/presentation/notifiers/subscription_notifier.dart';
import 'package:mohandis/features/shared/people/data/repositories/people_repository_impl.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/job.dart';
import '../notifiers/jobs_notifier.dart';

/// Two-step application flow — résumé + cover letter, then review — followed
/// by a success state that replaces the form entirely.
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _cover = TextEditingController();
  int _step = 0;
  bool _submitting = false;
  bool _done = false;

  /// A CV picked and uploaded in this session, as its host-less stored path.
  ///
  /// Null means "use whatever is on the profile". The upload happens at pick
  /// time, not at submit: the person can see it fail while they are still
  /// writing their cover letter, and submitting then costs one request rather
  /// than a chain that can strand a half-uploaded application.
  String? _cvPath;

  /// The name they picked it under, for the card. The stored path is a uuid
  /// and nothing else carries this.
  String? _cvName;

  bool _uploadingCv = false;

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  /// The CV this application will go up with — the fresh upload, or the one
  /// already on the profile.
  String? _resolvedCv(Profile? me) {
    final picked = _cvPath;
    if (picked != null && picked.isNotEmpty) return picked;
    final onFile = me?.cvUrl?.trim();
    return (onFile == null || onFile.isEmpty) ? null : onFile;
  }

  Future<void> _pickCv() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) {
      showRungToast(context, context.l10n.composerUploadsOff, success: false);
      return;
    }

    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // A CV is a document a human reads, not an archive or a slide deck.
        // The upload's own allow-list is wider; this is the narrower, honest
        // set for the one thing being asked for.
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
    } catch (e) {
      if (!mounted) return;
      showRungToast(context, arabicMessageForException(e), success: false);
      return;
    }

    final file = picked?.files.isNotEmpty == true ? picked!.files.first : null;
    if (file?.path == null || !mounted) return;
    if (file!.size > _maxCvBytes) {
      showRungToast(
        context,
        context.l10n.composerDocumentTooLarge(_maxCvBytes ~/ (1024 * 1024)),
        success: false,
      );
      return;
    }

    setState(() {
      _uploadingCv = true;
      _cvName = file.name;
    });

    // Its own folder: a CV is not a post attachment, and a zone-wide rule or a
    // retention policy written against `posts/` must never reach one.
    final result = await uploader.uploadDocument(file.path!, folder: 'cv');
    if (!mounted) return;

    setState(() => _uploadingCv = false);
    result.when(
      success: (path) {
        setState(() => _cvPath = path);
        // Written to the profile as well as sent with this application, so the
        // next job does not ask again. A failure here is deliberately silent:
        // this application already has its CV, and an error toast about a
        // profile the person did not open would be noise.
        ref
            .read(profileNotifierProvider(ProfileRepository.meSentinel).notifier)
            .save({'cvUrl': path});
      },
      failure: (e) {
        setState(() => _cvName = null);
        showRungToast(context, arabicMessageForException(e), success: false);
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final cv = _resolvedCv(
      ref.read(profileNotifierProvider(ProfileRepository.meSentinel)).valueOrNull,
    );
    // The server refuses this too — "Attach your CV before applying." — but a
    // round trip to be told what the screen already knows is a worse answer
    // than a button that says why it is disabled.
    if (cv == null) {
      showRungToast(context, context.l10n.applyResumeRequired, success: false);
      return;
    }

    setState(() => _submitting = true);

    final result =
        await ref.read(applicationsNotifierProvider.notifier).apply(
              jobId: widget.jobId,
              coverLetter: _cover.text,
              resumeUrl: cv,
            );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (_) => setState(() => _done = true),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  /// Matches the composer's document cap. Nothing compresses on the way out and
  /// a CV that does not fit in this is not a CV.
  static const int _maxCvBytes = 10 * 1024 * 1024;

  bool get _hasCv =>
      _resolvedCv(
        ref
            .watch(profileNotifierProvider(ProfileRepository.meSentinel))
            .valueOrNull,
      ) !=
      null;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final job = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        showBack: false,
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/jobs'),
          icon: const Icon(Icons.close, size: 22),
          color: c.ink,
          tooltip: l10n.actionCancel,
        ),
        title: l10n.applyTitle,
      ),
      body: job.when(
        loading: () => const FormSkeleton(fields: 3),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId)),
        ),
        data: (data) {
          // The route is reachable without going through the job detail
          // screen's gate — a deep link, or a tap taken before `me` resolved
          // there. `JobService.Apply` refuses a company outright, so the form
          // would be a dead end: no CV on a company profile means the submit
          // button never enables and nothing on screen says why.
          final me = ref
              .watch(profileNotifierProvider(ProfileRepository.meSentinel))
              .valueOrNull;
          if (me?.isCompany == true) return _companyRefusal();

          // Same gate as the job's apply button, for the same reason: this
          // route opens from a deep link too. Fails open while the state is
          // unknown — the server checks the application itself.
          final canApply = ref
                  .watch(subscriptionProvider)
                  .valueOrNull
                  ?.canApplyToJobs ??
              true;
          // Not while a submitted application is on screen: the success view
          // is the receipt for one that already went through, and replacing it
          // with a paywall would read as the application having failed.
          if (!canApply && !_done) return _subscriptionRefusal();

          return _done ? _successView(data) : _formView(data);
        },
      ),
    );
  }

  /// The paywall's doorway, not the paywall itself: the subscription page owns
  /// the plans and the prices, and a second copy of them here is a second place
  /// to get them wrong.
  Widget _subscriptionRefusal() {
    final c = context.rung;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 44, color: c.ink3),
            const SizedBox(height: 16),
            Text(
              l10n.jobApplyLockedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push('/subscription'),
              child: Text(l10n.subscriptionSubscribe),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/jobs'),
              child: Text(l10n.actionCancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyRefusal() {
    final c = context.rung;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.domain_disabled_outlined, size: 44, color: c.ink3),
            const SizedBox(height: 16),
            Text(
              l10n.jobCompanyCannotApply,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/feed'),
              child: Text(l10n.actionDone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successView(Job job) {
    final c = context.rung;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.greenSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 46, color: c.green),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.applyDoneTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.applyDoneBody(job.title, job.company),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.55, color: c.ink2),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: () {
                showRungToast(context, l10n.toastApplicationSent);
                if (context.canPop()) context.pop();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 34),
              ),
              child: Text(l10n.actionDone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView(Job job) {
    final c = context.rung;
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              RungSpace.gutter,
              18,
              RungSpace.gutter,
              18,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: RungRadius.mdAll,
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    RungLogoTile(
                      seed: job.company,
                      monogram: job.monogram,
                      size: 44,
                      radius: 11,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${job.company} · ${job.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _progressBar(filled: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _progressBar(filled: _step >= 1)),
                ],
              ),
              const SizedBox(height: 20),
              if (_step == 0) ..._resumeStep() else ..._reviewStep(job),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RungSpace.gutter,
              vertical: RungSpace.sm,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: FilledButton(
              // Disabled without a CV rather than failing at the server. The
              // application IS the CV — the poster's list opens it as a link —
              // so letting somebody through the review step to be refused at
              // the end would waste the only thing they came to do.
              onPressed: _submitting || _uploadingCv || !_hasCv
                  ? null
                  : _step == 0
                      ? () => setState(() => _step = 1)
                      : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_step == 0 ? l10n.actionContinue : l10n.applySubmit),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressBar({required bool filled}) {
    final c = context.rung;
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: filled ? c.accent : c.line2,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  List<Widget> _resumeStep() {
    final c = context.rung;
    final l10n = context.l10n;
    final me = ref
        .watch(profileNotifierProvider(ProfileRepository.meSentinel))
        .valueOrNull;
    final cv = _resolvedCv(me);

    // The name for the card: what they just picked, or — for a CV already on
    // the profile — the tail of its stored path, which is a uuid. Not pretty,
    // but it is what is actually on file, and inventing a friendly name for a
    // document nobody in this session chose would be a fiction.
    final label = _cvName ?? (cv == null ? null : cv.split('/').last);

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(l10n.applyResumeSection, style: _sectionStyle),
          const SizedBox(width: 6),
          Text(
            l10n.requiredSuffix,
            style: TextStyle(fontSize: 12, color: c.red),
          ),
        ],
      ),
      const SizedBox(height: 6),
      InkWell(
        onTap: _uploadingCv ? null : _pickCv,
        borderRadius: RungRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: RungRadius.mdAll,
            border: Border.all(color: cv == null ? c.line2 : c.accent),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cv == null ? c.line2 : c.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _uploadingCv
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.accent,
                        ),
                      )
                    : Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: cv == null ? c.ink3 : c.accent,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label ?? l10n.applyResumeNone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      cv == null
                          ? l10n.applyResumeUploadHint
                          : l10n.applyResumeReplace,
                      style: TextStyle(fontSize: 11.5, color: c.ink3),
                    ),
                  ],
                ),
              ),
              Icon(
                cv == null ? Icons.upload_file : Icons.check_circle,
                size: 20,
                color: cv == null ? c.ink3 : c.green,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(l10n.applyCoverLetterSection, style: _sectionStyle),
          const SizedBox(width: 6),
          Text(
            l10n.optionalSuffix,
            style: TextStyle(fontSize: 12, color: c.ink3),
          ),
        ],
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 150,
        child: TextField(
          controller: _cover,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
          decoration: InputDecoration(
            hintText: l10n.applyCoverHint,
            contentPadding: const EdgeInsets.all(13),
          ),
        ),
      ),
    ];
  }

  List<Widget> _reviewStep(Job job) {
    final c = context.rung;
    final l10n = context.l10n;
    final me = ref.watch(currentPersonProvider).valueOrNull;
    final cover = _cover.text.trim();

    Widget row(String label, Widget value, {bool last = false}) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: c.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink3,
                ),
              ),
              const SizedBox(height: 3),
              value,
            ],
          ),
        );

    return [
      Text(l10n.applyReviewSection, style: _sectionStyle),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          borderRadius: RungRadius.mdAll,
          border: Border.all(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            row(
              l10n.applyApplicantLabel,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    me?.name ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${me?.headline ?? ''} · ${me?.location ?? ''}',
                    style: TextStyle(fontSize: 12.5, color: c.ink2),
                  ),
                ],
              ),
            ),
            row(
              l10n.applyResumeLabel,
              Text(
                _cvName ??
                    _resolvedCv(
                          ref
                              .watch(
                                profileNotifierProvider(
                                  ProfileRepository.meSentinel,
                                ),
                              )
                              .valueOrNull,
                        )?.split('/').last ??
                    l10n.applyResumeNone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: c.ink2),
              ),
            ),
            row(
              l10n.applyCoverLetterSection,
              Text(
                cover.isEmpty ? l10n.applyNoCoverLetter : cover,
                style: TextStyle(fontSize: 13, height: 1.5, color: c.ink2),
              ),
              last: true,
            ),
          ],
        ),
      ),
    ];
  }

  static const _sectionStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}
