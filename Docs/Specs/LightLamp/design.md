# Design — LightLamp

Version: 1.1
Last updated: 2026-10-11
Status: implemented (build-verified, tests written but not run) — local-only data, no API contract

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. One feature folder, two screens (lighting, garden) owned
by one `ILLightLampCoordinator`, a child of `ILHomeCoordinator` (entry is Home's "Thắp đèn — Vu Lan"
row, so it is not a cross-section flow). Data is **local-only**: a Domain repository protocol with a
Core Data implementation; a remote source can be added later behind the same protocol. Shape
reference: `Memorial` (local Core Data + two screens under one coordinator).

## Sign-out clearing

`Lamp` rows are removed on sign-out by `ILSessionDataCleanerImpl` (Data layer, owned by the Profile
sign-out flow — see `Docs/Specs/Profile/design.md` § Logout flow). The lamp feature itself has no
sign-out code. When a lamp API replaces the local store, keep the entity in that cleaner only if a
local cache remains.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLampEntity.swift` | `ILLampEntity` (id, `ILLampKind` oil/lotus/float, `ILLampIntention` 4 cases, target (empty = all beings), vow, `durationDays`, `litAt`); `daysLeft(now:)` / `isActive(now:)`. No owner name (see `AS-LightLamp-004`). Pure; Foundation only. |
| Domain / Repository protocol | `Domain/Repositories/ILLampRepository.swift` | `loadAll()`, `save(_:)`; `ILLampError` (`loadFailed` / `saveFailed`). Expiry filtering lives in the use case. |
| Domain / UseCase | `Domain/UseCases/LightLamp/ILLightLampUseCase.swift` | `light(_:now:)` (trims target and vow, builds the entity, saves), `loadActiveLamps(now:)` (active lamps, newest first; the count line uses its `count`). Expiry rule lives here. |
| Data / Local | `Data/DataSources/Local/ILLampLocalDataSource.swift` + `ILLampMO.swift` | Core Data entity `ILLampMO` (entity name `Lamp`) in new model version `InnerLamp 5.xcdatamodel`, set current in `.xccurrentversion` (lightweight migration from 4). Maps to/from the Entity. |
| Data / Repository impl | `Data/Repositories/ILLampRepositoryImpl.swift` | Wraps the local data source; errors → `ILLampError`. |
| Presentation / State | `Presentation/Scenes/LightLamp/ILLightLampStateModel.swift` | Phase (`form` / `lighting` / `done`), selected kind/intention/duration, headline/count line, caption, dedication line, vow quote, button label/enabled. No UIKit. |
| Presentation / State | `Presentation/Scenes/LightLamp/ILLampGardenStateModel.swift` | Subtitle, chips (label, selected), card models, `hasMore`, empty flag. No UIKit. |
| Presentation / ViewModel | `ILLightLampViewModel.swift`, `ILLampGardenViewModel.swift` | `Input -> Output`; nav events `ILLightLampNavEvent` (`.back`, `.openGarden`) and `ILLampGardenNavEvent` (`.back`, `.openLighting`). The ~2.1 s ignite delay is an `igniteDelay: Duration` init parameter so tests pass `.zero`. |
| Presentation / Coordinator | `ILLightLampCoordinator.swift` | Lighting (root) is pushed (Home row, `start()`) or presented full-screen in its own `BaseNavigationController` (center tab-bar button, `startModal()`); garden is pushed on that stack; garden → lighting replaces/pops to a fresh lighting form; `finish()` on back. |
| Presentation / ViewController | `ILLightLampViewController.swift`, `ILLampGardenViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel`. |
| Presentation / Views | `Scenes/LightLamp/Views/` | `ILLampArtView` (3 kinds, lit/unlit, halo, ignite animation), `ILLampStageView` (hero stage), `ILLampKindPickerView`, `ILLampCardView` (garden cell + footer). Reuses `ILNavBar`, `ILChip`/`ILChipFlowView`/`ILChipScrollView`, `ILInputCardView`, `ILSegmentedToggleView`, `ILButton`, `ILStateView`. |
| Design system | `Tokens/ILColors`, `ILIcons`, `ILTypography`, `ILMetrics` | Added `ILColors.Lamp` (18 `ILLamp*` color sets) and `ILMetrics.Lamp`; flame reuses `ILIcons.tabLampFlame` / `tabLampCore` tinted with `ILColors.Lamp.flameOuter` / `flameCore`. |
| Home (modification) | `ILHomeViewModel.swift` (`ILHomeNavEvent.openLightLamp`), `ILHomeCoordinator.swift` (`showLightLamp()`) | The `.offering` suggested-session row emits `.openLightLamp` instead of doing nothing. |
| DI | `App/DIContainer.swift` | `makeLightLampUseCase/Repository/ViewModel/Coordinator`, garden ViewModel. |
| Localization | `Resources/Localization/vi.json` | All copy under `lightLamp.*` keys. |
| Tests | `InnerLampTests/ILLightLampViewModelTests.swift`, `ILLampGardenViewModelTests.swift`, `ILLightLampUseCaseTests.swift` | Defaults, selection, target normalization, double-tap guard, save failure, expiry, filter/paging. |

## Navigation flow

```
ILHomeCoordinator
  └─ .openLightLamp → showLightLamp() → ILLightLampCoordinator (child)
       push ILLightLampViewController                       (lighting)
       (header "Vườn đèn" / "Vào vườn đèn") → .openGarden → push ILLampGardenViewController
       (garden header "Thắp đèn")           → .openLighting → fresh lighting form
       (Back)                               → .back → finish() → Home
```

## Data flow

All local, no network, so no Step-by-step Flow is required (single local call per action).

**Light**: tap "Thắp đèn" → ViewModel sets phase `lighting` → `useCase.light(draft)` (saves via
repository) runs together with the ~2.1 s ignite delay → success: phase `done` and caption from the
saved entity; failure: phase back to `form` with values kept and an error alert.

**Garden load**: `viewDidLoad` → `useCase.loadGarden(now:)` → `repository.loadActive` →
filter elapsed, sort newest first → StateModel (counts per kind, first 12, `hasMore`). Fetch and
mapping run off the main actor; only the finished StateModel is applied on main. List views diff and
append only new cards (`AGENTS.md` §4.6).

## Deliberately stubbed for now

- Community lamps: none (own lamps only) until an API exists.
- "Thỉnh đèn tại chùa" and Cúng dường navigation: not built.
- Owner name: not stored; garden cards read "Của bạn · <intention>" (`AS-LightLamp-004`).

## Design reference

Prototype `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html` screens `offer` and `garden`;
artwork `IL-LampArt.dc.html`.
