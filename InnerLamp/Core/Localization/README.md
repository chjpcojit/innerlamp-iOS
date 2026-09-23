# Core/Localization

Custom JSON-based localization system — not `Localizable.xcstrings` — because strings need to update over-the-air without an App Store release.

## Structure

```
Localization/
├── LocalizationModels.swift        # LocalizedStringsFile: version + language + [key: value]
├── LocalizationConfig.swift        # Server base URL (mock) + default language ("vi")
├── LocalizationEndpoint.swift      # /localization/{lang}/version + /localization/{lang}
├── LocalizationFileStorage.swift   # Reads bundled default JSON, reads/writes cached downloaded JSON
├── LocalizationService.swift       # Loads active file, exposes string(for:), syncRemoteIfNeeded()
└── String+Localized.swift          # "key".localized convenience for static UI text

Resources/Localization/vi.json      # Bundled default file (source of truth on first launch)
```

## How it works

1. On init, `LocalizationServiceImpl` loads the cached file from Application Support (if a newer one was ever downloaded), else falls back to the bundled `vi.json` shipped in the app.
2. `AppDelegate.bootstrapLocalization()` calls `syncRemoteIfNeeded()` in the background at launch: fetch the server's current version, compare with the version already loaded, and only download the full file when it differs.
3. Any network/decode failure during sync is swallowed silently — the app keeps using whatever file it already loaded (cached or bundled). The UI never blocks on this and never crashes because of it.

## Usage

```swift
label.text = "common.retry".localized
```

or via DI (for code that needs to be testable, e.g. a UseCase/ViewModel):

```swift
container.localizationService.string(for: "common.retry")
```

A missing key returns the key itself instead of crashing — makes untranslated strings obvious in the UI during development.

## Adding a new language

1. Add `Resources/Localization/<lang>.json` with the same shape as `vi.json`.
2. There is no language switcher yet — `LocalizationConfig.defaultLanguage` is hardcoded to `"vi"`. Wiring a switcher means passing the chosen language into `LocalizationServiceImpl.init(language:)` instead of the default, and persisting the choice (e.g. via `UserDefaultsService`).

## Known limitation

`LocalizationConfig.serverBaseURL` is a mock — there is no real backend yet (same situation as `LoggingConfig`'s risk/metrics/analytics servers). Replace it once the endpoint exists.
