# Naming Conventions

**Hard constraint: every generated Swift type — and the file it lives in — always starts with
the project prefix `IL`** (2-3 uppercase letters taken from "InnerLamp"). This applies to
*every* file this skill generates, not just shared Design System components: Entity, UseCase,
Coordinator, ViewController, ViewModel, NavEvent, delegate protocols, and any split-out `Views/`
file. There is no unprefixed category anymore — do not generate `OnboardingViewModel`-style names
for new features; the historical `Onboarding`/`Splash` scenes already in the repo predate this
rule and are left as-is (do not rename existing files just to backfill the prefix unless the user
explicitly asks for that cleanup).

Common vs. feature-scoped is now decided by **folder placement**, not by presence/absence of the
prefix (both kinds carry `IL`):

## 1. Shared / reusable Design System pieces → `IL<Name><Kind>`

Anything added to `Presentation/Common/DesignSystem/Components/` or
`Presentation/Common/DesignSystem/Tokens/` — no feature name baked in, since it must work for any
screen:

- `ILButton`, `ILField`, `ILRow`, `ILChip`, `ILNavBar`, `ILAvatarView`, `ILStateView`,
  `ILBottomNavBar`, `ILSettingRow`, `ILColors`, `ILTypography`, `ILMetrics`

`<Kind>` is the UIKit role (`View`, `Button`, `Row`, `Chip`, `Bar`, ...). Example: a new reusable
badge is `ILBadgeView`, not `BadgeView` and not `ILBadge` (missing kind is acceptable only if the
existing codebase has a precedent, e.g. `ILChip`).

## 2. Feature scene types → `IL<Feature><Role>`

Everything under `Presentation/Scenes/<Feature>/` and `Domain/UseCases/<Feature>/` uses `IL` +
the feature name as the prefix:

- `Domain/Entities/IL{{Feature}}Entity.swift` → `IL{{Feature}}Entity` (pure business fields only —
  never UI-only fields like `*Error`/`isSubmitting`; see `references/data_layer_boundaries.md`)
- `Presentation/Scenes/{{Feature}}/IL{{Feature}}StateModel.swift` → `IL{{Feature}}StateModel` (UI
  state owned by the ViewModel — this is the `T` in `ViewState<T>`, lives in Presentation, not
  Domain)
- `Data/DTOs/IL{{Feature}}DTO.swift` → `IL{{Feature}}DTO` (wire format, only when a confirmed API
  contract exists) + `Data/DTOs/Mappers/IL{{Feature}}Mapper.swift` → `IL{{Feature}}Mapper`
  (`Entity <-> DTO` only)
- `Domain/UseCases/{{Feature}}/IL{{Feature}}UseCase.swift` → `IL{{Feature}}UseCase` (protocol) /
  `IL{{Feature}}UseCaseImpl` (class)
- `Presentation/Scenes/{{Feature}}/IL{{Feature}}Coordinator.swift` → `IL{{Feature}}Coordinator` +
  `IL{{Feature}}CoordinatorDelegate`
- `Presentation/Scenes/{{Feature}}/IL{{Feature}}ViewController.swift` → `IL{{Feature}}ViewController`
- `Presentation/Scenes/{{Feature}}/IL{{Feature}}ViewModel.swift` → `IL{{Feature}}ViewModel` +
  `IL{{Feature}}ViewModelProtocol` + `IL{{Feature}}NavEvent`

So for a new feature called `Settings`, generate `ILSettingsCoordinator`, `ILSettingsViewController`,
`ILSettingsViewModel`, `ILSettingsViewModelProtocol`, `ILSettingsUseCase`/`ILSettingsUseCaseImpl`,
`ILSettingsEntity` (Domain), `ILSettingsStateModel` (Presentation), and — only if a real API
contract exists — `ILSettingsDTO` + `ILSettingsMapper`.

Note: `DIContainer` factory **methods** (`make{{Feature}}ViewModel()`, not a type/file) stay
feature-name-only, no `IL` — the prefix rule is for types and file names, not for method names.

## 3. Split-out screen subviews (`Presentation/Scenes/<Feature>/Views/`)

When building a screen's UI, pull any UI piece that can stand on its own into its own `View` file
under `{{Feature}}/Views/` instead of inlining everything in the `ViewController`. Before naming
or placing it, decide reuse **first**:

- **Depends only on generic data** (a count, a label string, a state enum, a color) and has **no
  feature-specific content or copy baked in** → it is a shared primitive. Move it to
  `Presentation/Common/DesignSystem/Components/` as `IL<Name><Kind>` (rule 1) — even if this is
  its first use in only one feature so far. Do not leave a genuinely generic view sitting in a
  feature's `Views/` folder "for now."
- **Depends on this feature's specific content, copy, or is a screen-specific composition of
  several `IL*` pieces** → keep it feature-scoped: `Presentation/Scenes/{{Feature}}/Views/IL{{Feature}}<Name>View.swift`
  → `IL{{Feature}}<Name>View` (rule 2 naming, e.g. `ILOnboardingProgressHeaderView`).

Re-check this decision for every split-out view — reusability is a property of the view's
content/inputs, not of how many screens currently use it. Only wait for explicit user direction
when the two are genuinely ambiguous after applying this test.

## Rule of thumb

> Every type/file starts with `IL`. Shared Design System pieces have no feature name in them and
> live in `Common/DesignSystem/`; feature-scoped pieces have `IL<Feature>` in them and live in
> `Scenes/<Feature>/`.
