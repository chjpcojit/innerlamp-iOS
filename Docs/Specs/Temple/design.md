# Design — Temple

Version: 2.0
Last updated: 2026-09-28
Status: in-progress — full detail screen with a static catalog; list scope not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Temple ("Trang chùa") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
a **leaf screen** — `ILTempleCoordinator` has no delegate. It is reached from
two parents, both passing a `templeID`: the Home "Chùa Việt Nam" carousel
(`ILHomeCoordinator.showTemple(id)`) and the Sangha community card
(`ILSanghaCoordinator.showTemple(id)`). There is **no network** — the UseCase
returns a static catalog transcribed from the design handoff's
`Component.TEMPLE_INFO`.

> Scope note: `SRS.md` describes a larger feature (discovery list + detail). Only
> the detail screen is implemented; the list/discovery half is a separate future
> feature.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILTempleEntity.swift` | `ILTempleEntity` — identity & location (name, aliases, lat/lng, street/ward/district/province/region/subRegion), Phật học & tổ chức (sect, `ILTempleOrgInfoEntity[]`), lịch sử & kiến trúc (era, rank?, archStyle, materials, highlights, bio), tiện ích & hỗ trợ (`ILTempleOpeningHoursEntity` ×2, `ILTempleContactEntity[]`, `ILTempleAmenityEntity[]`, visitRules, hasUpcomingSchedule, sessions, updatedLabel). Plus `ILTempleSessionEntity` + tone/glyph enums. No UI-only state, no "now"-derived fields (open/closed, distance). |
| Domain / UseCase | `Domain/UseCases/Temple/ILTempleUseCase.swift` | `getInitialState(templeID:)` (static 9-temple catalog — Từ Quang fully detailed + the 8-temple Home carousel set — fallback to Từ Quang), `toggleFollow(templeID:)` (stub). Catalog content is plain Vietnamese string literals (data, not UI copy — same convention as `ILDeityUseCaseImpl`), except `name`/reused via `home.temple.*` localization keys shared with the Home carousel. |
| Presentation / State | `Presentation/Scenes/Temple/ILTempleStateModel.swift` | UI-only state: hero chip/alias/place strings, button titles, status-card fields (open/closed, note, distance, 2 hour rows), 4 facts, biography + expand state, org/amenity/contact row models (each pre-resolved to a display value + a "has value" flag), architecture strings + highlights, numbered rule rows, session rows, location strings, footer text. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Temple/ILTempleViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILTempleNavEvent` (`.back`, `.offer`, `.events`, `.session(id:)`, `.openURL(String)`); Entity→StateModel mapping incl. **client-side** open/closed + distance (via `ILLunarCalendar.solarToLunar` for the Rằm/Mùng-Một check + a haversine formula against a fixed reference location, matching the design handoff); builds Google Maps / Apple Maps / `tel:` / `https:` / `mailto:` URL strings; local optimistic `isFollowing`/`isBiographyExpanded` state (not persisted); injectable `now: () -> Date` for deterministic tests. |
| Presentation / Coordinator | `Presentation/Scenes/Temple/ILTempleCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop+finish; `.openURL` → `UIApplication.shared.open(_:)`; `.offer`/`.events`/`.session` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Temple/ILTempleViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; header-solid-on-scroll + collapsible-biography pattern ported from `ILDeityViewController`; a shared 2-column grid helper for the facts/amenities tiles; small leaf row/tile views (`ILTempleFactTileView`, `ILTempleAmenityTileView`, `ILTempleKeyValueRow`, `ILTempleHighlightCardView`, `ILTempleRuleRow`) defined `private` in the same file, following the existing in-file-leaf-view convention (`ILHomeTempleCarouselView`'s private card view). |
| Feature-scoped views | `Presentation/Scenes/Temple/Views/ILTempleHeroView.swift`, `Views/ILTempleStatusCardView.swift` | Hero (rank/sect chips, name, alias, place) and the open-status + hours card. `ILTempleStatsView` (the old 3-stat strip) was removed — superseded by the status card + facts grid. |
| Shared tokens | `ILColors.templeHeaderTop/Mid/Ink/Glow/Sub`, `ILColors.featBackgroundStart/featBorder` (rules card), `ILTypography.talkTitle` (hero name), `ILSectionEyebrowView` (all section headers) | Themed hero + section tokens, reused rather than adding new ones. |

## Navigation flow

```
ILHomeCoordinator (carousel)             ILSanghaCoordinator (community card)
  └─ showTemple(id) → ILTempleCoordinator            (leaf, no delegate)
       push ILTempleViewController
       (.back) → pop + finish()
       (.openURL(url)) → UIApplication.shared.open(url)   [Maps/tel/https/mailto]
       (.offer / .events / .session(id:)) → TODO
```

## Data flow

1. `ILTempleViewModel` loads `useCase.getInitialState(templeID:)` and maps the
   temple to `ILTempleStateModel` via a pure `makeStateModel(from:isFollowing:
   isBiographyExpanded:now:)`, recomputed on every state-changing input
   (`viewDidLoad`, follow toggle, bio toggle) so the open/closed + distance
   values always reflect `now()`.
2. Open/closed: compares the current minute-of-day against `regularHours`, or
   `holidayHours` when `ILLunarCalendar.solarToLunar(date: now)` reports the
   1st or 15th lunar day.
3. Distance: haversine formula from a fixed reference point (Quận 1, TP.HCM,
   matching the design handoff) to the temple's `latitude`/`longitude`.
4. `handleFollowTapped()` flips `isFollowing` immediately (optimistic) and
   spawns a `Task` calling `toggleFollow` (stub).
5. Nav taps emit `.back` / `.offer` / `.events` / `.session(id:)` directly, or
   `.openURL(_:)` with a URL built from the entity's coordinates (Maps) or a
   contact's raw value (`tel:`/`https:`/`mailto:`).

There is no network call and no Step-by-step Flow.

## Deliberately stub / mock

`ILTempleUseCaseImpl` returns a static 9-temple catalog (Từ Quang fully
detailed, matching the design handoff's "giả lập đầy đủ" note; the other 8
reuse the Home carousel's `home.temple.*` names/places with per-temple
history/hours/contacts/amenities/rules transcribed from `TEMPLE_INFO`), with
`toggleFollow` a `print("TODO: …")` stub. Completing this is `tasks.md`
Phase 3, blocked on the temple API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `temple` (`isTemple`) and its `Component.TEMPLE_INFO`/
`templeVals()` data + derivation logic. See
`InnerLamp/Presentation/Scenes/Temple/README.md` for the full
design-vs-implementation comparison and changelog.
