# Tasks — Settings

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock data. Checked items reflect
> what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILSettingsViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: account card, four section cards
      (schedule / display / content / privacy), footer — per design handoff
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILSettingsAccountCardView`,
      `ILSettingsScheduleCardView`, `ILSettingsDisplayCardView`,
      `ILSettingsContentCardView`, `ILSettingsPrivacyCardView`
- [x] Add shared `ILSectionEyebrowView`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `settings`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILSettingsEntity` + account/bell/sound/theme types
- [x] Create `ILSettingsStateModel`
- [x] Create `ILSettingsUseCase` / `ILSettingsUseCaseImpl` (`getSettings()` — mock)
- [x] Create `ILSettingsViewModel` (`Input -> Output`, `ILSettingsNavEvent`, 9
      cases, toggle/font-scale updates, formatting helpers)
- [x] Create `ILSettingsCoordinator` (goBack pop; openProfile → EditProfile;
      the rest TODO)
- [x] Wire `DIContainer.makeSettingsUseCase/ViewModel/Coordinator`
- [x] Wire `ILProfileCoordinator` (`openSettings` push)
- [x] Unit tests: `InnerLampTests/ILSettingsViewModelTests.swift` (19 tests) —
      per-Input, state mapping (full/empty dharma name), formatting helpers

## Phase 3 — Persistence/API (pending; blocked on contract)

> ⚠️ Not confirmed: the settings persistence/API contract (local UserDefaults vs
> remote) — see `requirements.md` Pending. Everything below is blocked until
> that is decided.

- [ ] Decide the settings persistence/API (UserDefaults vs remote) and confirm
      the contract if remote
- [ ] Create `ILSettingsRepository` protocol + implementation (UserDefaults
      and/or `NetworkService`)
- [ ] Replace the mock in `ILSettingsUseCaseImpl.getSettings()` with real reads;
      persist toggle/font-scale changes
- [ ] Sync the dark-mode value with `ThemeService`; wire the font scale to the
      scripture reader; read `appVersion` from `CFBundleShortVersionString`
- [ ] Update `ILSettingsViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Sub-destinations (pending, separate scope)

- [ ] Build the bell-sound picker and wire `.openBellSound`
- [ ] Build the language & display screen and wire `.openDarkMode` / `.openLanguage`
- [ ] Build the downloads screen and wire `.openDownloads`
- [ ] Build the help/FAQ screen and wire `.openHelp`
- [ ] Build the export-data flow and wire `.openExportData`
- [ ] Build the offline-status screen and wire `.openOffline`
- [ ] Update `InnerLamp/Presentation/Scenes/Settings/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Settings/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/settings.md` (OKF concept) — hold off until the
      persistence (Phase 3) lands. See `Docs/Specs/OKF.md`.
