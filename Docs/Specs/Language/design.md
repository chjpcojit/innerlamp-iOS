# Design — Language

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-only, no backend

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Language follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**section screen** owned by the Settings coordinator, reached via
`ILSettingsNavEvent.openLanguage` (already referenced in Settings code). It is
local-only — it writes the user's language / font-size / theme choices through
the shared localization and theme services — so there is **no Data / network
layer**.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLanguageEntity.swift` | Pure business fields: language code, font-size preset, theme mode (light / dark / system). |
| Domain / UseCase | `Domain/UseCases/Language/ILLanguageUseCase.swift` | `currentPreferences()`, `apply(...)` — delegates to the shared localization/theme services. |
| Presentation / State | `Presentation/Scenes/Language/ILLanguageStateModel.swift` | UI-only state: selected language / font size / theme, preview text + preview size. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Language/ILLanguageViewModel.swift` | `Input -> Output`; owns `ILLanguageNavEvent` (back). |
| Presentation / Coordinator | `Presentation/Scenes/Language/ILLanguageCoordinator.swift` | Pushes `ILLanguageViewController`. |
| Presentation / ViewController | `Presentation/Scenes/Language/ILLanguageViewController.swift` | Three sections (language / font size / theme) with preview. |

## Navigation flow

```
SettingsCoordinator
  └─ (tap "Hiển thị & ngôn ngữ" / dark-mode row) → openLanguage → ILLanguageCoordinator
       push ILLanguageViewController
       (tap back) → pop
```

## Data flow

Local-only, no network → no Step-by-step Flow section needed:

1. Selection → `ILLanguageViewModel.apply(...)` → `ILLanguageUseCase.apply(...)`
   → shared `LocalizationService` / theme service → re-render preview + app-wide.

## Deliberately stubbed for now

None — no network dependency. `ILLanguageUseCase.apply(...)` writes through the
shared services.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `lang`, and `Mo-ta-tinh-nang.md` §7 "Ngôn ngữ & hiển thị".
