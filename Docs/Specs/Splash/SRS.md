# Software Requirements Specification — Splash

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Splash |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | il-ba (Business Analyst) |
| Downstream handoff | `il-spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Splash** feature of InnerLamp. It
defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the already-implemented feature and its
engineering spec.

### 1.2 Scope

**In scope:**

- A brief branded splash screen shown first at launch, with the lamp ignition animation.
- Automatic advance to the next screen after the animation.
- Routing to Onboarding (when onboarding is incomplete) or Main (when complete).

**Out of scope:**

- Onboarding itself and the Main app — owned by the Onboarding and Main features.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Splash is the **first
screen** — a pure branding moment (lamp ignition animation) owned top-level by `AppCoordinator`, while
the app determines where to route the user.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Branding animation | The backdrop glow, ambience ripple/rays, lamp ignite + flicker, ember field, wordmark reveal, tagline rise, and pulsing dots. |
| Auto-advance | The timer (3.2s) that fires after the animation has played long enough. |

### 1.5 References

- `Docs/Specs/Splash/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/Onboarding/` — supplies the `isOnboardingCompleted()` signal.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, block `isSplash`.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) requirements. §4 defines
verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp, the first screen shown at launch. It is owned top-level by
`AppCoordinator` (`start()` → `showSplash()`), set as the root of its own stack. It has **no** network
and **no** dynamic content.

### 2.2 Product functions

- Show the splash first (`FR-001`).
- Run the branding animation (`FR-002`).
- Auto-advance (`FR-003`).
- Route to Onboarding or Main (`FR-004`, `FR-005`).
- Re-resolve themed colors on appearance change (`FR-006`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| User opening the app | Any user (first-time or returning). | Sees the splash briefly, then is routed onward. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: none.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`.
- No hardcoded colors — themed via the `--il-spl-*` token family.
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - The splash routes to Onboarding while development is ongoing, then to Main for already-onboarded
    users once the routing decision is made.
- **Dependencies:**
  - `ILOnboardingUseCase.isOnboardingCompleted()` (injected) for the routing signal.
  - `Onboarding` and `Main` (navigation targets).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single static branding screen: backdrop, ambience, lamp glow, ember field, wordmark, tagline, and
pulsing dots. Reuses `ILLampGlowView` (`.splash`), `ILFlameView`, `ILLoadingDotsView`, and feature-scoped
branding views.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

**N/A** — no backend is called.

#### 3.1.4 Communication interfaces

**N/A** — no network.

### 3.2 Functional requirements

**FR-001 — Show splash first**
- **Priority:** Must
- **Description:** WHEN the app launches, THE SYSTEM SHALL show the Splash screen first (before any other
  screen), owned by `AppCoordinator`.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (first screen).

**FR-002 — Branding animation**
- **Priority:** Must
- **Description:** WHEN the Splash screen appears, THE SYSTEM SHALL run the branding animation (backdrop
  glow, ambience ripple/rays, lamp ignite + flicker, ember field, wordmark reveal, tagline rise, pulsing
  dots) without any user interaction.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (branding animation).

**FR-003 — Auto-advance**
- **Priority:** Must
- **Description:** WHEN the splash animation has played long enough, THE SYSTEM SHALL auto-advance to the
  next screen.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (auto-advance).

**FR-004 — Route to Onboarding**
- **Priority:** Must
- **Description:** WHEN onboarding has not been completed, THE SYSTEM SHALL route to Onboarding.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (route to Onboarding).

**FR-005 — Route to Main**
- **Priority:** Must
- **Description:** WHEN onboarding has already been completed, THE SYSTEM SHALL route to the main app
  (Main). *(Temporarily hardcoded — see §5.)*
- **Verification method:** Unit test (once the routing is re-enabled).
- **Source:** EARS acceptance criterion (route to Main).

**FR-006 — Re-resolve themed colors**
- **Priority:** Must
- **Description:** WHEN the light/dark appearance changes, THE SYSTEM SHALL re-resolve the themed splash
  colors (backdrop, glow, ripple, rays, wordmark, tagline) from the `--il-spl-*` token family.
- **Verification method:** Manual QA (light/dark).
- **Source:** EARS acceptance criterion (theming).

### 3.3 Performance requirements

- **NFR-001 — Launch timing:** the splash should appear immediately and auto-advance after the 3.2s
  animation without jank.

### 3.4 Logical database requirements

- **Client-side:** no persistence owned by this feature; it reads `isOnboardingCompleted()` from the
  injected `ILOnboardingUseCase` (which reads `has_completed_onboarding`).

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; theme via the `--il-spl-*` token family.
- Follow Clean Architecture (with a documented drift: `ILSplashStateModel` lives in Domain, predating
  the current convention).

### 3.6 Software system attributes

- **Reliability:** no failure-prone paths; the screen always renders.
- **Availability:** fully offline.
- **Security:** no data handled.
- **Maintainability:** static branding separated into feature-scoped views.
- **Portability:** pure UIKit presentation.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`ILSplashViewModelTests`) for initial state and `splashFinished` → `.goToOnboarding`.
- **Manual QA** for the branding animation and light/dark theming.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Show first | → il-spec-writer | TBD |
| FR-002 | Branding animation | → il-spec-writer | TBD |
| FR-003 | Auto-advance | → il-spec-writer | TBD |
| FR-004 | Route to Onboarding | → il-spec-writer | TBD |
| FR-005 | Route to Main | → il-spec-writer | TBD |
| FR-006 | Re-resolve themed colors | → il-spec-writer | TBD |
| NFR-001 | Launch timing | → il-spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: when to flip the routing branch to use `isOnboardingCompleted()` — it is a product
> decision (always route through Onboarding during current development vs. skip to Main for
> already-onboarded users) — blocks the routing item.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Where does the "already onboarded?" signal come from? | `ILOnboardingUseCase.isOnboardingCompleted()` (injected, no direct UserDefaults read) | 2026-09-27 |
| Does Splash need a dynamic state model? | No — `ILSplashStateModel` is an empty marker | 2026-09-27 |
