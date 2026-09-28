# Tasks — Photos

Version: 1.0
Last updated: 2026-09-27
Status: complete (Phase 1–2); Phase 3 pending (photos API / real images)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer today; Phase 3 tracks replacing the
> static catalog with a real photos API.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILPhotosViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header + hairline, scrollable
      category chips, masonry grid — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILPhotosPhotoCardView`,
      `ILPhotosMasonryGridView`
- [x] Add `ILTypography.photoCaptionTitle` token
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `photos`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILPhotosEntity` + `ILPhotosCategory` + `ILPhotosPhotoEntity`
- [x] Create `ILPhotosStateModel` + `ILPhotosCategoryModel` + `ILPhotosPhotoModel`
- [x] Create `ILPhotosUseCase` / `ILPhotosUseCaseImpl` (catalog, selectCategory,
      filteredPhotos — pure logic)
- [x] Create `ILPhotosViewModel` (`Input -> Output`, `ILPhotosNavEvent`)
- [x] Create `ILPhotosCoordinator` (leaf — `.back` pop+finish)
- [x] Wire `DIContainer.makePhotosUseCase/ViewModel/Coordinator`
- [x] Wire `ILHomeCoordinator.showPhotos()` via `ILHomeNavEvent.openPhotos`
- [x] Unit tests: `InnerLampTests/ILPhotosViewModelTests.swift` (4 tests) —
      load all, filter, reset, nav back

## Phase 3 — API integration (pending; blocked on asset source)

> ⚠️ Not confirmed: the photos API / asset source (see `requirements.md`
> Pending). Everything below is blocked until real images are available.

- [ ] Confirm the photos API / asset source with the product/backend team
- [ ] Create `ILPhotosDTO` + `ILPhotosMapper` (once the contract is confirmed)
- [ ] Create `PhotosEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILPhotosRepository` protocol + `ILPhotosRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the static catalog in `ILPhotosUseCaseImpl` with real data; use
      real image dimensions/aspect ratio instead of `imageHeight`
- [ ] Update `ILPhotosViewModelTests` + add a mock repository
- [ ] Visual QA on simulator/device (masonry grid, chips, dark mode)
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Photos/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/photos.md` (OKF concept) — hold off until the
      photos API (Phase 3) lands. See `Docs/Specs/OKF.md`.
