# No Hardcoding: Text, Font Size, Color

Three hard constraints for every screen this skill generates. None of these are
"nice to have" — a generated screen that violates any of them is not done.

## 1. Text — no hardcoded strings, must support multiple languages

Never write a user-facing string literal directly in a `ViewController`, `View`, `ViewModel`, or
`Domain/Entities` default (titles, button labels, placeholders, alert messages, empty-state copy,
accessibility labels — anything a user reads). This project does **not** use Apple's String
Catalog (`Localizable.xcstrings`) — it has its own custom JSON-based localization system under
`InnerLamp/Core/Localization/` (see `InnerLamp/Core/Localization/README.md`), built so copy can
update over-the-air without an App Store release. Use it via the `String` extension:

```swift
nextButton.setTitle("onboarding.cta.start".localized, for: .normal)
```

- `"<key>".localized` (`InnerLamp/Core/Localization/String+Localized.swift`) is Foundation-only —
  safe to call from a `ViewModel` or even a `Domain/Entities` default/computed property, not just
  from UIKit code.
- Keys are **dotted namespaces**, not the raw base-language copy — follow the existing pattern
  already in `InnerLamp/Resources/Localization/vi.json` (`common.ok`, `error.generic`, ...): use
  `<feature>.<part>[.<variant>]`, e.g. `onboarding.cta.start`, `splash.tagline`,
  `onboarding.intent.0`.
- Add every new key's Vietnamese copy to `InnerLamp/Resources/Localization/vi.json` (the bundled
  default file, source of truth on first launch) as part of generating the feature. A missing key
  returns the key itself instead of crashing, but don't rely on that — always add the entry.
- `<Feature>StateModel` fields that hold display text (e.g. a label pulled from the model) should
  already be the resolved `String` by the time they reach the view — resolve `.localized` at the
  `Domain/Entities` default, `UseCase`, or `ViewModel` layer (wherever the literal would otherwise
  be baked in), not by leaving a raw literal in the state model's default/mock values.
- There is no `comment:`/translator-context mechanism in this system (unlike Apple's String
  Catalog) — the key name itself is the only context, so make keys descriptive
  (`onboarding.back.toLogin`, not `onboarding.back1`).

## 2. Font size — no hardcoded point sizes, always from `ILTypography`

Never write `UIFont.systemFont(ofSize: 14, ...)`, `.beVietnamPro(size: 14, ...)`, or any other
raw numeric size directly in a screen/view. Use one of `ILTypography`'s existing named presets
(`ILTypography.body`, `.title1`, `.caption`, `.button`, ...) — see
`InnerLamp/Presentation/Common/DesignSystem/Tokens/ILTypography.swift` for the full list.

- **If none of the existing presets fit**, do not hardcode a one-off size inline. Add a new named
  preset to `ILTypography.swift` itself (same pattern as the existing ones: a `public static let`
  built from `lora(size:weight:)` or `beVietnamPro(size:weight:)`), then reference that preset from
  the screen. The token file grows; the screen never hardcodes.
- This applies to every text-bearing view, including a newly split-out `IL{{Feature}}<Name>View`
  under `Views/` (see `references/naming_conventions.md` §3) — it also pulls its font from
  `ILTypography`, never a literal size.
- The one exception already in the codebase is `ILTypography.makeScriptureText`'s `size` parameter,
  which defaults to a named value (`18`) but stays overridable for scripture-reading font-scaling —
  don't copy this exception pattern elsewhere without the same justification (user-adjustable
  reading size).

## 3. Color — no hardcoded hex/RGB, always from `ILColors`

Never write `UIColor(hex: "...")`, `UIColor(red:green:blue:alpha:)`, or any other literal color
directly in a screen/view. Use one of `ILColors`'s existing named constants (`ILColors.ink`,
`.gold`, `.canvas`, `.border`, ...) — see
`InnerLamp/Presentation/Common/DesignSystem/Tokens/ILColors.swift`.

`ILColors` itself only loads from `Assets.xcassets/Colors` (each constant calls a private
`asset(_:)` helper wrapping `UIColor(named:)`) — it does not hardcode hex either, except for alpha
variants, which are `.withAlphaComponent(_:)` derived from a base asset color rather than a second
asset (e.g. `inkSecondary = ink.withAlphaComponent(0.70)`). Follow this same split when a new color
is needed:

- **New base/opaque color** (not achievable as an alpha variant of an existing one): add a color
  set under `Assets.xcassets/Colors/IL<Name>.colorset` (universal idiom, sRGB, matches the naming
  pattern of the existing sets — `ILGold`, `ILCanvas`, `ILInk`, ...), then add
  `public static let <name> = asset("IL<Name>")` to `ILColors.swift`. Never hardcode the hex value
  anywhere outside that one color set's `Contents.json`.
- **Alpha/tint of an existing base color**: don't create a new asset — add
  `public static let <name> = <baseConstant>.withAlphaComponent(<value>)` to `ILColors.swift`,
  same as `border`, `inkMuted`, `Tone.tintBackground`, etc. already do.
- The legacy `UIColor(hex:)` extension still in `ILColors.swift` exists only for older call sites
  (`ILButton`, `ILRow`, `ILField`, and a few other pre-existing components) that predate this rule.
  Do not use it in newly generated code, and do not use its existence as precedent — always go
  through `ILColors` instead.
