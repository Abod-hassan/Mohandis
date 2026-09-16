import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_mobile_template/app.dart';
import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/config/app_config.dart';
import 'package:flutter_mobile_template/core/config/environment.dart';
import 'package:flutter_mobile_template/core/providers.dart';
import 'package:flutter_mobile_template/core/services/tenant_store.dart';
import 'package:flutter_mobile_template/core/widgets/rung/rung.dart';
import 'package:flutter_mobile_template/features/activity/presentation/screens/notifications_screen.dart';
import 'package:flutter_mobile_template/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/screens/apply_screen.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/screens/jobs_screen.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/screens/my_applications_screen.dart';
import 'package:flutter_mobile_template/features/jobs/presentation/widgets/job_card.dart';
import 'package:flutter_mobile_template/features/messaging/presentation/screens/messages_screen.dart';
import 'package:flutter_mobile_template/features/messaging/presentation/screens/thread_screen.dart';
import 'package:flutter_mobile_template/features/network/presentation/screens/network_screen.dart';
import 'package:flutter_mobile_template/features/posts/presentation/screens/composer_screen.dart';
import 'package:flutter_mobile_template/features/posts/presentation/screens/feed_screen.dart';
import 'package:flutter_mobile_template/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:flutter_mobile_template/features/posts/presentation/widgets/post_card.dart';
import 'package:flutter_mobile_template/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flutter_mobile_template/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_mobile_template/features/reels/presentation/screens/reels_screen.dart';
import 'package:flutter_mobile_template/features/search/presentation/screens/search_screen.dart';
import 'package:flutter_mobile_template/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:flutter_mobile_template/features/shared/auth/data/auth_token_refresher.dart';
import 'package:flutter_mobile_template/features/shared/auth/presentation/screens/auth_screen.dart';
import 'package:flutter_mobile_template/mocks/mock_overrides.dart';

/// In-memory stand-in for the Keychain / EncryptedSharedPreferences channel
/// so the real `TokenStorage` works under the test VM.
void _mockSecureStorage() {
  final store = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
    final key = args['key'] as String?;
    switch (call.method) {
      case 'write':
        if (key != null) store[key] = '${args['value']}';
        return null;
      case 'read':
        return key == null ? null : store[key];
      case 'readAll':
        return Map<String, String>.from(store);
      case 'delete':
        store.remove(key);
        return null;
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(key);
      default:
        return null;
    }
  });
}

const _config = AppConfig(
  environment: Environment.dev,
  appName: 'رنق (Test)',
  apiBaseUrl: 'https://api-dev.rung.app',
  useMockData: true,
  enableLogging: false,
);

/// Pre-resolved, so the auth screen's `/health` lookup short-circuits instead
/// of putting a real Dio request — and its connect timer — into a widget test.
class _ResolvedTenant extends TenantNotifier {
  @override
  int? build() => 1;
}

Widget _app() => ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_config),
        tenantProvider.overrideWith(_ResolvedTenant.new),
        tokenRefresherProvider.overrideWith(
          (ref) => AuthTokenRefresher(
            baseUrl: _config.apiBaseUrl,
            refreshPath: EndPoints.authRefresh,
            tokenStorage: ref.read(tokenStorageProvider),
          ),
        ),
        ...mockOverrides(),
      ],
      child: const App(),
    );

/// Fills the sign-in form and submits it.
///
/// The auth screen is a real form now: the sheet's title is "تسجيل الدخول" and
/// the submit button is "دخول", so tapping the title does nothing, and an empty
/// form fails validation before it ever reaches the repository. The mock
/// repository accepts any credentials.
Future<void> _signIn(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'demo');
  await tester.enterText(fields.at(1), 'demo');
  await tester.tap(find.text('دخول'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _mockSecureStorage();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('cold start lands on auth, signing in reaches the feed',
      (tester) async {
    await tester.pumpWidget(_app());

    // Splash holds for its minimum window, then the redirect resolves.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);

    await _signIn(tester);

    expect(find.byType(FeedScreen), findsOneWidget);
    expect(find.byType(PostCard), findsWidgets);
  });

  testWidgets('bottom nav switches between the primary tabs', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await _signIn(tester);

    await tester.tap(find.text('الوظائف'));
    await tester.pumpAndSettle();
    expect(find.byType(JobsScreen), findsOneWidget);

    await tester.tap(find.text('لوحتي'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('أكمل التعلّم'), findsOneWidget);

    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedScreen), findsOneWidget);
  });

  testWidgets('every primary surface renders without layout errors',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await _signIn(tester);

    Future<void> visitTab(String label, Type screen) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: 'tab $label');
    }

    await visitTab('ريلز', ReelsScreen);
    await visitTab('شبكتي', NetworkScreen);
    await visitTab('الرئيسية', FeedScreen);

    // Pushed surfaces, each popped before the next so the stack stays shallow.
    Future<void> visitPushed(
      Finder trigger,
      Type screen, {
      String? reason,
    }) async {
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget, reason: reason ?? '$screen');
      Navigator.of(tester.element(find.byType(screen))).pop();
      await tester.pumpAndSettle();
    }

    await visitPushed(find.byType(RungSearchField).first, SearchScreen);
    await visitPushed(find.byIcon(Icons.chat_bubble_outline_rounded).first,
        MessagesScreen);
    await visitPushed(find.byType(PostCard).first, PostDetailScreen);
    await visitPushed(find.byType(RungAvatar).first, ProfileScreen);

    // Jobs stack: list → detail → apply.
    await tester.tap(find.text('الوظائف'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(JobCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(JobDetailScreen), findsOneWidget);

    await tester.tap(find.text('قدّم الآن'));
    await tester.pumpAndSettle();
    expect(find.byType(ApplyScreen), findsOneWidget);
    expect(find.text('سيرتك الذاتية'), findsOneWidget);

    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة وإرسال'), findsOneWidget);

    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('تم إرسال طلبك!'), findsOneWidget);

    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();

    // "تم" pops back to the job detail; pop again to reach the jobs list.
    Navigator.of(tester.element(find.byType(JobDetailScreen))).pop();
    await tester.pumpAndSettle();

    // My applications, reached from the jobs header.
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();
    expect(find.byType(MyApplicationsScreen), findsOneWidget);
    expect(find.byType(StatusStepper), findsWidgets);
    Navigator.of(tester.element(find.byType(MyApplicationsScreen))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('composer, story, thread, notifications, and edit profile render',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await _signIn(tester);

    // Composer, opened from the feed entry row.
    await tester.tap(find.text('شارك تحديثاً أو فكرة…'));
    await tester.pumpAndSettle();
    expect(find.byType(ComposerScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'منشور من الاختبار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('نشر'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedScreen), findsOneWidget);
    expect(find.text('منشور من الاختبار'), findsOneWidget);

    // Story viewer — its progress bar animates continuously, so drive it with
    // fixed pumps rather than pumpAndSettle, and pop before it auto-advances.
    await tester.tap(find.text('أمل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StoryViewerScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(StoryViewerScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Messages → thread.
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أمل العتيبي'));
    await tester.pumpAndSettle();
    expect(find.byType(ThreadScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'رسالة اختبار');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('رسالة اختبار'), findsOneWidget);
    Navigator.of(tester.element(find.byType(ThreadScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(MessagesScreen))).pop();
    await tester.pumpAndSettle();

    // Notifications, reached from the dashboard bell.
    await tester.tap(find.text('لوحتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    await tester.tap(find.text('تعليم الكل كمقروء'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(NotificationsScreen))).pop();
    await tester.pumpAndSettle();

    // Own profile → edit profile.
    await tester.tap(find.byType(RungAvatar).first);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.tap(find.text('تعديل الملف'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('الاسم الكامل'), findsOneWidget);
  });
}
