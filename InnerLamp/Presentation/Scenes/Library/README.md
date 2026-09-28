# Library

## Overview

Library tab ("Thư viện"): pinned title, tap-only search bar, category chips (All / Sutras /
Guided meditation / Dharma talks), a featured dark card and a filtered list of content rows.
Tab 2 of `ILMainTabBarController` (owned by `ILMainTabCoordinator`; switching tabs is handled by the tab bar, not by this screen). Previously: root screen owned by `AppCoordinator` (Home tab returned to
`ILHomeCoordinator`). Spec: `Docs/Specs/Library/`. Design: prototype screen `lib`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILLibraryEntity.swift` | Done | Catalog, item, featured, kind/tone/category. Pure business fields. |
| Presentation — StateModel | `ILLibraryStateModel.swift` | Done | Chips, featured, section title, rows (formatted duration), empty copy. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Catalog endpoint not confirmed, see spec Phase 3. |
| Domain — UseCase | `ILLibraryUseCase.swift` | Partial | `items(in:category:)` real; `getCatalog()` returns a static mock (TODO: repository). |
| Presentation — ViewModel | `ILLibraryViewModel.swift` | Done | 6 Inputs, Entity → StateModel mapping, duration formatting. |
| Presentation — ViewController | `ILLibraryViewController.swift` | Done | Built from `ILSearchBarView`, `ILFeatureCardView` (shared) + `Views/`. Visual QA pending. |
| Presentation — Coordinator | `ILLibraryCoordinator.swift` | Partial | `openSearch` / `openItem` are TODO (screens not built). |
| Tests | `ILLibraryViewModelTests.swift` | Done | ViewModel per-Input tests + UseCase filter tests. |
| Wiring | `DIContainer` + `AppCoordinator` | Done | `ILMainTabCoordinator` creates it on the Library tab's own nav; no delegate / `goHome` any more. |

## Navigation events

- `openSearch` — search bar tapped. TODO in coordinator (Search screen not built).
- `openItem(id:kind:)` — row or featured card tapped. TODO in coordinator (Detail / Talk not built).

## Known gaps / not implemented yet

- Catalog is mock data — real API blocked on contract (spec ⚠️).
- Per-category section titles are assumed copy (prototype only designs the default state).
- `.loading` renders `ILSkeletonLoadingView` over the content area, but the ViewModel never emits
  `.loading` yet (catalog is synchronous mock data until the Phase 3 async load). Error / offline
  states still not rendered (`.failure` is a TODO branch).
- Lamp / Sangha / Me tabs ignored until those screens exist.

## Changelog

- 2026-09-20 — initial implementation from spec v1.0 (il-spec-writer + il-screen-builder)
- 2026-09-27 — `.loading` now shows the shared `ILSkeletonLoadingView` (il-screen-builder)
