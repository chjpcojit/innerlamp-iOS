# Changelog — Library Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v2.0 (2026-09-27)

- Reconciled the spec with the shipped code: Library is now **tab 2 of
  `ILMainTabBarController`**, not an `AppCoordinator`-owned root screen (the
  v1.x shape). This was a structural change, hence the major bump.
- `requirements.md`: switched the intro note from prospective to retroactive.
  Removed the "bottom navigation bar with the Library tab active" and the
  tab-switch acceptance criteria (tab switching is owned by
  `ILMainTabBarController` now). Added `.sutra` → SutraDetail to the content-row
  criterion. Resolved the per-category section-title ⚠️ (4 `library.section.*`
  keys confirmed) and the ownership question; moved them to "Open questions
  (resolved)". "Pending" now scopes the destination ⚠️ to `.meditation` /
  `.talk` + featured only (sutra is wired).
- `design.md`: rewrote the Overview, the Layers & components table (removed the
  delegate + `goHome` + embedded `ILBottomNavBar` + Home entry rows; added the
  `ILMainTabCoordinator` wiring), the navigation flow, and the "Deliberately
  stubbed" section to reflect that `.openItem(id:.sutra)` → `showSutraDetail(id)`
  is now wired.
- `tasks.md`: Phase 2 reworded the wiring items (Main tab, no delegate; removed
  the v1.x Home entry wiring); added the `.openItem(id:.sutra)` → SutraDetail
  item; updated the test count to 13; renumbered the destination work into a new
  Phase 4 and moved the deferred destinations accordingly.
- Reason: reading the Library code (while refreshing this spec) revealed the
  implementation had shipped as a Main tab — the v1.1 spec still described the
  old AppCoordinator-root shape and a `goHome` delegate that no longer exist.

## v1.1 (2026-09-20)

- `requirements.md`: no behavior change; status line updated (implementation landed). All ⚠️ items
  still open.
- `design.md`: no change needed, verified against the built code (file names and the Home entry
  wiring match the Layers table).
- `tasks.md`: Phase 1–2 items checked off except "Visual QA against prototype (light + dark)"
  (not yet run on device/simulator); Phase 4 README checked; Phase 3 and the OKF concept remain
  open.
- Reason: Library screen implemented (mock catalog); 113/113 unit tests pass on iOS 26.5 sim.

## v1.0 (initial)

Initial spec written before implementation (2026-09-20), as the work order for building the
Library tab. Derived from prototype screen `lib` in `Docs/design_handoff_innerlamp/`. Open items
recorded as ⚠️ Not confirmed: catalog API contract, item-kind → destination mapping, list section
titles per category (prototype designs only the default state).
