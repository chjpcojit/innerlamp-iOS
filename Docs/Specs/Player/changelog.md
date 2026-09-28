# Changelog — Player Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Player feature
  (full-screen player UI with in-memory playback state; no audio; table of
  contents not wired).
- `requirements.md`: user story and 7 EARS acceptance criteria (load track +
  progress + seek + options, play/pause, rewind/forward, speed, sleep timer,
  back, table of contents). "Pending" records the missing audio (with a ⚠️ on
  the track API), the static catalog, and the unwired table-of-contents
  destination. One resolved open question (Player is a leaf, not a section
  coordinator).
- `design.md`: Layers & components table (Entity, UseCase, StateModel, ViewModel,
  leaf Coordinator, ViewController, 2 feature views, shared components/tokens),
  navigation flow (pushed from Reader + SutraDetail), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 8
  tests; Phase 3 (track API + audio) pending on contract; Phase 4 (table of
  contents) pending; Phase 5's OKF concept left `[ ]`.
- Reason: Player was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
