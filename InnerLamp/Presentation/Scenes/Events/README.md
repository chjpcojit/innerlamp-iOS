# Events

## Overview

"Sự kiện & khóa học": reached from the Sangha tab's "Sự kiện & khóa học" chip, pushed by
`ILSanghaCoordinator`. Shows a 3-tab selector (Sắp diễn ra / Khóa học / Đã ghi danh), a dark
featured "Sắp diễn ra" hero card with a "Ghi danh" CTA, and a list of events per tab. Design:
prototype screen `events` (`Docs/design_handoff_innerlamp/`). No spec under `Docs/Specs/Events/` yet.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILEventsEntity.swift` | Done | Featured + 3 tab arrays; `ILEventsTone`, `ILEventsStatus` (open/closing/upcoming/registered). Pure business fields. |
| Presentation — StateModel | `ILEventsStateModel.swift` | Done | `ILEventsFeaturedModel` / `ILEventsListItemModel` display-ready; `ILEventsTab`. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | No events endpoint confirmed. |
| Domain — UseCase | `ILEventsUseCase.swift` | Skeleton | `getEvents()` returns static mock (TODO: repository → network). |
| Presentation — ViewModel | `ILEventsViewModel.swift` | Done | 4 Inputs, Entity → StateModel mapping, status/tab-section label formatting. |
| Presentation — ViewController | `ILEventsViewController.swift` | Done | `ILNavBar` + sticky header, `ILChip` tabs, `ILSectionHeaderView`, `Views/ILEventsHeroCardView` + `Views/ILEventsListItemView`. Visual QA pending. |
| Presentation — Coordinator | `ILEventsCoordinator.swift` | Partial | `.goBack` wired (pop + finish); `.openRegister` is TODO (`register` not built). |
| Tests | `ILEventsViewModelTests.swift` | Done | Initial + viewDidLoad + tab switching + status mapping + nav events. |
| Wiring | `DIContainer` + `ILSanghaCoordinator` | Done | Wired to Sangha's `openEvents` nav event. |

## Navigation events

- `goBack` — back button tapped; coordinator pops and `finish()`es.
- `openRegister(eventId:)` — "Ghi danh" (hero CTA) or an event row tapped. TODO (`register` not built).

## Known gaps / not implemented yet

- All data is mock (`ILEventsUseCaseImpl.getEvents()`) — events/courses/registrations need API contracts.
- "Ghi danh" only fires `openRegister(eventId:)`; the Register screen (`register`) is not built yet.
- The featured hero is always shown regardless of tab (matches the prototype); no per-tab hero.
- Loading / error / offline states not rendered (data is local mock, so `.failure` only shows a generic alert).

## Changelog

- 2026-09-25 — initial implementation from design handoff prototype screen `events` (il-screen-builder). Added `ILTypography.dateTileDay`.
