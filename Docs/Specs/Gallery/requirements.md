# Requirements — Gallery

Version: 2.1
Last updated: 2026-10-15
Status: in-progress — Home block, gallery grid (paging, topic chips) and photo viewer are built against the gallery API (2026-10-06…10-07, build-verified, tests written but not run); product spec v1.1 alignment pending: name "Ảnh đẹp Phật giáo", credit in the viewer, viewer across the whole filtered gallery, no heart / wallpaper / share, real "Lưu ảnh" with its error toasts, home "+N" from the whole-gallery total, home block error / empty states, shared load-error copy, grid error / empty states — `tasks.md` Phase 2–8. Credit and "+N" are blocked on backend gallery v2.0 (not built); the viewer is not released to users before it (product §2.7).
Feature folders: `InnerLamp/Presentation/Scenes/Photos/` (gallery), `InnerLamp/Presentation/Scenes/PhotoViewer/` (viewer), the photo block of `InnerLamp/Presentation/Scenes/Home/`
Product spec: innerlamp-be `docs/product/gallery/product.md` @ v1.1
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ b0ad9c5 (info.version 1.0.0) — tag Gallery: `GET /v1/gallery/top` (`galleryTop`), `GET /v1/gallery` (`galleryList`), `GET /v1/gallery/{id}` (`galleryGet`, not used by iOS). Planned (backend gallery `docs/specs/features/gallery/requirements.md` v2.0, AC 3 and 11 — designed, **not built**, not yet in `openapi.yaml`): every item of `top` and of the paged list gains `author`, `license`, `source_url`; `top` gains `total` (whole gallery, no filter).
Architecture: none (product §2.7: no ADR for the feature)
Implements: BR-GAL-01, BR-GAL-02, BR-GAL-03, BR-GAL-04, BR-GAL-05, BR-GAL-06, BR-GAL-07, BR-GAL-08, BR-GAL-09, FR-GAL-001, FR-GAL-002, FR-GAL-003, FR-GAL-004, FR-GAL-005, FR-GAL-006, FR-GAL-007, FR-GAL-008, NFR-GAL-01, NFR-GAL-02, NFR-GAL-03
Not on iOS: FR-GAL-009 (Backend only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the Buddhist photo gallery ("Ảnh đẹp Phật giáo" — Buddhist photos). As
product §1.5 asks, this one folder merges the former `Docs/Specs/Photos/` v1.2 (gallery grid; its
changelog reached v1.3) and `Docs/Specs/PhotoViewer/` v1.0 (viewer), and absorbs their assumptions
(`AS-Photos-001`, `AS-PhotoViewer-001`) and tech debt (`TD-Photos-001`, `TD-Photos-002`,
`TD-PhotoViewer-001`, `TD-PhotoViewer-002`). The code folders keep their names (`Photos`, `PhotoViewer`).
The old spec folders and entries are kept until a separate clean-up change (`tasks.md` Phase 8).
Product behavior — order, featured list, page size, topic labels, credit, tile shape, viewer range,
"+N", removed actions, save, states — lives in the product spec and is **not** restated here; this
file only says how the iOS app implements those `BR-GAL-*` / `FR-GAL-*`. Written retroactively from the
built screens and prospectively for the product v1.0 and v1.1 changes.

> Layout source: the design prototype `InnerLamp Prototype.dc.html` (product §1.5), screen `photos`
> with its viewer block (`pvOpen`) and the home section. Where the prototype and the product spec
> differ (title "Ảnh chùa đẹp", heart, "Đặt hình nền" (set as wallpaper), "Chia sẻ" (share)), the
> product spec wins.

## User Story

As a visitor (signed in or not), I want to browse beautiful Buddhist photos on my iPhone — a few on
Home, the whole gallery filtered by topic, each photo large with its credit — and save the ones I like
to my photo library, so that I can enjoy them quietly and use them while respecting their authors.

## Constraints from the product spec

- **The server orders, pages and filters** (BR-GAL-02, BR-GAL-03): the app shows photos in the order
  received, sends the topic as the `type` filter and never sorts or filters locally. The vector
  `rules/gallery-order.json` is backend-only (product §4.1).
- **Apps load 20 photos at a time** at the end of the grid (§3.6 row BR-GAL-03 / FR-GAL-002).
- **Home block on the apps**: 3 tiles with "+N ảnh" (N more photos), computed by the app from the
  whole-gallery total (§3.6 row FR-GAL-001 / BR-GAL-07); the app runs `rules/gallery-home-more.json`.
- **A load failure is always shown, never hidden** (FR-GAL-008): every surface — Home block, gallery
  grid, viewer — uses the one load-error message "Không tải được danh sách ảnh. Vui lòng thử lại sau." (Couldn't load the photo list. Please try again later.), with "Thử lại" (Try again) wherever a
  retry is possible.
- **Credit is a licence obligation** (product §2.5, BR-GAL-04): the viewer must not reach users
  without the credit.
- **Release gate** (product §2.7, A2): the photo viewer is not shipped to users before backend gallery
  v2.0 carries the credit in every list. There is no per-photo fallback: iOS never calls
  `GET /v1/gallery/{id}` to show the credit in the meantime.
- **Vietnamese interface only** on iOS today (only `vi.json` exists); titles and places are shown as
  received (BR-GAL-09).
- **Online only** (product §2.4): nothing is cached on the device beyond the image HTTP / memory
  cache of `ILRemoteImageView`.

## Acceptance Criteria (EARS notation)

### Home block "Ảnh đẹp Phật giáo"

1. WHEN Home loads, THE SYSTEM SHALL request `GET /v1/gallery/top` without signing in and show the block titled "Ảnh đẹp Phật giáo" with "Xem tất cả" (See all) and the first 3 photos received as tiles, in the order received, using each photo's thumbnail. (FR-GAL-001, BR-GAL-01, BR-GAL-02, NFR-GAL-02)
2. WHEN `top` has answered, THE SYSTEM SHALL cover the last tile with "+N ảnh", N = the response's `total` minus the tiles shown, and SHALL show the overlay only when N > 0; every case of `rules/gallery-home-more.json` SHALL pass. (BR-GAL-07, FR-GAL-001)
3. WHEN `top` returns 1 or 2 photos, THE SYSTEM SHALL show only that many tiles, with no empty placeholder tile; WHEN `top` succeeds with no photo, THE SYSTEM SHALL still show the block with its title and show "Chưa có ảnh nào." (No photos yet.) in place of the tiles, with no tile and no overlay. (BR-GAL-07, BR-GAL-02, FR-GAL-008)
4. WHEN the user taps any tile, the "+N ảnh" overlay or "Xem tất cả", THE SYSTEM SHALL open the gallery with the filter "Tất cả" (All). (FR-GAL-001)
5. WHEN `top` fails (no connection, server unreachable, `500`, undecodable), THE SYSTEM SHALL still show the block with its title and show, in place of the tiles, the shared error block "Không tải được danh sách ảnh. Vui lòng thử lại sau." (Couldn't load the photo list. Please try again later.) with "Thử lại" (Try again) — no tile, no placeholder tile, no sample photo — and SHALL NOT fail the rest of Home; WHEN the user taps "Thử lại", THE SYSTEM SHALL request `GET /v1/gallery/top` again for this block only and show the tiles (or the empty text of criterion 3) on success. (FR-GAL-008; block-only retry: platform)
6. WHEN the `top` response carries no `total` (a backend before gallery v2.0), THE SYSTEM SHALL show the tiles without the "+N ảnh" overlay rather than a count of the featured photos. (BR-GAL-07, platform)

### Gallery "Ảnh đẹp Phật giáo"

7. WHEN the gallery opens, THE SYSTEM SHALL show the header "Ảnh đẹp Phật giáo", request `GET /v1/gallery?page=1` without `type`, show the skeleton grid until it answers, then show the photos in the order received as a 2-column grid of tiles of one 4:3 landscape shape, the thumbnail filling the tile (cropped at the edges), each tile with its title and place, and the subtitle "{total} ảnh" ({total} photos) with `total` from the response. (FR-GAL-002, BR-GAL-01, BR-GAL-02, BR-GAL-05, NFR-GAL-02)
8. WHILE a thumbnail is loading, or WHEN it fails to load, THE SYSTEM SHALL keep the neutral placeholder tile and show no error. (NFR-GAL-02, platform)
9. WHEN the user scrolls within 120 pt of the end of the grid and the last response says more pages exist, THE SYSTEM SHALL request the next page for the current filter, show "Đang tải thêm ảnh…" (Loading more photos…) while it loads and append only photos not shown yet (by `id`), keeping the photos already shown; THE SYSTEM SHALL never have two page requests in flight; WHEN the last page has been loaded (`page >= total_pages`) or a page comes back empty, THE SYSTEM SHALL request no further page and end the grid with "Bạn đã xem hết ảnh" (You have seen every photo). (FR-GAL-002, BR-GAL-03, NFR-GAL-01)
10. THE SYSTEM SHALL show the topic chips "Tất cả", "Chùa", "Tượng Phật", "Cảnh thiền", "Lễ hội" in this order, one selected at a time; WHEN the user selects a topic, THE SYSTEM SHALL select its chip at once, request `GET /v1/gallery?page=1&type=<value>` (`CHUA`, `TUONG_PHAT`, `THIEN`, `LE_HOI`) while the current photos stay visible, then crossfade the grid to the new photos, scroll it to the top and set the subtitle to "{total} ảnh · {topic}". (FR-GAL-003, BR-GAL-01, BR-GAL-03)
11. WHEN the user selects "Tất cả", THE SYSTEM SHALL request page 1 without `type` and show photos of every topic in the order received. (FR-GAL-003, BR-GAL-02)
12. WHEN a response arrives for a topic that is no longer the newest selection, THE SYSTEM SHALL drop it. (platform)
13. WHEN the first page of the gallery cannot be loaded, THE SYSTEM SHALL show the shared error block in place of the grid — "Không tải được danh sách ảnh. Vui lòng thử lại sau." (Couldn't load the photo list. Please try again later.) and "Thử lại" (Try again), no tile, no subtitle count, no end line — and WHEN the user taps "Thử lại", THE SYSTEM SHALL request page 1 for the selected chip again. (FR-GAL-008)
14. WHEN a later page fails, THE SYSTEM SHALL keep the photos already shown, remove the loading line, show the load-error message of criterion 13 as a toast (never the system error text) and request that page again the next time the user reaches the end of the grid. (FR-GAL-008; toast: platform)
15. WHEN page 1 of a newly selected topic fails while photos are shown, THE SYSTEM SHALL keep those photos, move the chip selection back to the topic they belong to and show the load-error message of criterion 13 as a toast. (FR-GAL-008; toast: platform)
16. WHEN the gallery or the selected topic holds no photo (`total` 0), THE SYSTEM SHALL show "Chưa có ảnh nào trong chủ đề này." (No photos in this topic yet.) in place of the grid, with no end line. (FR-GAL-008)
17. WHEN the user taps the back control, THE SYSTEM SHALL close the gallery and return to Home. (platform)

### Photo viewer

18. WHEN the user taps a tile, THE SYSTEM SHALL open the viewer on that photo with the tile morphing into the large photo (hero transition) on a dark background, showing the close control (×), the counter "{position} / {total}" where {total} is the server `total` of the current filter, the large photo (`image_url`) in a full-width 4:3 frame filled like the tile (cropped, never letterboxed), the topic as an uppercase small heading, the title, the place, the credit (criterion 24) and "Lưu ảnh" (Save photo). (FR-GAL-004, BR-GAL-04, BR-GAL-05, BR-GAL-06, NFR-GAL-02)
19. THE SYSTEM SHALL show no favourite (heart) control, no "Đặt hình nền" and no "Chia sẻ" action in the viewer, and none of their confirmation messages. (BR-GAL-08)
20. WHEN the user swipes left or taps the next arrow, THE SYSTEM SHALL show the next photo of the current filter in the gallery order with its own topic, title, place, credit and position; WHEN the user swipes right or taps the previous arrow, the previous one; THE SYSTEM SHALL hide the previous arrow on position 1 and the next arrow on position {total}, and ignore swipes past either end. (FR-GAL-005, BR-GAL-06, BR-GAL-04)
21. WHEN the viewer shows a photo within 3 positions of the last loaded photo and more pages exist, THE SYSTEM SHALL request the next page for the current filter through the same paging state as the grid (one request in flight for both), so the new photos are in the viewer and in the grid. (FR-GAL-005, BR-GAL-06, NFR-GAL-01)
22. WHEN the user moves to the next position while its page is still loading, THE SYSTEM SHALL keep the current photo with a loading indicator on the next control and show the next photo as soon as the page arrives. (FR-GAL-005, platform)
23. WHEN that page fails, THE SYSTEM SHALL stay on the current photo, keep the next control offered, show the load-error message of criterion 13 as a toast, and request the page again the next time the user moves to the next photo. (FR-GAL-008, BR-GAL-06)
24. WHEN a photo is shown in the viewer, THE SYSTEM SHALL show its credit "Ảnh: {author} · {licence}" (Photo: {author} · {licence}) with `author` and `license` as received; WHEN the user taps the credit and the photo's `source_url` is an `http`/`https` URL, THE SYSTEM SHALL open it in Safari; WHEN the photo has no source link (absent, or not `http`/`https`), THE SYSTEM SHALL still show the credit as plain text that is not tappable (no button trait, no tap feedback) and opens nothing. (FR-GAL-006, BR-GAL-04; the `http`/`https` filter: platform)
25. WHEN the user taps ×, THE SYSTEM SHALL close the viewer and return to the gallery with the tile of the photo last shown scrolled into view, morphing the large photo back into that tile. (FR-GAL-004)
26. WHEN the user changes photo, THE SYSTEM SHALL clear any message shown under the actions. (platform)

### Save the photo (FR-GAL-007)

27. WHEN the user taps "Lưu ảnh", THE SYSTEM SHALL ask iOS for add-only access to the photo library (`PHAccessLevel.addOnly`), which shows the system prompt only the first time, and SHALL never ask for read access. (FR-GAL-007, platform)
    The purpose text of the prompt (`NSPhotoLibraryAddUsageDescription`) is "InnerLamp cần quyền thêm ảnh để lưu ảnh bạn chọn vào thư viện." (InnerLamp needs permission to add photos to save the photo you choose to your library) (product §3.6 row FR-GAL-007 iOS).
28. WHEN add-only access is granted, THE SYSTEM SHALL download the large photo (`image_url`) and add it to the photo library, keep "Lưu ảnh" disabled with a progress indicator meanwhile, and show "Đã lưu vào thư viện ảnh" (Saved to the photo library) only after iOS confirms the photo was added. (FR-GAL-007, NFR-GAL-02)
29. WHEN access is denied, THE SYSTEM SHALL save nothing, show the toast "Chưa có quyền lưu ảnh. Mở Cài đặt để cấp quyền." (No permission to save photos yet. Open Settings to grant it.) with an action that opens the app's page in the iOS Settings app, and SHALL NOT show "Đã lưu vào thư viện ảnh". (FR-GAL-007, product §3.6 iOS)
    > ⚠️ Not confirmed (product): the label of the toast's open-Settings action (FR-GAL-007 gives the message, not the action label; suggested "Mở Cài đặt" (Open Settings)) — blocks only the `photoViewer.save.openSettings` copy in `tasks.md` Phase 4; hand back to ba-writer in innerlamp-be.
30. WHEN the download or the save fails, THE SYSTEM SHALL save nothing, show the toast "Không lưu được ảnh. Vui lòng thử lại." (Couldn't save the photo. Please try again.) with no Settings action and SHALL NOT show "Đã lưu vào thư viện ảnh"; WHEN access is restricted by the device (`.restricted`), THE SYSTEM SHALL do the same. (FR-GAL-007; `.restricted` mapping: platform)
    The iOS-only `.restricted` case (device policy, not the user's choice) uses the save-failed toast, not the Settings toast — an iOS choice recorded in `Docs/Assumptions/Gallery/AS-Gallery-001-restricted-save-copy.md`.

### Content language and responsiveness

31. THE SYSTEM SHALL show photo titles and places exactly as received (Vietnamese), with interface copy in Vietnamese. (BR-GAL-09)
32. WHEN the user selects a topic on a 4G connection, THE SYSTEM SHALL show its first photos within 2 s (checked by manual QA on a device). (NFR-GAL-03)

## Error → UI mapping

Operations are cited, not copied; the contract is innerlamp-be `docs/specs/api/openapi.yaml` (tag
Gallery) plus the planned v2.0 fields of backend gallery requirements AC 3 and 11. There is no cached
copy in any case.

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/gallery/top` | any failure | block title kept; shared error block with "Thử lại" in place of the tiles; the rest of Home loads (criterion 5) |
| `GET /v1/gallery/top` | `items` empty | block title kept; "Chưa có ảnh nào." in place of the tiles (criterion 3) |
| `GET /v1/gallery/top` | no `total` (pre-v2.0 backend) | tiles without "+N ảnh" (criterion 6) |
| `GET /v1/gallery` page 1 with no photo shown (open, "Thử lại") | any failure | shared error block with "Thử lại" in place of the grid (criterion 13) |
| `GET /v1/gallery` page 1, `total` 0 | — | "Chưa có ảnh nào trong chủ đề này." (criterion 16) |
| `GET /v1/gallery` page 1 of a new topic, photos shown | any failure | photos kept, chip reverted, load-error toast (criterion 15) |
| `GET /v1/gallery` page > 1 from the grid | any failure | photos kept, loading removed, load-error toast, retried on the next reach of the end (criterion 14) |
| `GET /v1/gallery` page > 1 from the viewer | any failure | stays on the current photo, load-error toast, retried on the next move to the next photo (criterion 23) |
| `GET /v1/gallery` | `400 INVALID_PAGE`, `400 INVALID_GALLERY_TYPE` | same as the other failures (the app never sends such values — a bug, logged, not a user error) |
| thumbnail / large image URL | any failure | placeholder, no message (criterion 8; viewer keeps its placeholder frame) |
| photo library | denied | toast "Chưa có quyền lưu ảnh. Mở Cài đặt để cấp quyền." with the open-Settings action (criterion 29) |
| photo library / large image download | restricted, download failed, save failed | toast "Không lưu được ảnh. Vui lòng thử lại.", no Settings action (criterion 30) |

## Out of scope (this feature boundary, not backend work)

- Favourite, set as wallpaper, share (BR-GAL-08, product §1.2).
- Masonry (staggered) tiles, search, pinch-to-zoom in the viewer, a web page per photo (product §1.2).
- `GET /v1/gallery/{id}`: iOS opens the viewer only from a tile, so the list item is enough once it
  carries the credit (product §3.1.3). It is not used as a temporary per-photo credit source either:
  the viewer waits for backend v2.0 instead (product §2.7, A2).
- Temple photos inside the temple page (`Docs/Specs/Temple/`) and deity images (`Docs/Specs/Deity/`).
- Loading gallery content (FR-GAL-009, backend only).

## Pending (not yet implemented — see `tasks.md`)

- Credit in the viewer (`tasks.md` Phase 2 + 4) and "+N ảnh" from the whole-gallery total (`tasks.md`
  Phase 2 + 6) — both need backend gallery v2.0.
- **Release gate** (product §2.7, A2): no build that exposes the photo viewer to users ships before
  backend gallery v2.0 is live and Phase 2 + the credit row of Phase 4 are done (`tasks.md` Phase 8).

  > ⚠️ Not confirmed: when the backend ships gallery v2.0 (credit fields on `top` and the paged list, `total` on `top`) and adds it to `openapi.yaml` (backend gallery `tasks.md` Phase 6–7, not started) — blocks `tasks.md` Phase 2, the credit / "+N" parts of Phase 4 and 6, and the release of the viewer to users (product §2.7). Until then iOS keeps today's behavior (no credit — `TD-Photos-001`, and "+N" counting the remaining featured photos — drift, product §4.2 BR-GAL-04 / BR-GAL-07).

- Name "Ảnh đẹp Phật giáo" on Home and the gallery header (`tasks.md` Phase 5, 6).
- Viewer across the whole filtered gallery with the server total (`tasks.md` Phase 3; resolves
  `TD-PhotoViewer-002`); return to the last shown tile (Phase 3).
- Remove heart, "Đặt hình nền", "Chia sẻ" and their toasts; real "Lưu ảnh" (`tasks.md` Phase 4;
  resolves `TD-PhotoViewer-001`).
- Grid error state with "Thử lại", the shared load-error copy in every toast, and the empty-topic text
  (`tasks.md` Phase 5).
- Home block error block with "Thử lại", empty text, fewer than 3 tiles (`tasks.md` Phase 6).
- Viewer next-page failure toast; save toasts with the open-Settings action; permission purpose text;
  credit not tappable without a source link (`tasks.md` Phase 3, 4).
- Visual QA and a test run on a device (`tasks.md` Phase 8).
- Product Appendix A items 1, 2 and 6 (production photo storage, content load in staging /
  production, content review) block production release, not this spec.

## Open questions (resolved)

- ~~Is "Tất cả" a category?~~ → No, it is the absence of a filter (`selectedCategory == nil`; product
  BR-GAL-01). Resolved 2026-10-06 (Photos v1.0), confirmed by product v1.0.
- ~~What is the photos API?~~ → `GET /v1/gallery` (public, 20 per page, `type` filter) and
  `GET /v1/gallery/top`, in `openapi.yaml` tag Gallery. Resolved 2026-10-06; the local "API contract"
  table of Photos v1.1–v1.2 is dropped and the spec cites `openapi.yaml` instead (2026-10-15).
- ~~No image dimensions — which tile shape?~~ → One 4:3 landscape shape for every tile and the viewer
  frame, photo fills and is cropped (BR-GAL-05, product Q10). Validates `AS-Photos-001` and
  `AS-PhotoViewer-001`. Resolved 2026-10-15.
- ~~Where do author, licence and source come from — a detail call?~~ → In every list item (BR-GAL-04,
  product Q4, backend v2.0 AC 11); the viewer needs no detail call. Resolved 2026-10-15 (delivery still
  pending, see Pending).
- ~~Does the viewer page only through the loaded photos?~~ → No, through the whole filtered gallery,
  counter total = server total (BR-GAL-06, product Q11). Resolved 2026-10-15.
- ~~Keep heart, wallpaper and share as stubs?~~ → All three removed (BR-GAL-08, product Q6–Q8); "Lưu ảnh"
  is real, add-only (FR-GAL-007, Q5). Resolved 2026-10-15.
- ~~What does "+N ảnh" count?~~ → The whole gallery minus the tiles shown, from `total` on `top`
  (BR-GAL-07, Q12). Resolved 2026-10-15.
- ~~Load-error copy and the Home block on error?~~ → One shared message "Không tải được danh sách ảnh.
  Vui lòng thử lại sau." with "Thử lại" wherever a retry is possible; the Home block shows it in place of
  the tiles, never hidden (FR-GAL-008, product P1, Appendix A item 5). Resolved 2026-10-15 (product v1.1).
- ~~Home block when `top` has no photo?~~ → The block stays with "Chưa có ảnh nào." (FR-GAL-008, product
  P4). Resolved 2026-10-15 (product v1.1).
- ~~Viewer cannot load the next photos?~~ → Error toast, stay on the current photo, moving next again
  retries (FR-GAL-008, product P5). Resolved 2026-10-15 (product v1.1).
- ~~Letterboxed viewer?~~ → No; the viewer crops to 4:3 (BR-GAL-05, product P3, Appendix A item 3).
  Resolved 2026-10-15 (product v1.1).
- ~~Save error copy?~~ → Toasts "Chưa có quyền lưu ảnh. Mở Cài đặt để cấp quyền." (with an action that
  opens Settings) and "Không lưu được ảnh. Vui lòng thử lại." (FR-GAL-007, product P2, Appendix A item
  4). Resolved 2026-10-15 (product v1.1).
- ~~iOS permission purpose text?~~ → "InnerLamp cần quyền thêm ảnh để lưu ảnh bạn chọn vào thư viện."
  (product §3.6, A1). Resolved 2026-10-15 (product v1.1).
- ~~Photo without a source link?~~ → Credit still shown, not tappable (BR-GAL-04, FR-GAL-006, product
  P6). Resolved 2026-10-15 (product v1.1).
- ~~May iOS fetch `GET /v1/gallery/{id}` for the credit while backend v2.0 is late?~~ → No; the viewer
  is not released to users before backend v2.0 (product §2.7, A2). Resolved 2026-10-15 (product v1.1).
- ~~Feature name?~~ → "Ảnh đẹp Phật giáo" everywhere (BR-GAL-01, Q2). Resolved 2026-10-15.
- ~~Sign-in needed?~~ → No (product §2.3, Q13). Resolved 2026-10-15.
