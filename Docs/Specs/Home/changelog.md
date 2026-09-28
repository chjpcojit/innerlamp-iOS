# Changelog — Home Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Home feature
  (full UI + local logic, mock content, no dashboard API).
- `requirements.md`: user story and 7 EARS acceptance criteria (greeting + date,
  section rendering from mock data, bead increment/reset, the eight navigation
  targets, and the no-op sutra/offering rows). "Pending" records the missing
  dashboard API (with a ⚠️ on the contract), the temporary `KeychainService`
  name read, and the memory-only bead count. One resolved open question (lunar
  date is computed via `ILLunarCalendar`, not hardcoded).
- `design.md`: Layers & components table (Entity + 15 sub-entities/enums,
  UseCase, StateModel, ViewModel, Coordinator, ViewController, 8 feature views),
  navigation flow (owned by `ILMainTabCoordinator`, not `AppCoordinator`), the
  screen-load data flow, and a "Deliberately stubbed / mock for now" section.
  No Step-by-step Flow — no network calls.
- `tasks.md`: Phases 1–2 checked (`[x]`) reflecting the shipped UI/logic and 13
  tests; Phase 3 (dashboard API) pending, blocked on contract; Phase 4's OKF
  concept left `[ ]`.
- Reason: Home was one of the implemented features with no spec folder; written
  to close documentation debt, matching the `Docs/Specs/SignUp/` example.
