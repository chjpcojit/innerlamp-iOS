# Library

## Overview

Library tab ("Thư viện"): pinned title, tap-only search bar, a 2×2 quick-access tile grid
(Kinh sách / Thiền định / Pháp thoại / Phật & Bồ Tát), a featured dark card, a "Chư Phật & Bồ Tát"
carousel (shared with Home's "Thư viện Phật & Bồ Tát" carousel), and a "Kinh thường tụng" list of
content rows.
Tab 2 of `ILMainTabBarController` (owned by `ILMainTabCoordinator`; switching tabs is handled by the tab bar, not by this screen). Previously: root screen owned by `AppCoordinator` (Home tab returned to
`ILHomeCoordinator`). Spec: `Docs/Specs/Library/`. Design: prototype screen `lib`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILLibraryEntity.swift` | Done | Catalog, item, featured, kind/tone, `deities` (shared `ILHomeDeityEntity`). Pure business fields. |
| Presentation — StateModel | `ILLibraryStateModel.swift` | Done | Quick-access tiles, featured, deities, sutras section title + view-all, rows (formatted duration), empty copy. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Catalog endpoint not confirmed, see spec Phase 3. |
| Domain — UseCase | `ILLibraryUseCase.swift` | Partial | `getCatalog()` returns a static mock catalog + real deities via `ILDeityUseCase.getAllDeities()` (TODO: sutra/meditation/talk repository). |
| Presentation — ViewModel | `ILLibraryViewModel.swift` | Done | 8 Inputs, Entity → StateModel mapping, duration formatting. |
| Presentation — ViewController | `ILLibraryViewController.swift` | Done | Built from `ILSearchBarView`, `ILFeatureCardView`, `ILSectionHeaderView`, `ILHomeDeityCarouselView` (shared with Home) + `Views/`. Visual QA pending. |
| Presentation — Coordinator | `ILLibraryCoordinator.swift` | Partial | `openDeity` → `ILDeityCoordinator`; `openQuickAccess(.buddhas)` → Deities, `openQuickAccess(.meditation)` → `ILMeditationHubCoordinator`, `openQuickAccess(.sutras)` → `ILSutrasCoordinator`; `openSearch` / `openQuickAccess(.talk)` / `openItem(.meditation)` are TODO (screens not built). |
| Tests | `ILLibraryViewModelTests.swift` | Done | ViewModel per-Input tests + UseCase deity-mapping test. |
| Wiring | `DIContainer` + `AppCoordinator` | Done | `ILMainTabCoordinator` creates it on the Library tab's own nav; `makeLibraryUseCase()` now also injects `ILDeityUseCase`. |

## Navigation events

- `openSearch` — search bar tapped. TODO in coordinator (Search screen not built).
- `openItem(id:kind:)` — row or featured card tapped. `.sutra` → SutraDetail, `.talk` → Talk. `.meditation` TODO.
- `openQuickAccess(kind)` — one of the 4 quick-access tiles (or the "Kinh sách" view-all link, which
  reuses `.sutras`) tapped. `.buddhas` → `ILDeitiesCoordinator`, `.meditation` → `ILMeditationHubCoordinator`.
  `.sutras` / `.talk` still TODO — no coordinator exists yet for those two lists.
- `openDeity(id:)` — a card in the "Chư Phật & Bồ Tát" carousel tapped. Wired to `ILDeityCoordinator`.
- `openDeities` — "Xem tất cả" on the "Chư Phật & Bồ Tát" carousel tapped. TODO (same gap as Home's
  "Thư viện Phật & Bồ Tát" view-all).

## Known gaps / not implemented yet

- Catalog is mock data — real API blocked on contract (spec ⚠️).
- The 4 quick-access tiles and both "view all" links have no destination screens yet.
- `.loading` renders `ILSkeletonLoadingView` over the content area, but the ViewModel never emits
  `.loading` yet (catalog is synchronous mock data until the Phase 3 async load). Error / offline
  states still not rendered (`.failure` is a TODO branch).
- Lamp / Sangha / Me tabs ignored until those screens exist.

## Changelog

- 2026-09-20 — initial implementation from spec v1.0 (il-spec-writer + il-screen-builder)
- 2026-09-27 — `.loading` now shows the shared `ILSkeletonLoadingView` (il-screen-builder)
- 2026-09-28 — reworked to match the design handoff prototype (`isLib`): category chips replaced by
  a 2×2 quick-access tile grid; added the "Chư Phật & Bồ Tát" carousel (shared with Home); the sutra
  list section gained a "Kinh sách" view-all link; `openDeity` wired to `ILDeityCoordinator`.
- 2026-10-03 — `openQuickAccess(.sutras)` wired to the new Sutras list screen (`ILSutrasCoordinator`)
