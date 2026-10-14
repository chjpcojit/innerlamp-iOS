# MeritBook

<!--
Living status doc — update (don't recreate) whenever this screen's files change.
-->

## Overview

"Sổ công đức" (prototype screen `merit`): a pushed child of the "Tôi" tab, opened from the Profile
"Công đức đã hồi hướng" card. Sticky header (`ILStickyHeaderBand` + `ILNavBar`: back, title,
subtitle, "Cúng dường" pill) over five blocks: statistics, offering history, temple letter,
monthly support (with "Dừng") and the temple's financial disclosure. Specs: `Docs/Specs/MeritBook/`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILMeritBookEntity.swift` | Done | Offering, purpose, letter, monthly support, build project. |
| Domain — Repository | `ILMeritBookRepository.swift` | Done | `fetchMeritBook`, `stopMonthlySupport` (async throws). |
| Domain — UseCase | `ILMeritBookUseCase.swift` | Done | Thin delegate. |
| Data — Repository | `ILMeritBookRepositoryImpl.swift` | Sample data | In-memory; no API contract (TD-MeritBook-001). |
| Presentation — StateModel | `ILMeritBookStateModel.swift` | Done | Formatted strings only. |
| Presentation — ViewModel | `ILMeritBookViewModel.swift` | Done | 4 Inputs; money/compact formatting; stats by injected calendar. |
| Presentation — ViewController | `ILMeritBookViewController.swift` | Done | Visual QA on device pending. |
| Presentation — Coordinator | `ILMeritBookCoordinator.swift` | Partial | `goBack` done; `openDonate` TODO (TD-MeritBook-002). |
| Tests | `ILMeritBookViewModelTests.swift`, `ILMeritBookUseCaseTests.swift` | Written, not run | build-for-testing blocked by GRPCProtobufGenerator. |

## Navigation events

- `goBack` — pops and finishes.
- `openDonate` — header "Cúng dường". TODO (donation flow not built).

## Known gaps / not implemented yet

- All data is sample data; stopping monthly support only lasts for the session.
- No confirmation dialog for "Dừng"; failure shows the full-screen error state.
- Empty/absent block behavior is assumed (AS-MeritBook-003).
