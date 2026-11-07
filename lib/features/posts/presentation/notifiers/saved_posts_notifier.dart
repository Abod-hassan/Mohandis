import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';

/// The caller's bookmarked posts.
///
/// `autoDispose` for the same reason as `savedJobsProvider`: `Post.saved` is a
/// snapshot, and un-saving from the feed has to be reflected the next time this
/// list is opened rather than the next time the app is restarted.
/// Posts carrying one hashtag — the hashtag page. Keyed by the tag without
/// its `#`, autoDispose so a page opened again reads fresh.
final hashtagPostsProvider =
    FutureProvider.autoDispose.family<List<Post>, String>((ref, tag) async {
  final result = await ref.watch(postRepositoryProvider).byHashtag(tag);
  return result.when(success: (posts) => posts, failure: (e) => throw e);
});

final savedPostsProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  final result = await ref.watch(postRepositoryProvider).saved();
  return result.when(success: (posts) => posts, failure: (e) => throw e);
});
