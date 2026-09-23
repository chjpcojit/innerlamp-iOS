# Design — Library

Version: 1.1
Last updated: 2026-09-20
Status: in-progress — UI + local filtering implemented against a mock catalog; backend catalog API not confirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Library is a **root tab** of the app, so it is reached
across sections (Home ⇄ Library) and is owned by `AppCoordinator` — same as `Home`: its coordinator
replaces the navigation stack root (`setViewControllers`), and each root screen embeds its own
`ILBottomNavBar` (there is no `UITabBarController` yet). It follows the shape of the `Home` feature
(mock-backed `UseCase` with a `TODO`, Entity → StateModel mapping in the ViewModel, `Views/` folder).
Nothing on this screen needs a network call yet, so no DTO / Mapper / Repository exists (see
"Deliberately stubbed for now").

Design reference: `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, screen `lib`
(`isLib`). Tokens: canvas `--il-canvas`, row/search `--il-card`, title Lora 26.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLibraryEntity.swift` | `ILLibraryEntity` (featured + items), `ILLibraryItemEntity`, `ILLibraryFeaturedEntity`, `ILLibraryContentKind` (sutra / meditation / talk), `ILLibraryTone`, `ILLibraryCategory` (all / kind). Pure business fields, no display strings beyond server-provided copy. |
| Domain / UseCase | `Domain/UseCases/Library/ILLibraryUseCase.swift` | `getCatalog()` returns the (mock) catalog; `items(in:category:)` is the real, pure in-memory category filter. |
| Presentation / State | `Presentation/Scenes/Library/ILLibraryStateModel.swift` | Chips (with selected flag), featured card model, section title, row models (formatted duration, tone), `isListEmpty`. No UIKit. |
| Presentation / ViewModel | `Presentation/Scenes/Library/ILLibraryViewModel.swift` | `Input -> Output`; Entity → StateModel mapping (duration formatting, section title, chip selection); owns `ILLibraryNavEvent`. |
| Presentation / Coordinator | `Presentation/Scenes/Library/ILLibraryCoordinator.swift` | Replaces stack root with the Library screen; forwards `goHome` to `AppCoordinator` via `ILLibraryCoordinatorDelegate`; search/item events end in a `TODO` (destinations not built). |
| Presentation / ViewController | `Presentation/Scenes/Library/ILLibraryViewController.swift` | `BaseViewController`; pinned title, scroll content, pinned `ILBottomNavBar(.lib)`; renders `ILLibraryStateModel`. |
| Presentation / View (shared) | `Presentation/Common/DesignSystem/Components/ILSearchBarView.swift` | Tap-only search field (icon + placeholder), reusable by the future Search entry points. Content-free → shared per naming rule §3. |
| Presentation / View (shared) | `Presentation/Common/DesignSystem/Components/ILFeatureCardView.swift` | Dark gradient card: caps eyebrow, serif title, gold pill CTA, glow. Takes only strings → shared. |
| Presentation / View (feature) | `Presentation/Scenes/Library/Views/ILLibraryCategoryChipsView.swift` | Composes four `ILChip`s in an `ILChipFlowView`, emits selected category. Knows `ILLibraryCategory` → feature-scoped. |
| Presentation / View (feature) | `Presentation/Scenes/Library/Views/ILLibraryListView.swift` | Section header + stack of `ILRow`s, or `ILStateView(.empty)`; emits tapped item id. Knows the row model → feature-scoped. |
| Design tokens | `ILTypography.swift` / `ILColors.swift` | Reuse `displayMedium`, `body`, `chip`, `eyebrow`, `button`, `scriptureTitle` (22 Lora); add presets/colours only if none fits. |
| Localization | `Resources/Localization/vi.json` | New `library.*` keys (title, search placeholder, chips, section titles, CTA, mock catalog copy). |
| Wiring | `App/DIContainer.swift`, `App/AppCoordinator.swift` | `makeLibraryUseCase/ViewModel/Coordinator`; `showLibrary()` + `ILLibraryCoordinatorDelegate` conformance. |
| Entry from Home | `ILHomeViewModel` / `ILHomeViewController` / `ILHomeCoordinator` | Needs modification: new Input `libraryTabTapped`, `ILHomeNavEvent.openLibrary`, `ILHomeCoordinatorDelegate.homeDidRequestLibrary`; `ILHomeViewModelTests` updated. |
| Tests | `InnerLampTests/ILLibraryViewModelTests.swift` | One test per Input, mocking `ILLibraryUseCase`; formatting cases. |

### Entity / StateModel / DTO split

- `ILLibraryItemEntity`: `id`, `kind`, `title`, `subtitle`, `durationMinutes`, `tone`
  (`ILLibraryTone` = gold/green/rose/ink, same convention as `ILHomeSessionTone`; mapped to
  `ILColors.Tone` in the ViewController because Domain must not import UIKit).
- `ILLibraryFeaturedEntity`: `id`, `eyebrow`, `title`, `durationMinutes`.
- `ILLibraryStateModel`: `chips`, `featured`, `sectionTitle`, `rows`, `isListEmpty` — everything
  display-shaped (`durationText`, localized titles, selected flag).
- DTO/Mapper: **not created** — no confirmed contract (see Pending in `requirements.md`).

## Navigation flow

```
AppCoordinator
  ├─ showHome() → ILHomeCoordinator (root)
  │     libraryTabTapped → .openLibrary → homeDidRequestLibrary → AppCoordinator.showLibrary()
  └─ showLibrary() → ILLibraryCoordinator (replaces stack root, crossfade)
        home tab       → .goHome        → libraryDidRequestHome → AppCoordinator.showHome()
        search bar     → .openSearch    → TODO (Search screen not built)
        row / featured → .openItem(id:kind:) → TODO (Detail / Talk / Reader not built)
```

On leaving a root screen, its coordinator calls `finish()` after notifying the delegate so
`AppCoordinator.childCoordinators` does not accumulate stale Home/Library coordinators.

## Data flow (single, local — no sequential API calls)

1. `viewDidLoad` → ViewModel asks `useCase.getCatalog()` (mock) → maps to `ILLibraryStateModel`
   with category `.all`.
2. `categorySelected(c)` → ViewModel calls `useCase.items(in: catalog, category: c)` → rebuilds
   chips / section title / rows. Featured is untouched.
3. Taps produce `ILLibraryNavEvent`s only; ViewModel holds no navigation logic.

No Step-by-step Flow section: the screen makes zero API calls today. When Phase 3 lands with a
single `GET` catalog call this stays a one-call flow; if the contract turns out to need a second
call (e.g. featured separate from list) add the section then.

## Deliberately stubbed for now

- `ILLibraryUseCaseImpl.getCatalog()` returns a static mock catalog (4 sutras from the prototype
  plus a few meditation/talk rows so the filters have data). Carries a `// TODO:` to swap in the
  Repository once the catalog contract is confirmed — tracked in `tasks.md` Phase 3. Same
  precedent as `ILHomeUseCaseImpl`.
- `ILLibraryCoordinator` search / item events: `TODO` — destination screens are Deferred.
- Lamp / Sangha / Me tab taps: ignored (`TODO`), as on Home.
