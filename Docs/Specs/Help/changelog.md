# Changelog — Help Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v2.0 (2026-10-10)

- `requirements.md`: rebuilt from the new `SRS.md`. FAQ set switched to the
  prototype's latest 5 items (the "gia hạn Sen Vàng" question is dropped); added
  footer → Contact Support, load-failure state and collapse-on-retap criteria;
  support team renamed "ban hỗ trợ". Search entry and empty/failure copy stay
  ⚠️ Not confirmed.
- `design.md`: FAQ source modeled as `ILHelpRepository` with a bundled-mock
  implementation (the previous conditional "drop the layer if static" is
  removed); accordion state moved into the ViewModel/StateModel; added feature
  views and the `openContact` delegate.
- `tasks.md`: new Phase 1–2 items for the repository, card views, delegate and
  tests; Phase 3 narrowed to replacing the mock with the API; Assumption and
  Tech Debt records added.
- Reason: product owner confirmed (2026-10-10) that FAQ content is mocked now
  and the API is provided later; scope grew to include the Contact Support
  link.

## v1.0 (initial) — 2026-09-27

- Initial spec written before implementation, as the work order for building
  Help. Covers the FAQ accordion + search entry, with the FAQ content source
  left ⚠️ Not confirmed.
