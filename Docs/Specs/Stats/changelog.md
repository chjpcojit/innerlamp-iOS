# Changelog — Stats Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md`
in this folder. All three files share one changelog since they change
together as one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Stats
  feature (UI + local logic done, data integration stubbed) — see
  `Docs/Specs/OKF.md`. The data source (`getStats()`) returns hardcoded
  sample data pending a confirmed stats API / local-store contract
  (⚠️ recorded in `requirements.md` and `design.md`), and `.openReminder`
  has no destination yet (the `remind` screen is not built).
