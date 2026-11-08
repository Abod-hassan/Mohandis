// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مهندس';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionDone => 'تم';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get actionSend => 'إرسال';

  @override
  String get actionAccept => 'قبول';

  @override
  String get actionIgnore => 'تجاهل';

  @override
  String get actionChange => 'تغيير';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get optionalSuffix => '(اختياري)';

  @override
  String get applyResumeReplace => 'اضغط لاستبدال الملف';

  @override
  String get applyResumeRequired => 'أرفق سيرتك الذاتية قبل التقديم';

  @override
  String get requiredSuffix => '(مطلوب)';

  @override
  String get genericError => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  String get emptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get themeToggleToDark => 'التبديل إلى المظهر الداكن';

  @override
  String get themeToggleToLight => 'التبديل إلى المظهر الفاتح';

  @override
  String get authHeroTitle => 'حيث تلتقي المسارات المهنية.';

  @override
  String get authHeroBody =>
      'ابنِ ملفك المهني، وسّع شبكتك، شارك أعمالك، واعثر على دورك المهني القادم — في مكان واحد هادئ واحترافي.';

  @override
  String get authGetStarted => 'لنبدأ';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authContinueWith => 'أو تابع عبر';

  @override
  String get authGoogle => 'جوجل';

  @override
  String get authApple => 'آبل';

  @override
  String get authTerms =>
      'بمتابعتك فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة بمهندس';

  @override
  String authWelcomeBack(String name) {
    return 'أهلاً بعودتك، $name 👋';
  }

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navReels => 'ريلز';

  @override
  String get navDashboard => 'لوحتي';

  @override
  String get navJobs => 'الوظائف';

  @override
  String get navNetwork => 'الاشخاص';

  @override
  String get topBarSearchHint => 'ابحث عن أشخاص أو وظائف أو وسوم';

  @override
  String get feedYourStory => 'قصتك';

  @override
  String get feedComposerHint => 'شارك تحديثاً أو فكرة…';

  @override
  String get feedCaughtUp => 'لقد اطّلعت على كل الجديد ✓';

  @override
  String feedRepostedBy(String name) {
    return 'أعاد $name النشر';
  }

  @override
  String get postActionLike => 'إعجاب';

  @override
  String get postActionComment => 'تعليق';

  @override
  String get postActionRepost => 'إعادة نشر';

  @override
  String get postActionSave => 'حفظ';

  @override
  String postCommentsCount(String count) {
    return '$count تعليق';
  }

  @override
  String postRepostsCount(String count) {
    return '$count إعادة نشر';
  }

  @override
  String postLikesCount(String count) {
    return '$count إعجاب';
  }

  @override
  String get postViewJob => 'عرض الوظيفة والتقديم ←';

  @override
  String get postDetailTitle => 'المنشور';

  @override
  String get postAddComment => 'أضف تعليقاً…';

  @override
  String get postReply => 'رد';

  @override
  String postLikeWithCount(String count) {
    return 'إعجاب · $count';
  }

  @override
  String get visibilityPublic => 'عام';

  @override
  String get visibilityFollowers => 'المتابعون';

  @override
  String get visibilityPrivate => 'خاص';

  @override
  String get visibilityEveryoneLabel => 'الجميع';

  @override
  String get visibilityFollowersOnlyLabel => 'المتابعون فقط';

  @override
  String get visibilityOnlyMeLabel => 'أنا فقط';

  @override
  String get composerTitle => 'منشور جديد';

  @override
  String get composerPublish => 'نشر';

  @override
  String get composerHint => 'شارك تحديثاً أو فكرة أو فرصة…';

  @override
  String get toastSavedToItems => 'حُفظ في عناصرك';

  @override
  String get toastReposted => 'أُعيد النشر لمتابعيك';

  @override
  String get toastPosted => 'تم نشر المنشور ✓';

  @override
  String get toastSavedToReels => 'حُفظ في ريلزك';

  @override
  String get toastProfileUpdated => 'تم تحديث الملف ✓';

  @override
  String get toastApplicationSent => 'تم إرسال الطلب ✓';

  @override
  String toastConnectRequestSent(String name) {
    return 'أُرسل طلب التواصل إلى $name';
  }

  @override
  String toastConnected(String name) {
    return 'تم التواصل مع $name';
  }

  @override
  String toastFollowing(String name) {
    return 'تتابع الآن $name';
  }

  @override
  String get toastUnfollowed => 'تم إلغاء المتابعة';

  @override
  String storyReplyTo(String name) {
    return 'رد على $name…';
  }

  @override
  String storyPostedAgo(String time) {
    return 'قبل $time';
  }

  @override
  String get reelsTitle => 'ريلز';

  @override
  String get reelFollow => 'متابعة';

  @override
  String get reelShare => 'مشاركة';

  @override
  String reelPlays(String count) {
    return '$count مشاهدة';
  }

  @override
  String get profileOpenToWork => 'متاح للعمل';

  @override
  String get profileHiring => 'نتوظّف';

  @override
  String get profileConnections => 'اتصالاً';

  @override
  String get profileFollowers => 'متابعاً';

  @override
  String get profileEdit => 'تعديل الملف';

  @override
  String get profileFollow => 'متابعة';

  @override
  String get profileUnfollow => 'إلغاء المتابعة';

  @override
  String get profileConnect => 'إضافة';

  @override
  String get profileAbout => 'نبذة';

  @override
  String get profileDownloadCv => 'تنزيل السيرة الذاتية';

  @override
  String get profileExperience => 'الخبرات';

  @override
  String get profileEducation => 'التعليم';

  @override
  String get profileSkills => 'المهارات';

  @override
  String profileEndorsements(String count) {
    return '$count تزكية';
  }

  @override
  String get profileEndorse => '+ تزكية';

  @override
  String get editProfileTitle => 'تعديل الملف';

  @override
  String get editProfileFullName => 'الاسم الكامل';

  @override
  String get editProfileHeadline => 'المسمى المهني';

  @override
  String get editProfileIndustry => 'القطاع';

  @override
  String get editProfileLocation => 'الموقع';

  @override
  String get editProfileAbout => 'نبذة';

  @override
  String get editProfileOpenToWorkTitle => 'متاح للعمل';

  @override
  String get editProfileOpenToWorkSubtitle => 'أظهر لجهات التوظيف أنك متاح';

  @override
  String get editProfilePrivateTitle => 'ملف خاص';

  @override
  String get editProfilePrivateSubtitle =>
      'وافق على المتابعين قبل رؤية منشوراتك';

  @override
  String get networkTitle => 'الاشخاص';

  @override
  String get networkRequests => 'طلبات التواصل';

  @override
  String get networkSuggestions => 'أشخاص قد تعرفهم';

  @override
  String networkMutual(String count) {
    return '$count معارف مشتركة';
  }

  @override
  String get networkAdd => '+ إضافة';

  @override
  String get searchHint => 'ابحث في مهندس';

  @override
  String get searchTabTop => 'الأهم';

  @override
  String get searchTabPeople => 'أشخاص';

  @override
  String get searchTabJobs => 'وظائف';

  @override
  String get searchTabTags => 'وسوم';

  @override
  String get searchTrendingTags => 'الوسوم الرائجة';

  @override
  String get searchSectionPeople => 'أشخاص';

  @override
  String get searchNoResults => 'لا نتائج مطابقة لبحثك';

  @override
  String searchPostsCount(String count) {
    return '$count منشور';
  }

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notificationsNowConnected => 'أصبح على تواصل معك';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get messagesSearchHint => 'بحث في الرسائل';

  @override
  String get messagesYouPrefix => 'أنت: ';

  @override
  String threadMembers(String count) {
    return '$count أعضاء';
  }

  @override
  String get threadInputHint => 'اكتب رسالة…';

  @override
  String get threadToday => 'اليوم';

  @override
  String get threadRead => 'تمت القراءة';

  @override
  String get threadJustNow => 'الآن';

  @override
  String get jobsTitle => 'الوظائف';

  @override
  String get jobsMyApplications => 'طلباتي';

  @override
  String get jobsSearchHint => 'المسمى أو الشركة أو الموقع';

  @override
  String get jobsFilterAll => 'الكل';

  @override
  String get jobsFilterRemote => 'عن بُعد';

  @override
  String get jobsFilterHybrid => 'هجين';

  @override
  String get jobsFilterOnsite => 'من المقر';

  @override
  String get jobsEmpty => 'لا توجد وظائف مطابقة للفلاتر';

  @override
  String jobPostedAgo(String time) {
    return 'قبل $time';
  }

  @override
  String jobApplicants(String count) {
    return '$count متقدماً';
  }

  @override
  String get jobApplied => 'تم التقديم';

  @override
  String get jobDetailTitle => 'تفاصيل الوظيفة';

  @override
  String get jobSalaryRange => 'نطاق الراتب';

  @override
  String get jobAboutSection => 'عن الوظيفة';

  @override
  String get jobRequirementsSection => 'ما نبحث عنه';

  @override
  String get jobSkillsSection => 'المهارات';

  @override
  String get jobApplyNow => 'قدّم الآن';

  @override
  String jobApplicationStatus(String status) {
    return 'الطلب: $status';
  }

  @override
  String get applyTitle => 'التقديم';

  @override
  String get applyResumeSection => 'سيرتك الذاتية';

  @override
  String applyResumeUploaded(String size) {
    return 'تم الرفع · $size';
  }

  @override
  String get applyCoverLetterSection => 'خطاب التقديم';

  @override
  String get applyCoverHint => 'أضف ملاحظة لفريق التوظيف…';

  @override
  String get applyReviewSection => 'مراجعة وإرسال';

  @override
  String get applyApplicantLabel => 'المتقدم';

  @override
  String get applyResumeLabel => 'السيرة الذاتية';

  @override
  String get applyNoCoverLetter => 'لم تتم إضافة خطاب تقديم.';

  @override
  String get applySubmit => 'إرسال الطلب';

  @override
  String get applyDoneTitle => 'تم إرسال طلبك!';

  @override
  String applyDoneBody(String title, String company) {
    return 'تم إرسال طلبك لوظيفة $title في $company. يمكنك متابعة حالته من صفحة طلباتي.';
  }

  @override
  String get myApplicationsTitle => 'طلباتي';

  @override
  String get myApplicationsEmpty => 'لم تقدّم على أي وظيفة بعد';

  @override
  String get applicationStepSubmitted => 'الإرسال';

  @override
  String get applicationStepReview => 'المراجعة';

  @override
  String get applicationStepShortlist => 'الاختيار';

  @override
  String get applicationStepInterview => 'المقابلة';

  @override
  String get applicationStepDecision => 'القرار';

  @override
  String get applicationStatusSubmitted => 'تم الإرسال';

  @override
  String get applicationStatusInReview => 'قيد المراجعة';

  @override
  String get applicationStatusShortlisted => 'القائمة المختصرة';

  @override
  String get applicationStatusInterview => 'مقابلة';

  @override
  String get applicationStatusAccepted => 'مقبول';

  @override
  String get applicationStatusRejected => 'مرفوض';

  @override
  String get dashboardGreeting => 'مساءً الخير';

  @override
  String get dashboardContinueLearning => 'أكمل التعلّم';

  @override
  String dashboardLectureProgress(String current, String total) {
    return 'المحاضرة $current من $total · نظري';
  }

  @override
  String get dashboardStatCourses => 'دورات نشطة';

  @override
  String get dashboardStatHours => 'ساعة تعلّم';

  @override
  String get dashboardStatCertificates => 'شهادات';

  @override
  String get dashboardSectionLearning => 'التعلّم';

  @override
  String get dashboardSectionServices => 'الخدمات';

  @override
  String get dashboardSectionTools => 'أدواتي';

  @override
  String dashboardNewBadge(String count) {
    return '$count جديد';
  }

  @override
  String get dashboardTheory => 'محاضرات نظرية';

  @override
  String get dashboardTheorySubtitle => 'دروس ومفاهيم أساسية';

  @override
  String get dashboardPractical => 'محاضرات عملية';

  @override
  String get dashboardPracticalSubtitle => 'تطبيقات وأمثلة عملية';

  @override
  String get dashboardTraining => 'تدريب وتطوير';

  @override
  String get dashboardTrainingSubtitle => 'برامج تطوير المهارات';

  @override
  String get dashboardEngy => 'المهندسة إنجي';

  @override
  String get dashboardEngySubtitle => 'مساعدتك الذكية للاستشارات';

  @override
  String get dashboardEngyBadge => 'AI';

  @override
  String get dashboardLegalRequest => 'طلب استشارة قانونية';

  @override
  String get dashboardLegalRequestSubtitle => 'خطوات حل النزاعات القانونية';

  @override
  String get dashboardLegalAffairs => 'الشؤون القانونية';

  @override
  String get dashboardLegalAffairsSubtitle => 'حقوق المهندس والقوانين';

  @override
  String get dashboardNotes => 'ملاحظاتي';

  @override
  String get dashboardNotesSubtitle => 'ملاحظاتك الشخصية';

  @override
  String get dashboardLibrary => 'المكتبة الهندسية';

  @override
  String get dashboardLibrarySubtitle => 'مراجع وأكواد ومواصفات';

  @override
  String dashboardOpening(String item) {
    return 'جارٍ فتح $item';
  }

  @override
  String get dashboardEngyGreeting => 'مرحباً، أنا إنجي — كيف أساعدك؟';

  @override
  String get authSignInTitle => 'تسجيل الدخول';

  @override
  String get authSignUpTitle => 'إنشاء حساب جديد';

  @override
  String get authUserName => 'معرف المستخدم';

  @override
  String get authUserNameHint => 'بالأحرف اللاتينية أو الأرقام';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authFullName => 'الاسم الكامل';

  @override
  String get authFullNameHint => 'كما تريد أن يظهر في ملفك';

  @override
  String get authCompanyName => 'اسم الشركة';

  @override
  String get authCompanyNameHint => 'كما تريد أن يظهر في صفحة الشركة';

  @override
  String get authPhone => 'رقم الهاتف';

  @override
  String get authAccountType => 'نوع الحساب';

  @override
  String get authAccountIndividual => 'فرد';

  @override
  String get authAccountCompany => 'شركة';

  @override
  String get authSubmitSignIn => 'دخول';

  @override
  String get authSubmitSignUp => 'إنشاء الحساب';

  @override
  String get authSwitchToSignUp => 'ليس لديك حساب؟ أنشئ حساباً';

  @override
  String get authSwitchToSignIn => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get authRequiredField => 'هذا الحقل مطلوب';

  @override
  String get authPasswordTooShort => 'كلمة المرور 8 أحرف على الأقل';

  @override
  String get authUserNameTooShort => 'معرف المستخدم 3 أحرف على الأقل';

  @override
  String get authChecking => 'جارٍ التحقق…';

  @override
  String get authAvailable => 'متاح';

  @override
  String get authUserNameTaken => 'هذا المعرف محجوز، جرّب غيره';

  @override
  String get authPhoneTaken => 'هذا الرقم مسجّل بحساب آخر';

  @override
  String get authPhoneHint => '7701234567';

  @override
  String get authSessionExpired => 'انتهت صلاحية الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get authPasswordWeak => 'أضف رقمًا وحرفًا كبيرًا وحرفًا صغيرًا';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authEmailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get authEmailHint => 'name@example.com';

  @override
  String get authEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get authEmailTaken => 'هذا البريد مسجّل بحساب آخر';

  @override
  String get authVerifyTitle => 'تأكيد رقم هاتفك';

  @override
  String get authVerifyNoDraft => 'انتهت جلسة التسجيل. ابدأ من جديد.';

  @override
  String get authVerifyRestart => 'البدء من جديد';

  @override
  String get authVerifyEmailLater =>
      'يمكنك تأكيد بريدك الإلكتروني بعد إنشاء الحساب لتفعيل التحقق بخطوتين.';

  @override
  String get authVerifyCodeTitle => 'أدخل رمز التأكيد';

  @override
  String get authVerifyResend => 'إعادة الإرسال';

  @override
  String get authVerifyConfirm => 'تأكيد';

  @override
  String get authVerifyNoCode => 'لم يصلك الرمز؟';

  @override
  String get authVerifySentTo => 'أرسلنا رمزًا من 6 أرقام إلى';

  @override
  String get authPhoneInvalid => 'أدخل رقم هاتف صحيح';

  @override
  String authAccountCreated(String name) {
    return 'تم إنشاء حسابك، أهلاً بك $name 🎉';
  }

  @override
  String get setupTitle => 'أكمل ملفك';

  @override
  String get setupSubtitle => 'عرّف الآخرين بنفسك — يمكنك تعديل كل شيء لاحقاً.';

  @override
  String get setupSubtitleCompany =>
      'عرّف الآخرين بشركتك — يمكنك تعديل كل شيء لاحقاً.';

  @override
  String get setupHeadline => 'المسمّى المهني';

  @override
  String get setupHeadlineHint => 'مهندس برمجيات في…';

  @override
  String get setupHeadlineHintCompany => 'ما الذي تقدّمه شركتك؟';

  @override
  String get setupAbout => 'نبذة';

  @override
  String get setupAboutHint => 'بضعة أسطر عن خبرتك واهتماماتك';

  @override
  String get setupAboutHintCompany => 'بضعة أسطر عن نشاط الشركة';

  @override
  String get setupLocation => 'الموقع';

  @override
  String get setupLocationHint => 'بغداد، العراق';

  @override
  String get setupIndustry => 'المجال';

  @override
  String get setupIndustryHint => 'التقنية، الهندسة، الرعاية الصحية…';

  @override
  String get setupWebsite => 'الموقع الإلكتروني';

  @override
  String get setupOpenToWork => 'متاح لفرص عمل';

  @override
  String get setupOpenToWorkSubtitle => 'يظهر شارة على ملفك';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotTitle => 'استعادة كلمة المرور';

  @override
  String get forgotIntro =>
      'اختر طريقة استلام رمز التحقق، ثم عيّن كلمة مرور جديدة.';

  @override
  String get forgotSend => 'إرسال الرمز';

  @override
  String get forgotNoAccountPhone =>
      'لا يوجد حساب بهذا الرقم. تحقق منه أو أنشئ حسابًا جديدًا.';

  @override
  String get forgotNoAccountEmail =>
      'لا يوجد حساب مؤكَّد بهذا البريد. جرّب رقم هاتفك.';

  @override
  String get forgotChangeTarget => 'تغيير الرقم أو البريد';

  @override
  String get forgotLeaveTitle => 'إلغاء استعادة كلمة المرور؟';

  @override
  String get forgotLeaveBody =>
      'لن تتغيّر كلمة المرور وسيتم تسجيل خروجك. ستحتاج إلى رمز تحقق جديد للمحاولة مرة أخرى.';

  @override
  String get forgotLeaveConfirm => 'إلغاء الاستعادة';

  @override
  String get forgotSetTitle => 'كلمة مرور جديدة';

  @override
  String get forgotSetSubtitle => 'اختر كلمة مرور لا تستخدمها في مكان آخر.';

  @override
  String get forgotNewPassword => 'كلمة المرور الجديدة';

  @override
  String get forgotConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get forgotPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get forgotSave => 'حفظ كلمة المرور';

  @override
  String get forgotDone => 'تم تغيير كلمة المرور ✅';

  @override
  String get setupCareerTitle => 'سيرتك المهنية';

  @override
  String get setupCv => 'السيرة الذاتية';

  @override
  String get setupCvOnFile => 'مرفقة';

  @override
  String get notificationsFollowApproved => 'وافقت على طلب المتابعة';

  @override
  String get notificationsRequestHandled => 'تمت معالجة هذا الطلب مسبقًا';

  @override
  String toastFollowApproved(String name) {
    return 'أصبح $name يتابعك';
  }

  @override
  String get activityFollowRequested => 'طلب متابعتك';

  @override
  String get settingsPrivacy => 'الخصوصية';

  @override
  String get settingsPrivateAccount => 'حساب خاص';

  @override
  String get settingsPrivateAccountOn =>
      'منشوراتك تظهر لمتابعيك فقط، وتوافق على كل طلب متابعة جديد';

  @override
  String get settingsPrivateAccountOff => 'يمكن لأي شخص رؤية منشوراتك ومتابعتك';

  @override
  String get profilePrivateTitle => 'هذا الحساب خاص';

  @override
  String get profilePrivateBody => 'تابِع هذا الحساب لرؤية منشوراته';

  @override
  String get profilePrivateRequested =>
      'أُرسل طلب المتابعة، وستظهر المنشورات بعد الموافقة';

  @override
  String postReplyingTo(String name) {
    return 'الرد على $name';
  }

  @override
  String get postCancelReply => 'إلغاء الرد';

  @override
  String get postWriteReply => 'اكتب ردًّا…';

  @override
  String get subscriptionApprovedToast =>
      'تمت الموافقة على اشتراكك وأصبح فعّالًا';

  @override
  String get feedRankingTitle => 'ترتيب المنشورات';

  @override
  String get feedRankingSaved => 'تم حفظ إعدادات الترتيب';

  @override
  String get feedRankingIntro =>
      'تحدد هذه الأوزان كيف يرتّب التطبيق منشورات الصفحة الرئيسية لكل المستخدمين. الأوزان نسبية: المهم هو النسبة بينها. تسري التغييرات على الصفحات التي تُحمَّل بعد الحفظ.';

  @override
  String get feedRankingWeights => 'الأوزان';

  @override
  String get feedRankingAdvanced => 'متقدم';

  @override
  String get feedRankingAffinity => 'القرب من الكاتب';

  @override
  String get feedRankingAffinityHint =>
      'كم يتفاعل المستخدم مع هذا الكاتب. الأعلى يجعل الصفحة أكثر شخصية.';

  @override
  String get feedRankingRecency => 'الحداثة';

  @override
  String get feedRankingRecencyHint => 'تفضيل المنشورات الأحدث.';

  @override
  String get feedRankingEngagement => 'التفاعل';

  @override
  String get feedRankingEngagementHint =>
      'الإعجابات والتعليقات والمشاركات بالنسبة لعمر المنشور.';

  @override
  String get feedRankingUnseen => 'مكافأة غير المُشاهَد';

  @override
  String get feedRankingUnseenHint =>
      'رفع المنشورات التي لم يرها المستخدم بعد.';

  @override
  String get feedRankingRepeat => 'عقوبة تكرار الكاتب';

  @override
  String get feedRankingRepeatHint =>
      'تخفيض كل منشور إضافي من نفس الكاتب في الصفحة، حتى لا يستحوذ كاتب واحد عليها.';

  @override
  String get feedRankingHalfLife => 'نصف عمر الحداثة';

  @override
  String get feedRankingHalfLifeHint =>
      'بعد هذه المدة تنخفض قيمة الحداثة إلى النصف. القيم القصيرة تجعل الصفحة زمنية أكثر.';

  @override
  String get feedRankingOverfetch => 'عدد المرشحين لكل خانة';

  @override
  String get feedRankingOverfetchHint =>
      'كم منشورًا يُجلب لكل مكان في الصفحة قبل الترتيب. الأعلى أدق لكنه أبطأ وأكثر كلفة.';

  @override
  String get feedRankingTtl => 'مدة بقاء عناصر الصفحة';

  @override
  String get feedRankingTtlHint =>
      'بعدها تُحذف المنشورات غير المقروءة من صفحة المستخدم. صفر يعني بلا حذف.';

  @override
  String get feedRankingTtlForever => 'دائم';

  @override
  String feedRankingHours(int count) {
    return '$count ساعة';
  }

  @override
  String feedRankingDays(int count) {
    return '$count يوم';
  }

  @override
  String get feedRankingReset => 'استعادة القيم الافتراضية';

  @override
  String get settingsAdmin => 'الإدارة';

  @override
  String get panelAccessTitle => 'صلاحية لوحتي';

  @override
  String get panelAccessIntro =>
      'حدد ما إذا كانت لوحة المهندس تتطلب اشتراكًا، وأي أقسامها مفتوحة للجميع. تسري التغييرات فورًا على كل المستخدمين.';

  @override
  String get panelAccessGateSection => 'الاشتراك';

  @override
  String get panelAccessGate => 'طلب اشتراك للوحة';

  @override
  String get panelAccessGateOn =>
      'اللوحة مغلقة إلا للمشتركين، عدا الأقسام المفتوحة أدناه.';

  @override
  String get panelAccessGateOff => 'اللوحة مفتوحة للجميع بالكامل.';

  @override
  String get panelAccessTrial => 'مدة التجربة';

  @override
  String get panelAccessTrialHint =>
      'أيام يحصل فيها الحساب الجديد على اللوحة كاملة، تُحسب من تاريخ إنشائه.';

  @override
  String get panelAccessTrialNone => 'بلا تجربة';

  @override
  String panelAccessDays(String count) {
    return '$count يوم';
  }

  @override
  String get panelAccessSections => 'الأقسام';

  @override
  String get panelAccessSectionsHint =>
      'القسم المفعّل هنا مفتوح لكل المستخدمين بلا اشتراك؛ البقية تحتاج اشتراكًا.';

  @override
  String get panelAccessSectionsIgnored =>
      'لا أثر لهذه الخيارات ما دامت اللوحة مفتوحة للجميع.';

  @override
  String get panelAccessSectionFree => 'مفتوح بلا اشتراك';

  @override
  String get panelAccessSectionPaid => 'يتطلب اشتراكًا';

  @override
  String get panelAccessSaved => 'تم حفظ إعدادات اللوحة';

  @override
  String get dashboardSectionLocked => 'يتطلب اشتراكًا — اضغط للاشتراك';

  @override
  String get panelAccessLibraryLive => 'تفعيل المكتبة الهندسية';

  @override
  String get panelAccessLibraryLiveHint =>
      'ما دامت متوقفة تظهر في اللوحة بوسم «قريبًا» ولا تُفتح، مهما كانت إعدادات الاشتراك.';

  @override
  String get disciplinesTitle => 'الاختصاصات الهندسية';

  @override
  String get disciplinesIntro =>
      'الاختصاصات التي يختار منها المهندسون عند إنشاء ملفاتهم. اضغط على الشعار لرفع صورة، والمفتاح لإيقاف اختصاص دون حذفه — من اختاره يحتفظ به.';

  @override
  String get disciplineAdd => 'إضافة اختصاص';

  @override
  String get disciplineRename => 'تعديل الاسم';

  @override
  String get disciplineSetLogo => 'رفع شعار';

  @override
  String get disciplineClearLogo => 'إزالة الشعار';

  @override
  String get disciplineNameTitle => 'اسم الاختصاص';

  @override
  String get disciplineNameAr => 'الاسم بالعربية';

  @override
  String get disciplineNameEn => 'الاسم بالإنجليزية';

  @override
  String get disciplineLogoHint => 'اضغط على المربع لرفع شعار';

  @override
  String get disciplineLogoNoStorage => 'رفع الصور غير مهيأ على هذا الخادم';

  @override
  String get disciplinePickerTitle => 'اختر اختصاصك';

  @override
  String get disciplinePickerHint => 'اختر اختصاصك';

  @override
  String get disciplinePickerSearch => 'ابحث عن اختصاص…';

  @override
  String get disciplinePickerClear => 'بلا اختصاص';

  @override
  String get disciplinePickerFailed => 'تعذّر تحميل قائمة الاختصاصات.';

  @override
  String get setupDiscipline => 'الاختصاص';

  @override
  String get setupDisciplineHint => 'اختر اختصاصك الهندسي';

  @override
  String get editProfileDiscipline => 'الاختصاص';

  @override
  String get governoratePickerTitle => 'اختر المحافظة';

  @override
  String get governoratePickerHint => 'اختر المحافظة';

  @override
  String get governoratePickerSearch => 'ابحث عن محافظة…';

  @override
  String get governoratePickerClear => 'بلا محافظة';

  @override
  String get governoratePickerFailed => 'تعذّر تحميل قائمة المحافظات.';

  @override
  String get setupGovernorate => 'المحافظة';

  @override
  String get setupGovernorateHint => 'اختر محافظتك';

  @override
  String get editProfileGovernorate => 'المحافظة';

  @override
  String get profileTabPosts => 'المنشورات';

  @override
  String get profileTabReels => 'ريلز';

  @override
  String get profileTabCv => 'الخبرة';

  @override
  String get profileNoPosts => 'لا توجد منشورات بعد.';

  @override
  String get profileNoReels => 'لا توجد ريلز بعد.';

  @override
  String get profileMessage => 'مراسلة';

  @override
  String get profileNoCv => 'لا توجد سيرة ذاتية مرفوعة.';

  @override
  String get profileCvFailed => 'تعذّر فتح السيرة الذاتية.';

  @override
  String get activityFollowAccepted => 'قبل طلب المتابعة';

  @override
  String get postOptionsTitle => 'خيارات المنشور';

  @override
  String get postOptionsEdit => 'تعديل المنشور';

  @override
  String get postOptionsDelete => 'حذف المنشور';

  @override
  String get postOptionsReport => 'الإبلاغ عن المنشور';

  @override
  String get postOptionsSave => 'حفظ المنشور';

  @override
  String get postOptionsUnsave => 'إزالة من المحفوظات';

  @override
  String get postDeleteConfirm => 'حذف هذا المنشور نهائياً؟';

  @override
  String get postDeleteConfirmBody => 'لا يمكن التراجع عن الحذف.';

  @override
  String get toastPostDeleted => 'حُذف المنشور';

  @override
  String get postEditTitle => 'تعديل المنشور';

  @override
  String get postEditHint => 'اكتب شيئاً…';

  @override
  String get postEditEmpty => 'لا يمكن ترك المنشور فارغاً';

  @override
  String get toastPostUpdated => 'تم تحديث المنشور';

  @override
  String get postReportTitle => 'سبب الإبلاغ';

  @override
  String get postReportDetailsHint => 'تفاصيل إضافية (اختياري)';

  @override
  String get postReportSend => 'إرسال البلاغ';

  @override
  String get toastPostReported => 'شكراً، وصلنا بلاغك';

  @override
  String get reportReasonSpam => 'محتوى مزعج أو إعلاني';

  @override
  String get reportReasonHarassment => 'تحرّش أو تنمّر';

  @override
  String get reportReasonHateSpeech => 'خطاب كراهية';

  @override
  String get reportReasonViolence => 'عنف أو تهديد';

  @override
  String get reportReasonNudity => 'محتوى جنسي أو عارٍ';

  @override
  String get reportReasonMisinformation => 'معلومات مضللة';

  @override
  String get reportReasonSelfHarm => 'إيذاء النفس';

  @override
  String get reportReasonImpersonation => 'انتحال شخصية';

  @override
  String get reportReasonIntellectualProperty => 'انتهاك حقوق ملكية';

  @override
  String get reportReasonOther => 'سبب آخر';

  @override
  String get companyApplicantOpenCv => 'عرض السيرة الذاتية';

  @override
  String get companyApplicantNoCv => 'لم يُرفق المتقدّم سيرة ذاتية';

  @override
  String get companyApplicantCvFailed => 'تعذّر فتح الملف';

  @override
  String get companyApplicantNotes => 'ملاحظات المتقدّم';

  @override
  String get companyApplicantNoNotes => 'لم يكتب المتقدّم أي ملاحظات';

  @override
  String get companyApplicantDetails => 'عرض التفاصيل';

  @override
  String get companyApplicantProfile => 'الملف الشخصي';

  @override
  String get companyDashboardTitle => 'لوحة الشركة';

  @override
  String get companyStatOpenJobs => 'وظائف مفتوحة';

  @override
  String get companyStatApplicants => 'إجمالي المتقدّمين';

  @override
  String get companyStatNewThisWeek => 'متقدّمون هذا الأسبوع';

  @override
  String get companyStatFollowers => 'متابعو الصفحة';

  @override
  String get companyPendingTitle => 'بانتظار قرارك';

  @override
  String get companyPendingEmpty => 'لا توجد طلبات بانتظار قرار';

  @override
  String get companyPendingAll => 'كل المتقدّمين';

  @override
  String get companyOpenJobsTitle => 'وظائفك المفتوحة';

  @override
  String get companyOpenJobsEmpty => 'لا توجد وظائف مفتوحة الآن';

  @override
  String companyJobApplicants(String count) {
    return 'المتقدّمون: $count';
  }

  @override
  String companyClosedJobs(String count) {
    return 'وظائف مغلقة: $count';
  }

  @override
  String companyDashboardGreeting(String name) {
    return 'أهلاً، $name';
  }

  @override
  String get companyQuickActions => 'إجراءات سريعة';

  @override
  String get companyEditPage => 'تعديل الصفحة';

  @override
  String get jobApplyLocked => 'التقديم للمشتركين';

  @override
  String get jobApplyLockedBody => 'اشترك لتتمكن من التقديم على الوظائف';

  @override
  String get authAccountEngineer => 'مهندس';

  @override
  String get authAccountContractor => 'مقاول';

  @override
  String get authAccountCraftsman => 'حرفي';

  @override
  String get authAccountEquipmentOwner => 'صاحب آلية';

  @override
  String get authBusinessName => 'اسم النشاط';

  @override
  String get authBusinessNameHint => 'كما تريد أن يظهر في صفحتك';

  @override
  String get profileTradeLabel => 'الحرفة';

  @override
  String get profileEquipmentLabel => 'نوع الآلية';

  @override
  String get authAccountTypeSheetTitle => 'اختر نوع الحساب';

  @override
  String get authAccountEngineerHint =>
      'حساب شخصي: تتقدّم على الوظائف وتبني ملفك المهني.';

  @override
  String get authAccountCompanyHint => 'تنشر الوظائف وتستقبل طلبات المتقدّمين.';

  @override
  String get authAccountContractorHint => 'تنفّذ المشاريع وتنشر فرص العمل.';

  @override
  String get authAccountCraftsmanHint =>
      'صاحب مهنة: نجار، حدّاد، كهربائي وغيرها.';

  @override
  String get authAccountEquipmentOwnerHint =>
      'تؤجّر الآليات والمعدّات وتنشر فرص العمل.';

  @override
  String get myCoursesTitle => 'دوراتي';

  @override
  String get myCoursesEmpty =>
      'لم تنشئ أي دورة بعد. ابدأ بدورة جديدة وأرسلها للمراجعة.';

  @override
  String get myCoursesNew => 'دورة جديدة';

  @override
  String get myCoursesEarnings => 'أرباح دوراتي';

  @override
  String get courseStatusDraft => 'مسودة';

  @override
  String get courseStatusSubmitted => 'قيد المراجعة';

  @override
  String get courseStatusRejected => 'مُعادة للتعديل';

  @override
  String get courseStatusApproved => 'منشورة';

  @override
  String get courseEditorEdit => 'تعديل الدورة';

  @override
  String get courseFieldTitle => 'عنوان الدورة';

  @override
  String get courseFieldSummary => 'وصف مختصر';

  @override
  String get courseFieldDescription => 'الوصف الكامل';

  @override
  String get courseFieldCategory => 'القسم';

  @override
  String get courseFieldLevel => 'المستوى';

  @override
  String get courseFieldPrice => 'السعر';

  @override
  String get courseFieldPriceHint => 'اتركه صفرًا لتكون الدورة مجانية';

  @override
  String get courseAddLine => 'إضافة سطر';

  @override
  String get courseLessons => 'الدروس';

  @override
  String get courseAddLesson => 'إضافة درس';

  @override
  String get courseLessonTitle => 'عنوان الدرس';

  @override
  String get courseLessonKind => 'نوع الدرس';

  @override
  String get courseLessonDuration => 'المدة بالدقائق';

  @override
  String get courseLessonPreview => 'درس تجريبي مجاني';

  @override
  String get courseLessonBody => 'نص الدرس';

  @override
  String get courseLessonDelete => 'حذف الدرس';

  @override
  String get courseSubmitForReview => 'إرسال للمراجعة';

  @override
  String get courseSubmittedToast => 'أُرسلت الدورة للمراجعة';

  @override
  String get courseSavedToast => 'تم حفظ الدورة';

  @override
  String get courseReviewNote => 'ملاحظة المراجع';

  @override
  String get courseLockedUntilReview =>
      'الدورة عند المراجع ولا يمكن تعديلها حتى يصدر القرار.';

  @override
  String get courseLockedApproved => 'الدورة منشورة ولا يمكن تعديلها.';

  @override
  String get courseBuy => 'شراء الدورة';

  @override
  String get coursePurchasePending => 'بانتظار تأكيد الدفع';

  @override
  String get coursePurchasePaid => 'تم الشراء';

  @override
  String get coursePurchaseAsked =>
      'تم إرسال طلب الشراء. تُفتح الدورة فور تأكيد الدفع.';

  @override
  String courseSubscriberDiscount(String percent) {
    return 'خصم المشتركين $percent%';
  }

  @override
  String get courseReviewTitle => 'مراجعة الدورات';

  @override
  String get courseReviewEmpty => 'لا توجد دورات بانتظار المراجعة.';

  @override
  String get courseApprove => 'موافقة';

  @override
  String get courseReject => 'رفض';

  @override
  String get coursePlatformPercent => 'نسبة المنصة %';

  @override
  String get coursePlatformPercentHint =>
      'تُحتسب من المبلغ المدفوع فعليًا، وتُثبّت على كل عملية شراء لهذه الدورة.';

  @override
  String get courseRejectReason => 'سبب الإعادة';

  @override
  String get courseApprovedToast => 'تمت الموافقة ونُشرت الدورة';

  @override
  String get courseRejectedToast => 'أُعيدت الدورة إلى ناشرها';

  @override
  String get courseAuthorLabel => 'الناشر';

  @override
  String get courseCommerceTitle => 'تسعير الدورات';

  @override
  String get courseCommerceIntro =>
      'رقمان يسريان على كل الدورات: نسبة المنصة المقترحة عند المراجعة، وخصم المشتركين على السعر.';

  @override
  String get courseCommissionDefault => 'نسبة المنصة الافتراضية %';

  @override
  String get courseCommissionDefaultHint =>
      'قيمة مقترحة فقط؛ النسبة المُلزِمة هي ما يُثبَّت على كل دورة عند الموافقة.';

  @override
  String get courseDiscountPercent => 'خصم المشتركين على الدورات %';

  @override
  String get courseDiscountPercentHint =>
      'يُخصم من سعر كل دورة مدفوعة لصاحب الاشتراك الفعّال. صفر يوقف الخصم.';

  @override
  String get courseCommerceSaved => 'تم حفظ إعدادات التسعير';

  @override
  String get coursePurchasesTitle => 'طلبات شراء الدورات';

  @override
  String get coursePurchasesEmpty => 'لا توجد طلبات شراء.';

  @override
  String get purchaseConfirm => 'تأكيد الدفع';

  @override
  String get purchaseCancelRequest => 'إلغاء الطلب';

  @override
  String get purchaseAmountDue => 'المبلغ';

  @override
  String get purchasePlatformShare => 'حصة المنصة';

  @override
  String get purchaseAuthorShare => 'حصة الناشر';

  @override
  String get purchaseConfirmedToast => 'تم تأكيد الدفع';

  @override
  String get purchaseCancelledToast => 'أُلغي الطلب';

  @override
  String get purchaseNote => 'ملاحظة';

  @override
  String get courseEarningsEmpty => 'لم تُبَع أي من دوراتك بعد.';

  @override
  String get dashboardTeach => 'دوراتي كمدرّب';

  @override
  String get dashboardTeachSubtitle =>
      'أنشئ دورة، حدّد سعرها، وأرسلها للمراجعة';

  @override
  String get courseCoverLabel => 'صورة الغلاف';

  @override
  String get courseCoverAdd => 'أضف صورة غلاف للدورة';

  @override
  String get courseCoverHint => 'تظهر على بطاقة الدورة في الكتالوج';

  @override
  String get courseCoverChange => 'تغيير الصورة';

  @override
  String get courseCoverRemove => 'إزالة الصورة';

  @override
  String get courseLessonFile => 'ملف الدرس';

  @override
  String get courseLessonPickVideo => 'اختيار فيديو';

  @override
  String get courseLessonPickPdf => 'اختيار ملف PDF';

  @override
  String get courseLessonFileReady => 'تم رفع الملف';

  @override
  String get courseLessonFileMissing => 'لم يُرفع ملف بعد';

  @override
  String courseUploading(String percent) {
    return 'جارٍ الرفع… $percent%';
  }

  @override
  String get courseLessonsAutoSave =>
      'تُحفظ الدورة تلقائيًا عند إضافة أول درس.';

  @override
  String get courseNewTag => 'جديد';

  @override
  String get profileBannerAdd => 'أضف صورة غلاف';

  @override
  String get profileBannerChange => 'تغيير صورة الغلاف';

  @override
  String get profileBannerRemove => 'إزالة صورة الغلاف';

  @override
  String get profileBannerSaved => 'تم تحديث صورة الغلاف';

  @override
  String get composerReelsStreamOff =>
      'نشر الريلز غير متاح على هذا الخادم حالياً';

  @override
  String get courseLessonStreamOff =>
      'رفع فيديو المحاضرات غير متاح على هذا الخادم حالياً';

  @override
  String get uploadBannerUploading => 'جارٍ رفع الفيديو';

  @override
  String get uploadBannerFinishing => 'جارٍ النشر…';

  @override
  String get uploadBannerDone => 'تم الرفع والنشر';

  @override
  String get uploadBannerFailed => 'فشل الرفع';

  @override
  String get uploadBannerBusy => 'هناك فيديو قيد الرفع بالفعل، انتظر حتى ينتهي';

  @override
  String get uploadLeaveTitle => 'الرفع لم ينتهِ';

  @override
  String get uploadLeaveBody =>
      'إغلاق التطبيق الآن سيلغي رفع الفيديو. هل تريد الخروج؟';

  @override
  String get uploadLeaveStay => 'ابقَ';

  @override
  String get uploadLeaveQuit => 'اخرج';

  @override
  String get uploadStartedBackground => 'سيكمل الرفع في الخلفية';

  @override
  String get uploadBannerCancel => 'إلغاء';

  @override
  String get uploadBannerCancelled => 'أُلغي الرفع';

  @override
  String get courseSaveAndAddLessons => 'حفظ ومتابعة للمحاضرات';

  @override
  String get courseLessonsTitle => 'محاضرات الدورة';

  @override
  String get courseLessonsEmpty => 'لا محاضرات بعد. أضف أول محاضرة لتبدأ.';

  @override
  String get courseLessonsNextStep => 'حُفظت الدورة. أضف محاضراتها الآن.';

  @override
  String get courseLessonUploadingChip => 'جارٍ الرفع';

  @override
  String get courseLessonUploadIncomplete =>
      'لم يكتمل رفع الملف — المس لإعادة المحاولة';

  @override
  String get courseLessonUploadQueued => 'في انتظار الرفع';

  @override
  String get courseLessonServerOutdated =>
      'الخادم الحالي لا يدعم حفظ الدرس قبل اكتمال رفع الملف. أعد تشغيل الخادم بعد آخر تحديث.';

  @override
  String get toastReelReposted => 'أُعيد نشر الريل لمتابعيك';

  @override
  String get toastReelUnreposted => 'أُلغيت إعادة النشر';

  @override
  String get postOriginalUnavailable => 'المنشور الأصلي لم يعد متاحًا.';

  @override
  String get cropAvatarTitle => 'قصّ الصورة الشخصية';

  @override
  String get cropBannerTitle => 'قصّ صورة الغلاف';

  @override
  String get cropDone => 'تم';

  @override
  String get cropCancel => 'إلغاء';

  @override
  String get reelOptions => 'خيارات الريل';

  @override
  String get reelDelete => 'حذف الريل';

  @override
  String get reelUndoRepost => 'إلغاء إعادة النشر';

  @override
  String get reelDeleteConfirm => 'حذف هذا الريل نهائياً؟';

  @override
  String get reelDeleteConfirmBody =>
      'سيختفي من ملفك ومن كل من أعاد نشره، ولا يمكن التراجع عن الحذف.';

  @override
  String get toastReelDeleted => 'تم حذف الريل';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get legalLinkFailed =>
      'تعذّر فتح الصفحة. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get authTermsLead => 'بمتابعتك فإنك توافق على ';

  @override
  String get authTermsPrivacy => 'سياسة الخصوصية';

  @override
  String get authTermsTail => ' الخاصة بمهندس';

  @override
  String get authGenderOptional => 'الجنس (اختياري)';

  @override
  String get settingsDeleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف حسابك نهائياً؟';

  @override
  String get deleteAccountBody =>
      'سيُحذف ملفك المهني ومنشوراتك وريلزك وتعليقاتك ومتابعاتك، ولن تتمكن من تسجيل الدخول بهذا الحساب مرة أخرى. لا يمكن التراجع عن ذلك.';

  @override
  String get deleteAccountConfirm => 'حذف الحساب نهائياً';

  @override
  String get toastAccountDeleted => 'تم حذف حسابك';

  @override
  String get authPhoneOrEmailHint =>
      'أدخل رقم هاتفك أو بريدك الإلكتروني، يكفي أحدهما. سنرسل إليه رمز تأكيد.';

  @override
  String get authPhoneOrEmailRequired => 'أدخل رقم الهاتف أو البريد الإلكتروني';

  @override
  String get reportProfile => 'الإبلاغ عن الحساب';

  @override
  String get reportReel => 'الإبلاغ عن الريل';

  @override
  String get reportComment => 'الإبلاغ عن التعليق';

  @override
  String get reportMessage => 'الإبلاغ عن الرسالة';

  @override
  String get reportStory => 'الإبلاغ عن القصة';

  @override
  String get actionReport => 'إبلاغ';

  @override
  String get authTermsLink => 'شروط الاستخدام';

  @override
  String get authTermsAnd => ' و';

  @override
  String get settingsTerms => 'شروط الاستخدام';

  @override
  String get hashtagPostsEmpty => 'لا توجد منشورات بهذا الوسم بعد';

  @override
  String get storyReplyHint => 'أرسل ردًّا…';

  @override
  String get storyReplySend => 'إرسال';

  @override
  String get storyReplySent => 'تم إرسال ردّك في الرسائل';

  @override
  String get storyReplyFailed => 'تعذّر إرسال الرد، حاول مجددًا';

  @override
  String get storyLike => 'إعجاب';

  @override
  String get storyLikeFailed => 'تعذّر تسجيل الإعجاب';

  @override
  String get activityLikedStory => 'أعجب بقصتك';

  @override
  String get activityCommentedReel => 'علّق على مقطعك';

  @override
  String get reelComment => 'تعليق';

  @override
  String get reelCommentsTitle => 'التعليقات';

  @override
  String get reelCommentsEmpty => 'لا توجد تعليقات بعد. كن أول من يعلّق!';

  @override
  String get reelCommentsRetry => 'إعادة المحاولة';

  @override
  String get reelCommentHint => 'أضف تعليقًا…';

  @override
  String get reelCommentReply => 'رد';

  @override
  String reelCommentReplyingTo(String name) {
    return 'الرد على $name';
  }

  @override
  String get reelCommentDelete => 'حذف';

  @override
  String get reelCommentDeleteTitle => 'حذف التعليق؟';

  @override
  String get reelCommentDeleteBody => 'سيُحذف التعليق وكل الردود عليه.';

  @override
  String get reelCommentDeleted => 'تم حذف التعليق';

  @override
  String get reelCommentReport => 'إبلاغ';

  @override
  String get composerAddPoll => 'إضافة استطلاع';

  @override
  String get composerRemovePoll => 'إزالة الاستطلاع';

  @override
  String get composerPollTitle => 'استطلاع رأي';

  @override
  String get composerPollQuestionNote => 'نص المنشور هو سؤال الاستطلاع.';

  @override
  String composerPollOptionHint(String n) {
    return 'الخيار $n';
  }

  @override
  String get composerPollAddOption => 'إضافة خيار';

  @override
  String get composerPollRemoveOption => 'حذف الخيار';

  @override
  String get pollDurationHour => 'ساعة';

  @override
  String get pollDurationSixHours => '6 ساعات';

  @override
  String get pollDurationDay => 'يوم';

  @override
  String get pollDurationThreeDays => '3 أيام';

  @override
  String get pollDurationWeek => 'أسبوع';

  @override
  String pollVotes(String count) {
    return '$count صوت';
  }

  @override
  String pollLeftDays(String n) {
    return 'متبقٍ $n يوم';
  }

  @override
  String pollLeftHours(String n) {
    return 'متبقٍ $n ساعة';
  }

  @override
  String pollLeftMinutes(String n) {
    return 'متبقٍ $n دقيقة';
  }

  @override
  String get pollClosed => 'انتهى التصويت';

  @override
  String get pollVoteFailed => 'تعذّر تسجيل صوتك';

  @override
  String get setupSecureTitle => 'أمّن حسابك';

  @override
  String get setupSecureOptional => 'اختياري';

  @override
  String get setupSecureBody =>
      'أكّد بريدك الإلكتروني ليصبح وسيلة تحقق ثانية وطريقة لاستعادة حسابك إن فقدت رقمك.';

  @override
  String get setupSecureAction => 'تأكيد البريد';

  @override
  String get setupSecureDismiss => 'ليس الآن';

  @override
  String get emailVerifyTitle => 'البريد الإلكتروني والتحقق بخطوتين';

  @override
  String get emailVerifyIntro =>
      'أضف بريدك الإلكتروني وأكّده ليصبح وسيلة تحقق ثانية لحسابك، وطريقة للدخول إن فقدت رقم هاتفك. رقم الهاتف يبقى هو الأساس.';

  @override
  String get emailVerifySend => 'إرسال رمز التأكيد';

  @override
  String get emailVerifyChangeAddress => 'تغيير البريد';

  @override
  String get emailVerifyDone => 'تم تأكيد بريدك الإلكتروني ✅';

  @override
  String get setupSave => 'متابعة';

  @override
  String get setupSkip => 'تخطٍّ الآن';

  @override
  String get setupSaved => 'تم حفظ ملفك 🎉';

  @override
  String get authGender => 'الجنس';

  @override
  String get authGenderMale => 'ذكر';

  @override
  String get authGenderFemale => 'أنثى';

  @override
  String get authPhoto => 'صورة الملف';

  @override
  String get authPhotoPick => 'اختر صورة';

  @override
  String get authPhotoChange => 'تغيير الصورة';

  @override
  String get authPhotoRemove => 'إزالة';

  @override
  String get authPhotoUploading => 'جارٍ رفع الصورة…';

  @override
  String get authGenderRequired => 'اختر الجنس';

  @override
  String get profileConnectSent => 'تم إرسال الطلب';

  @override
  String get profileConnectAccept => 'قبول الطلب';

  @override
  String get profileConnected => 'متصل';

  @override
  String get profileFollowRequested => 'بانتظار الموافقة';

  @override
  String get toastConnectRequestCancelled => 'تم سحب الطلب';

  @override
  String get toastConnectionRemoved => 'تمت إزالة الاتصال';

  @override
  String get toastConnectAccepted => 'تم قبول الطلب';

  @override
  String get networkAddSent => 'تم الإرسال';

  @override
  String get welcomeConnectTitle => 'ابدأ شبكتك';

  @override
  String get welcomeConnectBody =>
      'هؤلاء أشخاص في مجالك — أرسل طلب تواصل لتظهر منشوراتهم في صفحتك الرئيسية.';

  @override
  String get welcomeConnectEmpty =>
      'لا توجد اقتراحات الآن. يمكنك البحث عن أشخاص في أي وقت من تبويب الشبكة.';

  @override
  String get welcomeConnectContinue => 'المتابعة إلى الرئيسية';

  @override
  String get activityFollowed => 'بدأ بمتابعتك';

  @override
  String get activityConnectRequested => 'أرسل إليك طلب تواصل';

  @override
  String get activityConnectAccepted => 'قبل طلب التواصل';

  @override
  String get activityLiked => 'أعجب بمنشورك';

  @override
  String get activityCommented => 'علّق على منشورك';

  @override
  String get activityMentioned => 'أشار إليك';

  @override
  String get activityMessaged => 'أرسل إليك رسالة';

  @override
  String get activityShared => 'أعاد نشر منشورك';

  @override
  String get activityApplied => 'تقدّم إلى وظيفتك';

  @override
  String get activityCalled => 'اتصل بك';

  @override
  String get activityOther => 'أرسل إليك إشعارًا';

  @override
  String get applyResumeNone => 'لا توجد سيرة ذاتية مرفقة';

  @override
  String get applyResumeUploadHint => 'اختر ملف PDF أو Word';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get profileEditExperience => 'تعديل الخبرات';

  @override
  String get profileEditEducation => 'تعديل التعليم';

  @override
  String get profileEditSkills => 'تعديل المهارات';

  @override
  String get profileAddExperience => 'إضافة خبرة';

  @override
  String get profileAddEducation => 'إضافة مؤهل';

  @override
  String get profileAddSkill => 'إضافة مهارة';

  @override
  String get profileSectionEmpty => 'لا توجد عناصر بعد';

  @override
  String get profileDeleteEntryTitle => 'حذف العنصر؟';

  @override
  String get profileDeleteEntryBody => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get fieldRole => 'المسمى الوظيفي';

  @override
  String get fieldCompany => 'الشركة';

  @override
  String get fieldEmploymentType => 'نوع التوظيف';

  @override
  String get fieldLocation => 'الموقع';

  @override
  String get fieldStartDate => 'تاريخ البدء';

  @override
  String get fieldEndDate => 'تاريخ الانتهاء';

  @override
  String get fieldCurrentRole => 'أعمل هنا حالياً';

  @override
  String get fieldDescription => 'الوصف';

  @override
  String get fieldSchool => 'الجامعة أو المدرسة';

  @override
  String get fieldDegree => 'الدرجة العلمية';

  @override
  String get fieldFieldOfStudy => 'التخصص';

  @override
  String get fieldSkillName => 'اسم المهارة';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get fieldNotSet => 'غير محدد';

  @override
  String get employmentFullTime => 'دوام كامل';

  @override
  String get employmentPartTime => 'دوام جزئي';

  @override
  String get employmentContract => 'عقد';

  @override
  String get employmentInternship => 'تدريب';

  @override
  String get employmentFreelance => 'عمل حر';

  @override
  String get employmentSelfEmployed => 'عمل خاص';

  @override
  String get employmentTemporary => 'مؤقت';

  @override
  String get editProfileChangePhoto => 'تغيير الصورة الشخصية';

  @override
  String get editProfileChangeCover => 'تغيير صورة الغلاف';

  @override
  String get profileActivity => 'النشاط';

  @override
  String get profileActivityPosts => 'المنشورات';

  @override
  String get profileActivityComments => 'التعليقات';

  @override
  String get profileActivityShowAll => 'عرض الكل';

  @override
  String get profileCreatePost => 'إنشاء منشور';

  @override
  String profileFollowersCount(String count) {
    return '$count متابع';
  }

  @override
  String get profileCommentedOn => 'علّق على منشور';

  @override
  String get postSeeMore => '…المزيد';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeSystem => 'حسب النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsSaved => 'المحفوظات';

  @override
  String get savedPostsTitle => 'المنشورات المحفوظة';

  @override
  String get savedPostsEmpty => 'لم تحفظ أي منشور بعد';

  @override
  String get savedJobsTitle => 'الوظائف المحفوظة';

  @override
  String get savedJobsEmpty => 'لم تحفظ أي وظيفة بعد';

  @override
  String get jobSaveRemoved => 'أُزيلت من المحفوظات';

  @override
  String get jobCompanyCannotApply => 'حسابات الشركات لا تتقدّم للوظائف';

  @override
  String get settingsLogout => 'تسجيل الخروج';

  @override
  String get settingsLogoutTitle => 'تسجيل الخروج؟';

  @override
  String get settingsLogoutBody => 'سيلزمك تسجيل الدخول مرة أخرى للمتابعة.';

  @override
  String get profileMoreOptions => 'خيارات';

  @override
  String get profileBlock => 'حظر';

  @override
  String get profileBlockTitle => 'حظر هذا الحساب؟';

  @override
  String get profileBlockBody =>
      'لن يرى أحدكما منشورات الآخر أو ملفه، وستُلغى المتابعة بينكما.';

  @override
  String get profileBlockDone => 'تم الحظر';

  @override
  String get feedSuggestedPost => 'مقترح لك';

  @override
  String get composerAddPhoto => 'إضافة صورة';

  @override
  String get composerUploadsOff => 'رفع الملفات غير مفعّل على هذا الخادم';

  @override
  String get composerAddDocument => 'إضافة ملف';

  @override
  String get composerAddHashtag => 'إضافة وسم';

  @override
  String get composerAddMention => 'الإشارة إلى شخص';

  @override
  String get composerModePost => 'منشور';

  @override
  String get composerModeStory => 'قصة';

  @override
  String get composerModeReel => 'ريل';

  @override
  String get composerSingleMediaOnly => 'هذا النوع يأخذ ملفاً واحداً فقط';

  @override
  String composerVideoTooLarge(int max) {
    return 'الفيديو كبير جداً (الحد $max ميجابايت)';
  }

  @override
  String composerDocumentTooLarge(int max) {
    return 'الملف كبير جداً (الحد $max ميجابايت)';
  }

  @override
  String get composerTitleStory => 'قصة جديدة';

  @override
  String get composerTitleReel => 'ريل جديد';

  @override
  String get composerHintStory => 'أضف تعليقاً على القصة…';

  @override
  String get composerHintReel => 'اكتب وصفاً للريل…';

  @override
  String get composerAddVideo => 'إضافة فيديو';

  @override
  String get composerStoryNeedsMedia => 'القصة تحتاج صورة أو فيديو';

  @override
  String get composerReelNeedsVideo => 'الريل يحتاج فيديو';

  @override
  String get composerModeDropped => 'أُزيلت المرفقات التي لا تناسب هذا النوع';

  @override
  String get toastStoryPosted => 'تم نشر القصة ✓';

  @override
  String get toastReelPosted => 'تم نشر الريل ✓';

  @override
  String get postOpenDocument => 'فتح الملف';

  @override
  String get postOpenDocumentFailed => 'تعذّر فتح الملف';

  @override
  String get composerPhotoRetry => 'إعادة المحاولة';

  @override
  String composerPhotoLimit(int max) {
    return 'يمكنك إرفاق $max صور كحد أقصى';
  }

  @override
  String get navMyJobs => 'وظائفي';

  @override
  String get navApplicants => 'المتقدّمون';

  @override
  String get navPage => 'صفحتي';

  @override
  String get companyJobsTitle => 'وظائفي';

  @override
  String get companyJobsEmpty => 'لم تنشر أي وظيفة بعد';

  @override
  String get companyJobsEmptyHint => 'انشر وظيفة ليبدأ المرشّحون بالتقديم';

  @override
  String get companyPostJob => 'نشر وظيفة';

  @override
  String get companyPublishJob => 'نشر الوظيفة';

  @override
  String get companyJobPosted => 'تم نشر الوظيفة';

  @override
  String get companyJobOpen => 'مفتوحة';

  @override
  String get companyJobClosed => 'مغلقة';

  @override
  String get companyViewApplicants => 'عرض المتقدّمين';

  @override
  String get companyApplicantsTitle => 'المتقدّمون';

  @override
  String get companyNoApplicants => 'لا يوجد متقدّمون بعد';

  @override
  String get companyNoApplicantsHint => 'سيظهر هنا كل من يقدّم على هذه الوظيفة';

  @override
  String get companyApplicantUnknown => 'متقدّم';

  @override
  String get companyStatusSaved => 'تم تحديث حالة الطلب';

  @override
  String get companyFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get companyJobTitle => 'المسمى الوظيفي';

  @override
  String get companyJobCompany => 'اسم الجهة';

  @override
  String get companyJobLocation => 'الموقع';

  @override
  String get companyJobEmploymentType => 'نوع التوظيف';

  @override
  String get companyJobWorkMode => 'نمط العمل';

  @override
  String get companyJobSalaryMin => 'أقل راتب';

  @override
  String get companyJobSalaryMax => 'أعلى راتب';

  @override
  String get companyJobDescription => 'الوصف';

  @override
  String get companyJobRequirements => 'المتطلبات';

  @override
  String get companyJobRequirementsHint => 'متطلب واحد في كل سطر';

  @override
  String companyApplicantCount(String count) {
    return '$count متقدّم';
  }

  @override
  String companyAppliedAgo(String time) {
    return 'قدّم $time';
  }

  @override
  String get companyOverview => 'نظرة عامة';

  @override
  String get companySize => 'حجم الشركة';

  @override
  String get companySizeSelf => 'أنا فقط';

  @override
  String get companyFounded => 'تاريخ التأسيس';

  @override
  String companyFoundedOn(String date) {
    return 'تأسست في $date';
  }

  @override
  String get companySpecialties => 'التخصصات';

  @override
  String get companySpecialtiesHint => 'تخصص واحد في كل سطر';

  @override
  String get companyJobCompanyWebsite => 'الموقع الإلكتروني';

  @override
  String get companyOpenJobs => 'الوظائف المتاحة';

  @override
  String companyOpenJobsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وظيفة مفتوحة',
      many: 'وظيفة مفتوحة',
      few: 'وظائف مفتوحة',
      two: 'وظيفتان مفتوحتان',
      one: 'وظيفة مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String get companyWebsiteFailed => 'تعذّر فتح الموقع';

  @override
  String get companySeeAllJobs => 'عرض كل الوظائف';

  @override
  String get profilePosts => 'منشور';

  @override
  String companySizeOver(String count) {
    return 'أكثر من $count موظف';
  }

  @override
  String companySizeRange(String from, String to) {
    return 'من $from إلى $to موظف';
  }

  @override
  String get companyNoOpenJobs => 'لا توجد وظائف متاحة حالياً';

  @override
  String get courseTitle => 'الدورة';

  @override
  String get coursesEmpty => 'لا توجد دورات بعد';

  @override
  String get coursesEmptyHint => 'ستظهر هنا الدورات فور نشرها';

  @override
  String get courseLecturesDone => 'المحاضرات';

  @override
  String get courseEnroll => 'التحق بالدورة';

  @override
  String get courseEnrolled => 'تم التحاقك بالدورة';

  @override
  String get courseFinishLecture => 'أنهيت المحاضرة';

  @override
  String get courseProgressSaved => 'تم حفظ تقدّمك';

  @override
  String get courseCompleted => 'أتممت الدورة';

  @override
  String get courseCertificateEarned => 'حصلت على شهادة هذه الدورة';

  @override
  String get notesEmpty => 'لا توجد ملاحظات';

  @override
  String get notesEmptyHint => 'اكتب ملاحظتك الأولى';

  @override
  String get notesNew => 'ملاحظة جديدة';

  @override
  String get notesEdit => 'تعديل الملاحظة';

  @override
  String get notesTitleLabel => 'العنوان';

  @override
  String get notesBodyLabel => 'النص';

  @override
  String get notesUntitled => 'بدون عنوان';

  @override
  String get documentsEmpty => 'لا توجد مراجع بعد';

  @override
  String get documentsEmptyHint => 'ستظهر المراجع فور إضافتها';

  @override
  String get documentNoFile => 'لا يوجد ملف مرفق';

  @override
  String get legalEmpty => 'لا توجد طلبات';

  @override
  String get legalEmptyHint => 'أرسل طلب استشارة وسيصلك الرد هنا';

  @override
  String get legalNewRequest => 'طلب جديد';

  @override
  String get legalSubjectLabel => 'موضوع الطلب';

  @override
  String get legalBodyLabel => 'تفاصيل الطلب';

  @override
  String get legalSubmit => 'إرسال الطلب';

  @override
  String get legalSubmitted => 'تم إرسال طلبك';

  @override
  String get legalResponse => 'الرد';

  @override
  String get legalStatusSubmitted => 'مُرسل';

  @override
  String get legalStatusInReview => 'قيد المراجعة';

  @override
  String get legalStatusAnswered => 'تم الرد';

  @override
  String get legalStatusClosed => 'مغلق';

  @override
  String get assistantHint => 'اكتب سؤالك…';

  @override
  String get assistantStubNotice =>
      'المساعد غير مفعّل بعد — أسئلتك محفوظة وسيصلك الرد فور تفعيل الخدمة.';

  @override
  String courseLectureCount(String count) {
    return '$count محاضرة';
  }

  @override
  String courseLectureOf(String current, String total) {
    return '$current من $total';
  }

  @override
  String get courseLecturesSection => 'المحاضرات';

  @override
  String get courseLecturesEmpty => 'لم تُضف محاضرات لهذه الدورة بعد';

  @override
  String get courseLectureLocked => 'أكمل المحاضرة السابقة أولاً';

  @override
  String get courseLectureNoVideo => 'الفيديو غير متاح بعد';

  @override
  String get courseLecturePreview => 'معاينة مجانية';

  @override
  String get courseLectureMarkedDone => 'تم تحديد المحاضرة كمكتملة';

  @override
  String get coursePlayerError => 'تعذّر تشغيل الفيديو';

  @override
  String courseLectureMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get subscriptionTitle => 'الاشتراك';

  @override
  String get subscriptionLockedTitle => 'هذا القسم متاح للمشتركين';

  @override
  String get subscriptionLockedBody =>
      'اشترك للوصول إلى الدورات والمكتبة الهندسية والشؤون القانونية وأدواتك الشخصية.';

  @override
  String get subscriptionChoosePlan => 'اختر خطة';

  @override
  String get subscriptionSubscribe => 'اشترك الآن';

  @override
  String get subscriptionPlansEmpty => 'لا توجد خطط متاحة حالياً';

  @override
  String get subscriptionCurrent => 'اشتراكك الحالي';

  @override
  String get subscriptionManage => 'إدارة الاشتراك';

  @override
  String get subscriptionStatusPending => 'بانتظار التفعيل';

  @override
  String get subscriptionStatusActive => 'فعّال';

  @override
  String get subscriptionStatusExpired => 'منتهٍ';

  @override
  String get subscriptionStatusCancelled => 'ملغى';

  @override
  String get subscriptionPendingNotice =>
      'تم استلام طلبك. يبدأ اشتراكك فور تأكيد الدفع.';

  @override
  String get subscriptionStarted => 'تم إرسال طلب الاشتراك';

  @override
  String get subscriptionCancelAction => 'إلغاء الاشتراك';

  @override
  String get subscriptionCancelConfirm =>
      'هل تريد إلغاء اشتراكك؟ يبقى الوصول متاحاً حتى نهاية المدة المدفوعة.';

  @override
  String get subscriptionCancelled => 'تم إلغاء اشتراكك';

  @override
  String get subscriptionKeep => 'تراجع';

  @override
  String get subscriptionTrialBadge => 'تجربة مجانية';

  @override
  String subscriptionTrialEndsIn(String days) {
    return 'تنتهي تجربتك المجانية بعد $days يوماً';
  }

  @override
  String subscriptionExpiresIn(String days) {
    return 'ينتهي بعد $days يوماً';
  }

  @override
  String get subscriptionEndsToday => 'ينتهي اليوم';

  @override
  String get billingCycleMonthly => 'شهري';

  @override
  String get billingCycleAnnual => 'سنوي';

  @override
  String get billingPerMonth => 'شهرياً';

  @override
  String get billingPerYear => 'سنوياً';

  @override
  String billingSave(String percent) {
    return 'وفّر $percent%';
  }

  @override
  String get subscriptionCycleUnavailable => 'غير متاح على هذه الباقة';

  @override
  String get subscriptionChangeAction => 'تغيير الباقة';

  @override
  String get subscriptionChangeTitle => 'تغيير الباقة';

  @override
  String get subscriptionChangeConfirm => 'تأكيد التغيير';

  @override
  String get subscriptionChangeDismiss => 'تراجع';

  @override
  String get subscriptionChangeBlocked => 'لا يمكن التغيير إلى هذه الباقة';

  @override
  String get subscriptionChangeFrom => 'من';

  @override
  String get subscriptionChangeTo => 'إلى';

  @override
  String get subscriptionChangePrice => 'السعر';

  @override
  String get subscriptionCurrentPlanBadge => 'باقتك الحالية';

  @override
  String get subscriptionChangeDue => 'المطلوب دفعه';

  @override
  String get subscriptionChangePlanPrice => 'سعر الباقة الجديدة';

  @override
  String get subscriptionChangeCreditAmount => 'محتسب من باقتك الحالية';

  @override
  String get subscriptionChangeNoExtraCost => 'بدون رسوم إضافية';

  @override
  String subscriptionChangeKeepsDate(String days) {
    return 'لا يتغيّر موعد انتهاء اشتراكك — متبقٍ $days يوماً';
  }

  @override
  String get subscriptionChangeImmediateNotice =>
      'يبدأ التغيير فوراً، ويُحتسب الفرق على فاتورتك القادمة.';

  @override
  String get subscriptionChangeDowngradeNotice =>
      'ستفقد مزايا باقتك الحالية فور التأكيد، ولا يوجد استرداد للمبلغ المدفوع.';

  @override
  String get subscriptionChangeDone => 'تم تغيير باقتك';

  @override
  String subscriptionPerDays(String days) {
    return 'لكل $days يوماً';
  }

  @override
  String get courseLevelBeginner => 'مبتدئ';

  @override
  String get courseLevelIntermediate => 'متوسط';

  @override
  String get courseLevelAdvanced => 'متقدم';

  @override
  String get courseFree => 'مجاني';

  @override
  String get courseLockedBadge => 'يتطلب اشتراكاً';

  @override
  String get courseLockedTitle => 'هذه الدورة تتطلب اشتراكاً';

  @override
  String get courseLockedBody =>
      'اشترك لفتح هذا القسم من الدورات. يمكنك مشاهدة المحاضرة الأولى مجاناً قبل ذلك.';

  @override
  String get courseSubscribeToOpen => 'اعرض خطط الاشتراك';

  @override
  String courseHours(String hours) {
    return '$hours ساعة';
  }

  @override
  String courseEnrolledCount(String count) {
    return '$count ملتحق';
  }

  @override
  String get courseNoRatings => 'لا توجد تقييمات بعد';

  @override
  String courseRatingOf(String rating, String count) {
    return '$rating ($count)';
  }

  @override
  String get courseAbout => 'عن الدورة';

  @override
  String get courseOutcomes => 'ما ستتعلمه';

  @override
  String get courseRequirements => 'المتطلبات';

  @override
  String get courseInstructor => 'المدرّب';

  @override
  String get courseRateTitle => 'قيّم هذه الدورة';

  @override
  String get courseRateAction => 'أرسل التقييم';

  @override
  String get courseRated => 'شكراً لتقييمك';

  @override
  String get courseYourRating => 'تقييمك';

  @override
  String get courseRateHint => 'اكتب رأيك (اختياري)';

  @override
  String get lessonKindVideo => 'فيديو';

  @override
  String get lessonKindPdf => 'ملف PDF';

  @override
  String get lessonKindArticle => 'قراءة';

  @override
  String get lessonOpenPdf => 'فتح الملف';

  @override
  String get lessonPdfFailed => 'تعذّر فتح الملف';

  @override
  String get coursesFilterAll => 'الكل';

  @override
  String get coursesFilterFree => 'المتاحة لي';

  @override
  String get planIncludes => 'تشمل الخطة';

  @override
  String get featureTheoryCourses => 'الدورات النظرية';

  @override
  String get featurePracticalCourses => 'الدورات العملية';

  @override
  String get featureTrainingCourses => 'الدورات التدريبية';

  @override
  String get featureLibrary => 'المكتبة الهندسية';

  @override
  String get featureLegalAffairs => 'الشؤون القانونية والاستشارات';

  @override
  String get documentLocked => 'يتطلب اشتراكاً';

  @override
  String subscriptionInvoiceNumber(String number) {
    return 'فاتورة رقم $number';
  }

  @override
  String get subscriptionAutoRenew => 'التجديد التلقائي';

  @override
  String get subscriptionAutoRenewOn =>
      'سيبدأ اشتراك جديد تلقائياً عند انتهاء المدة الحالية.';

  @override
  String get subscriptionAutoRenewOff =>
      'سينتهي اشتراكك عند نهاية المدة الحالية ولن يُجدَّد.';

  @override
  String get subscriptionAutoRenewSaved => 'تم حفظ إعداد التجديد';

  @override
  String get profileFollowing => 'يتابع';

  @override
  String get peopleConnectionsTitle => 'الاتصالات';

  @override
  String get peopleFollowersTitle => 'المتابِعون';

  @override
  String get peopleFollowingTitle => 'المتابَعون';

  @override
  String get peopleRemove => 'إزالة';

  @override
  String get peopleEmpty => 'لا أحد هنا بعد';

  @override
  String peopleRemoveConfirm(String name) {
    return 'إزالة $name من اتصالاتك؟';
  }

  @override
  String peopleUnfollowConfirm(String name) {
    return 'إيقاف متابعة $name؟';
  }

  @override
  String get postSuggestedFollowing => 'تتابعه';

  @override
  String get reelMute => 'كتم';

  @override
  String get reelUnmute => 'تشغيل الصوت';
}
