# Tasks — Language

Version: 1.1
Last updated: 2026-10-07
Status: implemented — build verified; device QA pending; local-only

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILLanguageViewController` extending `BaseViewController`
- [x] `setupViews()`: language options, font-size options + preview sentence,
      appearance options
- [x] `setupConstraints()`: Auto Layout per design tokens
- [x] `bindViewModel()`: wire selections to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screen `lang`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILLanguageEntity` (pure business fields only)
- [x] Create `ILLanguageStateModel` (UI state, no UIKit import)
- [x] Create `ILLanguageUseCase` / `ILLanguageUseCaseImpl`:
      - `currentPreferences()` / `apply(...)` via shared services
- [x] Create `ILLanguageViewModel` (`Input -> Output`, `ILLanguageNavEvent`)
- [x] Create `ILLanguageCoordinator`
- [x] Wire `DIContainer.makeLanguage{UseCase,ViewModel,Coordinator}`
- [x] Wire `SettingsCoordinator.openLanguage` → `showLanguage()`
- [x] Unit tests: `ILLanguageViewModelTests.swift` + `ILLanguageUseCaseTests.swift`
      (mock localization/theme services)

## Phase 3 — API integration

- Not applicable — local-only. No backend.

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Language/README.md`
- [ ] `Docs/Knowledge/features/language.md` (OKF concept)

## Deferred (separate feature, not blocking Language)

- Settings.
