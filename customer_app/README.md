# customer_app

Flutter app for customers. State management via Riverpod, HTTP calls to `packages/api`.

## First-time setup

This folder was scaffolded by hand (no Flutter SDK was available at generation time), so the
native platform folders (`android/`, `ios/`, `web/`, etc.) don't exist yet. Once you have the
Flutter SDK installed:

```bash
flutter create . --project-name customer_app --org com.example
flutter pub get
```

This fills in the platform folders without touching the existing `lib/` code.

## Structure

```
lib/
  main.dart                     # entrypoint, wraps app in ProviderScope
  app/app.dart                  # MaterialApp + theme + root route
  shared/providers/api_client.dart  # http.Client provider + API base URL
  shared/models/user.dart       # example model
  features/home/                # example feature: fetches /users from the API
```

## Run

```bash
flutter run
```

Set `apiBaseUrl` in `lib/shared/providers/api_client.dart` to point at your running
`packages/api` instance (defaults to `http://localhost:3000`).
