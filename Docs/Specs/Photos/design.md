# Design — Photos

Version: 1.2
Last updated: 2026-10-07
Status: implemented against the real gallery API; build passes, tests not run

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Photos ("Ảnh chùa đẹp") follows MVVM-C + Clean Architecture per `AGENTS.md`. It
is a **leaf screen** — `ILPhotosCoordinator` has no delegate. It is created by
`ILHomeCoordinator` and pushed onto the Home tab's `BaseNavigationController`.

From v1.1 the photos come from the backend: `GET /v1/gallery` (REST, public,
page-number paging, server-side `type` filter), mirroring the Articles list
(`ILArticlesUseCase` / `ILArticleRepository`). Images are shown with
`ILRemoteImageView` (off-main decode + downsample).

## API contract

Source: backend team (`[BE]-InnerLamp`), 2026-10-06, `docs/specs/features/
gallery/api-contract.md` v1.1, verified against the running dev server
(`http://192.168.1.186:8080`, 86 images). Public routes — no `Authorization`.
Envelope `{"success":true,"data":...}`; keys are snake_case
(`.convertFromSnakeCase`).

| Item | Value |
|---|---|
| Used route | `GET /v1/gallery?page=N&type=T` |
| `page` | 1-based, default 1, fixed 20 per page (no `page_size`, no cursor) |
| `type` | optional: `CHUA`, `TUONG_PHAT`, `THIEN`, `LE_HOI`; omitted = all |
| Order | `sort_order`, the four types interleaved; with `type` the order within the type |
| `data` | `{items, page, page_size, total, total_pages}`; a page past the end is `200` with `items: []` |
| Item | `id`, `type`, `title`, `location`, `thumbnail_url`, `image_url` (never null) |
| Images | `thumbnail_url` JPEG 500 px (avg 58 KB); `image_url` JPEG 1280 px (avg 321 KB); absolute URLs on the server host, used verbatim |
| Errors | `400 INVALID_PAGE` (`details.field=page`), `400 INVALID_GALLERY_TYPE` (`details.field=type`), `405`, `404 NOT_FOUND` |
| Home strip | `GET /v1/gallery/top` → `{items}` (10 photos, same item shape), used by Home via `loadTopPhotos()` |
| Not used (out of scope) | `GET /v1/gallery/{id}` (adds `author`, `license`, `source_url`; `404 GALLERY_IMAGE_NOT_FOUND`) |

Type ↔ category: `CHUA` → temple, `TUONG_PHAT` → buddhaStatue, `THIEN` →
meditation, `LE_HOI` → festival. An item with an unknown `type` is dropped.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILPhotosEntity.swift` | `ILPhotosCategory`, `ILPhotosPhotoEntity` (id, category, title, place, thumbnailURL, imageURL), `ILPhotosPageEntity` (one page), `ILPhotosEntity` (photos, `selectedCategory`, paging position `lastLoadedPage` / `totalCount` / `hasMore`). No UI-only state. |
| Domain / Repository | `Domain/Repositories/ILPhotosRepository.swift` | `loadPhotos(category:page:) async throws -> ILPhotosPageEntity`; throws `ILCatalogError`. |
| Domain / UseCase | `Domain/UseCases/Photos/ILPhotosUseCase.swift` | `loadFirstPage(category:)`, `loadNextPage(after:)` (de-duplicates by id, no-op when `hasMore == false`). |
| Data / DTO | `Data/DTOs/ILPhotosDTO.swift` | `ILPhotosSummaryDTO`; the list wrapper reuses `ILCatalogPageDTO`. |
| Data / Mapper | `Data/DTOs/Mappers/ILPhotosMapper.swift` | DTO → Entity, type string ↔ category; empty URLs → nil. |
| Data / Endpoint | `Data/DataSources/Remote/PhotosPageEndpoint.swift` | `GET /v1/gallery`, `page` + optional `type`, `requiresAuth == false`. |
| Data / Repository | `Data/Repositories/ILPhotosRepositoryImpl.swift` | Wraps `NetworkService`; maps errors with `ILCatalogError.from`; `hasMore` from `page < total_pages` and a non-empty raw page. |
| Presentation / State | `Presentation/Scenes/Photos/ILPhotosStateModel.swift` | UI-only: `ILPhotosCategoryModel`, `ILPhotosPhotoModel` (id, title, place, thumbnailURL), `ILPhotosStateModel` (subtitle, `isLoadingMore`, `hasMore`). |
| Presentation / ViewModel | `Presentation/Scenes/Photos/ILPhotosViewModel.swift` | `Input -> Output`; new `loadMoreTriggered`; ignores a stale response after the category changed; owns `ILPhotosNavEvent` (`.back`). |
| Presentation / Coordinator | `Presentation/Scenes/Photos/ILPhotosCoordinator.swift` | Unchanged (leaf). |
| Presentation / ViewController | `Presentation/Scenes/Photos/ILPhotosViewController.swift` | Unchanged except wiring load-more and the footer. |
| Feature-scoped views | `Views/ILPhotosPhotoCardView.swift`, `Views/ILPhotosMasonryGridView.swift` | Card shows `ILRemoteImageView` at a fixed 4:3 tile; grid appends new items incrementally (`if photos != oldValue`), reports near-bottom scroll, hosts `ILLoadMoreFooterView`. |
| DI | `App/DIContainer.swift` | `makePhotosRepository()`; `makePhotosUseCase()` injects it. |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showPhotos() → ILPhotosCoordinator               (leaf, no delegate)
       push ILPhotosViewController
       (.back) → pop + finish()
```

## Data flow

1. `viewDidLoad` → `useCase.loadFirstPage(category: nil)` → `GET /v1/gallery?page=1`.
2. Scroll near the bottom (threshold 120 pt) while `hasMore && !isLoadingMore`
   → `loadNextPage(after:)` → `GET /v1/gallery?page=N+1[&type=T]`; only new rows
   are appended.
3. Category chip → the chip moves at once, the current photos stay visible and
   `loadFirstPage(category:)` runs; the grid crossfades (0.25 s, back to the top)
   when the response arrives. A response for a previous selection is discarded;
   on failure the chip moves back to the category still shown.
4. Failure → keep loaded photos, clear the spinner, surface the error.
5. `handleBack` emits `.back`.

There is a single API call per user action, so no Step-by-step Flow is needed.

## Decisions

- **Server-side filter.** Selecting a category re-queries with `type` instead of
  filtering locally: the server pages 20 at a time, so a local filter would show
  a partial subset of a category until every page was loaded.
- **Fixed 4:3 tiles.** The API gives no width/height (assumption
  `AS-Photos-001`); `imageHeight` is removed from the Entity. The masonry layout
  class is kept (2 columns, shortest-column placement) so real ratios can be
  plugged in later.
- **Thumbnail only.** The grid loads `thumbnail_url` (500 px); `image_url` is
  carried on the Entity for a future detail screen.
- **Dev host.** `APIConfig.serverBaseURL` (`.dev` = `192.168.1.186:8080`); image
  URLs use whatever host the server returns. HTTP needs the existing ATS
  exception in `Info.plist`.
