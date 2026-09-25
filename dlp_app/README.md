# Digital Learning Passport (DLP) — Flutter Application

Proof-of-concept companion application for the ICTer 2026 paper:
> **"An AI-Enabled Digital Learning Passport with Skill Gap Detection and Industry-Integrated Recruitment Interface"** (Industry R&D Track, [icter.lk](https://icter.lk/industry-rd-track/))
> Developed by **Madusanka Premaratne, Knivok Private Limited, Sri Lanka** in collaboration with academic supervisors.

This single Flutter codebase targets **Android**, **iOS**, and **Web**, implementing both sides of the Digital Learning Passport: the **Student Passport** and the **Industry-Integrated Recruitment Interface (IIDLP)**, backed by a hybrid **Edge AI** architecture.

---

## Key Features & User Flows

### 1. Student Experience: Living Learning Passport

- **Living Passport (`PassportScreen`)**:
  - Displays learner details, institution, enrolled programme, and OULAD outcome status (`Distinction`, `Pass`, `Fail`, `Withdrawn`).
  - **Skill Profile**: Visualizes learner competence across 6 canonical skill dimensions:
    - *Data analysis*, *Programming*, *Maths & statistics*, *Communication*, *Domain knowledge*, and *Engagement consistency*.
  - **Weekly VLE Engagement Trail**: Interactive time-series activity chart (`fl_chart` LineChart) mapping weekly clicks from virtual learning environment logs.
  - **Verified Module Record**: Granular academic course records including assessment scores, credits, and completion dates.
  - **External Certifications**: Verifiable industry credentials (e.g., AWS, Meta, professional certifications).

- **Student "Job Fit Check" (`JobFitScreen`)**:
  - Students can paste any free-text job description (JD) directly into the app.
  - The **Edge LM** analyzes the JD on-device without network connectivity:
    - Extracts required skill levels across all 6 dimensions.
    - Calculates an instant cosine similarity match score.
    - Identifies missing skills and severe gaps.
    - Generates a personalized readiness narrative and highlights matched keyword chips.

- **Consent-Controlled QR Sharing (`ShareScreen`)**:
  - Students control their data privacy before sharing:
    - Toggle granular assessment scores on/off.
    - Toggle detailed weekly engagement trails on/off.
  - Generates a compact, self-contained signed JSON payload rendered as an on-screen QR code (`qr_flutter`).
  - Cryptographically verifiable offline (SHA-256 digest in prototype; Ed25519 in campus server architecture).
  - Includes a 1-tap clipboard copy option for single-device demos or text sharing.

---

### 2. Recruiter Experience: IIDLP (Industry-Integrated Interface)

- **Scanner & Payload Intake (`ScanScreen`)**:
  - **Live Camera Scanner**: High-speed camera QR code scanning using `mobile_scanner`.
  - **Paste Code Fallback**: Direct payload pasting for testing or desktop/web environments.
  - **1-Click Sample Candidate**: Instantly loads a representative OULAD candidate profile without needing a second device.

- **Candidate Evaluation (`CandidateScreen`)**:
  - **Cryptographic Verification Badge**: Confirms whether the passport payload signature is authentic and verified by the issuing institution.
  - **Target Role Benchmarking**: Match candidate skills against pre-configured industry roles (*Data Analyst*, *Junior Software Developer*, etc.).
  - **Custom JD Matching with Edge LM**: Paste any corporate job description to dynamically generate requirement vectors and match candidates on-the-fly.
  - **Cosine Similarity Match Score**: Computes normalized vector alignment between candidate competence and role expectations.
  - **Interactive Radar Gap Map**: Multi-axis radar chart (`fl_chart` RadarChart) visually comparing candidate strengths against role demand.
  - **Ranked Skill Gaps**: Prioritized list of skill deficiencies with targeted learning recommendations.
  - **"Warm Start" Onboarding Plan**: Actionable 30/60/90-day ramp-up curriculum addressing the candidate's specific gaps before day one.
  - **Consent-Gated Academic Evidence**: Displays verified module records and engagement analytics strictly according to student-granted consent flags.

---

### 3. Edge LM & On-Device Model Manager

The Edge LM service ([lib/services/edge_lm/](lib/services/edge_lm/)) operates locally on-device, ensuring job descriptions and student profiles remain completely private:

- **Model Catalog & Download Manager (`EdgeModelScreen`)**:
  - Accessible directly from the app home screen.
  - **Public SLMs (No account or token required)**:
    - **Qwen 2.5 0.5B Instruct (q8)**: ≈550 MB download — quick start for low-end / entry-level mobile devices.
    - **Qwen 2.5 1.5B Instruct (q8)**: ≈1.6 GB download — recommended for high accuracy on devices with 4 GB+ RAM.
  - **Gated SLMs (Requires Hugging Face token with accepted license)**:
    - **Gemma 3 270M (q8)**: ≈300 MB download — ultra-compact footprint.
    - **Gemma 3 1B (int4)**: ≈555 MB download — efficient quantized 1B parameter model.
  - Features real-time download progress tracking, model activation, in-memory lifecycle management, and smoke tests.

- **Dual-Engine Architecture (`EdgeLmRuntime`)**:
  - **`GemmaEdgeLm`**: Real on-device SLM inference via `flutter_gemma` (Google MediaPipe LLM Inference / LiteRT). Rates skill requirements and writes contextual readiness narratives.
  - **`LexiconEdgeLm`**: Deterministic rule-based keyword & TF-IDF extractor. Zero-latency, zero-memory, running seamlessly across Web, mobile, and CI test suites.
  - **Automatic Fallback**: If an on-device SLM is not downloaded, times out, or encounters memory pressure, the app automatically falls back to `LexiconEdgeLm` while preserving keyword chips.

---

## Project Structure

```
dlp_app/
├── lib/
│   ├── main.dart                          # App entry point & theme setup
│   ├── theme.dart                         # Brand styling (Material 3, #045FDA)
│   ├── models/
│   │   └── models.dart                    # OULAD-compatible domain models & schemas
│   ├── data/
│   │   └── demo_data.dart                 # Sample learner profiles and benchmark roles
│   ├── services/
│   │   ├── passport_codec.dart            # Base64/JSON encoding & signature verification
│   │   ├── skill_match.dart               # Cosine similarity and gap detection logic
│   │   └── edge_lm/
│   │       ├── edge_lm.dart               # Abstract interface & runtime singleton
│   │       ├── edge_model_manager.dart    # Hugging Face downloader & model lifecycle
│   │       ├── gemma_edge_lm.dart         # MediaPipe / flutter_gemma SLM backend
│   │       └── lexicon_edge_lm.dart       # Deterministic keyword/lexicon fallback
│   ├── screens/
│   │   ├── home_screen.dart               # Landing screen (role selection & model status)
│   │   ├── edge_model_screen.dart         # Edge AI model downloader & manager
│   │   ├── student/
│   │   │   ├── passport_screen.dart       # Living student passport & charts
│   │   │   ├── share_screen.dart          # Privacy consent toggles & QR generator
│   │   │   └── job_fit_screen.dart        # On-device JD fit checker
│   │   └── recruiter/
│   │       ├── scan_screen.dart           # Camera QR scanner & paste input
│   │       └── candidate_screen.dart      # IIDLP match score, radar map, warm-start
│   └── widgets/
│       └── gap_tile.dart                  # Reusable gap display with recommendations
├── test/
│   ├── logic_test.dart                    # Codec, consent, and skill match engine tests
│   ├── edge_lm_test.dart                  # Deterministic Lexicon Edge LM tests
│   └── screens_test.dart                  # Full widget & user flow tests
├── android/                               # Native Android configuration (minSdk 24, ProGuard)
├── ios/                                   # Native iOS configuration (Info.plist, Podfile)
└── web/                                   # Web configuration & manifest
```

---

## Build & Platform Notes

### Android
- **SDK Requirements**: `minSdkVersion = 24`, `targetSdkVersion = 35`, `compileSdkVersion = 35`.
- **Permissions**: `INTERNET` (for optional model download), `CAMERA` (for QR scanning), and OpenGL native libraries (`libGLESv3.so`) for GPU-accelerated inference.
- **ProGuard / R8**: Custom rules in [android/app/proguard-rules.pro](android/app/proguard-rules.pro) preserve MediaPipe, LiteRT, and Protobuf classes during release builds.
- **Recommended Build**: Split per-ABI release APKs:
  ```sh
  flutter build apk --release --split-per-abi
  ```
  Produces `app-arm64-v8a-release.apk` (≈167 MB including native inference runtime) vs a fat APK (≈288 MB).

### iOS
- Declares `NSCameraUsageDescription` in `Info.plist` for live QR camera scanning.
- Compatible with iOS 12.0+ deployment target.

### Web
- Built as a responsive web app suitable for desktop and mobile browsers:
  ```sh
  flutter build web
  ```
  The web build automatically utilizes the deterministic `LexiconEdgeLm` engine with zero download overhead.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.12+ recommended)
- Android Studio / Xcode (for mobile development) or Google Chrome (for web)

### Run the App

```sh
# Navigate to the app directory
cd dlp_app

# Fetch dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Or run on a connected Android/iOS device
flutter run
```

### Running Tests

The test suite contains **22 comprehensive unit and widget tests** validating domain logic, serialization, consent stripping, cosine matching, Edge LM extraction, and UI screen transitions:

```sh
flutter test
```

### Demo Instructions

1. **Single-Device Walkthrough**:
   - Tap **"I am a student"** → select any demo learner (e.g., *Amara Okafor* or *Liam Davies*).
   - Explore the skill breakdown, weekly engagement chart, and verified modules.
   - Tap the briefcase icon in the top bar to run a **Job fit check** against sample job text.
   - Tap **"Share via QR"**, adjust consent toggles, and tap **"Copy code"**.
   - Return to the home screen → tap **"I am a recruiter"** → open the **"Paste code"** tab.
   - Paste the code (or tap **"Load sample candidate"**) to view the full IIDLP dashboard: radar gap map, cosine match score, ranked gaps, and onboarding plan.

2. **Two-Device Walkthrough**:
   - Open the app on Device A as a student, navigate to **"Share via QR"**.
   - Open the app on Device B as a recruiter, use the live camera scanner on the **"Scan QR"** tab to scan Device A's screen.
