# Changelog — Gallery Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

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
