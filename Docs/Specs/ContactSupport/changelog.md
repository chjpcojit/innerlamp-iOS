# Changelog — ContactSupport Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this
folder. All three files share one changelog since they change together as one
spec unit. Newest version first.

## v1.0 (initial) — 2026-10-10

- Initial spec written before implementation, as the work order for building
  ContactSupport, derived from `SRS.md`.
- `requirements.md`: EARS criteria for channels, topic, validation (≥ 10
  characters), submit, confirmation, FAQ shortcut. Open items kept as
  ⚠️ Not confirmed: real channel values, max message length, failure behavior,
  reply delivery, draft persistence, submit API.
- `design.md`: Entity / Repository / UseCase / StateModel / ViewModel /
  Coordinator / ViewController plus three feature views; submit is a stub behind
  `ILSupportRepository`; no Step-by-step Flow (single call).
- `tasks.md`: Phases 1–2 all `[ ]`; Phase 3 blocked on the contract; Phase 4
  documentation.
- Reason: product owner asked for the support screens (2026-10-10) and chose
  "stub + Assumption" for submit and mock content for now.
