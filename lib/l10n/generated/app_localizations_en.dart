// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rung';

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
  String get authStatProfessionalsValue => '12M+';

  @override
  String get authStatProfessionalsLabel => 'professionals';

  @override
  String get authStatJobsValue => '240k';

  @override
  String get authStatJobsLabel => 'open roles';

  @override
  String get authStatTrustValue => '98%';

  @override
  String get authStatTrustLabel => 'trust score';

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
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authUserNameTooShort => 'Username must be at least 3 characters';

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
  String get coursesFilterFree => 'Free';

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
}
