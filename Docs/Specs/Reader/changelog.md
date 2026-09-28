# Changelog — Reader Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Reader feature
  (bilingual verse reading + playback UI with a static catalog; destinations not
  built).
- `requirements.md`: user story and 7 EARS acceptance criteria (load sutra +
  verse + playback bar, toggle play, open player, share event, download event,
  font-size event, back). "Pending" records the missing sutra API (with a ⚠️ on
  the contract), the in-memory playback, and the three TODO destinations. One
  resolved open question (unknown sutra id falls back to the first catalog
  sutra).
- `design.md`: Layers & components table (Entity, UseCase, StateModel, ViewModel,
  Coordinator, ViewController, 2 feature views, shared `ILPlayPauseButton` +
  tokens), navigation flow (Library → Reader → Player), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 7
  tests; Phase 3 (sutra API) pending on contract; Phase 4 (sub-destinations)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: Reader was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
