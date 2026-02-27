# Edusign Bridge

A Flutter mobile app that bridges the communication gap between sign language users and spoken language through real-time AI. The app runs two parallel pipelines: **Sign-to-Voice** (camera → hand/face analysis → Gemini → speech) and **Voice-to-Sign** (microphone → STT → sign video playback), all powered by on-device ML and Google Cloud.

Built for Android (iOS structure included but untested). Requires a physical device — MediaPipe needs ARM architecture.

---

## Technical Architecture

### High-Level System Design

```
┌──────────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App (Dart)                    │
│                                                                  │
│  ┌──────────────────────┐       ┌──────────────────────────┐    │
│  │   Sign-to-Voice      │       │    Voice-to-Sign         │    │
│  │   ────────────       │       │    ────────────          │    │
│  │   Camera feed →      │       │   Mic recording →        │    │
│  │   Native Platform    │       │   Cloud STT →            │    │
│  │   Channel (Kotlin)   │       │   Gemini gloss mapping → │    │
│  │                      │       │   Sign video playback    │    │
│  └──────────────────────┘       └──────────────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│              Native Android Layer (Kotlin)                       │
│                                                                  │
│  NativeCameraView ─── processes each frame ──┐                  │
│      │                                       │                  │
│      ├── SignLanguageAnalyzer                 │                  │
│      │     MediaPipe HandLandmarker           │                  │
│      │     → 21 landmarks normalized         │                  │
│      │     → FingerspellingClassifier         │                  │
│      │       (geometric rule engine, A-Z)     │                  │
│      │                                       │                  │
│      └── EmotionAnalyzer                     │                  │
│            MediaPipe FaceLandmarker           │                  │
│            → 52 blendshape scores            │                  │
│            → TFLite classifier               │                  │
│            → majority-vote smoothing         │                  │
├──────────────────────────────────────────────────────────────────┤
│              Firebase Cloud Functions (TypeScript)               │
│                                                                  │
│  glossToSentence  ── Gemini 2.5 Flash (gloss → sentence)        │
│  sentenceToGloss  ── Gemini 2.5 Flash  (sentence → gloss)      │
│  textToSpeech     ── Google Cloud TTS (emotion-aware pitch/rate)│
│  speechToText     ── Google Cloud STT                           │
│  translateText    ── Google Cloud Translation API               │
│  lookupSignVideos ── Firebase Storage video lookup               │
└──────────────────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.10+, Dart, GetX state management |
| Native ML | Kotlin, MediaPipe (Hand + Face Landmarker), TensorFlow Lite |
| Cloud AI | Gemini 2.5 Flash (Vertex AI), Google Cloud TTS/STT |
| Backend | Firebase Cloud Functions (TypeScript, Node.js) |
| Database | Firebase Realtime Database |
| Storage | Firebase Cloud Storage (sign language videos) |
| Auth | Firebase Auth (Google Sign-In, Email/Password) |

---

## Implementation Details

### Sign-to-Voice Pipeline

This is the core feature — the user signs in front of the camera, and the app speaks the interpreted sentence out loud.

**Step 1 — On-Device Hand Detection**

Each camera frame goes through `NativeCameraView.kt`, which runs two analyzers in parallel on the same rotated bitmap:

- **SignLanguageAnalyzer** uses MediaPipe's `HandLandmarker` to extract 21 hand landmarks (x, y, z). These get wrist-centered and scale-normalized (same normalization as our Python training pipeline).

- **FingerspellingClassifier** is a pure geometric rule engine — no ML model needed. It scores each ASL letter A–Z based on finger extension, curl ratios, tip distances, thumb position, etc. Each letter has its own scoring function (e.g., `scoreA()` checks all four fingers curled with thumb lateral, `scoreL()` checks index+thumb extended in L-shape). We chose rules over LSTM because single-frame static signs don't need temporal context, and it avoids shipping a TFLite model.

- **EmotionAnalyzer** runs MediaPipe's `FaceLandmarker` to get 52 facial blendshape scores, feeds them through a small TFLite classifier (distilled from an SVM we trained on custom data), and uses majority-vote smoothing over 8 frames to stabilize predictions across 6 emotions: happy, angry, down, confused, questioning, neutral.

**Step 2 — Cloud AI Processing**

When the user hits "Send", the Flutter `SignToVoiceController` calls two Cloud Functions in sequence:

1. `glossToSentence` — sends the accumulated fingerspelled letters + detected emotion to Gemini 2.5 Flash. The prompt handles merging individual letters into words (e.g., "H E L L O" → "Hello"), correcting typos from fast signing, and adjusting tone based on the detected emotion.

2. `textToSpeech` — takes the natural sentence and generates audio via Google Cloud TTS. The emotion adjusts speaking rate and pitch (happy = faster/higher, down = slower/lower, questioning = rising pitch).

The audio comes back as base64 MP3 and plays through the device speaker.

### Voice-to-Sign Pipeline

Works in the opposite direction — for a hearing person to communicate with a sign language user.

1. User records voice → audio sent as base64 WAV to Cloud Function `speechToText` (Google Cloud STT, 16kHz PCM)
2. Transcribed text goes to `sentenceToGloss` (Gemini) to break the sentence into sign language gloss tokens
3. `lookupSignVideos` matches each gloss token to pre-recorded sign language videos in Firebase Storage
4. Videos play back sequentially on the Flutter screen

### Platform Channel Architecture

The camera and ML inference run entirely in Kotlin via Flutter's Platform Views. `NativeCameraView` creates a `PreviewView` embedded directly in the Flutter widget tree, with a `MethodChannel` for bidirectional communication:

- **Kotlin → Dart**: `onResult` (sign detection), `onEmotionResult` (emotion detection)
- **Dart → Kotlin**: method calls for camera control

This avoids the overhead of sending camera frames across the platform channel — all image processing stays native.

### Authentication & Data Persistence

- Firebase Auth with Google Sign-In and email/password
- Firebase App Check (debug provider for development)
- Sessions and transcripts stored in Firebase Realtime Database
- Each detected sign/emotion gets timestamped and saved as a transcript entry

---

## Challenges Faced

### 1. MediaPipe ARM-Only Limitation
MediaPipe's native libraries only ship for ARM architectures. The app crashes immediately on x86 emulators with `libmediapipe_tasks_vision_jni.so not found`. This meant all development and testing had to happen on physical Android devices — no quick emulator iteration loops. We had to set up wireless ADB debugging to make the workflow bearable.

### 2. LSTM → Rule-Based Classifier Pivot
We initially trained an LSTM model on 60-frame temporal sequences (collected via webcam with Python + MediaPipe). The model hit ~96% validation accuracy but only ~58% real-time accuracy on mobile. The gap came from differences in camera quality, lighting, and the fact that ASL fingerspelling letters are static poses — temporal modeling was overkill and introduced noise. We pivoted to a zero-model geometric rule engine that classifies each frame independently based on finger geometry. This removed the TFLite dependency for sign detection entirely and improved real-time reliability.

### 3. Parallel Analyzer Frame Sharing
Running both hand and face ML models on every camera frame was tricky. Initially each analyzer captured its own `ImageProxy`, causing conflicts with CameraX's single-analyzer limitation. We solved this by having `NativeCameraView` process the frame once (rotate the bitmap), then pass the same bitmap to both `SignLanguageAnalyzer.analyzeFromBitmap()` and `EmotionAnalyzer.analyze()` in sequence.

### 4. Emotion-Aware TTS Tuning
Getting the TTS to sound natural with emotion was harder than expected. Just changing speaking rate and pitch sounded robotic. We had to carefully tune the parameters (e.g., happy = 1.15x rate / +2.0 pitch, down = 0.85x rate / -2.0 pitch) and pair them with Gemini's emotion-aware sentence rephrasing. The combination of adjusted *word choice* (from Gemini) and adjusted *voice tone* (from TTS) makes the output feel much more natural than either alone.

### 5. Fingerspelling Disambiguation
Several ASL letters have very similar hand shapes (e.g., C vs X, U vs K, M vs N vs S). The geometric classifier needed careful threshold tuning per letter — we collected `.npy` landmark datasets for each letter and iteratively adjusted the scoring functions against real data.

---

## Future Roadmap

- [ ] **iOS support** — project structure exists but native Kotlin analyzers need Swift equivalents
- [ ] **Dynamic signs (J, Z)** — these require motion tracking across frames, not just static pose detection
- [ ] **Word-level sign recognition** — move beyond fingerspelling to recognize full ASL signs (e.g., "THANK YOU", "HELP")
- [ ] **Conversation mode** — auto-switch between Sign-to-Voice and Voice-to-Sign based on who's communicating
- [ ] **Offline mode** — cache Gemini responses and TTS audio for common phrases so the app works without internet
- [ ] **Multi-language sign systems** — currently ASL only; could extend to BSL, JSL, or other sign languages
- [ ] **Improved emotion model** — train on larger, more diverse facial expression datasets
- [ ] **App Check production** — switch from debug to Play Integrity provider for production deployment

---

## Project Structure

```
testing/
├── flutter-app/
│   ├── android/app/src/main/
│   │   ├── kotlin/.../
│   │   │   ├── MainActivity.kt              # Entry point
│   │   │   ├── NativeCameraView.kt          # Camera + dual analyzer
│   │   │   ├── SignLanguageAnalyzer.kt       # MediaPipe hand detection
│   │   │   ├── FingerspellingClassifier.kt   # Geometric rule engine (A-Z)
│   │   │   ├── EmotionAnalyzer.kt            # Face + TFLite emotion
│   │   │   └── NativeViewFactory.kt          # Platform view factory
│   │   └── assets/
│   │       ├── hand_landmarker.task           # MediaPipe hand model
│   │       ├── face_landmarker.task           # MediaPipe face model
│   │       ├── emotion_classifier.tflite      # Emotion TFLite model
│   │       └── emotion_classifier_labels.json
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── features/
│   │   │   ├── auth/                          # Login, signup, auth repo
│   │   │   ├── dashboard/                     # Main dashboard screen
│   │   │   ├── sign_to_voice/                 # Camera → AI → speech
│   │   │   └── voice_to_text/                 # Mic → AI → sign videos
│   │   ├── data/
│   │   │   ├── models/                        # Data classes
│   │   │   └── services/                      # Firebase services
│   │   └── util/                              # Themes, constants, helpers
│   ├── functions/                             # Firebase Cloud Functions
│   │   └── src/
│   │       ├── ai/                            # Gemini, TTS, STT
│   │       ├── auth/                          # Auth triggers
│   │       ├── signs/                         # Video lookup
│   │       ├── translation/                   # Translation API
│   │       └── seed/                          # Database seeding
│   ├── assets/                                # Fonts, icons, label map
│   ├── ios/                                   # iOS project (untested)
│   └── pubspec.yaml
└── README.md
```

---

## License

This project was built for a hackathon. All third-party services (MediaPipe, TensorFlow Lite, Google Cloud APIs, Firebase) are used under their respective licenses.

## Acknowledgments

- [MediaPipe](https://developers.google.com/mediapipe) — hand and face landmark detection
- [TensorFlow Lite](https://www.tensorflow.org/lite) — on-device emotion inference
- [Google Gemini](https://ai.google.dev/) — natural language processing
- [Google Cloud TTS/STT](https://cloud.google.com/text-to-speech) — speech synthesis and recognition
- [Firebase](https://firebase.google.com/) — auth, database, storage, cloud functions
- [Flutter](https://flutter.dev/) — cross-platform mobile framework
