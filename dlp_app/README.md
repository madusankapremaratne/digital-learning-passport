# Digital Learning Passport (DLP) — Flutter prototype

Proof-of-concept companion to the ICTAR paper *"An AI-Enabled Digital
Learning Passport with Skill Gap Detection and Industry-Integrated
Recruitment Interface"* and the Knovik × University of Vavuniya Edge AI
proposal. See the [repository README](../README.md) for the full system
overview, status, and roadmap.

One Flutter codebase targeting Android, iOS, and web (the web build doubles
as the staff/admin surface served from the campus edge server).

## What's implemented

- **Student DLP** — living passport profile: skill vector, weekly VLE
  engagement chart, verified module record, external certifications.
- **Consent-controlled QR sharing** — the student chooses what enters the
  payload (assessment scores, engagement trail) before the QR is generated.
  The QR encodes a signed, self-contained passport verifiable offline.
- **Recruiter IIDLP** — scan a passport QR (or paste the payload), pick a
  target role, and see: verification badge, cosine-similarity skill match
  score, radar gap map, ranked skill gaps with learning recommendations,
  verified academic evidence, and a "warm start" onboarding plan.
- **Edge LM (on-device AI)** — both sides can paste a free-text job
  description and have it analyzed locally, with no network: the recruiter
  matches a scanned candidate against any JD; the student runs a "job fit
  check" from their passport. The engine extracts a requirement vector
  from the JD and composes a readiness narrative on the device.

## Architecture notes

- Data models ([lib/models/models.dart](lib/models/models.dart)) mirror the
  OULAD schema (Kuzilek et al., 2017). The bundled demo profiles
  ([lib/data/demo_data.dart](lib/data/demo_data.dart)) stand in for the
  Python pipeline output (`studentInfo ⋈ studentAssessment ⋈ assessments`,
  `studentVle ⋈ vle`); the pipeline should export per-student JSON matching
  `LearnerProfile.toJson`.
- The skill gap engine ([lib/services/skill_match.dart](lib/services/skill_match.dart))
  runs entirely on-device: cosine similarity over skill vectors. Heavy
  analysis (profile vector construction, SLM-generated recommendations)
  belongs on the campus edge server per the hybrid Edge AI design.
- The Edge LM ([lib/services/edge_lm/edge_lm.dart](lib/services/edge_lm/edge_lm.dart))
  is an interface with a deterministic lexicon implementation
  ([lexicon_edge_lm.dart](lib/services/edge_lm/lexicon_edge_lm.dart)) that
  runs on every target including web and tests. A quantized SLM backend
  (e.g. Gemma 1B via llama.cpp or MediaPipe on Android/iOS) is a drop-in
  replacement: implement `EdgeLm` and swap the `edgeLm` singleton — no UI
  or test changes required.
- QR signing ([lib/services/passport_codec.dart](lib/services/passport_codec.dart))
  is a placeholder digest; production replaces it with Ed25519 signatures
  issued by the institution's edge server.

## Run

```sh
flutter run            # device/simulator
flutter run -d chrome  # web
flutter test           # 13 unit + widget tests
flutter build web      # static bundle in build/web
```

Demo without two devices: recruiter flow → "Paste code" tab → "Load sample
candidate", or copy a payload from the student share screen.
