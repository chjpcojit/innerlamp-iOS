# Language

<!--
Living status doc — update (don't recreate) whenever this screen's files change.
-->

## Overview

"Ngôn ngữ & hiển thị" screen (prototype screen `lang`): a child of Settings, pushed by
`ILSettingsCoordinator` from the "Ngôn ngữ & hiển thị" row and the "Chế độ tối" row. Three sections:
language (radio rows), sutra font size (live preview + 4 chips) and appearance (Sáng / Tối / Theo
máy swatch tiles). Every selection is applied immediately — there is no Save button. Spec:
`Docs/Specs/Language/`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILLanguageEntity.swift` | Done | `ILAppLanguage`, `ILScriptureFontSize`, `ILLanguageEntity` (reuses `ILSettingsThemeMode`). |
| Domain — UseCase | `ILLanguageUseCase.swift` | Done | Persists language + font size in `UserDefaultsService`; theme goes through `ThemeService.setMode`, which re-skins the live window. |
| Presentation — StateModel | `ILLanguageStateModel.swift` | Done | Option lists with `isSelected` + preview text / font index. |
| Presentation — ViewModel | `ILLanguageViewModel.swift` | Done | `Input -> Output`; selecting the current value is a no-op. |
| Presentation — ViewController | `ILLanguageViewController.swift` | Done | Built from `ILNavBar`, `ILSectionEyebrowView`, `ILChip` + `Views/`. Visual QA pending (device). |
| Presentation — Coordinator | `ILLanguageCoordinator.swift` | Done | `goBack` pops + finishes. |
| Tests | `ILLanguageViewModelTests.swift`, `ILLanguageUseCaseTests.swift` | Done | |
| Wiring | `DIContainer` + `ILSettingsCoordinator` | Done | Settings refreshes its theme / language summary rows on `viewWillAppear`. |

## Known gaps

- Only `vi.json` exists, so the chosen language is persisted but does not change any UI text yet
  (see `Docs/Tech-Debt/Language/`).
- The chosen font size is not yet read by the Reader / sutra detail screens, and the Settings
  slider row still uses the mock `scriptureFontScale`.
