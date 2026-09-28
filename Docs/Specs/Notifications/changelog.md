# Changelog — Notifications Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Notifications
  feature (full UI with mock data; "Ngồi ngay" destination not wired).
- `requirements.md`: user story and 5 EARS acceptance criteria (load header +
  hero + list, dismiss hero, open-setup event, close, unread indicator).
  "Pending" records the mock data (with a ⚠️ on the notifications API), the
  missing mark-as-read, the absent `.failure` rendering, and the unwired
  `.openSetup`. One resolved open question (MeditationSetup is built now, so
  `.openSetup` is a wiring task, not a blocked one).
- `design.md`: Layers & components table (Entity + kinds, UseCase, StateModel,
  ViewModel, Coordinator, ViewController, 2 feature views), navigation flow
  (inside the Profile tab), data flow, and a "Deliberately mock / stub" section.
  No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 7
  tests; Phase 3 (notifications API) pending on contract; Phase 4 (wire
  `.openSetup`) pending but not blocked; Phase 5's OKF concept left `[ ]`.
- Reason: Notifications was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
