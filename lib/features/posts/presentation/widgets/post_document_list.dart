import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/post.dart';

/// The document attachments on a post, as rows under the body.
///
/// Deliberately NOT part of [PostMediaGrid]: that lays out pictures at their
/// aspect ratio and crops them into tiles, and a PDF has neither a ratio nor
/// anything to crop. A document is a name, a size and a tap — the same shape a
/// mail client gives an attachment, because that is what people already read.
///
/// Handed to the device's own viewer rather than rendered in-app. An embedded
/// renderer is a platform plugin and a set of rendering bugs for a file the
/// phone already displays, and handing it off means downloading, printing and
/// sharing all work without being built.
class PostDocumentList extends ConsumerWidget {
  const PostDocumentList({super.key, required this.media});

  final List<PostMedia> media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = media.where((m) => m.isDocument).toList(growable: false);
    if (documents.isEmpty) return const SizedBox.shrink();

    // The same resolver every image goes through. What is stored is a host-less
    // path so the CDN can be repointed without rewriting rows, and this is
    // where it becomes openable again.
    final resolve = ref.watch(imageUrlResolverProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final document in documents)
          Padding(
            padding: const EdgeInsets.only(top: RungSpace.sm),
            child: _DocumentRow(
              document: document,
              url: resolve(document.url),
            ),
          ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.url});

  final PostMedia document;
  final String? url;

  /// A rough type badge from the extension. Not a content-type lookup — the
  /// point is to tell a PDF from a spreadsheet at a glance, and the extension
  /// is what the person who attached it saw too.
  (IconData, String) _badge() {
    final name = document.displayName.toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? '' : name.substring(dot + 1);
    return switch (ext) {
      'pdf' => (Icons.picture_as_pdf_outlined, 'PDF'),
      'doc' || 'docx' || 'rtf' => (Icons.article_outlined, 'DOC'),
      'xls' || 'xlsx' || 'csv' => (Icons.table_chart_outlined, 'XLS'),
      'ppt' || 'pptx' => (Icons.slideshow_outlined, 'PPT'),
      'zip' => (Icons.folder_zip_outlined, 'ZIP'),
      '' => (Icons.insert_drive_file_outlined, ''),
      _ => (Icons.insert_drive_file_outlined, ext.toUpperCase()),
    };
  }

  Future<void> _open(BuildContext context) async {
    final target = url;
    if (target == null || target.isEmpty) return;

    final l10n = context.l10n;
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(target),
        // The device's own viewer, not an in-app webview: that is what makes
        // save, print and share work without building any of them.
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showRungToast(context, l10n.postOpenDocumentFailed, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final (icon, label) = _badge();
    final size = document.readableSize;

    return Material(
      color: c.surface2,
      borderRadius: RungRadius.mdAll,
      child: InkWell(
        // Null when the row somehow carries no path — the tile still renders,
        // because a post that says nothing about its own attachment is worse
        // than one that shows an inert name.
        onTap: (url == null || url!.isEmpty) ? null : () => _open(context),
        borderRadius: RungRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: RungRadius.mdAll,
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: c.accentInk),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (label.isNotEmpty || size != null) ...[
                      const SizedBox(height: 2),
                      // Forced LTR: "PDF · 2.4 MB" is Latin throughout, and
                      // under RTL the separator and the unit resolve in the
                      // wrong order.
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          [label, if (size != null) size]
                              .where((p) => p.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(fontSize: 11.5, color: c.ink3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.download_outlined,
                size: 19,
                color: c.ink3,
                semanticLabel: l10n.postOpenDocument,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
