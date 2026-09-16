import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/base/base_list_notifier.dart';
import 'package:flutter_mobile_template/core/base/base_repository.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../../data/repositories/reel_repository_impl.dart';
import '../../domain/entities/reel.dart';

class ReelsNotifier extends BaseListNotifier<Reel> {
  @override
  BaseRepository<Reel> get repository => ref.read(reelRepositoryProvider);

  /// The last page number successfully appended. `ReelFilter` is
  /// page-numbered rather than cursor-paged, so this is the whole cursor.
  int _page = 1;

  /// From `IPagedList.HasNextPage`, not from the row count — the server can
  /// answer with fewer rows than the size it was asked for and still have a
  /// next page.
  bool _hasMore = false;

  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<Reel>> build() => _first();

  @override
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_first);
  }

  Future<List<Reel>> _first() async {
    final result = await ref.read(reelRepositoryProvider).wall(query: query);
    return result.when(
      success: (page) {
        _page = 1;
        _hasMore = page.hasMore;
        return page.reels;
      },
      failure: (e) {
        _page = 1;
        _hasMore = false;
        throw e;
      },
    );
  }

  /// Appends the next page. Silent on failure: the wall is a full-screen
  /// video pager, and an error banner over a reel that is already playing
  /// would be worse than simply not growing — the next swipe retries.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _loadingMore = true;
    final next = _page + 1;
    final result = await ref.read(reelRepositoryProvider).wall(
          query: {...?query, 'page': next},
        );
    _loadingMore = false;

    result.when(
      success: (page) {
        _page = next;
        _hasMore = page.hasMore;
        if (page.reels.isEmpty) return;
        // Reels can repeat across pages when a new one is published mid-scroll
        // and shifts the offsets; appending blind would put the same id in the
        // pager twice and break the PageView's keys.
        final seen = {for (final r in current) r.id};
        final fresh =
            page.reels.where((r) => !seen.contains(r.id)).toList(growable: false);
        if (fresh.isEmpty) return;
        state = AsyncValue.data([...current, ...fresh]);
      },
      failure: (_) {},
    );
  }

  /// Publishes a reel and puts it at the head of the wall.
  ///
  /// The page cursor is deliberately NOT reset. `_page` counts pages already
  /// appended from the server, and prepending a row the server will also
  /// return on page 1 does not change which pages those were — resetting it
  /// would re-fetch and duplicate everything already on screen.
  ///
  /// The duplicate that DOES appear — this reel, again, when page 1 is
  /// re-read — is what `refresh` is for; the wall is pull-to-refreshable and
  /// the fan-out is asynchronous server-side anyway.
  Future<Result<Reel, AppException>> publish({
    required String videoUrl,
    String caption = '',
    double? durationSeconds,
  }) async {
    final result = await ref.read(reelRepositoryProvider).create({
      'videoUrl': videoUrl,
      'caption': caption.trim(),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    });

    result.when(
      success: (reel) {
        // See StoriesNotifier.publish — same reasoning, same failure without
        // it: publish a reel without ever having opened the Reels tab and the
        // wall's first read, issued a moment earlier by this very call, lands
        // without the new row.
        final current = state.valueOrNull;
        if (current == null) {
          // Still loading, or failed. The read that is in flight was ISSUED
          // BEFORE this publish committed, so its page cannot contain the new
          // row — and letting it land would publish a list that silently omits
          // what was just posted. Re-running it is the only honest answer.
          //
          // This is the common case, not the edge one: reading `.notifier` to
          // call this method is itself what starts the first load.
          ref.invalidateSelf();
          return;
        }
        state = AsyncValue.data([reel, ...current]);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Reel, AppException>> toggleLike(String reelId) => _optimistic(
        reelId,
        (r) => r.toggleLike(),
        ref.read(reelRepositoryProvider).toggleLike,
      );

  Future<Result<Reel, AppException>> toggleSave(String reelId) => _optimistic(
        reelId,
        (r) => r.toggleSave(),
        ref.read(reelRepositoryProvider).toggleSave,
      );

  /// Counts a playback. Nothing in the list changes — the server owns the play
  /// count and only reports it on the next read — and a failure is
  /// deliberately silent: a lost counter must not throw an error banner over a
  /// reel the user is already watching.
  Future<void> markPlayed(String reelId) async {
    await ref.read(reelRepositoryProvider).markPlayed(reelId);
  }

  Future<Result<Reel, AppException>> _optimistic(
    String reelId,
    Reel Function(Reel) transform,
    Future<Result<Reel, AppException>> Function(String) call,
  ) async {
    final previous = state.valueOrNull;
    if (previous == null) return call(reelId);

    state = AsyncValue.data([
      for (final r in previous) r.id == reelId ? transform(r) : r,
    ]);

    final result = await call(reelId);
    return result.when(
      success: (server) {
        final current = state.valueOrNull ?? previous;
        state = AsyncValue.data([
          for (final r in current) r.id == server.id ? server : r,
        ]);
        return Result<Reel, AppException>.success(server);
      },
      failure: (e) {
        state = AsyncValue.data(previous);
        return Result<Reel, AppException>.failure(e);
      },
    );
  }
}

final reelsNotifierProvider =
    AsyncNotifierProvider<ReelsNotifier, List<Reel>>(ReelsNotifier.new);
