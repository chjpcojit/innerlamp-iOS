# Naming and Placement

Extends `ui-builder`'s `references/naming_conventions.md`, which already establishes the
`IL` prefix rule and the folder-decides-scope rule. Read that first; this file only covers what the
Data layer adds.

## 1. The `IL` rule, applied to this skill's output

Every type and file this skill creates carries `IL`, **except the Endpoint** (§4):

| File | Type |
|---|---|
| `Data/DTOs/IL<Feature>DTO.swift` | `struct IL<Feature>DTO` (or `IL<Feature><Action>RequestDTO` / `...ResponseDTO`, §3) |
| `Data/DTOs/Mappers/IL<Feature>Mapper.swift` | `enum IL<Feature>Mapper` |
| `Domain/Repositories/IL<Feature>Repository.swift` | `protocol IL<Feature>Repository` |
| `Data/Repositories/IL<Feature>RepositoryImpl.swift` | `final class IL<Feature>RepositoryImpl` |
| (in the existing UseCase file) | `enum IL<Feature>Error` — declared here, not in a new file |

`DIContainer` factory **methods** stay feature-name-only, no `IL` — same rule as the rest of the
project: `make<Feature>Repository()`, returning `IL<Feature>Repository`. The prefix is for types and
filenames, never for method names.

## 2. Folders — all of these already exist and are currently empty

```
InnerLamp/
  Domain/Repositories/            ← protocol
  Data/Repositories/              ← implementation
  Data/DTOs/                      ← DTO
  Data/DTOs/Mappers/              ← Mapper
  Data/DataSources/Remote/        ← Endpoint conformance (§4)
  Data/DataSources/Local/         ← local-storage wrapper; see data_layer_architecture.md §4 for when it is needed
```

Do not create a parallel structure (`Networking/`, `API/`, `Services/`). If a file doesn't obviously
belong in one of the above, it probably belongs in an existing folder — check before inventing one.

**Xcode project membership.** The project uses synchronized folder groups
(`PBXFileSystemSynchronizedRootGroup`), so a new `.swift` file placed under `InnerLamp/` is picked up
automatically — no `project.pbxproj` edit needed for the files this skill creates. Confirm with a
build rather than assuming. (The one pbxproj exception in this repo is for `README.md`
filename collisions between scenes — this skill does not create READMEs, so it does not apply here.)

Files under `InnerLampTests/` are likewise picked up automatically.

## 3. DTO naming — one type per wire shape

The contract distinguishes a request from a response → two types, suffixed:

```swift
struct ILSignUpSendCodeRequestDTO: Encodable   { ... }
struct ILSignUpSendCodeResponseDTO: Decodable  { ... }
```

A single shape used both ways → one type, no suffix: `struct ILSignUpDTO: Codable`.

**Prefer splitting them.** A response is `Decodable`-only and a request is `Encodable`-only, and
splitting is what lets the response rely on `.convertFromSnakeCase` while the request declares
explicit snake_case `CodingKeys` — the two can't coexist on one type (§5).

## 4. Endpoint — the one unprefixed type

**Naming: `struct <Action>Endpoint`, no `IL`.** Follows the existing precedent in
`Core/Localization/LocalizationEndpoint.swift` (`LocalizationVersionEndpoint`,
`LocalizationContentEndpoint`).

```swift
struct SendVerificationCodeEndpoint: Endpoint { ... }   // ✅
struct ILSignUpEndpoint: Endpoint { ... }               // ❌ feature-scoped, not action-scoped
struct ILSignUpSendCodeEndpoint: Endpoint { ... }       // ❌
```

Reasoning: an Endpoint describes *one server call*, not a feature scene type. Putting `IL<Feature>`
on it would make it look like part of the feature's Domain/Presentation set and invite someone to
start adding `IL<Feature>RepositoryEndpoint`-style types.

**Placement: `Data/DataSources/Remote/`, not `Core/Networking/`.** `Core/` is read-only for this
skill (`SKILL.md` hard rule 4) — including a brand-new file. Keeping every file this skill writes
out of `Core/` makes that rule reviewable at a glance: *no diff under `Core/`* is the check.

One `struct` per server call, `let` params, one `Endpoint` conformance each. Two calls to the same
path with different bodies are still two types.

## 5. A trap: `CodingKeys` vs `.convertFromSnakeCase`

The shared decoder uses `.keyDecodingStrategy = .convertFromSnakeCase`; the encoder is a default
`JSONEncoder()` with **no** strategy. So decoding and encoding are asymmetric, and a single type
cannot have it both ways:

- Declaring `CodingKeys` with raw values like `case phoneNumber = "phone_number"` **breaks decoding**,
  because the decoder rewrites the incoming key to `phoneNumber` and then looks for a `CodingKey`
  whose raw value is `phoneNumber` — which no longer exists.
- Omitting `CodingKeys` **breaks encoding** a snake_case body, because `JSONEncoder` writes
  `phoneNumber` verbatim.

Split the types (§3): the **Response** DTO declares camelCase properties and no `CodingKeys`
(automatic decoding works); the **Request** DTO declares explicit snake_case `CodingKeys` (encoding
works, and its decoding behaviour is irrelevant since nothing decodes it).

If a feature genuinely needs one type for both directions, that is a stop-and-ask — it means either
a custom encoder in the RepositoryImpl or a Core change, and neither is a silent choice.

## 6. Localization keys

The project uses its own JSON system, **not** Apple's String Catalog:
`InnerLamp/Resources/Localization/vi.json`, read via `"key".localized`
(`Core/Localization/String+Localized.swift`).

Key shape, matching what's already in `vi.json`:

```
<featureLower>.<area>.<name>
```

- `signup.error.phoneTaken` — a feature error message
- `signup.error.displayNameRequired` — a validation message
- `error.no_internet`, `error.generic` — shared; reuse rather than duplicating

Rules:

- **Every** user-facing string goes through `"key".localized`. Never a bare literal in an
  `errorDescription` or a caught-error path.
- Add each new key to `vi.json` in the feature's existing block, next to the keys
  `ui-builder` already added for that feature.
- Vietnamese, real diacritics. No `"TODO"`, no English placeholder, no untranslated leftover.
- A key referenced in Swift but missing from `vi.json` renders as the key itself in the UI — treat
  that as a bug, and check the pair before reporting done.
