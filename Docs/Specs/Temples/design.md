# Design — Temples ("Tất cả chùa")

Version: 1.0
Last updated: 2026-10-11

> See `changelog.md` in this folder for the version history of this spec.

## Flow

Home `ILHomeViewModel.templesViewAllTapped` → `.openTemples` → `ILHomeCoordinator.showTemples()` →
`ILTemplesCoordinator` pushes `ILTemplesViewController`; tapping a card → `ILTempleCoordinator` (temple page).

## Layers

| Layer | File |
|---|---|
| Domain | `Domain/UseCases/Temples/ILTemplesUseCase.swift` — pages through `ILTempleRepository.loadTemples(page:)` until `hasMore == false`, de-dups by id |
| Presentation | `ILTemplesViewModel` (client-side search + region filter), `ILTemplesStateModel`, `ILTemplesViewController`, `ILTemplesCoordinator`, `Views/ILTemplesRowCell` |
| DI | `DIContainer.makeTemples*` |

## UI

Header = `ILStickyHeaderBand` + `ILNavBar` (subtitle "N ngôi chùa") + `ILSearchInputView` + region
`ILChip`s; the `UITableView` runs under the band (band height applied as `contentInset.top`). Card =
84×84 `ILRemoteImageView` thumbnail + name + short place + note ("Di sản … · Dựng năm …", reused from
`ILHomeViewModel.templeNote`). Region filter / chips are reused from TempleFinder
(`ILTempleFinderRegionFilter`).
