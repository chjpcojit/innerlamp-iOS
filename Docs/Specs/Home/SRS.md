# Software Requirements Specification — Home

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Home |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Home** feature of InnerLamp. It
defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the already-implemented feature and its
engineering spec.

### 1.2 Scope

**In scope:**

- A home screen that greets the user by name and surfaces the daily quote, practice progress, the bead
  counter, and shortcuts to the app's main sections.
- The section layout: weekly calendar strip, lunar hero card (with daily quote), photo gallery, temple
  carousel, statistics, bead counter, bell card, suggested-session list, and articles list.
- A bead counter with increment (wrapping) and reset.
- Navigation events to eight child features.

**Out of scope:**

- The content of each child screen — Mala, LunarCalendar, Photos, Bell, Events, Article, Temple,
  MeditationSetup are owned by their own features.
- The Reader (Đọc kinh) and Offering (Cúng dường) screens — the `.sutra` / `.offering` rows currently
  do nothing.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Home is the **first
tab** of the post-auth shell (`ILMainTabBarController`) and a hub screen: it renders mock content and
routes taps to eight child features.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Hub screen | A screen that aggregates content and routes navigation to child features rather than owning them. |
| Guest label | The fallback greeting shown when no display name is stored. |
| Bead counter | A mala bead counter that increments to a goal (108) and wraps back to 1. |

### 1.5 References

- `Docs/Specs/Home/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, block `isHome`.
- `Docs/Specs/Main/` — the tab shell that owns Home as its first tab.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp, the first tab of the post-auth shell. It is owned by
`ILMainTabCoordinator` (not `AppCoordinator` directly), which gives it its own `BaseNavigationController`.
It has **no network** today — the UseCase returns mock content and reads the greeting name from
`KeychainService`.

### 2.2 Product functions

- Greet the user and show the current solar + lunar date (`FR-001`).
- Render the ordered section layout from mock content (`FR-002`).
- Operate the bead counter (increment / reset) (`FR-003`, `FR-004`).
- Route taps to child features (`FR-005`), and do nothing for unbuilt destinations (`FR-006`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Signed-in user (or guest) | Reaches Home after login/registration/guest entry. | Reads content and navigates to child features; interacts with the bead counter. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: none required today (mock content); a dashboard API is intended later.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; the coordinator is owned by `ILMainTabCoordinator`.
- No hardcoded user-facing text — strings come from the JSON localization system (`"home.*"` keys); no
  inline font sizes or colors — use `ILTypography`, `ILColors`, `ILMetrics`, and existing components.
- No UIKit import in ViewModels/Domain.

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - A dashboard/content API will exist to replace the mock content.
  - The greeting name will eventually come from a real session service.
- **Dependencies:**
  - Eight child features (Mala, LunarCalendar, Photos, Bell, Events, Article, Temple, MeditationSetup).
  - `ILLunarCalendar` (real lunar-date conversion) and `KeychainService` (name read).
  - `ILMainTabCoordinator` (tab ownership).

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single scrolling hub screen composed of feature-scoped views: greeting header, weekly calendar strip,
lunar hero card, photo grid, temple carousel, statistics, bead card, bell card, suggested-session list,
and articles list. Uses the Design System tokens and existing components.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

No backend is called today.

> ⚠️ Not confirmed: the dashboard/content API contract(s) — there is no home-dashboard endpoint in
> `Docs/Specs/API/openapi.yaml` v3.9 — blocks the Data layer (DTO, Mapper, Endpoint, Repository).

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope and `NetworkService` (once the dashboard API
  exists).

### 3.2 Functional requirements

**FR-001 — Greeting and date**
- **Priority:** Must
- **Description:** WHEN the Home screen loads, THE SYSTEM SHALL greet the user by their registered
  display name (falling back to a guest label when no name is stored) and show the current solar + lunar
  date.
- **Verification method:** Unit test (ViewModel, guest fallback) + manual QA.
- **Source:** EARS acceptance criterion (greeting + date).

**FR-002 — Section rendering**
- **Priority:** Must
- **Description:** WHEN the Home screen loads, THE SYSTEM SHALL render the sections in this order:
  weekly calendar strip, lunar hero card (with daily quote), photo gallery, temple carousel, statistics
  (session progress + streak), bead counter, bell card, suggested-session list, and articles list — all
  from mock data.
- **Verification method:** Unit test + manual QA.
- **Source:** EARS acceptance criterion (section order).

**FR-003 — Bead increment**
- **Priority:** Must
- **Description:** WHEN the user taps the bead counter, THE SYSTEM SHALL increment the bead count by
  one, wrapping back to 1 after the goal (108) instead of stopping.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (bead increment).

**FR-004 — Bead reset**
- **Priority:** Must
- **Description:** WHEN the user taps "Bắt đầu lại" (reset) on the bead counter, THE SYSTEM SHALL reset
  the bead count to zero.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (bead reset).

**FR-005 — Navigation targets**
- **Priority:** Must
- **Description:** WHEN the user taps a navigation target, THE SYSTEM SHALL open the corresponding child
  screen: "Toàn màn hình" on the bead card → Mala; "Lịch âm" or the lunar hero card → LunarCalendar;
  "Xem tất cả" / a photo tile → Photos; the bell card → Bell; "Tất cả" under events → Events; an article
  → Article (by id); a temple in the carousel → Temple (by id); a meditation row → MeditationSetup.
- **Verification method:** Unit test (8 nav events) + UI test.
- **Source:** EARS acceptance criterion (navigation targets).

**FR-006 — Unbuilt destination no-op**
- **Priority:** Must
- **Description:** WHEN the user taps a "sutra" or "offering" suggested-session row, THE SYSTEM SHALL NOT
  navigate (those destinations are not built yet).
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (sutra/offering no-op).

### 3.3 Performance requirements

- **NFR-001 — Load time:** the screen renders from local mock data with no network; it should reach a
  usable state without perceptible delay.
- **NFR-002 — Scroll smoothness:** the long scrolling hub should not jank on a reference device.

### 3.4 Logical database requirements

- **Client-side:** the bead count is **memory-only** (not persisted, not synced with the full-screen
  Mala screen). The greeting name is read from `KeychainService` (temporary arrangement).

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; assemble the screen from existing components and
  feature-scoped views before building new ones.
- Follow Clean Architecture: `ILHomeEntity` (pure business fields, Domain) vs `ILHomeStateModel`
  (UI-only state, Presentation). No UIKit import in Domain/StateModel.

### 3.6 Software system attributes

- **Reliability:** all content is local/mock, so the screen always renders; no network failure path.
- **Availability:** works fully offline today.
- **Security:** the greeting name is a non-secret display value read from the Keychain; no other data is
  collected.
- **Maintainability:** one feature-scoped view per section; each requirement maps to a unit-testable
  ViewModel seam.
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for the ViewModel via `MockILHomeUseCase`: initial state (incl.
  photos/temples/articles/bell), guest-name fallback, bead increment/reset, and the eight nav events.
- **Manual QA** for the visual layout and scroll behavior.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Greeting + date | → spec-writer | TBD |
| FR-002 | Section rendering | → spec-writer | TBD |
| FR-003 | Bead increment | → spec-writer | TBD |
| FR-004 | Bead reset | → spec-writer | TBD |
| FR-005 | Navigation targets | → spec-writer | TBD |
| FR-006 | Unbuilt destination no-op | → spec-writer | TBD |
| NFR-001 | Load time | → spec-writer | TBD |
| NFR-002 | Scroll smoothness | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: the dashboard/content API contract(s) — no home-dashboard endpoint in
> `Docs/Specs/API/openapi.yaml` v3.9 — blocks the Data layer (DTO, Mapper, Endpoint, Repository).

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| How is the "today" lunar date computed? | Via `ILLunarCalendar.solarToLunar` (real conversion), not a hardcoded string | 2026-09-27 |
