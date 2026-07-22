# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A minimal full-stack starter with **three account types** — `customer`, `vendor`, `management` —
each with register / login / dashboard / logout wired to one shared API:

```
api/            Hono API server (Bun), JWT auth
database/       Drizzle ORM schema + Postgres client (shared workspace package)
management/     SvelteKit admin app       (role: management)
vendor/         SvelteKit vendor web app  (role: vendor)
customer_app/   Flutter customer app      (role: customer)
vendor_app/     Flutter vendor app        (role: vendor)
```

`api` and `database` are a **Bun workspace** (root `package.json`, `workspaces: ["api", "database"]`,
`api` depends on `@boilerplate/database` via `workspace:*`). `management` and `vendor` are
standalone SvelteKit projects with their own `bun.lock`. `customer_app` and `vendor_app` are
standalone Flutter projects. There is no single top-level build/test command — work happens
per-package.

## Commands

### Fastest path: start everything

```bash
./start.sh      # macOS/Linux
start.bat       # Windows
```

Brings up Postgres (docker compose), installs deps, pushes the DB schema, starts the API,
then prompts for one frontend app to run. Useful as a reference for the manual sequence below.

### Infra / database

```bash
docker compose up -d                    # Postgres, db "myapp", host port 5433 (not 5432 — see below)
bun install                             # installs api + database workspace deps (run at repo root)
cp database/.env.example database/.env
cp api/.env.example api/.env
bun run --cwd database generate         # create a new migration after editing database/src/schema.ts
bun run --cwd database push             # push schema straight to the db (used in dev instead of migrate)
bun run --cwd database studio           # Drizzle Studio GUI
```

**Port 5433, not 5432**: `docker-compose.yml` maps Postgres to host port 5433 deliberately, to
avoid clashing with other local Postgres instances. `DATABASE_URL` in `api/.env.example` and
`database/.env.example` already point at 5433 — don't "fix" them back to 5432.

### API

```bash
bun run --cwd api dev     # watch mode, http://localhost:3000
bun run --cwd api start   # no watch
```

No test suite exists for the API yet; verification in this repo has been done via manual
curl smoke tests against `/auth/register`, `/auth/login`, `/auth/me`, `/users`, `/auth/logout`.

### SvelteKit apps (`management`, `vendor`)

Each has its own lockfile — `bun install` inside the app directory, not at root.

```bash
cd management   # or vendor
bun install
bun run dev              # http://localhost:5173
bun run check             # svelte-check, typecheck the whole app
bun run build
```

### Flutter apps (`customer_app`, `vendor_app`)

```bash
cd customer_app   # or vendor_app
flutter pub get
flutter run
flutter analyze
flutter test                              # runs everything under test/
flutter test test/widget_test.dart        # single test file
```

If `android/`/`ios/` are ever missing again (they're gitignored-by-convention but currently
committed), regenerate with `flutter create . --project-name <app_name> --org com.example` —
it will not touch existing `lib/` code.

## Architecture

### Auth model

One `users` table (`database/src/schema.ts`) shared by all three roles:

```ts
role: pgEnum("user_role", ["customer", "vendor", "management"])
users: { id, email, name, passwordHash, role, createdAt, updatedAt }
unique(email, role)   // same email CAN register separately as customer + vendor + management
```

There is no separate `sessions` table — auth is stateless JWT (`api/src/lib/jwt.ts`, using
`hono/jwt` + `Bun.password` for hashing). Tokens are `{ sub: userId, role, exp }`, HS256,
7-day expiry, signed with `JWT_SECRET`. **`hono/jwt`'s `verify()` requires the algorithm as an
explicit third argument** (`verify(token, secret, "HS256")`) — omitting it fails silently at
runtime with no compile-time error, which caused a real bug during initial development.

`api/src/middleware/auth.ts` exposes `requireAuth` (parses `Authorization: Bearer <token>`,
sets `c.get("authUser")`) and `requireRole(...roles)`. `GET /users` (`api/src/routes/users.ts`)
is `management`-only — it's the admin app's "list all accounts" view, not a general-purpose
endpoint.

Routes (`api/src/routes/auth.ts`):
- `POST /auth/register` — body `{ email, password, name, role }`, 409 if `(email, role)` exists
- `POST /auth/login` — body `{ email, password, role }` — **role is part of the login request**,
  since the same email can hold accounts under multiple roles
- `GET /auth/me` — requires auth, returns the current user
- `POST /auth/logout` — requires auth, 204 no-op (JWT is stateless; this exists for symmetry /
  as a hook for future server-side revocation, not because it does anything server-side today)

### Frontend auth pattern (repeated 4x, one per app/role)

Every frontend implements the same shape, scoped to its own role:

- **SvelteKit** (`management`, `vendor`): `src/lib/auth.svelte.ts` is a Svelte 5 class using
  runes (`$state`) as a singleton store — not Svelte's older writable-store pattern. Holds
  `token`/`user`/`loading`, persists the token to `localStorage`, exposes `login`/`register`/
  `logout`/`refresh`. Both apps set `export const ssr = false` in `src/routes/+layout.ts`
  because the auth store reads `localStorage`, which doesn't exist during SSR — these are
  effectively client-only SPAs despite being SvelteKit apps. Route guards live inline in each
  `+page.svelte` via `$effect` (e.g. redirect to `/login` if `!auth.user`), not in
  `+layout.server.ts` or hooks.
- **Flutter** (`customer_app`, `vendor_app`): `lib/shared/providers/auth_provider.dart` is a
  Riverpod `StateNotifier<AuthState>`, token persisted via `shared_preferences` (not
  `flutter_secure_storage` — chosen deliberately for setup simplicity in a boilerplate).
  `lib/app/app.dart` picks between `LoginPage`/`DashboardPage` based on `authProvider` state
  instead of using named routes/`go_router`.

Each app hardcodes its own role as a constant (`_role = 'vendor'` etc.) in its auth
store/provider — registration/login always sends that fixed role, so e.g. `vendor_app` can
never accidentally create a `customer` account.

### Workspace resolution gotcha

`api` imports the database package via `@boilerplate/database` (the `workspace:*` protocol).
This must resolve to a **symlink** into `database/`, created by `bun install` at the repo root.
If you ever see `api/node_modules/@boilerplate/database` as a real directory instead of a
symlink, or API code failing with stale schema errors, something (an old `bun install` run
from inside `database/` directly, or a bad commit) has shadowed the symlink with a stale copy —
delete `api/node_modules` and `database/node_modules` and reinstall from the repo root.

### Env files

Every package has `.env.example`; real `.env` files are gitignored. `PUBLIC_API_URL` in
`management`/`vendor` and `apiBaseUrl` (hardcoded in `lib/shared/providers/api_client.dart`)
in the Flutter apps all default to `http://localhost:3000` — the API's default port.
