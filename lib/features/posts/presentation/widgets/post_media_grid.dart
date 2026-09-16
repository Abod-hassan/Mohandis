import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/theme/rung_tokens.dart';

import '../../domain/entities/post.dart';

/// Media strip under a post. A single attachment keeps its own aspect ratio;
/// two or more render as a square two-column grid with a "+N" veil on the
/// last visible tile.
///
/// A tile's `url` is the host-less path the uploader stored (`posts/<uuid>.jpg`),
/// so it goes through `imageUrlResolverProvider` to become loadable. Anything
/// that yields no URL — a mocked backend, a deployment with no storage zone,
/// a path that 404s — falls back to a deterministic gradient keyed on the
/// media id rather than to a broken-image glyph.
class PostMediaGrid extends StatelessWidget {
  const PostMediaGrid({super.key, required this.media, this.onTap});

  final List<PostMedia> media;
  final VoidCallback? onTap;

  static const int _maxVisible = 2;

  @override
  Widget build(BuildContext context) {
    // Pictures only. A document has no aspect ratio and nothing to crop, so it
    // renders as its own row under the body — see PostDocumentList. Filtering
    // here rather than at the call sites means a post carrying both lays its
    // images out as if the document were not there, instead of leaving a grey
    // square in the grid.
    final media = [for (final m in this.media) if (!m.isDocument) m];

    if (media.isEmpty) return const SizedBox.shrink();

    if (media.length == 1) {
      return GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: media.first.aspectRatio,
          child: _Tile(media: media.first),
        ),
      );
    }

    final visible = media.take(_maxVisible).toList(growable: false);
    final overflow = media.length - visible.length;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _Tile(
                  media: visible[i],
                  overflowCount:
                      i == visible.length - 1 && overflow > 0 ? overflow : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.media, this.overflowCount});

  final PostMedia media;
  final int? overflowCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(imageUrlResolverProvider)(media.url);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Placeholder(seed: media.id),
          )
        else
          _Placeholder(seed: media.id),
        if (overflowCount != null)
          Container(
            color: const Color(0x800A0E16),
            alignment: Alignment.center,
            child: Text(
              '+$overflowCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: RungGradients.forSeed(seed)),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white54,
          size: 34,
        ),
      ),
    );
  }
}
