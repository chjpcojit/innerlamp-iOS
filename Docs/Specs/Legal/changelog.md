# Changelog — Legal Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v1.0 (initial) — 2026-10-10

- Initial spec written before implementation, as the work order for building
  the full-page Legal screen, derived from `SRS.md`.
- `requirements.md`: EARS criteria for opening the chosen document, segment
  switch, content, load failure, contact card. ⚠️ Not confirmed: API contract,
  effective-date source, account-deletion claim, scroll reset.
- `design.md`: Entity / Repository / UseCase / StateModel / ViewModel /
  Coordinator / ViewController plus three feature views; text read from the
  existing `legal.*` keys shared with the sign-up sheet; no Step-by-step Flow.
- `tasks.md`: Phases 1–2 all `[ ]`; Phase 3 blocked on the contract.
- Reason: product owner asked for the legal pages (2026-10-10); content is mock
  until the API is supplied.
