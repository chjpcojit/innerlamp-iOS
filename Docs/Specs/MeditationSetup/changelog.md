# Changelog — MeditationSetup Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented
  MeditationSetup feature (full-screen setup modal; session flow wired; Done
  screen not built; no network).
- `requirements.md`: user story and 6 EARS acceptance criteria (present as
  full-screen modal, load durations + bell card + tip, select duration, start
  guided, start silent, close). "Pending" records the missing Done/Journal
  screen, the non-persisted duration, the display-only bell rows (with a ⚠️ on
  scope), and the missing Home-row content passthrough. One resolved open
  question (it is a modal, not a 5th tab).
- `design.md`: Layers & components table (Entity, UseCase, StateModel, ViewModel,
  section Coordinator, ViewController, 3 feature views, shared token),
  navigation flow (section coordinator of the practice flow, presenting a
  full-screen modal and pushing MeditationSession), data flow, and a
  "Deliberately not implemented" section. No Step-by-step Flow — the practice
  flow is navigation, not sequential API calls.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 6 +
  4 tests; Phase 3 "not applicable"; Phase 4 leaves the Done screen, duration
  persistence, bell selection, and Home-row passthrough as `[ ]`.
- Reason: MeditationSetup was one of the implemented features with no spec
  folder; written to close documentation debt, matching the
  `Docs/Specs/SignUp/` example.
