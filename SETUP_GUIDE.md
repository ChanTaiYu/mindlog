# MindLog — Setup & Run Guide

How to get MindLog running on the Android emulator on a Windows PC — including a **fresh
laptop** that has never had Flutter installed.

> **Paths in this guide** use the username `chan` (e.g. `C:\Users\chan\...`). On another
> laptop, replace `chan` with **your** Windows username, and use wherever you actually
> installed Flutter / the Android SDK. The `flutter` command works from any folder once it's
> on your PATH (see Part 1).

---

## Part 1 — One-time machine setup (do this once per laptop)

If this laptop already has Flutter + Android Studio working (`flutter doctor` is happy and
`flutter emulators` lists a device), skip to **Part 2**.

### 1.1 Install the toolchain
1. **Android Studio** — https://developer.android.com/studio
   Installing it gives you the **Android SDK**, the **emulator**, the **Device Manager**, and
   a bundled **JDK** all at once. During first launch, let it download the default SDK
   components.
2. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows
   Unzip it (e.g. to `C:\Users\<you>\flutter`) and add `...\flutter\bin` to your **PATH**.
3. Open a **new** PowerShell window and accept the Android licenses:
   ```powershell
   flutter doctor --android-licenses     # press y to accept all
   flutter doctor                        # everything Android-related should be ✓
   ```
   This project was built with **Flutter 3.41.x / Dart 3.11.x** — any 3.41+ stable is fine.

### 1.2 Enable CPU virtualization in BIOS (required for the emulator)
The emulator needs hardware acceleration.
- Reboot → press **Del** or **F2** at startup to enter BIOS/UEFI.
- Turn on virtualization:
  - **AMD CPUs:** look for **SVM Mode** (often under *Advanced → CPU Configuration*, or *OC*
    on MSI boards) → **Enabled**.
  - **Intel CPUs:** look for **Intel VT-x / Virtualization Technology** → **Enabled**.
- Save & exit (F10). Back in Windows, verify (should print `True`):
  ```powershell
  (Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
  ```

### 1.3 Confirm emulator acceleration
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -accel-check
```
You want `accel: 0` and a message like **"WHPX is installed and usable"** (Windows
Hypervisor Platform). On this original PC it used WHPX — nothing extra to install.

> **If `-accel-check` fails** on the new laptop, install the bundled hypervisor driver from
> an **Administrator** terminal:
> ```powershell
> cd "$env:LOCALAPPDATA\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"
> .\silent_install.bat
> ```
> WHPX and AEHD are alternatives — use one. (If WHPX is on, you don't need AEHD.)
> If WHPX isn't enabled, turn it on: *Windows Features → tick "Windows Hypervisor Platform"
> and "Virtual Machine Platform" → reboot.*

### 1.4 Create an emulator (a fresh laptop has none!)
The AVD named `Medium_Phone_API_36.1` only exists on the original PC. On a new laptop, make
one:
- **Android Studio → (⋮ / More Actions) → Virtual Device Manager → Create Device**
- Pick e.g. **Pixel 7**, a system image like **API 34/35/36 (x86_64)** (download it), Finish.

Then confirm Flutter sees it:
```powershell
flutter emulators        # note the Id shown, e.g. Pixel_7_API_34
```

---

## Part 2 — Get the project onto the laptop

### Option A — GitHub (recommended, no stale files)
```powershell
git clone <your-repo-url> mindlog
cd mindlog
```

### Option B — Zip transfer
**On this PC, before zipping**, strip the machine-specific build cache so the zip is small
and clean:
```powershell
cd "C:\Users\chan\Mobile App Development\mindlog"
flutter clean
```
Zip the `mindlog` folder, copy it over, unzip it on the new laptop.
✅ Keep `lib/ android/ ios/ pubspec.yaml pubspec.lock test/ README.md`.
❌ `build/ .dart_tool/ .gradle/` are not needed — they regenerate.

### Either way — fetch dependencies after you have the folder
```powershell
cd <path-to>\mindlog
flutter pub get          # downloads the packages (needs internet)
```

---

## Part 3 — Run it

```powershell
# 1. Start your emulator (use the Id from `flutter emulators`)
flutter emulators --launch Pixel_7_API_34        # <- your AVD id here

# 2. Confirm it's connected (wait until the Android home screen loads)
flutter devices

# 3. From the project folder, run the app
cd <path-to>\mindlog
flutter run
```
The first Android build re-downloads Gradle and is slow (a few minutes); later runs are fast.

While `flutter run` is active, in that terminal:
| Key | Action |
|-----|--------|
| `r` | Hot reload (apply code changes instantly) |
| `R` | Hot restart |
| `h` | List all commands |
| `q` | Quit and stop the app |

---

## Part 4 — First-run walkthrough (and demo tips)

1. **Create a passcode** (e.g. `1234`) and confirm → this also creates the encrypted database.
2. You land on the **Home** dashboard with the quote of the day.
3. **Settings** (gear icon, top right) → **Add sample data** to instantly populate entries,
   the mood trend and the Insights chart — great for screenshots and the VIVA.
4. Explore the tabs: **Diary** (＋ New entry, attach a photo), **Tasks**, **Insights**, plus
   **Search** (magnifier).
5. Tap the **lock icon** (top right) to lock; re-enter the passcode to unlock.

> **Your data does not travel with the project.** The encrypted database, passcode and
> keystore live on the device/emulator, not in the folder. A fresh install always starts
> blank — set a new passcode and use *Add sample data*. That's expected for an encrypted,
> local-first app.

### Emulator hardware features
- **Camera** (photo attachment): the emulator has a simulated camera — usable; a real phone
  looks better in a demo.
- **Fingerprint** (biometric unlock): enable *Biometric unlock* in Settings, lock the app,
  then open the emulator's **⋮ → Extended controls → Fingerprint → Touch sensor**.
- **Notifications**: enable the daily reminder in Settings (allow the permission prompt).

---

## Useful commands

```powershell
flutter doctor                 # check the toolchain is healthy
flutter emulators              # list available emulators (and their Ids)
flutter devices                # what can I run on right now?
flutter run -d <device-id>     # target a specific device
flutter analyze                # static analysis (should say: No issues found)
flutter test                   # run unit tests
flutter clean                  # wipe build cache if something is stuck
```

### Taking screenshots for the report
Easiest: the **camera icon** in the emulator's side toolbar. Or via adb:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" exec-out screencap -p > shot.png
```

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| `flutter` not recognised | `...\flutter\bin` isn't on PATH — add it, open a new terminal. |
| `flutter doctor` shows Android ✗ | Install Android Studio + SDK, then `flutter doctor --android-licenses`. |
| `No emulators available` | Create an AVD in Android Studio → Virtual Device Manager (Part 1.4). |
| `... requires hardware acceleration` | Virtualization off in BIOS (SVM / VT-x) — redo Part 1.2; check `-accel-check`. |
| Emulator window never appears | Launch it from **Android Studio → Device Manager** to see its error. |
| `No devices found` in `flutter run` | Wait for the emulator to finish booting, then `flutter devices`. |
| Build errors after transfer | `flutter clean`, then `flutter pub get`, then run again. |
| Package/version errors on `pub get` | Ensure Flutter is **3.41+** (`flutter --version`); then `flutter pub get`. |
| Forgot passcode | App icon → App info → Storage → **Clear data** (wipes the encrypted DB; set a new passcode). |
