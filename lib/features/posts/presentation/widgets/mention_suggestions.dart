import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_colors.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/search/data/repositories/search_repository_impl.dart';
import 'package:flutter_mobile_template/features/shared/people/domain/entities/person.dart';

/// The `@token` the caret is currently sitting inside, if any.
///
/// The pattern mirrors the SERVER's — `(?<![\w])@(\w{1,50})` — with one
/// difference that matters: .NET's `\w` is Unicode-aware and Dart's is ASCII
/// only, so an explicit `\p{L}` class is what keeps `@أحمد` recognised here as
/// well as there. A client that only saw Latin handles would refuse to complete
/// the majority of this app's names.
class MentionQuery {
  const MentionQuery({required this.start, required this.end, required this.term});

  /// Offset of the `@`, and the end of the token — the replacement range.
  final int start;
  final int end;

  /// What was typed after the `@`, without it. May be empty, right after the
  /// button inserts one.
  final String term;

  static final _token = RegExp(r'@([\p{L}\p{M}\p{Nd}_]{0,50})$', unicode: true);

  /// Reads the text BEFORE the caret only. A mention is completed as it is
  /// typed, so anything to the right of the cursor is somebody else's word.
  static MentionQuery? at(String text, int caret) {
    if (caret < 0 || caret > text.length) return null;
    final match = _token.firstMatch(text.substring(0, caret));
    if (match == null) return null;

    // The server requires a word boundary before the '@' — `شيء@ahmed` is not
    // a mention on either side, so completing it would promise a notification
    // that never arrives.
    final before = match.start - 1;
    if (before >= 0 &&
        RegExp(r'[\p{L}\p{M}\p{Nd}_]', unicode: true).hasMatch(text[before])) {
      return null;
    }

    return MentionQuery(
      start: match.start,
      end: caret,
      term: match.group(1) ?? '',
    );
  }
}

/// People matching what is being typed after an `@`.
///
/// `autoDispose` and keyed on the term: the strip appears and disappears with
/// every keystroke, and a family entry per term is what stops a fast typist
/// re-querying a prefix they have already seen.
final mentionCandidatesProvider = FutureProvider.autoDispose
    .family<List<Person>, String>((ref, term) async {
  final query = term.trim();

  // The server rejects a blank full-text query, and one letter matches most of
  // the directory — neither is a suggestion worth a round trip.
  if (query.length < 2) return const <Person>[];

  final result = await ref
      .watch(searchRepositoryProvider)
      .people(query, size: 6);
  return result.valueOrNull ?? const <Person>[];
});

/// The suggestion strip above the composer's toolbar.
///
/// Renders nothing at all when there is no `@` under the caret, no match, or
/// fewer than two letters typed — so it costs no height on a normal post and
/// never leaves an empty box hanging over the keyboard.
class MentionSuggestions extends ConsumerWidget {
  const MentionSuggestions({
    super.key,
    required this.query,
    required this.onSelected,
  });

  final MentionQuery? query;

  /// Hands back the handle to insert. The caller owns the replacement, because
  /// it owns the controller and the caret.
  final ValueChanged<Person> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = query;
    if (active == null || active.term.trim().length < 2) {
      return const SizedBox.shrink();
    }

    final c = context.rung;
    final people = ref.watch(mentionCandidatesProvider(active.term)).valueOrNull;

    // Null while the first request is in flight, and on failure. Both render as
    // nothing: a spinner over the keyboard for a suggestion nobody asked for is
    // worse than a strip that simply appears when it has something to say.
    if (people == null || people.isEmpty) return const SizedBox.shrink();

    // Only people whose handle can actually be written as a mention. One
    // without a username would insert "@" and nothing, and the server would
    // parse it as no mention at all.
    final usable = [
      for (final person in people)
        if (person.username.trim().isNotEmpty) person,
    ];
    if (usable.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 176),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: usable.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
        itemBuilder: (_, i) {
          final person = usable[i];
          return InkWell(
            onTap: () => onSelected(person),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RungSpace.gutter,
                vertical: 9,
              ),
              child: Row(
                children: [
                  RungAvatar(
                    seed: person.id,
                    initials: person.initials,
                    size: 34,
                    imageUrl: ref.watch(imageUrlResolverProvider)(
                      person.avatarUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Forced LTR: a handle is Latin-ish and an RTL line
                        // would move the '@' to the wrong end of it.
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '@${person.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: c.ink3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
