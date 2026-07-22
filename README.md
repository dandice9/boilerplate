# boilerplate

A starter project for an app with three kinds of accounts — **customers**, **vendors**,
and **management** (admin) — that can each sign up, log in, see a dashboard, and log out.

It comes with:
- A web app for admins (`management`)
- A web app for vendors (`vendor`)
- A mobile app for customers (`customer_app`)
- A mobile app for vendors (`vendor_app`)
- One shared server (`api`) and database that all four apps talk to

You don't need to touch all of them — pick the one you're building on.

## 1. Install these first

You only need to install these once.

| Install | What it's for | Get it from |
|---|---|---|
| **Docker Desktop** | Runs the database for you — no manual database setup | [docker.com/get-started](https://www.docker.com/get-started/) |
| **Bun** | Runs the server and the two web apps | [bun.sh](https://bun.sh) |
| **Flutter** | Only needed if you're running the two mobile apps | [flutter.dev](https://docs.flutter.dev/get-started/install) |

After installing, make sure **Docker Desktop is open and running** before you start the project —
you'll see its whale icon in your menu bar / system tray when it's ready.

If you're only working on the web apps (`management` or `vendor`), you can skip installing Flutter.

## 2. What's in this folder

```
api/            The server — handles login, sign-up, and talks to the database
database/       The database structure (what info gets saved about each user)
management/     Admin web app
vendor/         Vendor web app
customer_app/   Customer mobile app
vendor_app/     Vendor mobile app
```

## 3. Start the project

This runs the database, the server, and lets you pick one app to open — no manual setup needed.

**On Mac or Linux**, open Terminal in this folder and run:
```bash
./start.sh
```

**On Windows**, double-click `start.bat`, or open Command Prompt in this folder and run:
```bat
start.bat
```

The first run takes a few minutes (it's downloading everything the project needs). After that,
it'll be much faster.

When it's ready, it will ask you which app to open:
```
1) management   (admin web app)
2) vendor       (vendor web app)
3) customer_app (customer mobile app)
4) vendor_app   (vendor mobile app)
```
Type the number and press Enter.

- If you picked **management** or **vendor**, open **http://localhost:5173** in your browser.
- If you picked **customer_app** or **vendor_app**, it will open in the Flutter app simulator/device.

The server itself runs at **http://localhost:3000** — you shouldn't need to open this directly,
the apps talk to it automatically.

To stop everything, go back to the terminal window and press `Ctrl+C`.

## Doing it manually (optional)

If you'd rather run each piece yourself instead of using the start script:

```bash
docker compose up -d          # starts the database
bun install                   # installs the server's dependencies
cp database/.env.example database/.env
cp api/.env.example api/.env
bun run --cwd database push   # sets up the database tables
bun run --cwd api dev         # starts the server (http://localhost:3000)
```

Then, in a separate terminal, start whichever app you want:
```bash
cd management   # or vendor
bun install
bun run dev      # http://localhost:5173
```
```bash
cd customer_app   # or vendor_app
flutter pub get
flutter run
```
