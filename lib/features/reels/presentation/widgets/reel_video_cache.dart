import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// A small window of live [VideoPlayerController]s around the page in view.
///
/// **Why a cache and not one controller per page.** A `PageView.builder` would
/// happily build a controller per item and keep them; a few dozen reels of open
/// sockets and decoders is how a video feed cooks a phone and then gets killed.
/// Initialising only on arrival is just as wrong — the decoder has to fetch the
/// header and buffer before it shows anything, so every swipe lands on black.
///
/// So: hold [_ahead] pages forward and [_behind] back. The current one plays,
/// its neighbours sit initialised and paused ready to take over, and anything
/// further away is disposed. Forward gets the bigger share because that is the
/// direction people swipe; one back covers the "wait, what was that" flick.
///
/// Order matters as much as size: the reel in view is opened FIRST and starts
/// the moment it is ready, and the neighbours are opened after it, in
/// parallel. This used to open the window one reel at a time, previous reel
/// first, and only press play once all three were ready — so every swipe
/// waited on up to three network round-trips, and a fast swipe waited on a
/// neighbour it had already left.
class ReelVideoCache extends ChangeNotifier {
  ReelVideoCache();

  static const int _ahead = 2;
  static const int _behind = 1;

  /// Offsets from the current page, in the order they are opened: 0, +1, -1,
  /// +2, …
  static final List<int> _openOrder = [
    0,
    for (var k = 1; k <= (_ahead > _behind ? _ahead : _behind); k++) ...[
      if (k <= _ahead) k,
      if (k <= _behind) -k,
    ],
  ];

  final Map<String, VideoPlayerController> _controllers = {};
  final Set<String> _initialising = {};

  /// Guards against an older, slower [setIndex] finishing after a newer one and
  /// playing a reel the viewer has already swiped past. Every suspension point
  /// re-checks it.
  int _generation = 0;

  /// What the last accepted [setIndex] was for. The screen calls setIndex from
  /// a post-frame callback on EVERY build — a like, a page of loadMore landing,
  /// a theme change — so without this the window is reconciled, and `play()`
  /// re-issued, at frame rate. Worse, the reconciliation ends in
  /// `notifyListeners`, which triggers the rebuild that schedules the next one:
  /// a loop that never settles while the tab is open.
  String? _currentId;
  String _idsKey = '';

  /// Set when the viewer taps to pause. Without it the next reconciliation
  /// would call `play()` again and the reel would simply be unpausable.
  bool _pausedByUser = false;

  bool _muted = true;
  bool _disposed = false;

  /// Set by [pauseAll] — the tab is hidden or the app is in the background.
  /// While set, nothing may start playing: not an open that finishes late,
  /// not a resume. Cleared by the next accepted [setIndex] (the screen only
  /// calls it while visible) or by [resumeCurrent].
  bool _suspended = false;

  /// Reels whose open failed, with the URL that failed and when.
  ///
  /// Not retried on every rebuild for the same URL — the screen calls
  /// [setIndex] per frame, so an un-gated retry would be a request per frame
  /// — and always retried once the URL changes.
  ///
  /// **The time is what Stream added.** On the storage zone a 404 was final:
  /// the file was there or it was not. A Stream playlist does not exist until
  /// the library has transcoded a rendition, so a reel published a minute ago
  /// answers 404 and then starts working on its own. Recording that as a
  /// permanent failure meant the author swiped to their brand-new reel, saw
  /// black, and nothing ever tried again for the life of the session —
  /// including after the video had been ready for ten minutes.
  final Map<String, _FailedOpen> _failedUrl = {};

  /// How long a failed open is trusted before it is worth another try.
  /// Long enough not to hammer a genuinely dead URL on every swipe, short
  /// enough that a transcode finishing is noticed without leaving the screen.
  static const Duration _retryAfter = Duration(seconds: 8);

  /// Wakes the screen once a failure has expired.
  ///
  /// The expiry alone would not be enough: nothing re-reads it. `_ensure` runs
  /// from `setIndex`, which the screen calls from a post-frame callback — so
  /// with no swipe and no rebuild, a reel that failed would sit on its poster
  /// forever while a perfectly good playlist waited behind it. One timer, not
  /// one per reel: it only has to make the screen look again.
  Timer? _retryTimer;

  /// Reels start muted. Autoplaying sound into a room is the fastest way to
  /// make somebody close an app.
  bool get muted => _muted;

  VideoPlayerController? controllerFor(String reelId) => _controllers[reelId];

  /// Brings the window in line with [index] and plays the reel at it.
  ///
  /// [urls] maps id to a FULLY RESOLVED video URL. Resolution is the caller's
  /// job: the module stores media host-less, and a bare `reels/uuid.mp4` has no
  /// scheme for the player to open.
  Future<void> setIndex({
    required int index,
    required List<String> ids,
    required Map<String, String?> urls,
  }) async {
    if (_disposed) return;

    final currentId = index >= 0 && index < ids.length ? ids[index] : null;
    final idsKey = ids.join('|');
    final wasSuspended = _suspended;
    _suspended = false;

    // Nothing to do only if the window is unchanged, we were not just
    // un-hidden (then the current reel is paused and must be restarted), and
    // the current reel is open, opening, or cannot be opened yet. The last
    // clause is what lets a reel whose URL resolved late — the storage zone
    // arrived after the list — still start instead of sitting on its poster.
    if (currentId == _currentId &&
        idsKey == _idsKey &&
        !wasSuspended &&
        !_needsOpen(currentId, urls)) {
      return;
    }

    // Only a NEW reel clears a hand-made pause. A page of loadMore landing,
    // or coming back to the tab, must not restart what the viewer stopped.
    if (currentId != _currentId) _pausedByUser = false;
    _currentId = currentId;
    _idsKey = idsKey;
    final gen = ++_generation;

    // Nearest first, forward before back — the order they are opened in.
    final wanted = <String>{
      for (final offset in _openOrder)
        if (index + offset >= 0 && index + offset < ids.length)
          ids[index + offset],
    };

    // Evict first, so a fast scroll never holds more than the window's worth
    // of decoders. Not awaited: the teardown runs on the platform side, and
    // the reel now in view should not wait for an old one to finish dying.
    for (final id in _controllers.keys.toList()) {
      if (wanted.contains(id)) continue;
      final gone = _controllers.remove(id);
      if (gone == null) continue;
      // No pause() first: dispose() tears playback down anyway, and a
      // pause() that threw would skip it and leak the native player.
      unawaited(
        gone.dispose().catchError((Object e) {
          if (kDebugMode) debugPrint('[reels] dispose failed for $id: $e');
        }),
      );
    }

    if (_disposed || gen != _generation) return;

    // Pause the rest BEFORE opening anything, so the reel just left stops
    // talking immediately rather than after the new one has loaded.
    await _settleOthers(currentId, gen);
    if (_disposed || gen != _generation) return;

    // The reel in view first, on its own: it is the one somebody is looking
    // at. If it is already initialising (it was a neighbour a moment ago),
    // _ensure returns at once and the in-flight open plays it on arrival.
    if (currentId != null) await _ensure(currentId, urls[currentId]);
    if (_disposed || gen != _generation) return;
    await _playIfCurrent(currentId);

    // **The neighbours wait for the visible reel to actually start.**
    //
    // `initialize()` returns as soon as the player knows the video's shape —
    // well before it has buffered enough to show a frame. Opening the
    // neighbours at that moment put three more video sessions on the wire
    // exactly while the one on screen was trying to fill its buffer, and they
    // took a share of a phone's uplink each.
    //
    // That was survivable with progressive MP4, where a reel was one request
    // that streamed in order. It is not with HLS: every stream spends its
    // first seconds probing bandwidth to choose a rendition, so three
    // background streams do not just take throughput, they talk the visible
    // one into picking a lower-quality ladder rung than the connection can
    // actually carry.
    //
    // Bounded, because "playing" may never arrive — a dead URL, a transcode
    // not finished, a reel paused by hand the instant it opened. After the
    // timeout the neighbours load anyway; being late is better than a swipe
    // landing on nothing.
    await _firstFrame(currentId);
    if (_disposed || gen != _generation) return;

    await Future.wait([
      for (final id in wanted)
        if (id != currentId) _ensure(id, urls[id]),
    ]);
    if (_disposed || gen != _generation) return;
    _notify();
  }

  /// Whether [id] has a usable URL but no controller, no open in flight, and
  /// no failed open for that same URL.
  bool _needsOpen(String? id, Map<String, String?> urls) {
    if (id == null) return false;
    final url = urls[id];
    if (url == null || url.trim().isEmpty) return false;
    if (_controllers.containsKey(id) || _initialising.contains(id)) {
      return false;
    }
    final failed = _failedUrl[id];
    if (failed == null || failed.url != url) return true;
    return DateTime.now().difference(failed.at) >= _retryAfter;
  }

  /// Pauses and rewinds every reel but [currentId].
  Future<void> _settleOthers(String? currentId, int gen) async {
    // `.toList()`: play/pause suspend, and an in-flight _ensure or a newer
    // setIndex can mutate the map underneath a live iterator.
    for (final entry in _controllers.entries.toList()) {
      if (_disposed || gen != _generation) return;
      if (entry.key == currentId) continue;
      final c = entry.value;
      if (!c.value.isInitialized) continue;
      try {
        if (c.value.isPlaying) await c.pause();
        // Rewound, so returning to a reel restarts it rather than resuming
        // halfway through a clip the viewer barely saw.
        if (c.value.position != Duration.zero) await c.seekTo(Duration.zero);
      } catch (e) {
        if (kDebugMode) debugPrint('[reels] settle failed for ${entry.key}: $e');
      }
    }
  }

  /// Plays [id] if it is still the reel in view and the viewer has not paused
  /// it. Called when the window moves AND when an open finishes, whichever
  /// comes second — that is what lets a reel that was still loading when it
  /// was swiped to start by itself instead of sitting on its thumbnail.
  Future<void> _playIfCurrent(String? id) async {
    if (id == null ||
        _disposed ||
        _suspended ||
        _pausedByUser ||
        id != _currentId) {
      return;
    }
    final c = _controllers[id];
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setVolume(_muted ? 0 : 1);
      if (!c.value.isPlaying) await c.play();
    } catch (e) {
      if (kDebugMode) debugPrint('[reels] play failed for $id: $e');
    }
    _notify();
  }

  Future<void> _ensure(String id, String? url) async {
    if (_disposed) return;
    if (url == null || url.trim().isEmpty) return;
    if (_controllers.containsKey(id) || _initialising.contains(id)) return;
    final failed = _failedUrl[id];
    if (failed != null &&
        failed.url == url &&
        DateTime.now().difference(failed.at) < _retryAfter) {
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      // Recorded as failed, or setIndex would see "needs opening" on every
      // frame and reconcile — and notify, and rebuild — forever.
      _recordFailure(id, url);
      if (kDebugMode) debugPrint('[reels] $id has an unusable url: $url');
      return;
    }

    _initialising.add(id);

    // **Say it is HLS rather than letting the player guess.** Both platforms
    // infer the source type from the URL, and both get `…/playlist.m3u8`
    // right — but that inference is the extension, not the content, so a
    // signed or query-stringed playlist URL (which is what a Stream library
    // with token authentication hands out) is read as a progressive file and
    // fails with a decode error rather than anything that names the cause.
    // The hint costs nothing and removes the whole class.
    final controller = VideoPlayerController.networkUrl(
      uri,
      formatHint: _looksLikeHls(uri) ? VideoFormat.hls : null,
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (_disposed) {
        await controller.dispose();
        return;
      }
      // Evicted while it was loading (the window moved on past it): nobody
      // will ever ask for it, so it must not be adopted and leak a decoder.
      if (!_stillWanted(id)) {
        await controller.dispose();
        return;
      }
      _failedUrl.remove(id);
      _controllers[id] = controller;
      _notify();
      // Swiped to while still loading: start now, not on the next swipe.
      await _playIfCurrent(id);
    } catch (e) {
      // A dead URL is one broken reel, not a broken feed: the page keeps its
      // thumbnail and the pager keeps working.
      _recordFailure(id, url);
      await controller.dispose();
      // The URL, not just the error. A 404 here has three different causes
      // that read identically — a poster or playlist Stream has not finished
      // making, a row built against the wrong CDN hostname, and a storage-zone
      // reel that never had an HLS playlist — and which one it is can only be
      // told from the address that was asked for.
      if (kDebugMode) debugPrint('[reels] $id failed to open: $url\n  $e');
    } finally {
      _initialising.remove(id);
    }
  }

  /// Resolves once [id] is actually playing, or after a short grace period.
  ///
  /// Polling rather than a listener: `VideoPlayerController` notifies on every
  /// position tick, so a listener here would mean attaching and detaching one
  /// per swipe for a value that is checked four times.
  static const Duration _firstFrameTimeout = Duration(milliseconds: 1200);

  Future<void> _firstFrame(String? id) async {
    if (id == null) return;
    final deadline = DateTime.now().add(_firstFrameTimeout);
    while (!_disposed && DateTime.now().isBefore(deadline)) {
      final c = _controllers[id];
      if (c == null) return; // never opened; nothing to wait for
      if (c.value.isPlaying || c.value.hasError) return;
      // Paused on purpose, or hidden: the viewer is not waiting on a frame.
      if (_pausedByUser || _suspended) return;
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }

  /// Marks an open as failed and arranges for one more look later.
  void _recordFailure(String id, String url) {
    _failedUrl[id] = _FailedOpen(url);
    _retryTimer ??= Timer(_retryAfter, () {
      _retryTimer = null;
      // Just a nudge. The screen rebuilds, calls setIndex, and `_needsOpen`
      // decides for itself whether the failure has aged out.
      _notify();
    });
  }

  /// An `.m3u8` anywhere in the path — Stream's playlists, and nothing the
  /// storage zone serves.
  static bool _looksLikeHls(Uri uri) =>
      uri.path.toLowerCase().endsWith('.m3u8');

  /// Whether [id] is inside the window the last [setIndex] asked for.
  bool _stillWanted(String id) {
    final ids = _idsKey.split('|');
    final current = _currentId == null ? -1 : ids.indexOf(_currentId!);
    final at = ids.indexOf(id);
    if (current < 0 || at < 0) return false;
    final offset = at - current;
    return offset <= _ahead && -offset <= _behind;
  }

  /// Pauses everything — the tab went away, or the app went to the background.
  Future<void> pauseAll() async {
    _suspended = true;
    for (final c in _controllers.values.toList()) {
      if (c.value.isInitialized && c.value.isPlaying) await c.pause();
    }
  }

  /// Resumes the reel in view, unless the viewer paused it by hand.
  Future<void> resumeCurrent() async {
    _suspended = false;
    final id = _currentId;
    if (id == null || _disposed || _pausedByUser) return;
    final c = _controllers[id];
    if (c == null || !c.value.isInitialized) return;
    await c.setVolume(_muted ? 0 : 1);
    await c.play();
  }

  Future<void> toggleMute(String reelId) async {
    _muted = !_muted;
    final c = _controllers[reelId];
    if (c != null && c.value.isInitialized) {
      await c.setVolume(_muted ? 0 : 1);
    }
    _notify();
  }

  Future<void> togglePlay(String reelId) async {
    final c = _controllers[reelId];
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      _pausedByUser = true;
      await c.pause();
    } else {
      _pausedByUser = false;
      await c.play();
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    for (final c in _controllers.values.toList()) {
      // Fire-and-forget: dispose() is async, a sync dispose() cannot await, and
      // this is the last thing that will ever touch these.
      unawaited(c.dispose());
    }
    _controllers.clear();
    super.dispose();
  }
}

/// A failed open, and when it failed. See `_failedUrl`.
class _FailedOpen {
  _FailedOpen(this.url) : at = DateTime.now();

  final String url;
  final DateTime at;
}
