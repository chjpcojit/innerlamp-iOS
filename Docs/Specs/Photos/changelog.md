# Changelog — Photos Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Photos
  feature (masonry gallery with category filter on a static catalog, no API).
- `requirements.md`: user story and 4 EARS acceptance criteria (masonry grid +
  filter chips + subtitle, category filtering, "Tất cả" reset, back). "Pending"
  records the placeholder images, the provisional `imageHeight`, and the
  unverified visual QA, with a ⚠️ on the photos API / asset source. One resolved
  open question ("Tất cả" is a filter, not a category).
- `design.md`: Layers & components table (Entity + `ILPhotosCategory`, UseCase,
  StateModel, ViewModel, leaf Coordinator, ViewController, 2 feature views, the
  shared `photoCaptionTitle` token), navigation flow, data flow, and a
  "Deliberately mock / placeholder" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 4
  tests; Phase 3 (photos API) pending on the asset source; Phase 4's OKF
  concept left `[ ]`.
- Reason: Photos was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
