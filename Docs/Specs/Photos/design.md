# Design — Photos

Version: 1.0
Last updated: 2026-09-27
Status: implemented — masonry gallery with category filter on a static catalog

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Photos ("Ảnh chùa đẹp") follows MVVM-C + Clean Architecture per `AGENTS.md`. It
is a **leaf screen** — `ILPhotosCoordinator` has no delegate. It is created by
`ILHomeCoordinator` (the "Ảnh chùa đẹp" block on Home) and pushed onto the Home
tab's `BaseNavigationController`. There is **no network** — the UseCase returns
a static 12-photo catalog.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILPhotosEntity.swift` | `ILPhotosCategory` (temple / buddhaStatue / meditation / festival), `ILPhotosPhotoEntity` (id, category, title, place, imageHeight), `ILPhotosEntity` (photos + `selectedCategory`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Photos/ILPhotosUseCase.swift` | `getInitialState()` (static 12-photo catalog), `selectCategory(_:in:)`, `filteredPhotos(in:)`. Pure logic, no network. |
| Presentation / State | `Presentation/Scenes/Photos/ILPhotosStateModel.swift` | UI-only state: `ILPhotosCategoryModel` (filter chips), `ILPhotosPhotoModel`, `ILPhotosStateModel` (subtitle). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Photos/ILPhotosViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILPhotosNavEvent` (`.back`); Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/Photos/ILPhotosCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop + `finish()`. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Photos/ILPhotosViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Photos/Views/ILPhotosPhotoCardView.swift`, `ILPhotosMasonryGridView.swift` | Photo card and masonry grid views. |
| Shared token | `DesignSystem/Tokens/ILTypography.swift` | `photoCaptionTitle` preset (Lora 13.5px). |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showPhotos() → ILPhotosCoordinator               (leaf, no delegate)
       push ILPhotosViewController
       (.back) → pop + finish()
```

## Data flow

1. `ILPhotosViewModel` loads `useCase.getInitialState()` (static catalog) and
   maps it to `ILPhotosStateModel` via `filteredPhotos(in:)`.
2. `handleCategorySelected(category)` updates `selectedCategory` and re-filters
   (no re-fetch — data is static).
3. `handleBack` emits `.back`.

There is no network call and no Step-by-step Flow.

## Deliberately mock / placeholder

The catalog is a static `Component.PHOTOS` (12 photos across the 4 categories)
built in `ILPhotosUseCaseImpl.makePhotoCatalog()`. Photo cells render a warm
tint + category label instead of a real image; `imageHeight` is a provisional
ratio. Completing this is `tasks.md` Phase 3, blocked on the photos API / asset
source.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `photos` / `Component.PHOTOS`. See `InnerLamp/Presentation/Scenes/Photos/
README.md` for the full design-vs-implementation comparison and changelog.
