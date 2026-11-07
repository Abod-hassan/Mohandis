/// All backend endpoint paths. **Never inline a URL string in a repository
/// — add it here first.** See docs/ARCHITECTURE.md §7 for the doc-comment
/// convention every endpoint constant SHALL follow.
///
/// Group related constants (auth, users, orders, …) into logical clusters
/// with header comments. Namespace the constant names so grepping for
/// `authLogin` / `usersProfile` / `ordersCreate` finds them.
class EndPoints {
  EndPoints._();

  // ── Host ────────────────────────────────────────────────────────────────

  /// `GET /health` — liveness, and the default tenant an anonymous client
  /// needs before it can write anything.
  ///
  /// Not under `/api`: it is mapped directly on the host, outside every
  /// module. **Response:** `{ ok, tenantId, modules: string[] }`.
  ///
  /// Why the client needs it: the tenant normally rides the JWT's `TenantId`
  /// claim, but sign-up and login happen before there is a token, and Kernel
  /// `StrictTenantWrites` rejects a write with no tenant in scope. The id from
  /// here goes back as the `X-Tenant-Id` header on exactly those calls.
  static const String health = '/health';

  // ══ RoboByte.Auth module ════════════════════════════════════════════════
  //
  // Auth does NOT use the `api/social` prefix — it declares plain routes, so
  // everything here is `api/Auth/…`. There was once a second, mobile-specific
  // controller at `api/Mobile/Auth`; it was deleted (commit "remove mobile
  // controllers") and is absent from the shipped package, so those paths 404.
  //
  // Unlike the social module these actions do NOT return a `ResultViewModel`
  // envelope: login answers a bare `LoginResultDto`, register a bare string.
  // `ApiEnvelope` handles both — a non-envelope body becomes the data.

  /// `POST /api/Auth/Login` — sign in.
  ///
  /// **Request:** `{ userName, password }`. The username is Identity's
  /// `UserName`, not an email — the module never stores one.
  /// **Response:** `{ id, userName, roles, userType, accessToken,
  /// refreshToken, displayName, phoneNumber, tenantId }` — no envelope, and
  /// **no expiry fields**: the access token's lifetime is read out of the JWT's
  /// own `exp` claim (see `MobileAuthResultDto`).
  /// **Failure:** `401` `{ message: "Invalid username" }` for an unknown user
  /// and `{ message: "User Unauthorized" }` for a bad password or a locked-out
  /// account — the two are deliberately not distinguished further.
  static const String authLogin = '/api/Auth/Login';

  /// `PUT /api/Auth/Refresh-Token?refreshToken=<value>` — rotate the
  /// pair.
  ///
  /// Note the verb (**PUT**) and that the token rides in the QUERY STRING, not
  /// the body. The response repeats the same refresh token rather than issuing
  /// a new one; only the access token is re-minted.
  /// **Failure:** `404` when the token is unknown, `401` when it has expired.
  static const String authRefresh = '/api/Auth/Refresh-Token';

  /// `POST /api/Auth/Logout` — revoke a refresh token.
  ///
  /// **Request:** `refreshToken` as **form data** (`[FromForm]`), not JSON.
  static const String authLogout = '/api/Auth/Logout';

  /// `DELETE /api/Auth/Account` — removes the caller's login (anonymised and
  /// disabled). Called after [profilesMe] DELETE has removed the social data.
  static const String authAccount = '/api/Auth/Account';

  /// `POST /api/Contact` — creates the contact record. **Step 1 of 2** in
  /// registration.
  ///
  /// A user account cannot exist without a contact: `RegisterForm` requires a
  /// `contactId`, and the contact is what carries the person's name and phone.
  ///
  /// **Request:** `{ name, phone, address, userType, gender?, dateOfBirth? }`.
  /// **Response:** `ResultViewModel<Guid>` — `data` is the new contact id,
  /// which step 2 needs.
  static const String contacts = '/api/Contact';

  /// `POST /api/Auth/Register` — creates the Identity user. **Step 2**.
  ///
  /// **Request:** `{ userName, password, contactId }`. The password must pass
  /// Identity's policy (6+ characters here) — a violation comes back as a
  /// `400` whose body is the raw message, e.g. "Passwords must have at least
  /// one digit ('0'-'9')."
  /// **Response:** `200` with the bare string `"user created successfully"` —
  /// no tokens, so the client signs in afterwards.
  static const String authRegister = '/api/Auth/Register';

  /// `POST /api/Auth/ResetPassword` — `{ password, confirmPassword }`.
  ///
  /// The end of the forgot-password flow, and authorized: the bearer is the
  /// session that proving a recovery channel just produced, which carries the
  /// `RecoveryVerified` role. That role is what lets the account's own
  /// password be replaced WITHOUT the old one — for that user only, since the
  /// target is taken from the token, never from the body.
  ///
  /// `POST /api/Auth/ForgotPassword` no longer exists. The module removed the
  /// link-based flow (it never sent, pointed at a hardcoded internal IP, and
  /// leaked account existence) in favour of prove-a-channel-then-reset.
  static const String authResetPassword = '/api/Auth/ResetPassword';

  // `POST /api/Auth/SignUp` does not exist on this backend and never did —
  // the constant and its documentation were removed with the client's
  // one-shot sign-up path. The two-step flow below replaces it.

  // ── Self-service registration (RoboByte.Auth 1.14.1, guide §5) ───────────
  //
  // Two steps, always: PROVE an identity to get a registration token
  // (`isNewUser: true`), then spend that token on CreateWithContact to create
  // the account and receive a real session. There is no one-shot sign-up, and
  // `POST /api/Contact` is `[Authorize]`d — which is what used to answer 401
  // on the first call of a registration.

  /// Anonymous pre-check the sign-up form calls while the person types.
  /// `GET ?userName=&phone=&email=` → `{exists, userNameTaken, phoneTaken,
  /// emailTaken}`. One call covers all three; omit the ones you are not asking
  /// about.
  static const String authExists = '/api/Auth/Exists';

  /// Phone channel. Both take QUERY parameters, not a body.
  /// `isSms=false` is the WhatsApp→SMS cascade; true forces plain SMS.
  static const String authGenerateOtp = '/api/Auth/GenerateOTP';
  static const String authValidateOtp = '/api/Auth/ValidateOTP';

  /// E-mail channel. These two take a JSON body.
  static const String authEmailSendCode = '/api/Auth/Email/SendCode';
  static const String authEmailVerifyCode = '/api/Auth/Email/VerifyCode';

  /// `POST /api/Auth/Email/Change` — `{ email, code }`. Sets AND confirms the
  /// CALLER's address in one call, acting on the JWT's user only.
  ///
  /// Authorized, which is what makes it the right endpoint for the optional
  /// second factor: [authEmailVerifyCode] is the anonymous sign-in path and
  /// answers a registration token for an address with no account behind it,
  /// which is the opposite of attaching an address to the account in hand.
  /// The code itself comes from the same [authEmailSendCode] either way.
  static const String authEmailChange = '/api/Auth/Email/Change';

  /// Spends the registration token. Authorized — the bearer IS the proof.
  static const String authCreateWithContact = '/api/Auth/CreateWithContact';

  // There is no `/api/auth/me`. Cold-start session validation uses
  // [profilesMe] instead — it needs a valid bearer token, which is exactly the
  // signal we want, and it returns the ProfileId the app needs anyway.
  //
  // There is no signing-bootstrap endpoint either. `RequestSigningInterceptor`
  // omits `X-Request-Key` when no secret is stored, which is the correct
  // behaviour against this backend — do not add a call for it.

  // ── Device / notifications ──────────────────────────────────────────────

  // These belong to the Notification module (RoboByte.Notification 1.0.7,
  // `NotificationController`, `[Route("api/[controller]")]`). The client used
  // to post to `/api/device/register-token`, which no module on this backend
  // has ever served — so no device was ever registered, and every push the
  // server tried to send had nowhere to go.
  //
  // Both act on the caller: the contact comes from the JWT ("no contact id in
  // token" otherwise) and the device from `X-Device-SN`, which is how one
  // person on two phones gets two rows in `notification.NotificationTokens`.

  /// `POST /api/Notification/UpdateNID?nid=<token>` — this device's FCM token
  /// ("NID"). The parameter is a bare string, so it binds from the query.
  static const String deviceRegisterToken = '/api/Notification/UpdateNID';

  /// `GET /api/Notification/RemoveNID` — forget this device's token, so a
  /// signed-out phone stops receiving someone else's notifications.
  ///
  /// A GET that writes, which is the module's choice, not this app's — see
  /// `NotificationController.RemoveNID`. Sent as POST it answers 405.
  static const String deviceUnregisterToken = '/api/Notification/RemoveNID';

  // ══ RoboByte.SocialMedia module ═════════════════════════════════════════
  //
  // Every controller in the module is served under `api/social/…` — the module
  // declares `[Route("api/[controller]")]` and `AddRoboByteSocialMedia` applies
  // the Kernel's `AddModuleRoutePrefix("social", …)` convention on top. Without
  // the prefix `JobsController` would collide with the HR module's, and the
  // collision fails at request time, not startup. Never hand-write a module
  // path without it.
  //
  // Two conventions differ from a plain REST API and drive every signature below:
  //
  //   1. **Reads are POSTs.** A list read is `POST /api/social/<Entity>` with a
  //      *filter object* as the body and `?page=&size=` (plus `?detailed=` where
  //      the entity has a simplified projection) in the query. The filter's
  //      `viewerProfileId` is set server-side from the bearer token — never send
  //      it, it is overwritten.
  //   2. **Every response is an envelope.** `ResultViewModel<T>` — the payload is
  //      under `data`, with `error` / `message` / `totalCount` / `hasMore`
  //      alongside. Decode with `ApiEnvelope`; never read a body directly.

  // ── Feed ────────────────────────────────────────────────────────────────

  /// `POST /api/social/Feed` — the ranked home feed, blended from the
  /// Cassandra fan-out store, the Postgres recommendation pool, and ads.
  ///
  /// **Request:** `{ bucket?, beforeEventTime?, recommendationOffset, pageSize }`
  /// — send none of the three cursors for the first page, then echo back
  /// `bucket`, `nextBeforeEventTime` AND `nextRecommendationOffset` from the
  /// previous page. The two sources page independently; dropping either cursor
  /// re-serves rows you already showed.
  /// **Response:** `data` = `{ items: FeedItemDto[], bucket,
  /// nextBeforeEventTime, nextRecommendationOffset, hasMore }`.
  ///
  /// A page can come back shorter than `pageSize` — rows whose underlying post
  /// was deleted are dropped after paging. Treat `hasMore`, not the item count,
  /// as the end-of-feed signal.
  static const String feed = '/api/social/Feed';

  /// `POST /api/social/Feed/Hide?itemId=<guid>&scope=<0|1>` — "not interested".
  /// `scope` 0 hides the single item, 1 hides everything from its author.
  static const String feedHide = '/api/social/Feed/Hide';

  /// `POST /api/social/Feed/Unhide?itemId=<guid>&scope=<0|1>` — undoes [feedHide].
  static const String feedUnhide = '/api/social/Feed/Unhide';

  /// `POST /api/social/Reports` — reports a post, reel, comment, message,
  /// story or profile.
  ///
  /// **Request:** `{ targetType, targetId, reason, details? }`, both enums as
  /// their integer value — `targetType` 0 is a post, and `reason` runs
  /// 0 spam, 1 harassment, 2 hate speech, 3 violence, 4 nudity,
  /// 5 misinformation, 6 self-harm, 7 impersonation, 8 IP, 9 other.
  ///
  /// Open to any signed-in caller: reporting is safe by construction, and
  /// acting on a report is a separate, gated surface.
  static const String reports = '/api/social/Reports';

  // ── Posts ───────────────────────────────────────────────────────────────

  /// `POST /api/social/Posts` — filtered post read. Backs profile activity and
  /// hashtag/search listings; the home feed uses [feed] instead.
  ///
  /// **Request:** `PostFilter` body — `{ id?, authorIds?: guid[], followedOnly?,
  /// onlyLiked?, hashtag?, search?, orderBy, descending }` — with
  /// `?detailed=true&page=1&size=20`. `detailed=false` returns the lighter
  /// `PostSimplifiedDto` projection.
  /// **Response:** `data` = `PostDto[]`, `totalCount` + `hasMore` on the envelope.
  static const String posts = '/api/social/Posts';

  /// `GET /api/social/Posts/{id}` — one post, full projection.
  ///
  /// **Failure:** `404` when the post is missing or invisible to the caller —
  /// visibility is applied inside the query, so "private" and "deleted" are
  /// deliberately indistinguishable from the client.
  static String postById(String id) => '/api/social/Posts/$id';

  /// `POST /api/social/Posts/Publish` — create a post.
  ///
  /// **Request:** `{ content, visibility: 0|1|2, media?: [{ url, kind: 0|1,
  /// thumbnailUrl?, position, width?, height?, durationSeconds? }] }`.
  /// Hashtags and @mentions are parsed out of `content` server-side — do not
  /// send a tags array, there is no field for one.
  /// **Response:** `data` = the created `PostDto`.
  static const String postsPublish = '/api/social/Posts/Publish';

  /// `POST /api/social/Posts/Share` — repost, optionally with a comment.
  ///
  /// **Request:** `{ sharedPostId, content?, visibility: 0|1|2 }`.
  /// **Response:** `data` = the new `PostDto` wrapping the original.
  static const String postsShare = '/api/social/Posts/Share';

  /// `POST /api/social/Posts/Save?postId=<guid>` — toggles the caller's
  /// bookmark.
  ///
  /// **Response:** `data` = the whole post with `isSaved` flipped. A save is
  /// private, so unlike a like it moves no counter and notifies nobody.
  static const String postsSave = '/api/social/Posts/Save';

  /// `POST /api/social/Posts/Like?postId=<guid>` — toggles the caller's like.
  ///
  /// **Response:** `data` = the whole post with authoritative `likeCount` /
  /// `isLiked`, so an optimistic toggle can be reconciled rather than trusted.
  static const String postsLike = '/api/social/Posts/Like';

  /// `POST /api/social/Posts/View?postId=<guid>` — records an explicit view and
  /// marks the viewer's fanned-out feed copy seen. Anonymous views are accepted.
  ///
  /// **Response:** `data` = `true`.
  static const String postsView = '/api/social/Posts/View';

  // ── Comments ────────────────────────────────────────────────────────────

  /// `POST /api/social/Comments` — filtered comment read.
  ///
  /// **Request:** `CommentFilter` body — `{ postId?, parentCommentId?,
  /// topLevelOnly?, orderBy, descending }` — with `?page=&size=`.
  /// **Response:** `data` = `CommentDto[]`. The list is FLAT: replies carry
  /// `parentCommentId` and are nested client-side.
  static const String comments = '/api/social/Comments';

  /// `POST /api/social/Comments/Add?postId=<guid>` — add a comment or reply.
  ///
  /// **Request:** `{ content, parentCommentId? }`.
  /// **Failure:** `400` `"Parent comment not found."` when the parent id is not
  /// a comment on that post.
  static const String commentsAdd = '/api/social/Comments/Add';

  /// `POST /api/social/Posts/Vote?pollId=&optionId=` — votes in a post's poll,
  /// moves the vote, or (same option again) takes it back. Answers `PollDto`.
  static const String postsVote = '/api/social/Posts/Vote';

  /// `POST /api/social/Comments/Like?commentId=<guid>` — toggle a comment like.
  static const String commentsLike = '/api/social/Comments/Like';

  /// `DELETE /api/social/Comments/{id}` — author-only soft delete.
  static String commentById(String id) => '/api/social/Comments/$id';

  // ── Profiles ────────────────────────────────────────────────────────────

  /// `POST /api/social/Profiles` — filtered profile read; also the people
  /// directory and people search.
  ///
  /// **Request:** `ProfileFilter` body — `{ id?, username?, search?, orderBy,
  /// descending }` — with `?detailed=<bool>&page=&size=`. `detailed=false`
  /// (the default) returns `ProfileSimplifiedDto`: id, username, displayName,
  /// headline, avatarUrl, isVerified, isOnline, lastSeenAt.
  /// **Response:** `data` = `ProfileDto[]` or `ProfileSimplifiedDto[]`.
  static const String profiles = '/api/social/Profiles';

  /// `GET /api/social/Profiles/Me` — the caller's own profile, resolved from the
  /// bearer token, so it takes no id.
  ///
  /// The module keys everything by **ProfileId**, which is NOT the auth
  /// ContactId in the JWT — this endpoint is the only way for the client to
  /// learn its own ProfileId, so "me" surfaces resolve through here first.
  ///
  /// **Response:** `data` = full `ProfileDto` with `isMe: true`.
  static const String profilesMe = '/api/social/Profiles/Me';

  /// `GET /api/social/Profiles/{profileId}` — one profile, full projection
  /// including the viewer-relative flags (`isFollowing`, `followRequestPending`,
  /// `isConnected`, …).
  ///
  /// **Failure:** `404` when unknown.
  static String profileById(String profileId) =>
      '/api/social/Profiles/$profileId';

  /// `GET /api/social/Profiles/followers/{profileId}?page=&size=` —
  /// `data` = `ProfileSimplifiedDto[]`.
  static String profileFollowers(String profileId) =>
      '/api/social/Profiles/followers/$profileId';

  /// `GET /api/social/Profiles/following/{profileId}?page=&size=`.
  static String profileFollowing(String profileId) =>
      '/api/social/Profiles/following/$profileId';

  /// `GET /api/social/Profiles/requests?page=&size=` — inbound follow requests
  /// awaiting the caller's approval (private profiles only).
  static const String profileRequests = '/api/social/Profiles/requests';

  /// `POST /api/social/Profiles/Follow?targetId=<guid>` — follow, or send a
  /// follow request when the target is private.
  ///
  /// **Response:** `data` = `{ isFollowing, pending, followerCount }` — NOT a
  /// profile. `pending: true` means a request was raised, not that a follow
  /// edge now exists.
  static const String profileFollow = '/api/social/Profiles/Follow';

  /// `POST /api/social/Profiles/Unfollow?targetId=<guid>` — same response shape
  /// as [profileFollow]. Also withdraws a pending request.
  static const String profileUnfollow = '/api/social/Profiles/Unfollow';

  /// `POST /api/social/Profiles/AcceptRequest?followerId=<guid>`.
  static const String profileAcceptRequest =
      '/api/social/Profiles/AcceptRequest';

  /// `POST /api/social/Profiles/RejectRequest?followerId=<guid>`.
  static const String profileRejectRequest =
      '/api/social/Profiles/RejectRequest';

  /// `POST /api/social/Profiles/Block?targetId=<guid>` — blocks both ways and
  /// tears down any follow edges.
  static const String profileBlock = '/api/social/Profiles/Block';

  /// `POST /api/social/Profiles/Unblock?targetId=<guid>`.
  static const String profileUnblock = '/api/social/Profiles/Unblock';

  // ── Connections ─────────────────────────────────────────────────────────

  /// `POST /api/social/Connections/Connect?targetId=<guid>` — sends a
  /// connection request (the "add" button).
  ///
  /// **Response:** `data` = `{ connected, incoming, outgoing, connectionCount }`
  /// — `outgoing: true` is the state the button must then show, since the
  /// request exists but has not been accepted.
  static const String connectionsConnect = '/api/social/Connections/Connect';

  /// `POST /api/social/Connections/Accept?requesterId=<guid>` — accepts an
  /// inbound request. Note the parameter is the REQUESTER, not the target.
  static const String connectionsAccept = '/api/social/Connections/Accept';

  /// `POST /api/social/Connections/Ignore?requesterId=<guid>` — dismisses an
  /// inbound request.
  static const String connectionsIgnore = '/api/social/Connections/Ignore';

  /// `POST /api/social/Connections/Remove?targetId=<guid>` — removes an
  /// accepted connection, and also withdraws one still pending.
  static const String connectionsRemove = '/api/social/Connections/Remove';

  /// `POST /api/social/Connections` — a profile's accepted connections.
  ///
  /// **Request:** `{ profileId, pending?, search? }` with `?page=&size=`.
  static const String connections = '/api/social/Connections';

  /// `GET /api/social/Connections/requests?page=&size=` — inbound requests
  /// awaiting the caller.
  static const String connectionRequests = '/api/social/Connections/requests';

  // ── Professional (CV sections) ──────────────────────────────────────────

  /// `POST /api/social/Experience` — a profile's work history.
  ///
  /// **Request:** `{ profileId }` with `?page=&size=`.
  /// **Response:** `data` = `ExperienceDto[]` — raw `startDate`/`endDate`/
  /// `isCurrent`, so date-range phrasing is the client's job.
  static const String experience = '/api/social/Experience';

  /// `POST /api/social/Education` — `{ profileId }` → `EducationDto[]`.
  static const String education = '/api/social/Education';

  /// `POST /api/social/Skills` — `{ profileId }` → `SkillDto[]` with
  /// `endorsementCount` and `isEndorsedByMe`.
  static const String skills = '/api/social/Skills';

  /// `POST /api/social/Skills/Endorse?skillId=<int>` — toggle an endorsement.
  ///
  /// Note `skillId` is the row's **int** id, not the skill name — a name is not
  /// unique across profiles.
  static const String skillsEndorse = '/api/social/Skills/Endorse';

  // ── Stories ─────────────────────────────────────────────────────────────

  /// `POST /api/social/Stories` — the story rail.
  ///
  /// **Request:** `StoryFilter` — `{ authorIds?, activeOnly, followedOnly?,
  /// orderBy, descending }` — with `?page=&size=`. `activeOnly` defaults true
  /// server-side (stories expire after 24h).
  /// **Response:** `data` = `StoryDto[]` — `{ id, authorId, authorName,
  /// authorAvatarUrl, kind, mediaUrl, caption, createdAt, expiresAt,
  /// viewCount, viewedByMe }`.
  static const String stories = '/api/social/Stories';

  /// `POST /api/social/Stories/Publish` — `{ mediaUrl, kind, caption? }`.
  static const String storiesPublish = '/api/social/Stories/Publish';

  /// `POST /api/social/Stories/View?storyId=<guid>` — marks it seen.
  static const String storiesView = '/api/social/Stories/View';

  /// `POST /api/social/Stories/Like?storyId=` — toggles the caller's like.
  /// Answers `{ liked, likeCount }`.
  static const String storiesLike = '/api/social/Stories/Like';

  /// `POST /api/social/Stories/Reply` `{ storyId, content }` — sends the reply
  /// as a direct message to the story's author. Answers the conversation id.
  static const String storiesReply = '/api/social/Stories/Reply';

  /// `GET /api/social/Stories/{id}/viewers?page=&size=` — who has seen it.
  static String storyViewers(String id) => '/api/social/Stories/$id/viewers';

  // ── Reels ───────────────────────────────────────────────────────────────

  /// `POST /api/social/Reels` — filtered reel read.
  ///
  /// **Request:** `ReelFilter` — `{ authorIds?, followedOnly?, onlyLiked?,
  /// onlySaved?, search?, orderBy, descending }` with `?page=&size=`.
  /// **Response:** `data` = `ReelDto[]`.
  static const String reels = '/api/social/Reels';

  /// `GET /api/social/Reels/{id}`.
  static String reelById(String id) => '/api/social/Reels/$id';

  /// `GET /api/social/Reels/saved?page=&size=` — the caller's saved reels.
  /// Reels DO have a saved list; posts do not.
  static const String reelsSaved = '/api/social/Reels/saved';

  /// `POST /api/social/Reels/Publish` —
  /// `{ videoUrl, thumbnailUrl?, caption?, durationSeconds? }`.
  static const String reelsPublish = '/api/social/Reels/Publish';

  /// `POST /api/social/Reels/Like?reelId=<guid>` — toggles; returns the reel.
  static const String reelsLike = '/api/social/Reels/Like';

  /// `POST /api/social/Reels/Save?reelId=<guid>` — toggles; returns the reel.
  static const String reelsSave = '/api/social/Reels/Save';

  /// `POST /api/social/Reels/Share?reelId=<id>` — repost a reel to your own
  /// followers, or undo a repost. Answers the ORIGINAL reel, with its repost
  /// count and this viewer's state refreshed.
  static const String reelsShare = '/api/social/Reels/Share';

  /// `POST /api/social/Reels/Play?reelId=<guid>` — counts a play. Distinct
  /// from a view: fire it when playback starts, not when the row scrolls past.
  static const String reelsPlay = '/api/social/Reels/Play';

  /// `GET /api/social/Reels/Comments?reelId=&page=&size=` — a reel's
  /// comments, oldest first, replies included (each carries its parent).
  static const String reelsComments = '/api/social/Reels/Comments';

  /// `POST /api/social/Reels/Comment` — body `{reelId, content,
  /// parentCommentId?}`. Answers the new `ReelCommentDto`.
  static const String reelsComment = '/api/social/Reels/Comment';

  /// `DELETE /api/social/Reels/Comment/<guid>` — the comment's author or the
  /// reel's author. Its replies go with it.
  static String reelCommentById(String id) => '$reelsComment/$id';

  // ── Notifications (the activity centre) ─────────────────────────────────

  /// `POST /api/social/Notifications` — the inbox.
  ///
  /// **Request:** `NotificationFilter` — `{ unreadOnly?, descending }` with
  /// `?page=&size=`.
  /// **Response:** `data` = `NotificationDto[]` — `{ id, type, actorId,
  /// actorName, actorAvatarUrl, postId?, commentId?, text, isRead, createdAt }`.
  /// `type` arrives BY NAME (`Follow`, `Like`, `Comment`, `Mention`, …).
  static const String notifications = '/api/social/Notifications';

  /// `GET /api/social/Notifications/unread-count` — `data` = int.
  static const String notificationsUnreadCount =
      '/api/social/Notifications/unread-count';

  /// `POST /api/social/Notifications/{id}/read`.
  static String notificationRead(String id) =>
      '/api/social/Notifications/$id/read';

  /// `POST /api/social/Notifications/read-all`.
  static const String notificationsReadAll =
      '/api/social/Notifications/read-all';

  // ── Search & hashtags ───────────────────────────────────────────────────

  /// `GET /api/social/Search?q=<text>&take=<int>` — blended landing page.
  ///
  /// **Response:** `data` = `{ profiles: ProfileSimplifiedDto[], hashtags,
  /// posts: PostSimplifiedDto[], reels, jobs }` — a few of each.
  static const String search = '/api/social/Search';

  /// `GET /api/social/Search/{scope}?q=&page=&size=` — one slice, paged.
  /// `scope` is the enum NAME: `Profiles` | `Posts` | `Reels` | `Hashtags` |
  /// `Jobs`.
  static String searchScope(String scope) => '/api/social/Search/$scope';

  /// `GET /api/social/Hashtags/trending?take=<int>` —
  /// `data` = `[{ tag, postCount }]`.
  static const String hashtagsTrending = '/api/social/Hashtags/trending';

  // ── Messaging ───────────────────────────────────────────────────────────

  /// `GET /api/social/Conversations?page=&size=` — the thread list.
  ///
  /// **Response:** `data` = `ConversationDto[]` — `{ id, type, title,
  /// participants: ProfileSimplifiedDto[], lastMessagePreview, lastMessageAt,
  /// unreadCount, isMuted, isAdmin }`. A direct thread has no title; name it
  /// from the other participant.
  static const String conversations = '/api/social/Conversations';

  /// `POST /api/social/Conversations/Start` — `{ participantIds: guid[],
  /// title? }`. Returns the existing direct thread rather than duplicating it.
  static const String conversationsStart = '/api/social/Conversations/Start';

  /// `GET|POST /api/social/Conversations/{id}/messages` — history (GET,
  /// `?page=&size=`) and send (POST).
  ///
  /// **Request (POST):** `{ content, attachments?, replyToMessageId? }`.
  static String conversationMessages(String id) =>
      '/api/social/Conversations/$id/messages';

  /// `POST /api/social/Conversations/{id}/read` — clears the unread count by
  /// moving the caller's read position, which is what read state is derived
  /// from; there are no per-message receipts.
  static String conversationRead(String id) =>
      '/api/social/Conversations/$id/read';

  /// `POST /api/social/Conversations/{id}/mute?muted=<bool>`.
  static String conversationMute(String id) =>
      '/api/social/Conversations/$id/mute';

  /// `POST /api/social/Conversations/{id}/leave`.
  static String conversationLeave(String id) =>
      '/api/social/Conversations/$id/leave';

  /// `POST /api/social/Conversations/{id}/rename` — `{ title }`, admin only.
  static String conversationRename(String id) =>
      '/api/social/Conversations/$id/rename';

  /// `POST /api/social/Conversations/{id}/participants` — `{ profileIds }`.
  static String conversationParticipants(String id) =>
      '/api/social/Conversations/$id/participants';

  /// `DELETE /api/social/Conversations/{id}/participants/{profileId}`.
  static String conversationParticipant(String id, String profileId) =>
      '/api/social/Conversations/$id/participants/$profileId';

  /// `POST /api/social/Conversations/messages/{id}/edit` — `{ content }`.
  static String messageEdit(String messageId) =>
      '/api/social/Conversations/messages/$messageId/edit';

  /// `POST /api/social/Conversations/messages/{id}/retract` — unsend. Leaves a
  /// tombstone (`isRetracted`), it does not delete the row.
  static String messageRetract(String messageId) =>
      '/api/social/Conversations/messages/$messageId/retract';

  /// `POST /api/social/Conversations/messages/{id}/react` — `{ emoji }`. One
  /// reaction per person per message; reacting again replaces it.
  static String messageReact(String messageId) =>
      '/api/social/Conversations/messages/$messageId/react';

  // ── Jobs ────────────────────────────────────────────────────────────────

  /// `POST /api/social/Jobs` — job search.
  ///
  /// **Request:** `JobFilter` — `{ search?, location?, employmentType?,
  /// workplaceType?, postedById?, openOnly, orderBy, descending }` with
  /// `?page=&size=`. The two enums go BY NAME; omit a filter entirely rather
  /// than sending "all".
  /// **Response:** `data` = `JobDto[]`, including `hasApplied`.
  static const String jobs = '/api/social/Jobs';

  /// `GET /api/social/Jobs/{id}`.
  static String jobById(String id) => '/api/social/Jobs/$id';

  /// `POST /api/social/Jobs/Publish` — `JobForm`.
  static const String jobsPublish = '/api/social/Jobs/Publish';

  /// `POST /api/social/Jobs/Apply?jobId=<guid>` — `{ coverLetter?, resumeUrl? }`.
  /// `POST /api/social/Jobs/Save?jobId=<guid>` — toggles the caller's
  /// bookmark and answers the job as the server sees it afterwards.
  static const String jobsSave = '/api/social/Jobs/Save';

  static const String jobsApply = '/api/social/Jobs/Apply';

  /// `GET /api/social/Jobs/my-applications?page=&size=` —
  /// `data` = `JobApplicationDto[]`.
  static const String jobsMyApplications = '/api/social/Jobs/my-applications';

  /// `GET /api/social/Jobs/{id}/applications?page=&size=` — the poster's view
  /// of who applied, `data` = `JobApplicationDto[]` carrying the applicant's
  /// name and photo.
  ///
  /// **Poster only.** The controller compares the job's `PostedById` against
  /// the caller and answers 403 otherwise, so this is safe to link to from a
  /// company surface without the app doing its own check.
  static String jobApplications(String id) =>
      '/api/social/Jobs/$id/applications';

  /// `POST /api/social/Jobs/applications/{id}/status?status=<name>` — move an
  /// application along.
  ///
  /// The status is a QUERY parameter, not a body, and travels BY NAME:
  /// `Submitted` | `Reviewed` | `Shortlisted` | `Interviewing` | `Rejected` |
  /// `Accepted`. Do not send an ordinal — the server's numbering puts
  /// `Rejected` before `Accepted`, the opposite of the app's enum, so an index
  /// would silently accept someone the company rejected.
  /// **Response:** `data` = `true`.
  static String jobApplicationStatus(String applicationId) =>
      '/api/social/Jobs/applications/$applicationId/status';

  // ── Engineering disciplines ─────────────────────────────────────────────

  /// `GET /api/social/Disciplines` — the engineering disciplines (الاختصاص) a
  /// profile can choose from, in the tenant's order.
  ///
  /// **Anonymous-safe on purpose**, like the storage zone: the profile step of
  /// sign-up offers the list before there is an account. `?includeInactive=true`
  /// is admin-only and answers 403 to everyone else.
  ///
  /// **Response:** `data` = `[{ id, nameAr, nameEn, iconUrl, sortOrder,
  /// isActive }]`, where `iconUrl` is host-less like every other upload.
  ///
  /// `POST` creates one and `PUT /{id}` edits it — both admin only.
  static const String disciplines = '/api/social/Disciplines';

  /// `PUT /api/social/Disciplines/{id}` — rename, reorder, switch on or off, or
  /// set the logo. Only the fields sent are changed; an empty `iconUrl` clears
  /// the logo. Admin only.
  static String discipline(int id) => '/api/social/Disciplines/$id';

  /// `GET /api/social/Governorates` — the governorates (المحافظة) a profile can
  /// choose from, in the tenant's order. **Anonymous-safe**, like the
  /// disciplines list and for the same reason.
  ///
  /// **Response:** `data` = `[{ id, nameAr, nameEn, sortOrder, isActive }]`.
  ///
  /// `POST` creates one and `PUT /{id}` edits it — both admin only.
  static const String governorates = '/api/social/Governorates';

  // No client-side write helper: the app reads this list and the server's
  // admin POST/PUT are reachable from the API for whoever curates it. Add one
  // here alongside a governorates admin screen if that moves into the app.

  // ── Tenant settings (admin) ─────────────────────────────────────────────

  /// `GET` / `PUT /api/social/Settings/FeedRanking` — the tenant's feed-ranking
  /// weights. Admin only (the JWT's `UserType` is `Admin` / `SystemAdmin`);
  /// anyone else gets 403.
  ///
  /// **Request (PUT):** `{ affinityWeight, recencyWeight, recencyHalfLifeHours,
  /// engagementWeight, unseenBonus, authorRepeatPenalty,
  /// candidateOverfetchFactor, newsFeedRowTtlDays }` — validated server-side.
  /// **Response:** `data` = the same shape, as saved.
  static const String settingsFeedRanking = '/api/social/Settings/FeedRanking';

  /// `GET` / `PUT /api/social/Settings/PanelAccess` — who the engineer panel is
  /// open to: whether it is gated at all, the trial length, and which sections
  /// are free regardless. Admin only; anyone else gets 403.
  ///
  /// **Request (PUT):** `{ subscriptionRequired, trialDays, freeSections[] }`,
  /// where a section is a `PlanFeatureEnum` NAME (`"TheoryCourses"`).
  /// **Response:** `data` = the same shape, as saved.
  static const String settingsPanelAccess = '/api/social/Settings/PanelAccess';

  // ── Kernel generic write ────────────────────────────────────────────────

  /// `POST /api/GenericWrite/Save` — the Kernel's generic create/update/delete
  /// engine. **Not** under the `social` prefix: it is host-level, wired by
  /// `AddRoboByteKernelContext<SocialMediaDbContext>()`.
  ///
  /// The module exposes no profile-update endpoint, so editing the signed-in
  /// user's own profile goes through here.
  ///
  /// **Request:** `[{ model: "ProfileModel", id, writeType: "Update",
  /// fields: { <column>: <value>, … } }]` — a LIST of forms. `writeType` is
  /// serialised BY NAME: `Create` | `Update` | `SoftDelete` | `PermanentDelete`
  /// (and the enum is 1-based, so sending an ordinal is doubly easy to get
  /// wrong). `fields` keys are `ProfileModel`'s column names, not the DTO's.
  /// **Response:** `data` = the affected row ids.
  ///
  /// It writes any column you name, with no module-level validation — send only
  /// the fields the user edited.
  static const String genericWriteSave = '/api/GenericWrite/Save';

  // ── Media storage ───────────────────────────────────────────────────────

  /// `GET /api/social/Storage/Zone` — the Bunny.net zone this tenant's photo
  /// uploads go to.
  ///
  /// **Response:** `data` = `{ name, password, storageHostname, pullZoneUrl,
  /// folder }`, or `error: true` with "Storage is not configured…" when the
  /// tenant has no zone — which is the signal to hide the photo control rather
  /// than to retry.
  ///
  /// Why a round-trip instead of a constant: the zone's write password used to
  /// be compiled into the app, so rotating it (or leaking it) meant a release.
  /// Held server-side it is per tenant and revocable, and the client only ever
  /// borrows it for the duration of a PUT.
  ///
  /// **Anonymous-safe on purpose** — sign-up uploads the profile photo before
  /// an account exists, so this is fetched with `X-Tenant-Id` when there is no
  /// bearer yet, exactly like login and sign-up.
  static const String storageZone = '/api/social/Storage/Zone';

  /// `GET /api/social/Storage/Stream` — the Bunny **Stream** video library
  /// reels are published to.
  ///
  /// **Response:** `data` = `{ libraryId, apiKey, cdnHostname }`, or
  /// `error: true` with "Video streaming is not configured on this server."
  ///
  /// Stream rather than the storage zone because a storage zone serves a file
  /// byte for byte: it has no poster frame to offer. Stream transcodes on
  /// ingest and publishes a thumbnail at a predictable path, which is the only
  /// way a reel can show a still while its video buffers.
  static const String streamLibrary = '/api/social/Storage/Stream';

  // ── Engineer dashboard ──────────────────────────────────────────────────

  /// `GET /api/social/Dashboard` — the engineer panel summary: the
  /// continue-learning card, the headline stats, and the per-section "new
  /// course" counts.
  ///
  /// **Under the module prefix, like everything else here.** This was
  /// `/api/dashboard` for a while and answered 404: the module declares
  /// `[Route("api/[controller]")]` and the Kernel's `AddModuleRoutePrefix`
  /// puts `social` in front of it.
  ///
  /// **Response:** a `ResultViewModel` envelope whose `data` is the summary —
  /// NOT the bare DTO it used to be, because it is a module controller now.
  static const String dashboard = '/api/social/Dashboard';

  // ── Subscription ────────────────────────────────────────────────────────

  /// `GET /api/social/Subscription` — whether the panel is gated, whether this
  /// caller is through it and why, what they hold, and the plans on offer.
  ///
  /// Ungated deliberately: it is how somebody WITHOUT a subscription finds out
  /// what one costs.
  static const String subscription = '/api/social/Subscription';

  /// `POST /api/social/Subscription/{planId}/Start/{cycle}` — requests a
  /// subscription on a plan, at one of its billing cycles. Creates a pending
  /// row; grants nothing until it is activated.
  ///
  /// The cycle is a path segment, not an optional query value: the server
  /// refuses to default it, because monthly and annual differ by an order of
  /// magnitude and quietly charging the wrong one is not a recoverable
  /// mistake. [cycle] is the enum's wire name — use
  /// `PlanPriceDto.wireName(...)`.
  static String subscriptionStart(String planId, String cycle) =>
      '/api/social/Subscription/$planId/Start/$cycle';

  /// `GET|POST /api/social/Subscription/{planId}/Change/{cycle}` — moving a
  /// RUNNING term to a different plan or cycle.
  ///
  /// GET prices it and changes nothing; POST requests it. The unused part of the
  /// current term is revalued at the new plan's rate and carried across as days.
  /// Same path for both, because they are one question asked twice — once to
  /// show the subscriber, once to act on — and a client that learnt only half
  /// of a split pair would be quoting from one rule and buying under another.
  static String subscriptionChange(String planId, String cycle) =>
      '/api/social/Subscription/$planId/Change/$cycle';

  /// `POST /api/social/Subscription/Cancel` — a paid term still runs to its
  /// end date, so this rarely closes access immediately.
  static const String subscriptionCancel =
      '/api/social/Subscription/Cancel';

  /// `POST /api/social/Subscription/AutoRenew` — `{ enabled }`. Applies to the
  /// current term; cancelling forces it off server-side.
  static const String subscriptionAutoRenew =
      '/api/social/Subscription/AutoRenew';

  // ── Panel: courses ──────────────────────────────────────────────────────

  /// `POST /api/social/Courses` — the catalogue, filtered.
  ///
  /// **Request:** `CourseFilter` — `{ id?, category?, search?, enrolledOnly? }`
  /// with `?page=&size=`. `category` goes BY NAME: `Theory` | `Practical` |
  /// `Training`; omit it for all three.
  /// **Response:** `data` = `CourseDto[]`, each carrying the caller's own
  /// `isEnrolled` / `currentLecture` / `minutesWatched`, so a card renders a
  /// progress bar without a second request.
  static const String courses = '/api/social/Courses';

  /// `POST /api/social/Courses/{id}/Enroll` — idempotent; enrolling twice
  /// returns the existing row rather than failing.
  /// `GET /api/social/Courses/{id}/Lectures` — the course's lectures in order.
  ///
  /// A GET rather than a filter POST like the catalogue: there is nothing to
  /// filter by. Anything this caller may not watch arrives with a null
  /// `videoUrl`, so the padlock the screen draws is a label for a lock that was
  /// already applied server-side.
  static String courseLectures(String id) => '/api/social/Courses/$id/Lectures';

  static String courseEnroll(String id) => '/api/social/Courses/$id/Enroll';

  /// `POST /api/social/Courses/{id}/Progress` — `{ currentLecture,
  /// minutesWatched }`.
  ///
  /// Both figures are ABSOLUTE, not deltas, and the server only ever moves
  /// them forward — a retry or a stale screen cannot rewind progress or
  /// subtract hours. Completion and the certificate are derived server-side.
  static String courseProgress(String id) => '/api/social/Courses/$id/Progress';

  /// `POST /api/social/Courses/{id}/Rate` — `{ stars, comment? }`. Rating again
  /// edits rather than stacks, and the server refuses it without enrolment.
  static String courseRate(String id) => '/api/social/Courses/$id/Rate';

  // ── Panel: the course marketplace ───────────────────────────────────────
  //
  // Authoring, review and purchase. Three different callers on one controller,
  // separated by route rather than by header: `Mine/…` is the author's,
  // `Purchases/…` is the money, and `Approve`/`Reject`/`Commerce` (on PUT) are
  // admin-gated server-side on the token's UserType claim.

  /// `POST` — creates or edits one of this viewer's own courses.
  static const String courseSaveMine = '/api/social/Courses/Mine/Save';

  /// `POST` adds or edits a lesson; `DELETE …/{lessonId}` removes one.
  static String courseLessons(String id) => '/api/social/Courses/$id/Lessons';

  static String courseLesson(String id, String lessonId) =>
      '/api/social/Courses/$id/Lessons/$lessonId';

  /// `POST` — hands the course to the reviewer.
  static String courseSubmit(String id) => '/api/social/Courses/$id/Submit';

  /// `POST` — admin only. Fixes the commission and publishes.
  static String courseApprove(String id) => '/api/social/Courses/$id/Approve';

  /// `POST` — admin only. Sends it back; the reason is required.
  static String courseReject(String id) => '/api/social/Courses/$id/Reject';

  /// `POST` — asks to buy. Creates a pending row; an administrator confirms
  /// the money separately, and only that opens the course.
  static String coursePurchase(String id) => '/api/social/Courses/$id/Purchase';

  /// `POST` — the administrator's queue over the whole tenant.
  static const String coursePurchases = '/api/social/Courses/Purchases';

  /// `POST` — this viewer's own purchases.
  static const String coursePurchasesMine =
      '/api/social/Courses/Purchases/Mine';

  /// `POST` — what this viewer has earned from courses they wrote.
  static const String coursePurchaseEarnings =
      '/api/social/Courses/Purchases/Earnings';

  static String coursePurchaseConfirm(String id) =>
      '/api/social/Courses/Purchases/$id/Confirm';

  static String coursePurchaseCancel(String id) =>
      '/api/social/Courses/Purchases/$id/Cancel';

  /// `GET` reads the commission default and the subscriber discount; `PUT`
  /// writes them, admin only.
  static const String courseCommerce = '/api/social/Courses/Commerce';

  // ── Panel: notes ────────────────────────────────────────────────────────

  /// `GET /api/social/Notes` — the caller's own notes, newest first.
  static const String notes = '/api/social/Notes';

  /// `POST /api/social/Notes/Save` — `{ id?, title, body }`. Creates when `id`
  /// is absent, updates when present; an id belonging to someone else simply
  /// does not resolve.
  static const String notesSave = '/api/social/Notes/Save';

  /// `POST /api/social/Notes/{id}/Delete` — soft delete.
  static String noteDelete(int id) => '/api/social/Notes/$id/Delete';

  // ── Panel: reference documents ──────────────────────────────────────────

  /// `GET /api/social/Documents?category=<name>&search=` — the engineering
  /// library and the legal-affairs shelf are one endpoint told apart by
  /// `category`: `Library` | `LegalAffairs`, BY NAME.
  ///
  /// **Response:** `data` = `DocumentDto[]`; `fileUrl` is host-less and goes
  /// through `imageUrlResolverProvider` like every other stored asset.
  static const String documents = '/api/social/Documents';

  // ── Panel: legal requests ───────────────────────────────────────────────

  /// `GET /api/social/LegalRequests` — the caller's own requests, newest
  /// first. `POST` to the same path submits one: `{ subject, body }`.
  static const String legalRequests = '/api/social/LegalRequests';

  // ── Panel: assistant ────────────────────────────────────────────────────

  /// `GET /api/social/Assistant` — the caller's conversations, most recent
  /// first. Messages are empty on this read.
  static const String assistant = '/api/social/Assistant';

  /// `GET /api/social/Assistant/{id}` — one conversation with its transcript.
  static String assistantConversation(String id) => '/api/social/Assistant/$id';

  /// `POST /api/social/Assistant/Send` — `{ conversationId?, text }`.
  ///
  /// A null `conversationId` starts a new conversation titled from the
  /// message, so the first send is one round trip. The response is the whole
  /// conversation including the reply.
  ///
  /// **The reply is a server-side placeholder** until a model is wired in —
  /// see `AssistantService.ComposeReply`.
  static const String assistantSend = '/api/social/Assistant/Send';
}
