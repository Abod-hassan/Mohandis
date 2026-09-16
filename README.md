# flutter_mobile_template

Opinionated Flutter mobile app template. Clone this to start a new mobile project without spending a week wiring the same infrastructure again.

## What's in the box

- **Clean Architecture, feature-first** — three layers per feature (`domain/`, `data/`, `presentation/`).
- **Riverpod** — the only state framework. Global providers in `lib/core/providers.dart`.
- **One shared Dio instance** with a full 7-interceptor chain:
  1. `ClientKeyInterceptor` — shared-secret `X-KEY` (fast rejection of non-mobile clients).
  2. `RequestSigningInterceptor` — per-device HMAC `X-Request-Key` + `X-Request-ID`.
  3. `DeviceHeaderInterceptor` — `X-Device-SN`, `X-Device-OS`, `X-App-Version`, `X-Timezone`.
  4. `AuthInterceptor` — `Authorization: Bearer`, single-flight 401→refresh→retry.
  5. `ErrorMappingInterceptor` — `DioException` → typed `AppException`.
  6. `LogInterceptor` — debug builds only.
- **Auth stack** — login, refresh (with rotating refresh tokens), signing-bootstrap, cold-start hydration through `/api/auth/me`, guardrail against collapsing network errors to signed-out.
- **`Result<T, AppException>`** — every repository returns this. No `null`-on-failure. No empty catches.
- **Arabic error localization** — `arabicMessageForException` maps known backend/transport errors to friendly Arabic copy; unmapped errors fall back to a generic Arabic message with the original preserved for logging.
- **Multi-flavor** — `dev` / `staging` / `prod` entrypoints under `lib/flavors/`.
- **Push notifications scaffold** — `firebase_core` + `firebase_messaging` + `flutter_local_notifications` preinstalled, background handler with a `SharedPreferences` queue, foreground drain into a typed event bus.
- **Base classes** — `BaseEntity`, `BaseDto<T>`, `BaseRepository<T>`, `RestRepository<T, D>`, `BaseListNotifier<T>`, `BaseItemNotifier<T, Arg>`.
- **Country code selector** with E.164 phone formatting, 30 curated countries.

## Quick start

```bash
flutter pub get
flutter run --target lib/flavors/main_dev.dart
```

You'll land on splash → login. See [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) for the full setup path (rename package, wire Firebase, point at your real backend).

## Documentation

| Doc | Purpose |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | **Canonical** — every "SHALL / SHALL NOT" rule. Read this before writing code. |
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | Fresh-clone onboarding. Rename the package, wire Firebase, run the app. |
| [docs/ADDING_A_FEATURE.md](docs/ADDING_A_FEATURE.md) | 7-step recipe with a worked `Product` example. |
| [CLAUDE.md](CLAUDE.md) | Rules for AI code assistants (Claude, Copilot, Cursor). |

## License

Choose your own — this template ships without a license file so you can drop yours in.
