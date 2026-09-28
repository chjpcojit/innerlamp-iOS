# Changelog — Article Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Article
  feature (full reading screen with static catalog + in-memory save; Share not
  built).
- `requirements.md`: user story and 5 EARS acceptance criteria (load article,
  toggle save + label, switch read-next in place, share event, back). "Pending"
  records the missing articles API (with a ⚠️ on the contract), placeholder hero
  images, in-memory save, the unimplemented Share destination, and unverified
  visual QA. One resolved open question (author initials are editorial data).
- `design.md`: Layers & components table (Entity, UseCase, StateModel,
  ViewModel, leaf Coordinator, ViewController, 3 feature views, shared tokens),
  navigation flow, data flow, and a "Deliberately mock / stub" section. No
  Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 5
  tests; Phase 3 (articles API) pending on contract; Phase 4 (Share screen)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: Article was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
