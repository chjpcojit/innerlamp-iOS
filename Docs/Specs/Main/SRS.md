# Software Requirements Specification — Main

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Main |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Main** tab-bar shell of InnerLamp.
It defines — for the PM and engineering — *what* the shell must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the already-implemented shell and its
engineering spec.

### 1.2 Scope

**In scope:**

- The post-auth tab-bar shell with four tabs — Home, Library, Sangha, Me — plus a prominent central
  lamp button.
- Tab switching with crossfade and active-highlight sync.
- A full-screen meditation-setup modal from the lamp button.
- Hiding/showing the bottom bar for child overlays.

**Out of scope:**

- The content of each tab — Home, Library, Sangha, and Profile are owned by their own features.
- The meditation-setup flow itself — owned by the MeditationSetup feature.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Main is the
post-auth container: a coordinator (`ILMainTabCoordinator`) plus a `BaseTabBarController` subclass
(`ILMainTabBarController`) that owns four per-tab coordinators. It is a container/coordinator feature,
not a single screen.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Tab shell | The bottom tab bar plus the per-tab navigation stacks it owns. |
| Central lamp action | The prominent center button that starts a meditation — an action, not a tab. |

### 1.5 References

- `Docs/Specs/Main/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/Specs/Home/`, `Docs/Specs/Library/` — the implemented tabs.
- `Docs/design_handoff_innerlamp/design/IL-BottomNav.dc.html`.

### 1.6 Document organization

§2 describes the shell at a product level. §3 gives the functional (`FR-*`) requirements. §4 defines
verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new container feature** within InnerLamp, reached from Login success, guest preview, OTP
verify, and (eventually) Splash. It is owned by `AppCoordinator` (`showMain()`) and owns four per-tab
coordinators, each with its own `BaseNavigationController`. It has **no** Domain/Data layer and **no**
network.

### 2.2 Product functions

- Present the 4-tab shell after auth (`FR-001`).
- Switch tabs and sync the active highlight (`FR-002`).
- Open the meditation-setup modal from the lamp button (`FR-003`).
- Crossfade between tab content (`FR-004`).
- Hide/show the bottom bar (`FR-005`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Signed-in user (or guest) | Reaches Main after login/registration/guest entry. | Navigates between the four tabs and starts a meditation. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: none — the shell is offline.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; `ILMainTabBarController` extends `BaseTabBarController`.
- The native `UITabBar` is hidden; the design uses the custom `ILBottomNavBar`.
- No hardcoded user-facing text; no inline font sizes or colors.

### 2.6 User documentation

**N/A** — this is a consumer app container; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - The central lamp button is an action (not a fifth tab).
  - The four tabs are wired to real coordinators (no placeholder remains in use).
- **Dependencies:**
  - `Home`, `Library`, `Sangha`, `Profile` feature coordinators (via `DIContainer`).
  - `MeditationSetup` coordinator for the lamp action.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

The bottom bar (`ILBottomNavBar`) with four tabs (Home, Library, Sangha, Me) and a central lamp button.
Tab content is rendered by each tab's coordinator in its own `BaseNavigationController`.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

**N/A** — no backend or software interface; the shell is a pure container.

#### 3.1.4 Communication interfaces

**N/A** — no network.

### 3.2 Functional requirements

**FR-001 — Present the tab shell**
- **Priority:** Must
- **Description:** WHEN the user finishes login / registration / onboarding (or enters as a guest), THE
  SYSTEM SHALL present the Main tab-bar shell with four tabs in order: Home, Library, Sangha, Me.
- **Verification method:** UI test + manual QA.
- **Source:** EARS acceptance criterion (tab shell).

**FR-002 — Tab switching**
- **Priority:** Must
- **Description:** WHEN the user taps a tab, THE SYSTEM SHALL switch to that tab and update the bottom
  bar's active highlight to match.
- **Verification method:** Manual QA / UI test.
- **Source:** EARS acceptance criterion (tab switch + highlight).

**FR-003 — Central lamp action**
- **Priority:** Must
- **Description:** WHEN the user taps the central lamp button, THE SYSTEM SHALL present the
  meditation-setup screen as a full-screen modal.
- **Verification method:** UI test + manual QA.
- **Source:** EARS acceptance criterion (lamp action).

**FR-004 — Crossfade on tab switch**
- **Priority:** Must
- **Description:** WHEN a tab is switched, THE SYSTEM SHALL crossfade between tab content (the
  `BaseTabBarController` default transition).
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (crossfade).

**FR-005 — Hide/show bottom bar**
- **Priority:** Must
- **Description:** WHEN a child screen inside a tab needs the bottom bar hidden (e.g. a full-screen
  overlay), THE SYSTEM SHALL support hiding/showing the bottom bar.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (bottom bar hide/show).

### 3.3 Performance requirements

- **NFR-001 — Tab responsiveness:** tab switching and the crossfade should feel immediate on a reference
  device.

### 3.4 Logical database requirements

- **N/A** — no persistence in this feature.

### 3.5 Design constraints

- Follow the InnerLamp Design System (`ILBottomNavBar`); the native `UITabBar` is hidden because the
  design uses a custom bar, while tab switching still routes through `UITabBarController` for the
  crossfade.

### 3.6 Software system attributes

- **Reliability:** the shell is a pure container with no failure-prone paths.
- **Availability:** fully offline.
- **Security:** no data handled by this feature.
- **Maintainability:** one coordinator + one tab-bar controller; no Domain/Data layer to drift.
- **Portability:** pure UIKit presentation.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **UI tests / manual QA** for tab switching, the lamp modal, and the crossfade.
- **Code review** for the tab wiring.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Tab shell | → spec-writer | TBD |
| FR-002 | Tab switching | → spec-writer | TBD |
| FR-003 | Lamp action | → spec-writer | TBD |
| FR-004 | Crossfade | → spec-writer | TBD |
| FR-005 | Hide/show bottom bar | → spec-writer | TBD |
| NFR-001 | Tab responsiveness | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

None.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| Is the central lamp button a fifth tab or an action? | An action, not a tab (`.lamp` is absent from `tabOrder`) | 2026-09-27 |
| Do Sangha and Me still use the placeholder? | No — replaced by real coordinators; the placeholder is now unused | 2026-09-27 |
