# Tasks — Temples

Version: 1.0
Last updated: 2026-10-11
Status: in-progress

> See `changelog.md` in this folder for the version history of this spec.

- [x] Home: link text "Xem tất cả" (`home.temple.viewAll`), `.openTemples` event, coordinator wiring
- [x] `ILTemplesUseCase` (+ Impl), `ILTemplesViewModel`, `ILTemplesStateModel`, `ILTemplesCoordinator`
- [x] `ILTemplesViewController` + `ILTemplesRowCell`, localization keys `temples.*`
- [x] `DIContainer.makeTemples*`
- [x] Unit tests written: `InnerLampTests/ILTemplesViewModelTests.swift`
- [x] `xcodebuild build` (generic iOS) succeeds
- [ ] Run the unit tests — ⚠️ test target blocked by GRPC plugin (see HANDOFF)
- [ ] Visual QA on device against prototype screen `temples`
- [ ] "Đề xuất" nav-bar action — TD-Temples-001
- [ ] OKF concept (`il-okf-writer`) after verification
