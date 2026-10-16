---
type: Feature
title: Library
description: Content-browsing tab — a search bar, four category chips, a featured dark card, and a list of sutras/meditations/dharma talks, all from a mock catalog, with an in-memory category filter.
resource: InnerLamp/Presentation/Scenes/Library/
tags: [library, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Library/requirements.md
    kind: spec
  - path: Docs/Specs/Library/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/Library/ILLibraryCoordinator.swift
    kind: code
  - path: InnerLamp/Domain/UseCases/Library/ILLibraryUseCase.swift
    kind: code
  - path: InnerLamp/Domain/Entities/ILLibraryEntity.swift
    kind: code
---

# Summary

Library ("Thư viện") is one of the four post-auth tabs, reached via the
`ILMainTabBarController`. It shows a pinned title, a search bar (a tap target,
not an editable field), four category chips (Tất cả / Kinh văn / Thiền dẫn / Pháp
thoại), a featured dark card, and a list of content rows with tone-coloured book
glyphs and formatted durations. The in-memory category filter is real; the
catalog it filters is **mock data**.

**Current limitation**: the catalog is a static mock (`// TODO:` to swap in a
Repository) and search/item taps end in coordinator TODOs (destinations not
built) — see [Pending work](#pending-work).

> Note (spec drift): `Docs/Specs/Library/design.md` v1.1 describes Library as a
> root screen "owned by AppCoordinator" with `showLibrary()`/`showHome()`
> cross-section navigation. The shipped code instead owns Library via
> `ILMainTabCoordinator` (a tab), and Home ⇄ Library switching is done by the
> tab bar, not `AppCoordinator`. This concept documents the code.

# Architecture

MVVM-C + Clean Architecture. `ILLibraryCoordinator` is owned by
`ILMainTabCoordinator` (its own `BaseNavigationController`); `start()` calls
`setViewControllers([ILLibraryViewController])` to make it that tab's root.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILLibraryEntity.swift` — `ILLibraryEntity` (featured + items), `ILLibraryItemEntity`, `ILLibraryFeaturedEntity`, `ILLibraryContentKind` (sutra / meditation / talk), `ILLibraryTone`, `ILLibraryCategory` |
| Domain / UseCase | UseCase | `Domain/UseCases/Library/ILLibraryUseCase.swift` — `getCatalog()` (mock), `items(in:category:)` (real in-memory filter) |
| Presentation / State | State Model | `Presentation/Scenes/Library/ILLibraryStateModel.swift` — chips, featured, section title, formatted rows, `isListEmpty` |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Library/ILLibraryViewModel.swift` — `Input -> Output`; Entity → StateModel mapping (duration/section-title/chip); owns `ILLibraryNavEvent` |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Library/ILLibraryCoordinator.swift` — `setViewControllers`; `openItem(.sutra)` → `showSutraDetail(id)`; search / meditation / talk → TODO |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Library/ILLibraryViewController.swift` |
| Feature-scoped views | View | `Presentation/Scenes/Library/Views/ILLibraryCategoryChipsView.swift`, `ILLibraryListView.swift` |
| Shared views | View | `Presentation/Common/DesignSystem/Components/ILSearchBarView.swift`, `ILFeatureCardView.swift` |
| Tests | Unit tests | `InnerLampTests/ILLibraryViewModelTests.swift` |

No DTO / Mapper / Repository exists — no confirmed catalog contract.

# Navigation

```
ILMainTabCoordinator (tab "Thư viện")
  └─ ILLibraryCoordinator (root of the Library tab's nav)
       openItem(.sutra)        → showSutraDetail(id)   (push ILSutraDetailCoordinator)
       openItem(.meditation/.talk) → TODO (destinations not built)
       openSearch              → TODO (Search screen not built)
```

Tab switching (Home ⇄ Library) is handled by `ILMainTabBarController`, not by a
coordinator delegate.

# Behavior rules

- Category filter: selecting a chip marks it selected, deselects the previous,
  and shows only matching rows ("Tất cả" = everything); an empty category shows
  the shared empty state; the featured card is unchanged by filtering.
- Duration formatting: `<60min` → "`<n>` phút"; `≥60min` → "`<h>`g `<m>`p"
  (minutes omitted when 0).
- The search bar emits a `.openSearch` event (it is a tap target, not an input).

# Pending work

- Real catalog data. `ILLibraryUseCaseImpl.getCatalog()` returns a static mock
  catalog with a `// TODO:` to swap in a Repository.
  > ⚠️ Not confirmed: the catalog endpoint(s) and response shape (pagination?
  > categories? featured?) — blocks the DTO / Mapper / Endpoint / Repository.
- Row/featured/search taps: `openItem(.sutra)` now opens SutraDetail, but
  `.meditation` / `.talk` / `.openSearch` are TODOs (destinations not built).
  > ⚠️ Not confirmed: which screen each item kind opens (sutra → Detail,
  > meditation → Setup/Session, talk → Talk).
- Section-title copy per category is unconfirmed (the prototype only shows
  "Kinh thường tụng").
- Lamp / Sangha / Me tab destinations — blocked by other specs.
- Promote to `stable` once the catalog API lands and the flow is exercised
  end-to-end.

# Related concepts

- [Main](main.md) (`InnerLamp/Presentation/Scenes/Main/`) — owns this tab via
  `ILMainTabCoordinator`.
- [Home](home.md) (`InnerLamp/Presentation/Scenes/Home/`) — sibling tab; the two
  share the mock-backed `UseCase` + Entity→StateModel shape.
- SutraDetail (`InnerLamp/Presentation/Scenes/SutraDetail/`) — the one wired
  destination for a `.sutra` row; no OKF concept yet. Its behaviour is specified in
  `Docs/Specs/Sutra/` (v1.0; the former `Sutras`, `SutraDetail` and `Reader` specs were merged into it
  and deleted on 2026-10-16). The sample sutra ids in this tab's mock catalog (e.g. `sutra.phapcu`)
  are not server ids and open the not-found state there until the Library spec lands.
