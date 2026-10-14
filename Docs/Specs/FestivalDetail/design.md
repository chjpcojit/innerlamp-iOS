# Design — FestivalDetail

Version: 1.0
Last updated: 2026-10-11
Status: implemented (app builds)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture. A **leaf screen** pushed by `ILHomeCoordinator` and
`ILFestivalsCoordinator`, each through `DIContainer.makeFestivalDetailCoordinator(...)`. No new
endpoint: it reuses the calendar-events data layer (`ILCalendarEventRepository`).

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILFestivalDetailEntity.swift` | One occurrence merged with its event: code, name, short/long description, guidance, image URL, group names, solar date, lunar day/month/leap, `daysUntil`. |
| Domain / UseCase | `Domain/UseCases/FestivalDetail/ILFestivalDetailUseCase.swift` | `loadDetail(code:date:today:)` — loads the year of `date`, finds the event + the occurrence on that day, resolves group names; `ILCatalogError.notFound` when absent. |
| Presentation / State | `.../FestivalDetail/ILFestivalDetailStateModel.swift` | Display-ready strings and lists, plus `…EmptyText` for every section. |
| Presentation / ViewModel | `.../ILFestivalDetailViewModel.swift` | Input `viewDidLoad`/`retryTapped`/`backTapped`; `.loading → .success/.failure`; entity → state mapping (line split, list-marker strip, countdown, weekday). |
| Presentation / ViewController | `.../ILFestivalDetailViewController.swift` | `ILStickyHeaderBand` + `ILNavBar`; hero (`ILRemoteImageView`); sections; loading/error states. |
| Presentation / Views | `.../Views/ILFestivalDetailDateCardView.swift`, `ILFestivalDetailListCardView.swift` | Solar date card + countdown pill; numbered list card that shows empty text when no items. |
| Presentation / Coordinator | `.../ILFestivalDetailCoordinator.swift` | Pushes the screen; `.back` → pop + `finish()`. |
| Modified | `ILFestivalDayEntity.eventCode`, `ILHomeEventItemEntity.eventCode` | Carry the server event code to the tap handlers. |
| Modified | `ILFestivalsViewModel` / `ILFestivalsViewController` / `ILFestivalsItemView` / `ILFestivalsCoordinator` | `dayTapped` input, `.openFestivalDetail`, tappable festival cards (observance cards stay inert). |
| Modified | `ILHomeViewModel` / `ILHomeViewController` / `ILHomeCoordinator` | `eventTapped` input, `.openFestivalDetail(code:date:)`. Events "Tất cả" / "+N" still open the list. |
| Localization | `Resources/Localization/vi.json` | `festivalDetail.*` keys. |

## Step-by-step Flow

1. Trigger: tap an event (Home) or a festival card (Festivals). Pre-condition: the item has a
   server `eventCode`. Output: nav event with `(code, solar date)`.
2. Trigger: `viewDidLoad`. API: `GET /v1/calendar/events?year=` (contract: `Docs/Specs/Home/design.md`
   → "API contract"). Success: event + occurrence found → render. Failure: `ILCatalogError`
   (`notFound` / `offline` / `loadFailed`) → error state + retry.

## Notes

- The year is the Gregorian year of the tapped date, so a late-December event whose lunar year
  differs is still requested with the right solar year.
- The calendar-events response is not cached (TD-Home-003): reopening a detail calls the server.
