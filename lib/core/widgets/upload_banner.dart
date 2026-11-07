import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/video_upload_queue.dart';
import '../theme/rung_colors.dart';
import '../theme/rung_tokens.dart';
import '../utils/error_messages.dart';
import 'package:mohandis/l10n/l10n.dart';

/// The strip that reports a video upload happening somewhere else.
///
/// Sits in the shell, above the bottom bar, so it is on screen whichever tab
/// the person wandered to after starting the upload — which is the whole point
/// of moving the transfer off the composer.
///
/// **A strip rather than a SnackBar.** A SnackBar is for something that just
/// happened; this is a thing that is still happening, for as long as a minute,
/// and SnackBars time out, stack badly and get dismissed by the next toast the
/// app shows. It also has to survive a tab change, which a SnackBar tied to one
/// Scaffold does not.
class UploadBanner extends ConsumerWidget {
  const UploadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(videoUploadQueueProvider);
    if (job == null) return const SizedBox.shrink();

    // An UNCLAIMED job is not news. Its transfer was begun when the video was
    // picked and nobody has pressed Publish yet, so the person is still on the
    // composer with its own indicator in front of them — announcing progress
    // on the shell behind it would be reporting a step they did not ask for,
    // on a thing they have not finished making and may yet abandon.
    if (!job.claimed) return const SizedBox.shrink();

    final c = context.rung;
    final l10n = context.l10n;

    final (text, tone) = switch (job.stage) {
      VideoUploadStage.uploading => (l10n.uploadBannerUploading, c.ink),
      VideoUploadStage.finishing => (l10n.uploadBannerFinishing, c.ink),
      VideoUploadStage.done => (l10n.uploadBannerDone, c.green),
      VideoUploadStage.failed => (l10n.uploadBannerFailed, c.red),
      VideoUploadStage.cancelled => (l10n.uploadBannerCancelled, c.ink3),
      // Never drawn — handled above — but the switch is exhaustive so that a
      // stage added later cannot slip through without a decision.
      VideoUploadStage.ready => (l10n.uploadBannerFinishing, c.ink),
    };

    return Material(
      color: c.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: c.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RungSpace.gutter,
              8,
              RungSpace.gutter,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: tone,
                              ),
                            ),
                          ),
                          if (job.stage == VideoUploadStage.uploading) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${(job.progress * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.ink3,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // The failure reason where there is one, the job's own
                        // name otherwise. A banner that said only "failed"
                        // would send somebody back to a composer they have
                        // already closed to find out why.
                        //
                        // In a DEBUG build the untranslated detail wins: the
                        // translated line collapses anything it has no rule for
                        // into "something went wrong", which is the right thing
                        // to tell somebody using the app and the wrong thing to
                        // show whoever is trying to fix it. Release builds
                        // never see this.
                        kDebugMode && job.debugDetail != null
                            ? job.debugDetail!
                            : job.stage == VideoUploadStage.cancelled
                                ? job.label
                                : job.error != null
                                ? arabicMessageForException(job.error!)
                                : job.label,
                        // Three lines in debug so a status code and a response
                        // body are not cut off at the first ellipsis.
                        maxLines: kDebugMode && job.debugDetail != null ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        // Left-to-right: this is an API path and a JSON body,
                        // and the RTL layout would otherwise reorder it into
                        // something that cannot be read back.
                        textDirection: kDebugMode && job.debugDetail != null
                            ? TextDirection.ltr
                            : null,
                        style: TextStyle(fontSize: 11.5, color: c.ink3),
                      ),
                    ],
                  ),
                ),
                // Cancel while the bytes are still moving — the only stage
                // where stopping leaves nothing half-written. A text button
                // rather than an icon: an X here would be read as "hide this
                // banner", which is the opposite of what it does.
                if (job.canCancel)
                  TextButton(
                    onPressed: () =>
                        ref.read(videoUploadQueueProvider.notifier).cancel(),
                    style: TextButton.styleFrom(
                      foregroundColor: c.red,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.uploadBannerCancel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (!job.isActive)
                  IconButton(
                    onPressed: () =>
                        ref.read(videoUploadQueueProvider.notifier).clear(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: c.ink3,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          // Determinate while bytes move, indeterminate once they have: the
          // publish call that follows has no measurable length, and a bar
          // frozen at 100% reads as a hang.
          SizedBox(
            height: 2,
            child: switch (job.stage) {
              VideoUploadStage.uploading => LinearProgressIndicator(
                  value: job.progress,
                  backgroundColor: c.line,
                  minHeight: 2,
                ),
              VideoUploadStage.finishing => LinearProgressIndicator(
                  backgroundColor: c.line,
                  minHeight: 2,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}
