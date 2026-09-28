# Changelog — MeditationSession Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented
  MeditationSession feature (immersive sitting screen with countdown + breath
  guidance; `recordSession` stub; Done screen not built).
- `requirements.md`: user story and 6 EARS acceptance criteria (open session +
  opening bell + breathing ring, guided cue vs silent, pause/resume, end early,
  natural end, back). "Pending" records the stubbed `recordSession` (with a ⚠️
  on practice-log storage), the unimplemented Done screen, the single-strike
  bells, and the foreground-only countdown. One resolved open question (the
  session makes no network call).
- `design.md`: Layers & components table (Entity + breath phase, UseCase,
  StateModel, ViewModel, Coordinator + delegate, ViewController, 2 shared
  components), navigation flow, data flow, and a "Deliberately stubbed for now"
  section. No Step-by-step Flow — `recordSession` is a single local action, not
  a confirmed API.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 11
  + 8 tests; Phase 3 (practice-log persistence) pending on the storage decision;
  Phase 4 (Done screen + audio extras) pending.
- Reason: MeditationSession was one of the implemented features with no spec
  folder; written to close documentation debt, matching the
  `Docs/Specs/SignUp/` example.
