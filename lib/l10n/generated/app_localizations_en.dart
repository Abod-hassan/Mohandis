// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mohandis';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDone => 'Done';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSend => 'Send';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionIgnore => 'Ignore';

  @override
  String get actionChange => 'Change';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get optionalSuffix => '(optional)';

  @override
  String get applyResumeReplace => 'Tap to replace';

  @override
  String get applyResumeRequired => 'Attach your CV before applying';

  @override
  String get requiredSuffix => '(required)';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get themeToggleToDark => 'Switch to dark theme';

  @override
  String get themeToggleToLight => 'Switch to light theme';

  @override
  String get authHeroTitle => 'Where professional paths meet.';

  @override
  String get authHeroBody =>
      'Build your professional profile, grow your network, share your work, and find your next role — all in one calm, professional place.';

  @override
  String get authGetStarted => 'Get started';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authContinueWith => 'or continue with';

  @override
  String get authGoogle => 'Google';

  @override
  String get authApple => 'Apple';

  @override
  String get authTerms =>
      'By continuing you agree to Rung\'s Terms of Use and Privacy Policy';

  @override
  String authWelcomeBack(String name) {
    return 'Welcome back, $name 👋';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navReels => 'Reels';

  @override
  String get navDashboard => 'My panel';

  @override
  String get navJobs => 'Jobs';

  @override
  String get navNetwork => 'Network';

  @override
  String get topBarSearchHint => 'Search people, jobs, or tags';

  @override
  String get feedYourStory => 'Your story';

  @override
  String get feedComposerHint => 'Share an update or idea…';

  @override
  String get feedCaughtUp => 'You\'re all caught up ✓';

  @override
  String feedRepostedBy(String name) {
    return '$name reposted';
  }

  @override
  String get postActionLike => 'Like';

  @override
  String get postActionComment => 'Comment';

  @override
  String get postActionRepost => 'Repost';

  @override
  String get postActionSave => 'Save';

  @override
  String postCommentsCount(String count) {
    return '$count comments';
  }

  @override
  String postRepostsCount(String count) {
    return '$count reposts';
  }

  @override
  String postLikesCount(String count) {
    return '$count likes';
  }

  @override
  String get postViewJob => 'View job and apply →';

  @override
  String get postDetailTitle => 'Post';

  @override
  String get postAddComment => 'Add a comment…';

  @override
  String get postReply => 'Reply';

  @override
  String postLikeWithCount(String count) {
    return 'Like · $count';
  }

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityFollowers => 'Followers';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get visibilityEveryoneLabel => 'Everyone';

  @override
  String get visibilityFollowersOnlyLabel => 'Followers only';

  @override
  String get visibilityOnlyMeLabel => 'Only me';

  @override
  String get composerTitle => 'New post';

  @override
  String get composerPublish => 'Post';

  @override
  String get composerHint => 'Share an update, an idea, or an opportunity…';

  @override
  String get toastSavedToItems => 'Saved to your items';

  @override
  String get toastReposted => 'Reposted to your followers';

  @override
  String get toastPosted => 'Post published ✓';

  @override
  String get toastSavedToReels => 'Saved to your reels';

  @override
  String get toastProfileUpdated => 'Profile updated ✓';

  @override
  String get toastApplicationSent => 'Application sent ✓';

  @override
  String toastConnectRequestSent(String name) {
    return 'Connection request sent to $name';
  }

  @override
  String toastConnected(String name) {
    return 'Connected with $name';
  }

  @override
  String toastFollowing(String name) {
    return 'Now following $name';
  }

  @override
  String get toastUnfollowed => 'Unfollowed';

  @override
  String storyReplyTo(String name) {
    return 'Reply to $name…';
  }

  @override
  String storyPostedAgo(String time) {
    return '$time ago';
  }

  @override
  String get reelsTitle => 'Reels';

  @override
  String get reelFollow => 'Follow';

  @override
  String get reelShare => 'Share';

  @override
  String reelPlays(String count) {
    return '$count views';
  }

  @override
  String get profileOpenToWork => 'Open to work';

  @override
  String get profileHiring => 'Hiring';

  @override
  String get profileConnections => 'connections';

  @override
  String get profileFollowers => 'followers';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileFollow => 'Follow';

  @override
  String get profileUnfollow => 'Unfollow';

  @override
  String get profileConnect => 'Connect';

  @override
  String get profileAbout => 'About';

  @override
  String get profileDownloadCv => 'Download résumé';

  @override
  String get profileExperience => 'Experience';

  @override
  String get profileEducation => 'Education';

  @override
  String get profileSkills => 'Skills';

  @override
  String profileEndorsements(String count) {
    return '$count endorsements';
  }

  @override
  String get profileEndorse => '+ Endorse';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileFullName => 'Full name';

  @override
  String get editProfileHeadline => 'Headline';

  @override
  String get editProfileIndustry => 'Industry';

  @override
  String get editProfileLocation => 'Location';

  @override
  String get editProfileAbout => 'About';

  @override
  String get editProfileOpenToWorkTitle => 'Open to work';

  @override
  String get editProfileOpenToWorkSubtitle =>
      'Show recruiters that you\'re available';

  @override
  String get editProfilePrivateTitle => 'Private profile';

  @override
  String get editProfilePrivateSubtitle =>
      'Approve followers before they see your posts';

  @override
  String get networkTitle => 'My network';

  @override
  String get networkRequests => 'Connection requests';

  @override
  String get networkSuggestions => 'People you may know';

  @override
  String networkMutual(String count) {
    return '$count mutual connections';
  }

  @override
  String get networkAdd => '+ Connect';

  @override
  String get searchHint => 'Search Rung';

  @override
  String get searchTabTop => 'Top';

  @override
  String get searchTabPeople => 'People';

  @override
  String get searchTabJobs => 'Jobs';

  @override
  String get searchTabTags => 'Tags';

  @override
  String get searchTrendingTags => 'Trending tags';

  @override
  String get searchSectionPeople => 'People';

  @override
  String get searchNoResults => 'No results match your search';

  @override
  String searchPostsCount(String count) {
    return '$count posts';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsNowConnected => 'is now connected with you';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesSearchHint => 'Search messages';

  @override
  String get messagesYouPrefix => 'You: ';

  @override
  String threadMembers(String count) {
    return '$count members';
  }

  @override
  String get threadInputHint => 'Write a message…';

  @override
  String get threadToday => 'Today';

  @override
  String get threadRead => 'Read';

  @override
  String get threadJustNow => 'Now';

  @override
  String get jobsTitle => 'Jobs';

  @override
  String get jobsMyApplications => 'My applications';

  @override
  String get jobsSearchHint => 'Title, company, or location';

  @override
  String get jobsFilterAll => 'All';

  @override
  String get jobsFilterRemote => 'Remote';

  @override
  String get jobsFilterHybrid => 'Hybrid';

  @override
  String get jobsFilterOnsite => 'On-site';

  @override
  String get jobsEmpty => 'No jobs match these filters';

  @override
  String jobPostedAgo(String time) {
    return '$time ago';
  }

  @override
  String jobApplicants(String count) {
    return '$count applicants';
  }

  @override
  String get jobApplied => 'Applied';

  @override
  String get jobDetailTitle => 'Job details';

  @override
  String get jobSalaryRange => 'Salary range';

  @override
  String get jobAboutSection => 'About the role';

  @override
  String get jobRequirementsSection => 'What we\'re looking for';

  @override
  String get jobSkillsSection => 'Skills';

  @override
  String get jobApplyNow => 'Apply now';

  @override
  String jobApplicationStatus(String status) {
    return 'Application: $status';
  }

  @override
  String get applyTitle => 'Apply';

  @override
  String get applyResumeSection => 'Your résumé';

  @override
  String applyResumeUploaded(String size) {
    return 'Uploaded · $size';
  }

  @override
  String get applyCoverLetterSection => 'Cover letter';

  @override
  String get applyCoverHint => 'Add a note for the hiring team…';

  @override
  String get applyReviewSection => 'Review and submit';

  @override
  String get applyApplicantLabel => 'Applicant';

  @override
  String get applyResumeLabel => 'Résumé';

  @override
  String get applyNoCoverLetter => 'No cover letter added.';

  @override
  String get applySubmit => 'Submit application';

  @override
  String get applyDoneTitle => 'Your application is in!';

  @override
  String applyDoneBody(String title, String company) {
    return 'Your application for $title at $company has been sent. Track its status from My applications.';
  }

  @override
  String get myApplicationsTitle => 'My applications';

  @override
  String get myApplicationsEmpty => 'You haven\'t applied to any job yet';

  @override
  String get applicationStepSubmitted => 'Submitted';

  @override
  String get applicationStepReview => 'Reviewed';

  @override
  String get applicationStepShortlist => 'Shortlisted';

  @override
  String get applicationStepInterview => 'Interview';

  @override
  String get applicationStepDecision => 'Decision';

  @override
  String get applicationStatusSubmitted => 'Submitted';

  @override
  String get applicationStatusInReview => 'In review';

  @override
  String get applicationStatusShortlisted => 'Shortlisted';

  @override
  String get applicationStatusInterview => 'Interview';

  @override
  String get applicationStatusAccepted => 'Accepted';

  @override
  String get applicationStatusRejected => 'Rejected';

  @override
  String get dashboardGreeting => 'Good evening';

  @override
  String get dashboardContinueLearning => 'Continue learning';

  @override
  String dashboardLectureProgress(String current, String total) {
    return 'Lecture $current of $total · theory';
  }

  @override
  String get dashboardStatCourses => 'active courses';

  @override
  String get dashboardStatHours => 'learning hours';

  @override
  String get dashboardStatCertificates => 'certificates';

  @override
  String get dashboardSectionLearning => 'Learning';

  @override
  String get dashboardSectionServices => 'Services';

  @override
  String get dashboardSectionTools => 'My tools';

  @override
  String dashboardNewBadge(String count) {
    return '$count new';
  }

  @override
  String get dashboardTheory => 'Theory lectures';

  @override
  String get dashboardTheorySubtitle => 'Core lessons and concepts';

  @override
  String get dashboardPractical => 'Practical lectures';

  @override
  String get dashboardPracticalSubtitle => 'Applications and worked examples';

  @override
  String get dashboardTraining => 'Training and development';

  @override
  String get dashboardTrainingSubtitle => 'Skill-development programmes';

  @override
  String get dashboardEngy => 'Engineer Engy';

  @override
  String get dashboardEngySubtitle => 'Your smart consulting assistant';

  @override
  String get dashboardEngyBadge => 'AI';

  @override
  String get dashboardLegalRequest => 'Request legal advice';

  @override
  String get dashboardLegalRequestSubtitle =>
      'Steps for resolving legal disputes';

  @override
  String get dashboardLegalAffairs => 'Legal affairs';

  @override
  String get dashboardLegalAffairsSubtitle =>
      'Engineers\' rights and regulations';

  @override
  String get dashboardNotes => 'My notes';

  @override
  String get dashboardNotesSubtitle => 'Your personal notes';

  @override
  String get dashboardLibrary => 'Engineering library';

  @override
  String get dashboardLibrarySubtitle =>
      'References, codes, and specifications';

  @override
  String dashboardOpening(String item) {
    return 'Opening $item';
  }

  @override
  String get dashboardEngyGreeting => 'Hi, I\'m Engy — how can I help?';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create an account';

  @override
  String get authUserName => 'Username';

  @override
  String get authUserNameHint => 'Latin letters or numbers';

  @override
  String get authPassword => 'Password';

  @override
  String get authFullName => 'Full name';

  @override
  String get authFullNameHint => 'As it should appear on your profile';

  @override
  String get authCompanyName => 'Company name';

  @override
  String get authCompanyNameHint => 'As it should appear on your company page';

  @override
  String get authPhone => 'Phone number';

  @override
  String get authAccountType => 'Account type';

  @override
  String get authAccountIndividual => 'Individual';

  @override
  String get authAccountCompany => 'Company';

  @override
  String get authSubmitSignIn => 'Sign in';

  @override
  String get authSubmitSignUp => 'Create account';

  @override
  String get authSwitchToSignUp => 'No account yet? Create one';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authRequiredField => 'This field is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authUserNameTooShort => 'Username must be at least 3 characters';

  @override
  String get authChecking => 'Checking…';

  @override
  String get authAvailable => 'Available';

  @override
  String get authUserNameTaken => 'That username is taken';

  @override
  String get authPhoneTaken => 'That number already has an account';

  @override
  String get authPhoneHint => '7701234567';

  @override
  String get authSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get authPasswordWeak =>
      'Add a digit, an uppercase and a lowercase letter';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailOptional => 'Email (optional)';

  @override
  String get authEmailHint => 'name@example.com';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authEmailTaken => 'That email already has an account';

  @override
  String get authVerifyTitle => 'Confirm your phone';

  @override
  String get authVerifyNoDraft =>
      'That sign-up session has ended. Start again.';

  @override
  String get authVerifyRestart => 'Start again';

  @override
  String get authVerifyEmailLater =>
      'You can confirm your email after your account is created, to turn on two-step verification.';

  @override
  String get authVerifyCodeTitle => 'Enter your code';

  @override
  String get authVerifyResend => 'Resend';

  @override
  String get authVerifyConfirm => 'Confirm';

  @override
  String get authVerifyNoCode => 'Didn\'t get the code?';

  @override
  String get authVerifySentTo => 'We sent a 6-digit code to';

  @override
  String get authPhoneInvalid => 'Enter a valid phone number';

  @override
  String authAccountCreated(String name) {
    return 'Account created — welcome, $name 🎉';
  }

  @override
  String get setupTitle => 'Complete your profile';

  @override
  String get setupSubtitle =>
      'Introduce yourself — you can change any of this later.';

  @override
  String get setupSubtitleCompany =>
      'Introduce your company — you can change any of this later.';

  @override
  String get setupHeadline => 'Headline';

  @override
  String get setupHeadlineHint => 'Software engineer at…';

  @override
  String get setupHeadlineHintCompany => 'What does your company do?';

  @override
  String get setupAbout => 'About';

  @override
  String get setupAboutHint =>
      'A few lines about your experience and interests';

  @override
  String get setupAboutHintCompany => 'A few lines about what the company does';

  @override
  String get setupLocation => 'Location';

  @override
  String get setupLocationHint => 'Baghdad, Iraq';

  @override
  String get setupIndustry => 'Industry';

  @override
  String get setupIndustryHint => 'Technology, engineering, healthcare…';

  @override
  String get setupWebsite => 'Website';

  @override
  String get setupOpenToWork => 'Open to work';

  @override
  String get setupOpenToWorkSubtitle => 'Shows a badge on your profile';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotIntro =>
      'Pick where to receive the code, then set a new password.';

  @override
  String get forgotSend => 'Send code';

  @override
  String get forgotNoAccountPhone =>
      'No account uses that number. Check it, or create an account.';

  @override
  String get forgotNoAccountEmail =>
      'No confirmed account uses that address. Try your phone number.';

  @override
  String get forgotChangeTarget => 'Change number or email';

  @override
  String get forgotLeaveTitle => 'Cancel the password reset?';

  @override
  String get forgotLeaveBody =>
      'Your password will not change and you will be signed out. You will need a new code to try again.';

  @override
  String get forgotLeaveConfirm => 'Cancel reset';

  @override
  String get forgotSetTitle => 'New password';

  @override
  String get forgotSetSubtitle => 'Pick one you do not use anywhere else.';

  @override
  String get forgotNewPassword => 'New password';

  @override
  String get forgotConfirmPassword => 'Confirm password';

  @override
  String get forgotPasswordMismatch => 'The passwords do not match';

  @override
  String get forgotSave => 'Save password';

  @override
  String get forgotDone => 'Your password has been changed';

  @override
  String get setupCareerTitle => 'Your career';

  @override
  String get setupCv => 'CV / resume';

  @override
  String get setupCvOnFile => 'Attached';

  @override
  String get notificationsFollowApproved => 'You approved this follow request';

  @override
  String get notificationsRequestHandled => 'This request was already handled';

  @override
  String toastFollowApproved(String name) {
    return '$name now follows you';
  }

  @override
  String get activityFollowRequested => 'asked to follow you';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivateAccount => 'Private account';

  @override
  String get settingsPrivateAccountOn =>
      'Only your followers see your posts, and you approve each new follower';

  @override
  String get settingsPrivateAccountOff =>
      'Anyone can see your posts and follow you';

  @override
  String get profilePrivateTitle => 'This account is private';

  @override
  String get profilePrivateBody => 'Follow this account to see its posts';

  @override
  String get profilePrivateRequested =>
      'Follow request sent. Posts appear once it is approved';

  @override
  String postReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get postCancelReply => 'Cancel reply';

  @override
  String get postWriteReply => 'Write a reply…';

  @override
  String get subscriptionApprovedToast =>
      'Your subscription was approved and is now active';

  @override
  String get feedRankingTitle => 'Feed ranking';

  @override
  String get feedRankingSaved => 'Ranking settings saved';

  @override
  String get feedRankingIntro =>
      'These weights decide how the home feed is ordered for everyone. They are relative — only their ratios matter. Changes apply to pages loaded after saving.';

  @override
  String get feedRankingWeights => 'Weights';

  @override
  String get feedRankingAdvanced => 'Advanced';

  @override
  String get feedRankingAffinity => 'Author affinity';

  @override
  String get feedRankingAffinityHint =>
      'How much the viewer engages with this author. Higher feels more personal.';

  @override
  String get feedRankingRecency => 'Recency';

  @override
  String get feedRankingRecencyHint => 'Preference for newer posts.';

  @override
  String get feedRankingEngagement => 'Engagement';

  @override
  String get feedRankingEngagementHint =>
      'Likes, comments and shares relative to the post\'s age.';

  @override
  String get feedRankingUnseen => 'Unseen bonus';

  @override
  String get feedRankingUnseenHint =>
      'Lift for posts the viewer hasn\'t seen yet.';

  @override
  String get feedRankingRepeat => 'Author repeat penalty';

  @override
  String get feedRankingRepeatHint =>
      'Discount for each extra post by the same author on a page, so one author can\'t take it over.';

  @override
  String get feedRankingHalfLife => 'Recency half-life';

  @override
  String get feedRankingHalfLifeHint =>
      'After this long, recency counts half. Short values feel more chronological.';

  @override
  String get feedRankingOverfetch => 'Candidates per slot';

  @override
  String get feedRankingOverfetchHint =>
      'How many posts are fetched per page slot before ranking. Higher is better but slower and costlier.';

  @override
  String get feedRankingTtl => 'Feed row lifetime';

  @override
  String get feedRankingTtlHint =>
      'After this, unread rows expire from a viewer\'s feed. Zero keeps them forever.';

  @override
  String get feedRankingTtlForever => 'Forever';

  @override
  String feedRankingHours(int count) {
    return '$count h';
  }

  @override
  String feedRankingDays(int count) {
    return '$count days';
  }

  @override
  String get feedRankingReset => 'Restore defaults';

  @override
  String get settingsAdmin => 'Administration';

  @override
  String get panelAccessTitle => 'Dashboard access';

  @override
  String get panelAccessIntro =>
      'Decide whether the engineer dashboard needs a subscription, and which of its sections are open to everyone. Changes apply to all users immediately.';

  @override
  String get panelAccessGateSection => 'Subscription';

  @override
  String get panelAccessGate => 'Require a subscription';

  @override
  String get panelAccessGateOn =>
      'The dashboard is for subscribers only, apart from the free sections below.';

  @override
  String get panelAccessGateOff => 'The whole dashboard is open to everyone.';

  @override
  String get panelAccessTrial => 'Trial length';

  @override
  String get panelAccessTrialHint =>
      'Days a new account gets the whole dashboard, counted from when it was created.';

  @override
  String get panelAccessTrialNone => 'No trial';

  @override
  String panelAccessDays(String count) {
    return '$count days';
  }

  @override
  String get panelAccessSections => 'Sections';

  @override
  String get panelAccessSectionsHint =>
      'A section switched on here is open to everyone with no subscription; the rest need one.';

  @override
  String get panelAccessSectionsIgnored =>
      'These have no effect while the whole dashboard is open to everyone.';

  @override
  String get panelAccessSectionFree => 'Open without a subscription';

  @override
  String get panelAccessSectionPaid => 'Needs a subscription';

  @override
  String get panelAccessSaved => 'Dashboard access saved';

  @override
  String get dashboardSectionLocked =>
      'Needs a subscription — tap to subscribe';

  @override
  String get panelAccessLibraryLive => 'Library is live';

  @override
  String get panelAccessLibraryLiveHint =>
      'While off, the library shows as \"coming soon\" on the panel and cannot be opened, whatever the subscription settings say.';

  @override
  String get disciplinesTitle => 'Engineering disciplines';

  @override
  String get disciplinesIntro =>
      'The disciplines engineers pick from on their profile. Tap a logo to upload an image, and the switch to withdraw one without deleting it — whoever chose it keeps it.';

  @override
  String get disciplineAdd => 'Add a discipline';

  @override
  String get disciplineRename => 'Rename';

  @override
  String get disciplineSetLogo => 'Upload a logo';

  @override
  String get disciplineClearLogo => 'Remove the logo';

  @override
  String get disciplineNameTitle => 'Discipline name';

  @override
  String get disciplineNameAr => 'Arabic name';

  @override
  String get disciplineNameEn => 'English name';

  @override
  String get disciplineLogoHint => 'Tap the square to upload a logo';

  @override
  String get disciplineLogoNoStorage =>
      'Image uploads are not configured on this server';

  @override
  String get disciplinePickerTitle => 'Choose your discipline';

  @override
  String get disciplinePickerHint => 'Choose your discipline';

  @override
  String get disciplinePickerSearch => 'Search disciplines…';

  @override
  String get disciplinePickerClear => 'No discipline';

  @override
  String get disciplinePickerFailed =>
      'Couldn\'t load the list of disciplines.';

  @override
  String get setupDiscipline => 'Discipline';

  @override
  String get setupDisciplineHint => 'Choose your engineering discipline';

  @override
  String get editProfileDiscipline => 'Discipline';

  @override
  String get governoratePickerTitle => 'Choose a governorate';

  @override
  String get governoratePickerHint => 'Choose a governorate';

  @override
  String get governoratePickerSearch => 'Search governorates…';

  @override
  String get governoratePickerClear => 'No governorate';

  @override
  String get governoratePickerFailed =>
      'Couldn\'t load the list of governorates.';

  @override
  String get setupGovernorate => 'Governorate';

  @override
  String get setupGovernorateHint => 'Choose your governorate';

  @override
  String get editProfileGovernorate => 'Governorate';

  @override
  String get profileTabPosts => 'Posts';

  @override
  String get profileTabReels => 'Reels';

  @override
  String get profileTabCv => 'Experience';

  @override
  String get profileNoPosts => 'No posts yet.';

  @override
  String get profileNoReels => 'No reels yet.';

  @override
  String get profileMessage => 'Message';

  @override
  String get profileNoCv => 'No CV has been uploaded.';

  @override
  String get profileCvFailed => 'Couldn\'t open the CV.';

  @override
  String get activityFollowAccepted => 'accepted your follow request';

  @override
  String get postOptionsTitle => 'Post options';

  @override
  String get postOptionsEdit => 'Edit post';

  @override
  String get postOptionsDelete => 'Delete post';

  @override
  String get postOptionsReport => 'Report post';

  @override
  String get postOptionsSave => 'Save post';

  @override
  String get postOptionsUnsave => 'Remove from saved';

  @override
  String get postDeleteConfirm => 'Delete this post permanently?';

  @override
  String get postDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get toastPostDeleted => 'Post deleted';

  @override
  String get postEditTitle => 'Edit post';

  @override
  String get postEditHint => 'Write something…';

  @override
  String get postEditEmpty => 'A post cannot be empty';

  @override
  String get toastPostUpdated => 'Post updated';

  @override
  String get postReportTitle => 'Reason for reporting';

  @override
  String get postReportDetailsHint => 'More details (optional)';

  @override
  String get postReportSend => 'Send report';

  @override
  String get toastPostReported => 'Thanks — your report was sent';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonHateSpeech => 'Hate speech';

  @override
  String get reportReasonViolence => 'Violence';

  @override
  String get reportReasonNudity => 'Nudity or sexual content';

  @override
  String get reportReasonMisinformation => 'Misinformation';

  @override
  String get reportReasonSelfHarm => 'Self-harm';

  @override
  String get reportReasonImpersonation => 'Impersonation';

  @override
  String get reportReasonIntellectualProperty => 'Intellectual property';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get companyApplicantOpenCv => 'View CV';

  @override
  String get companyApplicantNoCv => 'No CV attached';

  @override
  String get companyApplicantCvFailed => 'Could not open the file';

  @override
  String get companyApplicantNotes => 'Applicant\'s notes';

  @override
  String get companyApplicantNoNotes => 'The applicant wrote no notes';

  @override
  String get companyApplicantDetails => 'View details';

  @override
  String get companyApplicantProfile => 'Profile';

  @override
  String get companyDashboardTitle => 'Company dashboard';

  @override
  String get companyStatOpenJobs => 'Open jobs';

  @override
  String get companyStatApplicants => 'Total applicants';

  @override
  String get companyStatNewThisWeek => 'New this week';

  @override
  String get companyStatFollowers => 'Page followers';

  @override
  String get companyPendingTitle => 'Waiting on you';

  @override
  String get companyPendingEmpty => 'Nothing is waiting on a decision';

  @override
  String get companyPendingAll => 'All applicants';

  @override
  String get companyOpenJobsTitle => 'Your open jobs';

  @override
  String get companyOpenJobsEmpty => 'No open jobs right now';

  @override
  String companyJobApplicants(String count) {
    return 'Applicants: $count';
  }

  @override
  String companyClosedJobs(String count) {
    return 'Closed jobs: $count';
  }

  @override
  String companyDashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get companyQuickActions => 'Quick actions';

  @override
  String get companyEditPage => 'Edit page';

  @override
  String get jobApplyLocked => 'Applying is for subscribers';

  @override
  String get jobApplyLockedBody => 'Subscribe to apply for jobs';

  @override
  String get authAccountEngineer => 'Engineer';

  @override
  String get authAccountContractor => 'Contractor';

  @override
  String get authAccountCraftsman => 'Craftsman';

  @override
  String get authAccountEquipmentOwner => 'Machinery owner';

  @override
  String get authBusinessName => 'Business name';

  @override
  String get authBusinessNameHint => 'As it should appear on your page';

  @override
  String get profileTradeLabel => 'Trade';

  @override
  String get profileEquipmentLabel => 'Machinery type';

  @override
  String get authAccountTypeSheetTitle => 'Choose account type';

  @override
  String get authAccountEngineerHint =>
      'A personal account: apply to jobs and build your profile.';

  @override
  String get authAccountCompanyHint => 'Post jobs and receive applications.';

  @override
  String get authAccountContractorHint =>
      'Deliver projects and post work opportunities.';

  @override
  String get authAccountCraftsmanHint =>
      'A trade: carpenter, blacksmith, electrician and the rest.';

  @override
  String get authAccountEquipmentOwnerHint =>
      'Rent out machinery and equipment, and post work.';

  @override
  String get myCoursesTitle => 'My courses';

  @override
  String get myCoursesEmpty =>
      'You haven\'t created a course yet. Start one and send it for review.';

  @override
  String get myCoursesNew => 'New course';

  @override
  String get myCoursesEarnings => 'My earnings';

  @override
  String get courseStatusDraft => 'Draft';

  @override
  String get courseStatusSubmitted => 'In review';

  @override
  String get courseStatusRejected => 'Sent back';

  @override
  String get courseStatusApproved => 'Published';

  @override
  String get courseEditorEdit => 'Edit course';

  @override
  String get courseFieldTitle => 'Course title';

  @override
  String get courseFieldSummary => 'Short summary';

  @override
  String get courseFieldDescription => 'Full description';

  @override
  String get courseFieldCategory => 'Section';

  @override
  String get courseFieldLevel => 'Level';

  @override
  String get courseFieldPrice => 'Price';

  @override
  String get courseFieldPriceHint => 'Leave at zero to give the course away';

  @override
  String get courseAddLine => 'Add a line';

  @override
  String get courseLessons => 'Lessons';

  @override
  String get courseAddLesson => 'Add a lesson';

  @override
  String get courseLessonTitle => 'Lesson title';

  @override
  String get courseLessonKind => 'Lesson type';

  @override
  String get courseLessonDuration => 'Length in minutes';

  @override
  String get courseLessonPreview => 'Free preview lesson';

  @override
  String get courseLessonBody => 'Lesson text';

  @override
  String get courseLessonDelete => 'Delete lesson';

  @override
  String get courseSubmitForReview => 'Send for review';

  @override
  String get courseSubmittedToast => 'Course sent for review';

  @override
  String get courseSavedToast => 'Course saved';

  @override
  String get courseReviewNote => 'Reviewer\'s note';

  @override
  String get courseLockedUntilReview =>
      'This course is with the reviewer and can\'t be edited until a decision comes back.';

  @override
  String get courseLockedApproved =>
      'This course is published and can no longer be edited.';

  @override
  String get courseBuy => 'Buy this course';

  @override
  String get coursePurchasePending => 'Awaiting payment confirmation';

  @override
  String get coursePurchasePaid => 'Purchased';

  @override
  String get coursePurchaseAsked =>
      'Purchase requested. The course opens as soon as payment is confirmed.';

  @override
  String courseSubscriberDiscount(String percent) {
    return '$percent% subscriber discount';
  }

  @override
  String get courseReviewTitle => 'Course review';

  @override
  String get courseReviewEmpty => 'No courses are waiting for review.';

  @override
  String get courseApprove => 'Approve';

  @override
  String get courseReject => 'Send back';

  @override
  String get coursePlatformPercent => 'Platform share %';

  @override
  String get coursePlatformPercentHint =>
      'Taken from what the learner actually pays, and fixed on every purchase of this course.';

  @override
  String get courseRejectReason => 'Reason';

  @override
  String get courseApprovedToast => 'Approved and published';

  @override
  String get courseRejectedToast => 'Sent back to the author';

  @override
  String get courseAuthorLabel => 'Author';

  @override
  String get courseCommerceTitle => 'Course pricing';

  @override
  String get courseCommerceIntro =>
      'Two numbers that apply to every course: the commission suggested at review, and the discount subscribers get.';

  @override
  String get courseCommissionDefault => 'Default platform share %';

  @override
  String get courseCommissionDefaultHint =>
      'A suggestion only. The binding rate is the one fixed on each course at approval.';

  @override
  String get courseDiscountPercent => 'Subscriber discount on courses %';

  @override
  String get courseDiscountPercentHint =>
      'Comes off every paid course for anyone with an active plan. Zero turns it off.';

  @override
  String get courseCommerceSaved => 'Pricing saved';

  @override
  String get coursePurchasesTitle => 'Course purchases';

  @override
  String get coursePurchasesEmpty => 'No purchase requests.';

  @override
  String get purchaseConfirm => 'Confirm payment';

  @override
  String get purchaseCancelRequest => 'Turn down';

  @override
  String get purchaseAmountDue => 'Amount';

  @override
  String get purchasePlatformShare => 'Platform share';

  @override
  String get purchaseAuthorShare => 'Author share';

  @override
  String get purchaseConfirmedToast => 'Payment confirmed';

  @override
  String get purchaseCancelledToast => 'Request turned down';

  @override
  String get purchaseNote => 'Note';

  @override
  String get courseEarningsEmpty => 'None of your courses have sold yet.';

  @override
  String get dashboardTeach => 'Teach a course';

  @override
  String get dashboardTeachSubtitle =>
      'Create a course, price it, and send it for review';

  @override
  String get courseCoverLabel => 'Cover image';

  @override
  String get courseCoverAdd => 'Add a cover image';

  @override
  String get courseCoverHint => 'Shown on the course card in the catalogue';

  @override
  String get courseCoverChange => 'Change image';

  @override
  String get courseCoverRemove => 'Remove image';

  @override
  String get courseLessonFile => 'Lesson file';

  @override
  String get courseLessonPickVideo => 'Choose a video';

  @override
  String get courseLessonPickPdf => 'Choose a PDF';

  @override
  String get courseLessonFileReady => 'File uploaded';

  @override
  String get courseLessonFileMissing => 'No file uploaded yet';

  @override
  String courseUploading(String percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get courseLessonsAutoSave =>
      'The course is saved automatically when you add the first lesson.';

  @override
  String get courseNewTag => 'New';

  @override
  String get profileBannerAdd => 'Add a cover photo';

  @override
  String get profileBannerChange => 'Change cover photo';

  @override
  String get profileBannerRemove => 'Remove cover photo';

  @override
  String get profileBannerSaved => 'Cover photo updated';

  @override
  String get composerReelsStreamOff =>
      'Reel publishing is unavailable on this server right now';

  @override
  String get courseLessonStreamOff =>
      'Lesson video upload is unavailable on this server right now';

  @override
  String get uploadBannerUploading => 'Uploading video';

  @override
  String get uploadBannerFinishing => 'Publishing…';

  @override
  String get uploadBannerDone => 'Uploaded and published';

  @override
  String get uploadBannerFailed => 'Upload failed';

  @override
  String get uploadBannerBusy =>
      'A video is already uploading — wait for it to finish';

  @override
  String get uploadLeaveTitle => 'Upload not finished';

  @override
  String get uploadLeaveBody =>
      'Closing the app now will cancel the video upload. Leave anyway?';

  @override
  String get uploadLeaveStay => 'Stay';

  @override
  String get uploadLeaveQuit => 'Leave';

  @override
  String get uploadStartedBackground =>
      'The upload will continue in the background';

  @override
  String get uploadBannerCancel => 'Cancel';

  @override
  String get uploadBannerCancelled => 'Upload cancelled';

  @override
  String get courseSaveAndAddLessons => 'Save and add lessons';

  @override
  String get courseLessonsTitle => 'Course lessons';

  @override
  String get courseLessonsEmpty =>
      'No lessons yet. Add the first one to get started.';

  @override
  String get courseLessonsNextStep => 'Course saved. Now add its lessons.';

  @override
  String get courseLessonUploadingChip => 'Uploading';

  @override
  String get courseLessonUploadIncomplete =>
      'Upload did not finish — tap to try again';

  @override
  String get courseLessonUploadQueued => 'Waiting to upload';

  @override
  String get courseLessonServerOutdated =>
      'This server cannot save a lesson before its file finishes uploading. Restart the API after its latest build.';

  @override
  String get toastReelReposted => 'Reel reposted to your followers';

  @override
  String get toastReelUnreposted => 'Repost removed';

  @override
  String get postOriginalUnavailable =>
      'The original post is no longer available.';

  @override
  String get cropAvatarTitle => 'Crop profile photo';

  @override
  String get cropBannerTitle => 'Crop cover photo';

  @override
  String get cropDone => 'Done';

  @override
  String get cropCancel => 'Cancel';

  @override
  String get reelOptions => 'Reel options';

  @override
  String get reelDelete => 'Delete reel';

  @override
  String get reelUndoRepost => 'Undo repost';

  @override
  String get reelDeleteConfirm => 'Delete this reel permanently?';

  @override
  String get reelDeleteConfirmBody =>
      'It will disappear from your profile and from everyone who reposted it. This can\'t be undone.';

  @override
  String get toastReelDeleted => 'Reel deleted';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsAbout => 'About';

  @override
  String get legalLinkFailed =>
      'Couldn\'t open the page. Check your connection and try again.';

  @override
  String get authTermsLead => 'By continuing you agree to the ';

  @override
  String get authTermsPrivacy => 'Privacy Policy';

  @override
  String get authTermsTail => ' of Mohandis';

  @override
  String get authGenderOptional => 'Gender (optional)';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account permanently?';

  @override
  String get deleteAccountBody =>
      'Your profile, posts, reels, comments and follows will be deleted, and you won\'t be able to sign in to this account again. This can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get toastAccountDeleted => 'Your account was deleted';

  @override
  String get authPhoneOrEmailHint =>
      'Enter your phone number or your email, either one is enough. We\'ll send a confirmation code to it.';

  @override
  String get authPhoneOrEmailRequired => 'Enter a phone number or an email';

  @override
  String get reportProfile => 'Report account';

  @override
  String get reportReel => 'Report reel';

  @override
  String get reportComment => 'Report comment';

  @override
  String get reportMessage => 'Report message';

  @override
  String get reportStory => 'Report story';

  @override
  String get actionReport => 'Report';

  @override
  String get authTermsLink => 'Terms of Use';

  @override
  String get authTermsAnd => ' and ';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get hashtagPostsEmpty => 'No posts with this hashtag yet';

  @override
  String get storyReplyHint => 'Send a reply…';

  @override
  String get storyReplySend => 'Send';

  @override
  String get storyReplySent => 'Reply sent to messages';

  @override
  String get storyReplyFailed => 'Couldn\'t send the reply, try again';

  @override
  String get storyLike => 'Like';

  @override
  String get storyLikeFailed => 'Couldn\'t save the like';

  @override
  String get activityLikedStory => 'liked your story';

  @override
  String get activityCommentedReel => 'commented on your reel';

  @override
  String get reelComment => 'Comment';

  @override
  String get reelCommentsTitle => 'Comments';

  @override
  String get reelCommentsEmpty => 'No comments yet. Be the first!';

  @override
  String get reelCommentsRetry => 'Retry';

  @override
  String get reelCommentHint => 'Add a comment…';

  @override
  String get reelCommentReply => 'Reply';

  @override
  String reelCommentReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get reelCommentDelete => 'Delete';

  @override
  String get reelCommentDeleteTitle => 'Delete comment?';

  @override
  String get reelCommentDeleteBody =>
      'The comment and all its replies will be deleted.';

  @override
  String get reelCommentDeleted => 'Comment deleted';

  @override
  String get reelCommentReport => 'Report';

  @override
  String get composerAddPoll => 'Add a poll';

  @override
  String get composerRemovePoll => 'Remove the poll';

  @override
  String get composerPollTitle => 'Poll';

  @override
  String get composerPollQuestionNote =>
      'The post\'s text is the poll question.';

  @override
  String composerPollOptionHint(String n) {
    return 'Option $n';
  }

  @override
  String get composerPollAddOption => 'Add option';

  @override
  String get composerPollRemoveOption => 'Remove option';

  @override
  String get pollDurationHour => '1 hour';

  @override
  String get pollDurationSixHours => '6 hours';

  @override
  String get pollDurationDay => '1 day';

  @override
  String get pollDurationThreeDays => '3 days';

  @override
  String get pollDurationWeek => '1 week';

  @override
  String pollVotes(String count) {
    return '$count votes';
  }

  @override
  String pollLeftDays(String n) {
    return '${n}d left';
  }

  @override
  String pollLeftHours(String n) {
    return '${n}h left';
  }

  @override
  String pollLeftMinutes(String n) {
    return '${n}m left';
  }

  @override
  String get pollClosed => 'Poll closed';

  @override
  String get pollVoteFailed => 'Couldn\'t record your vote';

  @override
  String get setupSecureTitle => 'Secure your account';

  @override
  String get setupSecureOptional => 'Optional';

  @override
  String get setupSecureBody =>
      'Confirm your email to add a second way to verify — and a way back in if you lose your number.';

  @override
  String get setupSecureAction => 'Confirm email';

  @override
  String get setupSecureDismiss => 'Not now';

  @override
  String get emailVerifyTitle => 'Email & two-step verification';

  @override
  String get emailVerifyIntro =>
      'Add and confirm your email to use it as a second verification step, and as a way in if you lose your phone number. Your phone stays the primary one.';

  @override
  String get emailVerifySend => 'Send code';

  @override
  String get emailVerifyChangeAddress => 'Change email';

  @override
  String get emailVerifyDone => 'Your email is confirmed';

  @override
  String get setupSave => 'Continue';

  @override
  String get setupSkip => 'Skip for now';

  @override
  String get setupSaved => 'Your profile is saved 🎉';

  @override
  String get authGender => 'Gender';

  @override
  String get authGenderMale => 'Male';

  @override
  String get authGenderFemale => 'Female';

  @override
  String get authPhoto => 'Profile photo';

  @override
  String get authPhotoPick => 'Pick a photo';

  @override
  String get authPhotoChange => 'Change photo';

  @override
  String get authPhotoRemove => 'Remove';

  @override
  String get authPhotoUploading => 'Uploading photo…';

  @override
  String get authGenderRequired => 'Choose a gender';

  @override
  String get profileConnectSent => 'Request sent';

  @override
  String get profileConnectAccept => 'Accept request';

  @override
  String get profileConnected => 'Connected';

  @override
  String get profileFollowRequested => 'Requested';

  @override
  String get toastConnectRequestCancelled => 'Request withdrawn';

  @override
  String get toastConnectionRemoved => 'Connection removed';

  @override
  String get toastConnectAccepted => 'Request accepted';

  @override
  String get networkAddSent => 'Sent';

  @override
  String get welcomeConnectTitle => 'Start your network';

  @override
  String get welcomeConnectBody =>
      'People in your field. Send a request and their posts start showing up on your home feed.';

  @override
  String get welcomeConnectEmpty =>
      'No suggestions right now. You can search for people any time from the Network tab.';

  @override
  String get welcomeConnectContinue => 'Continue to the feed';

  @override
  String get activityFollowed => 'started following you';

  @override
  String get activityConnectRequested => 'sent you a connection request';

  @override
  String get activityConnectAccepted => 'accepted your connection request';

  @override
  String get activityLiked => 'liked your post';

  @override
  String get activityCommented => 'commented on your post';

  @override
  String get activityMentioned => 'mentioned you';

  @override
  String get activityMessaged => 'sent you a message';

  @override
  String get activityShared => 'shared your post';

  @override
  String get activityApplied => 'applied to your job';

  @override
  String get activityCalled => 'called you';

  @override
  String get activityOther => 'sent you a notification';

  @override
  String get applyResumeNone => 'No résumé attached';

  @override
  String get applyResumeUploadHint => 'Choose a PDF or Word file';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionEdit => 'Edit';

  @override
  String get profileEditExperience => 'Edit experience';

  @override
  String get profileEditEducation => 'Edit education';

  @override
  String get profileEditSkills => 'Edit skills';

  @override
  String get profileAddExperience => 'Add experience';

  @override
  String get profileAddEducation => 'Add education';

  @override
  String get profileAddSkill => 'Add skill';

  @override
  String get profileSectionEmpty => 'Nothing here yet';

  @override
  String get profileDeleteEntryTitle => 'Delete this entry?';

  @override
  String get profileDeleteEntryBody => 'This can\'t be undone.';

  @override
  String get fieldRole => 'Title';

  @override
  String get fieldCompany => 'Company';

  @override
  String get fieldEmploymentType => 'Employment type';

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldStartDate => 'Start date';

  @override
  String get fieldEndDate => 'End date';

  @override
  String get fieldCurrentRole => 'I currently work here';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldSchool => 'School';

  @override
  String get fieldDegree => 'Degree';

  @override
  String get fieldFieldOfStudy => 'Field of study';

  @override
  String get fieldSkillName => 'Skill name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get fieldNotSet => 'Not set';

  @override
  String get employmentFullTime => 'Full-time';

  @override
  String get employmentPartTime => 'Part-time';

  @override
  String get employmentContract => 'Contract';

  @override
  String get employmentInternship => 'Internship';

  @override
  String get employmentFreelance => 'Freelance';

  @override
  String get employmentSelfEmployed => 'Self-employed';

  @override
  String get employmentTemporary => 'Temporary';

  @override
  String get editProfileChangePhoto => 'Change photo';

  @override
  String get editProfileChangeCover => 'Change cover';

  @override
  String get profileActivity => 'Activity';

  @override
  String get profileActivityPosts => 'Posts';

  @override
  String get profileActivityComments => 'Comments';

  @override
  String get profileActivityShowAll => 'Show all';

  @override
  String get profileCreatePost => 'Create a post';

  @override
  String profileFollowersCount(String count) {
    return '$count followers';
  }

  @override
  String get profileCommentedOn => 'Commented on a post';

  @override
  String get postSeeMore => '…more';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'Match system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSaved => 'Saved';

  @override
  String get savedPostsTitle => 'Saved posts';

  @override
  String get savedPostsEmpty => 'You have not saved any posts yet';

  @override
  String get savedJobsTitle => 'Saved jobs';

  @override
  String get savedJobsEmpty => 'You have not saved any jobs yet';

  @override
  String get jobSaveRemoved => 'Removed from saved';

  @override
  String get jobCompanyCannotApply => 'Company accounts cannot apply to jobs';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutTitle => 'Log out?';

  @override
  String get settingsLogoutBody => 'You\'ll need to sign in again to continue.';

  @override
  String get profileMoreOptions => 'Options';

  @override
  String get profileBlock => 'Block';

  @override
  String get profileBlockTitle => 'Block this account?';

  @override
  String get profileBlockBody =>
      'Neither of you will see the other\'s posts or profile, and any follow between you is removed.';

  @override
  String get profileBlockDone => 'Blocked';

  @override
  String get feedSuggestedPost => 'Suggested for you';

  @override
  String get composerAddPhoto => 'Add a photo';

  @override
  String get composerUploadsOff =>
      'File uploads are not enabled on this server';

  @override
  String get composerAddDocument => 'Attach a document';

  @override
  String get composerAddHashtag => 'Add a hashtag';

  @override
  String get composerAddMention => 'Mention someone';

  @override
  String get composerModePost => 'Post';

  @override
  String get composerModeStory => 'Story';

  @override
  String get composerModeReel => 'Reel';

  @override
  String get composerSingleMediaOnly => 'This type holds one file';

  @override
  String composerVideoTooLarge(int max) {
    return 'That video is too large (the limit is $max MB)';
  }

  @override
  String composerDocumentTooLarge(int max) {
    return 'That file is too large (the limit is $max MB)';
  }

  @override
  String get composerTitleStory => 'New story';

  @override
  String get composerTitleReel => 'New reel';

  @override
  String get composerHintStory => 'Add a caption to your story…';

  @override
  String get composerHintReel => 'Describe your reel…';

  @override
  String get composerAddVideo => 'Add a video';

  @override
  String get composerStoryNeedsMedia => 'A story needs a photo or a video';

  @override
  String get composerReelNeedsVideo => 'A reel needs a video';

  @override
  String get composerModeDropped =>
      'Attachments that do not fit this type were removed';

  @override
  String get toastStoryPosted => 'Story published ✓';

  @override
  String get toastReelPosted => 'Reel published ✓';

  @override
  String get postOpenDocument => 'Open document';

  @override
  String get postOpenDocumentFailed => 'Could not open the document';

  @override
  String get composerPhotoRetry => 'Retry';

  @override
  String composerPhotoLimit(int max) {
    return 'You can attach up to $max photos';
  }

  @override
  String get navMyJobs => 'My jobs';

  @override
  String get navApplicants => 'Applicants';

  @override
  String get navPage => 'My page';

  @override
  String get companyJobsTitle => 'My jobs';

  @override
  String get companyJobsEmpty => 'No postings yet';

  @override
  String get companyJobsEmptyHint =>
      'Post a job and candidates can start applying';

  @override
  String get companyPostJob => 'Post a job';

  @override
  String get companyPublishJob => 'Publish job';

  @override
  String get companyJobPosted => 'Job posted';

  @override
  String get companyJobOpen => 'Open';

  @override
  String get companyJobClosed => 'Closed';

  @override
  String get companyViewApplicants => 'View applicants';

  @override
  String get companyApplicantsTitle => 'Applicants';

  @override
  String get companyNoApplicants => 'No applicants yet';

  @override
  String get companyNoApplicantsHint =>
      'Everyone who applies to this posting shows up here';

  @override
  String get companyApplicantUnknown => 'Applicant';

  @override
  String get companyStatusSaved => 'Application updated';

  @override
  String get companyFieldRequired => 'Required';

  @override
  String get companyJobTitle => 'Job title';

  @override
  String get companyJobCompany => 'Company';

  @override
  String get companyJobLocation => 'Location';

  @override
  String get companyJobEmploymentType => 'Employment type';

  @override
  String get companyJobWorkMode => 'Workplace';

  @override
  String get companyJobSalaryMin => 'Salary from';

  @override
  String get companyJobSalaryMax => 'Salary to';

  @override
  String get companyJobDescription => 'Description';

  @override
  String get companyJobRequirements => 'Requirements';

  @override
  String get companyJobRequirementsHint => 'One requirement per line';

  @override
  String companyApplicantCount(String count) {
    return '$count applicants';
  }

  @override
  String companyAppliedAgo(String time) {
    return 'Applied $time';
  }

  @override
  String get companyOverview => 'Overview';

  @override
  String get companySize => 'Company size';

  @override
  String get companySizeSelf => 'Just me';

  @override
  String get companyFounded => 'Founded';

  @override
  String companyFoundedOn(String date) {
    return 'Founded on $date';
  }

  @override
  String get companySpecialties => 'Specialties';

  @override
  String get companySpecialtiesHint => 'One specialty per line';

  @override
  String get companyJobCompanyWebsite => 'Website';

  @override
  String get companyOpenJobs => 'Open jobs';

  @override
  String companyOpenJobsCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'open jobs',
      one: 'open job',
    );
    return '$_temp0';
  }

  @override
  String get companyWebsiteFailed => 'Could not open the website';

  @override
  String get companySeeAllJobs => 'See all jobs';

  @override
  String get profilePosts => 'Posts';

  @override
  String companySizeOver(String count) {
    return 'Over $count employees';
  }

  @override
  String companySizeRange(String from, String to) {
    return '$from-$to employees';
  }

  @override
  String get companyNoOpenJobs => 'No open jobs right now';

  @override
  String get courseTitle => 'Course';

  @override
  String get coursesEmpty => 'No courses yet';

  @override
  String get coursesEmptyHint => 'Courses appear here as they are published';

  @override
  String get courseLecturesDone => 'Lectures';

  @override
  String get courseEnroll => 'Enrol';

  @override
  String get courseEnrolled => 'You are enrolled';

  @override
  String get courseFinishLecture => 'Finish this lecture';

  @override
  String get courseProgressSaved => 'Progress saved';

  @override
  String get courseCompleted => 'Course complete';

  @override
  String get courseCertificateEarned => 'You earned a certificate';

  @override
  String get notesEmpty => 'No notes yet';

  @override
  String get notesEmptyHint => 'Write your first note';

  @override
  String get notesNew => 'New note';

  @override
  String get notesEdit => 'Edit note';

  @override
  String get notesTitleLabel => 'Title';

  @override
  String get notesBodyLabel => 'Body';

  @override
  String get notesUntitled => 'Untitled';

  @override
  String get documentsEmpty => 'Nothing here yet';

  @override
  String get documentsEmptyHint => 'References appear here once added';

  @override
  String get documentNoFile => 'No file attached';

  @override
  String get legalEmpty => 'No requests yet';

  @override
  String get legalEmptyHint => 'Send a request and the answer arrives here';

  @override
  String get legalNewRequest => 'New request';

  @override
  String get legalSubjectLabel => 'Subject';

  @override
  String get legalBodyLabel => 'Your question';

  @override
  String get legalSubmit => 'Submit';

  @override
  String get legalSubmitted => 'Request sent';

  @override
  String get legalResponse => 'Answer';

  @override
  String get legalStatusSubmitted => 'Submitted';

  @override
  String get legalStatusInReview => 'In review';

  @override
  String get legalStatusAnswered => 'Answered';

  @override
  String get legalStatusClosed => 'Closed';

  @override
  String get assistantHint => 'Type your question…';

  @override
  String get assistantStubNotice =>
      'The assistant is not connected yet — your questions are saved and answered once it is.';

  @override
  String courseLectureCount(String count) {
    return '$count lectures';
  }

  @override
  String courseLectureOf(String current, String total) {
    return '$current of $total';
  }

  @override
  String get courseLecturesSection => 'Lectures';

  @override
  String get courseLecturesEmpty =>
      'No lectures have been added to this course yet';

  @override
  String get courseLectureLocked => 'Finish the previous lecture first';

  @override
  String get courseLectureNoVideo => 'The video isn\'t available yet';

  @override
  String get courseLecturePreview => 'Free preview';

  @override
  String get courseLectureMarkedDone => 'Lecture marked complete';

  @override
  String get coursePlayerError => 'The video could not be played';

  @override
  String courseLectureMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get subscriptionLockedTitle => 'This section is for subscribers';

  @override
  String get subscriptionLockedBody =>
      'Subscribe to reach the courses, the engineering library, legal affairs and your own tools.';

  @override
  String get subscriptionChoosePlan => 'Choose a plan';

  @override
  String get subscriptionSubscribe => 'Subscribe';

  @override
  String get subscriptionPlansEmpty => 'No plans are available right now';

  @override
  String get subscriptionCurrent => 'Your subscription';

  @override
  String get subscriptionManage => 'Manage subscription';

  @override
  String get subscriptionStatusPending => 'Awaiting activation';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionStatusExpired => 'Expired';

  @override
  String get subscriptionStatusCancelled => 'Cancelled';

  @override
  String get subscriptionPendingNotice =>
      'Your request was received. The subscription starts once payment is confirmed.';

  @override
  String get subscriptionStarted => 'Subscription requested';

  @override
  String get subscriptionCancelAction => 'Cancel subscription';

  @override
  String get subscriptionCancelConfirm =>
      'Cancel your subscription? Access stays open until the paid term ends.';

  @override
  String get subscriptionCancelled => 'Subscription cancelled';

  @override
  String get subscriptionKeep => 'Keep it';

  @override
  String get subscriptionTrialBadge => 'Free trial';

  @override
  String subscriptionTrialEndsIn(String days) {
    return 'Your free trial ends in $days days';
  }

  @override
  String subscriptionExpiresIn(String days) {
    return 'Ends in $days days';
  }

  @override
  String get subscriptionEndsToday => 'Ends today';

  @override
  String get billingCycleMonthly => 'Monthly';

  @override
  String get billingCycleAnnual => 'Annual';

  @override
  String get billingPerMonth => '/month';

  @override
  String get billingPerYear => '/year';

  @override
  String billingSave(String percent) {
    return 'Save $percent%';
  }

  @override
  String get subscriptionCycleUnavailable => 'Not offered on this plan';

  @override
  String get subscriptionChangeAction => 'Change plan';

  @override
  String get subscriptionChangeTitle => 'Change plan';

  @override
  String get subscriptionChangeConfirm => 'Confirm change';

  @override
  String get subscriptionChangeDismiss => 'Go back';

  @override
  String get subscriptionChangeBlocked => 'You cannot change to this plan';

  @override
  String get subscriptionChangeFrom => 'From';

  @override
  String get subscriptionChangeTo => 'To';

  @override
  String get subscriptionChangePrice => 'Price';

  @override
  String get subscriptionCurrentPlanBadge => 'Your plan';

  @override
  String get subscriptionChangeDue => 'You pay';

  @override
  String get subscriptionChangePlanPrice => 'New plan price';

  @override
  String get subscriptionChangeCreditAmount =>
      'Credited from your current plan';

  @override
  String get subscriptionChangeNoExtraCost => 'No extra charge';

  @override
  String subscriptionChangeKeepsDate(String days) {
    return 'Your renewal date does not change — $days days left';
  }

  @override
  String get subscriptionChangeImmediateNotice =>
      'The change takes effect right away; the difference is billed on your next invoice.';

  @override
  String get subscriptionChangeDowngradeNotice =>
      'You lose your current plan\'s features as soon as you confirm, and no money is refunded.';

  @override
  String get subscriptionChangeDone => 'Your plan has changed';

  @override
  String subscriptionPerDays(String days) {
    return 'per $days days';
  }

  @override
  String get courseLevelBeginner => 'Beginner';

  @override
  String get courseLevelIntermediate => 'Intermediate';

  @override
  String get courseLevelAdvanced => 'Advanced';

  @override
  String get courseFree => 'Free';

  @override
  String get courseLockedBadge => 'Subscription';

  @override
  String get courseLockedTitle => 'This course needs a subscription';

  @override
  String get courseLockedBody =>
      'Subscribe to open this section. The first lesson is free to watch first.';

  @override
  String get courseSubscribeToOpen => 'See plans';

  @override
  String courseHours(String hours) {
    return '$hours h';
  }

  @override
  String courseEnrolledCount(String count) {
    return '$count enrolled';
  }

  @override
  String get courseNoRatings => 'Not rated yet';

  @override
  String courseRatingOf(String rating, String count) {
    return '$rating ($count)';
  }

  @override
  String get courseAbout => 'About';

  @override
  String get courseOutcomes => 'What you\'ll learn';

  @override
  String get courseRequirements => 'Requirements';

  @override
  String get courseInstructor => 'Instructor';

  @override
  String get courseRateTitle => 'Rate this course';

  @override
  String get courseRateAction => 'Submit rating';

  @override
  String get courseRated => 'Thanks for rating';

  @override
  String get courseYourRating => 'Your rating';

  @override
  String get courseRateHint => 'Add a comment (optional)';

  @override
  String get lessonKindVideo => 'Video';

  @override
  String get lessonKindPdf => 'PDF';

  @override
  String get lessonKindArticle => 'Reading';

  @override
  String get lessonOpenPdf => 'Open file';

  @override
  String get lessonPdfFailed => 'The file could not be opened';

  @override
  String get coursesFilterAll => 'All';

  @override
  String get coursesFilterFree => 'Available to me';

  @override
  String get planIncludes => 'Includes';

  @override
  String get featureTheoryCourses => 'Theory courses';

  @override
  String get featurePracticalCourses => 'Practical courses';

  @override
  String get featureTrainingCourses => 'Training courses';

  @override
  String get featureLibrary => 'Engineering library';

  @override
  String get featureLegalAffairs => 'Legal affairs';

  @override
  String get documentLocked => 'Subscription';

  @override
  String subscriptionInvoiceNumber(String number) {
    return 'Invoice #$number';
  }

  @override
  String get subscriptionAutoRenew => 'Auto-renew';

  @override
  String get subscriptionAutoRenewOn =>
      'A new term starts automatically when this one ends.';

  @override
  String get subscriptionAutoRenewOff =>
      'Your subscription ends when this term does.';

  @override
  String get subscriptionAutoRenewSaved => 'Renewal setting saved';

  @override
  String get profileFollowing => 'following';

  @override
  String get peopleConnectionsTitle => 'Connections';

  @override
  String get peopleFollowersTitle => 'Followers';

  @override
  String get peopleFollowingTitle => 'Following';

  @override
  String get peopleRemove => 'Remove';

  @override
  String get peopleEmpty => 'Nobody here yet';

  @override
  String peopleRemoveConfirm(String name) {
    return 'Remove $name from your connections?';
  }

  @override
  String peopleUnfollowConfirm(String name) {
    return 'Stop following $name?';
  }

  @override
  String get postSuggestedFollowing => 'Following';

  @override
  String get reelMute => 'Mute';

  @override
  String get reelUnmute => 'Unmute';
}
