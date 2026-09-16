// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'رنق';

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
  String get authStatProfessionalsValue => '+١٢ مليون';

  @override
  String get authStatProfessionalsLabel => 'مختص';

  @override
  String get authStatJobsValue => '٢٤٠ ألف';

  @override
  String get authStatJobsLabel => 'وظيفة شاغرة';

  @override
  String get authStatTrustValue => '٩٨٪';

  @override
  String get authStatTrustLabel => 'درجة الثقة';

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
      'بمتابعتك فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة برنق';

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
  String get navNetwork => 'شبكتي';

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
  String get networkTitle => 'شبكتي';

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
  String get searchHint => 'ابحث في رنق';

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
  String get authUserName => 'اسم المستخدم';

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
  String get authPasswordTooShort => 'كلمة المرور ٦ أحرف على الأقل';

  @override
  String get authUserNameTooShort => 'اسم المستخدم ٣ أحرف على الأقل';

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
    return 'وفّر $percent٪';
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
  String get coursesFilterFree => 'المجانية';

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
}
