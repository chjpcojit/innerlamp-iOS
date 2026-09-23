# Concept types and section mapping

Seven `type:` values map onto the bundle's folder structure. Pick the type by asking what the
concept is *about* — the subject, not the file it happens to sit near.

## The types

| `type` | Section | File location | Subject |
|---|---|---|---|
| `Feature` | `features/` | `Docs/Knowledge/features/<name>.md` | One user-facing feature/flow end to end |
| `API Endpoint` | `api/` | `Docs/Knowledge/api/<domain>-<action>.md` | One backend endpoint's contract |
| `Domain Entity` | `domain/entities/` | `Docs/Knowledge/domain/entities/<name>.md` | One domain model |
| `UseCase` | `domain/usecases/` | `Docs/Knowledge/domain/usecases/<name>.md` | One business action / business rule set |
| `Architecture Pattern` | `architecture/` | `Docs/Knowledge/architecture/<name>.md` | A cross-cutting pattern many features follow |
| `Design Token` | `design-system/tokens/` | `Docs/Knowledge/design-system/tokens/<name>.md` | A token group (colors, typography, metrics) |
| `Component` | `design-system/components/` | `Docs/Knowledge/design-system/components/<name>.md` | One reusable UI component |

## Choosing between the close calls

**Feature vs UseCase.** A `Feature` concept is the entry point and covers the whole vertical slice —
screen, state, ViewModel, coordinator, navigation, validation, pending work. A `UseCase` concept is
written only when the business logic is worth documenting on its own: it is consumed by more than
one feature, or it encodes rules that a reader would otherwise have to reverse-engineer from code
(an OTP attempt counter, a password-strength policy, a retry/backoff rule). A UseCase used by
exactly one simple feature gets a row in that feature's Architecture table and no file of its own.

**Feature vs API Endpoint.** The `Feature` concept describes what the user experiences and links to
the endpoint concept. The `API Endpoint` concept describes the wire contract — method, path,
request shape, response shape, error cases — and links back to the feature(s) that call it. When
the backend contract is still unconfirmed, there is nothing to write: create no `api/` file at all
and record the gap in the feature's Pending work. Do not create an endpoint concept containing a
guessed shape.

**Architecture Pattern vs everything else.** Write one of these only for a pattern that is genuinely
cross-cutting and stable — the Coordinator lifecycle, the `BaseViewModel` unidirectional data flow,
DI registration, the transition system, logging groups. If it describes one feature, it is a
Feature. These files are written once and rarely updated; a change here usually means a
foundational refactor, and the concept should say which features are affected.

**Design Token vs Component.** Tokens are the `ILColors` / `ILTypography` / `ILMetrics` value sets —
one concept per group, mirroring a section of
`InnerLamp/Presentation/Common/DesignSystem/Tokens/DESIGN_SYSTEM.md`. Components are the individual
reusable views (`ILButton`, `ILField`, `ILPhoneField`, …) — one concept per component, listing its
public API and its real call sites so a reader can see who depends on it before changing it.

Note that `DESIGN_SYSTEM.md` §5 documents 9 core components, while `Components/` currently contains
27 `.swift` files — the extra ones were introduced by features (e.g. `ILCheckboxRow`,
`ILStrengthMeterView` came from SignUp). When writing component concepts, cover the component
itself; note in `sources:` that a feature concept documents its origin.

## Section folders

`features/` exists and is populated. `api/`, `domain/`, `architecture/`, and `design-system/` are
declared in `Docs/Knowledge/index.md` under "Planned, not yet populated" and have no files yet.

Create a section folder the first time a concept needs it, then update `index.md` to move that
section out of the planned list and into the active list (`bundle_management.md`). Do not create
empty section folders ahead of need — the planned list in `index.md` is what records the intent.

## One concept per thing

Do not merge two features into one concept, and do not split one feature across several. A concept
that covers "SignUp and OTP" makes both harder to find and makes `resource:` ambiguous. Instead,
write the SignUp concept and link to an `otp` concept; if the OTP concept does not exist yet, the
link stands as a marker (see `bundle_management.md` on dangling links).
