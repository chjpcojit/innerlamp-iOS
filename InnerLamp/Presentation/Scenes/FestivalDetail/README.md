# FestivalDetail

## Overview

"Chi tiết ngày lễ" — detail of one Buddhist festival day (prototype screen `festDetail`). Pushed
by `ILHomeCoordinator` (tap an event in the "Sự kiện Phật giáo" carousel) and by
`ILFestivalsCoordinator` (tap a named festival day). Spec: `Docs/Specs/Calendar/`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILFestivalDetailEntity.swift` | Done | Event + occurrence merged. |
| Domain — UseCase | `ILFestivalDetailUseCase.swift` | Done | Reuses `ILCalendarEventRepository` (`GET /v1/calendar/events?year=`). |
| Presentation — StateModel | `ILFestivalDetailStateModel.swift` | Done | Every section has an `…EmptyText`. |
| Presentation — ViewModel | `ILFestivalDetailViewModel.swift` | Done | loading → success/failure, retry. |
| Presentation — ViewController | `ILFestivalDetailViewController.swift` | Done | Visual QA on device pending. |
| Presentation — Views | `Views/ILFestivalDetailHeroView.swift`, `Views/ILFestivalDetailKindRowView.swift`, `Views/ILFestivalDetailAboutView.swift`, `Views/ILFestivalDetailErrorView.swift`, `Views/ILFestivalDetailDateCardView.swift`, `Views/ILFestivalDetailListCardView.swift` | Done | |
| Presentation — Coordinator | `ILFestivalDetailCoordinator.swift` | Done | `.back` pop + finish. |
| Tests | `ILFestivalDetailViewModelTests.swift`, `ILFestivalDetailUseCaseTests.swift` | Written | Not runnable here (GRPCProtobufGenerator blocks the test target). |
| Wiring | `DIContainer` + Home/Festivals coordinators | Done | |

## Navigation events

- `.back` — pop and `finish()`.

## Known gaps

- Empty kind / about / practices sections are hidden (BR-CAL-14); "Kinh nên tụng" and "Chùa tổ chức" were removed. The hero still shows placeholder text when the event has no image.
- "Nhắc tôi ngày này" is not built — out of scope for Calendar v1.0, later via ADR-0001 (`Docs/Specs/Calendar/tasks.md` "Deferred").
- No alternative title line; the kind label shows group names, the major mark is pending (BR-CAL-10; `Docs/Specs/Calendar/tasks.md` Phase 4 and 6).

## Changelog

- 2026-10-11 — initial implementation from prototype `festDetail`.
- 2026-10-12 — ui-builder compliance refactor (no behavior change): every subview is a `private lazy var`; hero / kind row / about / error blocks split into `Views/`; inline spacing literals replaced by `ILMetrics` tokens (`spaceTiny`, `spaceCompact`, `hairline`).
- 2026-10-15 — spec moved to `Docs/Specs/Calendar/` (the old `Docs/Specs/FestivalDetail/`, AS-FestivalDetail-001/002 and TD-FestivalDetail-001/002 were deleted); no code change.
