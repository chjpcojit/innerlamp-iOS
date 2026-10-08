# Tasks — Photos

Version: 1.2
Last updated: 2026-10-07
Status: Phase 3 (gallery API) coded; tests not run, device QA pending

> See `changelog.md` in this folder for the version history of this spec.


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

## Phase 3 — API integration (`GET /v1/gallery`, contract in `design.md`)

- [x] Confirm the photos API with the backend team (2026-10-06)
- [x] Create `ILPhotosDTO` + `ILPhotosMapper`
- [x] Create `PhotosPageEndpoint` under `Data/DataSources/Remote/`
- [x] Create `ILPhotosRepository` protocol + `ILPhotosRepositoryImpl` wrapping
      `NetworkService`
- [x] Rework `ILPhotosEntity` (thumbnail/image URL, paging position; drop
      `imageHeight`) and `ILPhotosUseCase` (`loadFirstPage` / `loadNextPage`)
- [x] Rework `ILPhotosStateModel` / `ILPhotosViewModel` (load more, loading
      footer, stale-response guard, error surfacing)
- [x] Show real images: `ILRemoteImageView` in the card, incremental append and
      near-bottom trigger in the grid, load-more footer
- [x] Wire `DIContainer.makePhotosRepository()`; remove the unused
      `photos.photo.N.*` copy keys
- [x] Crossfade the grid on a category change (`ILPhotosMasonryGridView`,
      ViewModel keeps old photos until the new page arrives)
- [ ] Update `ILPhotosViewModelTests`; add UseCase / Repository / Mapper tests
- [ ] Visual QA on device (grid, chips, paging, dark mode)
- [ ] Manual test against the dev backend

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Photos/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/photos.md` (OKF concept) — hold off until the
      Phase 3 flow has been verified on a device. See `Docs/Specs/OKF.md`.
