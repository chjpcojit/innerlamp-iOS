# Tasks — Help

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILHelpViewController` extending `BaseViewController`
- [ ] `setupViews()`: intro, search field, accordion FAQ, footer
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire search / question taps to `Input`, render
      `Output.state`
- [ ] Visual QA against the design prototype (screen `faq`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILHelpEntity` (pure business fields only)
- [ ] Create `ILHelpStateModel` (UI state, no UIKit import)
- [ ] Create `ILHelpUseCase` / `ILHelpUseCaseImpl`:
      - accordion open/close logic
      - `loadFAQ()` — stub only (content source unconfirmed)
- [ ] Create `ILHelpViewModel` (`Input -> Output`, `ILHelpNavEvent`)
- [ ] Create `ILHelpCoordinator`
- [ ] Wire `DIContainer.makeHelp{UseCase,ViewModel,Coordinator}`
- [ ] Wire `SettingsCoordinator.openHelp` → `showHelp()`
- [ ] Unit tests: `ILHelpViewModelTests.swift` (mock UseCase)

## Phase 3 — Content source integration (pending)

> Source unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm FAQ content source (bundled static vs backend/CMS)
- [ ] If fetched: create `ILHelpRepository` + `ILHelpRepositoryImpl` + DTO/Mapper
      + Endpoint; inject into `ILHelpUseCaseImpl`; replace the stub. If static:
      drop the Domain/Repository layer and load bundled data instead
- [ ] Map errors to feature error cases (if fetched)
- [ ] Manual test against a real/staging backend once available (if applicable)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Help/README.md`
- [ ] `Docs/Knowledge/features/help.md` (OKF concept) — after Phase 3

## Deferred (separate feature, not blocking Help)

- Settings, Search.
