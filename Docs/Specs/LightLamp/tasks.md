# Tasks — LightLamp

Version: 1.1
Last updated: 2026-10-11
Status: Phases 1–3 implemented (build-verified); tests written but not run; Phase 4 docs partly done

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — Data + Domain

- [x] Create `ILLampEntity` (+ kind/intention enums, `daysLeft(now:)`)
- [x] Create `ILLampRepository` protocol + `ILLampError`
- [x] Add `InnerLamp 5.xcdatamodel` with `ILLampMO`; set as current model
- [x] Create `ILLampLocalDataSource` + `ILLampRepositoryImpl`
- [x] Create `ILLightLampUseCase` / impl (`light`, `loadGarden`, `activeCount`, expiry)

## Phase 2 — Presentation

- [x] Add missing design tokens (lamp artwork colors) to `ILColors` / `ILIcons`
- [x] Create `ILLampArtView` (oil / lotus / float, lit + unlit, ignite animation)
- [x] Create `ILLightLampStateModel` + `ILLightLampViewModel` (`Input -> Output`, nav events)
- [x] Create `ILLightLampViewController` (hero stage, option groups, target/vow inputs, bottom button, completion state)
- [x] Create `ILLampGardenStateModel` + `ILLampGardenViewModel`
- [x] Create `ILLampGardenViewController` + `ILLampCardView` (filter chips, grid, "Xem thêm đèn", empty state)
- [x] Create `ILLightLampCoordinator` + delegate protocol
- [x] Add `lightLamp.*` keys to `vi.json`

## Phase 3 — Wiring

- [x] Wire `DIContainer.makeLightLamp*`
- [x] Add `ILHomeNavEvent.openLightLamp`; route the `.offering` row; `ILHomeCoordinator.showLightLamp()`
- [ ] Unit tests: `ILLightLampViewModelTests`, `ILLampGardenViewModelTests`, `ILLightLampUseCaseTests` — written and type-checked, not yet run (`TD-LightLamp-004`)
- [x] Build verification (`generic/platform=iOS`)

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/LightLamp/README.md` (+ `membershipExceptions` in `project.pbxproj`)
- [x] Assumption + Tech Debt entries for every ⚠️ interim default
- [ ] `Docs/Knowledge/` concept via `okf-writer` — after verification

## Deferred (separate feature, not blocking LightLamp)

- Paid offering, receipt, "Thỉnh đèn tại chùa" — see `Docs/Specs/Offering/`.
- Community lamps / backend API.
