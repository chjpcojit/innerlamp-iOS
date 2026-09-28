# Tasks — LunarDayDetail

Version: 1.0
Last updated: 2026-09-27
Status: implemented (Phases 1–3 done; Phase 4 partially — visual QA + copy/assets
confirmations pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built by `il-screen-builder` from the design handoff.
> Checked items below reflect what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILLunarDayDetailViewController` extending `BaseViewController`
- [x] `setupViews()`: full-bleed hero, day-type pill, info table, verse block,
      good-hours section, clash section, directions section (split across
      `Views/` — hero, info, verse, good hours, clash, directions)
- [x] `setupConstraints()`: Auto Layout per design tokens (`ILMetrics`,
      `ILTypography`)
- [x] `bindViewModel()`: wire `viewDidLoad` / `backTapped` to `Input`, render
      `Output.state`; transparent header → opaque on scroll >110 px
- [ ] Visual QA against the design prototype (hero height 72px, gradient, dark
      mode, header transition) — not yet done on simulator/device

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILLunarDayDetailEntity` (pure business fields, no UI state)
- [x] Create `ILLunarDayDetailStateModel` + nested display models
      (`ILLunarDayDetailTypeTone`, info-row/hour/clash/direction models)
- [x] Create `ILLunarDayDetailUseCase` / `ILLunarDayDetailUseCaseImpl`
      (`getDetail(for:)` — pure `ILLunarCalendar` computation; no stub)
- [x] Extend `Core/Utils/ILLunarCalendar.swift` with the can-chi / good-hour /
      clash / direction helpers this screen needs
- [x] Create `ILLunarDayDetailViewModel` (`Input -> Output`,
      `ILLunarDayDetailNavEvent`)
- [x] Create `ILLunarDayDetailCoordinator` (leaf, no delegate)
- [x] Wire `DIContainer.makeLunarDayDetail{UseCase,ViewModel,Coordinator}`
- [x] Wire `ILHomeCoordinator.showLunarDayDetail(_:)` +
      `ILHomeNavEvent.openLunarDayDetail(date:)`
- [x] Unit tests: `ILLunarDayDetailViewModelTests.swift` (4 tests, mock UseCase)
      + `ILLunarDayDetailUseCaseTests.swift` (8 tests — real lunar math: Tết
      10/2/2024, rằm 24/2/2024, verse selection)

## Phase 3 — API integration

- Not applicable — the feature is pure client-side computation with no
  network/disk dependency, so there is no API contract and no Data layer
  (DTO/Mapper/Repository) to build.

## Phase 4 — Documentation & assets

- [x] `InnerLamp/Presentation/Scenes/LunarDayDetail/README.md` (implementation
      notes, design comparison, known gaps, changelog)
- [ ] Get real hero cover imagery (temple/moon/lotus) from the product side to
      replace the gradient placeholder
- [ ] Localize can-chi / direction / month labels beyond `vi.json`
      (English / 中文)
- [ ] Confirm final advice-line copy/position and the zodiac-icon approach
      (emoji vs vector glyph) — see ⚠️ in `requirements.md` Pending
- [ ] Visual QA on simulator/device (build + unit tests re-run)

## Deferred (separate feature, not blocking LunarDayDetail)

- A server-backed "verse of the day" / daily-teaching API, if ever required —
  would be its own feature/endpoint, not this screen.
