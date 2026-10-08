# Design — TempleFinder

Version: 1.0
Last updated: 2026-10-05
Status: in-progress — UI + local logic done; proposal is UI only

> See `changelog.md` in this folder for the version history of this spec.

## Overview

"Chọn chùa tu tập" follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **leaf screen**:
`ILTempleFinderCoordinator` has no delegate and is pushed from `ILSanghaCoordinator` on `.openTempleFinder`.
`.back` and `.picked` pop + `finish()`; `.openTemple(id)` starts an `ILTempleCoordinator` as a child.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / UseCase | `Domain/UseCases/TempleFinder/ILTempleFinderUseCase.swift` | `loadTemples()` — all catalog pages, id-deduplicated; `loadMyTemple()`; `selectMyTemple(_:)` (delegates to `ILSanghaUseCase`). |
| Presentation / State | `ILTempleFinderStateModel.swift` | Row, region chip, add-form and screen state models. No UIKit import. |
| Presentation / ViewModel | `ILTempleFinderViewModel.swift` | `Input -> Output`; client-side search + region filter (`normalize`: case/diacritic-insensitive, `đ → d`); proposal validation; `ILTempleFinderNavEvent` (`.back`, `.openTemple`, `.picked`). |
| Presentation / Coordinator | `ILTempleFinderCoordinator.swift` | Leaf; see Overview. |
| Presentation / ViewController | `ILTempleFinderViewController.swift` | Sticky header + `UITableView` (items: sent banner, empty text, temple rows, add row) + in-place form + loading / error states. |
| Feature-scoped views | `Views/ILTempleFinderCells.swift`, `Views/ILTempleFinderAddFormView.swift` | Card-style cells (adjacent cells form one rounded card) and the proposal form (`ILField` ×4, `ILButton` ×2). |

Reuses: `ILTempleRepository.loadTemples(page:)` (local-first cache), `ILSanghaUseCase`,
`ILSanghaPillButton`, DesignSystem `ILNavBar` / `ILSearchInputView` / `ILChip` / `ILField` / `ILButton` /
`ILInlineBannerView` / `ILStateView` / `ILLoadingDotsView`.

## Navigation flow

Chùa tab "Đổi chùa" → `ILSanghaViewModel` emits `.openTempleFinder` → `ILSanghaCoordinator.showTempleFinder()`.
After "Chọn" the Chùa tab reloads on `viewWillAppear` (new Input `viewWillAppear`; the first appearance is
skipped because `viewDidLoad` already loaded).

## Step-by-step Flow — directory load

1. Trigger: `viewDidLoad` / "Thử lại". Pre-condition: none. API: `GET /v1/temples?page=N` for N = 1…
   until `hasMore == false` (cap 50 pages) via `ILTempleRepository.loadTemples(page:)`. Success: list built;
   failure: `.failure(ILCatalogError)` → error / offline state with retry.

## Persisting the choice

`ILSanghaUseCase.selectMyTemple(_ temple: ILTempleSummaryEntity)` stores the id (`sangha.myTempleID`) and a
`{id, name, address}` snapshot (`sangha.myTempleSnapshot`) in `UserDefaults`; `loadMyTemple()` falls back to
the snapshot when the id is not one of the Sangha mock temples. The directory has no opening hours / abbot in
list rows, so the practice-temple card hides the status pill and shows "Đang cập nhật" for the abbot
(`Docs/Tech-Debt/Sangha/TD-Sangha-002-*.md`).

## Deliberately stubbed

- Proposal submit: validates, then shows the banner; nothing is sent or stored (TD-TempleFinder-001).
