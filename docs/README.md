# Documentation

## Index

| Doc | Read when |
|-----|-----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | **Canonical.** Every "SHALL / SHALL NOT" rule that governs this codebase — and the blueprint for building on top of this template. Read once end-to-end; reference by section number thereafter. |
| [GETTING_STARTED.md](GETTING_STARTED.md) | First day on a fresh project. Install tools, run the app, wire your Firebase config, replace the placeholder API base URLs. |
| [ADDING_A_FEATURE.md](ADDING_A_FEATURE.md) | Every time you build a new feature — step-by-step recipe with a worked example. See also `ARCHITECTURE.md §14`. |

## Where the auth appendix in ARCHITECTURE.md doesn't match your backend

The template scaffolds a single-flavor auth surface against these placeholder routes:

- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `GET /api/auth/signing-bootstrap`
- `POST /api/device/register-token` / `POST /api/device/unregister-token`

If your backend uses different paths (customer vs sales controllers, versioned prefixes, etc.), update:

1. Constants in [`lib/core/api/endpoints.dart`](../lib/core/api/endpoints.dart).
2. `AuthRepositoryImpl` in [`lib/features/shared/auth/data/repositories/`](../lib/features/shared/auth/data/repositories/) if any request/response shape diverges.
3. `unauthenticatedPaths` in [`lib/core/api/api_client.dart`](../lib/core/api/api_client.dart) to match the login/refresh paths.
4. `AuthTokenRefresher`'s `refreshPath` argument in [`lib/bootstrap.dart`](../lib/bootstrap.dart).

See ARCHITECTURE.md §8 for the full contract.
