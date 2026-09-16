# Architecture Blueprint

Single-source-of-truth reference for building this project — and for scaffolding future projects on the same template. Every rule below is normative: **SHALL** rules must be met before code lands; **SHALL NOT** rules must not appear in code at all.

This document supersedes the previously separate `CONVENTIONS.md` content — that file is retained as a lightweight quick-reference only.

## Table of contents

  1. [Guiding principles](#1-guiding-principles)
  2. [Layer contract](#2-layer-contract)
  3. [Folder structure](#3-folder-structure)
  4. [Boot sequence](#4-boot-sequence)
  5. [State management (Riverpod)](#5-state-management-riverpod)
  6. [Networking](#6-networking)
  7. [Endpoints & backend contracts](#7-endpoints--backend-contracts)
  8. [Authentication & session persistence](#8-authentication--session-persistence)
  9. [Error handling & error localization](#9-error-handling--error-localization)
  10. [Flavors](#10-flavors)
  11. [Security, signing & credentials](#11-security-signing--credentials)
  12. [Notifications](#12-notifications)
  13. [Base classes](#13-base-classes)
  14. [Adding a feature (recipe)](#14-adding-a-feature-recipe)
  15. [Testing](#15-testing)
  16. [Localization](#16-localization)
  17. [Logging](#17-logging)
  18. [Naming conventions](#18-naming-conventions)
  19. [Locked infrastructure](#19-locked-infrastructure)
  20. [AI-assistant generation rules](#20-ai-assistant-generation-rules)
  21. [Setup checklist](#21-setup-checklist)

Appendices:
  * [A. Interceptor execution order](#appendix-a-interceptor-execution-order)
  * [B. Endpoint namespace mapping](#appendix-b-endpoint-namespace-mapping)
  * [C. Error subtype ladder](#appendix-c-error-subtype-ladder)
  * [D. TokenStorage keyspace](#appendix-d-tokenstorage-keyspace)

---

## 1. Guiding principles

  1.1. **Clean Architecture, feature-first.** Three layers per feature (domain / data / presentation), one folder per feature. Never organise by layer at the top level.

  1.2. **Riverpod is the only state framework.** No GetX, no `package:provider`, no BLoC, no plain `setState` outside trivial widget-local UI state.

  1.3. **Every repository returns `Result<T, AppException>`.** Never `null` on failure. Never `throw` up to the presentation layer.

  1.4. **Explicit dependencies.** No service locators, no static globals, no `Get.find()`. All wiring goes through Riverpod providers.

  1.5. **The domain layer runs in a pure Dart console.** Domain must not import Flutter, Dio, Firebase, or Riverpod. If it does, the boundary is broken.

  1.6. **The data layer owns the wire format.** DTOs live in data, entities live in domain. Even when they look identical, they are separate classes.

  1.7. **The presentation layer never touches the network.** Widgets and notifiers reach the network only through a repository provider.

  1.8. **Local additive changes over refactors.** A bug fix does not need a rewrite. A feature does not need surrounding cleanup unless the cleanup is what the ticket is about.

---

## 2. Layer contract

  2.1. **Import table (SHALL be enforced by code review):**

| Layer | May import | Must NOT import |
|-------|------------|-----------------|
| Domain | pure Dart only | Flutter, Dio, Firebase, Riverpod, DTOs |
| Data | Domain, Dio, Firebase, storage | Flutter widgets, Riverpod (except the provider file that exposes the repo), `presentation/*` |
| Presentation | Domain, Riverpod, Flutter, GoRouter | Dio, `ApiClient`, DTOs, `data/repositories/*` implementations directly |

  2.2. **Data → Domain is the only inward-facing edge.** Data implements domain interfaces; domain never knows the implementation exists. The Riverpod provider that binds the two lives in the data layer's provider file.

  2.3. **Presentation reads state, triggers intent.** Widgets read via `ref.watch(...)`, trigger via `ref.read(...notifier).someMethod()`. Widgets do not construct DTOs or map JSON.

  2.4. **The "pure Dart console" test.** If you cannot copy `lib/features/<foo>/domain/` into a plain Dart CLI project and have it compile, a boundary is broken.

---

## 3. Folder structure

  3.1. **Canonical tree:**

```
lib/
  core/                       # cross-cutting infrastructure — SHALL NOT hold feature code
    api/                      # Dio client + interceptors + endpoints + signing
      interceptors/
    base/                     # BaseEntity / BaseDto / BaseRepository / notifiers
    config/                   # AppConfig + Environment + AppType
    error/                    # AppException sealed hierarchy + Result<T,E>
    router/                   # GoRouter setup
    services/                 # DeviceInfoService, AppLogger, etc.
    storage/                  # TokenStorage
    theme/                    # theme tokens, colors, typography
    utils/                    # pure helpers (error_messages, countries, phone format, …)
    widgets/                  # LoadingView, ErrorView, shared reusable widgets
    providers.dart            # global providers (apiClient, tokenStorage, appConfig, …)
  features/                   # one folder per feature
    <feature>/
      data/
        dtos/
        repositories/
      domain/
        entities/
        repositories/         # repository *interfaces*
      presentation/
        notifiers/
        screens/
        widgets/              # feature-scoped widgets
    shared/                   # cross-flavor features (auth, notifications, file upload, …)
    customer/                 # customer-flavor-only features
    sales/                    # sales-flavor-only features
  flavors/                    # per-flavor entrypoints
    customer/
      main_dev.dart
      main_prod.dart
    sales/
      main_dev.dart
      main_prod.dart
  l10n/                       # .arb files (generate: true in pubspec)
  app.dart                    # MaterialApp.router
  bootstrap.dart              # shared entrypoint, called from each flavor
  main.dart                   # default → customer dev flavor
```

  3.2. **Feature-first, never layer-first.** There SHALL NOT be a top-level `repositories/`, `screens/`, or `dtos/` directory.

  3.3. **Every feature carries the same three-folder structure**, even if `presentation/widgets/` is empty at day one.

  3.4. **`shared/` is for features used by more than one flavor.** Anything used by exactly one flavor lives under `customer/` or `sales/`.

---

## 4. Boot sequence

  4.1. **Entry path:** `main.dart` → `flavors/<flavor>/main_<env>.dart` → `bootstrap(config)`.

  4.2. **`bootstrap()` SHALL:**
      a. Call `WidgetsFlutterBinding.ensureInitialized()`.
      b. Initialize Firebase (if used) at the top level — never inside a notifier.
      c. Register the notification background handler (see §12).
      d. Call `runApp(ProviderScope(overrides: [...], child: App()))`.

  4.3. **Provider overrides at bootstrap SHALL include at minimum:**
      * `appConfigProvider` → the flavor's `AppConfig` instance.
      * `tokenRefresherProvider` → a real `AuthTokenRefresher` bound to the correct refresh path for the flavor.
      * Any mock overrides gated behind `AppConfig.useMockData`.

  4.4. **Cold-start UI gate: `SplashScreen` SHALL block navigation until both:**
      a. `systemSettingsNotifierProvider` has resolved (data or cached fallback), AND
      b. `authNotifierProvider` has resolved (either a valid session or definitive signed-out).

      It SHALL also enforce a minimum display window (default 1.6 s) so the splash isn't a flash.

  4.5. **Signing-bootstrap SHALL fire during the splash** (best-effort, non-blocking). It provisions the per-device signing secret before any authenticated request needs it.

  4.6. **Router redirect SHALL be driven by `authNotifierProvider`.** Use `refreshListenable: AuthRefreshNotifier(ref)` on the `GoRouter` and re-evaluate `isAuthed` inside `redirect` on every navigation event.

---

## 5. State management (Riverpod)

  5.1. **Riverpod-only.** SHALL NOT import GetX, `package:provider`, BLoC, or any other state framework.

  5.2. **Global providers** — `apiClientProvider`, `tokenStorageProvider`, `appConfigProvider`, `tokenRefresherProvider`, `loggerProvider`, `deviceInfoServiceProvider` — live in [`lib/core/providers.dart`](../lib/core/providers.dart) and nowhere else.

  5.3. **Feature providers live with the feature.** Convention: co-locate the repository provider next to the impl file (`data/repositories/foo_repository_impl.dart`) and the notifier provider next to the notifier (`presentation/notifiers/foo_notifier.dart`).

  5.4. **Auto-dispose is the default.** Persist a provider (`Provider<T>` without auto-dispose) only when the state must outlive the screen that read it (e.g. `authNotifierProvider`, `activeShopProvider`).

  5.5. **One source of truth.** A given piece of state SHALL live in exactly one provider. Copying it into a second provider for convenience is a bug in disguise.

  5.6. **Mutations invalidate, don't patch.** After a server mutation succeeds, call `ref.invalidateSelf()` (or invalidate the specific dependent provider) instead of hand-editing local state.

  5.7. **Never call Riverpod from a background isolate.** Background handlers write to `SharedPreferences`; the main isolate drains the queue on foreground resume (see §12).

  5.8. **Every `StreamSubscription` and `Timer` SHALL be cancelled via `ref.onDispose`.**

  5.9. **Notifiers longer than ~200 lines are a smell.** Split by responsibility.

  5.10. **Widgets read via `ref.watch`, trigger via `ref.read(...notifier)`.** They handle all three `AsyncValue` branches — never `value!`.

---

## 6. Networking

  6.1. **Exactly one `Dio` instance app-wide**, exposed as `apiClientProvider`. Repositories reach it via `ref.watch(apiClientProvider).dio`. SHALL NOT construct a second `Dio` in a repository.

  6.2. **The only exception** is `AuthTokenRefresher`, which owns a bare `Dio` (no `AuthInterceptor`) to break the `apiClient → refresher → apiClient` cycle. It still carries `ClientKeyInterceptor` so backend `X-KEY` validation succeeds. See §8.

  6.3. **Interceptor chain (order matters — see Appendix A):**
      1. `ClientKeyInterceptor` — adds `X-KEY`.
      2. `RequestSigningInterceptor` — adds `X-Request-Key` + `X-Request-ID`.
      3. `DeviceHeaderInterceptor` — adds device + app metadata headers.
      4. `ActiveShopInterceptor` — adds `X-Active-Shop-Id` (customer flavor only).
      5. `AuthInterceptor` — adds `Authorization: Bearer`, handles 401 refresh + retry.
      6. `ErrorMappingInterceptor` — maps `DioException` → `AppException`.
      7. `LogInterceptor` — debug builds only.

  6.4. **Every request gets every header automatically.** Repositories SHALL NOT set `Authorization`, `X-KEY`, `X-Request-Key`, `X-Request-ID`, or any `X-Device-*` header by hand.

  6.5. **Endpoint constants live in `EndPoints` / `MobileEndpoints`.** Repositories SHALL NOT inline a URL string, ever. Every constant carries a doc comment stating: verb, request body shape, response envelope, and failure body shape.

  6.6. **`unauthenticatedPaths` in `AuthInterceptor` SHALL enumerate every route that:**
      * accepts anonymous requests (`login`, `refresh`, `signing-bootstrap`, `register-*`, OTP endpoints, forgot-password), OR
      * MUST NOT be replayed by the 401-refresh-retry loop (e.g. the refresh endpoint itself).

  6.7. **Retry after refresh SHALL re-execute through the full interceptor chain.** Do NOT `Dio(BaseOptions(...)).fetch(options)` on a bare Dio — the retry needs a fresh `X-KEY` window, a fresh `X-Request-ID`, and interceptor-attached headers. Mark the retry via `options.extra['auth_retried'] = true` so `AuthInterceptor` short-circuits a second 401 instead of looping.

  6.8. **Locale header** is set via `ApiClient.setAcceptLanguage(locale)` on locale change — never per-request.

---

## 7. Endpoints & backend contracts

  7.1. **Every endpoint lives in a typed constant class.** For this project:
      * Cross-flavor / anonymous endpoints → `MobileEndpoints.authXxx` static constants.
      * Customer-only endpoints → `MobileEndpoints.customerXxx` static constants.
      * Sales-only endpoints → same file, `sales*` prefix or dedicated namespace.
      * Legacy `MobileEndpointNamespace` prefix (`/api/mobile/{flavor}/v1/...`) is DEAD on this backend — new code SHALL NOT use it.

  7.2. **Doc-comment shape for every endpoint constant:**

```dart
/// `POST /api/Customer/Order/CreateOrder` — one-line purpose.
///
/// **Request:** JSON body shape and any query params.
/// **Response:** envelope + DTO fields.
/// **Failure:** status codes and plain-text/JSON body shapes.
static const String customerOrderCreate = '/api/Customer/Order/CreateOrder';
```

  7.3. **Namespace mapping (this project's backend):** see [Appendix B](#appendix-b-endpoint-namespace-mapping).

  7.4. **Response envelopes:** most endpoints use `ResultViewModel<T>` (`{ data: T, message, isSuccess }`). A few return raw DTOs (`Ok(dto)` on the controller). The repository parser SHALL be explicit about which shape it expects — do not silently unwrap based on presence of `data`.

  7.5. **Query-string vs body binding gotchas.** Some ASP.NET actions bind primitives from the query even on `[HttpPost]` (per `[ApiController]` binding rules). Every endpoint constant SHALL document whether an id parameter is on the query string or in the body, because the mobile-side call has to match.

---

## 8. Authentication & session persistence

  8.1. **`TokenStorage` (Flutter Secure Storage) is the only place tokens live.** See [Appendix D](#appendix-d-tokenstorage-keyspace) for the keyspace.

  8.2. **Login flow SHALL:**
      a. POST credentials to the flavor's login endpoint.
      b. Parse the flavor-shaped response DTO (`CustomerLoginResultDto` for customer, `MobileAuthResultDto` for sales/shared).
      c. Persist access + refresh tokens **with their expiries** via `TokenStorage.saveSession(...)`.
      d. Persist minimal user cache (id, userName, displayName) so cold-start hydration can rebuild the session without a second `/me` round-trip if desired.
      e. Notify `FcmSetupService.setAuthenticated(true)` so the device token registers server-side.

  8.3. **Cold-start hydration SHALL:**
      a. Read the stored access token. If missing/empty → return `null` (signed out).
      b. Otherwise hit `GET /api/Auth/me` (shared endpoint — both flavors).
      c. On success → rebuild the `AuthSession` from local storage.
      d. On `401` → the interceptor triggers refresh; if refresh succeeds and the retry succeeds → session hydrates.
      e. On any *other* failure (network, 5xx, timeout) → keep the stored session in a "pending revalidation" state. **SHALL NOT** collapse network errors to "signed out."

  8.4. **Refresh flow (single-flight, rotates refresh token):**
      * `AuthInterceptor.onError` catches 401 on non-public paths.
      * A single in-flight refresh is deduplicated via `_inflight` future.
      * `AuthTokenRefresher.refresh()` uses a bare Dio (only `ClientKeyInterceptor`) to avoid the auth loop.
      * Backend rotates the refresh token; the new pair SHALL be persisted via `TokenStorage.saveSession(...)` before the retry.
      * The retry SHALL re-execute through the full interceptor chain (§6.7).

  8.5. **Cross-flavor endpoint mapping** — the customer flavor uses a mix of customer-specific and shared endpoints:

| Concern | Customer flavor | Sales flavor |
|---|---|---|
| login | `POST /api/Customer/Auth/login` | `POST /api/Auth/login` |
| refresh | `POST /api/Customer/Auth/refresh` | `POST /api/Auth/refresh` |
| logout | `POST /api/Customer/Auth/logout` | `POST /api/Auth/logout` |
| current user | `GET /api/Auth/me` (shared) | `GET /api/Auth/me` (shared) |
| signing-bootstrap | `GET /api/Auth/signing-bootstrap` (shared, `X-Device-Fingerprint` header required) | same |
| change password | `POST /api/Auth/change-password` (shared) | same |
| OTP / forgot password | `POST /api/Auth/GenerateOTP` / `OtpVerify` / `forgot-password` (shared) | same |

  8.6. **Logout SHALL** revoke the refresh token server-side first, then clear `TokenStorage` locally, then flip `FcmSetupService.handleLogout()`. Local clear happens even if the server call fails — a stuck client SHALL NOT be trapped in a corrupt session.

  8.7. **Session guardrails:**
      * `AuthNotifier.build()` differentiates `UnauthorizedException` (→ signed out) from `NetworkException`/timeout (→ keep session, retry later).
      * `changePassword` on success WARNS the user that other devices will be signed out on next refresh (server-side revokes every refresh token).
      * `logout-all-devices` is a separate action, deliberately not called by normal logout.

  8.8. **Signing-bootstrap is best-effort at splash time.** Failures are swallowed. `RequestSigningInterceptor` gracefully skips the `X-Request-Key` header when no secret is stored, so unsigned endpoints keep working. Once the secret lands, subsequent requests sign automatically.

---

## 9. Error handling & error localization

  9.1. **`AppException` sealed hierarchy** (in `lib/core/error/app_exception.dart`):
      * `NetworkException` — transport failure, no HTTP response.
      * `TimeoutException` — connect/receive timeout.
      * `UnauthorizedException` — HTTP 401 or definitive auth failure.
      * `ForbiddenException` — HTTP 403.
      * `NotFoundException` — HTTP 404.
      * `ValidationException` — HTTP 400/422 with actionable body.
      * `ServerException` — HTTP 5xx.
      * `CancelledException` — request cancelled client-side.
      * `CacheException` — local storage/cache failure.
      * `UnknownException` — the catch-all; SHALL carry `cause` and, when useful, `stackTrace` for debugging.

  9.2. **Every repository method SHALL return `Future<Result<T, AppException>>`.** Never `null`, never `throw` past the repository boundary.

  9.3. **`Result<T, E>` is sealed** (`Success<T,E>` | `Failure<T,E>`). Callers use `.when(success:, failure:)`. Bang operators (`!`) are banned.

  9.4. **`ErrorMappingInterceptor` maps every `DioException` to the correct `AppException` subtype** before it reaches the repository. Repositories SHALL only re-map when they have body-specific knowledge (e.g. login controller returning plain-string errors → `UnauthorizedException(body)`).

  9.5. **`_asAppException` in repositories SHALL enrich unknown failures with diagnostic context:**

```dart
return UnknownException(
  'Foo failed [${e.type.name}${status != null ? " · $status" : ""}] $path',
  cause: e,
);
```

  9.6. **User-facing error text SHALL pass through `arabicMessageForException` / `arabicErrorFor`.** Raw backend messages MUST NOT reach the UI. The translator (in `lib/core/utils/error_messages.dart`) maps known backend/transport errors to Arabic user copy; unknown errors fall to a generic Arabic fallback. Original message stays on `AppException.cause` for logging.

  9.7. **`ErrorView` is the standard error-state widget** — every screen that reads an `AsyncValue` renders `ErrorView(error: e, onRetry: ...)` in the error branch. Custom error UI is allowed but SHALL still route text through `arabicMessageForException`.

  9.8. **Never write empty `catch { }` blocks.** Every catch either logs (`AppLogger` or `debugPrint` in kDebugMode) or returns `Result.failure(...)`. Preferably both.

  9.9. **DTO parsing errors** are `UnknownException` with the original object as `cause`. Do NOT let a `TypeError` from JSON parsing escape the repository.

---

## 10. Flavors

  10.1. **Three environments per app:** `dev`, `staging`, `prod`. One app ships from this codebase by default; the multi-app split (customer/sales) is documented but not scaffolded — turn it on when you actually need it.

  10.2. **Per-flavor entrypoint files SHALL exist** at `lib/flavors/<app>/main_<env>.dart`. Each entrypoint:
      a. Builds a flavor-specific `AppConfig` (base URL, `AppType`, `Environment`, `useMockData`).
      b. Calls `bootstrap(config)`.

  10.3. **`AppConfig` is the only source of environment info.** Call sites SHALL NOT read `String.fromEnvironment(...)` or dart-define flags directly. Reach env info via `ref.watch(appConfigProvider)`.

  10.4. **`AppType` (`customer` | `sales`) drives flavor-branching** in shared code (`AuthRepositoryImpl.login`, notification channels, etc.). Prefer `if (appType.isCustomer) { ... } else { ... }` over string comparisons.

  10.5. **Android `productFlavors`** SHALL define bundle IDs, Firebase configs, and application labels per app. `applicationId` values in this project: `com.example.your_app` — replace per your organisation.

  10.6. **iOS schemes** SHALL exist as `Runner-dev` and `Runner-prod` (or per-app equivalents), each with its own `Info.plist` overrides and Firebase config file.

  10.7. **Run commands:**

```bash
flutter run --flavor customer --target lib/flavors/customer/main_dev.dart
flutter run --flavor customer --target lib/flavors/customer/main_prod.dart
flutter run --flavor sales    --target lib/flavors/sales/main_dev.dart
```

---

## 11. Security, signing & credentials

  11.1. **Two independent request-integrity signatures ride every non-public request:**

| Header | Secret | Purpose |
|---|---|---|
| `X-KEY` | shared static (compiled-in) | fast rejection of non-mobile clients; deters casual curl. HMAC-SHA256 of `window\|METHOD\|path` (window = unix-epoch-seconds ÷ 30). |
| `X-Request-Key` | per-device (provisioned via signing-bootstrap) | per-device replay / theft defense. Same algorithm, different key. |
| `X-Request-ID` | UUID v4 per request | backend-side replay guard; MUST NOT be reused across retries. |

  11.2. **Compile-in-only for the shared X-KEY secret.** Per-device secret SHALL come from a runtime handshake (`/api/Auth/signing-bootstrap`) and persist in `TokenStorage.saveSigningSecret`. It SHALL NEVER be committed to the repo, printed in logs, or included in analytics.

  11.3. **`X-Device-Fingerprint` header is required by signing-bootstrap.** Reuse `DeviceInfoService.deviceSerial()` (the same install-stable value the interceptor chain attaches as `X-Device-SN`) so the derived secret is stable across cold starts on this install.

  11.4. **Signing algorithm** lives in `lib/core/api/request_signing.dart`. If it changes, the change SHALL be coordinated with the backend team — never fix client-side and expect the backend to catch up.

  11.5. **TokenStorage SHALL** use `flutter_secure_storage` (Keychain / EncryptedSharedPreferences). SHALL NOT fall back to plain `SharedPreferences` for tokens.

  11.6. **Password policy SHALL match backend ASP.NET Identity policy exactly.** Configured today as:
      * `RequiredLength = 8`
      * `RequireDigit = true`
      * `RequireNonAlphanumeric = true`
      * lower/upper case NOT required.

      The mobile validator lives in `lib/features/customer/auth/registration/presentation/widgets/password_strength.dart` as `checkPasswordPolicy(...)` and drives both the strength meter and the submit gate. If the backend changes policy, mobile SHALL be updated in the same commit sweep.

  11.7. **OTP-gated flows (registration, forgot-password)** SHALL verify the OTP BEFORE the terminal write (`register-customer` / `forgot-password`). The OTP is an auth gate, not a UX confirmation step.

  11.8. **Phones SHALL be sent to the backend in E.164 format** (`+964XXXXXXXX...`). The country dial-code selector defaults to Iraq (`+964`) but exposes 30 curated countries. Backend endpoint contracts assume E.164 for OTP endpoints (Twilio compat).

  11.9. **QA-bypass phone (`7701827031`)** short-circuits OTP with SID `"sid"` on the backend, so smoke tests can drive the flow without burning SMS credits.

---

## 12. Notifications

  12.1. **Background handler SHALL be a top-level function annotated `@pragma('vm:entry-point')`.** Never a method on a class.

  12.2. **Background isolate limits (hard):**
      * SHALL NOT touch Riverpod, `Navigator`, `GoRouter`, or any Flutter widget.
      * SHALL NOT construct a `Dio` or perform network work beyond what Firebase Messaging does implicitly.
      * MAY touch `SharedPreferences` and Firebase.

  12.3. **Background-to-foreground handoff is a queue.** Background handler serialises the payload into `SharedPreferences`; on foreground resume, the main isolate calls `drainPendingNotifications()` and dispatches typed `NotificationEvent`s through `notificationBusProvider`.

  12.4. **Notification channels SHALL be created at app startup** (inside `bootstrap()`). Never lazily inside the handler.

  12.5. **Every payload field SHALL be null-checked before use** (`data['id'] ?? ''`). The wire is untyped and any producer change can leak.

  12.6. **Push token lifecycle** is owned by `FcmSetupService`. Registration flips ON via `setAuthenticated(true)` after login/hydration; OFF via `handleLogout()` on logout. The device-register endpoint is `POST /api/Customer/Device/RegisterToken` (customer) — flavor-appropriate equivalent for sales.

---

## 13. Base classes

Reach for these first. Drop down to a hand-rolled implementation only when the feature genuinely doesn't fit (auth, payments, streams, complex domain logic).

| Base | Location | Use it for |
|------|----------|------------|
| `BaseEntity` | [`lib/core/base/base_entity.dart`](../lib/core/base/base_entity.dart) | Domain entities — id-based equality, immutable. |
| `BaseDto<T>` | [`lib/core/base/base_dto.dart`](../lib/core/base/base_dto.dart) | Data-layer DTOs — `toDomain()` + `toJson()`. |
| `BaseRepository<T>` | [`lib/core/base/base_repository.dart`](../lib/core/base/base_repository.dart) | Repository interfaces — standard CRUD returning `Result<..., AppException>`. |
| `RestRepository<T, D>` | [`lib/core/base/rest_repository.dart`](../lib/core/base/rest_repository.dart) | Concrete REST implementation — instantiate directly or extend for custom endpoints. |
| `BaseListNotifier<T>` | [`lib/core/base/base_list_notifier.dart`](../lib/core/base/base_list_notifier.dart) | `AsyncNotifier<List<T>>` with refresh + optimistic create/update/delete. |
| `BaseItemNotifier<T, A>` | [`lib/core/base/base_item_notifier.dart`](../lib/core/base/base_item_notifier.dart) | `FamilyAsyncNotifier<T, A>` for detail screens. |

---

## 14. Adding a feature (recipe)

Generate all seven artefacts. Never just the UI.

  14.1. **Domain entity** — `lib/features/<feature>/domain/entities/<foo>.dart`. Pure Dart. Extend `BaseEntity`.

  14.2. **Repository interface** — `lib/features/<feature>/domain/repositories/<foo>_repository.dart`. Extend `BaseRepository<Foo>` for standard CRUD; add feature-specific methods on the interface.

  14.3. **DTO** — `lib/features/<feature>/data/dtos/<foo>_dto.dart`. Implement `BaseDto<Foo>` — `fromJson`, `toJson`, `toDomain()`.

  14.4. **Repository impl** — `lib/features/<feature>/data/repositories/<foo>_repository_impl.dart`. For plain REST, instantiate `RestRepository<Foo, FooDto>` directly. Expose the provider next to it.

  14.5. **Notifier** — `lib/features/<feature>/presentation/notifiers/<foo>_notifier.dart`. Extend `BaseListNotifier<Foo>` or `BaseItemNotifier<Foo, String>`; override `repository`.

  14.6. **Screen / widgets** — `lib/features/<feature>/presentation/screens/<foo>_screen.dart`. Read state via `ref.watch(<foo>NotifierProvider)`. Handle `AsyncValue.when(loading, error, data)` — use `LoadingView` + `ErrorView` for the first two branches.

  14.7. **Endpoint** — add to `EndPoints` / `MobileEndpoints` with a full doc-comment (verb, request, response, failure — see §7.2). SHALL NOT inline the URL.

  14.8. **Tests** — repository (success + 401 + timeout) + notifier (initial + one mutation + one failure). See §15.

**Minimal boilerplate for a plain-REST CRUD feature:**

```dart
// domain/entities/product.dart
class Product extends BaseEntity {
  const Product({required this.id, required this.name});
  @override final String id;
  final String name;
}

// data/dtos/product_dto.dart
class ProductDto implements BaseDto<Product> {
  const ProductDto({required this.id, required this.name});
  factory ProductDto.fromJson(Map<String, dynamic> json) =>
      ProductDto(id: json['id'] as String, name: json['name'] as String);
  final String id;
  final String name;
  @override Product toDomain() => Product(id: id, name: name);
  @override Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

// data/repositories/product_repository.dart
final productRepositoryProvider = Provider<BaseRepository<Product>>((ref) {
  return RestRepository<Product, ProductDto>(
    apiClient: ref.watch(apiClientProvider),
    basePath: EndPoints.products,
    fromJson: ProductDto.fromJson,
  );
});

// presentation/notifiers/products_notifier.dart
class ProductsNotifier extends BaseListNotifier<Product> {
  @override
  BaseRepository<Product> get repository => ref.read(productRepositoryProvider);
}

final productsNotifierProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);
```

---

## 15. Testing

  15.1. **Every repository test SHALL cover:** success path, `401`, `5xx`, timeout. Mock via `MockDio` or the equivalent test double.

  15.2. **Every notifier test SHALL cover:** initial load, at least one mutation, at least one failure branch.

  15.3. **Every screen widget test SHALL cover:** loading state, error state, data state — one `pumpWidget` per branch.

  15.4. **Integration tests SHALL cover login → home minimum.** Add more per critical flow (checkout, order-detail, etc.).

  15.5. **Signing algorithm has a dedicated unit test** — reproducing the backend's HMAC output for known inputs. If the test breaks after a change, the backend team hears about it before the client ships.

  15.6. **Notification event parsing has a dedicated unit test** — payload shape gotchas surface here, not in production.

  15.7. **Tests SHALL NOT hit the real network.** Every `Dio` in a test is a mock or a `DioAdapter`.

---

## 16. Localization

  16.1. **Every user-facing string SHALL live in `lib/l10n/*.arb`** and be accessed via the generated `AppLocalizations`. Hard-coded Arabic literals are tolerated only in in-progress prototypes; before merge they SHALL move to `.arb`.

  16.2. **Default locale is Arabic (`ar`).** English (`en`) is a stretch goal — arb files SHOULD be written to support the swap.

  16.3. **`Cairo` font family** is the default for Arabic text. Set at the theme level; call sites SHALL NOT re-declare `fontFamily: 'Cairo'` on individual widgets except when a nested `Text` inside a non-Cairo container needs the override.

  16.4. **Backend error strings SHALL pass through `arabicErrorFor` / `arabicMessageForException`** before display (§9.6). New backend error strings SHALL be mapped in [`lib/core/utils/error_messages.dart`](../lib/core/utils/error_messages.dart) in the same PR that adds them backend-side.

  16.5. **`Accept-Language` header SHALL be kept in sync with the app locale** via `ApiClient.setAcceptLanguage(locale)`.

---

## 17. Logging

  17.1. **`print(...)` is banned.** Use `AppLogger` for structured events, `debugPrint(...)` guarded by `kDebugMode` for one-off diagnostics.

  17.2. **Tokens, signing secrets, and PII SHALL NEVER appear in logs** — production or debug. Logs go to Crashlytics/console; any leak is a security incident.

  17.3. **`LogInterceptor` is enabled only when `kDebugMode && appConfig.enableLogging`.** Redact bodies in production even if logging is on.

  17.4. **Every catch SHALL log the exception before returning `Result.failure(...)`.** Silent failures are debugging tar pits.

---

## 18. Naming conventions

| Element | Style | Example |
|---------|-------|---------|
| Files | `lower_snake_case.dart` | `product_repository.dart` |
| Classes | `UpperCamelCase` | `ProductRepository` |
| Providers | `<noun>Provider` | `productRepositoryProvider` |
| Notifier providers | `<noun>NotifierProvider` | `productsNotifierProvider` |
| Constants | `lowerCamelCase` or `kPrefix` for module-level | `kPendingNotificationsKey` |
| Endpoint constants | `lowerCamelCase` on a class | `MobileEndpoints.customerOrderCreate` |
| Test files | mirror source path | `test/features/products/products_notifier_test.dart` |
| Feature folders | `lower_snake_case` | `features/customer/my_shops` |

---

## 19. Locked infrastructure

These files are foundational — the interceptor chain, the error hierarchy, the storage layer, the config layer. If a feature seems to require editing one of them, STOP and confirm with the tech lead first.

  * `lib/core/api/api_client.dart`
  * `lib/core/api/interceptors/*`
  * `lib/core/api/request_signing.dart`
  * `lib/core/api/token_refresher.dart`
  * `lib/core/error/result.dart`
  * `lib/core/error/app_exception.dart`
  * `lib/core/storage/token_storage.dart`
  * `lib/core/config/app_config.dart`
  * `lib/features/shared/notifications/data/firebase_background_handler.dart`

Additions here require a security/architecture review, not a normal PR review.

---

## 20. AI-assistant generation rules

When Claude / Copilot / Cursor generates code for this repo, every §1–§19 rule applies plus these hard SHALL NOTs:

  20.1. **Never `print(...)`.** Use `debugPrint` (kDebugMode) or `AppLogger`.

  20.2. **Never `Get.find(...)` or any GetX API.**

  20.3. **Never inline a URL string.** Add the path to `MobileEndpoints` first.

  20.4. **Never write an empty `catch { }` block.** Log or map + return `Result.failure(...)`.

  20.5. **Never write a background message handler that touches Riverpod, GoRouter, or any controller.**

  20.6. **Never read `String.fromEnvironment(...)` at call sites** — resolve via `appConfigProvider`.

  20.7. **Never return `null` from a repository on failure** — return `Result.failure(AppException...)`.

  20.8. **Never leak raw backend error text to the UI** — pass through `arabicMessageForException` / `arabicErrorFor`.

  20.9. **Always null-check notification payload fields** (`data['id'] ?? ''`).

  20.10. **Always cancel `StreamSubscription`s and `Timer`s via `ref.onDispose`.**

  20.11. **Always resolve the flavor / app type from `appConfig`** (already set before `runApp`).

  20.12. **Never modify the locked infrastructure files listed in §19** without explicit user approval.

  20.13. **Never generate multi-line comment blocks or long doc strings** on regular code — one-line rationale for non-obvious "why" only. Endpoint constants are the documented exception (§7.2).

  20.14. **Never generate an emoji in code or commits** unless the user explicitly asks for one.

---

## 21. Setup checklist

For a fresh project scaffolded from this template:

  * [ ] Folder structure per §3.
  * [ ] `core/api`: `ApiClient` + full interceptor chain + `EndPoints` + signing.
  * [ ] `core/error`: `AppException` sealed hierarchy + `Result<T, E>`.
  * [ ] `core/storage`: `TokenStorage` on `flutter_secure_storage`.
  * [ ] `core/config`: `AppConfig` + `Environment` + `AppType`.
  * [ ] `core/utils/error_messages.dart` with the Arabic translation map.
  * [ ] `core/utils/countries.dart` + `core/widgets/country_code_selector.dart` for E.164 phone entry.
  * [ ] Flavors per §10 — entrypoints, Android productFlavors, iOS schemes, Firebase configs.
  * [ ] Background notification handler scaffold (§12) — even if Firebase deps aren't wired yet.
  * [ ] Sample `auth` feature demonstrating all four artefacts (§13, §14).
  * [ ] Splash screen gated on system settings + auth (§4.4).
  * [ ] Router with `refreshListenable` bridging `authNotifierProvider` (§4.6).
  * [ ] `.arb` files in `lib/l10n/` and `AppLocalizations` wired.
  * [ ] CI pipeline running `flutter analyze` + `flutter test` + per-flavor build smoke tests.
  * [ ] `docs/` populated with this document, `ADDING_A_FEATURE.md`, `PUBLISHING.md`, and a project-specific `BACKEND_ASKS.md` when applicable.

---

## Appendix A. Interceptor execution order

```
Repository call
    │
    ▼
┌────────────────────────────────────────────────────────────────────┐
│  ApiClient.dio  (single instance app-wide)                         │
│                                                                    │
│  onRequest chain (top-down):                                       │
│    1. ClientKeyInterceptor       →  adds X-KEY                     │
│    2. RequestSigningInterceptor  →  adds X-Request-Key + X-Request-ID
│    3. DeviceHeaderInterceptor    →  adds X-Device-SN / -OS / -App-* │
│    4. ActiveShopInterceptor      →  adds X-Active-Shop-Id (customer)│
│    5. AuthInterceptor            →  adds Authorization: Bearer     │
│                                                                    │
│  onResponse chain (bottom-up, reversed):                           │
│    5. AuthInterceptor            →  passes through                 │
│    6. ErrorMappingInterceptor    →  no-op on success               │
│    7. LogInterceptor             →  logs (debug only)              │
│                                                                    │
│  onError chain (bottom-up):                                        │
│    6. ErrorMappingInterceptor    →  DioException → AppException    │
│    5. AuthInterceptor            →  on 401 → refresh + retry       │
│                                       (retry re-runs through 1..5) │
└────────────────────────────────────────────────────────────────────┘
```

**Order rationale:** signing depends on the final method+path, so it goes early. Auth attaches Bearer last so refresh-and-retry can re-attach the *new* token on retry. Error mapping sits just above logging so logs see the original `DioException` type, not the mapped `AppException`.

---

## Appendix B. Endpoint namespace mapping

Backend controller layout → mobile constant class mapping:

| Backend controller | Route prefix | Mobile constants |
|---|---|---|
| `Auth/AuthController` (shared) | `/api/Auth/*` | `MobileEndpoints.authMe`, `authSigningBootstrap`, `authLogout`, `authRefresh`, `customerAuthChangePassword`, `registerCustomer`, `generateOtp`, `otpVerify`, `forgotPassword`, `getContactByPublicCode` |
| `Mobile/Customer/AuthController` | `/api/Customer/Auth/*` | `MobileEndpoints.customerLogin`, `customerAuthRefresh`, `customerAuthLogout` |
| `Mobile/Customer/CustomerController` | `/api/Customer/Customer/*` | `customerShopsGet`, `customerShopAdd`, `customerShopUpdate`, `customerGetProfile`, `customerUpdateProfile`, `customerGetPublicCode`, `customerMerchantCategoriesGet` |
| `Mobile/Customer/MerchantController` | `/api/Customer/Merchant/*` | `customerMerchantsList`, `customerMerchantGetById` |
| `Mobile/Customer/ProductController` | `/api/Customer/Product/*` | `customerProductsListByBranch`, `customerProductCategoriesByMerchant`, `customerProductByIdAndBranch`, `customerBrandsByMerchant` |
| `Mobile/Customer/OrderController` | `/api/Customer/Order/*` | `customerOrderValidation`, `customerOrderCreate`, `customerOrdersList`, `customerOrderById`, `customerOrderForEdit`, `customerOrderUpdate`, `customerOrderCancel`, `customerOrderReorder` |
| `Mobile/Customer/DeviceController` | `/api/Customer/Device/*` | `customerDeviceRegister`, `customerDeviceUnregister`, `customerSystemSettings` |
| `FilesController` (shared) | `/api/files/*` | `MobileEndpoints.filesImage` (multipart upload endpoint) |

**Dead namespace:** `MobileEndpointNamespace._base = '/api/mobile/{flavor}/v1/...'` has NO backend routes. Every getter on that class (`me`, `refresh`, `logout`, `signingBootstrap`, `deviceRegister`, `register`, `verifyOtp`, `resendOtp`, `switchMerchant`) is legacy — new code SHALL use the explicit static constants above.

---

## Appendix C. Error subtype ladder

`DioException` → `ErrorMappingInterceptor` → `AppException` subtype → `arabicMessageForException` → user-facing Arabic string.

| DioException type / HTTP status | AppException subtype | Arabic user message (default) |
|---|---|---|
| `connectionError`, `connectionTimeout` | `NetworkException` | "تعذّر الاتصال. تأكّد من الإنترنت." |
| `receiveTimeout`, `sendTimeout` | `TimeoutException` | "انتهت مهلة الاتصال. حاول مرة أخرى." |
| 401 | `UnauthorizedException` | "انتهت الجلسة. سجّل الدخول من جديد." (or endpoint-specific body) |
| 403 | `ForbiddenException` | "لا تملك صلاحية لهذا الإجراء." |
| 404 | `NotFoundException` | "العنصر المطلوب غير موجود." |
| 400 / 422 with body | `ValidationException(body)` | body passed through `arabicErrorFor` — mapped or fallback |
| 429 | `ValidationException` | "طلبات كثيرة. حاول لاحقاً." |
| 5xx | `ServerException` | "خطأ من الخادم. حاول لاحقاً." |
| cancelled | `CancelledException` | (typically not shown; caller decides) |
| anything else | `UnknownException` | "حدث خطأ غير متوقع. حاول مرة أخرى." |

`arabicErrorFor` also matches on well-known backend token strings (`invalid_otp`, `otp_expired`, `user_not_found`, `DuplicateUserName`, Identity password errors, etc.) case-insensitively. Add new mappings to `error_messages.dart` in the same PR that introduces a new backend error.

---

## Appendix D. TokenStorage keyspace

`flutter_secure_storage` keys owned by `TokenStorage`:

| Key | Type | Purpose |
|---|---|---|
| `auth.access_token` | `String` | current bearer token |
| `auth.refresh_token` | `String` | current refresh token |
| `auth.access_token_expires_at` | ISO-8601 UTC | for splash-time proactive refresh (optional today) |
| `auth.refresh_token_expires_at` | ISO-8601 UTC | for early bail on definitively-expired refresh tokens |
| `auth.user_id` | `String` | rebuild session on cold start without a `/me` round-trip |
| `auth.user_name` | `String` | (same) |
| `auth.display_name` | `String` | (same) |
| `security.signing_secret` | `String` (base64) | per-device HMAC secret from `/api/Auth/signing-bootstrap` |

**`clear()` SHALL wipe every auth.* key on logout.** The `security.signing_secret` key persists across logout — it's a per-install, not per-user, value.
