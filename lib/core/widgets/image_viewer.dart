import 'package:flutter/material.dart';

/// Full-screen image preview: pinch or double-tap to zoom, swipe sideways
/// between pictures, swipe down (or tap ✕) to close.
///
/// Takes already-resolved URLs — callers run their host-less paths through
/// `imageUrlResolverProvider` first, the same as every other `Image.network`.
///
/// Pushed on the root navigator so it covers the bottom bar, and as a
/// non-opaque route so the page underneath shows through while the viewer is
/// dragged down.
Future<void> showImageViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => ImageViewer(
        urls: urls,
        initialIndex: initialIndex.clamp(0, urls.length - 1),
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, required this.urls, this.initialIndex = 0});

  final List<String> urls;
  final int initialIndex;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// Whether the current picture is zoomed in. While it is, a drag pans the
  /// picture instead of paging to the next one or dismissing the viewer.
  bool _zoomed = false;

  /// Vertical offset of the swipe-to-dismiss drag.
  double _drag = 0;

  static const double _dismissDistance = 120;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_zoomed) return;
    setState(() => _drag += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_zoomed) return;
    final fling = (d.primaryVelocity ?? 0).abs() > 900;
    if (_drag.abs() > _dismissDistance || fling) {
      Navigator.of(context).pop();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = (1 - _drag.abs() / 400).clamp(0.3, 1.0);
    final many = widget.urls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
            onVerticalDragEnd: _zoomed ? null : _onDragEnd,
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: PageView.builder(
                controller: _pages,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _zoomed = false;
                }),
                itemBuilder: (_, i) => _ZoomablePicture(
                  // Keyed by index so leaving a page drops its zoom.
                  key: ValueKey(i),
                  url: widget.urls[i],
                  onZoomChanged: (z) {
                    if (i == _index && z != _zoomed) {
                      setState(() => _zoomed = z);
                    }
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (many)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        // Counter reads the same in either direction.
                        '${_index + 1} / ${widget.urls.length}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomablePicture extends StatefulWidget {
  const _ZoomablePicture({
    super.key,
    required this.url,
    required this.onZoomChanged,
  });

  final String url;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePicture> createState() => _ZoomablePictureState();
}

class _ZoomablePictureState extends State<_ZoomablePicture>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _tween;
  TapDownDetails? _doubleTap;
  bool _zoomed = false;

  static const double _doubleTapScale = 2.5;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_reportZoom);
    _anim.addListener(() {
      final t = _tween;
      if (t != null) _transform.value = t.value;
    });
  }

  @override
  void dispose() {
    _transform.removeListener(_reportZoom);
    _transform.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _reportZoom() {
    final z = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (z != _zoomed) {
      _zoomed = z;
      widget.onZoomChanged(z);
    }
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward(from: 0);
  }

  void _toggleZoom() {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    final p = _doubleTap?.localPosition ?? Offset.zero;
    // Zoom toward the tapped point: move it to the origin, scale, move back.
    final m = Matrix4.identity()
      ..translateByDouble(
        -p.dx * (_doubleTapScale - 1),
        -p.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    _animateTo(m);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTap = d,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        child: SizedBox.expand(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  ),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
