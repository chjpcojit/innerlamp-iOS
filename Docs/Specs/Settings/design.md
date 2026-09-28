# Design — Settings

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full settings UI with mock data; destinations not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Settings ("Cài đặt") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
a **pushed screen** inside the "Tôi" tab, owned by `ILProfileCoordinator`
(reached via the Profile menu's "Cài đặt" row). It has no delegate — `.goBack`
pops, `.openProfile` pushes EditProfile, and the rest are TODOs. There is **no
network** and no persistence — toggles are in-memory.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSettingsEntity.swift` | `ILSettingsEntity` (account, bell times, bell sound, font scale, bilingual, theme, downloads counts, hide-journal, appVersion) + `ILSettingsAccountEntity`, `ILSettingsBellEntity`, `ILSettingsBellSound`, `ILSettingsThemeMode`. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Settings/ILSettingsUseCase.swift` | `getSettings()` — static mock (TODO: repository → UserDefaults/network). |
| Presentation / State | `Presentation/Scenes/Settings/ILSettingsStateModel.swift` | UI-only state: account header, bell schedule text, font scale, bilingual, theme title, downloads/language summary, hide-journal, version. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Settings/ILSettingsViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILSettingsNavEvent` (9 cases); Entity→StateModel mapping + toggle/font-scale updates + formatting helpers. |
| Presentation / Coordinator | `Presentation/Scenes/Settings/ILSettingsCoordinator.swift` | `pushViewController`; `.goBack` → pop+finish; `.openProfile` → EditProfile; the rest TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Settings/ILSettingsViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Settings/Views/ILSettingsAccountCardView.swift`, `ILSettingsScheduleCardView.swift`, `ILSettingsDisplayCardView.swift`, `ILSettingsContentCardView.swift`, `ILSettingsPrivacyCardView.swift` | The five section-card views. |
| Shared component | `DesignSystem/Components/ILSectionEyebrowView.swift` | Section eyebrow (new, shared). |

## Navigation flow

```
ILProfileCoordinator (tab "Tôi")
  └─ openSettings → ILSettingsCoordinator            (no delegate)
       push ILSettingsViewController
       (.goBack) → pop + finish()
       (.openProfile) → showEditProfile() (ILEditProfileCoordinator)
       (.openBellSound / .openDarkMode / .openLanguage / .openDownloads /
        .openHelp / .openExportData / .openOffline) → TODO
```

## Data flow

1. `ILSettingsViewModel` loads `useCase.getSettings()` (mock) and maps to
   `ILSettingsStateModel` (formatted bell schedule, downloads summary, theme
   title, account subtitle).
2. Toggle/font-scale inputs update the in-memory state model only (no
   persistence).
3. Nav taps emit `.goBack` / `.openProfile` (wired) or the seven TODO events.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

`ILSettingsUseCaseImpl.getSettings()` returns hardcoded data (account, 3 bell
times, font scale 0.62, `.system` theme, 8 downloads / 412 MB, appVersion
"1.4") with a `// TODO` comment. Toggles are in-memory only. Completing this is
`tasks.md` Phase 3, blocked on the settings persistence/API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `settings`. See `InnerLamp/Presentation/Scenes/Settings/
README.md` for the full design-vs-implementation comparison and changelog.
