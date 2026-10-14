# Tasks — FestivalDetail

Version: 1.0
Last updated: 2026-10-11
Status: implemented (app builds); tests not runnable here; device QA pending

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI
- [x] `ILFestivalDetailViewController` (sticky header band + nav bar, hero, sections, loading/error)
- [x] `ILFestivalDetailDateCardView`, `ILFestivalDetailListCardView`
- [ ] Visual QA against prototype `festDetail` on a physical device (light + dark)

## Phase 2 — Logic
- [x] `ILFestivalDetailEntity`, `ILFestivalDetailUseCase`
- [x] `ILFestivalDetailStateModel`, `ILFestivalDetailViewModel`
- [x] Coordinator + DI (`makeFestivalDetail*`)
- [x] Entry points: Home carousel, Festivals list
- [x] Localization keys

## Phase 3 — Tests
- [x] `ILFestivalDetailViewModelTests`, `ILFestivalDetailUseCaseTests`, new cases in `ILFestivalsViewModelTests`, `ILHomeViewModelTests`
- [ ] Run them — blocked by `GRPCProtobufGenerator` plugin validation (test target does not build with `generic/platform=iOS`)

## Phase 4 — Deferred
- [ ] "Kinh nên tụng" real data (TD-FestivalDetail-001)
- [ ] "Chùa tổ chức" real data (TD-FestivalDetail-001)
- [ ] "Nhắc tôi ngày này" button (TD-FestivalDetail-002)
- [ ] OKF concept (`okf-writer`) after device verification
