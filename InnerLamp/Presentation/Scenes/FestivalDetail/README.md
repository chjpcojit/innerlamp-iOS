# FestivalDetail

## Overview

"Chi tiết ngày lễ" — detail of one Buddhist festival day (prototype screen `festDetail`). Pushed
by `ILHomeCoordinator` (tap an event in the "Sự kiện Phật giáo" carousel) and by
`ILFestivalsCoordinator` (tap a named festival day). Spec: `Docs/Specs/FestivalDetail/`.

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

- "Kinh nên tụng" and "Chùa tổ chức" always show "no data" text (TD-FestivalDetail-001).
- "Nhắc tôi ngày này" is not built (TD-FestivalDetail-002).
- No alternative title line; the kind label shows group names (AS-FestivalDetail-002).

## Changelog

- 2026-10-11 — initial implementation from prototype `festDetail`.
- 2026-10-12 — ui-builder compliance refactor (no behavior change): every subview is a `private lazy var`; hero / kind row / about / error blocks split into `Views/`; inline spacing literals replaced by `ILMetrics` tokens (`spaceTiny`, `spaceCompact`, `hairline`).
