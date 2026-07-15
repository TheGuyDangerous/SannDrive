# SannDrive

A personal cloud drive **powered by the Telegram API** — store your files in your own Telegram cloud (Saved Messages): up to **2 GB per file** (4 GB with Telegram Premium), with no storage cap, no third-party server, and a clean Drive-style UI instead of a chat.

> ⚠️ **Alpha / work in progress.** SannDrive is an independent app and is **not affiliated with Telegram**. Your files live in *your own* Telegram account; it is **not a backup service** — if your Telegram account is lost, the files go with it. Telegram may place accounts using unofficial clients under extra review, so use a reasonable pace (SannDrive throttles for you — see [Ban-safety](#ban-safety)).

## Download

Every push to `main` publishes a rolling **[`latest`](https://github.com/TheGuyDangerous/SannDrive/releases/tag/latest)** prerelease with fresh binaries:

- **Windows** — `SannDrive-Setup.exe` (installer) or `SannDrive-windows-x64.zip` (portable)
- **Android** — per-ABI debug APKs (`app-arm64-v8a-debug.apk` for most phones)

## What works today

You can run and explore the whole app right now — with or without a Telegram account:

- **Full drive UI**, two designs from one codebase: a phone layout and a desktop file-manager layout.
- **Upload queue** with real progress, **ban-safety throttling**, and automatic `FLOOD_WAIT` back-off with proper error/retry components.
- **Persistent drive index** (SQLite) — folders, search, sort, rename, delete, breadcrumb navigation; uploads appear and survive a restart.
- **`api_id` onboarding** — paste your own Telegram API credentials, or tap **"Try the demo"** to explore with sample data.
- **TDLib is bundled and loads natively** (Windows DLLs ship next to the exe; Android `.so` per ABI).

### What needs *your own* credentials

Real Telegram login, upload, and Saved-Messages sync are wired end-to-end but can only run with **your own `api_id`/`api_hash` + phone number** — so they aren't exercised in CI. Get free credentials at **[my.telegram.org](https://my.telegram.org) → API development tools**, enter them on the onboarding screen, and sign in with your phone (login code → optional 2-step password). Without credentials the app runs in **demo mode** on sample data.

## How it works

Files are sent to your **Saved Messages** as documents, tagged in the caption so SannDrive can parse them back into a proper file tree. Telegram gives every account free cloud storage with **2 GB/file** (4 GB with Premium) and no total cap; captions are searchable, so the drive index stays in sync with what's actually stored.

## Ban-safety

Telegram rate-limits how fast a client can send. SannDrive keeps you safe by design:

- Uploads run **strictly one at a time** with a minimum gap between them — no spamming.
- `FLOOD_WAIT` responses **pause the queue and auto-resume** after the cooldown, with a clear "Telegram asked us to slow down — this keeps your account safe" banner.
- **Settings → Storage** explains the limits and why they exist.

## Architecture

One Flutter codebase, UI split by form factor over a shared logic layer:

```
lib/
  main.dart              # desktop init (sqflite ffi, window), runApp
  app.dart               # routes by setup + auth + platform (mobile vs desktop)
  theme/                 # Freelexity (mobile) + TelDrive (desktop) Material 3 themes
  shared/                # no UI — used by both form factors
    core/                # env, form-factor, formatting
    models/              # DriveItem, UploadTask
    services/telegram/   # tdjson dart:ffi bindings, RealTgClient + FakeTgClient, credentials
    services/upload/     # serial, throttled, FLOOD_WAIT-aware upload queue
    services/index/      # SQLite drive index
    controllers/         # Riverpod state (auth, setup, drive)
  ui/mobile/             # Freelexity-styled phone screens
  ui/desktop/            # TelDrive-styled desktop file manager
  ui/common/             # shared widgets (brand mark, error/flood banners)
```

- **State:** Riverpod · **Index:** SQLite · **Telegram:** TDLib (`tdjson`) via `dart:ffi` in a background isolate.
- The Telegram client is chosen at runtime: `RealTgClient` when credentials exist **and** the native library loads, otherwise a `FakeTgClient` demo — so the app runs everywhere and CI stays green.
- **Mobile** follows the [Freelexity](https://github.com/TheGuyDangerous/Freelexity) look; **desktop** follows [TelDrive](https://github.com/tgdrive/teldrive-ui)'s Material 3 file manager.

## Build

```bash
flutter pub get
flutter run                         # runs on the current desktop / a connected device
flutter build windows --release     # desktop (bundles the TDLib DLLs next to the exe)
flutter build apk --split-per-abi   # Android (packages libtdjson.so per ABI)
```

The prebuilt TDLib native libraries are committed under `windows/tdlib/` and `android/app/src/main/jniLibs/`; CI can also fetch them on demand. To log in, supply your own `api_id`/`api_hash` from [my.telegram.org](https://my.telegram.org).

## CI

`.github/workflows/build.yml` runs `flutter analyze`, builds Android + Windows, and publishes the rolling `latest` prerelease with the installer, zip, and APKs on every push to `main`.
