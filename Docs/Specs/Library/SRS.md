# Software Requirements Specification — Library

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Library |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-27 |
| Status | retroactive — reconstructed from `requirements.md` / `design.md` / `tasks.md` |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Library** feature of InnerLamp. It
defines — for the PM and engineering — *what* the feature must do, at business level, in IEEE
29148-2018 form. It is reconstructed retroactively from the implemented feature and its engineering
spec.

### 1.2 Scope

**In scope:**

- A library tab ("Thư viện") to browse sutras, guided meditations, and dharma talks.
- A category chip filter (Tất cả / Kinh văn / Thiền dẫn / Pháp thoại), a featured card, content rows, and
  a search-bar tap target.
- Navigation events toward Search, Detail, Talk, and Player screens.

**Out of scope:**

- The Search, Sutra detail, Reader, Dharma talk, and Player screens — Library only emits navigation
  events toward them.
- Loading skeleton, error, and offline full-screen states — owned by the shared system-state work.
- Downloads / offline listening.
- The Lamp, Sangha, and Me tab destinations.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C). Library is a **root
tab** of the app, reached across sections (Home ⇄ Library) and owned by `AppCoordinator`, where a
practitioner browses and opens practice content.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Content kind | `ILLibraryContentKind` — sutra / meditation / talk. |
| Category | `ILLibraryCategory` — all / sutra / meditation / talk, matching the four chips. |
| Tone | `ILLibraryTone` — gold/green/rose/ink, the colour of the book-glyph tile. |
| Featured card | The dark "always dark" hero card at the top of the list. |

### 1.5 References

- `Docs/Specs/Library/requirements.md`, `design.md`, `tasks.md`, `changelog.md`.
- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, screen `lib` (`isLib`).
- `Docs/Specs/Home/` — the tab Library is reached from Home.

### 1.6 Document organization

§2 describes the feature at a product level. §3 gives the functional (`FR-*`) and non-functional
(`NFR-*`) requirements. §4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp, a root tab that replaces the navigation stack root
(`setViewControllers`) and embeds its own `ILBottomNavBar`. It has **no network** today — the UseCase
returns a mock catalog. It follows the `Home` feature's shape (mock-backed UseCase, Entity → StateModel
mapping, `Views/` folder).

### 2.2 Product functions

- Render the Library layout with pinned title and bottom nav (`FR-001`–`FR-004`).
- Filter content by category chip (`FR-005`–`FR-009`).
- Render content rows and the featured card (`FR-010`–`FR-015`).
- Handle search, tab, and navigation taps (`FR-016`–`FR-018`).
- Read all copy from the localization system (`FR-019`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Practitioner | A signed-in user (or guest) browsing practice content. | Read-only browsing and filtering; taps route to child screens. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target.
- Devices: iPhone (primary).
- Network: none required today (mock catalog); a catalog API is intended later.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; the coordinator is owned by `AppCoordinator`.
- No hardcoded user-facing text — strings come from the JSON localization system (`"library.*"` keys);
  no inline font sizes or colors — use `ILTypography`, `ILColors`, `ILMetrics`.
- The featured card stays dark in both light and dark mode ("always dark" hero card).

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - A backend catalog endpoint will exist to replace the mock catalog.
  - The prototype's section-title copy is only defined for the default state; filtered-state titles are
    assumed (see §5).
- **Dependencies:**
  - Child screens (Search, Detail, Talk, Player) — not yet built; taps end in coordinator TODOs.
  - The Lamp / Sangha / Me tab destinations — not yet built.

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

A single screen, top to bottom: pinned title "Thư viện", a search bar (tap-only), four category chips,
one featured dark card, a section title + content-row list, and the bottom navigation bar with the
Library tab active. Reuses `ILSearchBarView`, `ILFeatureCardView`, `ILChip`, `ILRow`, `ILBottomNavBar`.

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

No backend is called today.

> ⚠️ Not confirmed: which backend endpoint(s) serve the library catalog, and the request/response shape
> (pagination? categories? featured item?) — blocks the Data layer (DTO, Mapper, Endpoint, Repository).

#### 3.1.4 Communication interfaces

- HTTPS + JSON through the shared `ApiResponse` envelope and `NetworkService` (once the catalog API
  exists).

### 3.2 Functional requirements

#### Layout

**FR-001 — Layout**
- **Priority:** Must
- **Description:** WHEN the Library screen loads, THE SYSTEM SHALL show, top to bottom: a pinned title
  "Thư viện", a search bar, a row of four category chips (Tất cả / Kinh văn / Thiền dẫn / Pháp thoại),
  one featured dark card, a section title with a list of content rows, and the bottom navigation bar
  with the Library tab active.
- **Verification method:** Manual QA + UI test.
- **Source:** EARS acceptance criterion (layout).

**FR-002 — Preselect "Tất cả"**
- **Priority:** Must
- **Description:** WHEN the screen loads, THE SYSTEM SHALL preselect the "Tất cả" chip.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (default selection).

**FR-003 — Pinned title and bottom nav on scroll**
- **Priority:** Must
- **Description:** WHEN the content is taller than the viewport, THE SYSTEM SHALL scroll the search bar,
  chips, featured card and list while keeping the title and the bottom navigation bar pinned.
- **Verification method:** Manual QA / UI test.
- **Source:** EARS acceptance criterion (pinned regions).

**FR-004 — Dark mode**
- **Priority:** Must
- **Description:** WHEN the device is in dark mode, THE SYSTEM SHALL render the screen with the dark
  token set (canvas, card, ink); the featured card stays dark in both modes.
- **Verification method:** Manual QA (light + dark).
- **Source:** EARS acceptance criterion (dark mode).

#### Category filter

**FR-005 — Category selection**
- **Priority:** Must
- **Description:** WHEN the user taps a category chip that is not selected, THE SYSTEM SHALL mark that
  chip selected, deselect the previous one, and show only the content rows belonging to that category
  ("Tất cả" shows every kind).
- **Verification method:** Unit test (in-memory filter).
- **Source:** EARS acceptance criterion (category filter).

**FR-006 — Tap selected chip**
- **Priority:** Must
- **Description:** WHEN the user taps the already-selected chip, THE SYSTEM SHALL keep the current
  selection and list unchanged.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (no-op on reselect).

**FR-007 — Empty category state**
- **Priority:** Must
- **Description:** WHEN the selected category has no content, THE SYSTEM SHALL replace the list with the
  shared empty state instead of a blank area.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (empty state).

**FR-008 — Section title update**
- **Priority:** Must
- **Description:** WHEN the category changes, THE SYSTEM SHALL update the list section title to match the
  category.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (section title).

**FR-009 — Featured card unchanged**
- **Priority:** Must
- **Description:** WHEN the category changes, THE SYSTEM SHALL leave the featured card unchanged.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (featured stability).

#### Content rows and featured card

**FR-010 — Row display**
- **Priority:** Must
- **Description:** WHEN a content row is shown, THE SYSTEM SHALL display its title, one-line subtitle,
  a trailing duration, and a tone-coloured book glyph tile.
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (row display).

**FR-011 — Duration formatting**
- **Priority:** Must
- **Description:** WHEN the duration is under 60 minutes, THE SYSTEM SHALL format it as "<n> phút";
  WHEN it is 60 minutes or more, THE SYSTEM SHALL format it as "<h>g <m>p", omitting the minutes part
  when it is 0.
- **Verification method:** Unit test (formatting cases).
- **Source:** EARS acceptance criterion (duration formatting).

**FR-012 — Row tap**
- **Priority:** Must
- **Description:** WHEN the user taps a content row, THE SYSTEM SHALL emit a navigation event carrying
  the item id and kind so the owning coordinator can open the matching detail screen.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (row tap).

**FR-013 — Featured card display**
- **Priority:** Must
- **Description:** WHEN the featured card is shown, THE SYSTEM SHALL display its eyebrow in caps, its
  serif title (may span two lines), and a pill button "Nghe · <duration>".
- **Verification method:** Manual QA.
- **Source:** EARS acceptance criterion (featured display).

**FR-014 — Featured tap**
- **Priority:** Must
- **Description:** WHEN the user taps anywhere on the featured card, THE SYSTEM SHALL emit a navigation
  event carrying the featured item id.
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (featured tap).

**FR-015 — No featured item**
- **Priority:** Must
- **Description:** WHEN no featured item is available, THE SYSTEM SHALL hide the featured card and keep
  the rest of the screen intact.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (featured hidden).

#### Search and navigation

**FR-016 — Search bar tap**
- **Priority:** Must
- **Description:** WHEN the user taps the search bar, THE SYSTEM SHALL emit a search navigation event
  (the bar is a tap target, not an editable field).
- **Verification method:** Unit test (nav event).
- **Source:** EARS acceptance criterion (search tap).

**FR-017 — Bottom nav tabs**
- **Priority:** Must
- **Description:** WHEN the user taps the "Trang chủ" tab, THE SYSTEM SHALL navigate to Home; WHEN the
  user taps the Library tab, THE SYSTEM SHALL do nothing (already active); WHEN the user taps the Lamp,
  Sangha or Me tab, THE SYSTEM SHALL do nothing until those screens exist.
- **Verification method:** Unit test.
- **Source:** EARS acceptance criterion (tab behavior).

**FR-018 — Home → Library crossfade**
- **Priority:** Must
- **Description:** WHEN the user taps the "Thư viện" tab on the Home screen, THE SYSTEM SHALL navigate
  to the Library screen with a crossfade transition.
- **Verification method:** UI test + manual QA.
- **Source:** EARS acceptance criterion (crossfade).

#### Copy

**FR-019 — Localization**
- **Priority:** Must
- **Description:** THE SYSTEM SHALL read every user-facing string from the JSON localization system
  (`"library.*"` keys in `vi.json`); no string literal in code.
- **Verification method:** Code review.
- **Source:** EARS acceptance criterion (copy).

### 3.3 Performance requirements

- **NFR-001 — Filter responsiveness:** category filtering is an in-memory operation and should feel
  instantaneous.
- **NFR-002 — Scroll smoothness:** the scrollable list should not jank on a reference device.

### 3.4 Logical database requirements

- **Client-side:** no local persistence for the catalog (mock in-memory data today); a server-backed
  catalog is intended later.

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens; reuse `ILSearchBarView`, `ILFeatureCardView`, `ILChip`,
  `ILRow`, `ILBottomNavBar` before building new views.
- Follow Clean Architecture: `ILLibraryEntity` (pure business fields, Domain) vs `ILLibraryStateModel`
  (UI-only state, Presentation). Domain must not import UIKit (the tone maps to `ILColors` in the
  ViewController).

### 3.6 Software system attributes

- **Reliability:** all content is local/mock, so the screen always renders; the empty state covers a
  category with no rows.
- **Availability:** works fully offline today.
- **Security:** no PII is collected or stored; the catalog is public content.
- **Maintainability:** one feature-scoped view per section; each requirement maps to a unit-testable
  ViewModel seam.
- **Portability:** pure-Domain code is `Foundation`-only.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for the ViewModel via `MockILLibraryUseCase`: initial state, category
  selection/no-op, empty state, section title, duration formatting, and the nav events.
- **Manual QA** for the layout (light + dark), pinned regions, and the featured card.
- **Code review** for the localization rule.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | Layout | → spec-writer | TBD |
| FR-002 | Preselect "Tất cả" | → spec-writer | TBD |
| FR-003 | Pinned regions | → spec-writer | TBD |
| FR-004 | Dark mode | → spec-writer | TBD |
| FR-005 | Category selection | → spec-writer | TBD |
| FR-006 | Reselect no-op | → spec-writer | TBD |
| FR-007 | Empty state | → spec-writer | TBD |
| FR-008 | Section title | → spec-writer | TBD |
| FR-009 | Featured stability | → spec-writer | TBD |
| FR-010 | Row display | → spec-writer | TBD |
| FR-011 | Duration formatting | → spec-writer | TBD |
| FR-012 | Row tap | → spec-writer | TBD |
| FR-013 | Featured display | → spec-writer | TBD |
| FR-014 | Featured tap | → spec-writer | TBD |
| FR-015 | No featured item | → spec-writer | TBD |
| FR-016 | Search tap | → spec-writer | TBD |
| FR-017 | Bottom nav tabs | → spec-writer | TBD |
| FR-018 | Crossfade | → spec-writer | TBD |
| FR-019 | Localization | → spec-writer | TBD |
| NFR-001 | Filter responsiveness | → spec-writer | TBD |
| NFR-002 | Scroll smoothness | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: which backend endpoint(s) serve the library catalog and its request/response shape —
> blocks the Data layer.

> ⚠️ Not confirmed: which screen each item kind opens (sutra → Detail, meditation → Setup/Session, talk →
> Talk) — the prototype wires every row to `detail` and the featured card to `talk`; meditation rows have
> no designed destination — blocks the coordinator navigation mapping.

> ⚠️ Not confirmed: the exact list section-title copy per category (the prototype only shows "Kinh thường
> tụng" for the default state) — blocks final copy in `vi.json`.

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| None | — | — |
