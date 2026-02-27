# Setup Guide (For Hackathon Judges)

This guide walks you through getting the app running on a physical Android phone. Total setup time: ~10 minutes.

---

## Prerequisites

Before you start, make sure you have:

- **Flutter SDK** (3.10 or higher) — [install here](https://docs.flutter.dev/get-started/install)
- **Android Studio** — needed for Android SDK and build tools
- **A physical Android phone** with USB debugging enabled
  - ⚠️ Emulators **will not work** — MediaPipe requires ARM hardware
- **USB cable** to connect your phone

### Quick check

Run this in your terminal to verify everything is set up:

```bash
flutter doctor
```

You should see checkmarks for Flutter and Android toolchain. Don't worry about other items (Chrome, Visual Studio, etc.).

---

## Step 1 — Clone the Repository

```bash
git clone https://github.com/lokeyuheng/testing.git
cd testing/flutter-app
```

---

## Step 2 — Get the Firebase Config Files

For security reasons, two Firebase configuration files are **not included** in the repository. You'll need to download them from our shared Google Drive:

📁 **[Google Drive Link]** *(link will be provided in the submission notes)*

Download the following 2 files from the Drive folder:

| File | Where to place it |
|------|------------------|
| `google-services.json` | `flutter-app/android/app/google-services.json` |
| `firebase_options.dart` | `flutter-app/lib/firebase_options.dart` |

### On Windows:
```bash
# After downloading, copy them to the right locations:
copy %USERPROFILE%\Downloads\google-services.json android\app\google-services.json
copy %USERPROFILE%\Downloads\firebase_options.dart lib\firebase_options.dart
```

### On macOS/Linux:
```bash
cp ~/Downloads/google-services.json android/app/google-services.json
cp ~/Downloads/firebase_options.dart lib/firebase_options.dart
```

> **Note:** Template files (`firebase_options.dart.example` and `google-services.example.json`) are included in the repo so you can see the expected structure.

---

## Step 3 — Install Dependencies

```bash
flutter pub get
```

This will download all Dart/Flutter packages. Should take about a minute.

---

## Step 4 — Connect Your Phone

1. **Enable Developer Options** on your Android phone:
   - Go to *Settings → About Phone*
   - Tap *Build Number* 7 times until it says "You are now a developer"

2. **Enable USB Debugging**:
   - Go to *Settings → Developer Options*
   - Toggle on *USB Debugging*

3. **Plug in your phone** via USB and accept the debugging prompt on the phone

4. **Verify the connection**:

```bash
flutter devices
```

You should see your phone listed (e.g., `SM A546E (mobile) • R58RA...`). If you see only "Chrome" or no devices, check your USB cable and driver installation.

---

## Step 5 — Run the App

From the `flutter-app` directory:

```bash
flutter run
```

The first build takes 2-5 minutes (Gradle needs to download dependencies and compile native code). Subsequent builds are much faster.

---

## Step 6 — Using the App

1. **Login** — Use Google Sign-In or create an account with email/password
2. **Dashboard** — You'll see two main cards: *Sign to Voice* and *Voice to Text*

### Sign to Voice
- Tap the *Sign to Voice* card
- Grant camera permission when prompted
- Tap the record button to start detection
- Hold ASL fingerspelling signs in front of the camera (A-Z supported, except J and Z)
- Detected letters appear on screen with confidence scores
- Your facial emotion is also detected (shown as an indicator)
- Tap "Send to AI" to convert the letters into a spoken sentence — the app will read it aloud with emotion-matching tone

### Voice to Text
- Tap the *Voice to Text* card
- Grant microphone permission when prompted
- Tap record, speak a sentence, then tap stop
- The app transcribes your speech, converts it to sign language gloss, and plays back matching sign language videos

---

## Troubleshooting

**"libmediapipe_tasks_vision_jni.so not found" crash**
→ You're running on an emulator. Use a physical phone instead.

**Build fails with Gradle errors**
→ Try a clean build:
```bash
flutter clean
flutter pub get
flutter run
```

**"SDK location not found"**
→ Create `android/local.properties` with:
```
sdk.dir=C:\\Users\\YOUR_USERNAME\\AppData\\Local\\Android\\Sdk
```

**App crashes on launch / Firebase errors**
→ Double-check that `google-services.json` is in `android/app/` and `firebase_options.dart` is in `lib/`. These files are required for Firebase to connect.

**Camera shows black screen**
→ Make sure you granted camera permissions. You can also go to phone Settings → Apps → find the app → Permissions → Camera.

---

## Cloud Functions (Already Deployed)

The Firebase Cloud Functions (Gemini AI, TTS, STT, Translation) are **already deployed** to our Google Cloud project. You don't need to deploy or configure anything — the app connects to them automatically once the Firebase config files are in place.

---

That's it! If you run into any issues, feel free to reach out. Thanks for reviewing the project 🙏
