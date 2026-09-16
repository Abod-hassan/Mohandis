import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/activity/data/repositories/activity_mock_repository.dart';
import '../features/activity/data/repositories/activity_repository_impl.dart';
import '../features/dashboard/data/repositories/dashboard_mock_repository.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/jobs/data/repositories/job_mock_repository.dart';
import '../features/jobs/data/repositories/job_repository_impl.dart';
import '../features/messaging/data/repositories/messaging_mock_repository.dart';
import '../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../features/network/data/repositories/network_mock_repository.dart';
import '../features/network/data/repositories/network_repository_impl.dart';
import '../features/posts/data/repositories/post_mock_repository.dart';
import '../features/posts/data/repositories/post_repository_impl.dart';
import '../features/profile/data/repositories/profile_mock_repository.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/reels/data/repositories/reel_mock_repository.dart';
import '../features/reels/data/repositories/reel_repository_impl.dart';
import '../features/search/data/repositories/search_mock_repository.dart';
import '../features/search/data/repositories/search_repository_impl.dart';
import '../features/shared/auth/data/repositories/auth_mock_repository.dart';
import '../features/shared/people/data/repositories/people_mock_repository.dart';
import '../features/shared/people/data/repositories/people_repository_impl.dart';
import '../features/shared/auth/presentation/notifiers/auth_notifier.dart';
import '../features/stories/data/repositories/story_mock_repository.dart';
import '../features/stories/data/repositories/story_repository_impl.dart';

/// Every repository provider swapped for its in-memory twin.
///
/// Applied by `bootstrap` when `AppConfig.useMockData` is true, so the whole
/// app runs against seeded Arabic content with no backend. Deleting a line
/// here is all it takes to move one feature onto the real API.
List<Override> mockOverrides() => [
      peopleRepositoryProvider.overrideWith(
        (ref) => PeopleMockRepository(),
      ),
      postRepositoryProvider.overrideWith(
        (ref) => PostMockRepository(),
      ),
      storyRepositoryProvider.overrideWith(
        (ref) => StoryMockRepository(),
      ),
      reelRepositoryProvider.overrideWith(
        (ref) => ReelMockRepository(),
      ),
      profileRepositoryProvider.overrideWith(
        (ref) => ProfileMockRepository(),
      ),
      networkRepositoryProvider.overrideWith(
        (ref) => NetworkMockRepository(),
      ),
      activityRepositoryProvider.overrideWith(
        (ref) => ActivityMockRepository(),
      ),
      messagingRepositoryProvider.overrideWith(
        (ref) => MessagingMockRepository(),
      ),
      jobRepositoryProvider.overrideWith(
        (ref) => JobMockRepository(),
      ),
      searchRepositoryProvider.overrideWith(
        (ref) => SearchMockRepository(),
      ),
      dashboardRepositoryProvider.overrideWith(
        (ref) => DashboardMockRepository(),
      ),
      // Auth keeps using the real TokenStorage so the splash gate, the router
      // redirect, and logout all exercise their production code paths.
      authRepositoryProvider.overrideWith(
        (ref) => AuthMockRepository(
          tokenStorage: ref.watch(tokenStorageProvider),
        ),
      ),
    ];
