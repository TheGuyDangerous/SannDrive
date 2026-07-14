# SannDrive

A personal cloud drive **powered by the Telegram API** — store your files in your own Telegram cloud (Saved Messages): up to **2 GB per file** (4 GB with Telegram Premium), with no storage cap, no third-party server, and a clean Drive-style UI instead of a chat.

> ⚠️ **Alpha / work in progress.** SannDrive is an independent app and is **not affiliated with Telegram**. Your files live in *your own* Telegram account; it is **not a backup service** — if your Telegram account is lost, the files go with it.

## What it does
- Sign in with your Telegram phone number (login code + optional 2‑step password).
- Upload files and folders straight into your Telegram cloud, tagged so SannDrive can index them.
- Browse, search, and download them back as a proper file drive — on **mobile and desktop** from one codebase.

## Architecture
One Flutter codebase, UI split by form factor over a shared logic layer:

```
lib/
  app.dart              # routes by auth + platform (mobile vs desktop)
  shared/               # no UI — used by both
    core/               # env, form-factor
    services/telegram/  # TDLib client + auth
    controllers/        # Riverpod state
  ui/mobile/            # phone screens
  ui/desktop/           # desktop screens
```

Telegram access is via **TDLib** through `dart:ffi` (prebuilt native binaries per platform). State is **Riverpod**; the local file index is **SQLite**.

## Ban-safety
Telegram limits how fast you can send. SannDrive throttles uploads and honors `FLOOD_WAIT` so normal use stays well within safe bounds — see **Settings → Storage** in the app.

## Build
```bash
flutter pub get
flutter run                 # or: flutter build apk / flutter build windows
```

You'll need your own `api_id` / `api_hash` from [my.telegram.org](https://my.telegram.org) to log in.
