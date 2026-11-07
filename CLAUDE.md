# Rung مهندس — Conventions (Riverpod, Clean Architecture, multi-flavor)

Machine-readable rules for AI code assistants (Claude, Copilot, Cursor). Human-facing versions live in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

**Before generating any code for this repo, load `docs/ARCHITECTURE.md`.** Every rule below is a summary; the doc is authoritative.

**This repo now hosts the Rung app** — an Arabic-first (RTL) professional network for engineers. Read [docs/RUNG.md](docs/RUNG.md) for the screen/route/feature map, the design-token vocabulary, mock mode, and the backend contract asks.

## Rung-specific rules

- **UI is RTL and Arabic-first.** Default locale is `ar`; use directional widgets (`PositionedDirectional`, `EdgeInsetsDirectional`) rather than left/right.
- **Read colours off `context.rung`** (the `RungColors` theme extension) — never hard-code a hex value in a feature.
- **Compose from `core/widgets/rung/`** before writing a new widget: `RungAvatar`, `RungCard`, `RungGroupedCard`, `RungNavRow`, `RungFilterChip`, `RungTagChip`, `RungStatusPill`, `StatusStepper`, `RungSearchField`, `RungField`, `RungToggleTile`, `showRungToast`.
- **Never re-declare `fontFamily`** — IBM Plex Sans Arabic is set once on the theme.
- **Render counts through `ArabicNumbers`** and relative times through `relativeTimeArabic` — `intl`'s `ar` locale emits Western digits and gets Arabic's dual form wrong.
- **Mock repositories live beside their REST twin** (`data/repositories/<foo>_mock_repository.dart`) and are wired in `lib/mocks/mock_overrides.dart`, gated on `AppConfig.useMockData`.

## TL;DR

- **Architecture:** Clean Architecture, 3 layers (domain → data → presentation). Outer depends on inner; inner knows nothing about outer.
- **State:** Riverpod (`flutter_riverpod`). No other state libraries.
- **Structure:** feature-first, NOT layer-first. Each feature owns its own `data/`, `domain/`, `presentation/`.
- **Flavors:** `dev`, `staging`, `prod`. Each has its own `lib/flavors/main_<env>.dart` entrypoint.
- **API:** single `Dio` via `ApiClient`. All requests go through interceptors (client-key, signing, device headers, auth, error mapping).
- **Errors:** `Result<T, AppException>` from every repository. No `null`-on-failure. No empty catch blocks.
- **UI error text:** `arabicMessageForException(e)` — never leak raw backend text.

## AI generation rules (hard)

1. Never `print(...)`. Use `debugPrint` guarded by `kDebugMode`, or `AppLogger`.
2. Never `Get.find(...)` or any GetX API.
3. Never inline URL strings. Add the path to `EndPoints` first.
4. Never write empty `catch { }` blocks — log or map + return `Result.failure(...)`.
5. Never write a background message handler that touches Riverpod, GoRouter, or any controller.
6. Never read `String.fromEnvironment(...)` at call sites — go through `appConfigProvider`.
7. Never return `null` from a repository on failure — return `Result.failure(AppException...)`.
8. Never leak raw backend error text to the UI — pass through `arabicMessageForException` / `arabicErrorFor`.
9. Always null-check notification payload fields (`data['id'] ?? ''`).
10. Always cancel `StreamSubscription`s and `Timer`s via `ref.onDispose`.
11. Always resolve environment from `appConfig` (already set before `runApp`).
12. Never modify locked infrastructure files (see docs/ARCHITECTURE.md §19) without user approval.
13. Never add emojis to code or commits unless the user explicitly asks.

## Locked infrastructure — DO NOT modify when building features

- `lib/core/api/api_client.dart`
- `lib/core/api/interceptors/*`
- `lib/core/api/request_signing.dart`
- `lib/core/api/token_refresher.dart`
- `lib/core/error/result.dart`
- `lib/core/error/app_exception.dart`
- `lib/core/storage/token_storage.dart`
- `lib/core/config/app_config.dart`
- `lib/features/shared/notifications/data/firebase_background_handler.dart`

If a feature seems to require editing one of these, stop and ask the user.

## Adding a feature (7 artefacts, in order)

1. **Domain entity** — `lib/features/<feature>/domain/entities/<foo>.dart`. Pure Dart, extends `BaseEntity`.
2. **Repository interface** — `lib/features/<feature>/domain/repositories/<foo>_repository.dart`. Extends `BaseRepository<Foo>`.
3. **DTO** — `lib/features/<feature>/data/dtos/<foo>_dto.dart`. Implements `BaseDto<Foo>` (fromJson + toJson + toDomain).
4. **Repository impl + provider** — `lib/features/<feature>/data/repositories/<foo>_repository_impl.dart`. `RestRepository<Foo, FooDto>` for plain REST.
5. **Notifier + provider** — `lib/features/<feature>/presentation/notifiers/<foo>_notifier.dart`. Extends `BaseListNotifier<Foo>` or `BaseItemNotifier<Foo, Arg>`.
6. **Screen** — `lib/features/<feature>/presentation/screens/<foo>_screen.dart`. Reads via `ref.watch`; `AsyncValue.when(loading, error, data)`; uses `LoadingView` + `ErrorView`.
7. **Endpoint constant** — add to `EndPoints` with a full doc-comment (verb / request / response / failure).

Then: tests per docs/ARCHITECTURE.md §15.

See docs/ADDING_A_FEATURE.md for a worked example.
