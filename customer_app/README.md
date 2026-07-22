# customer_app

Flutter app for customers: register, login, dashboard, logout against the `api` server.
State management via Riverpod; the auth token is persisted with `shared_preferences`.

## First-time setup

```bash
flutter create . --project-name customer_app --org com.example
flutter pub get
```

This fills in the native platform folders (`android/`, `ios/`, `web/`, etc.) without touching
the existing `lib/` code.

## Structure

```
lib/
  main.dart                          # entrypoint, wraps app in ProviderScope
  app/app.dart                       # MaterialApp + auth-gated routing
  shared/providers/api_client.dart   # http.Client provider + API base URL + ApiException
  shared/providers/auth_provider.dart  # AuthController: login/register/logout, token persistence
  shared/models/user.dart            # user model returned by the API
  features/auth/                     # login_page.dart, register_page.dart
  features/dashboard/                # dashboard_page.dart
```

## Run

```bash
flutter run
```

Set `apiBaseUrl` in `lib/shared/providers/api_client.dart` to point at your running
`api` instance (defaults to `http://localhost:3000`). Accounts registered here use
role `customer`, which is a separate account namespace from the vendor/management apps.
