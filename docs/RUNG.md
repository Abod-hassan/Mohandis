# Rung (رنق) — app implementation notes

Arabic-first (RTL) professional network for engineers, built on this template's
Clean Architecture + Riverpod stack. Source of truth for the UI is the Claude
Design project `Rung Screens.dc.html` / `Rung.dc.html` and its style guide.

Everything currently runs on seeded in-memory repositories. See
[Mock mode](#mock-mode) for how to move a feature onto the real API.

## Design system

| Concern | Where |
|---|---|
| Colour tokens (light + dark parity) | [`lib/core/theme/rung_colors.dart`](../lib/core/theme/rung_colors.dart) — a `ThemeExtension`, read via `context.rung` |
| Type scale, spacing, radii, elevation, motion, gradients | [`lib/core/theme/rung_tokens.dart`](../lib/core/theme/rung_tokens.dart) |
| Material theme assembly | [`lib/core/theme/app_theme.dart`](../lib/core/theme/app_theme.dart) |
| Light/dark preference | `themeModeProvider` — persisted in `SharedPreferences` |
| Widget kit | [`lib/core/widgets/rung/`](../lib/core/widgets/rung/) — avatars, badges, chips, cards, grouped rows, stepper, inputs, toast, app bar |

Token names mirror the design system 1:1 (`--surface-2` → `surface2`), so a
design change traces straight to code. Font is **IBM Plex Sans Arabic**,
bundled in `assets/fonts/` and set once on the theme — call sites never
re-declare `fontFamily`.

The family tops out at Bold (700); the design's w800 headings map onto it.

## Screen → route → feature map

Nineteen screens from the design, all implemented.

| # | Screen | Route | Feature |
|---|---|---|---|
| 01 | شاشة الدخول | `/auth` | `shared/auth` |
| 02 | الخلاصة | `/feed` | `posts` |
| 03 | تفاصيل المنشور | `/feed/posts/:postId` | `posts` |
| 04 | محرر المنشور | `/feed/composer` | `posts` |
| 05 | عارض القصص | `/feed/stories/:storyId` | `stories` |
| 06 | مشغّل الريلز | `/reels` | `reels` |
| 07 | الملف الشخصي | `/profile/:personId` | `profile` |
| 08 | تعديل الملف | `/profile/me/edit` | `profile` |
| 09 | شبكتي | `/network` | `network` |
| 10 | البحث | `/search` | `search` |
| 11 | الإشعارات | `/notifications` | `activity` |
| 12 | الرسائل | `/messages` | `messaging` |
| 13 | المحادثة | `/messages/:threadId` | `messaging` |
| 14 | قائمة الوظائف | `/jobs` | `jobs` |
| 15 | تفاصيل الوظيفة | `/jobs/:jobId` | `jobs` |
| 16 | مسار التقديم | `/jobs/:jobId/apply` | `jobs` |
| 17 | طلباتي | `/jobs/applications` | `jobs` |
| 18 | لوحة المهندس | `/dashboard` | `dashboard` |
| — | الشاشة الافتتاحية | `/splash` | `shared/auth` |

`shared/people` owns the `Person` directory that feed, messaging, network,
search, and profile all resolve author / participant ids through.

### Navigation shape

`StatefulShellRoute.indexedStack` with five branches — الرئيسية / ريلز / لوحتي /
الوظائف / شبكتي — each keeping its own stack and scroll position. Every other
screen pushes on the **root** navigator, so the bottom nav is hidden while it
is open.

**Deviation from the prototype:** the prototype keeps the nav bar visible on
the profile, search, messages, notifications, and my-applications screens, and
hides it on reels. This build does the opposite on both counts:

* Those five screens push over the shell (nav hidden). They all already carry a
  back button in the design, so nothing becomes unreachable, and it avoids
  duplicating shared sub-routes under all five branches.
* Reels **keeps** the nav bar, rendered translucent over the video. Hiding it on
  a primary tab would trap the user with no way back.

Flag either if you want the prototype's exact behaviour instead.

## Localization

Arabic is the authoritative catalogue ([`lib/l10n/app_ar.arb`](../lib/l10n/app_ar.arb));
English mirrors it. Regenerate after editing either:

```bash
flutter gen-l10n
```

Access strings via `context.l10n.<key>` (the extension lives in
`lib/l10n/l10n.dart`). Mock content — post bodies, job descriptions, person
names — is data, not UI copy, and stays in the mock repositories.

Counts render through `ArabicNumbers` (`٤٬٢٠٨`, `٦٢٪`) because `intl`'s `ar`
locale emits Western digits. Relative times use `relativeTimeArabic`, which
honours Arabic's dual form (`ساعتان`, `يومان`) that a plain `{n} hours`
template gets wrong.

## Mock mode

`AppConfig.useMockData` is `true` in the dev flavor. `bootstrap` then applies
[`lib/mocks/mock_overrides.dart`](../lib/mocks/mock_overrides.dart), swapping
every repository provider for an in-memory twin seeded with the design's
Arabic content. Mutations (likes, saves, reposts, new posts, comments, sent
messages, applications, endorsements) persist for the session.

Auth deliberately keeps the **real** `TokenStorage`, so the splash gate, router
redirect, refresh path, and logout all exercise production code.

To move one feature onto the real API, delete its line from `mockOverrides()`.

```bash
flutter run --target lib/flavors/main_dev.dart      # mock data, no backend
flutter run --target lib/flavors/main_staging.dart  # real API
flutter run --target lib/flavors/main_prod.dart
```

## Backend asks

Every endpoint is declared with a full doc-comment in
[`lib/core/api/endpoints.dart`](../lib/core/api/endpoints.dart) — verb, request,
response, and failure shape per ARCHITECTURE.md §7.2. Contracts worth
confirming before the API is built:

1. **Preformatted display strings.** `Job.salaryLabel` ("١٥٠ – ١٨٥ ألف دولار")
   and `Experience.dates` ("٢٠٢٢ — الآن · ٣ سنوات") arrive ready to render.
   Range, currency, and duration phrasing vary per market and the client must
   not re-derive them.
2. **Company/school monograms** come from the backend (`Job.monogram`). The
   client does not guess how to abbreviate a name.
3. **Engagement toggles return the authoritative record.** `POST
   /api/posts/{id}/like` responds with the whole post so the optimistic update
   can be reconciled rather than trusted.
4. **Jobs filters omit "all".** `work` is dropped from the query entirely when
   unset — never sent as `work=all`.
5. **`409` on duplicate apply** is mapped to a `ValidationException` so the UI
   shows copy instead of a generic server error.
6. **Unknown enum values must not break old clients.** `visibility`,
   `workMode`, `employmentType`, application `status`, and activity `type` all
   fall back to a safe default on parse.
7. **Media and video URLs are nullable today.** Posts, stories, and reels
   render deterministic gradient placeholders keyed on the entity id until the
   uploads service exists.

## What is deliberately not built

These surfaces exist in the design as affordances only; each confirms with a
"قريباً" toast rather than silently doing nothing:

* Composer attachments (image, document, hashtag, poll, mention).
* Résumé file picking in the apply flow — the CV on file is fixed.
* Reel comments and sharing; story replies.
* Message search, new-conversation composer, thread attachments.
* Hashtag result pages behind trending tags.
* Saved-items, profile cover photo, and CV download.
* The engineering library (`قريباً` by design), and the dashboard's learning
  and legal destinations, which need their own feature specs.
