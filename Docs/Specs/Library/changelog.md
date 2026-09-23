# Changelog — Library Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

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
