# Tasks — Language

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-only

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILLanguageViewController` extending `BaseViewController`
- [ ] `setupViews()`: language options, font-size options + preview sentence,
      appearance options
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire selections to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screen `lang`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILLanguageEntity` (pure business fields only)
- [ ] Create `ILLanguageStateModel` (UI state, no UIKit import)
- [ ] Create `ILLanguageUseCase` / `ILLanguageUseCaseImpl`:
      - `currentPreferences()` / `apply(...)` via shared services
- [ ] Create `ILLanguageViewModel` (`Input -> Output`, `ILLanguageNavEvent`)
- [ ] Create `ILLanguageCoordinator`
- [ ] Wire `DIContainer.makeLanguage{UseCase,ViewModel,Coordinator}`
- [ ] Wire `SettingsCoordinator.openLanguage` → `showLanguage()`
- [ ] Unit tests: `ILLanguageViewModelTests.swift` + `ILLanguageUseCaseTests.swift`
      (mock localization/theme services)

## Phase 3 — API integration

- Not applicable — local-only. No backend.

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Language/README.md`
- [ ] `Docs/Knowledge/features/language.md` (OKF concept)

## Deferred (separate feature, not blocking Language)

- Settings.
