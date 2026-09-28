# Changelog — Events Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Events
  feature (UI + tab logic with mock data; Register destination not built).
- `requirements.md`: user story and 5 EARS acceptance criteria (3-tab selector
  + hero + list, tab switching with section title, empty state, register tap →
  event, back). "Pending" records the mock data (with a ⚠️ on the API contract),
  the unimplemented Register destination, and the absent loading/error states.
  One resolved open question (the featured hero is always shown, not per-tab).
- `design.md`: Layers & components table (Entity + enums, UseCase, StateModel,
  ViewModel, leaf Coordinator, ViewController, 2 feature views), the dual
  navigation flow (Sangha and Home), and a "Deliberately stubbed / mock for
  now" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 7
  tests; Phase 3 (events API) pending on contract; Phase 4 (Register screen)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: Events was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
