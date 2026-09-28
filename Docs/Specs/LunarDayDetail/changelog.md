# Changelog — LunarDayDetail Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v1.0 (initial) — 2026-09-27

- Initial spec written retroactively from the already-implemented
  LunarDayDetail feature (built by `il-screen-builder` from the design handoff),
  documenting what shipped: a pure client-side lunar-computation leaf screen
  owned by `ILHomeCoordinator`, with Entity / UseCase / StateModel / ViewModel /
  Coordinator / ViewController + 6 feature views and full unit tests. No Data
  layer (no API). Pending: hero imagery, non-Vietnamese localization, advice
  copy/position confirmation, and visual QA.
