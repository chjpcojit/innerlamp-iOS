# Software Requirements Specification — Temple

| Field | Value |
|---|---|
| Document type | Software Requirements Specification (SRS) — IEEE 29148-2018 |
| Feature | Temple |
| Product | InnerLamp |
| Version | 0.1 (draft) |
| Last updated | 2026-09-24 |
| Status | draft — awaiting confirmation of open questions |
| Owner / author | ba-writer (Business Analyst) |
| Downstream handoff | `spec-writer` → `requirements.md` / `design.md` / `tasks.md` |

---

## 1. Introduction

### 1.1 Purpose

This document is the Software Requirements Specification for the **Temple** feature of InnerLamp, an
iOS application for Buddhist practice. It defines — for stakeholders, the PM, and engineering — *what*
the feature must do, at business level, in IEEE 29148-2018 form, and it is the input that drives the
downstream engineering spec (`spec-writer` → `requirements.md` / `design.md` / `tasks.md`).

### 1.2 Scope

**In scope:**

- Browsing a curated **"top temples"** list (admin-curated, no user rating).
- Browsing the **full directory** of Buddhist places in Vietnam, loaded **page by page** with
  **infinite scroll** (page size 10).
- **Filtering** by place type and by region/province, and **searching** by name.
- Opening a **temple detail screen** ("Trang chùa") whose field set matches the design handoff
  prototype exactly (identity, stats, description, address, upcoming-sessions section, image).
- Loading temple **images** via thumbnail + full-size URLs with asynchronous client caching.
- Cross-feature navigation: the existing `Sangha` "Tìm đạo tràng" link and `openCommunity(id:)` /
  Profile `openCommunity(id:)` events resolve to this feature's screens.

**Out of scope:**

- A **map view** (temple pins) — deferred.
- **Following** a temple ("Theo dõi") — requires auth; deferred.
- **Donating** ("Cúng dường") — the detail screen only emits a navigation event toward the existing
  `offer` screen; the offering flow itself is out of scope.
- The **upcoming-sessions data source** ("Thời khóa sắp tới") — the detail renders the section, but
  the temple-events data belongs to a separate events feature.
- **Offline persistence** of the temple list (online-only; only images are cached).
- Any non-Vietnam places, and any write/CRUD or admin curation tooling on the client.

### 1.3 Product overview

InnerLamp is a Buddhist companion app (UIKit, Swift, Clean Architecture + MVVM-C) covering daily
practice, the lunar calendar, a sutra/meditation library, the Sangha community, and a practitioner
profile. The Temple feature is a **new, read-only discovery feature** that lets any user find and
learn about Buddhist places in Vietnam — chùa (temples), đạo tràng (practice centers), thiền
viện/thiền xá (meditation halls), and tịnh xá — and open a detail page for one place.

### 1.4 Definitions, acronyms, abbreviations

| Term | Definition |
|---|---|
| Temple / place | A unified business entity for any Buddhist place. Its `type` field distinguishes the kinds below. |
| Chùa | A temple (the default/generic kind). |
| Đạo tràng | A practice center / study group. Note: "Đạo tràng" is also the name of the existing Sangha tab — see §2.1 and the open question in §5. |
| Thiền viện / thiền xá | A meditation monastery / meditation hall. |
| Tịnh xá | A small monastic residence / hermitage. |
| Hệ phái | Buddhist sect/school (e.g. "Bắc tông", "Nam tông"). |
| Top temples | The admin-curated "top beautiful temples" list (no user rating). |
| Infinite scroll | Appending the next page automatically as the user scrolls near the list end. |
| Featured / curated | Ordered manually by an admin/editor, not by a user score or popularity metric. |

### 1.5 References

- `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html` — screen `Trang chùa`
  (`data-screen-label="Trang chùa"`, ~line 1018) and the bottom-nav screen map (`temple: 'Trang chùa'`).
- `InnerLamp/Presentation/Scenes/Sangha/README.md` — `openFindSangha` / `openCommunity(id:)` nav
  events currently TODO ("Temple screen `temple` not built").
- `Docs/Specs/API/openapi.yaml` — existing API envelope + auth contract (no temple endpoints yet).
- `Docs/Specs/Library/requirements.md` — the project's EARS + "⚠️ Not confirmed" convention this SRS follows.

### 1.6 Document organization

§2 describes the feature at a product level (perspective, functions, actors, environment, constraints,
assumptions). §3 gives the specific functional (`FR-*`) and non-functional (`NFR-*`) requirements.
§4 defines verification and the traceability matrix. §5 lists open questions.

---

## 2. Overall description

### 2.1 Product perspective

This is a **new feature** within InnerLamp. It fills a gap the existing prototype and code already
anticipate: the Sangha tab's "Tìm đạo tràng" (find temple) link and the `openCommunity(id:)` events in
Sangha/Profile currently end in TODOs pointing at a "`temple`" screen. This feature builds the missing
**list/discovery** screen and wires the **detail** screen the prototype already sketches. It touches one
external system — a **backend API** (not yet built) that stores temple records and serves list/detail
endpoints; see §3.1.3.

> ⚠️ Not confirmed: The feature reuses the domain term "đạo tràng" both as a *place type* (this feature)
> and as the *name of the Sangha tab* (the user's own community). Confirm whether "đạo tràng" is one
> concept shown in two places, or two distinct concepts that need distinct canonical terms — affects the
> glossary and the UI copy in `vi.json`.

### 2.2 Product functions

- Fetch and show the curated **top temples** list (`FR-001`).
- Fetch and show the **paginated directory** with infinite scroll (`FR-002`, `FR-010`).
- **Filter** by place type and region/province, and **search** by name (`FR-003`, `FR-004`, `FR-005`).
- Render loading / empty / error / offline states (`FR-006`–`FR-009`).
- Open a **temple detail** page with images and the prototype field set (`FR-011`–`FR-019`).
- Load images with a thumbnail + full-size, async-cached strategy (`FR-012`).

### 2.3 User classes and characteristics

| Actor | Description | Characteristics / permissions |
|---|---|---|
| Visitor | Any person using the app, signed-in or not. | Read-only access to the list and detail. No auth required to browse. |
| (Future) Follower | A signed-in user who follows a temple. | Deferred — "Theo dõi" is out of scope for this version. |
| Admin / editor | Curates the "top temples" list server-side. | Out of scope on the client; no admin tooling is built here. |

### 2.4 Operating environment

- Platform: iOS, minimum version per the existing project target (see `Info.plist`).
- Devices: iPhone (primary); iPad layout is not specifically designed in this version.
- Network: **online required** for list/detail; the only offline-capable asset is the image cache.

### 2.5 Design and implementation constraints

- Swift + UIKit (100% programmatic UI), Clean Architecture + MVVM-C + Coordinator, per `AGENTS.md`.
- Manual DI via `DIContainer`; repositories/data sources follow the existing Networking layer
  (`Endpoint`, `NetworkService`, `APIEnvelope`).
- No hardcoded user-facing text — every string reads from the JSON localization system
  (`"temple.*"` keys in `vi.json`); no inline font sizes or colors — use `ILTypography`, `ILColors`,
  `ILMetrics`, and existing Design System components before new views.
- No UIKit import in ViewModels/Domain; Domain is `Foundation`-only.
- The detail screen must match the prototype `Trang chùa` field set (see §3.2).

### 2.6 User documentation

**N/A** — this is a consumer app feature; no separate manual is produced.

### 2.7 Assumptions and dependencies

- **Assumptions:**
  - A backend will exist that stores temple records (images, name, type, sect, location, stats,
    description, address) and serves list/detail endpoints; the client proposes the contract (§3.1.3).
  - Browsing is public (no auth token required for list/detail).
  - "Top temples" is an admin-curated ordering, not a computed rating or popularity metric.
  - Page size is 10 (confirmed), adjustable server-side.
- **Dependencies:**
  - Backend API (temple endpoints) — not yet built; client is mock-first until confirmed.
  - `Core/Networking` (`Endpoint`, `NetworkService`, `APIEnvelope`) and the shared image-cache
    component (may need a new shared component — see §3.5).
  - Shared system-state views (`ILStateView` `.loading` / `.error` / `.offline`) for list states.
  - Cross-feature: `Sangha` (`openFindSangha`, `openCommunity(id:)`) and `Profile`
    (`openCommunity(id:)`) resolve their TODOs to this feature.
  - Deferred target screens: `offer` ("Cúng dường") and the temple-events feature ("Thời khóa sắp tới").

---

## 3. Specific requirements

### 3.1 External interface requirements

#### 3.1.1 User interfaces

Two screens, both new in code (the detail screen is sketched in the prototype; the list screen is not):

- **Temple list / discovery screen** (not yet designed in the prototype):
  - A pinned title; the curated "top temples" section; the paginated directory list (infinite scroll);
    filter controls for place type and region/province; a name search field/trigger.
  - Refer to `ILColors` / `ILTypography` / `ILMetrics` and existing components (`ILSectionHeaderView`,
    `ILChip`, `ILRow`, `ILTabHeaderView`) rather than inventing new ones.
- **Temple detail screen ("Trang chùa")** — matches the prototype `Trang chùa` field set (§3.2, `FR-013`–`FR-019`).

#### 3.1.2 Hardware interfaces

**N/A** — this is an iOS application feature with no custom hardware interface.

#### 3.1.3 Software interfaces

The backend REST API is **not yet built**; the client proposes the contract (mock-first, matching the
`Library` feature's approach). The following is the proposed shape, to be confirmed:

- `GET /v1/temples` — paginated directory (params: `page`/`cursor`, `page_size=10`, `type`, `region`,
  `q`). Response is the shared `{"success": true, "data": …}` envelope with a page of temple summaries
  and a pagination token/flag.
- `GET /v1/temples/top` — curated "top temples" list (no pagination, small fixed size).
- `GET /v1/temples/{id}` — full temple detail.

> ⚠️ Not confirmed: The exact endpoint paths, request parameters, response shapes, and error codes —
> blocks the DTO, Mapper, Endpoint, and Repository implementation. The client will code against a mock
> until the backend contract is fixed.

#### 3.1.4 Communication interfaces

- HTTPS + JSON. Requests use the existing `Endpoint`/`NetworkService` and the shared `APIEnvelope`
  (`{"success": true, "data": …}` / `{"success": false, "error": {code, message, type}}`).
- No bearer token is required for list/detail (public read).

### 3.2 Functional requirements

#### Temple list / discovery

**FR-001 — Curated "top temples" list**
- **Priority:** Must
- **Description:** WHEN the list screen loads, THE SYSTEM SHALL fetch and display the admin-curated "top temples" list.
- **Verification method:** Unit test (ViewModel) + manual QA against mock data.
- **Source:** User request ("lấy danh sách top các chùa đẹp ở VN") + curated-ranking answer.

**FR-002 — Paginated directory with infinite scroll**
- **Priority:** Must
- **Description:** WHEN the user scrolls near the end of the directory list, THE SYSTEM SHALL fetch the next page (page size 10) and append it without reloading the existing rows.
- **Verification method:** Unit test (pagination state) + UI test (scroll triggers append).
- **Source:** User request ("lấy danh sách chùa theo từng page") + infinite-scroll answer.

**FR-003 — Filter by place type**
- **Priority:** Must
- **Description:** WHEN the user selects a place type (e.g. chùa / thiền viện / tịnh xá), THE SYSTEM SHALL re-fetch and show only places of that type.
- **Verification method:** Unit test (filter state) + manual QA.
- **Source:** Filter answer ("Filter by place type").

**FR-004 — Filter by region/province**
- **Priority:** Should
- **Description:** WHEN the user selects a region/province, THE SYSTEM SHALL re-fetch and show only places in that region.
- **Verification method:** Unit test + manual QA.
- **Source:** Filter answer ("Filter by region/province").

**FR-005 — Search by name**
- **Priority:** Should
- **Description:** WHEN the user submits a name query, THE SYSTEM SHALL re-fetch and show places whose name matches the query.
- **Verification method:** Unit test + manual QA.
- **Source:** Filter answer ("Search by name").

**FR-006 — Loading state**
- **Priority:** Must
- **Description:** WHEN a list fetch is in flight, THE SYSTEM SHALL show a loading state (skeleton or spinner) instead of a blank area.
- **Verification method:** Manual QA / UI test.
- **Source:** Silent-gap detection (no state described in input).

**FR-007 — Empty state**
- **Priority:** Must
- **Description:** WHEN a fetch returns zero places (including a filter/search with no results), THE SYSTEM SHALL show the shared empty state instead of a blank list.
- **Verification method:** Unit test (empty state) + manual QA.
- **Source:** Silent-gap detection.

**FR-008 — Error state**
- **Priority:** Must
- **Description:** WHEN a list fetch fails (server/network error), THE SYSTEM SHALL show the shared error state with a retry action.
- **Verification method:** Unit test + manual QA.
- **Source:** Silent-gap detection.

**FR-009 — Offline state**
- **Priority:** Must
- **Description:** WHEN the device has no network on first load, THE SYSTEM SHALL show the shared offline state.
- **Verification method:** Manual QA (airplane mode).
- **Source:** Silent-gap detection + online-only answer.

**FR-010 — End-of-list handling**
- **Priority:** Must
- **Description:** WHEN the last page is reached, THE SYSTEM SHALL stop requesting further pages and indicate there are no more items (rather than looping or erroring).
- **Verification method:** Unit test (pagination boundary).
- **Source:** Edge-case detection.

**FR-011 — Open detail from a row**
- **Priority:** Must
- **Description:** WHEN the user taps a temple row, THE SYSTEM SHALL emit a navigation event carrying the temple id so the coordinator opens the detail screen.
- **Verification method:** Unit test (nav event) + UI test.
- **Source:** User request ("client xem các chùa") + list+detail answer.

**FR-012 — Async thumbnail image loading**
- **Priority:** Must
- **Description:** WHEN a temple row is shown, THE SYSTEM SHALL load its thumbnail asynchronously (and cache it) so scrolling stays smooth; a placeholder is shown while loading.
- **Verification method:** Manual QA (scroll + network throttle).
- **Source:** Image-handling answer.

#### Temple detail ("Trang chùa")

**FR-013 — Fetch and display detail**
- **Priority:** Must
- **Description:** WHEN the detail screen opens for a temple id, THE SYSTEM SHALL fetch and display that temple's full record.
- **Verification method:** Unit test (ViewModel) + manual QA.
- **Source:** Prototype `Trang chùa` + detail-field-set answer.

**FR-014 — Cover / hero image**
- **Priority:** Must
- **Description:** WHEN the detail screen shows, THE SYSTEM SHALL display the temple's cover image (full-size, async), with a placeholder while loading.
- **Verification method:** Manual QA.
- **Source:** Prototype hero area + image-handling answer.

**FR-015 — Identity block**
- **Priority:** Must
- **Description:** WHEN the detail screen shows, THE SYSTEM SHALL display the temple name, its sect ("Hệ phái"), and its district + city.
- **Verification method:** Manual QA.
- **Source:** Prototype ("Chùa Từ Quang", "Q. Bình Thạnh, TP.HCM · Hệ phái Bắc tông").

**FR-016 — Stats row**
- **Priority:** Must
- **Description:** WHEN the detail screen shows, THE SYSTEM SHALL display the three stats: follower count ("Phật tử"), sessions per week ("Thời khóa/tuần"), and founding year ("Năm lập").
- **Verification method:** Manual QA.
- **Source:** Prototype stats row (184 / 6 / 1938).

**FR-017 — Description**
- **Priority:** Must
- **Description:** WHEN the detail screen shows, THE SYSTEM SHALL display the temple's descriptive text (e.g. opening hours, notes for visitors).
- **Verification method:** Manual QA.
- **Source:** Prototype description block.

**FR-018 — Address and directions**
- **Priority:** Should
- **Description:** WHEN the detail screen shows, THE SYSTEM SHALL display the full address and a "chỉ đường" (directions) action that opens the platform Maps app at the temple's coordinates/address.
- **Verification method:** Manual QA (tap → Maps).
- **Source:** Prototype address row ("128 Nguyễn Văn Đậu, P.5 · chỉ đường").

**FR-019 — Upcoming-sessions section**
- **Priority:** Should
- **Description:** WHEN the detail screen shows and the temple has upcoming sessions, THE SYSTEM SHALL render the "Thời khóa sắp tới" section (session rows).
- **Verification method:** Manual QA.
- **Source:** Prototype "Thời khóa sắp tới" rows.
- **Note:** Only the rendering is in scope; the session data source belongs to the temple-events feature — see §5.

**FR-020 — "Cúng dường" navigation**
- **Priority:** Could
- **Description:** WHEN the user taps "Cúng dường", THE SYSTEM SHALL emit a navigation event toward the existing `offer` screen (out of scope to build here).
- **Verification method:** Unit test (nav event).
- **Source:** Prototype "Cúng dường" button.

**FR-021 — "Theo dõi" (Follow) — deferred**
- **Priority:** Out of scope (documented, not implemented)
- **Description:** The "Theo dõi" button is present in the prototype but is NOT built in this version; THE SYSTEM SHALL either hide it or render it disabled, per the final design decision.
- **Verification method:** Manual QA.
- **Source:** Follow out-of-scope answer.

### 3.3 Performance requirements

- **NFR-001 — First-page list load:** the first page should load within a target to be confirmed.
  > ⚠️ Not confirmed: the concrete response-time budget (e.g. ≤ 1500 ms on 4G) — blocks the performance test threshold.
- **NFR-002 — Scroll smoothness:** infinite-scroll appends and thumbnail image loading must not cause
  visible jank (target: 60 fps on a reference device).
- **NFR-003 — Image strategy:** thumbnail-first (load a small image, upgrade to full-size) to bound
  list memory and bandwidth; cached images are reused within a session.

### 3.4 Logical database requirements

- **Server-side (authoritative):** each temple record stores — id, name, type, sect (hệ phái),
  province/city/district, full address, coordinates, cover image (thumbnail + full-size URLs), an
  optional image gallery, description, follower count, sessions-per-week, founding year, and the
  admin-curated "top" flag/ordering.
  > ⚠️ Not confirmed: whether a temple has a single cover image or a gallery of multiple images —
  > blocks the Entity shape and the detail UI.
- **Client-side:** no local persistence for temple records (online-only, per the answer). The only
  client-side storage is the **image cache** (transient, managed by the shared image-cache component).

### 3.5 Design constraints

- Follow the InnerLamp Design System tokens (`ILColors`, `ILTypography`, `ILMetrics`) and prefer the 9
  existing shared components before building new views.
- Follow Clean Architecture: `ILTempleEntity` (pure business fields, Domain) vs `ILTempleStateModel`
  (UI-only state, Presentation) vs `ILTempleDTO` + `ILTempleMapper` (Data) — never mix concerns.
- Feature owns its files under `InnerLamp/Presentation/Scenes/Temple/` (and Domain/Data equivalents),
  matching the existing feature-per-folder convention.
- An image-cache component may be required; if none exists, add a **shared** component under
  `Presentation/Common/` rather than a feature-private cache.

### 3.6 Software system attributes

- **Reliability:** list and detail failures surface the shared error/offline states with retry; no
  crash on malformed or missing image data.
- **Availability:** the feature is online-only; it degrades gracefully to the offline/error states when
  the backend is unreachable.
- **Security:** read-only public data. No PII is collected, stored, or logged by this feature; all
  traffic is HTTPS. No bearer token is used for browse. Image and temple data are not PII.
- **Maintainability:** each functional requirement maps to a unit-testable ViewModel/UseCase seam; no
  hardcoded strings, colors, or one-off layouts.
- **Portability:** pure-Domain code (Entity/UseCase) is `Foundation`-only and device-agnostic; UI code
  targets iPhone with the existing responsive Design System tokens.

---

## 4. Verification & traceability

### 4.1 Verification approach

- **Unit tests** (`XCTest`) for ViewModel/UseCase logic: pagination boundary, filter/search state,
  empty state, nav events, and DTO→Entity mapping.
- **UI tests** for the infinite-scroll trigger and row→detail navigation.
- **Manual QA** for visual states (loading/empty/error/offline), image loading, and the "chỉ đường"
  deep link into Maps.
- Every `FR-*` carries its verification method; every `NFR-*` is verified by measurement or code review.

### 4.2 Traceability matrix

| Requirement ID | Source | Design | Test |
|---|---|---|---|
| FR-001 | User request — top list | → spec-writer | TBD |
| FR-002 | User request — pagination | → spec-writer | TBD |
| FR-003 | Filter answer — place type | → spec-writer | TBD |
| FR-004 | Filter answer — region | → spec-writer | TBD |
| FR-005 | Filter answer — name | → spec-writer | TBD |
| FR-006 | Silent-gap detection | → spec-writer | TBD |
| FR-007 | Silent-gap detection | → spec-writer | TBD |
| FR-008 | Silent-gap detection | → spec-writer | TBD |
| FR-009 | Silent-gap detection | → spec-writer | TBD |
| FR-010 | Edge-case detection | → spec-writer | TBD |
| FR-011 | User request + list/detail answer | → spec-writer | TBD |
| FR-012 | Image-handling answer | → spec-writer | TBD |
| FR-013 | Prototype `Trang chùa` | → spec-writer | TBD |
| FR-014 | Prototype hero | → spec-writer | TBD |
| FR-015 | Prototype identity block | → spec-writer | TBD |
| FR-016 | Prototype stats row | → spec-writer | TBD |
| FR-017 | Prototype description | → spec-writer | TBD |
| FR-018 | Prototype address row | → spec-writer | TBD |
| FR-019 | Prototype sessions section | → spec-writer | TBD |
| FR-020 | Prototype "Cúng dường" | → spec-writer | TBD |
| FR-021 | Follow out-of-scope answer | → spec-writer | TBD |
| NFR-001 | Non-functional (perf) | → spec-writer | TBD |
| NFR-002 | Non-functional (smoothness) | → spec-writer | TBD |
| NFR-003 | Non-functional (images) | → spec-writer | TBD |

---

## 5. Appendices

### Appendix A — Open questions

#### Open (unconfirmed)

> ⚠️ Not confirmed: How do the curated "top temples" list and the full paginated directory relate on
> the list screen (a featured section above the list, two tabs, or one list sorted by "top" first)? —
> blocks the list-screen layout and the `FR-001`/`FR-002` interplay.

> ⚠️ Not confirmed: What are the exact place-`type` enum values (chùa / thiền viện / thiền xá / tịnh xá
> / niệm phật đường / đạo tràng …)? — blocks the DTO enum and the type-filter chips.

> ⚠️ Not confirmed: What region/province taxonomy is used for `FR-004` (63 provinces, north/central/south,
> or a curated set)? — blocks the region filter UI and DTO.

> ⚠️ Not confirmed: Does a temple have a single cover image or a gallery of multiple images? — blocks
> the Entity shape and the detail image UI.

> ⚠️ Not confirmed: The exact backend endpoint paths, parameters, response shapes, and error codes
> (`GET /v1/temples`, `/top`, `/{id}` proposed) — blocks the DTO, Mapper, Endpoint, and Repository.

> ⚠️ Not confirmed: Pagination mechanics at the contract level — offset vs cursor, and the "has more"
> signal in the response — blocks `FR-002`/`FR-010` implementation details.

> ⚠️ Not confirmed: The concrete first-page load-time budget for `NFR-001` — blocks the performance
> test threshold.

> ⚠️ Not confirmed: The "đạo tràng" terminology collision (place type vs Sangha tab name) — blocks the
> glossary and `vi.json` copy.

> ⚠️ Not confirmed: Whether the "Thời khóa sắp tới" (`FR-019`) data comes from a shared temple-events
> feature or is fetched inline by this feature — blocks the detail ViewModel/data source.

> ⚠️ Not confirmed: Exact Vietnamese copy for empty/error/offline states and the list/detail titles —
> blocks `vi.json` keys (`"temple.*"`).

#### Open questions (resolved)

| Question | Resolution | Date |
|---|---|---|
| List vs detail scope | Build list + detail | 2026-09-24 |
| Place-type modeling | One entity + `type` field | 2026-09-24 |
| "Top" ranking | Admin-curated / featured | 2026-09-24 |
| Detail field set | Match the prototype | 2026-09-24 |
| Backend status | No backend yet — client defines contract (mock-first) | 2026-09-24 |
| Follow ("Theo dõi") | Out of scope for now | 2026-09-24 |
| Pagination UI | Infinite scroll | 2026-09-24 |
| Page size | 10 | 2026-09-24 |
| Map view | No map for now | 2026-09-24 |
| Filters / search | Type filter + region filter + name search | 2026-09-24 |
| Image handling | Thumbnail + full-size, async cache | 2026-09-24 |
| Offline behavior | Online-only | 2026-09-24 |
