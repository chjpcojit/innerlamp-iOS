# Temples

Screen **"Tất cả chùa"** (prototype `temples`) — pushed from the Home block "Chùa Việt Nam" → "Xem tất cả".
Leaf coordinator (`ILTemplesCoordinator`); tapping a card opens the Temple page. Spec: `Docs/Specs/Temples/`.

- Header: `ILStickyHeaderBand` + `ILNavBar` (subtitle "N ngôi chùa"), search, region chips.
- Data: `ILTemplesUseCase.loadTemples()` (all pages, de-dup); search / region filter are client-side.
- Not built: "Đề xuất" action (TD-Temples-001); "Tây Nguyên" chip (AS-Temples-001).

## Status

| Layer | Status | Notes |
|---|---|---|
| UseCase / ViewModel / StateModel / Coordinator / ViewController / Cell | Done | Build verified |
| Tests | Written, not run | `ILTemplesViewModelTests`; test target blocked by GRPC plugin |
| Device QA | Pending | |
