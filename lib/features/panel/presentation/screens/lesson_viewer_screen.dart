import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/utils/arabic_numbers.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../widgets/course_bits.dart';

/// A lesson that is not a video: a PDF, or a written one.
///
/// Pops `true` once the lesson counts as done — reaching the end of the text,
/// or handing the PDF off to the device's viewer. The caller writes the
/// progress, not this screen: the write has to survive the screen being closed.
///
/// **The PDF opens in the device's own viewer**, not in an embedded one. An
/// in-app PDF renderer is a platform plugin and a set of rendering bugs for a
/// file the phone already knows how to display, and handing it off means
/// downloads and printing work for free.
class LessonViewerScreen extends ConsumerStatefulWidget {
  const LessonViewerScreen({super.key, required this.lesson});

  final Lecture lesson;

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  bool _opened = false;

  Future<void> _openFile() async {
    final l10n = context.l10n;
    final resolved = ref.read(imageUrlResolverProvider)(widget.lesson.contentUrl);

    if (resolved == null || resolved.isEmpty) {
      showRungToast(context, l10n.lessonPdfFailed, success: false);
      return;
    }

    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(resolved),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    if (!mounted) return;
    if (!launched) {
      showRungToast(context, l10n.lessonPdfFailed, success: false);
      return;
    }

    // Handed off successfully. There is no way to know whether they read it —
    // the same is true of a printed handout — so opening it is what counts.
    setState(() => _opened = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: RungAppBar(title: lesson.title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          RungSpace.gutter,
          RungSpace.md,
          RungSpace.gutter,
          32,
        ),
        children: [
          Row(
            children: [
              Icon(lesson.kind.icon, size: 18, color: c.accent),
              const SizedBox(width: 7),
              Text(
                lesson.kind.label(context),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
              if (lesson.durationMinutes > 0) ...[
                const Spacer(),
                Text(
                  l10n.courseLectureMinutes(
                    ArabicNumbers.plain(lesson.durationMinutes),
                  ),
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ],
          ),
          const SizedBox(height: RungSpace.md),

          if (lesson.kind == LessonKind.article)
            Text(
              lesson.articleBody ?? '',
              style: const TextStyle(fontSize: 14.5, height: 1.75),
            )
          else
            RungCard(
              radius: RungRadius.md + 2,
              child: Column(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 40, color: c.amber),
                  const SizedBox(height: 10),
                  Text(
                    lesson.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _openFile,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.lessonOpenPdf),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: RungSpace.lg),
          FilledButton(
            // A written lesson is done when the reader says so; a PDF, once it
            // has actually been handed to a viewer. Neither can be observed,
            // and pretending otherwise would be theatre.
            onPressed: lesson.kind == LessonKind.article || _opened
                ? () => Navigator.of(context).pop(true)
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.courseFinishLecture),
          ),
        ],
      ),
    );
  }
}
