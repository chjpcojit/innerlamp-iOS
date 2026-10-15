# Design — Gallery

Version: 2.0
Last updated: 2026-10-15
Status: in-progress — gallery grid, viewer and Home block built network-only on `ILPhotosRepository` (`top`, paged list); planned: credit and `total` from backend gallery v2.0 (not built), viewer paging through the grid's paging state, viewer without heart / wallpaper / share, real add-only save, Home block hidden on error with "+N" from `total`, grid error / empty states, name "Ảnh đẹp Phật giáo"

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Three surfaces share one Data layer
(`ILPhotosRepository`, network-only — no Core Data, no cache beyond `ILRemoteImageView`):

- **Home block** "Ảnh đẹp Phật giáo" — part of `Presentation/Scenes/Home/` (`ILHomePhotoGridView`), fed by
  `ILHomeUseCase.loadTopPhotos()`.
- **Gallery** — `Presentation/Scenes/Photos/` (`ILPhotosCoordinator`, child of `ILHomeCoordinator`).
- **Photo viewer** — `Presentation/Scenes/PhotoViewer/` (`ILPhotoViewerCoordinator`, child of
  `ILPhotosCoordinator`), pushed with `HeroTransition`.

Code folder names stay `Photos` / `PhotoViewer` (product §1.5); type names keep their `ILPhotos*` /
`ILPhotoViewer*` prefixes. No rename is planned.

How iOS meets the product constraints (see `requirements.md` "Constraints"):

- **Server order, paging and filter** (BR-GAL-02, BR-GAL-03). The app appends pages in the order
  received and de-duplicates by `id`; the topic is the server `type`. No client-side sorting.
- **One paging state for grid and viewer** (BR-GAL-06). Today the viewer receives a snapshot array
  (`TD-PhotoViewer-002`). Planned: `ILPhotosViewModel` stays the only owner of the loaded pages and
  exposes them to the viewer through a small Presentation protocol (`ILPhotoViewerPagingSource`), so a
  page loaded from the viewer also appears in the grid, the counter total is the server `total` and
  only one page request is ever in flight.
- **Credit in the list item** (BR-GAL-04). The DTO / Entity / StateModel carry `author`, `license`,
  `sourceURL` once backend v2.0 sends them; the viewer makes no detail call.
- **"+N" from the whole gallery** (BR-GAL-07). A pure Domain rule computes N from `top.total` and the
  tiles shown; the product vector file is run against it.
- **Save is add-only** (FR-GAL-007). A Domain repository protocol hides the Photos framework; the Data
  implementation downloads `image_url` and adds it with `PHPhotoLibrary`; only `.addOnly` access is
  ever requested.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity (photo) | `Domain/Entities/ILPhotosEntity.swift` → `ILPhotosPhotoEntity` | id, `ILPhotosCategory`, title, place, `thumbnailURL?`, `imageURL?`. | built; **add** `author`, `license`, `sourceURL?` (only `http(s)` kept) |
| Domain / Entity (page, screen) | `Domain/Entities/ILPhotosEntity.swift` → `ILPhotosPageEntity`, `ILPhotosEntity` | One page (`items`, `page`, `totalCount`, `hasMore`); the gallery state (`photos`, `selectedCategory`, `totalCount`, `lastLoadedPage`, `hasMore`). | built; unchanged |
| Domain / Entity (featured) | `Domain/Entities/ILPhotosEntity.swift` → `ILPhotosTopEntity` (new) | `items: [ILPhotosPhotoEntity]`, `totalCount: Int?` (`nil` = backend before v2.0). | planned |
| Domain / Entity (Home) | `Domain/Entities/ILHomeEntity.swift` → `ILHomePhotoEntity`, `ILHomeEntity.photos` | Home tile (id, thumbnail). | built; **add** `ILHomeEntity.photosTotalCount: Int?` and a load-failed flag so the block can be hidden |
| Domain / Rule (Home "+N") | `Domain/UseCases/Home/ILHomePhotoRules.swift` (new) | Pure: `tilesShown(photoCount:) = min(3, photoCount)`; `moreCount(totalPhotos:tilesShown:) = max(0, total − tiles)`; overlay shown when > 0. Unit of the product vectors. | planned |
| Domain / Repository protocol | `Domain/Repositories/ILPhotosRepository.swift` | `loadTopPhotos()`, `loadPhotos(category:page:)`; failures are `ILCatalogError`. | built; **change** `loadTopPhotos() -> ILPhotosTopEntity` |
| Domain / UseCase (gallery) | `Domain/UseCases/Photos/ILPhotosUseCase.swift` | `loadFirstPage(category:)`, `loadNextPage(after:)` (de-duplicates by id; no-op when `hasMore == false`). Used by the grid and, through the grid's ViewModel, by the viewer. | built; unchanged |
| Domain / UseCase (Home) | `Domain/UseCases/Home/ILHomeUseCase.swift` → `loadTopPhotos()` | Featured tiles. | built; **change** return tiles + `totalCount` |
| Domain / Repository protocol (library) | `Domain/Repositories/ILPhotoLibraryRepository.swift` (new) | `requestAddAccess() async -> ILPhotoLibraryAccess` (`.granted` / `.denied` / `.restricted`); `saveImage(from url: String) async throws` (download + add). Errors: `ILPhotoSaveError` (`.downloadFailed`, `.saveFailed`). | planned |
| Domain / UseCase (save) | `Domain/UseCases/PhotoViewer/ILPhotoViewerUseCase.swift` (new) | `savePhoto(imageURL:) async -> ILPhotoSaveResult` (`.saved`, `.denied`, `.restricted`, `.failed`): asks add-only access, then saves; never throws to the ViewModel. | planned |
| Data / DTO | `Data/DTOs/ILPhotosDTO.swift` → `ILPhotosSummaryDTO` | `id`, `type`, `title`, `location`, `thumbnailUrl`, `imageUrl`; `.convertFromSnakeCase`, no `CodingKeys`. | built; **add** optional `author`, `license`, `sourceUrl` (optional so today's server still decodes) |
| Data / DTO (top) | `Data/DTOs/ILPhotosDTO.swift` → `ILPhotosTopDTO` (new) | `{items, total?}` for `GET /v1/gallery/top`; replaces the shared `ILCatalogTopListDTO` for this one call so the shared type stays unchanged. | planned |
| Data / DTO (page) | `ILCatalogPageDTO<ILPhotosSummaryDTO>` (shared) | `{items, page, page_size, total, total_pages}`. | built; unchanged |
| Data / Mapper | `Data/DTOs/Mappers/ILPhotosMapper.swift` | DTO → Entity; `type` ↔ `ILPhotosCategory` (`CHUA`, `TUONG_PHAT`, `THIEN`, `LE_HOI`); unknown type dropped; empty URLs → `nil`. | built; **map** `author`, `license` (trimmed, `nil` → `""`), `sourceUrl` (only `http`/`https` kept) |
| Data / Endpoints | `Data/DataSources/Remote/TopPhotosEndpoint.swift`, `PhotosPageEndpoint.swift` | `GET /v1/gallery/top`, `GET /v1/gallery?page=N[&type=T]`; `requiresAuth == false`. | built; unchanged |
| Data / Repository | `Data/Repositories/ILPhotosRepositoryImpl.swift` | Wraps `NetworkService`; `ILCatalogError.from`; `hasMore` = non-empty raw page and `page < total_pages`. | built; **change** `loadTopPhotos()` decodes `ILPhotosTopDTO` |
| Data / Repository (library) | `Data/Repositories/ILPhotoLibraryRepositoryImpl.swift` (new) | `PHPhotoLibrary.requestAuthorization(for: .addOnly)`; downloads `image_url` with `URLSession.shared` (shares the HTTP cache with `ILRemoteImageView`) off the main actor; `PHPhotoLibrary.shared().performChanges` + `PHAssetCreationRequest.forAsset().addResource(with: .photo, data:)`. The only file that imports `Photos`. | planned |
| App / Info.plist | `InnerLamp/Info.plist` | `NSPhotoLibraryAddUsageDescription` (required before the first request; absent today). | planned (⚠️ copy) |
| Presentation / Gallery | `Presentation/Scenes/Photos/ILPhotosViewModel.swift`, `ILPhotosStateModel.swift`, `ILPhotosViewController.swift`, `Views/ILPhotosMasonryGridView.swift`, `Views/ILPhotosPhotoCardView.swift`, `Views/ILPhotosSkeletonView.swift` | VM: page 1 on load, chip change (chip moves at once, old photos kept, stale responses dropped, chip reverted on failure), load-more with in-flight guard; StateModel: chips, photo models, subtitle, `isLoadingMore`, `hasMore`. VC: `ILNavBar` header + chips row, 2-column grid of 4:3 tiles (`imageAspectRatio = 0.75`), skeleton for the first load, `ILLoadMoreFooterView`, crossfade on chip change, errors as `showError` toasts. | built; **change** (Phase 3, 5): header title; `content` / `error` / `empty` screen state (`ILStateView` + "Thử lại"); conforms to `ILPhotoViewerPagingSource`; reveals the tile of the last shown photo on return; credit fields in `ILPhotosPhotoModel`; header rebuilt on `ILStickyHeaderBand` (AGENTS.md 4.5) while touching it |
| Presentation / Viewer paging protocol | `Presentation/Scenes/PhotoViewer/ILPhotoViewerPagingSource.swift` (new) | `var pagingStatePublisher: AnyPublisher<ILPhotoViewerPagingState, Never>` (`items: [ILPhotoViewerItemModel]`, `totalCount`, `hasMore`, `isLoadingMore`, `lastError?`) and `func loadMore()`. Implemented by `ILPhotosViewModel`, held `weak` by the viewer. | planned |
| Presentation / Viewer | `Presentation/Scenes/PhotoViewer/ILPhotoViewerViewModel.swift`, `ILPhotoViewerStateModel.swift`, `ILPhotoViewerViewController.swift`, `Views/ILPhotoViewerInfoPanelView.swift`, `Views/ILPhotoViewerIconButton.swift` | VM: current photo by id, previous / next, counter, toast timer. VC: dark UI, hero push / pop (`TransitionProviding`), swipe + arrows, 4:3 aspect-fill frame (`imageAspectRatio = 0.75`), info panel (topic eyebrow, title, place, actions, toast). | built; **change** (Phase 3, 4): items and total from `ILPhotoViewerPagingSource`; prefetch within 3 of the last loaded; pending-next state; credit row (tap → `.openURL`); only "Lưu ảnh" (save state: idle / saving / result); **remove** favourite input + button, `setWallpaper` / `share` actions, favourite / wallpaper / share toasts |
| Presentation / Viewer coordinator | `Presentation/Scenes/PhotoViewer/ILPhotoViewerCoordinator.swift`; `Presentation/Scenes/Photos/ILPhotosCoordinator.swift` | Leaf; `.close` → pop + `finish()`. `ILPhotosCoordinator` maps the snapshot today. | built; **change**: `ILPhotosCoordinator` passes the paging source + start id; new nav events `.close(lastShownID:)` (grid reveals the tile before the pop), `.openURL(URL)` → `UIApplication.shared.open` (Safari), `.openSettings` → `UIApplication.openSettingsURLString` |
| Presentation / Home block | `Presentation/Scenes/Home/ILHomeViewModel.swift` (`loadTopPhotos`, `makeState` "+N" at the `photos.count - 3` line), `ILHomeStateModel.swift`, `ILHomeViewController.swift`, `Views/ILHomePhotoGridView.swift` | 3 fixed tiles (1 large + 2 small), "+N ảnh" overlay on the last small tile, any tap → gallery; on failure `photos = []` and the tiles stay as placeholders. | built; **change** (Phase 6): "+N" from `ILHomePhotoRules`; `isPhotosBlockVisible` (hidden on failure); tiles collapse to the photos received (1–2); title copy |
| Localization | `Resources/Localization/vi.json` | `home.photos.*`, `photos.*`, `photoViewer.*`. | **change** `home.photos.title`, `photos.header.title` → "Ảnh đẹp Phật giáo"; **add** `photos.empty`, `photos.error.*` + retry (⚠️ copy), `photoViewer.credit` ("Ảnh: %@ · %@"), `photoViewer.save.*` (⚠️ copy), `photoViewer.save.openSettings`; **remove** `photoViewer.action.setWallpaper`, `photoViewer.action.share`, `photoViewer.toast.wallpaperSet`, `photoViewer.toast.shared`, `photoViewer.toast.favoriteOn`, `photoViewer.toast.favoriteOff`, `photoViewer.a11y.favorite` |
| Tokens | `Presentation/Common/DesignSystem/Tokens/ILIcons.swift`, `Assets.xcassets/Icons` | `viewerClose`, `viewerHeart`, `viewerHeartFilled`, `viewerChevronLeft`, `viewerChevronRight`. | built; **remove** `viewerHeart`, `viewerHeartFilled` and their image sets |
| DI | `App/DIContainer.swift` | `makePhotosRepository`, `makePhotos{UseCase,ViewModel,Coordinator}`, `makePhotoViewer{ViewModel,Coordinator}`; Home use case gets `makePhotosRepository()`. | built; **add** `makePhotoLibraryRepository`, `makePhotoViewerUseCase`; **change** `makePhotoViewer*` to take the paging source |
| Tests | `InnerLampTests/ILPhotosRepositoryTests.swift` (14), `ILPhotosViewModelTests.swift` (15), `ILPhotoViewerViewModelTests.swift` (8), `ILHomeUseCaseTests.swift`, `ILHomeViewModelTests.swift` | Stub repositories / use cases. Written and type-checked, never run (no device / provisioning for the test runner). | built (old behavior); **rewrite** per phase; **add** `ILPhotosMapperTests`, `ILPhotoViewerUseCaseTests`, `ILGalleryProductVectorTests` |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ (.openPhotos)  → showPhotos() → ILPhotosCoordinator          (tile, "+N ảnh" or "Xem tất cả")
       push ILPhotosViewController
       (.back)                       → pop + finish()
       (.openPhoto(selectedID))      → ILPhotoViewerCoordinator (child), HeroTransition push
            ILPhotoViewerViewController
            (.close(lastShownID))    → ILPhotosViewModel reveals that tile, then pop (hero morph)
                                       + finish()                              (planned: lastShownID)
            (.openURL(sourceURL))    → UIApplication.shared.open → Safari     (planned)
            (.openSettings)          → app page in the Settings app          (planned)
```

Today `.openPhoto` carries the whole loaded array (`photos:selectedID:`); planned it carries only the
id and the coordinator hands the viewer the `ILPhotoViewerPagingSource` (the grid's ViewModel).

## Step-by-step Flow — Gallery

```
Step 1 — First page (this feature)
- Trigger: `viewDidLoad`, or "Thử lại" in the error state
- Pre-condition: none (public); the selected chip is "Tất cả" on open
- API: GET /v1/gallery?page=1[&type=T] (galleryList) — page size fixed by the server (20), never sent
    - Success, total > 0 → tiles in order, subtitle "{total} ảnh" / "{total} ảnh · {topic}";
      hasMore = items non-empty && page < total_pages; hasMore false → end line
    - Success, total == 0 → "Chưa có ảnh nào trong chủ đề này."
    - Failure (any) with no photo shown → error state + "Thử lại" (⚠️ copy, product A5)

Step 2 — Next page (this feature; also triggered by the viewer, Step 5)
- Trigger: grid scrolled within 120 pt of the end, or the viewer within 3 of the last loaded photo
- Pre-condition: hasMore == true, no page request in flight
- API: GET /v1/gallery?page=<last + 1>[&type=T]
    - Success → append photos whose id is not shown yet; update total and hasMore; last / empty page
      → end line "Bạn đã xem hết ảnh"
    - Failure → keep photos, clear the loading line, show the error; the next reach of the end (or
      the next viewer move) repeats this step

Step 3 — Topic change (this feature)
- Trigger: tap a chip other than the selected one (re-tapping the selected chip retries only when
  nothing is shown)
- Pre-condition: none; any in-flight request is invalidated (generation counter)
- API: GET /v1/gallery?page=1[&type=T]
    - Success → crossfade (0.25 s) to the new photos, scroll to the top, new subtitle
    - Success, total == 0 → empty text
    - Failure with photos shown → photos kept, chip back to their topic, error shown
    - Failure with no photo shown → error state + "Thử lại"
    - A response for an older selection is dropped
```

## Step-by-step Flow — Photo viewer

```
Step 4 — Open (this feature, no network)
- Trigger: tap a tile
- Pre-condition: the id is in the grid's loaded photos
- Effect: push the viewer with HeroTransition (tile ↔ large photo share heroID "photo-<id>"); the
  viewer subscribes to the paging source: counter "{index + 1} / {totalCount}", previous hidden at 1,
  next hidden at totalCount; large photo from image_url in the 4:3 frame; credit row

Step 5 — Move and load more (this feature; reuses Step 2)
- Trigger: swipe / arrow
- Pre-condition: target position within 1…totalCount
    - Target loaded → show it (crossfade), clear the toast; if it is within 3 of the last loaded
      photo and hasMore → source.loadMore() (Step 2; no-op while a request is in flight)
    - Target not loaded yet (its page in flight or not requested) → loadMore(); keep the current
      photo with a loading indicator on next; move when the items arrive
    - Step 2 fails → stay, next still offered, error shown (⚠️ copy, product A5); the next move
      retries

Step 6 — Credit (this feature, no network)
- Trigger: tap "Ảnh: {author} · {licence}"
- Pre-condition: sourceURL is http(s)
- Effect: .openURL → Safari. No in-app browser, no detail call.
  ⚠️ Not confirmed: author / license / source_url are not sent by today's server (backend gallery
  v2.0 AC 11, not built) — until then the credit row is hidden (TD-Photos-001, licence breach,
  blocks release of the viewer).

Step 7 — Save (this feature; device photo library + image download)
- Trigger: tap "Lưu ảnh"
- Pre-condition: no save in progress for this photo; the button is disabled while saving
- Call 1: PHPhotoLibrary.requestAuthorization(for: .addOnly) — system prompt only the first time
    - .authorized / .limited → Call 2
    - .denied → "not saved" message + "open Settings" action (⚠️ copy, product A4); stop
    - .restricted → "not saved" message, no Settings action; stop
- Call 2: GET <image_url> (large photo, URLSession.shared, off the main actor)
    - Success → Call 3
    - Failure → "not saved" message; stop
- Call 3: PHPhotoLibrary.shared().performChanges { PHAssetCreationRequest addResource(.photo, data) }
    - Success → toast "Đã lưu vào thư viện ảnh" (~1.8 s)
    - Failure → "not saved" message
- A result that arrives after the user moved to another photo is still reported (the save concerns
  the photo it was started on); a move does not cancel a save in progress.

Step 8 — Close (this feature, no network)
- Trigger: tap ×
- Effect: .close(lastShownID) → the grid scrolls the tile of lastShownID into view without
  animation → pop with HeroTransition morphing into that tile → finish()
```

## Step-by-step Flow — Home block

```
Step 9 — Featured photos (Home)
- Trigger: Home load (in parallel with the other Home blocks)
- API: GET /v1/gallery/top (galleryTop, public)
    - Success, items ≥ 1 → tiles = first min(3, count) photos in order; "+N ảnh" with
      N = ILHomePhotoRules.moreCount(totalPhotos: total, tilesShown:) when total is present and N > 0;
      no total → no overlay
    - Success, items empty → block hidden (⚠️ Not confirmed (product): Home empty state, criterion 3)
    - Failure → block hidden (header + tiles), the rest of Home unaffected
  ⚠️ Not confirmed: `total` on top is backend gallery v2.0 AC 3 (not built); today's response has no
  total, so the overlay stays hidden after Phase 6 until the backend ships.
```

## Product vectors

- `rules/gallery-order.json` (BR-GAL-02) is backend-only: the app neither sorts nor filters.
- `rules/gallery-home-more.json` (BR-GAL-07, 5 cases) is run by `ILGalleryProductVectorTests`: for each
  case, `ILHomePhotoRules.moreCount(totalPhotos: input.total_photos, tilesShown: input.tiles_shown)`
  must equal `expected.more_count` and "overlay shown" (`moreCount > 0`) must equal
  `expected.overlay_shown`.
- `Scripts/sync-product-vectors.sh` (shared with Deity / Memorial / Temple / Calendar, created by
  whichever lands first) copies `../innerlamp-be/docs/product/gallery/rules/gallery-home-more.json` into
  `InnerLampTests/ProductVectors/gallery/` with a `SOURCE` file (backend commit sha + hash); never
  hand-edited.

## Deliberately stubbed for now

- **Credit.** Until backend v2.0 sends the credit in the lists, the decoded fields are `nil` and the
  credit row is hidden. This is a known licence gap (`TD-Photos-001`, High), not a fallback to keep: the
  viewer must not be released to users without it (product §2.5). Whether to bridge with a
  `GET /v1/gallery/{id}` call is an open iOS decision (`requirements.md` Pending).
- **"+N".** Until `top` carries `total`, Phase 6 shows no overlay (criterion 6) instead of today's count
  of the remaining featured photos. Shipping Phase 6 before the backend therefore removes the overlay
  for a while — acceptable, a wrong count is not.
- **Save.** Until Phase 4 the "Lưu ảnh" button is a stub that shows the success toast without saving
  (`TD-PhotoViewer-001`, High). Phase 4 removes the stub; no step may claim success before Call 3.

## Decisions

- **Server-side filter** (kept from Photos v1.1): a local filter over 20-photo pages would show a
  partial topic.
- **2-column masonry layout class with uniform 4:3 tiles** (kept): BR-GAL-05 fixes one shape; the
  masonry class stays so a later staggered layout (product §1.2, later) needs no rewrite.
- **Viewer reads the grid's paging state** rather than its own use case: one source of truth for the
  loaded photos, so closing the viewer after loading more shows the same photos in the grid, and no
  duplicate page requests. The viewer holds the source `weak`; the grid's ViewModel lives as long as
  the gallery screen, which is below the viewer in the stack.
- **Add-only access** and the large photo bytes as downloaded (no re-encoding), so the saved file is
  the server's JPEG.
- **Dev host.** Image URLs are used exactly as the server returns them (`APIConfig.serverBaseURL` is
  the LAN dev host; HTTP needs the existing ATS exception).

## Design reference

Prototype `InnerLamp Prototype.dc.html` (product §1.5): screen `photos` with its viewer block
(`pvOpen`) and the home section; the title "Ảnh chùa đẹp" and the heart / wallpaper / share controls of
the prototype are superseded by the product spec. Per-screen implementation notes:
`InnerLamp/Presentation/Scenes/Photos/README.md`, `InnerLamp/Presentation/Scenes/PhotoViewer/README.md`.
