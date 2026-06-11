# Digital Learning Passport (DLP)

An AI-enabled system that transforms passive Learning Management System
(LMS) records into a verified, portable, living learner profile — with
skill gap detection for students and an industry-integrated recruitment
interface (IIDLP) for employers.

This repository hosts the full research and engineering effort by
**Knovik Private Limited, Sri Lanka**:

- **ICTer 2026 conference paper** (Industry R&D Track,
  [icter.lk](https://icter.lk/industry-rd-track/); submission due
  June 14, 2026) — Design Science Research treatment of the DLP,
  demonstrated on the Open University Learning Analytics Dataset (OULAD).
  Springer LNCS format, max 6 pages, double-blind review
- **Cross-platform prototype** (Flutter: Android, iOS, web) — the working
  proof of concept for both the student and recruiter experiences
- **Hybrid Edge AI architecture** — the product direction for the
  University of Vavuniya proposal: campus-edge servers plus on-device
  models for low-bandwidth contexts

## The system at a glance

```
┌─────────────────────────────────────────────────────────┐
│ Campus edge server (on-prem, no cloud)                   │
│  LMS connector → SSOT + Chroma DB → SLM + gap engine     │
│  (Moodle/VLE)    (verified data)    (batch analysis)     │
└──────────┬───────────────────────────────────▲──────────┘
           │ sync over campus Wi-Fi             │ consent-gated fetch
┌──────────▼──────────────┐      ┌─────────────┴──────────┐
│ Student device           │  QR  │ Recruiter device       │
│  DLP app (passport,      │ ───▶ │  IIDLP app (scan,      │
│  QR generator)           │      │  match score, gap map) │
│  Edge LM (~1B, offline)  │      │  offline verification  │
└──────────────────────────┘      └────────────────────────┘
```

Three artifacts, mapped to the paper's research questions:

1. **Skill gap detection engine** — constructs learner skill vectors from
   LMS signals (relative achievement, missed assessments, engagement
   velocity per Al-Gahmi 2025) and scores them against role requirement
   vectors via cosine similarity. Validated against held-out
   `final_result` labels on OULAD (32,593 students).
2. **Digital Learning Passport (student)** — a living profile the student
   owns beyond graduation: assessment trajectories, weekly VLE engagement,
   certifications. Shared as a **signed, consent-scoped QR snapshot**
   verifiable offline.
3. **IIDLP (recruiter)** — scan → verified candidate profile → skill
   match score → gap map → "warm start" onboarding plan. Includes
   **on-device Edge LM** job description analysis: paste any JD, get an
   extracted requirement vector and readiness narrative without the JD
   ever leaving the device.

## Repository layout

| Path | Contents |
|---|---|
| [`dlp_app/`](dlp_app/) | Flutter prototype (student DLP + recruiter IIDLP + Edge LM). See its [README](dlp_app/README.md) for run instructions and architecture notes. |
| [`paper/dlp-paper-icter.md`](paper/dlp-paper-icter.md) | Full ICTer 2026 manuscript (5 authors, DSR methodology, OULAD demonstration). Pending items are marked `[PENDING]` and listed in the notes block at the top, including the LNCS 6-page condensation and double-blind stripping required for submission. |
| `pipeline/` *(planned)* | Python/pandas OULAD join pipeline: `studentInfo ⋈ studentAssessment ⋈ assessments`, `studentVle ⋈ vle` → per-student JSON profiles matching the app's `LearnerProfile` schema. Fills the paper's Section 5 results. |
| `server/` *(planned)* | Campus edge server: FastAPI + Postgres (SSOT) + Chroma + Ollama serving open-source SLMs; Ed25519 passport signing. |

## Status

**Built and verified**

- Flutter app, one codebase for Android/iOS/web, 22 passing tests
- Student passport: skill profile, engagement chart, verified module
  record, certifications
- Consent-controlled QR sharing (signed payload, offline-verifiable)
- Recruiter flow: camera scan + paste fallback, match score, radar gap
  map, ranked gaps with recommendations, warm-start card
- Edge LM v1: deterministic on-device JD analysis behind a model-agnostic
  `EdgeLm` interface (drop-in seam for a quantized SLM such as Gemma 1B
  via llama.cpp/MediaPipe)
- Complete paper manuscript with three `[PENDING]` empirical blocks

**Not yet built**

- OULAD pipeline (highest priority: unblocks the paper's Section 5)
- Campus edge server and Ed25519 institutional signing (prototype uses a
  placeholder digest)
- Real SLM backend for the Edge LM interface (requires a physical device
  and model file)
- Recruiter field evaluation of the IIDLP / HR process model

**Known caveats**

- Cosine similarity over all-positive vectors inflates absolute match
  scores; rank ordering is reliable, absolute percentages overstate
  discrimination. Mean-centering is the planned fix (disclosed in the
  paper, Section 5.2).
- Demo profiles in the app are OULAD-shaped synthetic data until the
  pipeline ships.

## Quick start

```sh
cd dlp_app
flutter run -d chrome   # or a device/simulator
flutter test            # 22 unit + widget tests
```

Single-device demo: recruiter flow → "Paste code" tab → "Load sample
candidate". Two-device demo: generate a QR from the student share screen
and scan it with the recruiter flow on another device.

## Team

| Author | Role |
|---|---|
| Madusanka Premaratne Rathnayake Mudiyanselage ✉ | Corresponding author; architecture, prototype, OULAD pipeline, gap engine |
| Hasanthi Lakmali Thellapura Arachchilage | HR domain expertise, IIDLP design, recruiter process model |
| Dimuthma Umashani | Paper structure, methodology, literature, editing |
| Harini Madusha Naurunne Arachchilage | IIDLP gap analysis, real-world recruitment issue identification |
| Dr. Dillina Herath (ESU) | Academic supervisor |

Dataset: Kuzilek, J., Hlosta, M., & Zdrahal, Z. (2017). *Open University
Learning Analytics dataset.* Scientific Data 4, 170171
(CC-BY 4.0) — https://analyse.kmi.open.ac.uk/open-dataset

© 2026 Knovik Private Limited. Research prototype; not a production
system.
