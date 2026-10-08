# Changelog — Sangha Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.2 — "Đổi chùa" opens the temple picker (2026-10-05)

Implementation entry; the spec prose below still describes the removed community feed.

- "Đổi chùa" no longer clears the practice temple: it emits `.openTempleFinder` and opens the new
  "Chọn chùa tu tập" screen (spec: `Docs/Specs/TempleFinder/`). `ILSanghaUseCase.clearMyTemple()` removed;
  `selectMyTemple(_ temple: ILTempleSummaryEntity)` added (id + name/address snapshot).
- New `viewWillAppear` Input: the tab reloads when it comes back (first appearance skipped).
- Debt: `Docs/Tech-Debt/Sangha/TD-Sangha-002-*.md`.

## v1.1 — code redesign (spec not yet rewritten)

- The Sangha tab was rebuilt to the prototype `sangha` screen (practice temple / chooser / festival
  days, label "Chùa"). `requirements.md` / `design.md` / `tasks.md` below still describe the removed
  community feed and must be rewritten — tracked in
  `Docs/Tech-Debt/Sangha/TD-Sangha-001-spec-and-orphan-scenes.md`.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Sangha feature
  (full tab UI with mock data; three destinations not built).
- `requirements.md`: user story and 5 EARS acceptance criteria (load hub
  sections, open post, open events, open community/temple, emit the three
  unimplemented events). "Pending" records the mock data (with a ⚠️ on the API
  contract), the three TODO destinations, the static live count, the
  display-only engagement, and the absent loading/error states. One resolved
  open question (community card → Temple screen).
- `design.md`: Layers & components table (Entity + 3 sub-entities, UseCase,
  StateModel, ViewModel, Coordinator, ViewController, 4 feature views),
  navigation flow (owned by `ILMainTabCoordinator`), data flow, and a
  "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 13
  tests; Phase 3 (community API) pending on contract; Phase 4 (unbuilt
  destinations) pending; Phase 5's OKF concept left `[ ]`.
- Reason: Sangha was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
