# Changelog — Photos Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.3 — Tiles open the photo viewer (2026-10-07)

- Out of scope item "lightbox" moved to `Docs/Specs/PhotoViewer/`. Code: `ILPhotosNavEvent.openPhoto`,
  `photoSelected` Input, tile `heroID`, Photos keeps the bottom nav hidden under the viewer.

## v1.2 — Crossfade on category change (2026-10-07)

- `requirements.md`: category-change criterion rewritten (chip moves at once, old
  photos stay, crossfade, scroll to top) plus a failure criterion (chip reverts).
  `design.md` data flow step 3 updated; `tasks.md` gets a checked crossfade item.
- Code: `ILPhotosViewModel` no longer clears the grid on a category change (tracks
  `requestedCategory`, reverts the chip on failure); `ILPhotosMasonryGridView`
  reloads inside `UIView.transition(.transitionCrossDissolve, 0.25 s)`.
  2 ViewModel tests added, not run. The last build was blocked by errors in
  `Sutras/ILSutrasViewModel.swift` (`ILSutraEntity` has no `name` /
  `originalName`), a file outside this change; no Photos diagnostics.

## v1.1 — Real gallery API (2026-10-06)

Spec update plus implementation (2026-10-07).

- Trigger: `[BE]-InnerLamp` confirmed `GET /v1/gallery` on dev (REST, public,
  `page` + `type`, 20 per page, 86 images) — the previously "⚠️ Not confirmed"
  photos API.
- `requirements.md`: acceptance criteria rewritten (API-backed grid, image
  placeholder, infinite scroll + footer, server-side category filter, error
  keeps loaded photos). Resolved questions: photos API; no image dimensions
  (→ fixed 4:3, assumption). Attribution (CC BY) added to Pending.
- `design.md`: new "API contract" section, layer table extended with
  Repository / DTO / Mapper / Endpoint, data flow and decisions rewritten.
- `tasks.md`: Phase 3 rewritten from `design.md`; only the API confirmation is
  checked.
- Implementation: Data layer (DTO, Mapper, `PhotosPageEndpoint`, Repository),
  UseCase paging, ViewModel/StateModel/ViewController/views, `DIContainer`,
  `vi.json` (dropped `photos.photo.N.*`, added `photos.loadingMore`/`photos.end`).
  Tasks checked: all code items of Phase 3. Left `[ ]`: tests item (written, but
  `xcodebuild test` could not run: no provisioning profile for the UI-test
  runner on the device), device QA, manual test against the backend.
  `generic/platform=iOS` build passes.
- Recorded: `Docs/Assumptions/Photos/AS-Photos-001`, `Docs/Tech-Debt/Photos/
  TD-Photos-001` (attribution) and `TD-Photos-002` (Home strip still static).

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
