# Tasks — Gallery

Version: 2.0
Last updated: 2026-10-15
Status: in-progress — Phase 1 (built and still matching product v1.0) done; Phase 2–8 pending; Phase 2 blocked on backend gallery v2.0 (credit in the lists, `total` on `top`); save and error copy blocked on ⚠️ product

> See `changelog.md` in this folder for the version history of this spec.

> Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flows.
> `[x]` = verified in the code on 2026-10-15 **and** matching this spec v2.0; work that exists but no
> longer matches product v1.0 is listed as a `[ ]` change task instead.

## Phase 1 — Built and kept (retroactive record)

- [x] Shared Data layer: `TopPhotosEndpoint`, `PhotosPageEndpoint` (public, `page` + optional `type`), `ILPhotosSummaryDTO`, `ILPhotosMapper` (`type` ↔ `ILPhotosCategory`, unknown type dropped, empty URL → `nil`), `ILPhotosRepository` + `ILPhotosRepositoryImpl` (network-only, `ILCatalogError.from`, `hasMore` from the raw page)
- [x] `ILPhotosEntity` / `ILPhotosPageEntity` / `ILPhotosPhotoEntity`, `ILPhotosUseCase` (`loadFirstPage(category:)`, `loadNextPage(after:)`, de-duplicated by id)
- [x] Gallery grid: `ILPhotosCoordinator` (leaf of Home, back → pop + finish), `ILPhotosViewController`, `ILPhotosMasonryGridView` (2 columns, uniform 4:3 tiles via `ILPhotosPhotoCardView.imageAspectRatio = 0.75`, incremental append), `ILPhotosSkeletonView` for the first load, thumbnails through `ILRemoteImageView` with placeholder, title + place on each tile, subtitle "{total} ảnh" / "{total} ảnh · {topic}" (criteria 7 except the header title, 8, 17)
- [x] Paging: load-more 120 pt from the end with an in-flight guard, "Đang tải thêm ảnh…" / "Bạn đã xem hết ảnh" footer (end only once photos are shown), later-page failure keeps the photos, shows the error and is retried on the next reach of the end (criteria 9, 14)
- [x] Topic chips "Tất cả · Chùa · Tượng Phật · Cảnh thiền · Lễ hội" in product order, server-side `type` filter, chip selected at once, old photos kept until the response, crossfade + scroll to top, stale responses dropped, chip reverted and error shown on failure (criteria 10, 11, 12, 15)
- [x] Viewer shell: `ILPhotoViewerCoordinator` (child of `ILPhotosCoordinator`), `ILPhotoViewerViewController` (dark UI, `HeroTransition` push / pop on `photo-<id>`, swipe + arrows, arrows hidden at the ends, 4:3 aspect-fill frame), `ILPhotoViewerInfoPanelView` (uppercase topic, title, place), large photo from `image_url`, toast cleared on photo change (criteria 18 except credit / total / actions, 20 within the loaded photos, 26)
- [x] Home block: `GET /v1/gallery/top` in `ILHomeViewModel.loadTopPhotos()`, first 3 photos as tiles in `ILHomePhotoGridView`, any tile or "Xem tất cả" → gallery (criteria 1 except the title, 4)
- [x] Titles and places shown as received; Vietnamese interface (criterion 31)
- [x] DI: `DIContainer.makePhotosRepository`, `makePhotos*`, `makePhotoViewer*`; Home use case takes `ILPhotosRepository`; `ILHomeCoordinator.showPhotos()`
- [x] Unit tests written: `ILPhotosRepositoryTests` (14), `ILPhotosViewModelTests` (15), `ILPhotoViewerViewModelTests` (8), Home photo tests (type-checked, not run; they test the old behavior and are rewritten in Phase 3–6)
- [x] Scene notes: `InnerLamp/Presentation/Scenes/Photos/README.md`, `InnerLamp/Presentation/Scenes/PhotoViewer/README.md` (describe the v1 behavior; updated in Phase 8)

## Phase 2 — Credit and `total` from the backend (blocked: backend gallery v2.0, `tasks.md` Phase 6–7 there + `openapi.yaml`)

- [ ] Confirm that `author`, `license`, `source_url` on the items of `top` and the paged list, and `total` on `top`, are in innerlamp-be `docs/specs/api/openapi.yaml` (tag Gallery); update the `Contract:` line of `requirements.md` and drop the "planned" notes of `design.md`
- [ ] `ILPhotosSummaryDTO`: optional `author`, `license`, `sourceUrl`; new `ILPhotosTopDTO` `{items, total?}`
- [ ] `ILPhotosMapper`: map the credit (trimmed; `sourceUrl` kept only when `http`/`https`); `ILPhotosPhotoEntity` gains `author`, `license`, `sourceURL?`
- [ ] `ILPhotosTopEntity` (`items`, `totalCount?`); `ILPhotosRepository.loadTopPhotos()` returns it; `ILPhotosRepositoryImpl` decodes `ILPhotosTopDTO`
- [ ] `ILPhotosRepositoryTests`: credit decoded and mapped, non-http source dropped, `total` present / absent on `top`, a pre-v2.0 payload still decodes
- [ ] `ILPhotosMapperTests` (new): type mapping, unknown type dropped, credit trimming, source URL filter

## Phase 3 — Viewer across the whole filtered gallery (BR-GAL-06, FR-GAL-004, FR-GAL-005; resolves `TD-PhotoViewer-002`)

- [ ] `ILPhotoViewerPagingSource` + `ILPhotoViewerPagingState` (Presentation/Scenes/PhotoViewer); `ILPhotosViewModel` conforms (items, `totalCount`, `hasMore`, `isLoadingMore`, last error; `loadMore()` reuses the grid's load-more path and in-flight guard)
- [ ] `ILPhotosNavEvent.openPhoto(selectedID:)` (no array); `ILPhotosCoordinator` passes the paging source; `DIContainer.makePhotoViewer*` take it
- [ ] `ILPhotoViewerViewModel`: current photo by id; counter "{position} / {totalCount}" from the server total; previous hidden at 1, next hidden at `totalCount`; prefetch within 3 of the last loaded; pending-next state with a loading indicator; failure keeps the photo, shows the error, retries on the next move (criteria 18 total, 20, 21, 22, 23) — error copy blocked on ⚠️ (product A5)
- [ ] Close returns to the last shown photo: `.close(lastShownID:)`; `ILPhotosViewController` / `ILPhotosMasonryGridView` scroll that tile into view before the pop so the hero morphs into it (criterion 25)
- [ ] Tests: `ILPhotoViewerViewModelTests` (counter uses the server total, next at the last loaded photo triggers a load, pending next, failure keeps position, ends hidden), `ILPhotosViewModelTests` (viewer `loadMore()` appends to the grid, no duplicate in-flight request)

## Phase 4 — Viewer content and actions (BR-GAL-04, BR-GAL-08, FR-GAL-006, FR-GAL-007; resolves `TD-PhotoViewer-001`, with Phase 2 `TD-Photos-001`)

- [ ] Remove heart, "Đặt hình nền", "Chia sẻ": `favoriteTapped` input, `favoriteButton`, `isFavorite`, `favoriteIDs`, `ILPhotoViewerAction.setWallpaper` / `.share`, `ILIcons.viewerHeart` / `viewerHeartFilled` + image sets, keys `photoViewer.action.setWallpaper`, `photoViewer.action.share`, `photoViewer.toast.wallpaperSet`, `photoViewer.toast.shared`, `photoViewer.toast.favoriteOn`, `photoViewer.toast.favoriteOff`, `photoViewer.a11y.favorite` (criterion 19)
- [ ] Credit row in `ILPhotoViewerInfoPanelView`: "Ảnh: {author} · {licence}" (`photoViewer.credit`), tappable only with an http(s) source → `.openURL` → Safari via the coordinator; hidden while the fields are missing (criterion 24) — needs Phase 2 data
- [ ] `ILPhotoLibraryRepository` (Domain) + `ILPhotoLibraryRepositoryImpl` (Data: add-only authorization, download of `image_url` off the main actor, `PHAssetCreationRequest` with the downloaded data) + `ILPhotoSaveError`
- [ ] `ILPhotoViewerUseCase.savePhoto(imageURL:) -> ILPhotoSaveResult`; `DIContainer.makePhotoLibraryRepository`, `makePhotoViewerUseCase`
- [ ] `ILPhotoViewerViewModel`: "Lưu ảnh" disabled + progress while saving; toast "Đã lưu vào thư viện ảnh" only on `.saved`; denied → message + "open Settings" (`.openSettings` nav event); restricted / failed → message without Settings (criteria 27–30) — message copy blocked on ⚠️ (product A4)
- [ ] `Info.plist`: `NSPhotoLibraryAddUsageDescription` — copy blocked on ⚠️ (product, criterion 27 marker)
- [ ] Tests: `ILPhotoViewerUseCaseTests` (granted → saved; denied; restricted; download failure; save failure), `ILPhotoViewerViewModelTests` (no favourite / wallpaper / share in the state, success toast only after `.saved`, Settings action only for denied, credit text and link per photo)

## Phase 5 — Gallery alignment (BR-GAL-01, FR-GAL-008)

- [ ] Header title "Ảnh đẹp Phật giáo": `photos.header.title` (criterion 7)
- [ ] Rebuild the header on `ILStickyHeaderBand` + `ILNavBar` with the chips row inside the band (AGENTS.md 4.5; today a plain `UIView` + hand-made divider) — layout only, no behavior change
- [ ] `ILPhotosStateModel` screen state `content` / `error` / `empty`; `ILPhotosViewController` shows `ILStateView` in place of the grid for the first-load error with "Thử lại" (retries page 1 for the selected chip; replaces today's hidden re-tap-the-chip retry and the toast) (criterion 13) — copy blocked on ⚠️ (product A5)
- [ ] Empty state "Chưa có ảnh nào trong chủ đề này." (`photos.empty`) when `total` is 0, no end line (criterion 16)
- [ ] `ILPhotosViewModelTests`: error state on first-load failure + retry, empty state on `total` 0, chip revert keeps photos

## Phase 6 — Home block alignment (FR-GAL-001, BR-GAL-07, FR-GAL-008)

- [ ] Title "Ảnh đẹp Phật giáo": `home.photos.title` (criterion 1)
- [ ] `ILHomePhotoRules` (pure Domain): `tilesShown`, `moreCount`; `ILHomeUseCase.loadTopPhotos()` returns tiles + `totalCount`; `ILHomeViewModel.makeState` replaces `entity.photos.count - 3` with `moreCount(totalPhotos:tilesShown:)`, no overlay when `totalCount` is `nil` (criteria 2, 6) — the overlay stays hidden until Phase 2 data
- [ ] Block hidden (header + grid) when `top` fails: `ILHomeStateModel.isPhotosBlockVisible`, `ILHomeViewController` collapses the section without breaking the Home layout (criterion 5)
- [ ] `ILHomePhotoGridView` shows only the photos received when fewer than 3 (1 → the large tile alone, 2 → large + one small), no placeholder tile (criterion 3)
- [ ] Zero photos from `top` — blocked on ⚠️ (product, criterion 3 marker); until answered, hidden like an error
- [ ] `Scripts/sync-product-vectors.sh` (create or extend) copies `../innerlamp-be/docs/product/gallery/rules/gallery-home-more.json` into `InnerLampTests/ProductVectors/gallery/` with a `SOURCE` file; add it to the test target resources
- [ ] `ILGalleryProductVectorTests`: every case of `gallery-home-more.json` (BR-GAL-07) through `ILHomePhotoRules` (design "Product vectors"); `gallery-order.json` is backend-only
- [ ] `ILHomeViewModelTests` / `ILHomeUseCaseTests`: block hidden on failure, overlay from `total`, no overlay without `total`, 1 and 2 tiles

## Phase 7 — Non-functional checks (NFR-GAL-01, NFR-GAL-02, NFR-GAL-03)

- [ ] Confirm by test that no code path requests more than one page at a time or the whole gallery (grid + viewer) (NFR-GAL-01)
- [ ] Confirm tiles and Home use `thumbnail_url` and only the viewer and save use `image_url` (NFR-GAL-02; a `ILPhotosViewModelTests` / `ILHomeViewModelTests` assertion on the URLs passed)
- [ ] Manual QA on a device over 4G: a topic change shows its first photos within 2 s (criterion 32, NFR-GAL-03); record the result here

## Phase 8 — Verification and documentation

- [ ] Build (`xcodebuild build`, `generic/platform=iOS`) and test run (physical device per AGENTS.md); record the result here
- [ ] Manual QA on device against the prototype (`photos`, `pvOpen`, home section): chips, paging to the end, viewer paging past the loaded photos ("21 / 86"), "12 / 12" with no next on "Lễ hội", credit link, save (allow / deny / Settings), no connection on each surface, dark mode
- [ ] `InnerLamp/Presentation/Scenes/Photos/README.md` and `PhotoViewer/README.md`: status tables + changelog for these changes, and a pointer to `Docs/Specs/Gallery/`
- [ ] Separate change (not this one): delete `Docs/Specs/Photos/` and `Docs/Specs/PhotoViewer/`; set `AS-Photos-001` and `AS-PhotoViewer-001` to Validated (product BR-GAL-05); close `TD-Photos-001`, `TD-PhotoViewer-001`, `TD-PhotoViewer-002` when Phases 2–4 ship; update `Docs/Specs/Home/` (its photo criterion still says "Ảnh chùa đẹp", "+N for the rest" of the featured photos, placeholders on failure, and cites `Docs/Specs/Photos/design.md`) and the OKF `Docs/Knowledge/features/home.md`
- [ ] `Docs/Knowledge/features/gallery.md` (OKF) — with `okf-writer` after Phase 2–6 are verified on device

## Deferred (not blocking Gallery)

- Masonry (staggered) tiles with real photo sizes — product §1.2, later; needs width / height from the backend.
- Letterboxed viewer — only if product Appendix A item 3 is answered yes.
- Backend gallery v2.0 (credit in the lists, `total` on `top`) — backend `tasks.md` Phase 6–7.
