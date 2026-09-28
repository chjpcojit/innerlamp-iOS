# Changelog — Sangha Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Sangha feature
  (full tab UI with mock data; three destinations not built).
- `requirements.md`: user story and 5 EARS acceptance criteria (load hub
  sections, open post, open events, open community/temple, emit the three
  unimplemented events). "Pending" records the mock data (with a ⚠️ on the API
  contract), the three TODO destinations, the static live count, the
  display-only engagement, and the absent loading/error states. One resolved
  open question (community card → Temple screen).
- `design.md`: Layers & components table (Entity + 3 sub-entities, UseCase,
  StateModel, ViewModel, Coordinator, ViewController, 4 feature views),
  navigation flow (owned by `ILMainTabCoordinator`), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 13
  tests; Phase 3 (community API) pending on contract; Phase 4 (unbuilt
  destinations) pending; Phase 5's OKF concept left `[ ]`.
- Reason: Sangha was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
