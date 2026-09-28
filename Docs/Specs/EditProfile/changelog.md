# Changelog — EditProfile Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented EditProfile
  feature (full edit form with mock data + real client-side validation;
  `saveProfile` stub; destinations not built).
- `requirements.md`: user story and 6 EARS acceptance criteria (load avatar +
  4 input cards + visibility group + danger zone, update initials + clear
  error, block save on empty display name, save + trim + pop, back/save close,
  emit the four unimplemented events). "Pending" records the mock data +
  `saveProfile` stub (with a ⚠️ on the profile API), the four TODO destinations,
  and a ⚠️ on the display-name-to-backend mapping. One resolved open question
  (phone is read-only).
- `design.md`: Layers & components table (Entity + visibility enum, UseCase,
  StateModel, ViewModel, Coordinator, ViewController, 3 feature views, shared
  `ILInputCardView`), navigation flow (from Profile + Settings), data flow, and
  a "Deliberately stub / mock" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 15
  tests; Phase 3 (profile API) pending on contract; Phase 4 (sub-destinations)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: EditProfile was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
