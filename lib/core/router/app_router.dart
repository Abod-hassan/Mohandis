import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/screens/notifications_screen.dart';
import '../../features/panel/domain/repositories/panel_repository.dart';
import '../../features/panel/presentation/screens/course_editor_screen.dart';
import '../../features/panel/presentation/screens/course_lessons_screen.dart';
import '../../features/panel/presentation/screens/my_courses_screen.dart';
import '../../features/admin/presentation/screens/course_purchases_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/jobs/presentation/screens/apply_screen.dart';
import '../../features/jobs/presentation/screens/company_applicants_screen.dart';
import '../../features/jobs/presentation/screens/company_dashboard_screen.dart';
import '../../features/jobs/presentation/screens/company_job_form_screen.dart';
import '../../features/jobs/presentation/screens/company_jobs_screen.dart';
import '../../features/jobs/presentation/screens/job_applicants_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/my_applications_screen.dart';
import '../../features/messaging/presentation/screens/messages_screen.dart';
import '../../features/messaging/presentation/screens/thread_screen.dart';
import '../../features/network/domain/entities/people_list_kind.dart';
import '../../features/network/presentation/screens/people_list_screen.dart';
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
import '../../features/posts/presentation/screens/hashtag_posts_screen.dart';
import '../../features/reels/presentation/notifiers/reels_notifier.dart';
import '../../features/profile/presentation/notifiers/profile_activity_notifier.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/shared/auth/presentation/notifiers/auth_notifier.dart';
import '../../features/shared/auth/presentation/screens/auth_screen.dart';
import '../../features/shared/auth/presentation/screens/email_verify_screen.dart';
import '../../features/shared/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/shared/auth/presentation/screens/verify_screen.dart';
import '../../features/profile/data/profile_setup_store.dart';
import '../../features/profile/presentation/notifiers/profile_notifier.dart';
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

/// Password recovery. Named here for the same reason as the path below, but
/// the other way round: proving a recovery channel SIGNS THE PERSON IN — the
/// session it issues carries `RecoveryVerified`, which is what authorises the
/// reset — so the new-password step happens with a session in hand, on a route
/// under `/auth`. Without an exemption the redirect would bounce them to the
/// feed the instant the code was accepted, one step short of the new password.
const String _forgotPasswordPath = '/auth/forgot';

/// The optional second factor. Named here because the redirect has to know
/// it: it is offered ON the profile step, and the profile step holds the
/// router to exactly one location — so without an exemption the offer would
/// bounce straight back to the screen it was tapped from.
const String _emailVerifyPath = '/settings/email';

/// The only places the profile step is allowed to send someone.
///
/// That step pins the router to one location on purpose — a fresh account
/// with nothing on it has no business in the feed yet. But every screen here
/// fills in part of the very profile it is holding them for, so without an
/// exemption its own links would bounce back to it and read as broken.
/// `/profile/me/...` rather than `:personId`: during onboarding the only
/// profile being edited is this person's own.
const Set<String> _profileSetupDetours = {
  _emailVerifyPath,
  '/profile/me/experience',
  '/profile/me/education',
  '/profile/me/skills',
};

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

      // Anything UNDER /auth counts as the auth flow, not just /auth itself.
      // Sign-up's verification step lives at /auth/verify and runs with no
      // session by definition — an exact match sent it straight back to the
      // form the moment it was pushed.
      final onAuth = loc == '/auth' || loc.startsWith('/auth/');
      if (!isAuthed) return onAuth ? null : '/auth';

      // A freshly registered account owes us the profile step. Held here
      // rather than merely offered it: the account exists but has nothing on
      // it, and a feed is a poor first impression of a network you have not
      // introduced yourself to yet. The screen itself offers a skip, which
      // clears the flag.
      if (ref.read(profileSetupPendingProvider)) {
        // The e-mail step is reachable from here and nothing else is: it is
        // offered on the profile screen, it is optional, and it leaves the
        // flag exactly as it found it — so this person still owes us the
        // profile step when they come back from it.
        // `_forgotPasswordPath` belongs here as well, and it is not
        // hypothetical: the flag is restored from disk asynchronously, so it
        // can flip to true one frame AFTER a recovery session lands. Without
        // this, that timing throws the person onto the profile step with the
        // password they came to change still unchanged — and no way back.
        // Someone recovering a password owes us the profile step AFTER they
        // have a password, not instead of one.
        final allowed =
            loc == _profileSetupPath ||
            loc == _forgotPasswordPath ||
            _profileSetupDetours.contains(loc);
        return allowed ? null : _profileSetupPath;
      }

      // Not `allowed` above: once the flag is clear, /settings/email is an
      // ordinary screen someone reached from Settings, and bouncing it to the
      // feed would make the Settings row inert.
      //
      // `/auth/forgot` is under /auth and is the one route there that a signed
      // in person is SUPPOSED to be on — see the path's own note. Backing out
      // of it lands on /auth, which this line then turns into the feed, so
      // there is no way to get stuck inside the exemption.
      if ((onAuth && loc != _forgotPasswordPath) || loc == _profileSetupPath) {
        return '/feed';
      }

      // A company has no feed tab — its home is the dashboard (see RungShell).
      // Every "go home" in the app points at /feed, including the line above
      // and the splash screen, so this is the one place that has to know: one
      // rewrite here beats an account-type check at a dozen call sites.
      //
      // Only the exact path. `/feed/posts/<id>` and `/feed/composer` stay
      // reachable — a company still writes posts and still opens one from a
      // notification, it simply does not browse a feed of them.
      if (loc == '/feed' && ref.read(isCompanyAccountProvider)) {
        return '/company/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      // Step 2 of sign-up: prove a phone or an e-mail, then spend the token on
      // CreateWithContact. Pushed over /auth rather than replacing it, so
      // backing out returns to a form that still has everything typed in it.
      //
      // Above the redirect's reach on purpose — it sits in the unauthenticated
      // half, and the session it produces is what moves the router on.
      GoRoute(
        path: '/auth/verify',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const VerifyScreen(),
      ),
      // Reached from the sign-in form. Pushed over /auth rather than replacing
      // it, so backing out returns to a form that still has the username in it.
      GoRoute(
        path: _forgotPasswordPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      // App-wide, not per-profile — reached from the profile's options sheet.
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      // No admin routes. Tenant administration — panel access, feed ranking,
      // disciplines, course review, purchase confirmation, course pricing —
      // lives in the web dashboard only. Hiding the rows from non-admins was
      // not enough: the routes themselves are gone, so nothing in this app can
      // reach those screens, by a row, a deep link or a notification.
      // The author's side of the marketplace. Root-level rather than under the
      // panel's branch: "دوراتي" belongs to the person, not to the tab they
      // happened to be on, and it is reached from the panel AND from settings.
      GoRoute(
        path: '/panel/courses/mine',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const MyCoursesScreen(),
        routes: [
          // Before the ':id' route, so the literal wins — otherwise "new" is
          // read as a course id and the editor asks the server for it.
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const CourseEditorScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                CourseEditorScreen(courseId: state.pathParameters['id']),
            routes: [
              // Lessons are their own screen rather than a section of the
              // editor: a lesson hangs off a course id, so it cannot be
              // written until the course has been saved, and the editor now
              // sends people here once it has an id to give.
              GoRoute(
                path: 'lessons',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => CourseLessonsScreen(
                  courseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/panel/courses/earnings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) =>
            const CoursePurchasesScreen(scope: PurchaseScope.earnings),
      ),
      // Optional, and never a gate — see EmailVerifyScreen. Root-level so it
      // covers the nav bar from Settings and sits cleanly over the profile
      // step, which has no shell of its own.
      GoRoute(
        path: _emailVerifyPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EmailVerifyScreen(),
      ),
      // Root-level rather than under a shell branch: saved items belong to the
      // person, not to the tab they happened to be on when they saved
      // something, and both are reached from Settings.
      GoRoute(
        path: '/saved/posts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SavedPostsScreen(),
      ),
      // A hashtag's posts — from a tag in search or under any post.
      GoRoute(
        path: '/hashtags/:tag',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => HashtagPostsScreen(
          tag: state.pathParameters['tag']!.replaceFirst('#', ''),
        ),
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
          // `/profile/<id>/people/<connections|followers|following>`.
          //
          // Nested under the profile so the ProfileId the three module
          // endpoints all require comes straight off the path — none of them
          // resolves "the caller", so there is nothing to look up here.
          //
          // `?me=true` is what enables the Remove / Unfollow button, and the
          // profile screen sets it because it already knows. A deep link that
          // omits it renders the list read-only, which is the safe way to be
          // wrong: both endpoints act on the CALLER's edges, so a button shown
          // on someone else's list would tear down the viewer's own
          // relationship with whoever they happened to be looking at.
          GoRoute(
            path: 'people/:kind',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) => PeopleListScreen(
              kind: PeopleListKind.fromWire(state.pathParameters['kind']),
              profileId: state.pathParameters['personId']!,
              isMe: state.uri.queryParameters['me'] == 'true',
            ),
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
          // One profile's reels, full screen, from its grid. On the root
          // navigator — over the profile, not a switch to the Reels tab — so
          // back returns to the grid it was opened from.
          //
          // The player is the Reels tab's own screen, pointed at this
          // profile's list by a scoped override. The grid's rows ride in as
          // `extra` so the tapped reel opens at once; without them (a cold
          // deep link) the list is read from the server and opens on the
          // first reel.
          GoRoute(
            path: 'reels',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final extra = state.extra;
              final seed = extra is ReelsPlayerSeed ? extra : null;
              final authorId = state.pathParameters['personId']!;
              // Read ABOVE the nested scope, so this is the app's own
              // container — the one holding the Reels tab's wall and the
              // profile grid, which a reel deleted in here must leave too.
              final root = ProviderScope.containerOf(context, listen: false);
              return ProviderScope(
                overrides: [
                  reelsNotifierProvider.overrideWith(
                    () => AuthorReelsNotifier(
                      authorId,
                      seed: seed?.reels,
                      onRemoved: (reelId) {
                        // Only if the wall was ever opened: reading it
                        // otherwise would load it just to drop one row.
                        if (root.exists(reelsNotifierProvider)) {
                          root.read(reelsNotifierProvider.notifier).forget(reelId);
                        }
                        root.invalidate(profileReelsProvider(authorId));
                      },
                    ),
                  ),
                ],
                child: ReelsScreen(
                  standalone: true,
                  initialIndex: seed?.index ?? 0,
                ),
              );
            },
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
          StatefulShellBranch(
            routes: [
              // The company's home. It replaced the feed on that tab: a company
              // follows nobody and is followed instead, so the feed it was
              // given had nothing in it to read.
              GoRoute(
                path: '/company/dashboard',
                builder: (_, __) => const CompanyDashboardScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bridges the providers the redirect reads into a `Listenable` so GoRouter
/// re-evaluates when any of them changes.
///
/// All three matter: auth state decides signed-in vs signed-out, the
/// profile-setup flag decides whether a signed-in user is held on onboarding,
/// and the account type decides where "home" is. Each of them settles
/// asynchronously at startup, so without listening a returning user would land
/// on the wrong screen and stay there.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(this._ref) {
    _subs.add(
      _ref.listen(authNotifierProvider, (_, next) {
        _watchAccountType(next);
        notifyListeners();
      }),
    );
    _subs.add(
      _ref.listen(profileSetupPendingProvider, (_, __) => notifyListeners()),
    );
    _watchAccountType(_ref.read(authNotifierProvider));
  }

  final Ref _ref;
  final List<ProviderSubscription> _subs = [];
  bool _watchingAccountType = false;

  /// Starts listening to the account type — but only once there is a session.
  ///
  /// The account type decides whether `/feed` means the feed or the company
  /// dashboard, and it resolves a moment AFTER the first navigation, so the
  /// redirect has to be re-run when it lands. Listening is what MOUNTS that
  /// provider, though, and it reads `Profiles/Me`: subscribing in the
  /// constructor fired that request on every signed-out cold start, where it
  /// could only 401. Deferred to the first session instead.
  void _watchAccountType(AsyncValue<Object?> auth) {
    if (_watchingAccountType) return;
    final signedIn = auth.maybeWhen(
      data: (session) => session != null,
      orElse: () => false,
    );
    if (!signedIn) return;
    _watchingAccountType = true;
    _subs.add(
      _ref.listen(isCompanyAccountProvider, (_, __) => notifyListeners()),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    super.dispose();
  }
}
