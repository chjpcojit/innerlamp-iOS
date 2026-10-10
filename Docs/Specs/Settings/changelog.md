# Changelog — Settings Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.1 (2026-10-10)

- `requirements.md`: added the "Hỗ trợ & pháp lý" section (three rows) and its
  navigation criteria; clarified that `.openHelp` opens the new Help screen; the
  Help / Contact Support / Legal screens are out of scope here. One
  ⚠️ Not confirmed: whether the footer legal line becomes tappable.
- `design.md`: new `ILSettingsSupportCardView`, three new nav events, coordinator
  wiring for Help / ContactSupport / Legal and the cross-link delegates;
  navigation diagram updated. Data flow unchanged (no network).
- `tasks.md`: new Phase 6 for the rows and wiring; Phase 4 help item points to the
  Help spec. Nothing checked off — none of this is built.
- Reason: Help, Contact Support and Legal specs (2026-10-10) need entry points
  from Settings, matching the prototype's "HỖ TRỢ & PHÁP LÝ" section.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Settings
  feature (full settings UI with mock data; toggles in-memory; destinations not
  built).
- `requirements.md`: user story and 6 EARS acceptance criteria (load account +
  4 sections + footer, toggle updates, font-scale update, open EditProfile, emit
  the seven unimplemented events, back). "Pending" records the mock data (with a
  ⚠️ on persistence/API), the seven TODO destinations, the in-memory toggles, and
  the un-synced theme/font-scale/appVersion. One resolved open question (the
  dark-mode value is mock, not `ThemeService`).
- `design.md`: Layers & components table (Entity + 4 sub-types, UseCase,
  StateModel, ViewModel, Coordinator, ViewController, 5 feature views, shared
  `ILSectionEyebrowView`), navigation flow (inside the Profile tab), data flow,
  and a "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 19
  tests; Phase 3 (persistence/API) pending on the storage decision; Phase 4
  (sub-destinations) pending; Phase 5's OKF concept left `[ ]`.
- Reason: Settings was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
