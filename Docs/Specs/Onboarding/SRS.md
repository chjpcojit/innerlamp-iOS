# Software Requirements Specification — Onboarding

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Onboarding |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | il-ba (Business Analyst) |
| Downstream handoff | `il-spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Onboarding** feature of InnerLamp.
It defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the already-implemented feature and its
engineering spec.

### 1.2 Scope

**In scope:**

- A 3-step first-launch flow (intro → practice intents → bell reminders) owned by `AppCoordinator`.
- Step advancement, skip, and back navigation with appropriate CTA/back labels.
- Practice-intent chip toggles and bell toggles, with a swipe-to-change-step gesture.
- Local persistence of preferences and a completion flag.

**Out of scope:**

- Account creation and the subsequent OTP verification — owned by SignUp and Otp.
- Syncing preferences to a backend — preferences are local via `UserDefaultsService`.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Onboarding is the
**first-run** flow (Splash → Onboarding → SignUp / Login) that walks a first-time user through practice
intentions and bell-reminder preferences so the app feels personal from the first launch.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Practice intent | A user's selected practice intention (e.g. meditation, chanting). |
| Bell reminder | A user-enabled bell reminder setting. |
| Completion flag | The `has_completed_onboarding` flag that gates whether Splash routes to Onboarding or Main. |

### 1.5 References

- `Docs/Specs/Onboarding/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/Splash/`, `Docs/Specs/SignUp/` — the flow's neighbors.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html` (onboarding blocks).

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) requirements. §4 defines
verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp and the canonical shape later auth screens copied. It is a
cross-section navigation (Splash → Onboarding → SignUp / Login) owned by `AppCoordinator`
(`showOnboarding()`), set as the root of its own stack. There is **no** network — preference persistence
is local (`UserDefaultsService`).

### 2.2 Product functions

- Route to onboarding on first launch (`FR-001`).
- Show the 3-step flow with correct CTA/back labels (`FR-002`, `FR-003`).
- Persist preferences and complete on the last step / skip (`FR-004`, `FR-005`).
- Navigate back to a previous step or to Login (`FR-006`).
- Toggle intents and bells (`FR-007`).
- Swipe between steps with crossfade (`FR-008`).
- Record the completion flag (`FR-009`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| First-time user | Opens the app for the first time. | Walks through intents and bells, then continues to SignUp or Login. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: none — fully offline.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; the coordinator is owned by `AppCoordinator`.
- No hardcoded user-facing text; no inline font sizes or colors.
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - Preferences are local-only; there is no backend sync.
- **Dependencies:**
  - `UserDefaultsService` (persistence), `ILSplashUseCase` (reads the completion flag).
  - `SignUp` and `Login` (navigation targets).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

Three steps rendered by feature-scoped views (`ILOnboardingIntroStepView`, `ILOnboardingChoiceStepView`,
`ILOnboardingToggleListStepView`), a `ILStepProgressBar`, a primary CTA, a back button, and a skip
button. Reuses `ILButton`, `ILTypography`/`ILColors`/`ILMetrics`.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

**N/A** — no backend is called.

#### 3.1.4 Communication interfaces

**N/A** — no network.

### 3.2 Functional requirements

**FR-001 — First-launch routing**
- **Priority:** Must
- **Description:** WHEN the app launches for the first time (onboarding not yet completed), THE SYSTEM
  SHALL show a 3-step onboarding flow (intro → practice intents → bell reminders) owned by
  `AppCoordinator`.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (first-launch routing).

**FR-002 — Intro step**
- **Priority:** Must
- **Description:** WHEN the onboarding screen loads, THE SYSTEM SHALL show the intro step (step 0), with
  the primary CTA reading "Bắt đầu" and the back/footer label reading "Tôi đã có tài khoản", and a step
  progress bar with three segments.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (intro step).

**FR-003 — Step advancement and labels**
- **Priority:** Must
- **Description:** WHEN the user taps the primary CTA on a non-last step, THE SYSTEM SHALL advance to
  the next step; the CTA SHALL read "Tiếp tục" on step 1 and "Tạo tài khoản" on the last step, and the
  back label SHALL read "Quay lại" on non-first steps.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (step advancement).

**FR-004 — Complete on the last step**
- **Priority:** Must
- **Description:** WHEN the user taps the primary CTA on the last step, THE SYSTEM SHALL persist the
  selected intents and enabled bells, mark onboarding as completed, and navigate to the SignUp screen.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (completion).

**FR-005 — Skip**
- **Priority:** Must
- **Description:** WHEN the user taps "Bỏ qua" (skip) at any step, THE SYSTEM SHALL persist the current
  preferences, mark onboarding as completed, and navigate to SignUp.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (skip).

**FR-006 — Back navigation**
- **Priority:** Must
- **Description:** WHEN the user taps the back control on a non-first step, THE SYSTEM SHALL return to
  the previous step; WHEN the user taps it on the first step, THE SYSTEM SHALL navigate to the Login
  screen.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (back).

**FR-007 — Toggles**
- **Priority:** Must
- **Description:** WHEN the user taps a practice-intent chip, THE SYSTEM SHALL toggle that intent's
  selection; WHEN the user taps a bell toggle, THE SYSTEM SHALL toggle that bell's enabled state.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (toggles).

**FR-008 — Swipe between steps**
- **Priority:** Must
- **Description:** WHEN the user swipes horizontally on a step, THE SYSTEM SHALL crossfade to the
  adjacent step, tracking the finger, and commit the step change if the swipe passes a threshold.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (swipe).

**FR-009 — Completion flag**
- **Priority:** Must
- **Description:** WHEN onboarding completes, THE SYSTEM SHALL record the completion flag so that
  subsequent launches skip onboarding and go straight to the main flow.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (completion flag).

### 3.3 Performance requirements

- **NFR-001 — Step transition smoothness:** step changes and the swipe-driven crossfade should not jank
  on a reference device.

### 3.4 Logical database requirements

- **Client-side:** persisted via `UserDefaultsService` under three keys — `has_completed_onboarding`
  (Bool), `onboarding_selected_intents` ([Int]), `onboarding_enabled_bells` ([Int]).

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; reuse `ILStepProgressBar`, `ILButton`.
- Follow Clean Architecture (with a documented drift: `ILOnboardingStateModel` lives in Domain rather
  than Presentation, predating the current convention).

### 3.6 Software system attributes

- **Reliability:** fully offline; no network failure paths.
- **Availability:** works without connectivity.
- **Security:** preferences are non-sensitive; no PII is collected.
- **Maintainability:** one feature-scoped view per step; each requirement maps to a unit-testable
  ViewModel seam.
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for the ViewModel via `MockILOnboardingUseCase`: initial state,
  next-through-all-steps-and-complete, back-to-login, back-within-steps, skip, toggle intent, toggle
  bell.
- **Manual QA** for the swipe gesture and the visual layout.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | First-launch routing | → il-spec-writer | TBD |
| FR-002 | Intro step | → il-spec-writer | TBD |
| FR-003 | Step advancement | → il-spec-writer | TBD |
| FR-004 | Completion | → il-spec-writer | TBD |
| FR-005 | Skip | → il-spec-writer | TBD |
| FR-006 | Back navigation | → il-spec-writer | TBD |
| FR-007 | Toggles | → il-spec-writer | TBD |
| FR-008 | Swipe | → il-spec-writer | TBD |
| FR-009 | Completion flag | → il-spec-writer | TBD |
| NFR-001 | Transition smoothness | → il-spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

None.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Does onboarding need a network call? | No — preferences persisted locally via `UserDefaultsService` | 2026-09-27 |
