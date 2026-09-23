# Entity vs. StateModel vs. DTO — and What This Skill Implements vs. Stubs

This is a hard architectural boundary for every feature this skill generates. Read this before
filling in any `TODO` in the generated files.

## The three types, never merged

| Type | File | Layer | Contains |
|---|---|---|---|
| `IL{{Feature}}Entity` | `Domain/Entities/IL{{Feature}}Entity.swift` | Domain | Only fields with real business meaning — what the server/local storage actually cares about. |
| `IL{{Feature}}StateModel` | `Presentation/Scenes/{{Feature}}/IL{{Feature}}StateModel.swift` | Presentation | Everything the `ViewController` needs to render: raw input mirrors (may be invalid mid-edit), `*Error: String?` fields, `isSubmitting`/`isVerifying`/loading flags, computed display-only formatting (hints, masks, `.localized` strings). Owned and mutated exclusively by `IL{{Feature}}ViewModel`. |
| `IL{{Feature}}DTO` | `Data/DTOs/IL{{Feature}}DTO.swift` | Data | Wire format matching the confirmed server request/response contract field-for-field. Only generate this (+ its mapper) if the feature has an actual, user-confirmed API contract — skip both otherwise. |

**Never put UI-only fields on `IL{{Feature}}Entity`.** If you catch yourself adding `*Error`,
`isSubmitting`, `isLoading`, `isPasswordVisible`, a `.localized` string, or any field that only
exists to drive a specific screen's look — it belongs on `IL{{Feature}}StateModel` instead.
**Never put persistence/wire-format fields on `IL{{Feature}}StateModel`** that don't already
exist on the Entity — the StateModel describes a screen, not a payload.

## Mapping rules

- `IL{{Feature}}Mapper` (`Data/DTOs/Mappers/IL{{Feature}}Mapper.swift`, generated only alongside
  a DTO) converts **only** `Entity <-> DTO`, field-for-field. It never sees `StateModel`.
- `IL{{Feature}}ViewModel` converts `Entity <-> StateModel` itself, with a small private helper
  (e.g. `private func applyEntity(_ entity: IL{{Feature}}Entity)` mutating `currentState`) —
  this mapping is presentation-specific (formatting, defaults, which fields are even shown) and
  belongs with the ViewModel, not in a shared mapper type.
- If a mapper ever needs to silently drop or ignore a field on either side, that's a signal a
  UI-only field leaked into the Entity, or a business field is missing from the DTO/StateModel —
  fix the source type instead of working around it in the mapper.

## What this skill implements vs. stubs (hard boundary)

This skill must never write the real implementation of:

- Any `NetworkService`/`Endpoint` call (`Core/Networking/NetworkService.swift`).
- Any local Repository call — Core Data, Keychain-, or UserDefaults-backed persistence.

Every `UseCase` method whose real implementation would need one of the above is generated as a
**stub only**: keep the method signature (`async throws`), reduce the body to exactly one line
printing a TODO, and nothing else:

```swift
func handleAction() async throws {
    print("TODO: implement handleAction — network/repository call, not built by il-screen-builder")
}
```

Never fabricate a response, never throw a made-up error, never invent an `Endpoint` case, path,
or field that wasn't given by the user or doesn't already exist in the codebase.

**What IS in scope and must be genuinely implemented (never stubbed):**

- Simple, pure client-side validation the device can compute with no network/disk I/O — phone
  number format/length checks, password strength/length rules, required-field/non-empty checks,
  matching-fields checks (e.g. confirm-password == password), and similar. These go on
  `IL{{Feature}}UseCase` (or as a `private` helper on the ViewModel if truly trivial) as real,
  working logic — not `// TODO`.
- The pure data transforms described above: `Entity <-> StateModel` in the ViewModel,
  `Entity <-> DTO` in the Mapper.

**Rule of thumb:** if implementing something for real would require the device to talk to the
network or read/write persistent storage, it is out of scope — stub it with the one-line TODO
print and move on. If it's a pure computation over values already in memory, it's in scope —
implement it for real.
