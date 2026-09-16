import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/screens/notifications_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/jobs/presentation/screens/apply_screen.dart';
import '../../features/jobs/presentation/screens/company_applicants_screen.dart';
import '../../features/jobs/presentation/screens/company_job_form_screen.dart';
import '../../features/jobs/presentation/screens/company_jobs_screen.dart';
import '../../features/jobs/presentation/screens/job_applicants_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/my_applications_screen.dart';
import '../../features/messaging/presentation/screens/messages_screen.dart';
import '../../features/messaging/presentation/screens/thread_screen.dart';
import '../../features/network/presentation/screens/network_screen.dart';
import '../../features/panel/domain/entities/panel_entities.dart';
import '../../features/panel/presentation/screens/assistant_screen.dart';
import '../../features/panel/presentation/screens/course_detail_screen.dart';
import '../../features/panel/presentation/screens/courses_screen.dart';
import '../../features/panel/presentation/screens/documents_screen.dart';
import '../../features/panel/presentation/screens/lecture_player_screen.dart';
import '../../features/panel/presentation/screens/lesson_viewer_screen.dart';
import '../../features/panel/presentation/screens/legal_requests_screen.dart';
import '../../features/panel/presentation/screens/notes_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen.dart';
import '../../features/jobs/presentation/screens/saved_jobs_screen.dart';
import '../../features/network/presentation/screens/welcome_connect_screen.dart';
import '../../features/posts/presentation/screens/composer_screen.dart';
import '../../features/posts/presentation/screens/saved_posts_screen.dart';
import '../../features/posts/presentation/screens/feed_screen.dart';
import '../../features/posts/presentation/screens/post_detail_screen.dart';
import '../../features/profile/presentation/screens/edit_education_screen.dart';
import '../../features/profile/presentation/screens/edit_experience_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/edit_skills_screen.dart';
import '../../features/profile/presentation/screens/profile_activity_screen.dart';
import '../../features/profile/presentation/widgets/company_sections.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reels/presentation/screens/reels_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/shared/auth/presentation/notifiers/auth_notifier.dart';
import '../../features/shared/auth/presentation/screens/auth_screen.dart';
import '../../features/profile/data/profile_setup_store.dart';
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/shared/auth/presentation/screens/splash_screen.dart';
import '../../features/stories/presentation/screens/story_viewer_screen.dart';
import 'rung_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes are grouped by chrome:
///
/// * Inside [StatefulShellRoute] — the five primary tabs, each with its own
///   stack, under the bottom nav.
/// * On the root navigator (`parentNavigatorKey: _rootNavigatorKey`) — every
///   pushed screen. These cover the nav bar, matching the design's
///   full-screen detail, composer, story, thread, and apply surfaces.
///
/// Where a newly registered account is held until it has a profile.
const String _profileSetupPath = '/onboarding/profile';

/// See docs/ARCHITECTURE.md §4.6 for the auth redirect contract.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final isAuthed = auth.maybeWhen(
        data: (session) => session != null,
        orElse: () => false,
      );

      final loc = state.matchedLocation;
      // Splash advances itself once auth resolves — never redirect off it.
      if (loc == '/splash') return null;

      final onAuth = loc == '/auth';
      if (!isAuthed) return onAuth ? null : '/auth';

      // A freshly registered account owes us the profile step. Held here
      // rather than merely offered it: the account exists but has nothing on
      // it, and a feed is a poor first impression of a network you have not
      // introduced yourself to yet. The screen itself offers a skip, which
      // clears the flag.
      final onProfileSetup = loc == _profileSetupPath;
      if (ref.read(profileSetupPendingProvider)) {
        return onProfileSetup ? null : _profileSetupPath;
      }

      if (onAuth || onProfileSetup) return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      // App-wide, not per-profile — reached from the profile's options sheet.
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      // Root-level rather than under a shell branch: saved items belong to the
      // person, not to the tab they happened to be on when they saved
      // something, and both are reached from Settings.
      GoRoute(
        path: '/saved/posts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SavedPostsScreen(),
      ),
      GoRoute(
        path: '/saved/jobs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SavedJobsScreen(),
      ),
      GoRoute(
        path: _profileSetupPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      // The last step of sign-up, and not a step: the setup flag is already
      // cleared by the time this renders, so the redirect above lets it stand
      // and the only thing between here and the feed is one tap.
      GoRoute(
        path: '/welcome/connect',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const WelcomeConnectScreen(),
      ),

      // ── Pushed over the shell (no bottom nav) ───────────────────────────
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SearchScreen(),
      ),

      // ── Engineer panel ──────────────────────────────────────────────────
      //
      // All on the root navigator: they are opened from the dashboard tab and
      // cover the nav bar, like every other pushed detail screen.
      GoRoute(
        path: '/panel/courses/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => CoursesScreen(
          category: CourseCategoryLabel.fromSlug(
            state.pathParameters['slug']!,
          ),
        ),
      ),
      // Declared after the category route so `/panel/courses/theory` matches
      // that one; a course id is a GUID, which never collides with a slug.
      GoRoute(
        path: '/panel/course/:courseId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => CourseDetailScreen(
          courseId: state.pathParameters['courseId']!,
        ),
      ),
      // The player takes the whole Lecture through `extra` rather than an id in
      // the path: the URL it plays is decided server-side and arrives with the
      // syllabus, so a route that only carried an id would have to fetch the
      // list again to find out whether this caller may watch it at all. The
      // cost is that this route is not deep-linkable, which a video screen has
      // no business being.
      // The PDF and article viewer. A separate route from the player rather
      // than one screen with a switch: they share nothing but a Lecture, and a
      // video controller has no business being constructed to show text.
      GoRoute(
        path: '/panel/lesson',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final lesson = state.extra;
          if (lesson is! Lecture) return const DashboardScreen();
          return LessonViewerScreen(lesson: lesson);
        },
      ),
      GoRoute(
        path: '/panel/lecture',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final lecture = state.extra;
          // Reached without its extra — a cold deep link, or a restored stack.
          // Sending them back to the panel beats a crash on a null cast.
          if (lecture is! Lecture) return const DashboardScreen();
          return LecturePlayerScreen(lecture: lecture);
        },
      ),
      // Ungated, and outside /panel on purpose: this is where someone lands
      // when the panel is closed to them, so it cannot live behind the panel.
      GoRoute(
        path: '/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/panel/notes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NotesScreen(),
      ),
      GoRoute(
        path: '/panel/documents/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => DocumentsScreen(
          category: DocumentsScreen.fromSlug(state.pathParameters['slug']!),
        ),
      ),
      GoRoute(
        path: '/panel/legal-requests',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LegalRequestsScreen(),
      ),
      GoRoute(
        path: '/panel/assistant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AssistantScreen(
          // Empty starts a new conversation; the first send creates it.
          conversationId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/messages',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MessagesScreen(),
        routes: [
          GoRoute(
            path: ':threadId',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => ThreadScreen(
              threadId: state.pathParameters['threadId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/:personId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ProfileScreen(
          personId: state.pathParameters['personId']!,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const EditProfileScreen(),
          ),
          // The CV editors always act on the signed-in profile — the module's
          // generic-write path keys every row by the caller's own ProfileId —
          // so they take no id of their own, and the pencils that open them
          // only render on your own profile.
          // Anyone's activity, not just your own — the section links here from
          // every profile, so the person id has to ride on the route.
          GoRoute(
            path: 'activity',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => ProfileActivityScreen(
              personId: state.pathParameters['personId']!,
            ),
          ),
          // A company page's postings, for whoever is looking at it. Distinct
          // from the `/company/jobs` TAB, which is the signed-in company's own
          // management list — this one is keyed by the profile being viewed
          // and shows open postings only.
          GoRoute(
            path: 'jobs',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => CompanyProfileJobsScreen(
              personId: state.pathParameters['personId']!,
            ),
          ),
          GoRoute(
            path: 'experience',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const EditExperienceScreen(),
          ),
          GoRoute(
            path: 'education',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const EditEducationScreen(),
          ),
          GoRoute(
            path: 'skills',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const EditSkillsScreen(),
          ),
        ],
      ),

      // ── Primary tabs ────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            RungShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (_, __) => const FeedScreen(),
                routes: [
                  GoRoute(
                    path: 'composer',
                    parentNavigatorKey: _rootNavigatorKey,
                    // `?mode=story|reel` opens the composer already switched.
                    // Unknown values fall back to a post rather than failing
                    // the navigation — an old deep link should still land
                    // somewhere usable.
                    builder: (_, state) => ComposerScreen(
                      initialMode: ComposerMode.fromWire(
                        state.uri.queryParameters['mode'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'posts/:postId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => PostDetailScreen(
                      postId: state.pathParameters['postId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'stories/:storyId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => StoryViewerScreen(
                      storyId: state.pathParameters['storyId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/reels', builder: (_, __) => const ReelsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/jobs',
                builder: (_, __) => const JobsScreen(),
                routes: [
                  // `applications` is declared before `:jobId` so the literal
                  // segment wins the match.
                  GoRoute(
                    path: 'applications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, __) => const MyApplicationsScreen(),
                  ),
                  GoRoute(
                    path: ':jobId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => JobDetailScreen(
                      jobId: state.pathParameters['jobId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'apply',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, state) => ApplyScreen(
                          jobId: state.pathParameters['jobId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/network',
                builder: (_, __) => const NetworkScreen(),
              ),
            ],
          ),

          // ── Company-only branches ─────────────────────────────────────
          //
          // Declared alongside the individual's rather than swapped in: a
          // `StatefulShellRoute`'s branch list is fixed at construction, so
          // both tab sets live here and `RungShell` chooses which of them to
          // draw and how visible position maps onto branch index. The cost is
          // three branches an individual never sees; the alternative is
          // rebuilding the router when the account type resolves, which
          // throws away every branch's navigation stack.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/company/jobs',
                builder: (_, __) => const CompanyJobsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, __) => const CompanyJobFormScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/company/applicants',
                builder: (_, __) => const CompanyApplicantsScreen(),
                routes: [
                  GoRoute(
                    path: ':jobId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => JobApplicantsScreen(
                      jobId: state.pathParameters['jobId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // The same screen the profile route renders, as a tab. A company
              // has no feed-side reason to visit anyone else's profile often,
              // so its own is a destination rather than something reached
              // through an avatar.
              GoRoute(
                path: '/company/profile',
                builder: (_, __) => const ProfileScreen(personId: 'me'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bridges the providers the redirect reads into a `Listenable` so GoRouter
/// re-evaluates when either changes.
///
/// Both matter: auth state decides signed-in vs signed-out, and the
/// profile-setup flag decides whether a signed-in user is held on onboarding.
/// The flag is restored asynchronously at startup, so without listening to it
/// a returning user mid-onboarding would land on the feed.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    _subs = [
      ref.listen(authNotifierProvider, (_, __) => notifyListeners()),
      ref.listen(profileSetupPendingProvider, (_, __) => notifyListeners()),
    ];
  }

  late final List<ProviderSubscription> _subs;

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    super.dispose();
  }
}
