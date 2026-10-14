# Design — MeritBook

Version: 1.0
Last updated: 2026-10-11
Status: in-progress — built against in-memory sample data

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. The screen is a pushed child of the "Tôi" tab, owned by
`ILMeritBookCoordinator`, created from `ILProfileCoordinator` on `.openMeritBook`.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILMeritBookEntity.swift` | `ILMeritBookEntity`, `ILMeritOfferingEntity`, `ILMeritPurpose`, `ILMeritLetterEntity`, `ILMeritMonthlySupportEntity`, `ILMeritBuildProjectEntity`. Foundation only. |
| Domain / Repository | `Domain/Repositories/ILMeritBookRepository.swift` | `fetchMeritBook() async throws`, `stopMonthlySupport() async throws`. |
| Domain / UseCase | `Domain/UseCases/MeritBook/ILMeritBookUseCase.swift` | Thin delegate to the repository. |
| Data / Repository | `Data/Repositories/ILMeritBookRepositoryImpl.swift` | **Sample data** (localized `meritBook.mock.*`), in-memory monthly-support state. Replace with API + DTO/Mapper when a contract exists. |
| Presentation / State | `Presentation/Scenes/MeritBook/ILMeritBookStateModel.swift` | Formatted strings only (stats, history rows, letter, monthly, build project). `Equatable`. |
| Presentation / ViewModel | `…/ILMeritBookViewModel.swift` | `Input -> Output`; `ILMeritBookNavEvent` (`goBack`, `openDonate`); entity → state mapping; `money`, `compactAmount`. |
| Presentation / Coordinator | `…/ILMeritBookCoordinator.swift` | Push; `goBack` pop + finish; `openDonate` TODO. |
| Presentation / ViewController | `…/ILMeritBookViewController.swift` | Sticky header + scroll stack; error state. |
| Presentation / Views | `…/Views/ILMerit*View.swift` | `ILMeritCardView` base, stats, history, letter, monthly (+ dashed note), build cards. |
| Design System | `ILIcons.rowCalendar` + `Icons/row_calendar.imageset` | New calendar glyph for the monthly card. |
| DI | `DIContainer.makeMeritBook*` | `meritBookRepository` is a shared `lazy var` so a stop persists for the session. |

## Navigation flow

```
ILProfileCoordinator
  └─ .openMeritBook (merit card) → showMeritBook() → ILMeritBookCoordinator
       push ILMeritBookViewController
       back → pop + finish
       "Cúng dường" → .openDonate → TODO
```

## Step-by-step Flow — Stop monthly support

```
Step 1 — Stop (this feature)
- Trigger: user taps "Dừng"
- Pre-condition: monthly support is active
- API: ⚠️ Not confirmed — currently in-memory only
    - Success → monthly becomes nil, dashed note shown
    - Failure → state .failure (error state)
```

## Design decisions

- Statistics use the injected `Calendar`/`now` so they are testable.
- Money and dates are formatted locale-independently (`.` grouping, `dd/MM/yyyy`).
- Letter and build blocks hide when absent; monthly shows the "off" note (as in the prototype).
