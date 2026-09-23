---
name: il-data-layer-builder
description: This skill should be used when a feature's Presentation/Domain layers already exist (built by il-screen-builder) but its API integration is still a stub — i.e. an `IL<Feature>UseCase` method whose body is a one-line `print("TODO: ...")` because it needs a network call. It takes a feature from stub to real Data layer: creates `IL<Feature>DTO` + `IL<Feature>Mapper` (Data), the `<Action>Endpoint` conformance (`Data/DataSources/Remote/`), the `IL<Feature>Repository` protocol (Domain/Repositories) + `IL<Feature>RepositoryImpl` (Data/Repositories), injects that Repository into `IL<Feature>UseCaseImpl.init`, replaces the stub body with the real call, maps `NetworkError` (and any local-storage failure) to feature-specific `IL<Feature>Error` cases, and updates the unit tests to mock the Repository instead of the UseCase. It reads the confirmed API contract out of `Docs/Specs/<Feature>/design.md`'s Step-by-step Flow section and refuses to run without one — it never invents an endpoint path, request/response field, or error case. It is allowed to tick the API-integration checkboxes in `Docs/Specs/<Feature>/tasks.md` and append an implementation entry to `changelog.md`, but never to edit the prose of `requirements.md`/`design.md` (if the design turns out to be wrong, it stops and hands back to `il-spec-writer`). It never writes UI, ViewModel, Coordinator, or Entity/StateModel code — that is `il-screen-builder`'s job.
---

# InnerLamp Data Layer Builder

## Overview

`il-screen-builder` builds a feature up to the **UseCase** layer and stops: any method whose real
implementation would need to talk to the network or to persistent storage is generated as a
one-line-TODO stub, by design (see its `references/data_layer_boundaries.md`). `il-spec-writer`
writes the spec that says what that stub should eventually do. **This skill is the missing third
step — it turns the stub into a real, tested implementation.**

It generates, in this order (each layer only knowing about the one below it):

```
IL<Feature>ViewController / ViewModel / Coordinator      ← already exists (il-screen-builder)
        │
IL<Feature>UseCase                                       ← exists, but the API method is a stub
        │  (this skill: replace the stub body, inject the repository)
IL<Feature>Repository (protocol, Domain/Repositories)    ← this skill
        │
IL<Feature>RepositoryImpl (Data/Repositories)            ← this skill
        │  (wraps NetworkService; maps DTO ↔ Entity via IL<Feature>Mapper)
IL<Feature>DTO + IL<Feature>Mapper (Data/DTOs)           ← this skill
        │
<Action>Endpoint → NetworkService (Core/Networking)      ← this skill creates the Endpoint only
```

Everything under `InnerLamp/Core/` (`Networking/`, `Base/`, `Storage/`, `Logging/`,
`Localization/`) is **fixed infrastructure — read only, never edit.** This skill writes new
`Endpoint` conformance *files* that adopt the existing `Endpoint` protocol; it never modifies the
protocol itself, `NetworkService`, or `HTTPMethod`.

## Hard rules that override everything else below

1. **No confirmed contract → refuse to run.** Every field, path, and error case this skill writes
   must come from a contract the user has actually given, or that already exists in the codebase.
   If `design.md` still carries a `⚠️ Not confirmed` marker (or no `design.md` exists at all),
   stop and report what is missing — do not proceed with a plausible-looking guess. See
   `references/contract_requirements.md`.
2. **Never edit `requirements.md` or `design.md`.** Those belong to `il-spec-writer`. If
   implementing the contract reveals the design is wrong (a field the server doesn't actually
   return, a step missing from the flow), **stop, do not work around it in code**, and report the
   discrepancy so the user can run `il-spec-writer` to correct the design first.
   *Single, narrow exception:* the `Version`/`Last updated`/`Status` header lines of those two
   files may be synced mechanically when this skill bumps the spec version — never a line of prose.
3. **`tasks.md` checkboxes may be ticked; `changelog.md` may be appended to.** This skill is the one
   that actually implemented the work, so it is the honest place to record it. See
   `references/spec_ownership.md` for the exact rules on both.
4. **Never touch any file under `InnerLamp/Core/`.** If `NetworkService`/`Endpoint`/`HTTPMethod`
   genuinely lacks something this feature needs (e.g. multipart encoding, a retry policy), that is
   a **stop-and-ask** — a Core change is a separate, explicitly-requested piece of work, never a
   side effect of adding a feature.
5. **The three types stay separate.** `IL<Feature>DTO` (wire format, Data)
   → `IL<Feature>Entity` (Domain) via `IL<Feature>Mapper`; never let a DTO escape the Repository,
   and never let the Mapper see a `StateModel`. See
   `references/data_layer_architecture.md`.
6. **No invented user-facing text.** Every error message surfaced to the user goes through
   `"key".localized` and its key is added to
   `InnerLamp/Resources/Localization/vi.json` — the project's own JSON system, not Apple's String
   Catalog. See `references/naming_and_placement.md`.
7. **Every new type and file starts with `IL`** (Repository, RepositoryImpl, DTO, Mapper, error
   enum). The `Endpoint` conformance is the one exception — see
   `references/naming_and_placement.md` §4.

## Reference map

Read these as needed — don't load all upfront if the task is narrow.

| Reference | Covers |
|---|---|
| `references/contract_requirements.md` | **Read first.** What counts as a "confirmed contract", where to read it from in `design.md`, and the exact stop conditions |
| `references/data_layer_architecture.md` | The Repository boundary, the three-type split (DTO/Entity/StateModel), where each file lives, async/`throws` shapes, and the `NetworkService` API surface this skill builds on |
| `references/error_mapping.md` | Mapping `NetworkError` → `IL<Feature>Error` cases, what counts as a user-facing message, and the `LocalizedError` shape |
| `references/naming_and_placement.md` | File/type naming (`IL`, and the `Endpoint` exception), folder placement, localization key conventions |
| `references/wiring_guide.md` | `DIContainer` injection, the `IL<Feature>UseCaseImpl.init` change, and the full pre-flight/verification checklist |
| `references/testing_guide.md` | Writing `MockIL<Feature>Repository`, rewriting the existing `ViewModelTests` to mock the Repository instead of the UseCase, and what must be covered |
| `references/spec_ownership.md` | Exactly what may be written to `Docs/Specs/<Feature>/` — checkbox ticking, changelog entry format, version bump, the header-only exception |

## Workflow

### 1. Pre-flight — confirm the work is actually ready

Do not generate anything until all of these hold (report any that don't, and stop):

1. **A spec exists**: `Docs/Specs/<Feature>/` with `requirements.md`, `design.md`, `tasks.md`.
2. **A confirmed contract exists**: `design.md` names the concrete endpoint (method + path), the
   request fields, the success response shape, and the named failure cases — with **no
   `⚠️ Not confirmed` marker** on any of them. Read `references/contract_requirements.md` for the
   exact bar; the SignUp spec's Phase 3 items are the canonical example of the *unconfirmed* state,
   which is a stop, not a green light.
3. **The stub exists**: locate the real `IL<Feature>UseCaseImpl` method(s) still carrying the
   `print("TODO: ...")` body. If the method is already implemented, there is nothing to do —
   tell the user instead of rewriting working code.
4. **The Entity exists**: `IL<Feature>Entity` in `Domain/Entities/`, with the business fields the
   DTO must map to. If the contract needs a business field the Entity doesn't have, that is an
   `il-screen-builder` change (Domain is its layer) — flag it rather than quietly widening the
   Entity here.
5. **`Int`/`String`/date shapes of the wire format are known** — in particular whether the server
   returns snake_case (the shared `JSONDecoder` uses `.convertFromSnakeCase` — see
   `references/data_layer_architecture.md` §5) and whether dates are ISO-8601.
6. **A host to point at exists**: every `Endpoint` needs a `baseURL`. Read it from
   `Core/Networking/APIConfig.swift` (`APIConfig.serverBaseURL`). If no such config holds the
   feature's host, that is a **stop** — never fall back to another subsystem's config (e.g.
   `LocalizationConfig.serverBaseURL` points at the i18n mock host, not the API), and never invent
   a host. Report it as missing infrastructure, per `references/contract_requirements.md`.
   Related, and also a stop rather than something to work around: if the contract requires an
   `Authorization` header and nothing in the codebase yet reads a token out of `KeychainService`
   into a request, that auth plumbing does not exist yet — say so instead of hand-rolling it.

Then state the plan back in one short block (files to create, files to edit, tests to update)
before writing code.

### 2. Generate the Data layer, bottom-up

Copy each file in `assets/templates/`, replacing `{{Feature}}` (PascalCase) and `{{featureLower}}`
as applicable, then fill in real content from the confirmed contract — **no placeholder left
behind, and no field that isn't in the contract**:

| Template | Destination |
|---|---|
| `assets/templates/DTO.swift.template` | `InnerLamp/Data/DTOs/IL{{Feature}}DTO.swift` — request and/or response shapes, matching the wire format name-for-name (typed for the `.convertFromSnakeCase` decoder) |
| `assets/templates/Mapper.swift.template` | `InnerLamp/Data/DTOs/Mappers/IL{{Feature}}Mapper.swift` — `Entity <-> DTO` only, field-for-field |
| `assets/templates/Endpoint.swift.template` | `InnerLamp/Core/Networking/` is read-only — place the conformance in `InnerLamp/Data/DataSources/Remote/` instead (see `references/naming_and_placement.md` §4 for why) |
| `assets/templates/Repository.swift.template` | `InnerLamp/Domain/Repositories/IL{{Feature}}Repository.swift` — protocol only, `async throws`, expressed in **Domain** terms (Entity in/out), never DTO |
| `assets/templates/RepositoryImpl.swift.template` | `InnerLamp/Data/Repositories/IL{{Feature}}RepositoryImpl.swift` — wraps `NetworkService`, owns the Endpoint + Mapper, maps transport errors |
| `assets/templates/DataSource.swift.template` | `InnerLamp/Data/DataSources/Local/IL{{Feature}}{{Backend}}DataSource.swift` — **only when §4.1's rule says the backend has no abstraction yet.** Protocol + Impl; owns the framework types and the transaction so the RepositoryImpl never imports them |
| `assets/templates/MockRepository.swift.template` | appended to the feature's existing `InnerLampTests/IL{{Feature}}ViewModelTests.swift` (not a separate file) — see `references/testing_guide.md` |

**When the job is storage rather than HTTP**, do not reach for a list of known backends — that list
is always incomplete. Apply the rule in `references/data_layer_architecture.md` §4 instead, which
turns on one question: **does an abstraction for this backend already exist?**

- **Yes** (`KeychainService`, `UserDefaultsService`, `NetworkService` — all protocols in `Core/`)
  → inject it into the RepositoryImpl and skip the DTO/Mapper/Endpoint rows above; the stored type
  *is* the wire format.
- **No** (Core Data through `CoreDataStack`, SQLite, `FileManager`, a bare `URLSession`, or anything
  not yet invented) → **create the DataSource first**, using
  `assets/templates/DataSource.swift.template`, and inject that. `CoreDataStack` is a container
  wrapper, not an entity abstraction — reaching through it puts `NSFetchRequest`, `@NSManaged`
  subclasses and `import CoreData` inside the RepositoryImpl, which is the violation the rule exists
  to catch.

The mechanical check: after writing the RepositoryImpl, grep it for the backend's framework import
(`import CoreData`, `import SQLite3`, ...). A hit means the split is owed.

### 3. Wire the UseCase

This is the only edit this skill makes to an `il-screen-builder`-generated file:

1. Add the Repository dependency to `IL<Feature>UseCaseImpl.init` — and **remove the
   `// TODO: inject NetworkService/Repository...` comment left there**, since it is now satisfied.
2. Replace the stub body with the real call, keeping the exact signature (`async throws`, same
   parameter labels/types — the ViewModel already depends on it).
3. Wrap the repository call in the feature's error mapping (`references/error_mapping.md`) so the
   ViewModel's existing `catch IL<Feature>Error.xxx` branches keep working. **If the ViewModel
   already switches on a specific error case, that case's behaviour must not change** — if it
   must, that's a `design.md`/ViewModel change, i.e. stop and hand back.
4. Update `DIContainer.make{{Feature}}UseCase()` to pass the new dependency, adding a
   `make{{Feature}}Repository()` factory in the feature's `// MARK:` section. See
   `references/wiring_guide.md`.

### 4. Update the tests

Follow `references/testing_guide.md` exactly:

- Add `MockIL<Feature>Repository` (conforming to the new protocol) at the bottom of
  `InnerLampTests/IL<Feature>ViewModelTests.swift`, replacing the old
  `MockIL<Feature>UseCase`'s network-path responsibility. Keep the UseCase mock only if the
  ViewModel tests still exercise pure-validation paths through it — otherwise the tests should now
  construct the **real** `IL<Feature>UseCaseImpl` with the mock repository injected, which is the
  point of the change.
- Keep every existing test passing. A test that asserted "the stub was called" and nothing else is
  now testing nothing — replace it with real success/failure-path assertions.
- Cover, at minimum: success, each named failure case from the contract, and the
  `NetworkError` → `IL<Feature>Error` mapping for at least no-internet and server-error.

### 5. Update the spec folder (narrowly)

Per `references/spec_ownership.md`: tick the API-integration items in `tasks.md` that this run
genuinely completed, mark `requirements.md`/`design.md`'s Status line if it is now stale, append a
`changelog.md` entry, and bump the shared version across the three headers (header lines only —
never prose). Items not actually done stay `[ ]`.

### 6. Verify before reporting done

- [ ] Build passes, and the full test suite passes (`xcodebuild test`) — report the real result,
      including failures, never a summary that assumes success
- [ ] Every field written into the DTO exists in the confirmed contract — no field invented, none
      silently dropped
- [ ] `IL{{Feature}}Mapper` maps `Entity <-> DTO` only; it never references
      `IL{{Feature}}StateModel`
- [ ] `IL{{Feature}}Repository` (Domain) is expressed in Entities; no `DTO` type appears anywhere
      under `Domain/` or `Presentation/`
- [ ] No file under `InnerLamp/Core/` was modified
- [ ] `IL{{Feature}}UseCaseImpl` no longer contains a `print("TODO:` body, and its `init` no longer
      carries the "inject ... later" TODO comment
- [ ] Every user-facing message is a `"key".localized` string with its key present in
      `vi.json` (see `references/error_mapping.md` §3)
- [ ] Every new type/file follows `references/naming_and_placement.md` (including the `Endpoint`
      naming exception, and the `.`-prefixed `PBXFileSystemSynchronized` note if a new folder was
      created)
- [ ] `DIContainer` injects the Repository; no `UseCase`/`Repository` is instantiated anywhere
      outside `DIContainer`
- [ ] `tasks.md` checkboxes reflect only what was actually completed
- [ ] A `changelog.md` entry exists for this change, and the version headers are in sync
