---
name: ui-builder
description: This skill should be used when creating a new mobile UI screen, feature, or flow for the InnerLamp iOS app. It scaffolds Domain (pure Entity + UseCase), Presentation (Coordinator + ViewController + ViewModel + feature-owned StateModel), Data (DTO + Mapper, only when a real API contract is confirmed), a status-tracking README, and DIContainer wiring that strictly follows this project's existing Clean Architecture + Coordinator + MVVM pattern defined in InnerLamp/Core/Base — covering naming (every generated type/file gets the "IL" project prefix; shared vs. feature-scoped is decided by folder, not by prefix), the hard split between IL<Feature>Entity (pure business fields, Domain), IL<Feature>StateModel (UI-only state — errors, loading flags, display formatting — owned by the ViewModel, living in Presentation, never in Domain), and IL<Feature>DTO (wire format, Data, mapped to/from the Entity via IL<Feature>Mapper), which coordinator (AppCoordinator vs. a section coordinator) should own the new screen's navigation, when to split a screen's UI into its own View files (and whether those belong in the feature's Views/ folder or get promoted to the shared DesignSystem), default screen-transition behavior (crossfade unless a specific effect is requested), the hard scope limit that this skill only ever implements simple client-side validation (phone/password format, required fields) plus pure Entity/StateModel/DTO mapping for real — any action needing a network or local Repository call is generated as a one-line-TODO stub, never a guessed implementation, and hard no-hardcoding rules for user-facing text (must be localizable via the project's own `"key".localized` JSON system under InnerLamp/Core/Localization, not Apple's String Catalog), font size (must come from ILTypography), and color (must come from ILColors, which itself only loads from Assets.xcassets).
---

# InnerLamp Screen Builder

## Overview

Generates a new feature/screen for the InnerLamp iOS app — pure Domain Entity, UseCase,
Coordinator, ViewController, ViewModel + its own StateModel, a status-tracking `README.md`, and
the `DIContainer` + parent-coordinator wiring — matching the project's existing Clean
Architecture + Coordinator + MVVM conventions exactly, rather than inventing a new shape per
screen.

**Two rules that override everything else below — read `references/data_layer_boundaries.md`
first:**
1. `IL{{Feature}}Entity` (Domain), `IL{{Feature}}StateModel` (Presentation), and
   `IL{{Feature}}DTO` (Data) are three separate types that must never be merged — UI-only fields
   (`*Error`, `isSubmitting`, display formatting) never go on the Entity.
2. This skill only ever writes real implementations for pure client-side validation and
   Entity/StateModel/DTO mapping. Any action that would need a network or local Repository call
   is generated as a stub (signature kept, body is one `print("TODO: ...")` line) — never a
   guessed real implementation.

**Fixed infrastructure — read only, never edit:** everything under `InnerLamp/Core/Base/`
(`BaseViewController`, `ViewModelType`/`ViewState` in `BaseViewModel.swift`, `Coordinator`,
`BaseNavigationController`, `BaseTabBarController`, `Transition/`). This skill builds strictly on
top of these; it never regenerates or modifies them.

`IL<Feature>ViewController` **inherits** the concrete class `BaseViewController`.
`IL<Feature>ViewModel` and `IL<Feature>Coordinator` **conform to** the protocols `ViewModelType`
(via a per-feature `IL<Feature>ViewModelProtocol`) and `Coordinator` — there is no
`BaseViewModel`/`BaseCoordinator` class to subclass. Don't introduce one to "fix" this unless the
user explicitly asks for that architecture change.

`BaseViewController` already gives every generated screen tap-outside-to-dismiss-keyboard and
scroll-the-focused-field-above-the-keyboard for free — see
`references/base_architecture.md`'s "Keyboard handling" section. Never generate a second
tap gesture, `endEditing` call, or keyboard-notification observer on top of it.

## Reference map

Read these as needed — don't load all upfront if the task is narrow. Each covers one concern;
don't duplicate their content back into this file.

| Reference | Covers |
|---|---|
| `references/naming_conventions.md` | `IL` prefix rule; shared-vs-feature-scoped placement (§3 also covers splitting UI into `View` files) |
| `references/base_architecture.md` | Exact shape of `BaseViewController`, `ViewModelType`, `ViewState<T>`, `Coordinator`, transition system |
| `references/coordinator_navigation_rules.md` | `AppCoordinator` vs. section coordinator rule; delegate + `addChild`/`finish()` wiring |
| `references/mvvm_pattern.md` | The Combine-based ViewModel↔ViewController↔Coordinator shape to reproduce (canonical, supersedes the legacy closure-based `Onboarding` scene — see its own note on that) |
| `references/data_layer_boundaries.md` | **Read before touching Entity/UseCase**: `IL{{Feature}}Entity` (pure Domain) vs. `IL{{Feature}}StateModel` (Presentation UI state) vs. `IL{{Feature}}DTO` (Data wire format) split, their mappers, and the hard rule on never implementing real network/Repository calls |
| `references/design_tokens_rules.md` | Hard constraints: no hardcoded text/font-size/color |
| `references/wiring_guide.md` | `DIContainer` + parent-coordinator wiring, plus the final sanity checklist |

For everything **except** ViewModel↔ViewController↔Coordinator wiring, `Onboarding`
(`InnerLamp/Presentation/Scenes/Onboarding/`, `InnerLamp/Domain/UseCases/Onboarding/`) is still a
useful live example of subview declaration style, view-splitting, and design-token usage — just
not of the closure-based `handle*(onState:)`/`onNavigationEvent` shape it predates (see
`references/mvvm_pattern.md`).

## Workflow

### 1. Gather the required decisions

Before generating anything, determine (ask the user if not already stated):

1. **Feature name** (PascalCase, e.g. `Settings`, `Profile`, `PaymentHistory`) — becomes the
   `{{Feature}}` prefix used throughout.
2. **Parent flow** — major/cross-section flow (→ `AppCoordinator`) or reachable from within an
   existing section (→ that section's coordinator, e.g. `HomeCoordinator`, creating it first if it
   doesn't exist)? See `references/coordinator_navigation_rules.md` — a fixed project rule, not
   inferred per screen.
3. **Needs a `UseCase`?** Default yes (validation/business logic layer) unless the screen is
   confirmed pure-UI with nothing to validate or fetch.
4. **Does this screen call a confirmed server endpoint?** Only if the user has given (or the
   codebase already has) a confirmed API contract does this screen get an `IL{{Feature}}DTO` +
   `IL{{Feature}}Mapper`. Otherwise skip both — don't generate a DTO/Mapper speculatively "for
   later." See `references/data_layer_boundaries.md`.
5. **Custom transition?** Default is **none** — `CrossFadeTransition` already applies
   automatically. Only add `TransitionProviding` conformance if the user explicitly names an
   effect, checking `InnerLamp/Core/Base/Transition/` for an existing animator to reuse first. See
   `references/base_architecture.md`.

### 2. Generate files from templates

Copy each file in `assets/templates/` to its destination, replacing `{{Feature}}` with the
PascalCase feature name (and `{{featureLower}}` with its lowerCamelCase form where present), then
fill in the `TODO`s with real screen-specific content — **respecting the hard scope limit in
`references/data_layer_boundaries.md`**: only pure client-side validation and Entity/StateModel/
DTO mapping get real implementations; anything needing a network or Repository call is left as a
one-line-TODO stub, never guessed or faked:

| Template | Destination |
|---|---|
| `assets/templates/Entity.swift.template` | `InnerLamp/Domain/Entities/IL{{Feature}}Entity.swift` — pure business fields only, no UI-only fields (see `references/data_layer_boundaries.md`) |
| `assets/templates/ViewState.swift.template` | `InnerLamp/Presentation/Scenes/{{Feature}}/IL{{Feature}}StateModel.swift` — all UI-only state (`*Error`, `isSubmitting`, display formatting) lives here, not on the Entity |
| `assets/templates/UseCase.swift.template` | `InnerLamp/Domain/UseCases/{{Feature}}/IL{{Feature}}UseCase.swift` (skip if pure-UI, see step 1) |
| `assets/templates/DTO.swift.template` | `InnerLamp/Data/DTOs/IL{{Feature}}DTO.swift` (only if step 1.4 confirmed a real API contract; skip otherwise) |
| `assets/templates/Mapper.swift.template` | `InnerLamp/Data/DTOs/Mappers/IL{{Feature}}Mapper.swift` (generate only alongside the DTO above) |
| `assets/templates/Coordinator.swift.template` | `InnerLamp/Presentation/Scenes/{{Feature}}/IL{{Feature}}Coordinator.swift` |
| `assets/templates/ViewController.swift.template` | `InnerLamp/Presentation/Scenes/{{Feature}}/IL{{Feature}}ViewController.swift` |
| `assets/templates/ViewModel.swift.template` | `InnerLamp/Presentation/Scenes/{{Feature}}/IL{{Feature}}ViewModel.swift` |
| `assets/templates/ViewModelTests.swift.template` | `InnerLampTests/IL{{Feature}}ViewModelTests.swift` |
| `assets/templates/README.md.template` | `InnerLamp/Presentation/Scenes/{{Feature}}/README.md` |

Every generated file/type carries the `IL` prefix (see `references/naming_conventions.md`) — a
hard rule for new features; the existing `Onboarding`/`Splash` scenes predate it and stay
unprefixed, don't rename them.

**Mandatory, non-optional parts of "done":**

- **Tests**: one per action/trigger, driven through its `Input` publisher, mocking
  `IL{{Feature}}UseCase` directly — see `references/mvvm_pattern.md` §Testing. Never leave
  placeholder-only tests.
- **View-splitting**: pull any standalone UI piece into its own `View` file instead of inlining it
  in the ViewController, deciding shared (`DesignSystem/Components/`) vs. feature-scoped
  (`Scenes/{{Feature}}/Views/`) placement per `references/naming_conventions.md` §3 — reusability
  is judged per-piece, not deferred "until a second screen needs it."
- **README**: fill `README.md`'s Overview/Status/Navigation events/Known-gaps sections honestly
  based on what this run actually built — a row legitimately stays "Skeleton" if that layer's
  logic isn't implemented yet (e.g. a `UseCase` method still a one-line-TODO stub because it needs
  a network/Repository call — see `references/data_layer_boundaries.md`). **If the feature already
  has a `README.md`** (you're extending, not creating it), update it in place — refresh the Status
  table and append a Changelog line — instead of regenerating from the template.

Do **not** auto-generate a UI test file — only add one if the user explicitly asks, scoped per
`references/mvvm_pattern.md` §Testing.

### 3. Wire the feature in

Follow `references/wiring_guide.md` exactly:

1. Add `make{{Feature}}UseCase()` / `make{{Feature}}ViewModel()` /
   `make{{Feature}}Coordinator(navigationController:)` factory methods to `DIContainer`.
2. Add a `show{{Feature}}()` method + delegate conformance to the correct parent coordinator,
   calling `addChild(_:)` then `start()`.

### 4. Verify

Run through `references/wiring_guide.md`'s sanity checklist before reporting the feature done —
in particular confirm no file under `InnerLamp/Core/Base/` was touched, no transition code was
added unless explicitly requested, every new type name follows the `IL`-vs-unprefixed rule,
`IL{{Feature}}Entity` has no UI-only fields (they're on `IL{{Feature}}StateModel` instead), no
`handleAction()`-style method contains a guessed network/Repository call instead of the one-line
TODO stub, and `README.md`'s Status table matches what was actually implemented (not all rows
blindly marked Done).
