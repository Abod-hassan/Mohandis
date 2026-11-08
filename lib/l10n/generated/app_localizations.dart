import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Product name shown in the OS task switcher.
  ///
  /// In ar, this message translates to:
  /// **'مهندس'**
  String get appTitle;

  /// No description provided for @actionRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get actionSave;

  /// No description provided for @actionDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get actionDone;

  /// No description provided for @actionContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get actionContinue;

  /// No description provided for @actionSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get actionSend;

  /// No description provided for @actionAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get actionAccept;

  /// No description provided for @actionIgnore.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get actionIgnore;

  /// No description provided for @actionChange.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get actionChange;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get comingSoon;

  /// No description provided for @optionalSuffix.
  ///
  /// In ar, this message translates to:
  /// **'(اختياري)'**
  String get optionalSuffix;

  /// No description provided for @applyResumeReplace.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لاستبدال الملف'**
  String get applyResumeReplace;

  /// No description provided for @applyResumeRequired.
  ///
  /// In ar, this message translates to:
  /// **'أرفق سيرتك الذاتية قبل التقديم'**
  String get applyResumeRequired;

  /// No description provided for @requiredSuffix.
  ///
  /// In ar, this message translates to:
  /// **'(مطلوب)'**
  String get requiredSuffix;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مرة أخرى.'**
  String get genericError;

  /// No description provided for @emptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء هنا بعد'**
  String get emptyTitle;

  /// No description provided for @themeToggleToDark.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى المظهر الداكن'**
  String get themeToggleToDark;

  /// No description provided for @themeToggleToLight.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى المظهر الفاتح'**
  String get themeToggleToLight;

  /// Onboarding hero headline.
  ///
  /// In ar, this message translates to:
  /// **'حيث تلتقي المسارات المهنية.'**
  String get authHeroTitle;

  /// No description provided for @authHeroBody.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ ملفك المهني، وسّع شبكتك، شارك أعمالك، واعثر على دورك المهني القادم — في مكان واحد هادئ واحترافي.'**
  String get authHeroBody;

  /// No description provided for @authGetStarted.
  ///
  /// In ar, this message translates to:
  /// **'لنبدأ'**
  String get authGetStarted;

  /// No description provided for @authSignIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccount;

  /// No description provided for @authContinueWith.
  ///
  /// In ar, this message translates to:
  /// **'أو تابع عبر'**
  String get authContinueWith;

  /// No description provided for @authGoogle.
  ///
  /// In ar, this message translates to:
  /// **'جوجل'**
  String get authGoogle;

  /// No description provided for @authApple.
  ///
  /// In ar, this message translates to:
  /// **'آبل'**
  String get authApple;

  /// No description provided for @authTerms.
  ///
  /// In ar, this message translates to:
  /// **'بمتابعتك فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة بمهندس'**
  String get authTerms;

  /// No description provided for @authWelcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك، {name} 👋'**
  String authWelcomeBack(String name);

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navReels.
  ///
  /// In ar, this message translates to:
  /// **'ريلز'**
  String get navReels;

  /// No description provided for @navDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحتي'**
  String get navDashboard;

  /// No description provided for @navJobs.
  ///
  /// In ar, this message translates to:
  /// **'الوظائف'**
  String get navJobs;

  /// No description provided for @navNetwork.
  ///
  /// In ar, this message translates to:
  /// **'الاشخاص'**
  String get navNetwork;

  /// No description provided for @topBarSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن أشخاص أو وظائف أو وسوم'**
  String get topBarSearchHint;

  /// No description provided for @feedYourStory.
  ///
  /// In ar, this message translates to:
  /// **'قصتك'**
  String get feedYourStory;

  /// No description provided for @feedComposerHint.
  ///
  /// In ar, this message translates to:
  /// **'شارك تحديثاً أو فكرة…'**
  String get feedComposerHint;

  /// No description provided for @feedCaughtUp.
  ///
  /// In ar, this message translates to:
  /// **'لقد اطّلعت على كل الجديد ✓'**
  String get feedCaughtUp;

  /// No description provided for @feedRepostedBy.
  ///
  /// In ar, this message translates to:
  /// **'أعاد {name} النشر'**
  String feedRepostedBy(String name);

  /// No description provided for @postActionLike.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب'**
  String get postActionLike;

  /// No description provided for @postActionComment.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get postActionComment;

  /// No description provided for @postActionRepost.
  ///
  /// In ar, this message translates to:
  /// **'إعادة نشر'**
  String get postActionRepost;

  /// No description provided for @postActionSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get postActionSave;

  /// No description provided for @postCommentsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} تعليق'**
  String postCommentsCount(String count);

  /// No description provided for @postRepostsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} إعادة نشر'**
  String postRepostsCount(String count);

  /// No description provided for @postLikesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} إعجاب'**
  String postLikesCount(String count);

  /// No description provided for @postViewJob.
  ///
  /// In ar, this message translates to:
  /// **'عرض الوظيفة والتقديم ←'**
  String get postViewJob;

  /// No description provided for @postDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنشور'**
  String get postDetailTitle;

  /// No description provided for @postAddComment.
  ///
  /// In ar, this message translates to:
  /// **'أضف تعليقاً…'**
  String get postAddComment;

  /// No description provided for @postReply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get postReply;

  /// No description provided for @postLikeWithCount.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب · {count}'**
  String postLikeWithCount(String count);

  /// No description provided for @visibilityPublic.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get visibilityPublic;

  /// No description provided for @visibilityFollowers.
  ///
  /// In ar, this message translates to:
  /// **'المتابعون'**
  String get visibilityFollowers;

  /// No description provided for @visibilityPrivate.
  ///
  /// In ar, this message translates to:
  /// **'خاص'**
  String get visibilityPrivate;

  /// No description provided for @visibilityEveryoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجميع'**
  String get visibilityEveryoneLabel;

  /// No description provided for @visibilityFollowersOnlyLabel.
  ///
  /// In ar, this message translates to:
  /// **'المتابعون فقط'**
  String get visibilityFollowersOnlyLabel;

  /// No description provided for @visibilityOnlyMeLabel.
  ///
  /// In ar, this message translates to:
  /// **'أنا فقط'**
  String get visibilityOnlyMeLabel;

  /// No description provided for @composerTitle.
  ///
  /// In ar, this message translates to:
  /// **'منشور جديد'**
  String get composerTitle;

  /// No description provided for @composerPublish.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get composerPublish;

  /// No description provided for @composerHint.
  ///
  /// In ar, this message translates to:
  /// **'شارك تحديثاً أو فكرة أو فرصة…'**
  String get composerHint;

  /// No description provided for @toastSavedToItems.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ في عناصرك'**
  String get toastSavedToItems;

  /// No description provided for @toastReposted.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد النشر لمتابعيك'**
  String get toastReposted;

  /// No description provided for @toastPosted.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر المنشور ✓'**
  String get toastPosted;

  /// No description provided for @toastSavedToReels.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ في ريلزك'**
  String get toastSavedToReels;

  /// No description provided for @toastProfileUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الملف ✓'**
  String get toastProfileUpdated;

  /// No description provided for @toastApplicationSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الطلب ✓'**
  String get toastApplicationSent;

  /// No description provided for @toastConnectRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلب التواصل إلى {name}'**
  String toastConnectRequestSent(String name);

  /// No description provided for @toastConnected.
  ///
  /// In ar, this message translates to:
  /// **'تم التواصل مع {name}'**
  String toastConnected(String name);

  /// No description provided for @toastFollowing.
  ///
  /// In ar, this message translates to:
  /// **'تتابع الآن {name}'**
  String toastFollowing(String name);

  /// No description provided for @toastUnfollowed.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء المتابعة'**
  String get toastUnfollowed;

  /// No description provided for @storyReplyTo.
  ///
  /// In ar, this message translates to:
  /// **'رد على {name}…'**
  String storyReplyTo(String name);

  /// No description provided for @storyPostedAgo.
  ///
  /// In ar, this message translates to:
  /// **'قبل {time}'**
  String storyPostedAgo(String time);

  /// No description provided for @reelsTitle.
  ///
  /// In ar, this message translates to:
  /// **'ريلز'**
  String get reelsTitle;

  /// No description provided for @reelFollow.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get reelFollow;

  /// No description provided for @reelShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get reelShare;

  /// No description provided for @reelPlays.
  ///
  /// In ar, this message translates to:
  /// **'{count} مشاهدة'**
  String reelPlays(String count);

  /// No description provided for @profileOpenToWork.
  ///
  /// In ar, this message translates to:
  /// **'متاح للعمل'**
  String get profileOpenToWork;

  /// No description provided for @profileHiring.
  ///
  /// In ar, this message translates to:
  /// **'نتوظّف'**
  String get profileHiring;

  /// No description provided for @profileConnections.
  ///
  /// In ar, this message translates to:
  /// **'اتصالاً'**
  String get profileConnections;

  /// No description provided for @profileFollowers.
  ///
  /// In ar, this message translates to:
  /// **'متابعاً'**
  String get profileFollowers;

  /// No description provided for @profileEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف'**
  String get profileEdit;

  /// No description provided for @profileFollow.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get profileFollow;

  /// No description provided for @profileUnfollow.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المتابعة'**
  String get profileUnfollow;

  /// No description provided for @profileConnect.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get profileConnect;

  /// No description provided for @profileAbout.
  ///
  /// In ar, this message translates to:
  /// **'نبذة'**
  String get profileAbout;

  /// No description provided for @profileDownloadCv.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل السيرة الذاتية'**
  String get profileDownloadCv;

  /// No description provided for @profileExperience.
  ///
  /// In ar, this message translates to:
  /// **'الخبرات'**
  String get profileExperience;

  /// No description provided for @profileEducation.
  ///
  /// In ar, this message translates to:
  /// **'التعليم'**
  String get profileEducation;

  /// No description provided for @profileSkills.
  ///
  /// In ar, this message translates to:
  /// **'المهارات'**
  String get profileSkills;

  /// No description provided for @profileEndorsements.
  ///
  /// In ar, this message translates to:
  /// **'{count} تزكية'**
  String profileEndorsements(String count);

  /// No description provided for @profileEndorse.
  ///
  /// In ar, this message translates to:
  /// **'+ تزكية'**
  String get profileEndorse;

  /// No description provided for @editProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف'**
  String get editProfileTitle;

  /// No description provided for @editProfileFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get editProfileFullName;

  /// No description provided for @editProfileHeadline.
  ///
  /// In ar, this message translates to:
  /// **'المسمى المهني'**
  String get editProfileHeadline;

  /// No description provided for @editProfileIndustry.
  ///
  /// In ar, this message translates to:
  /// **'القطاع'**
  String get editProfileIndustry;

  /// No description provided for @editProfileLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get editProfileLocation;

  /// No description provided for @editProfileAbout.
  ///
  /// In ar, this message translates to:
  /// **'نبذة'**
  String get editProfileAbout;

  /// No description provided for @editProfileOpenToWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'متاح للعمل'**
  String get editProfileOpenToWorkTitle;

  /// No description provided for @editProfileOpenToWorkSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أظهر لجهات التوظيف أنك متاح'**
  String get editProfileOpenToWorkSubtitle;

  /// No description provided for @editProfilePrivateTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف خاص'**
  String get editProfilePrivateTitle;

  /// No description provided for @editProfilePrivateSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'وافق على المتابعين قبل رؤية منشوراتك'**
  String get editProfilePrivateSubtitle;

  /// No description provided for @networkTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاشخاص'**
  String get networkTitle;

  /// No description provided for @networkRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات التواصل'**
  String get networkRequests;

  /// No description provided for @networkSuggestions.
  ///
  /// In ar, this message translates to:
  /// **'أشخاص قد تعرفهم'**
  String get networkSuggestions;

  /// No description provided for @networkMutual.
  ///
  /// In ar, this message translates to:
  /// **'{count} معارف مشتركة'**
  String networkMutual(String count);

  /// No description provided for @networkAdd.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة'**
  String get networkAdd;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في مهندس'**
  String get searchHint;

  /// No description provided for @searchTabTop.
  ///
  /// In ar, this message translates to:
  /// **'الأهم'**
  String get searchTabTop;

  /// No description provided for @searchTabPeople.
  ///
  /// In ar, this message translates to:
  /// **'أشخاص'**
  String get searchTabPeople;

  /// No description provided for @searchTabJobs.
  ///
  /// In ar, this message translates to:
  /// **'وظائف'**
  String get searchTabJobs;

  /// No description provided for @searchTabTags.
  ///
  /// In ar, this message translates to:
  /// **'وسوم'**
  String get searchTabTags;

  /// No description provided for @searchTrendingTags.
  ///
  /// In ar, this message translates to:
  /// **'الوسوم الرائجة'**
  String get searchTrendingTags;

  /// No description provided for @searchSectionPeople.
  ///
  /// In ar, this message translates to:
  /// **'أشخاص'**
  String get searchSectionPeople;

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج مطابقة لبحثك'**
  String get searchNoResults;

  /// No description provided for @searchPostsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} منشور'**
  String searchPostsCount(String count);

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsNowConnected.
  ///
  /// In ar, this message translates to:
  /// **'أصبح على تواصل معك'**
  String get notificationsNowConnected;

  /// No description provided for @messagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get messagesTitle;

  /// No description provided for @messagesSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الرسائل'**
  String get messagesSearchHint;

  /// No description provided for @messagesYouPrefix.
  ///
  /// In ar, this message translates to:
  /// **'أنت: '**
  String get messagesYouPrefix;

  /// No description provided for @threadMembers.
  ///
  /// In ar, this message translates to:
  /// **'{count} أعضاء'**
  String threadMembers(String count);

  /// No description provided for @threadInputHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get threadInputHint;

  /// No description provided for @threadToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get threadToday;

  /// No description provided for @threadRead.
  ///
  /// In ar, this message translates to:
  /// **'تمت القراءة'**
  String get threadRead;

  /// No description provided for @threadJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get threadJustNow;

  /// No description provided for @jobsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوظائف'**
  String get jobsTitle;

  /// No description provided for @jobsMyApplications.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get jobsMyApplications;

  /// No description provided for @jobsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'المسمى أو الشركة أو الموقع'**
  String get jobsSearchHint;

  /// No description provided for @jobsFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get jobsFilterAll;

  /// No description provided for @jobsFilterRemote.
  ///
  /// In ar, this message translates to:
  /// **'عن بُعد'**
  String get jobsFilterRemote;

  /// No description provided for @jobsFilterHybrid.
  ///
  /// In ar, this message translates to:
  /// **'هجين'**
  String get jobsFilterHybrid;

  /// No description provided for @jobsFilterOnsite.
  ///
  /// In ar, this message translates to:
  /// **'من المقر'**
  String get jobsFilterOnsite;

  /// No description provided for @jobsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وظائف مطابقة للفلاتر'**
  String get jobsEmpty;

  /// No description provided for @jobPostedAgo.
  ///
  /// In ar, this message translates to:
  /// **'قبل {time}'**
  String jobPostedAgo(String time);

  /// No description provided for @jobApplicants.
  ///
  /// In ar, this message translates to:
  /// **'{count} متقدماً'**
  String jobApplicants(String count);

  /// No description provided for @jobApplied.
  ///
  /// In ar, this message translates to:
  /// **'تم التقديم'**
  String get jobApplied;

  /// No description provided for @jobDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الوظيفة'**
  String get jobDetailTitle;

  /// No description provided for @jobSalaryRange.
  ///
  /// In ar, this message translates to:
  /// **'نطاق الراتب'**
  String get jobSalaryRange;

  /// No description provided for @jobAboutSection.
  ///
  /// In ar, this message translates to:
  /// **'عن الوظيفة'**
  String get jobAboutSection;

  /// No description provided for @jobRequirementsSection.
  ///
  /// In ar, this message translates to:
  /// **'ما نبحث عنه'**
  String get jobRequirementsSection;

  /// No description provided for @jobSkillsSection.
  ///
  /// In ar, this message translates to:
  /// **'المهارات'**
  String get jobSkillsSection;

  /// No description provided for @jobApplyNow.
  ///
  /// In ar, this message translates to:
  /// **'قدّم الآن'**
  String get jobApplyNow;

  /// No description provided for @jobApplicationStatus.
  ///
  /// In ar, this message translates to:
  /// **'الطلب: {status}'**
  String jobApplicationStatus(String status);

  /// No description provided for @applyTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقديم'**
  String get applyTitle;

  /// No description provided for @applyResumeSection.
  ///
  /// In ar, this message translates to:
  /// **'سيرتك الذاتية'**
  String get applyResumeSection;

  /// No description provided for @applyResumeUploaded.
  ///
  /// In ar, this message translates to:
  /// **'تم الرفع · {size}'**
  String applyResumeUploaded(String size);

  /// No description provided for @applyCoverLetterSection.
  ///
  /// In ar, this message translates to:
  /// **'خطاب التقديم'**
  String get applyCoverLetterSection;

  /// No description provided for @applyCoverHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف ملاحظة لفريق التوظيف…'**
  String get applyCoverHint;

  /// No description provided for @applyReviewSection.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة وإرسال'**
  String get applyReviewSection;

  /// No description provided for @applyApplicantLabel.
  ///
  /// In ar, this message translates to:
  /// **'المتقدم'**
  String get applyApplicantLabel;

  /// No description provided for @applyResumeLabel.
  ///
  /// In ar, this message translates to:
  /// **'السيرة الذاتية'**
  String get applyResumeLabel;

  /// No description provided for @applyNoCoverLetter.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة خطاب تقديم.'**
  String get applyNoCoverLetter;

  /// No description provided for @applySubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get applySubmit;

  /// No description provided for @applyDoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك!'**
  String get applyDoneTitle;

  /// No description provided for @applyDoneBody.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك لوظيفة {title} في {company}. يمكنك متابعة حالته من صفحة طلباتي.'**
  String applyDoneBody(String title, String company);

  /// No description provided for @myApplicationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myApplicationsTitle;

  /// No description provided for @myApplicationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تقدّم على أي وظيفة بعد'**
  String get myApplicationsEmpty;

  /// No description provided for @applicationStepSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'الإرسال'**
  String get applicationStepSubmitted;

  /// No description provided for @applicationStepReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة'**
  String get applicationStepReview;

  /// No description provided for @applicationStepShortlist.
  ///
  /// In ar, this message translates to:
  /// **'الاختيار'**
  String get applicationStepShortlist;

  /// No description provided for @applicationStepInterview.
  ///
  /// In ar, this message translates to:
  /// **'المقابلة'**
  String get applicationStepInterview;

  /// No description provided for @applicationStepDecision.
  ///
  /// In ar, this message translates to:
  /// **'القرار'**
  String get applicationStepDecision;

  /// No description provided for @applicationStatusSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال'**
  String get applicationStatusSubmitted;

  /// No description provided for @applicationStatusInReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get applicationStatusInReview;

  /// No description provided for @applicationStatusShortlisted.
  ///
  /// In ar, this message translates to:
  /// **'القائمة المختصرة'**
  String get applicationStatusShortlisted;

  /// No description provided for @applicationStatusInterview.
  ///
  /// In ar, this message translates to:
  /// **'مقابلة'**
  String get applicationStatusInterview;

  /// No description provided for @applicationStatusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get applicationStatusAccepted;

  /// No description provided for @applicationStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get applicationStatusRejected;

  /// No description provided for @dashboardGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مساءً الخير'**
  String get dashboardGreeting;

  /// No description provided for @dashboardContinueLearning.
  ///
  /// In ar, this message translates to:
  /// **'أكمل التعلّم'**
  String get dashboardContinueLearning;

  /// No description provided for @dashboardLectureProgress.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرة {current} من {total} · نظري'**
  String dashboardLectureProgress(String current, String total);

  /// No description provided for @dashboardStatCourses.
  ///
  /// In ar, this message translates to:
  /// **'دورات نشطة'**
  String get dashboardStatCourses;

  /// No description provided for @dashboardStatHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعة تعلّم'**
  String get dashboardStatHours;

  /// No description provided for @dashboardStatCertificates.
  ///
  /// In ar, this message translates to:
  /// **'شهادات'**
  String get dashboardStatCertificates;

  /// No description provided for @dashboardSectionLearning.
  ///
  /// In ar, this message translates to:
  /// **'التعلّم'**
  String get dashboardSectionLearning;

  /// No description provided for @dashboardSectionServices.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get dashboardSectionServices;

  /// No description provided for @dashboardSectionTools.
  ///
  /// In ar, this message translates to:
  /// **'أدواتي'**
  String get dashboardSectionTools;

  /// No description provided for @dashboardNewBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} جديد'**
  String dashboardNewBadge(String count);

  /// No description provided for @dashboardTheory.
  ///
  /// In ar, this message translates to:
  /// **'محاضرات نظرية'**
  String get dashboardTheory;

  /// No description provided for @dashboardTheorySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'دروس ومفاهيم أساسية'**
  String get dashboardTheorySubtitle;

  /// No description provided for @dashboardPractical.
  ///
  /// In ar, this message translates to:
  /// **'محاضرات عملية'**
  String get dashboardPractical;

  /// No description provided for @dashboardPracticalSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيقات وأمثلة عملية'**
  String get dashboardPracticalSubtitle;

  /// No description provided for @dashboardTraining.
  ///
  /// In ar, this message translates to:
  /// **'تدريب وتطوير'**
  String get dashboardTraining;

  /// No description provided for @dashboardTrainingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'برامج تطوير المهارات'**
  String get dashboardTrainingSubtitle;

  /// No description provided for @dashboardEngy.
  ///
  /// In ar, this message translates to:
  /// **'المهندسة إنجي'**
  String get dashboardEngy;

  /// No description provided for @dashboardEngySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مساعدتك الذكية للاستشارات'**
  String get dashboardEngySubtitle;

  /// No description provided for @dashboardEngyBadge.
  ///
  /// In ar, this message translates to:
  /// **'AI'**
  String get dashboardEngyBadge;

  /// No description provided for @dashboardLegalRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب استشارة قانونية'**
  String get dashboardLegalRequest;

  /// No description provided for @dashboardLegalRequestSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خطوات حل النزاعات القانونية'**
  String get dashboardLegalRequestSubtitle;

  /// No description provided for @dashboardLegalAffairs.
  ///
  /// In ar, this message translates to:
  /// **'الشؤون القانونية'**
  String get dashboardLegalAffairs;

  /// No description provided for @dashboardLegalAffairsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حقوق المهندس والقوانين'**
  String get dashboardLegalAffairsSubtitle;

  /// No description provided for @dashboardNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتي'**
  String get dashboardNotes;

  /// No description provided for @dashboardNotesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك الشخصية'**
  String get dashboardNotesSubtitle;

  /// No description provided for @dashboardLibrary.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة الهندسية'**
  String get dashboardLibrary;

  /// No description provided for @dashboardLibrarySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجع وأكواد ومواصفات'**
  String get dashboardLibrarySubtitle;

  /// No description provided for @dashboardOpening.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فتح {item}'**
  String dashboardOpening(String item);

  /// No description provided for @dashboardEngyGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، أنا إنجي — كيف أساعدك؟'**
  String get dashboardEngyGreeting;

  /// No description provided for @authSignInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get authSignUpTitle;

  /// No description provided for @authUserName.
  ///
  /// In ar, this message translates to:
  /// **'معرف المستخدم'**
  String get authUserName;

  /// Helper text under the username field at sign-up.
  ///
  /// In ar, this message translates to:
  /// **'بالأحرف اللاتينية أو الأرقام'**
  String get authUserNameHint;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get authFullName;

  /// No description provided for @authFullNameHint.
  ///
  /// In ar, this message translates to:
  /// **'كما تريد أن يظهر في ملفك'**
  String get authFullNameHint;

  /// No description provided for @authCompanyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة'**
  String get authCompanyName;

  /// No description provided for @authCompanyNameHint.
  ///
  /// In ar, this message translates to:
  /// **'كما تريد أن يظهر في صفحة الشركة'**
  String get authCompanyNameHint;

  /// No description provided for @authPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get authPhone;

  /// No description provided for @authAccountType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get authAccountType;

  /// No description provided for @authAccountIndividual.
  ///
  /// In ar, this message translates to:
  /// **'فرد'**
  String get authAccountIndividual;

  /// No description provided for @authAccountCompany.
  ///
  /// In ar, this message translates to:
  /// **'شركة'**
  String get authAccountCompany;

  /// No description provided for @authSubmitSignIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get authSubmitSignIn;

  /// No description provided for @authSubmitSignUp.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get authSubmitSignUp;

  /// No description provided for @authSwitchToSignUp.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ أنشئ حساباً'**
  String get authSwitchToSignUp;

  /// No description provided for @authSwitchToSignIn.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟ سجّل الدخول'**
  String get authSwitchToSignIn;

  /// No description provided for @authRequiredField.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get authRequiredField;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور 8 أحرف على الأقل'**
  String get authPasswordTooShort;

  /// No description provided for @authUserNameTooShort.
  ///
  /// In ar, this message translates to:
  /// **'معرف المستخدم 3 أحرف على الأقل'**
  String get authUserNameTooShort;

  /// No description provided for @authChecking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق…'**
  String get authChecking;

  /// No description provided for @authAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get authAvailable;

  /// No description provided for @authUserNameTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا المعرف محجوز، جرّب غيره'**
  String get authUserNameTaken;

  /// No description provided for @authPhoneTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرقم مسجّل بحساب آخر'**
  String get authPhoneTaken;

  /// No description provided for @authPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'7701234567'**
  String get authPhoneHint;

  /// No description provided for @authSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الجلسة. سجّل الدخول مرة أخرى.'**
  String get authSessionExpired;

  /// No description provided for @authPasswordWeak.
  ///
  /// In ar, this message translates to:
  /// **'أضف رقمًا وحرفًا كبيرًا وحرفًا صغيرًا'**
  String get authPasswordWeak;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authEmailOptional.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (اختياري)'**
  String get authEmailOptional;

  /// No description provided for @authEmailHint.
  ///
  /// In ar, this message translates to:
  /// **'name@example.com'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get authEmailInvalid;

  /// No description provided for @authEmailTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد مسجّل بحساب آخر'**
  String get authEmailTaken;

  /// No description provided for @authVerifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد رقم هاتفك'**
  String get authVerifyTitle;

  /// Shown when the verify screen opens with no draft to verify.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلسة التسجيل. ابدأ من جديد.'**
  String get authVerifyNoDraft;

  /// No description provided for @authVerifyRestart.
  ///
  /// In ar, this message translates to:
  /// **'البدء من جديد'**
  String get authVerifyRestart;

  /// Explains why there is no e-mail option on the sign-up code screen.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تأكيد بريدك الإلكتروني بعد إنشاء الحساب لتفعيل التحقق بخطوتين.'**
  String get authVerifyEmailLater;

  /// No description provided for @authVerifyCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التأكيد'**
  String get authVerifyCodeTitle;

  /// No description provided for @authVerifyResend.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال'**
  String get authVerifyResend;

  /// No description provided for @authVerifyConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get authVerifyConfirm;

  /// No description provided for @authVerifyNoCode.
  ///
  /// In ar, this message translates to:
  /// **'لم يصلك الرمز؟'**
  String get authVerifyNoCode;

  /// No description provided for @authVerifySentTo.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزًا من 6 أرقام إلى'**
  String get authVerifySentTo;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف صحيح'**
  String get authPhoneInvalid;

  /// No description provided for @authAccountCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حسابك، أهلاً بك {name} 🎉'**
  String authAccountCreated(String name);

  /// No description provided for @setupTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكمل ملفك'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'عرّف الآخرين بنفسك — يمكنك تعديل كل شيء لاحقاً.'**
  String get setupSubtitle;

  /// No description provided for @setupSubtitleCompany.
  ///
  /// In ar, this message translates to:
  /// **'عرّف الآخرين بشركتك — يمكنك تعديل كل شيء لاحقاً.'**
  String get setupSubtitleCompany;

  /// No description provided for @setupHeadline.
  ///
  /// In ar, this message translates to:
  /// **'المسمّى المهني'**
  String get setupHeadline;

  /// No description provided for @setupHeadlineHint.
  ///
  /// In ar, this message translates to:
  /// **'مهندس برمجيات في…'**
  String get setupHeadlineHint;

  /// No description provided for @setupHeadlineHintCompany.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي تقدّمه شركتك؟'**
  String get setupHeadlineHintCompany;

  /// No description provided for @setupAbout.
  ///
  /// In ar, this message translates to:
  /// **'نبذة'**
  String get setupAbout;

  /// No description provided for @setupAboutHint.
  ///
  /// In ar, this message translates to:
  /// **'بضعة أسطر عن خبرتك واهتماماتك'**
  String get setupAboutHint;

  /// No description provided for @setupAboutHintCompany.
  ///
  /// In ar, this message translates to:
  /// **'بضعة أسطر عن نشاط الشركة'**
  String get setupAboutHintCompany;

  /// No description provided for @setupLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get setupLocation;

  /// No description provided for @setupLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'بغداد، العراق'**
  String get setupLocationHint;

  /// No description provided for @setupIndustry.
  ///
  /// In ar, this message translates to:
  /// **'المجال'**
  String get setupIndustry;

  /// No description provided for @setupIndustryHint.
  ///
  /// In ar, this message translates to:
  /// **'التقنية، الهندسة، الرعاية الصحية…'**
  String get setupIndustryHint;

  /// No description provided for @setupWebsite.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الإلكتروني'**
  String get setupWebsite;

  /// No description provided for @setupOpenToWork.
  ///
  /// In ar, this message translates to:
  /// **'متاح لفرص عمل'**
  String get setupOpenToWork;

  /// No description provided for @setupOpenToWorkSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يظهر شارة على ملفك'**
  String get setupOpenToWorkSubtitle;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @forgotTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotTitle;

  /// No description provided for @forgotIntro.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة استلام رمز التحقق، ثم عيّن كلمة مرور جديدة.'**
  String get forgotIntro;

  /// No description provided for @forgotSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get forgotSend;

  /// No description provided for @forgotNoAccountPhone.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب بهذا الرقم. تحقق منه أو أنشئ حسابًا جديدًا.'**
  String get forgotNoAccountPhone;

  /// Only a CONFIRMED e-mail identifies an account, so an unconfirmed one reads as no account.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب مؤكَّد بهذا البريد. جرّب رقم هاتفك.'**
  String get forgotNoAccountEmail;

  /// No description provided for @forgotChangeTarget.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم أو البريد'**
  String get forgotChangeTarget;

  /// No description provided for @forgotLeaveTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء استعادة كلمة المرور؟'**
  String get forgotLeaveTitle;

  /// No description provided for @forgotLeaveBody.
  ///
  /// In ar, this message translates to:
  /// **'لن تتغيّر كلمة المرور وسيتم تسجيل خروجك. ستحتاج إلى رمز تحقق جديد للمحاولة مرة أخرى.'**
  String get forgotLeaveBody;

  /// No description provided for @forgotLeaveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الاستعادة'**
  String get forgotLeaveConfirm;

  /// No description provided for @forgotSetTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور جديدة'**
  String get forgotSetTitle;

  /// No description provided for @forgotSetSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر كلمة مرور لا تستخدمها في مكان آخر.'**
  String get forgotSetSubtitle;

  /// No description provided for @forgotNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get forgotNewPassword;

  /// No description provided for @forgotConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get forgotConfirmPassword;

  /// No description provided for @forgotPasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get forgotPasswordMismatch;

  /// No description provided for @forgotSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة المرور'**
  String get forgotSave;

  /// No description provided for @forgotDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور ✅'**
  String get forgotDone;

  /// No description provided for @setupCareerTitle.
  ///
  /// In ar, this message translates to:
  /// **'سيرتك المهنية'**
  String get setupCareerTitle;

  /// No description provided for @setupCv.
  ///
  /// In ar, this message translates to:
  /// **'السيرة الذاتية'**
  String get setupCv;

  /// No description provided for @setupCvOnFile.
  ///
  /// In ar, this message translates to:
  /// **'مرفقة'**
  String get setupCvOnFile;

  /// No description provided for @notificationsFollowApproved.
  ///
  /// In ar, this message translates to:
  /// **'وافقت على طلب المتابعة'**
  String get notificationsFollowApproved;

  /// No description provided for @notificationsRequestHandled.
  ///
  /// In ar, this message translates to:
  /// **'تمت معالجة هذا الطلب مسبقًا'**
  String get notificationsRequestHandled;

  /// No description provided for @toastFollowApproved.
  ///
  /// In ar, this message translates to:
  /// **'أصبح {name} يتابعك'**
  String toastFollowApproved(String name);

  /// No description provided for @activityFollowRequested.
  ///
  /// In ar, this message translates to:
  /// **'طلب متابعتك'**
  String get activityFollowRequested;

  /// No description provided for @settingsPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivateAccount.
  ///
  /// In ar, this message translates to:
  /// **'حساب خاص'**
  String get settingsPrivateAccount;

  /// No description provided for @settingsPrivateAccountOn.
  ///
  /// In ar, this message translates to:
  /// **'منشوراتك تظهر لمتابعيك فقط، وتوافق على كل طلب متابعة جديد'**
  String get settingsPrivateAccountOn;

  /// No description provided for @settingsPrivateAccountOff.
  ///
  /// In ar, this message translates to:
  /// **'يمكن لأي شخص رؤية منشوراتك ومتابعتك'**
  String get settingsPrivateAccountOff;

  /// No description provided for @profilePrivateTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب خاص'**
  String get profilePrivateTitle;

  /// No description provided for @profilePrivateBody.
  ///
  /// In ar, this message translates to:
  /// **'تابِع هذا الحساب لرؤية منشوراته'**
  String get profilePrivateBody;

  /// No description provided for @profilePrivateRequested.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل طلب المتابعة، وستظهر المنشورات بعد الموافقة'**
  String get profilePrivateRequested;

  /// No description provided for @postReplyingTo.
  ///
  /// In ar, this message translates to:
  /// **'الرد على {name}'**
  String postReplyingTo(String name);

  /// No description provided for @postCancelReply.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الرد'**
  String get postCancelReply;

  /// No description provided for @postWriteReply.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردًّا…'**
  String get postWriteReply;

  /// No description provided for @subscriptionApprovedToast.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على اشتراكك وأصبح فعّالًا'**
  String get subscriptionApprovedToast;

  /// No description provided for @feedRankingTitle.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب المنشورات'**
  String get feedRankingTitle;

  /// No description provided for @feedRankingSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات الترتيب'**
  String get feedRankingSaved;

  /// No description provided for @feedRankingIntro.
  ///
  /// In ar, this message translates to:
  /// **'تحدد هذه الأوزان كيف يرتّب التطبيق منشورات الصفحة الرئيسية لكل المستخدمين. الأوزان نسبية: المهم هو النسبة بينها. تسري التغييرات على الصفحات التي تُحمَّل بعد الحفظ.'**
  String get feedRankingIntro;

  /// No description provided for @feedRankingWeights.
  ///
  /// In ar, this message translates to:
  /// **'الأوزان'**
  String get feedRankingWeights;

  /// No description provided for @feedRankingAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get feedRankingAdvanced;

  /// No description provided for @feedRankingAffinity.
  ///
  /// In ar, this message translates to:
  /// **'القرب من الكاتب'**
  String get feedRankingAffinity;

  /// No description provided for @feedRankingAffinityHint.
  ///
  /// In ar, this message translates to:
  /// **'كم يتفاعل المستخدم مع هذا الكاتب. الأعلى يجعل الصفحة أكثر شخصية.'**
  String get feedRankingAffinityHint;

  /// No description provided for @feedRankingRecency.
  ///
  /// In ar, this message translates to:
  /// **'الحداثة'**
  String get feedRankingRecency;

  /// No description provided for @feedRankingRecencyHint.
  ///
  /// In ar, this message translates to:
  /// **'تفضيل المنشورات الأحدث.'**
  String get feedRankingRecencyHint;

  /// No description provided for @feedRankingEngagement.
  ///
  /// In ar, this message translates to:
  /// **'التفاعل'**
  String get feedRankingEngagement;

  /// No description provided for @feedRankingEngagementHint.
  ///
  /// In ar, this message translates to:
  /// **'الإعجابات والتعليقات والمشاركات بالنسبة لعمر المنشور.'**
  String get feedRankingEngagementHint;

  /// No description provided for @feedRankingUnseen.
  ///
  /// In ar, this message translates to:
  /// **'مكافأة غير المُشاهَد'**
  String get feedRankingUnseen;

  /// No description provided for @feedRankingUnseenHint.
  ///
  /// In ar, this message translates to:
  /// **'رفع المنشورات التي لم يرها المستخدم بعد.'**
  String get feedRankingUnseenHint;

  /// No description provided for @feedRankingRepeat.
  ///
  /// In ar, this message translates to:
  /// **'عقوبة تكرار الكاتب'**
  String get feedRankingRepeat;

  /// No description provided for @feedRankingRepeatHint.
  ///
  /// In ar, this message translates to:
  /// **'تخفيض كل منشور إضافي من نفس الكاتب في الصفحة، حتى لا يستحوذ كاتب واحد عليها.'**
  String get feedRankingRepeatHint;

  /// No description provided for @feedRankingHalfLife.
  ///
  /// In ar, this message translates to:
  /// **'نصف عمر الحداثة'**
  String get feedRankingHalfLife;

  /// No description provided for @feedRankingHalfLifeHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد هذه المدة تنخفض قيمة الحداثة إلى النصف. القيم القصيرة تجعل الصفحة زمنية أكثر.'**
  String get feedRankingHalfLifeHint;

  /// No description provided for @feedRankingOverfetch.
  ///
  /// In ar, this message translates to:
  /// **'عدد المرشحين لكل خانة'**
  String get feedRankingOverfetch;

  /// No description provided for @feedRankingOverfetchHint.
  ///
  /// In ar, this message translates to:
  /// **'كم منشورًا يُجلب لكل مكان في الصفحة قبل الترتيب. الأعلى أدق لكنه أبطأ وأكثر كلفة.'**
  String get feedRankingOverfetchHint;

  /// No description provided for @feedRankingTtl.
  ///
  /// In ar, this message translates to:
  /// **'مدة بقاء عناصر الصفحة'**
  String get feedRankingTtl;

  /// No description provided for @feedRankingTtlHint.
  ///
  /// In ar, this message translates to:
  /// **'بعدها تُحذف المنشورات غير المقروءة من صفحة المستخدم. صفر يعني بلا حذف.'**
  String get feedRankingTtlHint;

  /// No description provided for @feedRankingTtlForever.
  ///
  /// In ar, this message translates to:
  /// **'دائم'**
  String get feedRankingTtlForever;

  /// No description provided for @feedRankingHours.
  ///
  /// In ar, this message translates to:
  /// **'{count} ساعة'**
  String feedRankingHours(int count);

  /// No description provided for @feedRankingDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String feedRankingDays(int count);

  /// No description provided for @feedRankingReset.
  ///
  /// In ar, this message translates to:
  /// **'استعادة القيم الافتراضية'**
  String get feedRankingReset;

  /// No description provided for @settingsAdmin.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get settingsAdmin;

  /// No description provided for @panelAccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية لوحتي'**
  String get panelAccessTitle;

  /// No description provided for @panelAccessIntro.
  ///
  /// In ar, this message translates to:
  /// **'حدد ما إذا كانت لوحة المهندس تتطلب اشتراكًا، وأي أقسامها مفتوحة للجميع. تسري التغييرات فورًا على كل المستخدمين.'**
  String get panelAccessIntro;

  /// No description provided for @panelAccessGateSection.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get panelAccessGateSection;

  /// No description provided for @panelAccessGate.
  ///
  /// In ar, this message translates to:
  /// **'طلب اشتراك للوحة'**
  String get panelAccessGate;

  /// No description provided for @panelAccessGateOn.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة مغلقة إلا للمشتركين، عدا الأقسام المفتوحة أدناه.'**
  String get panelAccessGateOn;

  /// No description provided for @panelAccessGateOff.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة مفتوحة للجميع بالكامل.'**
  String get panelAccessGateOff;

  /// No description provided for @panelAccessTrial.
  ///
  /// In ar, this message translates to:
  /// **'مدة التجربة'**
  String get panelAccessTrial;

  /// No description provided for @panelAccessTrialHint.
  ///
  /// In ar, this message translates to:
  /// **'أيام يحصل فيها الحساب الجديد على اللوحة كاملة، تُحسب من تاريخ إنشائه.'**
  String get panelAccessTrialHint;

  /// No description provided for @panelAccessTrialNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا تجربة'**
  String get panelAccessTrialNone;

  /// No description provided for @panelAccessDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String panelAccessDays(String count);

  /// No description provided for @panelAccessSections.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get panelAccessSections;

  /// No description provided for @panelAccessSectionsHint.
  ///
  /// In ar, this message translates to:
  /// **'القسم المفعّل هنا مفتوح لكل المستخدمين بلا اشتراك؛ البقية تحتاج اشتراكًا.'**
  String get panelAccessSectionsHint;

  /// No description provided for @panelAccessSectionsIgnored.
  ///
  /// In ar, this message translates to:
  /// **'لا أثر لهذه الخيارات ما دامت اللوحة مفتوحة للجميع.'**
  String get panelAccessSectionsIgnored;

  /// No description provided for @panelAccessSectionFree.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح بلا اشتراك'**
  String get panelAccessSectionFree;

  /// No description provided for @panelAccessSectionPaid.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب اشتراكًا'**
  String get panelAccessSectionPaid;

  /// No description provided for @panelAccessSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات اللوحة'**
  String get panelAccessSaved;

  /// No description provided for @dashboardSectionLocked.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب اشتراكًا — اضغط للاشتراك'**
  String get dashboardSectionLocked;

  /// No description provided for @panelAccessLibraryLive.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل المكتبة الهندسية'**
  String get panelAccessLibraryLive;

  /// No description provided for @panelAccessLibraryLiveHint.
  ///
  /// In ar, this message translates to:
  /// **'ما دامت متوقفة تظهر في اللوحة بوسم «قريبًا» ولا تُفتح، مهما كانت إعدادات الاشتراك.'**
  String get panelAccessLibraryLiveHint;

  /// No description provided for @disciplinesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاختصاصات الهندسية'**
  String get disciplinesTitle;

  /// No description provided for @disciplinesIntro.
  ///
  /// In ar, this message translates to:
  /// **'الاختصاصات التي يختار منها المهندسون عند إنشاء ملفاتهم. اضغط على الشعار لرفع صورة، والمفتاح لإيقاف اختصاص دون حذفه — من اختاره يحتفظ به.'**
  String get disciplinesIntro;

  /// No description provided for @disciplineAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة اختصاص'**
  String get disciplineAdd;

  /// No description provided for @disciplineRename.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الاسم'**
  String get disciplineRename;

  /// No description provided for @disciplineSetLogo.
  ///
  /// In ar, this message translates to:
  /// **'رفع شعار'**
  String get disciplineSetLogo;

  /// No description provided for @disciplineClearLogo.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الشعار'**
  String get disciplineClearLogo;

  /// No description provided for @disciplineNameTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم الاختصاص'**
  String get disciplineNameTitle;

  /// No description provided for @disciplineNameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربية'**
  String get disciplineNameAr;

  /// No description provided for @disciplineNameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالإنجليزية'**
  String get disciplineNameEn;

  /// No description provided for @disciplineLogoHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على المربع لرفع شعار'**
  String get disciplineLogoHint;

  /// No description provided for @disciplineLogoNoStorage.
  ///
  /// In ar, this message translates to:
  /// **'رفع الصور غير مهيأ على هذا الخادم'**
  String get disciplineLogoNoStorage;

  /// No description provided for @disciplinePickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر اختصاصك'**
  String get disciplinePickerTitle;

  /// No description provided for @disciplinePickerHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر اختصاصك'**
  String get disciplinePickerHint;

  /// No description provided for @disciplinePickerSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن اختصاص…'**
  String get disciplinePickerSearch;

  /// No description provided for @disciplinePickerClear.
  ///
  /// In ar, this message translates to:
  /// **'بلا اختصاص'**
  String get disciplinePickerClear;

  /// No description provided for @disciplinePickerFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل قائمة الاختصاصات.'**
  String get disciplinePickerFailed;

  /// No description provided for @setupDiscipline.
  ///
  /// In ar, this message translates to:
  /// **'الاختصاص'**
  String get setupDiscipline;

  /// No description provided for @setupDisciplineHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر اختصاصك الهندسي'**
  String get setupDisciplineHint;

  /// No description provided for @editProfileDiscipline.
  ///
  /// In ar, this message translates to:
  /// **'الاختصاص'**
  String get editProfileDiscipline;

  /// No description provided for @governoratePickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر المحافظة'**
  String get governoratePickerTitle;

  /// No description provided for @governoratePickerHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر المحافظة'**
  String get governoratePickerHint;

  /// No description provided for @governoratePickerSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن محافظة…'**
  String get governoratePickerSearch;

  /// No description provided for @governoratePickerClear.
  ///
  /// In ar, this message translates to:
  /// **'بلا محافظة'**
  String get governoratePickerClear;

  /// No description provided for @governoratePickerFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل قائمة المحافظات.'**
  String get governoratePickerFailed;

  /// No description provided for @setupGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get setupGovernorate;

  /// No description provided for @setupGovernorateHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر محافظتك'**
  String get setupGovernorateHint;

  /// No description provided for @editProfileGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get editProfileGovernorate;

  /// No description provided for @profileTabPosts.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get profileTabPosts;

  /// No description provided for @profileTabReels.
  ///
  /// In ar, this message translates to:
  /// **'ريلز'**
  String get profileTabReels;

  /// No description provided for @profileTabCv.
  ///
  /// In ar, this message translates to:
  /// **'الخبرة'**
  String get profileTabCv;

  /// No description provided for @profileNoPosts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات بعد.'**
  String get profileNoPosts;

  /// No description provided for @profileNoReels.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ريلز بعد.'**
  String get profileNoReels;

  /// No description provided for @profileMessage.
  ///
  /// In ar, this message translates to:
  /// **'مراسلة'**
  String get profileMessage;

  /// No description provided for @profileNoCv.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سيرة ذاتية مرفوعة.'**
  String get profileNoCv;

  /// No description provided for @profileCvFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح السيرة الذاتية.'**
  String get profileCvFailed;

  /// Predicate on a notification row: the actor approved the viewer's follow request
  ///
  /// In ar, this message translates to:
  /// **'قبل طلب المتابعة'**
  String get activityFollowAccepted;

  /// Header of the post options sheet
  ///
  /// In ar, this message translates to:
  /// **'خيارات المنشور'**
  String get postOptionsTitle;

  /// Option: edit your own post
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنشور'**
  String get postOptionsEdit;

  /// Option: delete your own post
  ///
  /// In ar, this message translates to:
  /// **'حذف المنشور'**
  String get postOptionsDelete;

  /// Option: report somebody else's post
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن المنشور'**
  String get postOptionsReport;

  /// Option: bookmark a post
  ///
  /// In ar, this message translates to:
  /// **'حفظ المنشور'**
  String get postOptionsSave;

  /// Option: remove a bookmarked post
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المحفوظات'**
  String get postOptionsUnsave;

  /// Confirmation question before deleting a post
  ///
  /// In ar, this message translates to:
  /// **'حذف هذا المنشور نهائياً؟'**
  String get postDeleteConfirm;

  /// Body of the delete confirmation dialog
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن الحذف.'**
  String get postDeleteConfirmBody;

  /// Toast after deleting a post
  ///
  /// In ar, this message translates to:
  /// **'حُذف المنشور'**
  String get toastPostDeleted;

  /// Title of the edit-post sheet
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنشور'**
  String get postEditTitle;

  /// Hint of the edit-post text field
  ///
  /// In ar, this message translates to:
  /// **'اكتب شيئاً…'**
  String get postEditHint;

  /// Validation message when the edited post has no text
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن ترك المنشور فارغاً'**
  String get postEditEmpty;

  /// Toast after editing a post
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المنشور'**
  String get toastPostUpdated;

  /// Title of the report sheet
  ///
  /// In ar, this message translates to:
  /// **'سبب الإبلاغ'**
  String get postReportTitle;

  /// Hint of the optional report details field
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إضافية (اختياري)'**
  String get postReportDetailsHint;

  /// Submit button of the report sheet
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get postReportSend;

  /// Toast after reporting a post
  ///
  /// In ar, this message translates to:
  /// **'شكراً، وصلنا بلاغك'**
  String get toastPostReported;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'محتوى مزعج أو إعلاني'**
  String get reportReasonSpam;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'تحرّش أو تنمّر'**
  String get reportReasonHarassment;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'خطاب كراهية'**
  String get reportReasonHateSpeech;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'عنف أو تهديد'**
  String get reportReasonViolence;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'محتوى جنسي أو عارٍ'**
  String get reportReasonNudity;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'معلومات مضللة'**
  String get reportReasonMisinformation;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'إيذاء النفس'**
  String get reportReasonSelfHarm;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'انتحال شخصية'**
  String get reportReasonImpersonation;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'انتهاك حقوق ملكية'**
  String get reportReasonIntellectualProperty;

  /// Report reason
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get reportReasonOther;

  /// Button on an applicant card that opens the attached résumé
  ///
  /// In ar, this message translates to:
  /// **'عرض السيرة الذاتية'**
  String get companyApplicantOpenCv;

  /// Shown when an application has no résumé file
  ///
  /// In ar, this message translates to:
  /// **'لم يُرفق المتقدّم سيرة ذاتية'**
  String get companyApplicantNoCv;

  /// Toast when the résumé link cannot be opened
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الملف'**
  String get companyApplicantCvFailed;

  /// Heading above the cover letter on an applicant card
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات المتقدّم'**
  String get companyApplicantNotes;

  /// Shown when an application has no cover letter
  ///
  /// In ar, this message translates to:
  /// **'لم يكتب المتقدّم أي ملاحظات'**
  String get companyApplicantNoNotes;

  /// Opens the full applicant sheet
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get companyApplicantDetails;

  /// Opens the applicant's profile from their application
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get companyApplicantProfile;

  /// Title of the company's home screen
  ///
  /// In ar, this message translates to:
  /// **'لوحة الشركة'**
  String get companyDashboardTitle;

  /// Stat tile: postings still taking applications
  ///
  /// In ar, this message translates to:
  /// **'وظائف مفتوحة'**
  String get companyStatOpenJobs;

  /// Stat tile: everyone who applied
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المتقدّمين'**
  String get companyStatApplicants;

  /// Stat tile: applications received in the last seven days
  ///
  /// In ar, this message translates to:
  /// **'متقدّمون هذا الأسبوع'**
  String get companyStatNewThisWeek;

  /// Stat tile: followers of the company page
  ///
  /// In ar, this message translates to:
  /// **'متابعو الصفحة'**
  String get companyStatFollowers;

  /// Section title: applications not yet decided
  ///
  /// In ar, this message translates to:
  /// **'بانتظار قرارك'**
  String get companyPendingTitle;

  /// Empty state of the pending-applications section
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بانتظار قرار'**
  String get companyPendingEmpty;

  /// Link from the pending section to the applicants tab
  ///
  /// In ar, this message translates to:
  /// **'كل المتقدّمين'**
  String get companyPendingAll;

  /// Section title: the company's active postings
  ///
  /// In ar, this message translates to:
  /// **'وظائفك المفتوحة'**
  String get companyOpenJobsTitle;

  /// Empty state of the open-jobs section
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وظائف مفتوحة الآن'**
  String get companyOpenJobsEmpty;

  /// Applicant count under a posting on the dashboard
  ///
  /// In ar, this message translates to:
  /// **'المتقدّمون: {count}'**
  String companyJobApplicants(String count);

  /// Note under the open-jobs section about closed postings
  ///
  /// In ar, this message translates to:
  /// **'وظائف مغلقة: {count}'**
  String companyClosedJobs(String count);

  /// Greeting at the top of the company dashboard
  ///
  /// In ar, this message translates to:
  /// **'أهلاً، {name}'**
  String companyDashboardGreeting(String name);

  /// Section title above the company dashboard's shortcut tiles
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get companyQuickActions;

  /// Shortcut that opens the company's page editor
  ///
  /// In ar, this message translates to:
  /// **'تعديل الصفحة'**
  String get companyEditPage;

  /// Label on the apply button when the viewer has no subscription
  ///
  /// In ar, this message translates to:
  /// **'التقديم للمشتركين'**
  String get jobApplyLocked;

  /// Explains why the apply button is locked
  ///
  /// In ar, this message translates to:
  /// **'اشترك لتتمكن من التقديم على الوظائف'**
  String get jobApplyLockedBody;

  /// Account type: an engineer, the account that looks for work
  ///
  /// In ar, this message translates to:
  /// **'مهندس'**
  String get authAccountEngineer;

  /// Account type: a contractor
  ///
  /// In ar, this message translates to:
  /// **'مقاول'**
  String get authAccountContractor;

  /// Account type: a tradesperson — carpenter, blacksmith, electrician
  ///
  /// In ar, this message translates to:
  /// **'حرفي'**
  String get authAccountCraftsman;

  /// Account type: owns machinery and hires it out
  ///
  /// In ar, this message translates to:
  /// **'صاحب آلية'**
  String get authAccountEquipmentOwner;

  /// Name field label for a contractor, craftsman or machinery-owner account
  ///
  /// In ar, this message translates to:
  /// **'اسم النشاط'**
  String get authBusinessName;

  /// Hint under the business name field
  ///
  /// In ar, this message translates to:
  /// **'كما تريد أن يظهر في صفحتك'**
  String get authBusinessNameHint;

  /// Label of the specialty picker for a craftsman account
  ///
  /// In ar, this message translates to:
  /// **'الحرفة'**
  String get profileTradeLabel;

  /// Label of the specialty picker for a machinery-owner account
  ///
  /// In ar, this message translates to:
  /// **'نوع الآلية'**
  String get profileEquipmentLabel;

  /// Title of the bottom sheet that lists the five account types.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الحساب'**
  String get authAccountTypeSheetTitle;

  /// One-line description of the مهندس account type in the picker.
  ///
  /// In ar, this message translates to:
  /// **'حساب شخصي: تتقدّم على الوظائف وتبني ملفك المهني.'**
  String get authAccountEngineerHint;

  /// One-line description of the شركة account type in the picker.
  ///
  /// In ar, this message translates to:
  /// **'تنشر الوظائف وتستقبل طلبات المتقدّمين.'**
  String get authAccountCompanyHint;

  /// One-line description of the مقاول account type in the picker.
  ///
  /// In ar, this message translates to:
  /// **'تنفّذ المشاريع وتنشر فرص العمل.'**
  String get authAccountContractorHint;

  /// One-line description of the حرفي account type in the picker.
  ///
  /// In ar, this message translates to:
  /// **'صاحب مهنة: نجار، حدّاد، كهربائي وغيرها.'**
  String get authAccountCraftsmanHint;

  /// One-line description of the صاحب آلية account type in the picker.
  ///
  /// In ar, this message translates to:
  /// **'تؤجّر الآليات والمعدّات وتنشر فرص العمل.'**
  String get authAccountEquipmentOwnerHint;

  /// Title of the list of courses this viewer has authored.
  ///
  /// In ar, this message translates to:
  /// **'دوراتي'**
  String get myCoursesTitle;

  /// Empty state of the author's course list.
  ///
  /// In ar, this message translates to:
  /// **'لم تنشئ أي دورة بعد. ابدأ بدورة جديدة وأرسلها للمراجعة.'**
  String get myCoursesEmpty;

  /// Button that starts a new course.
  ///
  /// In ar, this message translates to:
  /// **'دورة جديدة'**
  String get myCoursesNew;

  /// Opens the list of purchases of courses this viewer wrote.
  ///
  /// In ar, this message translates to:
  /// **'أرباح دوراتي'**
  String get myCoursesEarnings;

  /// Review state: not yet submitted.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get courseStatusDraft;

  /// Review state: with the reviewer.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get courseStatusSubmitted;

  /// Review state: rejected with a note.
  ///
  /// In ar, this message translates to:
  /// **'مُعادة للتعديل'**
  String get courseStatusRejected;

  /// Review state: approved and live.
  ///
  /// In ar, this message translates to:
  /// **'منشورة'**
  String get courseStatusApproved;

  /// Title of the course editor when editing.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الدورة'**
  String get courseEditorEdit;

  /// Form field label.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدورة'**
  String get courseFieldTitle;

  /// Form field label for the one-line card summary.
  ///
  /// In ar, this message translates to:
  /// **'وصف مختصر'**
  String get courseFieldSummary;

  /// Form field label.
  ///
  /// In ar, this message translates to:
  /// **'الوصف الكامل'**
  String get courseFieldDescription;

  /// Form field label for the course category.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get courseFieldCategory;

  /// Form field label.
  ///
  /// In ar, this message translates to:
  /// **'المستوى'**
  String get courseFieldLevel;

  /// Form field label for what the author charges.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get courseFieldPrice;

  /// Hint under the price field.
  ///
  /// In ar, this message translates to:
  /// **'اتركه صفرًا لتكون الدورة مجانية'**
  String get courseFieldPriceHint;

  /// Adds one bullet to an outcomes or requirements list.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سطر'**
  String get courseAddLine;

  /// Section heading for the lesson list in the editor.
  ///
  /// In ar, this message translates to:
  /// **'الدروس'**
  String get courseLessons;

  /// Button in the course editor.
  ///
  /// In ar, this message translates to:
  /// **'إضافة درس'**
  String get courseAddLesson;

  /// Form field label.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدرس'**
  String get courseLessonTitle;

  /// Form field label: video, PDF or article.
  ///
  /// In ar, this message translates to:
  /// **'نوع الدرس'**
  String get courseLessonKind;

  /// Form field label.
  ///
  /// In ar, this message translates to:
  /// **'المدة بالدقائق'**
  String get courseLessonDuration;

  /// Toggle: openable before buying.
  ///
  /// In ar, this message translates to:
  /// **'درس تجريبي مجاني'**
  String get courseLessonPreview;

  /// Form field label for an article lesson's body.
  ///
  /// In ar, this message translates to:
  /// **'نص الدرس'**
  String get courseLessonBody;

  /// Removes a lesson from a course.
  ///
  /// In ar, this message translates to:
  /// **'حذف الدرس'**
  String get courseLessonDelete;

  /// Hands the course to the reviewer.
  ///
  /// In ar, this message translates to:
  /// **'إرسال للمراجعة'**
  String get courseSubmitForReview;

  /// Confirmation after submitting.
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت الدورة للمراجعة'**
  String get courseSubmittedToast;

  /// Confirmation after saving a draft.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الدورة'**
  String get courseSavedToast;

  /// Heading over the rejection reason shown to the author.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة المراجع'**
  String get courseReviewNote;

  /// Explains why the editor is read-only.
  ///
  /// In ar, this message translates to:
  /// **'الدورة عند المراجع ولا يمكن تعديلها حتى يصدر القرار.'**
  String get courseLockedUntilReview;

  /// Explains why an approved course is read-only.
  ///
  /// In ar, this message translates to:
  /// **'الدورة منشورة ولا يمكن تعديلها.'**
  String get courseLockedApproved;

  /// Button on a paid course.
  ///
  /// In ar, this message translates to:
  /// **'شراء الدورة'**
  String get courseBuy;

  /// State of a purchase request not yet confirmed.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار تأكيد الدفع'**
  String get coursePurchasePending;

  /// State of a confirmed purchase.
  ///
  /// In ar, this message translates to:
  /// **'تم الشراء'**
  String get coursePurchasePaid;

  /// Toast after asking to buy.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الشراء. تُفتح الدورة فور تأكيد الدفع.'**
  String get coursePurchaseAsked;

  /// Badge on a price a subscriber gets a discount on.
  ///
  /// In ar, this message translates to:
  /// **'خصم المشتركين {percent}%'**
  String courseSubscriberDiscount(String percent);

  /// Title of the admin review queue.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الدورات'**
  String get courseReviewTitle;

  /// Empty state of the review queue.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دورات بانتظار المراجعة.'**
  String get courseReviewEmpty;

  /// Approves a submitted course.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get courseApprove;

  /// Rejects a submitted course with a reason.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get courseReject;

  /// The commission the platform takes from this course.
  ///
  /// In ar, this message translates to:
  /// **'نسبة المنصة %'**
  String get coursePlatformPercent;

  /// Hint under the commission field.
  ///
  /// In ar, this message translates to:
  /// **'تُحتسب من المبلغ المدفوع فعليًا، وتُثبّت على كل عملية شراء لهذه الدورة.'**
  String get coursePlatformPercentHint;

  /// Required note on a rejection.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإعادة'**
  String get courseRejectReason;

  /// Toast after approving.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة ونُشرت الدورة'**
  String get courseApprovedToast;

  /// Toast after rejecting.
  ///
  /// In ar, this message translates to:
  /// **'أُعيدت الدورة إلى ناشرها'**
  String get courseRejectedToast;

  /// Label over the profile that wrote a course.
  ///
  /// In ar, this message translates to:
  /// **'الناشر'**
  String get courseAuthorLabel;

  /// Title of the admin screen holding the two tenant-wide numbers.
  ///
  /// In ar, this message translates to:
  /// **'تسعير الدورات'**
  String get courseCommerceTitle;

  /// Intro on the course pricing screen.
  ///
  /// In ar, this message translates to:
  /// **'رقمان يسريان على كل الدورات: نسبة المنصة المقترحة عند المراجعة، وخصم المشتركين على السعر.'**
  String get courseCommerceIntro;

  /// Settings field: what the review screen pre-fills.
  ///
  /// In ar, this message translates to:
  /// **'نسبة المنصة الافتراضية %'**
  String get courseCommissionDefault;

  /// Hint under the default commission field.
  ///
  /// In ar, this message translates to:
  /// **'قيمة مقترحة فقط؛ النسبة المُلزِمة هي ما يُثبَّت على كل دورة عند الموافقة.'**
  String get courseCommissionDefaultHint;

  /// Settings field.
  ///
  /// In ar, this message translates to:
  /// **'خصم المشتركين على الدورات %'**
  String get courseDiscountPercent;

  /// Hint under the subscriber discount field.
  ///
  /// In ar, this message translates to:
  /// **'يُخصم من سعر كل دورة مدفوعة لصاحب الاشتراك الفعّال. صفر يوقف الخصم.'**
  String get courseDiscountPercentHint;

  /// Toast after saving the two numbers.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات التسعير'**
  String get courseCommerceSaved;

  /// Title of the admin purchase queue.
  ///
  /// In ar, this message translates to:
  /// **'طلبات شراء الدورات'**
  String get coursePurchasesTitle;

  /// Empty state of the purchase queue.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات شراء.'**
  String get coursePurchasesEmpty;

  /// Admin action that opens the course for the buyer.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الدفع'**
  String get purchaseConfirm;

  /// Admin action that cancels a pending request.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get purchaseCancelRequest;

  /// What the learner owes.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get purchaseAmountDue;

  /// The commission on one purchase.
  ///
  /// In ar, this message translates to:
  /// **'حصة المنصة'**
  String get purchasePlatformShare;

  /// What the author is owed for one purchase.
  ///
  /// In ar, this message translates to:
  /// **'حصة الناشر'**
  String get purchaseAuthorShare;

  /// Toast after confirming a purchase.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد الدفع'**
  String get purchaseConfirmedToast;

  /// Toast after cancelling a purchase.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي الطلب'**
  String get purchaseCancelledToast;

  /// Free-text note on a purchase decision, e.g. a transfer reference.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get purchaseNote;

  /// Empty state of the author's earnings list.
  ///
  /// In ar, this message translates to:
  /// **'لم تُبَع أي من دوراتك بعد.'**
  String get courseEarningsEmpty;

  /// Panel row that opens the author's own course list.
  ///
  /// In ar, this message translates to:
  /// **'دوراتي كمدرّب'**
  String get dashboardTeach;

  /// Subtitle of the teach row on the panel.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ دورة، حدّد سعرها، وأرسلها للمراجعة'**
  String get dashboardTeachSubtitle;

  /// Label over the course cover picker in the editor.
  ///
  /// In ar, this message translates to:
  /// **'صورة الغلاف'**
  String get courseCoverLabel;

  /// Empty state of the cover picker.
  ///
  /// In ar, this message translates to:
  /// **'أضف صورة غلاف للدورة'**
  String get courseCoverAdd;

  /// Hint under the cover picker.
  ///
  /// In ar, this message translates to:
  /// **'تظهر على بطاقة الدورة في الكتالوج'**
  String get courseCoverHint;

  /// Replaces an already-chosen cover.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get courseCoverChange;

  /// Clears the chosen cover.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الصورة'**
  String get courseCoverRemove;

  /// Label over the lesson file picker.
  ///
  /// In ar, this message translates to:
  /// **'ملف الدرس'**
  String get courseLessonFile;

  /// Opens the video picker for a lesson.
  ///
  /// In ar, this message translates to:
  /// **'اختيار فيديو'**
  String get courseLessonPickVideo;

  /// Opens the file picker for a PDF lesson.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف PDF'**
  String get courseLessonPickPdf;

  /// Shown once a lesson's file is on the CDN.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع الملف'**
  String get courseLessonFileReady;

  /// Empty state of the lesson file picker.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرفع ملف بعد'**
  String get courseLessonFileMissing;

  /// Progress text while a course file uploads.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع… {percent}%'**
  String courseUploading(String percent);

  /// Explains why the lessons section is empty on a course that has never been saved.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ الدورة تلقائيًا عند إضافة أول درس.'**
  String get courseLessonsAutoSave;

  /// Tag on a catalogue card for a course published recently that this viewer has not opened.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get courseNewTag;

  /// Button on an empty profile banner, shown only to its owner.
  ///
  /// In ar, this message translates to:
  /// **'أضف صورة غلاف'**
  String get profileBannerAdd;

  /// Action on a profile banner that already has an image.
  ///
  /// In ar, this message translates to:
  /// **'تغيير صورة الغلاف'**
  String get profileBannerChange;

  /// Clears the profile's cover image.
  ///
  /// In ar, this message translates to:
  /// **'إزالة صورة الغلاف'**
  String get profileBannerRemove;

  /// Toast after the cover image is saved.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث صورة الغلاف'**
  String get profileBannerSaved;

  /// Shown when a reel cannot be published because the Bunny Stream library is not configured.
  ///
  /// In ar, this message translates to:
  /// **'نشر الريلز غير متاح على هذا الخادم حالياً'**
  String get composerReelsStreamOff;

  /// Shown when a course lesson video cannot be uploaded because the Bunny Stream library is not configured.
  ///
  /// In ar, this message translates to:
  /// **'رفع فيديو المحاضرات غير متاح على هذا الخادم حالياً'**
  String get courseLessonStreamOff;

  /// Background upload banner, while bytes are transferring.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع الفيديو'**
  String get uploadBannerUploading;

  /// Background upload banner, after the transfer and while the publish call runs.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ النشر…'**
  String get uploadBannerFinishing;

  /// Background upload banner, on success.
  ///
  /// In ar, this message translates to:
  /// **'تم الرفع والنشر'**
  String get uploadBannerDone;

  /// Background upload banner, on failure.
  ///
  /// In ar, this message translates to:
  /// **'فشل الرفع'**
  String get uploadBannerFailed;

  /// Shown when a second video upload is requested while one is running.
  ///
  /// In ar, this message translates to:
  /// **'هناك فيديو قيد الرفع بالفعل، انتظر حتى ينتهي'**
  String get uploadBannerBusy;

  /// Title of the confirm dialog shown when leaving the app mid-upload.
  ///
  /// In ar, this message translates to:
  /// **'الرفع لم ينتهِ'**
  String get uploadLeaveTitle;

  /// Body of the confirm dialog shown when leaving the app mid-upload.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق التطبيق الآن سيلغي رفع الفيديو. هل تريد الخروج؟'**
  String get uploadLeaveBody;

  /// Keeps the app open so the upload can finish.
  ///
  /// In ar, this message translates to:
  /// **'ابقَ'**
  String get uploadLeaveStay;

  /// Leaves the app and abandons the upload.
  ///
  /// In ar, this message translates to:
  /// **'اخرج'**
  String get uploadLeaveQuit;

  /// Toast when a composer hands a video to the background queue and closes.
  ///
  /// In ar, this message translates to:
  /// **'سيكمل الرفع في الخلفية'**
  String get uploadStartedBackground;

  /// Button on the upload banner that stops a transfer in progress.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get uploadBannerCancel;

  /// Upload banner title after the person cancelled the transfer.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي الرفع'**
  String get uploadBannerCancelled;

  /// Button on the course editor that saves the course and opens the lessons screen.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ومتابعة للمحاضرات'**
  String get courseSaveAndAddLessons;

  /// Title of the screen listing a course's lessons.
  ///
  /// In ar, this message translates to:
  /// **'محاضرات الدورة'**
  String get courseLessonsTitle;

  /// Empty state on the course lessons screen.
  ///
  /// In ar, this message translates to:
  /// **'لا محاضرات بعد. أضف أول محاضرة لتبدأ.'**
  String get courseLessonsEmpty;

  /// Toast shown when the editor saves a course and moves to the lessons screen.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الدورة. أضف محاضراتها الآن.'**
  String get courseLessonsNextStep;

  /// Chip on a lesson row whose video is being uploaded right now.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع'**
  String get courseLessonUploadingChip;

  /// Subtitle on a lesson row saved before its file and left without one.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل رفع الملف — المس لإعادة المحاولة'**
  String get courseLessonUploadIncomplete;

  /// Subtitle on a pending lesson row while another upload holds the queue.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار الرفع'**
  String get courseLessonUploadQueued;

  /// Shown when the server refuses a lesson saved ahead of its upload, which only an out-of-date server does.
  ///
  /// In ar, this message translates to:
  /// **'الخادم الحالي لا يدعم حفظ الدرس قبل اكتمال رفع الملف. أعد تشغيل الخادم بعد آخر تحديث.'**
  String get courseLessonServerOutdated;

  /// Toast after reposting a reel.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد نشر الريل لمتابعيك'**
  String get toastReelReposted;

  /// Toast after undoing a reel repost.
  ///
  /// In ar, this message translates to:
  /// **'أُلغيت إعادة النشر'**
  String get toastReelUnreposted;

  /// Shown inside a repost whose original post was deleted.
  ///
  /// In ar, this message translates to:
  /// **'المنشور الأصلي لم يعد متاحًا.'**
  String get postOriginalUnavailable;

  /// Title of the crop screen for the profile photo.
  ///
  /// In ar, this message translates to:
  /// **'قصّ الصورة الشخصية'**
  String get cropAvatarTitle;

  /// Title of the crop screen for the profile banner.
  ///
  /// In ar, this message translates to:
  /// **'قصّ صورة الغلاف'**
  String get cropBannerTitle;

  /// Confirm button on the crop screen.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get cropDone;

  /// Cancel button on the crop screen.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cropCancel;

  /// Tooltip of the ⋯ button on your own reel.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الريل'**
  String get reelOptions;

  /// Sheet row that deletes your own reel.
  ///
  /// In ar, this message translates to:
  /// **'حذف الريل'**
  String get reelDelete;

  /// Sheet row on your own repost of someone's reel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء إعادة النشر'**
  String get reelUndoRepost;

  /// Title of the delete-reel confirmation.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذا الريل نهائياً؟'**
  String get reelDeleteConfirm;

  /// Body of the delete-reel confirmation.
  ///
  /// In ar, this message translates to:
  /// **'سيختفي من ملفك ومن كل من أعاد نشره، ولا يمكن التراجع عن الحذف.'**
  String get reelDeleteConfirmBody;

  /// Toast after a reel is deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الريل'**
  String get toastReelDeleted;

  /// Settings row that opens the privacy policy web page.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get settingsPrivacyPolicy;

  /// Settings section holding the privacy policy link.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get settingsAbout;

  /// Toast when the privacy policy page can't be opened.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الصفحة. تحقق من اتصالك وحاول مجدداً.'**
  String get legalLinkFailed;

  /// Sign-in footer, text before the privacy policy link. Ends right before the link.
  ///
  /// In ar, this message translates to:
  /// **'بمتابعتك فإنك توافق على '**
  String get authTermsLead;

  /// Tappable privacy policy link in the sign-in footer.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get authTermsPrivacy;

  /// Sign-in footer, text after the privacy policy link.
  ///
  /// In ar, this message translates to:
  /// **' الخاصة بمهندس'**
  String get authTermsTail;

  /// Sign-up label above the optional gender chips.
  ///
  /// In ar, this message translates to:
  /// **'الجنس (اختياري)'**
  String get authGenderOptional;

  /// Settings row that permanently deletes the account.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get settingsDeleteAccount;

  /// Title of the delete-account confirmation.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابك نهائياً؟'**
  String get deleteAccountTitle;

  /// Body of the delete-account confirmation.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف ملفك المهني ومنشوراتك وريلزك وتعليقاتك ومتابعاتك، ولن تتمكن من تسجيل الدخول بهذا الحساب مرة أخرى. لا يمكن التراجع عن ذلك.'**
  String get deleteAccountBody;

  /// Destructive confirm button in the delete-account dialog.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائياً'**
  String get deleteAccountConfirm;

  /// Toast after the account is deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف حسابك'**
  String get toastAccountDeleted;

  /// Sign-up hint above the phone and email fields.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك أو بريدك الإلكتروني، يكفي أحدهما. سنرسل إليه رمز تأكيد.'**
  String get authPhoneOrEmailHint;

  /// Sign-up error when both phone and email are empty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الهاتف أو البريد الإلكتروني'**
  String get authPhoneOrEmailRequired;

  /// Option on someone else's profile.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن الحساب'**
  String get reportProfile;

  /// Option on someone else's reel.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن الريل'**
  String get reportReel;

  /// Option on someone else's comment.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن التعليق'**
  String get reportComment;

  /// Option when long-pressing someone else's message.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن الرسالة'**
  String get reportMessage;

  /// Button on someone else's story.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن القصة'**
  String get reportStory;

  /// Short report action under a comment.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ'**
  String get actionReport;

  /// Tappable terms-of-use link in the sign-in footer.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get authTermsLink;

  /// Joins the terms and privacy links in the sign-in footer.
  ///
  /// In ar, this message translates to:
  /// **' و'**
  String get authTermsAnd;

  /// Settings row that opens the terms of use page.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get settingsTerms;

  /// Empty state of the hashtag posts page.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات بهذا الوسم بعد'**
  String get hashtagPostsEmpty;

  /// Hint in the story reply field
  ///
  /// In ar, this message translates to:
  /// **'أرسل ردًّا…'**
  String get storyReplyHint;

  /// No description provided for @storyReplySend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get storyReplySend;

  /// No description provided for @storyReplySent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال ردّك في الرسائل'**
  String get storyReplySent;

  /// No description provided for @storyReplyFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال الرد، حاول مجددًا'**
  String get storyReplyFailed;

  /// No description provided for @storyLike.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب'**
  String get storyLike;

  /// No description provided for @storyLikeFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الإعجاب'**
  String get storyLikeFailed;

  /// No description provided for @activityLikedStory.
  ///
  /// In ar, this message translates to:
  /// **'أعجب بقصتك'**
  String get activityLikedStory;

  /// No description provided for @activityCommentedReel.
  ///
  /// In ar, this message translates to:
  /// **'علّق على مقطعك'**
  String get activityCommentedReel;

  /// Reel rail comment button label when there are no comments
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get reelComment;

  /// No description provided for @reelCommentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get reelCommentsTitle;

  /// No description provided for @reelCommentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تعليقات بعد. كن أول من يعلّق!'**
  String get reelCommentsEmpty;

  /// No description provided for @reelCommentsRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get reelCommentsRetry;

  /// No description provided for @reelCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف تعليقًا…'**
  String get reelCommentHint;

  /// No description provided for @reelCommentReply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get reelCommentReply;

  /// No description provided for @reelCommentReplyingTo.
  ///
  /// In ar, this message translates to:
  /// **'الرد على {name}'**
  String reelCommentReplyingTo(String name);

  /// No description provided for @reelCommentDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get reelCommentDelete;

  /// No description provided for @reelCommentDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف التعليق؟'**
  String get reelCommentDeleteTitle;

  /// No description provided for @reelCommentDeleteBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف التعليق وكل الردود عليه.'**
  String get reelCommentDeleteBody;

  /// No description provided for @reelCommentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف التعليق'**
  String get reelCommentDeleted;

  /// No description provided for @reelCommentReport.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ'**
  String get reelCommentReport;

  /// No description provided for @composerAddPoll.
  ///
  /// In ar, this message translates to:
  /// **'إضافة استطلاع'**
  String get composerAddPoll;

  /// No description provided for @composerRemovePoll.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الاستطلاع'**
  String get composerRemovePoll;

  /// No description provided for @composerPollTitle.
  ///
  /// In ar, this message translates to:
  /// **'استطلاع رأي'**
  String get composerPollTitle;

  /// No description provided for @composerPollQuestionNote.
  ///
  /// In ar, this message translates to:
  /// **'نص المنشور هو سؤال الاستطلاع.'**
  String get composerPollQuestionNote;

  /// No description provided for @composerPollOptionHint.
  ///
  /// In ar, this message translates to:
  /// **'الخيار {n}'**
  String composerPollOptionHint(String n);

  /// No description provided for @composerPollAddOption.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خيار'**
  String get composerPollAddOption;

  /// No description provided for @composerPollRemoveOption.
  ///
  /// In ar, this message translates to:
  /// **'حذف الخيار'**
  String get composerPollRemoveOption;

  /// No description provided for @pollDurationHour.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get pollDurationHour;

  /// No description provided for @pollDurationSixHours.
  ///
  /// In ar, this message translates to:
  /// **'6 ساعات'**
  String get pollDurationSixHours;

  /// No description provided for @pollDurationDay.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get pollDurationDay;

  /// No description provided for @pollDurationThreeDays.
  ///
  /// In ar, this message translates to:
  /// **'3 أيام'**
  String get pollDurationThreeDays;

  /// No description provided for @pollDurationWeek.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع'**
  String get pollDurationWeek;

  /// No description provided for @pollVotes.
  ///
  /// In ar, this message translates to:
  /// **'{count} صوت'**
  String pollVotes(String count);

  /// No description provided for @pollLeftDays.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {n} يوم'**
  String pollLeftDays(String n);

  /// No description provided for @pollLeftHours.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {n} ساعة'**
  String pollLeftHours(String n);

  /// No description provided for @pollLeftMinutes.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {n} دقيقة'**
  String pollLeftMinutes(String n);

  /// No description provided for @pollClosed.
  ///
  /// In ar, this message translates to:
  /// **'انتهى التصويت'**
  String get pollClosed;

  /// No description provided for @pollVoteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل صوتك'**
  String get pollVoteFailed;

  /// No description provided for @setupSecureTitle.
  ///
  /// In ar, this message translates to:
  /// **'أمّن حسابك'**
  String get setupSecureTitle;

  /// No description provided for @setupSecureOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get setupSecureOptional;

  /// No description provided for @setupSecureBody.
  ///
  /// In ar, this message translates to:
  /// **'أكّد بريدك الإلكتروني ليصبح وسيلة تحقق ثانية وطريقة لاستعادة حسابك إن فقدت رقمك.'**
  String get setupSecureBody;

  /// No description provided for @setupSecureAction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البريد'**
  String get setupSecureAction;

  /// No description provided for @setupSecureDismiss.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get setupSecureDismiss;

  /// No description provided for @emailVerifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني والتحقق بخطوتين'**
  String get emailVerifyTitle;

  /// No description provided for @emailVerifyIntro.
  ///
  /// In ar, this message translates to:
  /// **'أضف بريدك الإلكتروني وأكّده ليصبح وسيلة تحقق ثانية لحسابك، وطريقة للدخول إن فقدت رقم هاتفك. رقم الهاتف يبقى هو الأساس.'**
  String get emailVerifyIntro;

  /// No description provided for @emailVerifySend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز التأكيد'**
  String get emailVerifySend;

  /// No description provided for @emailVerifyChangeAddress.
  ///
  /// In ar, this message translates to:
  /// **'تغيير البريد'**
  String get emailVerifyChangeAddress;

  /// No description provided for @emailVerifyDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد بريدك الإلكتروني ✅'**
  String get emailVerifyDone;

  /// No description provided for @setupSave.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get setupSave;

  /// No description provided for @setupSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطٍّ الآن'**
  String get setupSkip;

  /// No description provided for @setupSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ ملفك 🎉'**
  String get setupSaved;

  /// No description provided for @authGender.
  ///
  /// In ar, this message translates to:
  /// **'الجنس'**
  String get authGender;

  /// No description provided for @authGenderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get authGenderMale;

  /// No description provided for @authGenderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get authGenderFemale;

  /// No description provided for @authPhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة الملف'**
  String get authPhoto;

  /// No description provided for @authPhotoPick.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة'**
  String get authPhotoPick;

  /// No description provided for @authPhotoChange.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get authPhotoChange;

  /// No description provided for @authPhotoRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get authPhotoRemove;

  /// No description provided for @authPhotoUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع الصورة…'**
  String get authPhotoUploading;

  /// No description provided for @authGenderRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر الجنس'**
  String get authGenderRequired;

  /// No description provided for @profileConnectSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الطلب'**
  String get profileConnectSent;

  /// No description provided for @profileConnectAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول الطلب'**
  String get profileConnectAccept;

  /// No description provided for @profileConnected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get profileConnected;

  /// No description provided for @profileFollowRequested.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الموافقة'**
  String get profileFollowRequested;

  /// No description provided for @toastConnectRequestCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم سحب الطلب'**
  String get toastConnectRequestCancelled;

  /// No description provided for @toastConnectionRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة الاتصال'**
  String get toastConnectionRemoved;

  /// No description provided for @toastConnectAccepted.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول الطلب'**
  String get toastConnectAccepted;

  /// No description provided for @networkAddSent.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال'**
  String get networkAddSent;

  /// No description provided for @welcomeConnectTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ شبكتك'**
  String get welcomeConnectTitle;

  /// No description provided for @welcomeConnectBody.
  ///
  /// In ar, this message translates to:
  /// **'هؤلاء أشخاص في مجالك — أرسل طلب تواصل لتظهر منشوراتهم في صفحتك الرئيسية.'**
  String get welcomeConnectBody;

  /// No description provided for @welcomeConnectEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد اقتراحات الآن. يمكنك البحث عن أشخاص في أي وقت من تبويب الشبكة.'**
  String get welcomeConnectEmpty;

  /// No description provided for @welcomeConnectContinue.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة إلى الرئيسية'**
  String get welcomeConnectContinue;

  /// No description provided for @activityFollowed.
  ///
  /// In ar, this message translates to:
  /// **'بدأ بمتابعتك'**
  String get activityFollowed;

  /// No description provided for @activityConnectRequested.
  ///
  /// In ar, this message translates to:
  /// **'أرسل إليك طلب تواصل'**
  String get activityConnectRequested;

  /// No description provided for @activityConnectAccepted.
  ///
  /// In ar, this message translates to:
  /// **'قبل طلب التواصل'**
  String get activityConnectAccepted;

  /// No description provided for @activityLiked.
  ///
  /// In ar, this message translates to:
  /// **'أعجب بمنشورك'**
  String get activityLiked;

  /// No description provided for @activityCommented.
  ///
  /// In ar, this message translates to:
  /// **'علّق على منشورك'**
  String get activityCommented;

  /// No description provided for @activityMentioned.
  ///
  /// In ar, this message translates to:
  /// **'أشار إليك'**
  String get activityMentioned;

  /// No description provided for @activityMessaged.
  ///
  /// In ar, this message translates to:
  /// **'أرسل إليك رسالة'**
  String get activityMessaged;

  /// No description provided for @activityShared.
  ///
  /// In ar, this message translates to:
  /// **'أعاد نشر منشورك'**
  String get activityShared;

  /// No description provided for @activityApplied.
  ///
  /// In ar, this message translates to:
  /// **'تقدّم إلى وظيفتك'**
  String get activityApplied;

  /// No description provided for @activityCalled.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بك'**
  String get activityCalled;

  /// No description provided for @activityOther.
  ///
  /// In ar, this message translates to:
  /// **'أرسل إليك إشعارًا'**
  String get activityOther;

  /// No description provided for @applyResumeNone.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سيرة ذاتية مرفقة'**
  String get applyResumeNone;

  /// No description provided for @applyResumeUploadHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف PDF أو Word'**
  String get applyResumeUploadHint;

  /// No description provided for @actionDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get actionDelete;

  /// No description provided for @actionAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get actionEdit;

  /// No description provided for @profileEditExperience.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخبرات'**
  String get profileEditExperience;

  /// No description provided for @profileEditEducation.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التعليم'**
  String get profileEditEducation;

  /// No description provided for @profileEditSkills.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المهارات'**
  String get profileEditSkills;

  /// No description provided for @profileAddExperience.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خبرة'**
  String get profileAddExperience;

  /// No description provided for @profileAddEducation.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مؤهل'**
  String get profileAddEducation;

  /// No description provided for @profileAddSkill.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مهارة'**
  String get profileAddSkill;

  /// No description provided for @profileSectionEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناصر بعد'**
  String get profileSectionEmpty;

  /// No description provided for @profileDeleteEntryTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنصر؟'**
  String get profileDeleteEntryTitle;

  /// No description provided for @profileDeleteEntryBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء.'**
  String get profileDeleteEntryBody;

  /// No description provided for @fieldRole.
  ///
  /// In ar, this message translates to:
  /// **'المسمى الوظيفي'**
  String get fieldRole;

  /// No description provided for @fieldCompany.
  ///
  /// In ar, this message translates to:
  /// **'الشركة'**
  String get fieldCompany;

  /// No description provided for @fieldEmploymentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع التوظيف'**
  String get fieldEmploymentType;

  /// No description provided for @fieldLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get fieldLocation;

  /// No description provided for @fieldStartDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البدء'**
  String get fieldStartDate;

  /// No description provided for @fieldEndDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get fieldEndDate;

  /// No description provided for @fieldCurrentRole.
  ///
  /// In ar, this message translates to:
  /// **'أعمل هنا حالياً'**
  String get fieldCurrentRole;

  /// No description provided for @fieldDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get fieldDescription;

  /// No description provided for @fieldSchool.
  ///
  /// In ar, this message translates to:
  /// **'الجامعة أو المدرسة'**
  String get fieldSchool;

  /// No description provided for @fieldDegree.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة العلمية'**
  String get fieldDegree;

  /// No description provided for @fieldFieldOfStudy.
  ///
  /// In ar, this message translates to:
  /// **'التخصص'**
  String get fieldFieldOfStudy;

  /// No description provided for @fieldSkillName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المهارة'**
  String get fieldSkillName;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// No description provided for @fieldNotSet.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get fieldNotSet;

  /// No description provided for @employmentFullTime.
  ///
  /// In ar, this message translates to:
  /// **'دوام كامل'**
  String get employmentFullTime;

  /// No description provided for @employmentPartTime.
  ///
  /// In ar, this message translates to:
  /// **'دوام جزئي'**
  String get employmentPartTime;

  /// No description provided for @employmentContract.
  ///
  /// In ar, this message translates to:
  /// **'عقد'**
  String get employmentContract;

  /// No description provided for @employmentInternship.
  ///
  /// In ar, this message translates to:
  /// **'تدريب'**
  String get employmentInternship;

  /// No description provided for @employmentFreelance.
  ///
  /// In ar, this message translates to:
  /// **'عمل حر'**
  String get employmentFreelance;

  /// No description provided for @employmentSelfEmployed.
  ///
  /// In ar, this message translates to:
  /// **'عمل خاص'**
  String get employmentSelfEmployed;

  /// No description provided for @employmentTemporary.
  ///
  /// In ar, this message translates to:
  /// **'مؤقت'**
  String get employmentTemporary;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة الشخصية'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfileChangeCover.
  ///
  /// In ar, this message translates to:
  /// **'تغيير صورة الغلاف'**
  String get editProfileChangeCover;

  /// No description provided for @profileActivity.
  ///
  /// In ar, this message translates to:
  /// **'النشاط'**
  String get profileActivity;

  /// No description provided for @profileActivityPosts.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get profileActivityPosts;

  /// No description provided for @profileActivityComments.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get profileActivityComments;

  /// No description provided for @profileActivityShowAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get profileActivityShowAll;

  /// No description provided for @profileCreatePost.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منشور'**
  String get profileCreatePost;

  /// No description provided for @profileFollowersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} متابع'**
  String profileFollowersCount(String count);

  /// No description provided for @profileCommentedOn.
  ///
  /// In ar, this message translates to:
  /// **'علّق على منشور'**
  String get profileCommentedOn;

  /// No description provided for @postSeeMore.
  ///
  /// In ar, this message translates to:
  /// **'…المزيد'**
  String get postSeeMore;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get settingsThemeDark;

  /// No description provided for @settingsAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccount;

  /// No description provided for @settingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get settingsSaved;

  /// No description provided for @savedPostsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات المحفوظة'**
  String get savedPostsTitle;

  /// No description provided for @savedPostsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تحفظ أي منشور بعد'**
  String get savedPostsEmpty;

  /// No description provided for @savedJobsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوظائف المحفوظة'**
  String get savedJobsTitle;

  /// No description provided for @savedJobsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تحفظ أي وظيفة بعد'**
  String get savedJobsEmpty;

  /// No description provided for @jobSaveRemoved.
  ///
  /// In ar, this message translates to:
  /// **'أُزيلت من المحفوظات'**
  String get jobSaveRemoved;

  /// No description provided for @jobCompanyCannotApply.
  ///
  /// In ar, this message translates to:
  /// **'حسابات الشركات لا تتقدّم للوظائف'**
  String get jobCompanyCannotApply;

  /// No description provided for @settingsLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج؟'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutBody.
  ///
  /// In ar, this message translates to:
  /// **'سيلزمك تسجيل الدخول مرة أخرى للمتابعة.'**
  String get settingsLogoutBody;

  /// No description provided for @profileMoreOptions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات'**
  String get profileMoreOptions;

  /// No description provided for @profileBlock.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get profileBlock;

  /// No description provided for @profileBlockTitle.
  ///
  /// In ar, this message translates to:
  /// **'حظر هذا الحساب؟'**
  String get profileBlockTitle;

  /// No description provided for @profileBlockBody.
  ///
  /// In ar, this message translates to:
  /// **'لن يرى أحدكما منشورات الآخر أو ملفه، وستُلغى المتابعة بينكما.'**
  String get profileBlockBody;

  /// No description provided for @profileBlockDone.
  ///
  /// In ar, this message translates to:
  /// **'تم الحظر'**
  String get profileBlockDone;

  /// No description provided for @feedSuggestedPost.
  ///
  /// In ar, this message translates to:
  /// **'مقترح لك'**
  String get feedSuggestedPost;

  /// No description provided for @composerAddPhoto.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get composerAddPhoto;

  /// No description provided for @composerUploadsOff.
  ///
  /// In ar, this message translates to:
  /// **'رفع الملفات غير مفعّل على هذا الخادم'**
  String get composerUploadsOff;

  /// No description provided for @composerAddDocument.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملف'**
  String get composerAddDocument;

  /// No description provided for @composerAddHashtag.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وسم'**
  String get composerAddHashtag;

  /// No description provided for @composerAddMention.
  ///
  /// In ar, this message translates to:
  /// **'الإشارة إلى شخص'**
  String get composerAddMention;

  /// No description provided for @composerModePost.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get composerModePost;

  /// No description provided for @composerModeStory.
  ///
  /// In ar, this message translates to:
  /// **'قصة'**
  String get composerModeStory;

  /// No description provided for @composerModeReel.
  ///
  /// In ar, this message translates to:
  /// **'ريل'**
  String get composerModeReel;

  /// No description provided for @composerSingleMediaOnly.
  ///
  /// In ar, this message translates to:
  /// **'هذا النوع يأخذ ملفاً واحداً فقط'**
  String get composerSingleMediaOnly;

  /// No description provided for @composerVideoTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو كبير جداً (الحد {max} ميجابايت)'**
  String composerVideoTooLarge(int max);

  /// No description provided for @composerDocumentTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الملف كبير جداً (الحد {max} ميجابايت)'**
  String composerDocumentTooLarge(int max);

  /// No description provided for @composerTitleStory.
  ///
  /// In ar, this message translates to:
  /// **'قصة جديدة'**
  String get composerTitleStory;

  /// No description provided for @composerTitleReel.
  ///
  /// In ar, this message translates to:
  /// **'ريل جديد'**
  String get composerTitleReel;

  /// No description provided for @composerHintStory.
  ///
  /// In ar, this message translates to:
  /// **'أضف تعليقاً على القصة…'**
  String get composerHintStory;

  /// No description provided for @composerHintReel.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وصفاً للريل…'**
  String get composerHintReel;

  /// No description provided for @composerAddVideo.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فيديو'**
  String get composerAddVideo;

  /// No description provided for @composerStoryNeedsMedia.
  ///
  /// In ar, this message translates to:
  /// **'القصة تحتاج صورة أو فيديو'**
  String get composerStoryNeedsMedia;

  /// No description provided for @composerReelNeedsVideo.
  ///
  /// In ar, this message translates to:
  /// **'الريل يحتاج فيديو'**
  String get composerReelNeedsVideo;

  /// No description provided for @composerModeDropped.
  ///
  /// In ar, this message translates to:
  /// **'أُزيلت المرفقات التي لا تناسب هذا النوع'**
  String get composerModeDropped;

  /// No description provided for @toastStoryPosted.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر القصة ✓'**
  String get toastStoryPosted;

  /// No description provided for @toastReelPosted.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الريل ✓'**
  String get toastReelPosted;

  /// No description provided for @postOpenDocument.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملف'**
  String get postOpenDocument;

  /// No description provided for @postOpenDocumentFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الملف'**
  String get postOpenDocumentFailed;

  /// No description provided for @composerPhotoRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get composerPhotoRetry;

  /// No description provided for @composerPhotoLimit.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إرفاق {max} صور كحد أقصى'**
  String composerPhotoLimit(int max);

  /// No description provided for @navMyJobs.
  ///
  /// In ar, this message translates to:
  /// **'وظائفي'**
  String get navMyJobs;

  /// No description provided for @navApplicants.
  ///
  /// In ar, this message translates to:
  /// **'المتقدّمون'**
  String get navApplicants;

  /// No description provided for @navPage.
  ///
  /// In ar, this message translates to:
  /// **'صفحتي'**
  String get navPage;

  /// No description provided for @companyJobsTitle.
  ///
  /// In ar, this message translates to:
  /// **'وظائفي'**
  String get companyJobsTitle;

  /// No description provided for @companyJobsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تنشر أي وظيفة بعد'**
  String get companyJobsEmpty;

  /// No description provided for @companyJobsEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'انشر وظيفة ليبدأ المرشّحون بالتقديم'**
  String get companyJobsEmptyHint;

  /// No description provided for @companyPostJob.
  ///
  /// In ar, this message translates to:
  /// **'نشر وظيفة'**
  String get companyPostJob;

  /// No description provided for @companyPublishJob.
  ///
  /// In ar, this message translates to:
  /// **'نشر الوظيفة'**
  String get companyPublishJob;

  /// No description provided for @companyJobPosted.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الوظيفة'**
  String get companyJobPosted;

  /// No description provided for @companyJobOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get companyJobOpen;

  /// No description provided for @companyJobClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلقة'**
  String get companyJobClosed;

  /// No description provided for @companyViewApplicants.
  ///
  /// In ar, this message translates to:
  /// **'عرض المتقدّمين'**
  String get companyViewApplicants;

  /// No description provided for @companyApplicantsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتقدّمون'**
  String get companyApplicantsTitle;

  /// No description provided for @companyNoApplicants.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد متقدّمون بعد'**
  String get companyNoApplicants;

  /// No description provided for @companyNoApplicantsHint.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر هنا كل من يقدّم على هذه الوظيفة'**
  String get companyNoApplicantsHint;

  /// No description provided for @companyApplicantUnknown.
  ///
  /// In ar, this message translates to:
  /// **'متقدّم'**
  String get companyApplicantUnknown;

  /// No description provided for @companyStatusSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث حالة الطلب'**
  String get companyStatusSaved;

  /// No description provided for @companyFieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get companyFieldRequired;

  /// No description provided for @companyJobTitle.
  ///
  /// In ar, this message translates to:
  /// **'المسمى الوظيفي'**
  String get companyJobTitle;

  /// No description provided for @companyJobCompany.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجهة'**
  String get companyJobCompany;

  /// No description provided for @companyJobLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get companyJobLocation;

  /// No description provided for @companyJobEmploymentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع التوظيف'**
  String get companyJobEmploymentType;

  /// No description provided for @companyJobWorkMode.
  ///
  /// In ar, this message translates to:
  /// **'نمط العمل'**
  String get companyJobWorkMode;

  /// No description provided for @companyJobSalaryMin.
  ///
  /// In ar, this message translates to:
  /// **'أقل راتب'**
  String get companyJobSalaryMin;

  /// No description provided for @companyJobSalaryMax.
  ///
  /// In ar, this message translates to:
  /// **'أعلى راتب'**
  String get companyJobSalaryMax;

  /// No description provided for @companyJobDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get companyJobDescription;

  /// No description provided for @companyJobRequirements.
  ///
  /// In ar, this message translates to:
  /// **'المتطلبات'**
  String get companyJobRequirements;

  /// No description provided for @companyJobRequirementsHint.
  ///
  /// In ar, this message translates to:
  /// **'متطلب واحد في كل سطر'**
  String get companyJobRequirementsHint;

  /// No description provided for @companyApplicantCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} متقدّم'**
  String companyApplicantCount(String count);

  /// No description provided for @companyAppliedAgo.
  ///
  /// In ar, this message translates to:
  /// **'قدّم {time}'**
  String companyAppliedAgo(String time);

  /// No description provided for @companyOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get companyOverview;

  /// No description provided for @companySize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الشركة'**
  String get companySize;

  /// No description provided for @companySizeSelf.
  ///
  /// In ar, this message translates to:
  /// **'أنا فقط'**
  String get companySizeSelf;

  /// No description provided for @companyFounded.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التأسيس'**
  String get companyFounded;

  /// No description provided for @companyFoundedOn.
  ///
  /// In ar, this message translates to:
  /// **'تأسست في {date}'**
  String companyFoundedOn(String date);

  /// No description provided for @companySpecialties.
  ///
  /// In ar, this message translates to:
  /// **'التخصصات'**
  String get companySpecialties;

  /// No description provided for @companySpecialtiesHint.
  ///
  /// In ar, this message translates to:
  /// **'تخصص واحد في كل سطر'**
  String get companySpecialtiesHint;

  /// No description provided for @companyJobCompanyWebsite.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الإلكتروني'**
  String get companyJobCompanyWebsite;

  /// No description provided for @companyOpenJobs.
  ///
  /// In ar, this message translates to:
  /// **'الوظائف المتاحة'**
  String get companyOpenJobs;

  /// No description provided for @companyOpenJobsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{وظيفة مفتوحة} =2{وظيفتان مفتوحتان} few{وظائف مفتوحة} many{وظيفة مفتوحة} other{وظيفة مفتوحة}}'**
  String companyOpenJobsCount(num count);

  /// No description provided for @companyWebsiteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الموقع'**
  String get companyWebsiteFailed;

  /// No description provided for @companySeeAllJobs.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الوظائف'**
  String get companySeeAllJobs;

  /// No description provided for @profilePosts.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get profilePosts;

  /// No description provided for @companySizeOver.
  ///
  /// In ar, this message translates to:
  /// **'أكثر من {count} موظف'**
  String companySizeOver(String count);

  /// No description provided for @companySizeRange.
  ///
  /// In ar, this message translates to:
  /// **'من {from} إلى {to} موظف'**
  String companySizeRange(String from, String to);

  /// No description provided for @companyNoOpenJobs.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وظائف متاحة حالياً'**
  String get companyNoOpenJobs;

  /// No description provided for @courseTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدورة'**
  String get courseTitle;

  /// No description provided for @coursesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دورات بعد'**
  String get coursesEmpty;

  /// No description provided for @coursesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا الدورات فور نشرها'**
  String get coursesEmptyHint;

  /// No description provided for @courseLecturesDone.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرات'**
  String get courseLecturesDone;

  /// No description provided for @courseEnroll.
  ///
  /// In ar, this message translates to:
  /// **'التحق بالدورة'**
  String get courseEnroll;

  /// No description provided for @courseEnrolled.
  ///
  /// In ar, this message translates to:
  /// **'تم التحاقك بالدورة'**
  String get courseEnrolled;

  /// No description provided for @courseFinishLecture.
  ///
  /// In ar, this message translates to:
  /// **'أنهيت المحاضرة'**
  String get courseFinishLecture;

  /// No description provided for @courseProgressSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ تقدّمك'**
  String get courseProgressSaved;

  /// No description provided for @courseCompleted.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الدورة'**
  String get courseCompleted;

  /// No description provided for @courseCertificateEarned.
  ///
  /// In ar, this message translates to:
  /// **'حصلت على شهادة هذه الدورة'**
  String get courseCertificateEarned;

  /// No description provided for @notesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات'**
  String get notesEmpty;

  /// No description provided for @notesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظتك الأولى'**
  String get notesEmptyHint;

  /// No description provided for @notesNew.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get notesNew;

  /// No description provided for @notesEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get notesEdit;

  /// No description provided for @notesTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get notesTitleLabel;

  /// No description provided for @notesBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get notesBodyLabel;

  /// No description provided for @notesUntitled.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان'**
  String get notesUntitled;

  /// No description provided for @documentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مراجع بعد'**
  String get documentsEmpty;

  /// No description provided for @documentsEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر المراجع فور إضافتها'**
  String get documentsEmptyHint;

  /// No description provided for @documentNoFile.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ملف مرفق'**
  String get documentNoFile;

  /// No description provided for @legalEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get legalEmpty;

  /// No description provided for @legalEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل طلب استشارة وسيصلك الرد هنا'**
  String get legalEmptyHint;

  /// No description provided for @legalNewRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get legalNewRequest;

  /// No description provided for @legalSubjectLabel.
  ///
  /// In ar, this message translates to:
  /// **'موضوع الطلب'**
  String get legalSubjectLabel;

  /// No description provided for @legalBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get legalBodyLabel;

  /// No description provided for @legalSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get legalSubmit;

  /// No description provided for @legalSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك'**
  String get legalSubmitted;

  /// No description provided for @legalResponse.
  ///
  /// In ar, this message translates to:
  /// **'الرد'**
  String get legalResponse;

  /// No description provided for @legalStatusSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'مُرسل'**
  String get legalStatusSubmitted;

  /// No description provided for @legalStatusInReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get legalStatusInReview;

  /// No description provided for @legalStatusAnswered.
  ///
  /// In ar, this message translates to:
  /// **'تم الرد'**
  String get legalStatusAnswered;

  /// No description provided for @legalStatusClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get legalStatusClosed;

  /// No description provided for @assistantHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سؤالك…'**
  String get assistantHint;

  /// No description provided for @assistantStubNotice.
  ///
  /// In ar, this message translates to:
  /// **'المساعد غير مفعّل بعد — أسئلتك محفوظة وسيصلك الرد فور تفعيل الخدمة.'**
  String get assistantStubNotice;

  /// No description provided for @courseLectureCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} محاضرة'**
  String courseLectureCount(String count);

  /// No description provided for @courseLectureOf.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total}'**
  String courseLectureOf(String current, String total);

  /// No description provided for @courseLecturesSection.
  ///
  /// In ar, this message translates to:
  /// **'المحاضرات'**
  String get courseLecturesSection;

  /// No description provided for @courseLecturesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضف محاضرات لهذه الدورة بعد'**
  String get courseLecturesEmpty;

  /// No description provided for @courseLectureLocked.
  ///
  /// In ar, this message translates to:
  /// **'أكمل المحاضرة السابقة أولاً'**
  String get courseLectureLocked;

  /// No description provided for @courseLectureNoVideo.
  ///
  /// In ar, this message translates to:
  /// **'الفيديو غير متاح بعد'**
  String get courseLectureNoVideo;

  /// No description provided for @courseLecturePreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة مجانية'**
  String get courseLecturePreview;

  /// No description provided for @courseLectureMarkedDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد المحاضرة كمكتملة'**
  String get courseLectureMarkedDone;

  /// No description provided for @coursePlayerError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل الفيديو'**
  String get coursePlayerError;

  /// No description provided for @courseLectureMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String courseLectureMinutes(String minutes);

  /// No description provided for @subscriptionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionLockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا القسم متاح للمشتركين'**
  String get subscriptionLockedTitle;

  /// No description provided for @subscriptionLockedBody.
  ///
  /// In ar, this message translates to:
  /// **'اشترك للوصول إلى الدورات والمكتبة الهندسية والشؤون القانونية وأدواتك الشخصية.'**
  String get subscriptionLockedBody;

  /// No description provided for @subscriptionChoosePlan.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطة'**
  String get subscriptionChoosePlan;

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In ar, this message translates to:
  /// **'اشترك الآن'**
  String get subscriptionSubscribe;

  /// No description provided for @subscriptionPlansEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطط متاحة حالياً'**
  String get subscriptionPlansEmpty;

  /// No description provided for @subscriptionCurrent.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك الحالي'**
  String get subscriptionCurrent;

  /// No description provided for @subscriptionManage.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراك'**
  String get subscriptionManage;

  /// No description provided for @subscriptionStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار التفعيل'**
  String get subscriptionStatusPending;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'فعّال'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهٍ'**
  String get subscriptionStatusExpired;

  /// No description provided for @subscriptionStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get subscriptionStatusCancelled;

  /// No description provided for @subscriptionPendingNotice.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلبك. يبدأ اشتراكك فور تأكيد الدفع.'**
  String get subscriptionPendingNotice;

  /// No description provided for @subscriptionStarted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الاشتراك'**
  String get subscriptionStarted;

  /// No description provided for @subscriptionCancelAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الاشتراك'**
  String get subscriptionCancelAction;

  /// No description provided for @subscriptionCancelConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إلغاء اشتراكك؟ يبقى الوصول متاحاً حتى نهاية المدة المدفوعة.'**
  String get subscriptionCancelConfirm;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء اشتراكك'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionKeep.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get subscriptionKeep;

  /// No description provided for @subscriptionTrialBadge.
  ///
  /// In ar, this message translates to:
  /// **'تجربة مجانية'**
  String get subscriptionTrialBadge;

  /// No description provided for @subscriptionTrialEndsIn.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي تجربتك المجانية بعد {days} يوماً'**
  String subscriptionTrialEndsIn(String days);

  /// No description provided for @subscriptionExpiresIn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {days} يوماً'**
  String subscriptionExpiresIn(String days);

  /// No description provided for @subscriptionEndsToday.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي اليوم'**
  String get subscriptionEndsToday;

  /// No description provided for @billingCycleMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get billingCycleMonthly;

  /// No description provided for @billingCycleAnnual.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get billingCycleAnnual;

  /// No description provided for @billingPerMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهرياً'**
  String get billingPerMonth;

  /// No description provided for @billingPerYear.
  ///
  /// In ar, this message translates to:
  /// **'سنوياً'**
  String get billingPerYear;

  /// No description provided for @billingSave.
  ///
  /// In ar, this message translates to:
  /// **'وفّر {percent}%'**
  String billingSave(String percent);

  /// No description provided for @subscriptionCycleUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح على هذه الباقة'**
  String get subscriptionCycleUnavailable;

  /// No description provided for @subscriptionChangeAction.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الباقة'**
  String get subscriptionChangeAction;

  /// No description provided for @subscriptionChangeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الباقة'**
  String get subscriptionChangeTitle;

  /// No description provided for @subscriptionChangeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التغيير'**
  String get subscriptionChangeConfirm;

  /// No description provided for @subscriptionChangeDismiss.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get subscriptionChangeDismiss;

  /// No description provided for @subscriptionChangeBlocked.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التغيير إلى هذه الباقة'**
  String get subscriptionChangeBlocked;

  /// No description provided for @subscriptionChangeFrom.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get subscriptionChangeFrom;

  /// No description provided for @subscriptionChangeTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get subscriptionChangeTo;

  /// No description provided for @subscriptionChangePrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get subscriptionChangePrice;

  /// No description provided for @subscriptionCurrentPlanBadge.
  ///
  /// In ar, this message translates to:
  /// **'باقتك الحالية'**
  String get subscriptionCurrentPlanBadge;

  /// No description provided for @subscriptionChangeDue.
  ///
  /// In ar, this message translates to:
  /// **'المطلوب دفعه'**
  String get subscriptionChangeDue;

  /// No description provided for @subscriptionChangePlanPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الباقة الجديدة'**
  String get subscriptionChangePlanPrice;

  /// No description provided for @subscriptionChangeCreditAmount.
  ///
  /// In ar, this message translates to:
  /// **'محتسب من باقتك الحالية'**
  String get subscriptionChangeCreditAmount;

  /// No description provided for @subscriptionChangeNoExtraCost.
  ///
  /// In ar, this message translates to:
  /// **'بدون رسوم إضافية'**
  String get subscriptionChangeNoExtraCost;

  /// No description provided for @subscriptionChangeKeepsDate.
  ///
  /// In ar, this message translates to:
  /// **'لا يتغيّر موعد انتهاء اشتراكك — متبقٍ {days} يوماً'**
  String subscriptionChangeKeepsDate(String days);

  /// No description provided for @subscriptionChangeImmediateNotice.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ التغيير فوراً، ويُحتسب الفرق على فاتورتك القادمة.'**
  String get subscriptionChangeImmediateNotice;

  /// No description provided for @subscriptionChangeDowngradeNotice.
  ///
  /// In ar, this message translates to:
  /// **'ستفقد مزايا باقتك الحالية فور التأكيد، ولا يوجد استرداد للمبلغ المدفوع.'**
  String get subscriptionChangeDowngradeNotice;

  /// No description provided for @subscriptionChangeDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير باقتك'**
  String get subscriptionChangeDone;

  /// No description provided for @subscriptionPerDays.
  ///
  /// In ar, this message translates to:
  /// **'لكل {days} يوماً'**
  String subscriptionPerDays(String days);

  /// No description provided for @courseLevelBeginner.
  ///
  /// In ar, this message translates to:
  /// **'مبتدئ'**
  String get courseLevelBeginner;

  /// No description provided for @courseLevelIntermediate.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get courseLevelIntermediate;

  /// No description provided for @courseLevelAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get courseLevelAdvanced;

  /// No description provided for @courseFree.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get courseFree;

  /// No description provided for @courseLockedBadge.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب اشتراكاً'**
  String get courseLockedBadge;

  /// No description provided for @courseLockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذه الدورة تتطلب اشتراكاً'**
  String get courseLockedTitle;

  /// No description provided for @courseLockedBody.
  ///
  /// In ar, this message translates to:
  /// **'اشترك لفتح هذا القسم من الدورات. يمكنك مشاهدة المحاضرة الأولى مجاناً قبل ذلك.'**
  String get courseLockedBody;

  /// No description provided for @courseSubscribeToOpen.
  ///
  /// In ar, this message translates to:
  /// **'اعرض خطط الاشتراك'**
  String get courseSubscribeToOpen;

  /// No description provided for @courseHours.
  ///
  /// In ar, this message translates to:
  /// **'{hours} ساعة'**
  String courseHours(String hours);

  /// No description provided for @courseEnrolledCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} ملتحق'**
  String courseEnrolledCount(String count);

  /// No description provided for @courseNoRatings.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تقييمات بعد'**
  String get courseNoRatings;

  /// No description provided for @courseRatingOf.
  ///
  /// In ar, this message translates to:
  /// **'{rating} ({count})'**
  String courseRatingOf(String rating, String count);

  /// No description provided for @courseAbout.
  ///
  /// In ar, this message translates to:
  /// **'عن الدورة'**
  String get courseAbout;

  /// No description provided for @courseOutcomes.
  ///
  /// In ar, this message translates to:
  /// **'ما ستتعلمه'**
  String get courseOutcomes;

  /// No description provided for @courseRequirements.
  ///
  /// In ar, this message translates to:
  /// **'المتطلبات'**
  String get courseRequirements;

  /// No description provided for @courseInstructor.
  ///
  /// In ar, this message translates to:
  /// **'المدرّب'**
  String get courseInstructor;

  /// No description provided for @courseRateTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيّم هذه الدورة'**
  String get courseRateTitle;

  /// No description provided for @courseRateAction.
  ///
  /// In ar, this message translates to:
  /// **'أرسل التقييم'**
  String get courseRateAction;

  /// No description provided for @courseRated.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لتقييمك'**
  String get courseRated;

  /// No description provided for @courseYourRating.
  ///
  /// In ar, this message translates to:
  /// **'تقييمك'**
  String get courseYourRating;

  /// No description provided for @courseRateHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رأيك (اختياري)'**
  String get courseRateHint;

  /// No description provided for @lessonKindVideo.
  ///
  /// In ar, this message translates to:
  /// **'فيديو'**
  String get lessonKindVideo;

  /// No description provided for @lessonKindPdf.
  ///
  /// In ar, this message translates to:
  /// **'ملف PDF'**
  String get lessonKindPdf;

  /// No description provided for @lessonKindArticle.
  ///
  /// In ar, this message translates to:
  /// **'قراءة'**
  String get lessonKindArticle;

  /// No description provided for @lessonOpenPdf.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملف'**
  String get lessonOpenPdf;

  /// No description provided for @lessonPdfFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الملف'**
  String get lessonPdfFailed;

  /// No description provided for @coursesFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get coursesFilterAll;

  /// No description provided for @coursesFilterFree.
  ///
  /// In ar, this message translates to:
  /// **'المتاحة لي'**
  String get coursesFilterFree;

  /// No description provided for @planIncludes.
  ///
  /// In ar, this message translates to:
  /// **'تشمل الخطة'**
  String get planIncludes;

  /// No description provided for @featureTheoryCourses.
  ///
  /// In ar, this message translates to:
  /// **'الدورات النظرية'**
  String get featureTheoryCourses;

  /// No description provided for @featurePracticalCourses.
  ///
  /// In ar, this message translates to:
  /// **'الدورات العملية'**
  String get featurePracticalCourses;

  /// No description provided for @featureTrainingCourses.
  ///
  /// In ar, this message translates to:
  /// **'الدورات التدريبية'**
  String get featureTrainingCourses;

  /// No description provided for @featureLibrary.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة الهندسية'**
  String get featureLibrary;

  /// No description provided for @featureLegalAffairs.
  ///
  /// In ar, this message translates to:
  /// **'الشؤون القانونية والاستشارات'**
  String get featureLegalAffairs;

  /// No description provided for @documentLocked.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب اشتراكاً'**
  String get documentLocked;

  /// No description provided for @subscriptionInvoiceNumber.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة رقم {number}'**
  String subscriptionInvoiceNumber(String number);

  /// No description provided for @subscriptionAutoRenew.
  ///
  /// In ar, this message translates to:
  /// **'التجديد التلقائي'**
  String get subscriptionAutoRenew;

  /// No description provided for @subscriptionAutoRenewOn.
  ///
  /// In ar, this message translates to:
  /// **'سيبدأ اشتراك جديد تلقائياً عند انتهاء المدة الحالية.'**
  String get subscriptionAutoRenewOn;

  /// No description provided for @subscriptionAutoRenewOff.
  ///
  /// In ar, this message translates to:
  /// **'سينتهي اشتراكك عند نهاية المدة الحالية ولن يُجدَّد.'**
  String get subscriptionAutoRenewOff;

  /// No description provided for @subscriptionAutoRenewSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعداد التجديد'**
  String get subscriptionAutoRenewSaved;

  /// No description provided for @profileFollowing.
  ///
  /// In ar, this message translates to:
  /// **'يتابع'**
  String get profileFollowing;

  /// No description provided for @peopleConnectionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاتصالات'**
  String get peopleConnectionsTitle;

  /// No description provided for @peopleFollowersTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتابِعون'**
  String get peopleFollowersTitle;

  /// No description provided for @peopleFollowingTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتابَعون'**
  String get peopleFollowingTitle;

  /// No description provided for @peopleRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get peopleRemove;

  /// No description provided for @peopleEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا أحد هنا بعد'**
  String get peopleEmpty;

  /// No description provided for @peopleRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إزالة {name} من اتصالاتك؟'**
  String peopleRemoveConfirm(String name);

  /// No description provided for @peopleUnfollowConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف متابعة {name}؟'**
  String peopleUnfollowConfirm(String name);

  /// No description provided for @postSuggestedFollowing.
  ///
  /// In ar, this message translates to:
  /// **'تتابعه'**
  String get postSuggestedFollowing;

  /// No description provided for @reelMute.
  ///
  /// In ar, this message translates to:
  /// **'كتم'**
  String get reelMute;

  /// No description provided for @reelUnmute.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الصوت'**
  String get reelUnmute;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
