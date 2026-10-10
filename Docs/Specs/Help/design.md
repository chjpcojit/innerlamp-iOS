# Design — Help

Version: 2.0
Last updated: 2026-10-10
Status: not started — prospective; FAQ content is bundled mock, backend contract unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Help follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** owned by `ILSettingsCoordinator`, reached via
`ILSettingsNavEvent.openHelp`. FAQ items come from an `ILHelpRepository`; the
current implementation returns bundled localized strings so the real API can
replace it without touching the UseCase or UI. Shape reference: the Language
feature (a leaf screen pushed from Settings).

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILHelpFAQItemEntity.swift` | Pure business fields: `id`, `question`, `answer`. |
| Domain / Repository | `Domain/Repositories/ILHelpRepository.swift` | `listFAQ() async throws -> [ILHelpFAQItemEntity]`. |
| Domain / UseCase | `Domain/UseCases/Help/ILHelpUseCase.swift` | `loadFAQ()` → delegates to the repository; maps failures to `ILHelpError`. |
| Data / Repository | `Data/Repositories/ILHelpRepositoryImpl.swift` | Bundled mock: 5 items from localization keys `help.faq.<n>.question` / `.answer`. Replaced by `NetworkService` once the contract exists. |
| Presentation / State | `Presentation/Scenes/Help/ILHelpStateModel.swift` | UI-only state: items, `expandedIndex`, loading/error flags. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Help/ILHelpViewModel.swift` | `Input -> Output`; accordion toggle (one open at a time); owns `ILHelpNavEvent` (`openSearch`, `openContact`, `goBack`). |
| Presentation / Coordinator | `Presentation/Scenes/Help/ILHelpCoordinator.swift` | Pushes `ILHelpViewController`; `.goBack` → pop + finish; `.openContact` → forwards to parent via delegate; `.openSearch` → TODO. |
| Presentation / ViewController | `Presentation/Scenes/Help/ILHelpViewController.swift` | Search field, accordion cards, footer card; `setupViews`/`setupConstraints`/`bindViewModel`. |
| Feature-scoped views | `Presentation/Scenes/Help/Views/ILHelpFAQCardView.swift`, `ILHelpFooterCardView.swift` | One accordion card; footer "Vẫn chưa rõ?" card. |

Reuse from the Design System: `ILNavBar`/base nav, `ILButton`, `ILState` (error/empty), tokens only.

## Navigation flow

```
ILSettingsCoordinator
  └─ (.openHelp) → showHelp() → ILHelpCoordinator
       push ILHelpViewController
       (tap search)  → openSearch  → TODO (Search not built)
       (tap footer)  → openContact → delegate → ILSettingsCoordinator.showContactSupport()
       (tap back)    → pop + finish()
```

> ⚠️ Not confirmed: when Contact Support was opened from Help and its "Câu hỏi
> thường gặp" shortcut is tapped, pop back to the existing Help instead of
> pushing a second Help — assumed (stack hygiene); see ContactSupport design.

## Data flow

Single load, no multi-call sequence → Step-by-step Flow not required:

1. `viewDidLoad` → `ILHelpViewModel` → `ILHelpUseCase.loadFAQ()` →
   `ILHelpRepository.listFAQ()` → map to `ILHelpStateModel` → render collapsed.
2. Tap card → ViewModel updates `expandedIndex` (same index → `nil`) → incremental
   update of the two affected cards only (no full rebuild).
3. Failure → `.failure` state with retry; retry re-runs step 1.

## Deliberately stubbed for now

`ILHelpRepositoryImpl.listFAQ()` returns bundled mock text, not a backend call.
Tracked in `tasks.md` Phase 3 and `Docs/Assumptions/Help/` / `Docs/Tech-Debt/Help/`
entries created during the build.

## Design reference

Prototype `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html`, screen
`faq`; `docs/Mo-ta-tinh-nang.md` §"Trợ giúp".
