# Changelog — Post Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Post feature
  (full post detail with static catalog + in-memory like; Share not built;
  comment composer UI-only).
- `requirements.md`: user story and 4 EARS acceptance criteria (load post +
  header + card + comments, toggle like + count, share event, back). "Pending"
  records the missing community API (with a ⚠️ on the contract), in-memory like,
  UI-only composer, approximate avatar tones, and unverified visual QA. One
  resolved open question (like count display = catalog count + user's like).
- `design.md`: Layers & components table (Entity + comment threading, UseCase,
  StateModel, ViewModel, leaf Coordinator, ViewController, 3 feature views,
  shared tokens), navigation flow (from Sangha), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 8
  tests; Phase 3 (community API) pending on contract; Phase 4 (Share screen)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: Post was one of the implemented features with no spec folder; written
  to close documentation debt, matching the `Docs/Specs/SignUp/` example.
