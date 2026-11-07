import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mohandis/core/providers.dart';
import 'package:mohandis/core/theme/rung_colors.dart';
import 'package:mohandis/core/widgets/image_viewer.dart';

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
///
/// Tapping a picture opens it full-screen ([showImageViewer]) at that picture,
/// with the post's other pictures a swipe away — the "+N" tile opens at the
/// first hidden one. [onTap] is only the fallback for a tile with nothing to
/// show (no resolvable URL).
class PostMediaGrid extends ConsumerWidget {
  const PostMediaGrid({super.key, required this.media, this.onTap});

  final List<PostMedia> media;
  final VoidCallback? onTap;

  static const int _maxVisible = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pictures only. A document has no aspect ratio and nothing to crop, so it
    // renders as its own row under the body — see PostDocumentList. Filtering
    // here rather than at the call sites means a post carrying both lays its
    // images out as if the document were not there, instead of leaving a grey
    // square in the grid.
    final media = [for (final m in this.media) if (!m.isDocument) m];

    if (media.isEmpty) return const SizedBox.shrink();

    final resolve = ref.watch(imageUrlResolverProvider);
    final urls = [for (final m in media) resolve(m.url)];

    void open(int index) {
      final url = urls[index];
      if (url == null) {
        onTap?.call();
        return;
      }
      // Only the loadable ones go in the viewer; the index shifts to match.
      final loadable = [for (final u in urls) if (u != null) u];
      showImageViewer(
        context,
        urls: loadable,
        initialIndex: loadable.indexOf(url),
      );
    }

    if (media.length == 1) {
      return GestureDetector(
        onTap: () => open(0),
        child: AspectRatio(
          aspectRatio: media.first.aspectRatio,
          child: _Tile(media: media.first),
        ),
      );
    }

    final visible = media.take(_maxVisible).toList(growable: false);
    final overflow = media.length - visible.length;

    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              // The "+N" tile opens at the first picture it hides.
              onTap: () => open(
                i == visible.length - 1 && overflow > 0 ? i + 1 : i,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: _Tile(
                  media: visible[i],
                  overflowCount:
                      i == visible.length - 1 && overflow > 0 ? overflow : null,
                ),
              ),
            ),
          ),
        ],
      ],
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
            // A plain grey stand-in while it loads, and the same with an image
            // mark if it never does — not a coloured gradient, which read as
            // part of the post rather than as a picture still on its way.
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const _Placeholder(showIcon: false),
            errorBuilder: (_, __, ___) => const _Placeholder(),
          )
        else
          const _Placeholder(),
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

/// A neutral tile where a picture is, or should be.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.showIcon = true});

  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return ColoredBox(
      color: c.surface3,
      child: showIcon
          ? Center(
              child: Icon(Icons.image_outlined, color: c.ink3, size: 30),
            )
          : const SizedBox.expand(),
    );
  }
}
