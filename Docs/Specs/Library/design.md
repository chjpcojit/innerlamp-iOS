# Design — Library

Version: 2.0
Last updated: 2026-09-27
Status: in-progress — UI + local filtering implemented against a mock catalog;
owned by `ILMainTabCoordinator` (tab 2)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Library ("Thư viện") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
**tab 2** of `ILMainTabBarController`, so `ILLibraryCoordinator` is owned by
`ILMainTabCoordinator` (which gives it its own `BaseNavigationController`). It
follows the `Home`/`Sangha` shape (mock-backed `UseCase` with a `TODO`, Entity →
StateModel mapping in the ViewModel, `Views/` folder). Nothing on this screen
needs a network call yet, so no DTO / Mapper / Repository exists.

> Note (vs v1.x): v1.x documented Library as an `AppCoordinator`-owned root
> screen with an embedded `ILBottomNavBar` and a `goHome` delegate. That shape
> was superseded — Library is now a tab; the delegate, `goHome`, the embedded
> bottom bar, and the Home "library tab" entry are all gone.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLibraryEntity.swift` | `ILLibraryEntity` (featured + items), `ILLibraryItemEntity`, `ILLibraryFeaturedEntity`, `ILLibraryContentKind` (sutra / meditation / talk), `ILLibraryTone`, `ILLibraryCategory` (all / kind, with `kind` mapping). Pure business fields. |
| Domain / UseCase | `Domain/UseCases/Library/ILLibraryUseCase.swift` | `getCatalog()` returns the (mock) catalog; `items(in:category:)` is the real, pure in-memory category filter. |
| Presentation / State | `Presentation/Scenes/Library/ILLibraryStateModel.swift` | Chips, featured card model, section title, row models (formatted duration, tone), empty copy, `isListEmpty`. No UIKit. |
| Presentation / ViewModel | `Presentation/Scenes/Library/ILLibraryViewModel.swift` | `Input -> Output` per `ViewModelType`; Entity → StateModel mapping (duration formatting, section title, chip selection); owns `ILLibraryNavEvent` (`.openSearch`, `.openItem(id:kind:)`). |
| Presentation / Coordinator | `Presentation/Scenes/Library/ILLibraryCoordinator.swift` | `setViewControllers([ILLibraryViewController])`; `.openItem` with `kind == .sutra` → `showSutraDetail(id)` (wired); `.openSearch` and `.openItem` for `.meditation`/`.talk` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Library/ILLibraryViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; pinned title, scroll content. |
| Shared component | `Presentation/Common/DesignSystem/Components/ILSearchBarView.swift` | Tap-only search field (icon + placeholder), reusable by future Search entry points. |
| Shared component | `Presentation/Common/DesignSystem/Components/ILFeatureCardView.swift` | Dark gradient card: caps eyebrow, serif title, gold pill CTA, glow. |
| Feature-scoped view | `Presentation/Scenes/Library/Views/ILLibraryCategoryChipsView.swift` | Composes four `ILChip`s; emits selected category. |
| Feature-scoped view | `Presentation/Scenes/Library/Views/ILLibraryListView.swift` | Section header + stack of `ILRow`s, or empty state; emits tapped item id. |
| Localization | `Resources/Localization/vi.json` | `library.*` keys (title, search placeholder, chips, section titles, CTA, empty copy, mock catalog copy). |
| Wiring | `App/DIContainer.swift`, `ILMainTabCoordinator` | `makeLibraryUseCase/ViewModel/Coordinator`; `ILMainTabCoordinator` creates it on the Library tab's own nav. |

## Navigation flow

```
ILMainTabCoordinator (tab "Thư viện")
  └─ ILLibraryCoordinator                         (owned by Main, not AppCoordinator)
       setViewControllers([ILLibraryViewController])  ← root of the Library tab's nav
       search bar   → .openSearch              → TODO (Search screen not built)
       row (sutra)  → .openItem(id:.sutra)     → showSutraDetail(id) (wired)
       row (meditation/talk) → .openItem       → TODO (Meditation/Talk not built)
       featured     → .openItem(id:.talk)      → TODO (Talk not built)
```

## Data flow (single, local — no sequential API calls)

1. `viewDidLoad` → ViewModel asks `useCase.getCatalog()` (mock) → maps to
   `ILLibraryStateModel` with category `.all`.
2. `categorySelected(c)` → ViewModel calls `useCase.items(in: category:)` →
   rebuilds chips / section title / rows. Featured is untouched.
3. Taps produce `ILLibraryNavEvent`s only; ViewModel holds no navigation logic.

No Step-by-step Flow section: the screen makes zero API calls today. When Phase
3 lands with a single `GET` catalog call this stays a one-call flow; if the
contract turns out to need a second call (e.g. featured separate from list) add
the section then.

## Deliberately stubbed for now

- `ILLibraryUseCaseImpl.getCatalog()` returns a static mock catalog (4 sutras,
  2 meditations, 2 talks, 1 featured) with a `// TODO:` to swap in the
  Repository once the catalog contract is confirmed — tracked in `tasks.md`
  Phase 3.
- `ILLibraryCoordinator` search event and `.openItem` for `.meditation` /
  `.talk` are `TODO` (destination screens not built). Only `.sutra` →
  SutraDetail is wired.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `lib` (`isLib`). See `InnerLamp/Presentation/Scenes/Library/README.md`
for the full design-vs-implementation comparison and changelog.
