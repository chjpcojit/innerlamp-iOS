# Changelog — Calendar Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v1.1 (2026-10-15) — superseded festival docs removed

- `requirements.md`: no change needed (header re-synced). The resolved questions and Pending items
  still name `AS-Festivals-001…002`, `AS-FestivalDetail-001…002`, `AS-Home-003`,
  `TD-FestivalDetail-001…002` and `TD-Home-003` as history; those files now exist only in git history.
- `design.md`: no change needed (header re-synced).
- `tasks.md`: Phase 9 — ticked "`Docs/Specs/Home/` pointer" (Home spec v1.12) and "Remove the
  superseded iOS docs" (deleted `Docs/Specs/FestivalDetail/`, the two Festivals and two
  FestivalDetail assumptions, `AS-Home-003`, the two FestivalDetail tech-debt entries and
  `TD-Home-003`; the Festivals / FestivalDetail / Home scene READMEs and the comments in
  `ILCalendarEventRepository` and `ILFestivalDetailStateModel` now cite this spec). The README
  refresh item stays open: only their citations changed, the behavior notes follow Phase 4.
- Reason: the product owner asked to delete the old "Sự kiện Phật giáo" docs now that this spec
  exists — last step of the docs pipeline. Docs only; no Swift logic changed.

## v1.0 (initial) (2026-10-15)

Initial spec written retroactively from the already-implemented festival calendar (`Festivals`), event
detail (`FestivalDetail`) and Home's events block, against the cross-platform product spec innerlamp-be
`docs/product/calendar/product.md` @ v1.1, the contract `docs/specs/api/openapi.yaml` @ 0eb7d1f
(`calendarEvents`, last changed a8a016b) and the planned backend shape in
`docs/specs/features/calendar/` v3.0 (merged in 0eb7d1f, not implemented). Docs only; no code changed.

- `requirements.md`: header `Product spec` / `Contract` / `Implements` (the iOS column of product §4.2:
  BR-CAL-05, 08…15, FR-CAL-001…008, NFR-CAL-03); 24 EARS criteria, each tagged with the product ID or
  `(platform)`; Error → UI table citing the one operation; Pending lists what the code does not meet yet
  by criterion number; resolved questions record which old iOS assumption or tech-debt entry each product
  decision replaces.
- `design.md`: one shared year-based data layer (memory + device copy, planned) for the three surfaces;
  `ILCalendarRules` (planned) as the single place for countdown, order and home block; Step-by-step Flow
  for the shared year load (Y-1…Y-4), the calendar (F), load more (M), the detail (D) and the home block
  (H, two years at once); "Server sync" names the v3.0 fields the app adopts and how it behaves before
  they ship; "Product vectors"; "Dependencies" (Sangha reuses festival types; Home spec sections
  replaced).
- `tasks.md`: Phase 1–3 `[x]` only where verified in code; Phase 4 drift, Phase 5 device copy,
  Phase 6 waits on backend Phase 14–18, Phase 7 vectors, Phase 8 copy (⚠️ product), Phase 9 docs
  (README refresh, Home spec pointer, removal of the superseded docs in a later step, OKF).
- Reason: step 4 of the docs pipeline — move the calendar from scattered iOS assumptions to the
  three-layer model (product spec → contract → platform spec).
- Drift found (code vs product v1.1): local Rằm / Mùng Một on days without a server occurrence
  (BR-CAL-05); "Lễ lớn" = every named event, chips "Tất cả / Lễ lớn / Rằm & Mùng Một", no group chips or
  counts, no group names or major mark on rows (BR-CAL-09, BR-CAL-10, FR-CAL-003); year from the device
  time zone, loads up to 2200, silent next-year retry (FR-CAL-002, FR-CAL-004); "Chưa có…" placeholders on
  every empty section, sutra and temple sections, not-found offers retry (BR-CAL-14, FR-CAL-005); home
  block = whole calendar year, every group, first three by date, empty months dropped, disappears on
  failure (BR-CAL-15, FR-CAL-006, FR-CAL-008); no device copy (FR-CAL-007); first-load failure on the
  calendar is a toast with no retry (FR-CAL-008); endpoint needs a token (FR-CAL-001); countdown computed
  in three places, list copy "còn N ngày"; vectors not run; an unused Core Data event catalogue
  (`ILBuddhistEvent*`) is still compiled.
- Platform defaults chosen (each marked `⚠️ Not confirmed` with the default; merging approves them):
  device copy = one JSON file per year in Application Support, not per account, past years pruned
  (criterion 19); copy first, then refresh (criterion 20); home block with one failed year shows the
  failure on that year's cards (criterion 21); 429 = server error, no automatic retry (criterion 22);
  chip count as "Lễ lớn (10)" (criterion 7); scene names `Festivals` / `FestivalDetail` kept.
- Superseded iOS docs (kept for now; removed in a later step, `tasks.md` Phase 9):
  `Docs/Specs/FestivalDetail/` (requirements, design, tasks, changelog v1.0),
  `Docs/Assumptions/Festivals/AS-Festivals-001`, `AS-Festivals-002`,
  `Docs/Assumptions/FestivalDetail/AS-FestivalDetail-001`, `AS-FestivalDetail-002`,
  `Docs/Assumptions/Home/AS-Home-003`, `Docs/Tech-Debt/FestivalDetail/TD-FestivalDetail-001`,
  `TD-FestivalDetail-002`, `Docs/Tech-Debt/Home/TD-Home-003`; partly: `Docs/Specs/Home/` v1.11 (events
  carousel criterion, "API contract — calendar events").
- Open: `⚠️ Not confirmed (contract)` — public route and the v3.0 fields are not in `openapi.yaml` yet
  (criterion 1; backend Phase 18). `⚠️ Not confirmed (product)` — the shared default image (criterion
  13); the copy of the stale note, failure states, retry row, empty month, not-found (Pending).
- Hand back to `ba-writer` (product spec, not edited here):
  1. BR-CAL-14 / FR-CAL-005: which image is the shared default image.
  2. FR-CAL-007 / FR-CAL-008 / BR-CAL-15: copy for the out-of-date note, offline and could-not-load
     messages, the retry row, the home block's empty month and failure, the detail's not-found state —
     the spec has no copy list.
  3. Matrix §4.2 iOS column: FR-CAL-008 `done` → `drift` (calendar first-load failure is a toast with no
     retry; the home block disappears on failure); FR-CAL-002 `done` → `drift` (rows lack group names and
     major mark, year from device time zone, Rằm / Mùng Một rows not tappable); BR-CAL-09 `done` → `drift`
     (no group chips, no group names on list rows); BR-CAL-13 `done` is right in behavior but the list's
     "còn N ngày" differs from "Còn n ngày".
