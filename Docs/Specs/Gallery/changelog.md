# Changelog — Gallery Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v2.1 (2026-10-15) — follow product spec v1.1

Docs only; no code changed. Minor bump: answered questions and changed copy / states, no new phase and
no new API step.

- `requirements.md`: cites innerlamp-be `docs/product/gallery/product.md` @ v1.1 (product changelog
  v1.1: P1–P6, A1–A2). Constraints: "Home block on error is hidden" removed; added "a load failure is
  always shown" with the shared copy "Không tải được danh sách ảnh. Vui lòng thử lại sau." + "Thử lại"
  (FR-GAL-008) and the viewer release gate (§2.7, A2).
  - Criterion 3 (FR-GAL-008, P4): zero photos from `top` → the block stays with "Chưa có ảnh nào.";
    its ⚠️ marker closed.
  - Criterion 5 (FR-GAL-008, P1): `top` failure → the block stays with the shared error block and
    "Thử lại" (block-only retry, platform) instead of being hidden.
  - Criteria 13–15 (FR-GAL-008, P1): shared error copy — error block for the first load, toast for a
    later page or a topic change; criterion 13 ⚠️ marker (product A5) closed.
  - Criterion 18 (BR-GAL-05, P3): viewer crops to 4:3, never letterboxed; ⚠️ marker closed.
  - Criterion 23 (FR-GAL-008, BR-GAL-06, P5): next-photos failure → toast, stay on the current photo,
    the next move retries; ⚠️ marker closed.
  - Criterion 24 (BR-GAL-04, FR-GAL-006, P6): credit without a source link is shown, not tappable.
  - Criterion 27 (FR-GAL-007, §3.6, A1): purpose text "InnerLamp cần quyền thêm ảnh để lưu ảnh bạn
    chọn vào thư viện."; ⚠️ marker closed.
  - Criteria 29–30 (FR-GAL-007, P2): toasts "Chưa có quyền lưu ảnh. Mở Cài đặt để cấp quyền." (with
    an open-Settings action) and "Không lưu được ảnh. Vui lòng thử lại."; ⚠️ marker (product A4)
    closed. New ⚠️ Not confirmed (product): the label of the open-Settings action. `.restricted` uses
    the save-failed toast (`AS-Gallery-001`, new).
  - Error → UI table: Home failure / empty rows, grid and viewer later-page rows split, save rows per
    toast.
  - Pending / resolved: the "may iOS fetch `GET /v1/gallery/{id}` for the credit" question replaced by
    the release gate (no per-photo fallback, A2); the "Home block on failure → hidden" resolved line
    removed; resolved lines added for P1–P6, A1, A2. The backend v2.0 delivery marker stays open and
    now also blocks the viewer release.
- `design.md`: overview adds the release gate, the non-tappable credit and the one load-error copy
  (error block vs toast; never `error.localizedDescription`). Layers: Home entity load status and
  block state `tiles` / `empty` / `error` with "Thử lại" (replaces `isPhotosBlockVisible`); gallery
  toasts use the shared copy; viewer next-page toast, credit label without a source, save result
  toasts; `Info.plist` copy; localisation keys `photos.error.load`, `home.photos.empty`,
  `photoViewer.save.denied`, `photoViewer.save.failed` (`photoViewer.save.openSettings` ⚠️ label).
  Step-by-step Flows: Steps 1–3, 5–7 and 9 updated with the copy and the Home retry; Step 6 no detail
  call fallback. Decisions: release gate, shared copy with two presentations.
- `tasks.md`: Phase 1 items for criteria 14 and 15 now note the error copy as not yet matching (moved
  to Phase 5, nothing unticked or newly ticked). Changed `[ ]`: Phase 3 viewer failure toast + tests;
  Phase 4 credit without a source, save toasts, `Info.plist` copy, tests; Phase 5 error block copy;
  Phase 6 Home error block + retry and empty text replace "block hidden", tests. New `[ ]`: Phase 5
  replace the `localizedDescription` toasts; Phase 8 release gate check. Deferred "letterboxed viewer"
  removed (closed by P3).
- Reason: product spec v1.1 (be#40) answers the questions this spec raised against v1.0 and changes
  FR-GAL-008 (a load failure is never hidden). Shipped code that now contradicts a confirmed
  requirement (Home placeholders on failure, `localizedDescription` toasts, stub save) is covered by
  `[ ]` tasks; no code changed here.

## v2.0.1 (2026-10-15) — cleanup of the superseded docs

- `tasks.md`: the cleanup item is done (old Photos / PhotoViewer specs deleted, the two 4:3 assumptions
  Validated, Home spec v1.13 points here, open TD entries point here); closing the TD entries and the
  `ILPhotosDTO.swift` comment stay open. No requirement or design change.

## v2.0 (2026-10-15) — merge Photos + PhotoViewer, align with product spec v1.0

Docs only; no code changed. Major bump: new folder continuing the `Photos` history (last v1.3), the
`PhotoViewer` spec merged in, scope change (heart, wallpaper and share out; credit, real save and a
viewer across the whole gallery in), new phases and new API-dependent steps.

- `requirements.md`: rewritten against the cross-platform product spec innerlamp-be
  `docs/product/gallery/product.md` @ v1.0. Header carries `Product spec`, `Contract` (`openapi.yaml`
  @ b0ad9c5, info.version 1.0.0, tag Gallery; planned v2.0 fields from backend gallery requirements
  AC 3 and 11 — not built), `Architecture` (none) and `Implements` (BR-GAL-01…09, FR-GAL-001…008,
  NFR-GAL-01…03; FR-GAL-009 backend only). Covers the Home block, the gallery grid (merged from
  `Docs/Specs/Photos/` v1.2), the viewer (merged from `Docs/Specs/PhotoViewer/` v1.0), save, language
  and responsiveness: 32 EARS criteria, each tagged with a product ID or `(platform)`; error → UI
  mapping table. Open `⚠️ Not confirmed` markers: Home block with zero photos (product), gallery
  load-error copy (product A5, two places), letterboxed viewer (product A3), permission purpose text
  (product), save error copy (product A4), backend v2.0 delivery, interim detail call for the credit
  (iOS decision).
- `design.md`: the local "API contract" table of Photos v1.1–v1.2 is dropped — operations are cited
  from `openapi.yaml`, never copied. New layers table naming the real files with a State column
  (built / change / planned): credit fields and `ILPhotosTopDTO` / `ILPhotosTopEntity`,
  `ILHomePhotoRules`, `ILPhotoLibraryRepository` + Impl, `ILPhotoViewerUseCase`,
  `ILPhotoViewerPagingSource`, `Info.plist` key, removed heart / wallpaper / share. Step-by-step Flows
  for the gallery (first page, next page, topic change), the viewer (open, move and load more, credit,
  save, close) and the Home block. Product vectors: `gallery-home-more.json` on iOS,
  `gallery-order.json` backend-only.
- `tasks.md`: Phase 1 records what is built and still matches product v1.0 (`[x]`, verified in the
  code on 2026-10-15); Phase 2 credit and `total` (blocked on backend v2.0), Phase 3 viewer across the
  whole filtered gallery, Phase 4 viewer content and actions, Phase 5 gallery alignment, Phase 6 Home
  block, Phase 7 non-functional checks, Phase 8 verification and documentation. Work that exists but
  no longer matches (title "Ảnh chùa đẹp", snapshot viewer with a loaded-count total, stub actions and
  toasts, "+N" counting featured photos, placeholder tiles on failure, error toast without retry) is
  listed as `[ ]` change tasks.
- Absorbed: `AS-Photos-001` and `AS-PhotoViewer-001` (4:3 tiles and frame — now product BR-GAL-05),
  `TD-Photos-001` (credit → Phase 2 + 4), `TD-Photos-002` (already resolved: Home reads `top`),
  `TD-PhotoViewer-001` (stub actions → Phase 4), `TD-PhotoViewer-002` (snapshot viewer → Phase 3).
  The entries themselves are not edited here.
- Reason: product spec v1.0 (2026-10-15) settles the feature for every platform and its §1.5 maps iOS
  to one folder `Docs/Specs/Gallery/`, merging the former `Photos` and `PhotoViewer` specs; the repo
  language policy requires English. `Docs/Specs/Photos/`, `Docs/Specs/PhotoViewer/` and their entries
  are kept for now — their clean-up is a separate change (`tasks.md` Phase 8).

## Merged history — former `Docs/Specs/Photos/` (gallery grid)

- v1.3 (2026-10-07): tiles open the photo viewer (`ILPhotosNavEvent.openPhoto`, tile `heroID`, bottom
  nav kept hidden under the viewer).
- v1.2 (2026-10-07): crossfade on a category change; the chip moves at once and reverts on failure.
- v1.1 (2026-10-06): real gallery API (`GET /v1/gallery`, 20 per page, `type` filter), infinite scroll
  with footer, errors keep loaded photos; `AS-Photos-001`, `TD-Photos-001`, `TD-Photos-002` recorded.
- v1.0: initial retroactive spec of the masonry gallery on a static catalog.

## Merged history — former `Docs/Specs/PhotoViewer/` (viewer)

- v1.0 (2026-10-07): initial spec and Phase 1 build from the prototype's `pvOpen` block — hero
  transition, swipe / arrow paging over a snapshot of the loaded photos, heart and three stub actions
  with toasts; `GET /v1/gallery/{id}` deferred (`⚠️ Not confirmed`); `TD-PhotoViewer-001`,
  `TD-PhotoViewer-002`, `AS-PhotoViewer-001` recorded.
