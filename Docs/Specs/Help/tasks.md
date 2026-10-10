# Tasks — Help

Version: 2.0
Last updated: 2026-10-10
Status: not started — prospective; FAQ content is bundled mock

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILHelpViewController` extending `BaseViewController`
- [ ] `setupViews()`: search field, accordion FAQ, footer card
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire search / card / footer taps to `Input`, render
      `Output.state`
- [ ] Extract `ILHelpFAQCardView` and `ILHelpFooterCardView` (feature `Views/`)
- [ ] Incremental card update on expand/collapse (no full rebuild; guard
      `if items != oldValue`)
- [ ] Visual QA against the design prototype (screen `faq`)

## Phase 2 — Logic (Domain + bundled content)

- [ ] Create `ILHelpFAQItemEntity` (pure business fields only)
- [ ] Create `ILHelpRepository` protocol (Domain) + `ILHelpRepositoryImpl`
      (bundled localized mock, 5 items)
- [ ] Add localization keys `help.faq.<n>.question/answer`, footer and search
      copy
- [ ] Create `ILHelpStateModel` (UI state, no UIKit import)
- [ ] Create `ILHelpUseCase` / `ILHelpUseCaseImpl` (`loadFAQ()`, error mapping to
      `ILHelpError`)
- [ ] Create `ILHelpViewModel` (`Input -> Output`, `ILHelpNavEvent`, accordion
      single-open logic)
- [ ] Create `ILHelpCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeHelp{Repository,UseCase,ViewModel,Coordinator}`
- [ ] Wire `ILSettingsCoordinator.openHelp` → `showHelp()` + delegate
      (`openContact`)
- [ ] Unit tests: `InnerLampTests/ILHelpViewModelTests.swift` (accordion
      expand / switch / collapse, load failure + retry), mocking `ILHelpUseCase`
- [ ] Record Assumption (bundled mock FAQ) in `Docs/Assumptions/Help/` and Tech
      Debt (mock source) in `Docs/Tech-Debt/Help/` — bilingual, per AGENTS §10

## Phase 3 — API integration (pending, blocks feature completion)

> ⚠️ Not confirmed: FAQ API contract (endpoint, fields, language handling).

- [ ] Obtain the FAQ API contract from the product owner
- [ ] Create `ILHelpDTO` + `ILHelpMapper` (only after the contract is confirmed)
- [ ] Create the `Endpoint` conformance (`Data/DataSources/Remote/`)
- [ ] Switch `ILHelpRepositoryImpl` from bundled mock to `NetworkService`
- [ ] Map network errors to `ILHelpError`
- [ ] Update `ILHelpViewModelTests` / add repository tests for success + failure
- [ ] Resolve the Assumption and Tech Debt entries (update status, never delete)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Help/README.md` (add its path to
      `membershipExceptions` in `project.pbxproj`, AGENTS §8)
- [ ] `Docs/Knowledge/features/help.md` (OKF concept) — after Phase 3, via
      `okf-writer`

## Deferred (separate feature, not blocking Help)

- Settings (entry row), Search (search field target).
- Contact Support — see `Docs/Specs/ContactSupport/`.
