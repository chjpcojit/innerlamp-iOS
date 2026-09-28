# Changelog — Profile Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Profile
  feature (full tab UI with mock data; destinations partially built).
- `requirements.md`: user story and 7 EARS acceptance criteria (load header +
  stats + heatmap + badges + merit + plan + menu, edit profile, open stats, open
  settings, open notifications, emit the five unimplemented events, open
  community). "Pending" records the mock data (with a ⚠️ on the profile API),
  the five TODO destinations, and the missing avatar/role/find-sangha. One
  resolved open question (`editProfile` and `openStats` are wired — the README's
  "TODO" notes for them are stale).
- `design.md`: Layers & components table (Entity + 6 sub-entities/enums, UseCase,
  StateModel, ViewModel, Coordinator, ViewController, 7 feature views, 2 shared
  components), navigation flow (owned by `ILMainTabCoordinator`), data flow, and
  a "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 18
  tests; Phase 3 (profile API) pending on contract; Phase 4 (unbuilt
  destinations) pending; Phase 5's OKF concept left `[ ]`.
- Reason: Profile was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
