# Tasks — LunarDayDetail

Version: 2.0
Last updated: 2026-10-07
Status: Phases 1–3 implemented (app builds); hero-image tests written and
type-checked but not yet run; Phase 4 partially — device QA + copy confirmations
pending

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built by `ui-builder` from the design handoff.
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

## Phase 3 — API integration (hero image, `GET /v1/calendar/image`)

- [x] Add `CalendarImageEndpoint` (`Data/DataSources/Remote/`)
- [x] Add `ILCalendarImageDTO` + `ILCalendarImageMapper` (`Data/DTOs/`,
      `Data/DTOs/Mappers/`) incl. the `yyyy-MM-dd` date formatter
- [x] Add `ILCalendarImageEntity` (`Domain/Entities/`)
- [x] Add `ILCalendarImageRepository` (`Domain/Repositories/`) +
      `ILCalendarImageRepositoryImpl` (`Data/Repositories/`), errors →
      `ILCatalogError`
- [x] Add `ILCalendarImageUseCase` / `ILCalendarImageUseCaseImpl`
      (`Domain/UseCases/LunarDayDetail/`) — `nil` outside year 1900–2100
- [x] Wire `DIContainer.makeCalendarImageRepository/UseCase` and pass the use
      case into `makeLunarDayDetailViewModel`
- [x] `ILLunarDayDetailStateModel`: `heroImageURL`, `heroImageCredit`
- [x] `ILLunarDayDetailViewModel`: inject the use case, load once on
      `viewDidLoad`, re-publish state, format the credit; failure never becomes
      `.failure`
- [x] `ILLunarDayDetailHeroView`: `ILRemoteImageView` + scrim + credit caption;
      call `setImage` only when the URL changed
- [x] Add `lunarDayDetail.hero.imageCreditFormat` / `imageCreditSingleFormat` to
      `vi.json`
- [ ] Unit tests — written in `InnerLampTests/ILCalendarImageTests.swift`
      (endpoint query, wire decoding, mapping, `NetworkError` →
      `ILCatalogError`, year range) and extended
      `ILLunarDayDetailViewModelTests` (image + credit in state, failure keeps
      them empty, loaded once). Type-checked only: the `InnerLampTests` target
      does not build from the CLI (pre-existing gRPC module errors), so tick
      this after ⌘U passes in Xcode.

## Phase 4 — Documentation & assets

- [x] `InnerLamp/Presentation/Scenes/LunarDayDetail/README.md` (implementation
      notes, design comparison, known gaps, changelog)
- [x] ~~Get real hero cover imagery from the product side~~ — superseded in
      v2.0 by the server image (Phase 3); the gradient stays as the fallback
- [ ] Localize can-chi / direction / month labels beyond `vi.json`
      (English / 中文)
- [ ] Confirm final advice-line copy/position and the zodiac-icon approach
      (emoji vs vector glyph) — see ⚠️ in `requirements.md` Pending
- [ ] Visual QA on a physical device (build + unit tests re-run), now including
      the hero photo: text legibility over the scrim in light/dark, back-button
      contrast over the photo, credit caption wrapping
- [ ] Restart the backend (`make run`) and set `APIConfig` `.dev` host to the Mac's
      current LAN IP before testing the hero image on a device
- [ ] Resolve `TD-LunarDayDetail-001` (tappable license link),
      `TD-LunarDayDetail-002` (production image hosting),
      `TD-LunarDayDetail-003` (credit shown when image bytes fail)

## Deferred (separate feature, not blocking LunarDayDetail)

- A server-backed "verse of the day" / daily-teaching API, if ever required —
  would be its own feature/endpoint, not this screen.
