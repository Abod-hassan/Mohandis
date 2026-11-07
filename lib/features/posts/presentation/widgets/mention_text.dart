import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/utils/error_messages.dart';
import 'package:mohandis/core/widgets/rung/rung.dart';
import 'package:mohandis/features/profile/data/repositories/profile_repository_impl.dart';

/// Text with every `@handle` drawn as a link to that person's profile.
///
/// The pattern is the server's mention rule (`(?<![\w])@(\w{1,50})`, with
/// .NET's Unicode `\w` spelled out) so exactly the handles that notified
/// someone are the ones that look tappable — nothing more, nothing less.
class MentionText extends ConsumerStatefulWidget {
  const MentionText(this.text, {super.key, this.style, this.maxLines});

  final String text;
  final TextStyle? style;
  final int? maxLines;

  static final pattern = RegExp(
    r'(?<![\p{L}\p{M}\p{Nd}_])@([\p{L}\p{M}\p{Nd}_]{1,50})',
    unicode: true,
  );

  @override
  ConsumerState<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends ConsumerState<MentionText> {
  // Recognizers are owned objects: rebuilt with the text, disposed with us.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final matches = MentionText.pattern.allMatches(text).toList();
    if (matches.isEmpty) {
      _disposeRecognizers();
      return Text(
        text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
      );
    }

    _disposeRecognizers();
    final linkStyle = TextStyle(
      color: context.rung.accent,
      fontWeight: FontWeight.w600,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final handle = m.group(1)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openMentionedProfile(context, ref, handle);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: linkStyle,
          recognizer: recognizer,
        ),
      );
      cursor = m.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));

    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// Resolves `@handle` to a profile and opens it; a toast if nobody has it
/// (renamed, or never existed — a mention is only text).
Future<void> openMentionedProfile(
  BuildContext context,
  WidgetRef ref,
  String handle,
) async {
  final result =
      await ref.read(profileRepositoryProvider).idForUsername(handle);
  if (!context.mounted) return;
  result.when(
    success: (id) => context.push('/profile/$id'),
    failure: (e) =>
        showRungToast(context, arabicMessageForException(e), success: false),
  );
}
