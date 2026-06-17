# MindLog

A private journal, mood tracker and task planner built with **Flutter/Dart** for the
6002CEM Mobile App Development coursework (CW2). MindLog keeps reflection, emotion and
action in one place — and keeps it private with **local-first encryption**.

## Features

| # | Module | Highlights |
|---|--------|-----------|
| 1 | Secure access | Passcode + optional biometric (fingerprint/face) unlock, auto-lock on background |
| 2 | Diary entries | Create/edit/delete entries with title, body, date, mood and an optional photo |
| 3 | Mood tracking | Pick a mood per entry; weekly mood-trend line chart on the dashboard |
| 4 | Daily reminder | Configurable local notification at a chosen time |
| 5 | Task planner | Add, complete and swipe-to-delete to-dos |
| 6 | Mood–productivity insight | Correlates average mood with tasks completed per day |
| 7 | Mood-tagged search & "On this day" | Search by text/mood; resurfaces past entries on their anniversary |
| 8 | Quote of the day | Inspirational quote from an external REST API with offline fallback |

## Security policy (data protection)

- Passcode is stretched into a 256-bit key with **PBKDF2-HMAC-SHA256** (random per-install salt).
- The derived key is the **SQLCipher** database key, so all journal data is **encrypted at rest by default**.
- The key is never stored in plaintext; for biometric unlock a copy is held in the
  OS keystore (`flutter_secure_storage`) and released only after a successful biometric prompt.
- The whole app sits behind an auth gate and auto-locks when backgrounded.

## Tech stack

- **State management:** provider
- **Persistence:** sqflite_sqlcipher (encrypted SQLite)
- **Security:** flutter_secure_storage, crypto (PBKDF2)
- **Sensors / APIs:** local_auth (biometric), image_picker (camera/gallery), http (ZenQuotes API)
- **Notifications:** flutter_local_notifications + timezone
- **Charts:** fl_chart

## Project structure

```
lib/
  main.dart, app.dart        # bootstrap + auth gate + routing
  theme/                     # Material 3 theme
  models/                    # DiaryEntry, Task, Mood
  services/                  # database, auth, secure storage, notifications, quotes, crypto
  providers/                 # auth, diary, task, settings
  screens/                   # lock, setup, dashboard, diary, tasks, insights, search, settings
  widgets/                   # mood picker, charts, cards
```

## Getting started

```bash
flutter pub get
flutter run            # on an Android device or emulator
```

> Biometrics, camera and notifications require a physical Android device or a hardware-
> accelerated emulator. **Settings → Add sample data** populates demo entries/tasks.

## Tests

```bash
flutter analyze
flutter test
```

Unit tests cover model serialization and the PBKDF2 security layer.
