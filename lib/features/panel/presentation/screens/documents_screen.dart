import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/widgets/empty_view.dart';
import 'package:mohandis/core/widgets/error_view.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/core/utils/pull_refresh.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/panel_notifiers.dart';

/// The engineering library and the legal-affairs shelf.
///
/// One screen for both: they differ only in which category they read and what
/// the app bar says, and two near-identical files would drift the first time
/// either changed.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key, required this.category});

  final DocumentCategory category;

  static DocumentCategory fromSlug(String slug) => slug == 'legal-affairs'
      ? DocumentCategory.legalAffairs
      : DocumentCategory.library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final documents = ref.watch(documentsProvider(category));

    final title = category == DocumentCategory.legalAffairs
        ? l10n.dashboardLegalAffairs
        : l10n.dashboardLibrary;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: title),
      body: documents.when(
        loading: () => const CardListSkeleton(count: 6, height: 84, lines: 1),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(documentsProvider(category)),
        ),
        data: (list) => list.isEmpty
            ? EmptyView(
                title: l10n.documentsEmpty,
                message: l10n.documentsEmptyHint,
                icon: Icons.local_library_outlined,
              )
            : RefreshIndicator(
                onRefresh: () => pullRefresh(
                  ref.refresh(documentsProvider(category).future),
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _DocumentCard(document: list[i]),
                ),
              ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  const _DocumentCard({required this.document});

  final ReferenceDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    // Stored host-less like every other asset; resolved only to be shown, since
    // the app has no in-app viewer to open it with yet.
    final resolved = ref.watch(imageUrlResolverProvider)(document.fileUrl);

    return RungCard(
      margin: const EdgeInsets.symmetric(horizontal: RungSpace.sm),
      radius: RungRadius.md + 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.amberSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  document.isLocked
                      ? Icons.lock_outline
                      : document.hasFile
                      ? Icons.picture_as_pdf_outlined
                      : Icons.article_outlined,
                  size: 20,
                  color: document.isLocked ? c.ink3 : c.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((document.summary ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        document.summary!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: c.ink2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (document.isLocked) ...[
            const SizedBox(height: RungSpace.sm),
            // A locked entry keeps its title and summary — that is what makes
            // the shelf worth paying for — and the file is withheld by the
            // READ, so there is nothing here to open even if this were tapped.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.push('/subscription'),
                icon: const Icon(Icons.lock_outline, size: 16),
                label: Text(l10n.documentLocked),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ] else if (resolved != null) ...[
            const SizedBox(height: RungSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                // Handed to the device's own viewer. An embedded PDF renderer
                // is a platform plugin and a set of rendering bugs for a file
                // the phone already displays.
                onPressed: () async {
                  var launched = false;
                  try {
                    launched = await launchUrl(
                      Uri.parse(resolved),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {
                    launched = false;
                  }
                  if (!context.mounted || launched) return;
                  showRungToast(context, l10n.lessonPdfFailed, success: false);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.lessonOpenPdf),
              ),
            ),
          ] else if (!document.hasFile) ...[
            const SizedBox(height: 8),
            Text(
              l10n.documentNoFile,
              style: TextStyle(fontSize: 11.5, color: c.ink3),
            ),
          ],
        ],
      ),
    );
  }
}
