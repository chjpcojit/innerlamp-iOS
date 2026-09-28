# Changelog — SutraDetail Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented SutraDetail
  feature (full detail screen with static catalog; Download destination not
  built).
- `requirements.md`: user story and 5 EARS acceptance criteria (load hero +
  progress + description + TOC, open reader on chant/chapter, open player on
  play, download event, back). "Pending" records the missing sutra API (with a
  ⚠️ on the contract), the unimplemented Download destination, and the sample
  reading progress. One resolved open question (`.openPlayer` is wired — the
  README's "TODO" note for it is stale).
- `design.md`: Layers & components table (Entity + enums, UseCase, StateModel,
  ViewModel, Coordinator, ViewController, 2 feature views, shared tokens),
  navigation flow (Library → SutraDetail → Reader/Player), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 8
  tests; Phase 3 (sutra API) pending on contract; Phase 4 (Download screen)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: SutraDetail was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
