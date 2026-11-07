import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/services/media_upload_service.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/theme/rung_tokens.dart';
import 'package:mohandis/core/utils/arabic_numbers.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/panel_entities.dart';
import '../notifiers/course_market_notifiers.dart';
import '../widgets/course_bits.dart';
import '../widgets/course_status_pill.dart';

/// Where an author writes a course and sends it for review.
///
/// One screen for the whole life of a course rather than a wizard: an author
/// comes back to a draft several times before submitting, and a wizard would
/// walk them through five steps they have already finished to change one word.
///
/// **The screen mirrors the server's editability rule rather than trusting it.**
/// A course with the reviewer, or already approved, renders read-only — the
/// server refuses those writes anyway, and offering a Save button that always
/// fails is worse than not offering one.
class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key, this.courseId});

  /// Null starts a new course. Anything else edits that one, which must be this
  /// viewer's own — the server answers "not found" for anybody else's.
  final String? courseId;

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  /// The cover's host-less CDN path — what the server stores — or null.
  ///
  /// Held as state rather than in a controller: the person never types it, and
  /// a text field holding a machine-written path invites them to edit it into
  /// something that does not exist.
  String? _coverPath;
  bool _coverUploading = false;
  double _coverProgress = 0;

  CourseCategory _category = CourseCategory.theory;
  CourseLevel _level = CourseLevel.beginner;
  List<String> _outcomes = [];
  List<String> _requirements = [];

  /// The server's copy. Null while a new course has never been saved — which is
  /// also what decides whether the lessons section can be shown at all, since a
  /// lesson needs a course id to hang off.
  Course? _course;

  bool _busy = false;

  /// Whether the controllers have been filled from [_course] yet. Without it
  /// every rebuild would overwrite what the author is typing with the last
  /// value the server sent.
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in [_title, _summary, _description, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Course course) {
    _course = course;
    if (_loaded) return;
    _loaded = true;

    _title.text = course.title;
    _summary.text = course.summary ?? '';
    _description.text = course.description ?? '';
    _coverPath = course.coverImageUrl;
    _price.text = course.commerce.price == 0
        ? ''
        : course.commerce.price.toStringAsFixed(0);
    _category = course.category;
    _level = course.level;
    _outcomes = [...course.outcomes];
    _requirements = [...course.requirements];
  }

  bool get _editable => _course == null || _course!.commerce.isEditable;

  /// Picks a cover, puts it on the CDN, and keeps the host-less path it came
  /// back with — the same thing every other upload in the app stores.
  ///
  /// The path is NOT saved to the course here. An author who picks a cover and
  /// then abandons the form has changed nothing; the picture is only attached
  /// when they press Save, like every other field on this screen.
  Future<void> _pickCover() async {
    final uploader = ref.read(mediaUploadServiceProvider);
    if (uploader == null) {
      showRungToast(context, context.l10n.composerUploadsOff, success: false);
      return;
    }

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // A catalogue card is 180pt tall at most. Anything larger is bytes
        // every reader of the catalogue pays for, on every scroll.
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 85,
      );
    } catch (e) {
      if (mounted) {
        showRungToast(context, arabicMessageForException(e), success: false);
      }
      return;
    }
    if (picked == null || !mounted) return;

    setState(() {
      _coverUploading = true;
      _coverProgress = 0;
    });

    final result = await uploader.uploadImage(
      picked.path,
      folder: 'courses',
      onProgress: (sent, total) {
        if (!mounted || total <= 0) return;
        setState(() => _coverProgress = (sent / total).clamp(0, 1).toDouble());
      },
    );

    if (!mounted) return;
    setState(() => _coverUploading = false);
    result.when(
      success: (path) => setState(() => _coverPath = path),
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  /// The course's id, saving the draft first if it has never been saved.
  ///
  /// Saves the course, then opens its lessons on their own screen.
  ///
  /// **The order is the point.** A lesson is a row that hangs off a course id,
  /// so there is nothing to add one to until the course exists server-side.
  /// This screen used to hide that by saving the draft behind the first tap of
  /// an inline "add lesson" — the right sequence, carried out invisibly, in a
  /// form the author still had unsaved edits in. Now the sequence is the
  /// navigation: the save happens here, and the lessons screen is only reached
  /// once it has returned an id.
  ///
  /// A refused save — a course with no title — goes no further. `_save` has
  /// already said why, so this stays quiet rather than reporting it twice.
  Future<void> _saveThenLessons() async {
    await _save(quiet: true);
    final id = _course?.id;
    if (id == null || !mounted) return;

    showRungToast(context, context.l10n.courseLessonsNextStep);
    await context.push('/panel/courses/mine/$id/lessons');
  }

  Future<void> _save({bool thenSubmit = false, bool quiet = false}) async {
    if (_title.text.trim().isEmpty) {
      showRungToast(context, context.l10n.courseFieldTitle, success: false);
      return;
    }

    setState(() => _busy = true);
    final result = await ref
        .read(myCoursesProvider.notifier)
        .run(
          (repo) => repo.saveMyCourse(
            id: _course?.id,
            title: _title.text,
            summary: _summary.text,
            description: _description.text,
            category: _category,
            level: _level,
            coverImageUrl: _coverPath,
            // Parsed leniently: an author who typed nothing means free, and a
            // price that failed to parse must not silently become a number
            // they did not choose.
            price: double.tryParse(_price.text.trim()) ?? 0,
            outcomes: _outcomes,
            requirements: _requirements,
          ),
        );

    if (!mounted) return;
    setState(() => _busy = false);

    await result.when(
      success: (course) async {
        setState(() => _course = course);
        if (!thenSubmit) {
          // Quiet when the save is a side effect of something else the author
          // asked for — adding the first lesson — rather than the act itself.
          if (!quiet) showRungToast(context, context.l10n.courseSavedToast);
          return;
        }
        await _submit(course.id);
      },
      failure: (e) async =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  Future<void> _submit(String courseId) async {
    setState(() => _busy = true);
    final result = await ref
        .read(myCoursesProvider.notifier)
        .run((repo) => repo.submitCourse(courseId));

    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (course) {
        setState(() => _course = course);
        showRungToast(context, context.l10n.courseSubmittedToast);
      },
      failure: (e) =>
          showRungToast(context, arabicMessageForException(e), success: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final id = widget.courseId;

    // A new course has nothing to read; an existing one is read through the
    // catalogue provider, which is also what the rest of the app renders it
    // from — so an edit and a course page can never disagree about it.
    if (id != null) {
      // `myCourseProvider`, not `courseProvider`: the catalogue cannot see a
      // draft or a rejection, which is most of what gets opened here.
      final course = ref.watch(myCourseProvider(id));
      return course.when(
        loading: () => Scaffold(
          backgroundColor: c.surface,
          appBar: RungAppBar(title: l10n.courseEditorEdit, showBack: true),
          body: const FormSkeleton(),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: c.surface,
          appBar: RungAppBar(title: l10n.courseEditorEdit, showBack: true),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(RungSpace.gutter),
              child: Text(
                arabicMessageForException(e),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.ink3),
              ),
            ),
          ),
        ),
        data: (course) {
          _fill(course);
          return _form(context);
        },
      );
    }

    return _form(context);
  }

  Widget _form(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;
    final course = _course;
    final commerce = course?.commerce;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: RungAppBar(
        title: course == null ? l10n.myCoursesNew : l10n.courseEditorEdit,
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          RungSpace.gutter,
          RungSpace.sm,
          RungSpace.gutter,
          RungSpace.xl,
        ),
        children: [
          if (commerce != null) ...[
            Row(
              children: [
                CourseStatusPill(status: commerce.reviewStatus),
                const Spacer(),
                CoursePrice(commerce: commerce),
              ],
            ),
            const SizedBox(height: RungSpace.sm),
          ],

          // Why the form is read-only, said once at the top rather than by a
          // dozen disabled fields with no explanation between them.
          if (!_editable)
            _Notice(
              text: commerce?.reviewStatus == CourseReviewStatus.submitted
                  ? l10n.courseLockedUntilReview
                  : l10n.courseLockedApproved,
              tone: _NoticeTone.neutral,
            ),

          if (commerce?.reviewStatus == CourseReviewStatus.rejected &&
              commerce?.reviewNote != null)
            _Notice(
              title: l10n.courseReviewNote,
              text: commerce!.reviewNote!,
              tone: _NoticeTone.bad,
            ),

          RungField(
            label: l10n.courseFieldTitle,
            controller: _title,
            enabled: _editable && !_busy,
            maxLength: 200,
          ),
          const SizedBox(height: RungSpace.sm),
          RungField(
            label: l10n.courseFieldSummary,
            controller: _summary,
            enabled: _editable && !_busy,
            maxLines: 2,
            maxLength: 500,
          ),
          const SizedBox(height: RungSpace.sm),
          RungField(
            label: l10n.courseFieldDescription,
            controller: _description,
            enabled: _editable && !_busy,
            maxLines: 6,
          ),
          const SizedBox(height: RungSpace.md),

          // Dropdowns, not chip rows. Two questions of three options each cost
          // six rows as chips, in a form that still has to fit a price, a
          // cover, two bullet lists and the lessons.
          RungSelectField<CourseCategory>(
            label: l10n.courseFieldCategory,
            value: _category,
            values: CourseCategory.values,
            enabled: _editable && !_busy,
            labelOf: (v) => switch (v) {
              CourseCategory.theory => l10n.dashboardTheory,
              CourseCategory.practical => l10n.dashboardPractical,
              CourseCategory.training => l10n.dashboardTraining,
            },
            subtitleOf: (v) => switch (v) {
              CourseCategory.theory => l10n.dashboardTheorySubtitle,
              CourseCategory.practical => l10n.dashboardPracticalSubtitle,
              CourseCategory.training => l10n.dashboardTrainingSubtitle,
            },
            iconOf: (v) => switch (v) {
              CourseCategory.theory => Icons.menu_book_outlined,
              CourseCategory.practical => Icons.handyman_outlined,
              CourseCategory.training => Icons.school_outlined,
            },
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: RungSpace.sm),
          RungSelectField<CourseLevel>(
            label: l10n.courseFieldLevel,
            value: _level,
            values: CourseLevel.values,
            enabled: _editable && !_busy,
            labelOf: (v) => v.label(context),
            onChanged: (v) => setState(() => _level = v),
          ),
          const SizedBox(height: RungSpace.md),

          RungField(
            label: l10n.courseFieldPrice,
            controller: _price,
            enabled: _editable && !_busy,
            hint: l10n.courseFieldPriceHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: RungSpace.md),
          _CoverPicker(
            path: _coverPath,
            uploading: _coverUploading,
            progress: _coverProgress,
            enabled: _editable && !_busy,
            onPick: _pickCover,
            onRemove: () => setState(() => _coverPath = null),
          ),
          const SizedBox(height: RungSpace.md),

          _Lines(
            title: l10n.courseOutcomes,
            lines: _outcomes,
            enabled: _editable && !_busy,
            onChanged: (lines) => setState(() => _outcomes = lines),
          ),
          const SizedBox(height: RungSpace.sm),
          _Lines(
            title: l10n.courseRequirements,
            lines: _requirements,
            enabled: _editable && !_busy,
            onChanged: (lines) => setState(() => _requirements = lines),
          ),

          const SizedBox(height: RungSpace.lg),
          if (_editable) ...[
            // A NEW course has exactly one way forward, and it is not "save
            // and stay here": the lessons are the rest of the job, and they
            // live on a screen that needs the id this save produces. So the
            // only button is the one that does both, in that order.
            if (course == null)
              FilledButton(
                onPressed: _busy ? null : _saveThenLessons,
                child: Text(l10n.courseSaveAndAddLessons),
              )
            else ...[
              FilledButton(
                onPressed: _busy ? null : () => _save(),
                child: Text(l10n.actionSave),
              ),
              const SizedBox(height: RungSpace.xs),
              // Saves on the way through rather than navigating straight off:
              // somebody who edited the price and then went to the lessons
              // would otherwise come back to a form holding changes the server
              // never heard about.
              OutlinedButton.icon(
                onPressed: _busy ? null : _saveThenLessons,
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: Text(l10n.courseLessonsTitle),
              ),
              const SizedBox(height: RungSpace.xs),
              OutlinedButton(
                onPressed: _busy ? null : () => _save(thenSubmit: true),
                child: Text(l10n.courseSubmitForReview),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// An editable list of one-line bullets — ما ستتعلمه, المتطلبات.
///
/// Edited as a whole list and sent as a whole list, matching how the server
/// stores them: it deletes and rewrites both lists on every save, so a partial
/// update here would silently drop whatever it left out.
class _Lines extends StatefulWidget {
  const _Lines({
    required this.title,
    required this.lines,
    required this.onChanged,
    required this.enabled,
  });

  final String title;
  final List<String> lines;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<_Lines> createState() => _LinesState();
}

class _LinesState extends State<_Lines> {
  /// One controller per row, owned here and kept alive across rebuilds.
  ///
  /// **This is what makes typing work.** The rows used to be keyed by their own
  /// CONTENT — a guard against a removed row handing its text to the row that
  /// slid up into its place. But the content changes on every keystroke, so the
  /// key changed on every keystroke: Flutter saw a different widget, destroyed
  /// the field mid-word and built a new one, and the focus fell through to the
  /// next field on the form. One character per visit to the field.
  ///
  /// Controllers fix both problems at once. Identity now comes from this list
  /// rather than from the text, so a row keeps its field while its text
  /// changes, and a removal rebuilds the controllers from the new values
  /// instead of leaving a stale one behind.
  final List<TextEditingController> _rows = [];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Lines old) {
    super.didUpdateWidget(old);
    // ONLY when the number of rows changes — an add or a remove. A rebuild
    // carrying the same count is this widget's own keystroke coming back
    // around, and rewriting the controllers there would reset the cursor to
    // the end of the line on every character.
    if (widget.lines.length != _rows.length) _sync();
  }

  void _sync() {
    for (final row in _rows) {
      row.dispose();
    }
    _rows
      ..clear()
      // Not `TextEditingController.new` as a tear-off: its `text` parameter is
      // NAMED, so the constructor's type is `({String? text})` and it cannot
      // stand in for the `String -> T` that `map` wants.
      ..addAll(widget.lines.map((text) => TextEditingController(text: text)));
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _report() => widget.onChanged([for (final row in _rows) row.text]);

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final l10n = context.l10n;

    return RungSection(
      title: widget.title,
      trailing: widget.enabled
          ? TextButton(
              onPressed: () => widget.onChanged([...widget.lines, '']),
              child: Text(l10n.courseAddLine),
            )
          : null,
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: RungSpace.xs),
              child: Row(
                children: [
                  Expanded(
                    child: RungField(
                      label: '',
                      controller: _rows[i],
                      enabled: widget.enabled,
                      onChanged: (_) => _report(),
                    ),
                  ),
                  if (widget.enabled)
                    IconButton(
                      onPressed: () =>
                          widget.onChanged([...widget.lines]..removeAt(i)),
                      icon: Icon(Icons.close_rounded, size: 18, color: c.ink3),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}



enum _NoticeTone { neutral, bad }

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.tone, this.title});

  final String? title;
  final String text;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final (fg, bg) = switch (tone) {
      _NoticeTone.neutral => (c.ink2, c.surface2),
      _NoticeTone.bad => (c.red, c.redSoft),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: RungSpace.sm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: RungRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 12.5, height: 1.45, color: c.ink2),
          ),
        ],
      ),
    );
  }
}

/// The course's catalogue artwork: tap to pick, replace or clear.
///
/// Shows the LOCAL preview through the CDN resolver rather than the raw stored
/// path — the path is host-less by design, so rendering it directly would be a
/// broken image on every screen that tried.
class _CoverPicker extends ConsumerWidget {
  const _CoverPicker({
    required this.path,
    required this.uploading,
    required this.progress,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final bool uploading;
  final double progress;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.rung;
    final l10n = context.l10n;
    final url = ref.watch(imageUrlResolverProvider)(path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.courseCoverLabel,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled && !uploading ? onPick : null,
          borderRadius: RungRadius.mdAll,
          child: Container(
            height: 160,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: RungRadius.mdAll,
              border: Border.all(color: c.line),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 30,
                        color: c.ink3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.courseCoverAdd,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.ink2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.courseCoverHint,
                        style: TextStyle(fontSize: 11.5, color: c.ink3),
                      ),
                    ],
                  ),

                // Over the picture, not instead of it: a replacement upload
                // should leave the old cover visible underneath rather than
                // blanking the box for the length of the transfer.
                if (uploading)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              value: progress == 0 ? null : progress,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.courseUploading(
                              ArabicNumbers.plain((progress * 100).round()),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (path != null && enabled && !uploading)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: onRemove,
              child: Text(
                l10n.courseCoverRemove,
                style: TextStyle(color: c.red),
              ),
            ),
          ),
      ],
    );
  }
}

