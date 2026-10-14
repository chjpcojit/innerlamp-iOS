# Software Requirements Specification — Splash

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Splash |
| Product | InnerLamp |
| Version | 0.6 (draft) |
| Last updated | 2026-10-11 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

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
- Routing to Main (when a stored login session exists), SignUp (no session, onboarding completed) or
  Onboarding (no session, onboarding not completed).
- Discarding stale credentials left on the device by a previous install or an older app version.

**Out of scope:**

- Onboarding itself and the Main app — owned by the Onboarding and Main features.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Splash is the **first
screen** — a pure branding moment (lamp ignition animation) owned top-level by `AppCoordinator`, while
the app determines where to route the user based on whether a login session is already stored
on the device.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Branding animation | The backdrop glow, ambience ripple/rays, lamp ignite + flicker, ember field, wordmark reveal, and tagline rise. |
| Auto-advance | The timer (3.2s) that fires after the animation has played long enough. |

### 1.5 References

- `Docs/Specs/Splash/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/Onboarding/` and `Docs/Specs/Main/` — the two navigation targets.
- `Docs/Tech-Debt/Splash/TD-Splash-001-stale-keychain-session-after-reinstall.md` — origin of the fresh-install credential cleanup.
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
- Route to Onboarding, Login or Main based on the stored session and onboarding status (`FR-004`,
  `FR-005`).
- Discard stale credentials (`FR-007`).
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
  - A stored access token means the user is logged in. Token expiry is not checked at launch; an expired
    token is refreshed automatically on the first request that gets rejected, and if the refresh fails the
    user is sent to Login.
  - A user who finished onboarding earlier but has no stored session is routed to SignUp. A first-time
    user sees Onboarding on the first launch only (`AS-Splash-001`, validated).
- **Dependencies:**
  - Secure on-device credential storage (Keychain) for the session check and the credential cleanup.
  - A local "has launched before" flag, which is erased when the app is deleted.
  - `Onboarding` and `Main` (navigation targets).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single static branding screen: backdrop, ambience, lamp glow, ember field, wordmark, and tagline.
No loading indicator. Reuses `ILLampGlowView` (`.splash`), `ILFlameView`, and feature-scoped
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
- **Acceptance criteria:**

  ```gherkin
  Scenario: Splash is the first screen
    Given the app is not running
    When the user opens the app
    Then the splash screen is shown before any other screen
  ```

**FR-002 — Branding animation**
- **Priority:** Must
- **Description:** WHEN the Splash screen appears, THE SYSTEM SHALL run the branding animation (backdrop
  glow, ambience ripple/rays, lamp ignite + flicker, ember field, wordmark reveal, tagline rise) without
  any user interaction. No loading indicator is shown.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (branding animation); design handoff `isSplash`.
- **Acceptance criteria:**

  ```gherkin
  Scenario: Animation plays without interaction
    Given the splash screen has appeared
    When the user does nothing
    Then the lamp ignites, the wordmark is revealed and the tagline rises into place

  Scenario: No loading indicator
    Given the splash screen is showing
    Then no loading dots or spinner are visible
  ```

**FR-003 — Auto-advance**
- **Priority:** Must
- **Description:** WHEN the splash animation has played long enough (about 3.2 seconds), THE SYSTEM SHALL
  auto-advance to the next screen.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (auto-advance).
- **Acceptance criteria:**

  ```gherkin
  Scenario: Splash advances on its own
    Given the splash screen has been showing for about 3.2 seconds
    When the timer elapses
    Then the app leaves the splash screen and shows Onboarding or the main app
  ```

**FR-004 — Route without a session**
- **Priority:** Must
- **Description:** WHEN the splash auto-advances AND no login session is stored on the device, THE SYSTEM
  SHALL route to SignUp if onboarding has been completed, and to Onboarding otherwise.
- **Verification method:** Unit test.
- **Source:** Implemented behavior; user decision 2026-10-10 (no token → Login); 2026-10-11 changed to SignUp; `AS-Splash-001`.
- **Acceptance criteria:**

  ```gherkin
  Scenario: First-time user without a session
    Given the user has not completed Onboarding
    And no login session is stored on the device
    When the splash screen auto-advances
    Then the user is shown Onboarding

  Scenario: Returning user who lost the session
    Given the user completed Onboarding in the past
    And no login session is stored on the device
    When the splash screen auto-advances
    Then the user is shown SignUp
  ```


**FR-005 — Route to Main**
- **Priority:** Must
- **Description:** WHEN the splash auto-advances AND a login session is stored on the device, THE SYSTEM
  SHALL route to the main app (Main).
- **Verification method:** Unit test.
- **Source:** Implemented behavior; supersedes the earlier "onboarding completed" criterion and its
  "temporarily hardcoded" note.
- **Acceptance criteria:**

  ```gherkin
  Scenario: Stored session
    Given a login session is stored on the device
    When the splash screen auto-advances
    Then the user is shown the main app

  Scenario: Stored session has expired but can be renewed
    Given a login session is stored on the device
    And the access token has expired
    When the splash screen auto-advances
    Then the user is shown the main app
    And the session is renewed automatically when the first request is rejected

  Scenario: Stored session can no longer be renewed
    Given a login session is stored on the device
    And the session cannot be renewed
    When the first request is rejected
    Then the stored session is removed
    And the user is taken to Login
  ```

**FR-006 — Re-resolve themed colors**
- **Priority:** Must
- **Description:** WHEN the light/dark appearance changes, THE SYSTEM SHALL re-resolve the themed splash
  colors (backdrop, glow, ripple, rays, wordmark, tagline) from the `--il-spl-*` token family.
- **Verification method:** Manual QA (light/dark).
- **Source:** EARS acceptance criterion (theming).
- **Acceptance criteria:**

  ```gherkin
  Scenario: Appearance changes while splash is showing
    Given the splash screen is showing in light appearance
    When the device switches to dark appearance
    Then the splash colors change to the dark variants
  ```

**FR-007 — Discard stale credentials**
- **Priority:** Must
- **Description:** WHEN the splash decides its route, THE SYSTEM SHALL (a) on the first launch after a
  fresh install, delete any access/refresh tokens left on the device by a previous install before
  checking for a session, and (b) delete the legacy pending sign-up credentials item if it exists.
- **Verification method:** Unit test.
- **Source:** Implemented behavior; `TD-Splash-001`.
- **Acceptance criteria:**

  ```gherkin
  Scenario: Reinstall does not resume the old session
    Given the app was deleted and installed again
    And login tokens from the previous install are still on the device
    When the app launches for the first time after the reinstall
    Then the stored tokens are removed
    And the user is shown Onboarding

  Scenario: Later launches keep the session
    Given the app has launched before on this install
    And a login session is stored on the device
    When the app launches again
    Then the stored session is kept
    And the user is shown the main app

  Scenario: Legacy sign-up credentials are removed
    Given pending sign-up credentials from an older app version are stored on the device
    When the splash decides its route
    Then those credentials are removed
  ```

### 3.3 Performance requirements

- **NFR-001 — Launch timing:** the splash should appear immediately and auto-advance after the 3.2s
  animation without jank.
- **NFR-002 — Route decision latency:** the session check and credential cleanup are local reads/deletes
  and must not delay or visibly stall the auto-advance.

### 3.4 Logical database requirements

- **Client-side:** the feature owns one local flag (`has_launched_before`: "app has launched on
  this install", stored in UserDefaults, erased with the app). It reads the login-session tokens from
  the Keychain and may delete them (`FR-007`); it never writes tokens.

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; theme via the `--il-spl-*` token family.
- Follow Clean Architecture (with a documented drift: `ILSplashStateModel` lives in Domain, predating
  the current convention).

### 3.6 Software system attributes

- **Reliability:** no failure-prone paths; the screen always renders.
- **Availability:** fully offline.
- **Security:** handles login tokens only to test existence or delete them; never logs, displays or
  transmits them. Deletes stale credentials left by older installs (`FR-007`).
- **Maintainability:** static branding separated into feature-scoped views.
- **Portability:** pure UIKit presentation.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests**: `ILSplashViewModelTests` (initial state; no session → Onboarding; no session +
  onboarding completed → SignUp; stored session → Main) and `ILSplashUseCaseTests` (fresh-install wipe, session kept after first launch, legacy
  credential purge, no token).
- **Manual QA** for the branding animation and light/dark theming.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Show first | → spec-writer | 1 scenario |
| FR-002 | Branding animation | → spec-writer | 2 scenarios |
| FR-003 | Auto-advance | → spec-writer | 1 scenario |
| FR-004 | Route without a session | → spec-writer | 2 scenarios |
| FR-005 | Route to Main | → spec-writer | 3 scenarios |
| FR-006 | Re-resolve themed colors | → spec-writer | 1 scenario |
| FR-007 | Discard stale credentials | → spec-writer | 3 scenarios |
| NFR-001 | Launch timing | → spec-writer | Manual QA |
| NFR-002 | Route decision latency | → spec-writer | Manual QA |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)





#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Where does the "already onboarded?" signal come from? | `ILOnboardingUseCase.isOnboardingCompleted()` — no longer used for routing as of 2026-10-10 | 2026-09-27 |
| Does Splash need a dynamic state model? | No — `ILSplashStateModel` is an empty marker | 2026-09-27 |
| Where should a user with no session who completed Onboarding go? | SignUp (`FR-004`; changed from Login by the user). | 2026-10-11 |
| Does a fresh install see Onboarding or Login? | Onboarding on the first launch only; SignUp after a lost session (`AS-Splash-001`, validated). | 2026-10-10 |
| Should launch validate or refresh the stored session before routing to Main? | No — route on existence only; the first rejected request refreshes automatically, and a failed refresh clears the session and goes to Login. | 2026-10-10 |
| When to flip the hardcoded Onboarding route? | Superseded: routing is by stored login session (`FR-004`/`FR-005`), not by onboarding completion. Product decision date not recorded. | 2026-10-10 |
