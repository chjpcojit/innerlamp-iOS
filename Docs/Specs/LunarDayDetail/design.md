# Design — LunarDayDetail

Version: 1.0
Last updated: 2026-09-27
Status: implemented — pure client-side lunar computation, no backend

> See `changelog.md` in this folder for the version history of this spec.

## Overview

LunarDayDetail follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**leaf screen** owned by `ILHomeCoordinator` (not `AppCoordinator`), reached only
from within the Home section. The whole feature is a pure computation over
`ILLunarCalendar` from a passed-in solar `Date` — there is **no network, no disk,
no DTO/Mapper, and no Repository**, so the Data layer is intentionally absent.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLunarDayDetailEntity.swift` | Pure business fields for one solar day: `date`, solar day/month/year, lunar day/month/year + leap flag, `isHoangDao`, day can/chi indices, six good-hour chi indices, clash chi index, joy/wealth directions, verse lines + source. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/LunarDayDetail/ILLunarDayDetailUseCase.swift` | `getDetail(for:) -> ILLunarDayDetailEntity` — computes lunar conversion, can-chi, good hours, clash, directions, and the verse via `ILLunarCalendar`. Pure, synchronous. No stub needed (no network/disk). |
| Presentation / State | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailStateModel.swift` | UI-only state: `.localized`/formatted display values (hero, day-type pill + tone, info rows, good hours, clash, directions). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailViewModel.swift` | `Input` (`viewDidLoad`, `backTapped`) → `Output` (`ViewState<ILLunarDayDetailStateModel>`); owns the `ILLunarDayDetailNavEvent` publisher; maps Entity → StateModel in `makeStateModel`. |
| Presentation / Coordinator | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailCoordinator.swift` | Pushes `ILLunarDayDetailViewController`; `.back` → pop + `finish()`. No delegate (leaf). |
| Presentation / ViewController | `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailViewController.swift` | Full-bleed hero + info table + verse + good hours + clash + directions; transparent → opaque header after >110 px scroll. UI split into `Views/` (hero, info, verse, good hours, clash, directions). |
| Shared helper (modified) | `Core/Utils/ILLunarCalendar.swift` | Extended with `canChiDay/canChiMonth/canChiYear`, `isHoangDao`, `goodHourChiIndices`, `clashChiIndex`, `joyStarDirection`, `wealthStarDirection` used by this feature. |
| Design System tokens (modified) | `ILColors` (`ILSunk2`, `ILClashForeground`) | New tokens for the hero gradient and clash accents. |

## Navigation flow

```
ILHomeCoordinator
  └─ (tap large lunar card) → ILHomeNavEvent.openLunarDayDetail(date:)
       → showLunarDayDetail(date:) → ILLunarDayDetailCoordinator
            push ILLunarDayDetailViewController
            (tap ‹) → ILLunarDayDetailNavEvent.back → pop + finish()
```

## Data flow

Single synchronous computation, no network call:

1. `ILHomeCoordinator` passes the selected solar `Date` into
   `ILLunarDayDetailCoordinator` / `makeLunarDayDetailViewModel(date:)`.
2. `ILLunarDayDetailViewModel` calls `useCase.getDetail(for: date)` to build the
   initial `ILLunarDayDetailEntity`, then maps it to
   `ILLunarDayDetailStateModel` and emits `.success(state)`.
3. `viewDidLoad` re-runs the same computation and re-emits the state.

There is no Step-by-step Flow section: the flow has **zero** API/network calls.

## Deliberately stubbed for now

None — `ILLunarDayDetailUseCase.getDetail(for:)` is fully implemented as a pure
computation. The only "missing" pieces are visual/copy assets (hero image, verse
content source, non-Vietnamese localization) recorded in `requirements.md`
Pending, not code stubs.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
(lunar detail screen) and `Mo-ta-tinh-nang.md` §5 "Chi tiết ngày âm". See
`InnerLamp/Presentation/Scenes/LunarDayDetail/README.md` for the
design-vs-implementation comparison and known gaps.
