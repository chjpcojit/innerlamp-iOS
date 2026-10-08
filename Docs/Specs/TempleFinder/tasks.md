# Tasks — TempleFinder

Version: 1.0
Last updated: 2026-10-05
Status: in-progress (Phase 1–2 done; Phase 3 proposal API pending; on-device QA + test run pending)

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI

- [x] `ILTempleFinderViewController` (header: `ILNavBar` + search + region chips; table; in-place form;
      loading / error states)
- [x] Feature views: card cells (row / add / empty / sent banner) and `ILTempleFinderAddFormView`
- [x] Localization keys `templeFinder.*` in `Resources/Localization/vi.json`
- [ ] Visual QA on device against the prototype screen `findtp`

## Phase 2 — Logic

- [x] `ILTempleFinderUseCase` (+ Impl) — all-pages load, de-dup, pick via `ILSanghaUseCase`
- [x] `ILSanghaUseCase.selectMyTemple(_ temple:)` + snapshot fallback in `loadMyTemple()`
- [x] `ILTempleFinderStateModel`, `ILTempleFinderViewModel` (search, region filter, pick, proposal validation)
- [x] `ILTempleFinderCoordinator` + `DIContainer.makeTempleFinder*`
- [x] Chùa tab: "Đổi chùa" → `.openTempleFinder`; reload on `viewWillAppear`
- [x] Unit tests written: `ILTempleFinderViewModelTests`, `ILTempleFinderUseCaseTests`; Sangha tests updated
- [ ] Run the tests — ⚠️ the test target currently fails to compile on unrelated `InnerLampTests/GRPC/*`
      module-resolution errors

## Phase 3 — API integration (pending; blocked on contract)

- [ ] Submit the temple proposal to the backend
      > ⚠️ Not confirmed: endpoint / payload — see `Docs/Tech-Debt/TempleFinder/TD-TempleFinder-001-*.md`
- [ ] Decide whether a proposal is selectable as the practice temple ("Chờ xác minh" state)

## Phase 4 — Docs

- [ ] OKF concept under `Docs/Knowledge/features/` (only after on-device verification)
