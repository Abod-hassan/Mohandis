import 'package:flutter_mobile_template/core/base/base_repository.dart';
import 'package:flutter_mobile_template/core/error/app_exception.dart';
import 'package:flutter_mobile_template/core/error/result.dart';

import '../entities/reel.dart';
import '../entities/reel_page.dart';

abstract class ReelRepository extends BaseRepository<Reel> {
  /// One page of the reel wall. [query] takes the same keys as [getAll] —
  /// `onlySaved`, `onlyLiked`, `followedOnly`, `authorIds`, `search`, `page`
  /// and `size` — and `getAll` is its first page, so a notifier can start
  /// from the base contract and page on from here.
  Future<Result<ReelPage, AppException>> wall({Map<String, dynamic>? query});

  /// Toggles the caller's like. Returns the reel as the server sees it, so an
  /// optimistic UI update can be reconciled rather than trusted.
  Future<Result<Reel, AppException>> toggleLike(String reelId);

  /// Toggles the caller's save, and returns the updated reel the same way
  /// [toggleLike] does. Reels are the only thing this module can save — a post
  /// has no equivalent.
  Future<Result<Reel, AppException>> toggleSave(String reelId);

  /// Counts one playback: a reel that actually started playing, not one that
  /// scrolled past. Fire-and-forget from the UI's side — the count comes back
  /// on the next read, not from this call.
  Future<Result<bool, AppException>> markPlayed(String reelId);
}
