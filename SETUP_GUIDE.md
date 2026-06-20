# MindLog — Setup & Run Guide

How to run MindLog on the Android emulator on this Windows PC. Written for this exact
machine (AMD Ryzen 5 5600, Android SDK at `C:\Users\chan\AppData\Local\Android\Sdk`,
Flutter at `C:\Users\chan\flutter`).

---

## TL;DR — run it (after the one-time setup below is done)

```powershell
# 1. Start the emulator
flutter emulators --launch Medium_Phone_API_36.1

# 2. From the project folder, run the app on it
cd "C:\Users\chan\Mobile App Development\mindlog"
flutter run
```

Then in the `flutter run` terminal: press **r** = hot reload, **R** = hot restart,
**q** = quit.

---

## One-time setup (already completed on this PC ✅)

You only ever do this once. It's recorded here so you can repeat it on another machine or
after a Windows reset.

### 1. Enable CPU virtualization in BIOS (done)
The emulator needs hardware acceleration. On AMD this is **SVM Mode**.
- Reboot → press **Del** (or F2) at startup to enter BIOS/UEFI.
- Find **SVM Mode** (often under *Advanced → CPU Configuration*, or *OC* on MSI boards)
  and set it to **Enabled**.
- Save & exit (F10).
- Verify in PowerShell — should print `True`:
  ```powershell
  (Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
  ```

### 2. Confirm the emulator has an accelerator (done — uses WHPX)
```powershell
& "C:\Users\chan\AppData\Local\Android\Sdk\emulator\emulator.exe" -accel-check
```
On this PC it reports `accel: 0` → **"WHPX is installed and usable."** That's all that's
needed — nothing else to install.

> **If `-accel-check` ever fails** (e.g. on a PC without WHPX), install the bundled
> Android Emulator Hypervisor Driver instead. Run an **Administrator** terminal and:
> ```powershell
> cd "C:\Users\chan\AppData\Local\Android\Sdk\extras\google\Android_Emulator_Hypervisor_Driver"
> .\silent_install.bat
> ```
> Note: AEHD requires Hyper-V/WHPX to be **off**; WHPX and AEHD are alternatives, not both.

---

## Running step by step

### Step A — list and launch the emulator
```powershell
flutter emulators                                   # shows available AVDs
flutter emulators --launch Medium_Phone_API_36.1    # boot the phone
```
A phone window opens. Wait until the Android home screen is fully loaded (~30–60s the first
time). Check it's connected:
```powershell
flutter devices         # should list "sdk gphone64 x86 64 (mobile) • emulator-5554"
```

### Step B — run MindLog
```powershell
cd "C:\Users\chan\Mobile App Development\mindlog"
flutter run
```
Flutter builds the app, installs it, and launches it on the emulator. The first build is
slower; later runs are fast.

### Step C — interact while it runs
In the terminal where `flutter run` is active:
| Key | Action |
|-----|--------|
| `r` | Hot reload (apply code changes instantly) |
| `R` | Hot restart (restart app, keep emulator) |
| `h` | List all commands |
| `q` | Quit and stop the app |

---

## First-run walkthrough (and demo tips)

1. **Create a passcode** (e.g. `1234`) and confirm it → this also creates the encrypted
   database.
2. You land on the **Home** dashboard with the quote of the day.
3. Go to **Settings** (gear icon, top right) → **Add sample data** to instantly populate
   entries, mood trend and the Insights chart — great for screenshots and the VIVA.
4. Explore the tabs: **Diary** (＋ New entry, attach a photo), **Tasks**, **Insights**.
5. Tap the **lock icon** (top right) to lock; re-enter the passcode to unlock.

### Emulator hardware features
- **Camera** (photo attachment): the emulator has a simulated camera — usable, but a real
  phone looks better in a demo.
- **Fingerprint** (biometric unlock): enable *Biometric unlock* in Settings, lock the app,
  then open the emulator's **⋮ → Extended controls → Fingerprint → Touch sensor** to
  authenticate.
- **Notifications**: enable the daily reminder in Settings (allow the permission prompt).

---

## Useful commands

```powershell
flutter doctor            # check the toolchain is healthy
flutter devices           # what can I run on?
flutter run -d emulator-5554   # target a specific device
flutter analyze           # static analysis (should say: No issues found)
flutter test              # run unit tests
flutter clean             # wipe build cache if something is stuck
```

## Taking screenshots for the report
With the app on screen:
```powershell
& "C:\Users\chan\AppData\Local\Android\Sdk\platform-tools\adb.exe" exec-out screencap -p > shot.png
```
(or use the camera icon in the emulator's side toolbar).

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| `emulator: ... requires hardware acceleration` | SVM not enabled in BIOS — redo one-time step 1. |
| Emulator window never appears | `flutter emulators --launch Medium_Phone_API_36.1`; if still stuck, open **Android Studio → Device Manager** and start it there. |
| `No devices found` in `flutter run` | Make sure the emulator finished booting; run `flutter devices`. |
| Build fails after editing code | `flutter clean` then `flutter pub get`, run again. |
| Forgot passcode | Long-press the app icon → App info → Storage → Clear data (this wipes the encrypted DB and lets you set a new passcode). |
