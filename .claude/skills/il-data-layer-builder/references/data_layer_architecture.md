# Data Layer Architecture — What This Skill Builds On

Everything here is grounded in files that already exist in the repo. Read the real sources before
writing anything:

- `InnerLamp/Core/Networking/Endpoint.swift`
- `InnerLamp/Core/Networking/HTTPMethod.swift`
- `InnerLamp/Core/Networking/NetworkService.swift`
- `InnerLamp/Core/Storage/KeychainService.swift`
- `InnerLamp/Core/Storage/UserDefaultsService.swift`
- `InnerLamp/Core/Localization/LocalizationEndpoint.swift` (an existing `Endpoint` conformance)

## 1. The dependency direction

Each layer knows only the layer below it. A violation is nearly always a type crossing a boundary
it shouldn't:

```
ViewModel ── knows ──▶ UseCase ── knows ──▶ Repository (protocol, Domain)
                                                ▲
                                                │ conforms
                       RepositoryImpl (Data) ───┘
                              │ uses
                              ├─▶ NetworkService  (Core, fixed)
                              ├─▶ Endpoint        (Core protocol; conformance file we write)
                              └─▶ Mapper ──▶ DTO  (Data)

Entity (Domain) ── never ──▶ DTO      ← DTO must not appear above the Repository
StateModel (Presentation) ── never ──▶ DTO   ← nor below it
```

**The Repository is the only place a DTO may exist above `NetworkService`.** Its protocol speaks
Entities; its implementation converts at the boundary. If `IL<Feature>DTO` appears in a file under
`Domain/` or `Presentation/`, the boundary has leaked.

## 2. The three types, and why this skill touches only two

`il-screen-builder` already established these (see its `references/data_layer_boundaries.md`).
This skill **adds the DTO and connects it to the Entity — it never touches the StateModel**:

| Type | Layer | File | This skill |
|---|---|---|---|
| `IL<Feature>Entity` | Domain | `Domain/Entities/` | reads it; edits only if the contract proved a business field is missing — and that's a flagged hand-back, not a quiet edit |
| `IL<Feature>StateModel` | Presentation | `Presentation/Scenes/<Feature>/` | **never touched** |
| `IL<Feature>DTO` | Data | `Data/DTOs/` | **created here** |

Entity ↔ StateModel mapping stays in the ViewModel (presentation-specific). Entity ↔ DTO mapping is
the Mapper's job (wire-specific). Both directions of the latter are field-for-field; if the Mapper
needs to drop a field, the source type is wrong.

## 3. Files this skill creates (HTTP variant)

| File | Type | Notes |
|---|---|---|
| `Data/DTOs/IL<Feature>DTO.swift` | `struct IL<Feature>DTO: Codable` | Request and/or response shapes. One type per wire shape; suffix `Request`/`Response` when a feature has both (`ILSignUpSendCodeRequestDTO` / `...ResponseDTO`) and the contract distinguishes them |
| `Data/DTOs/Mappers/IL<Feature>Mapper.swift` | `enum IL<Feature>Mapper` | Static `toDomain` / `toDTO`. An enum because it holds no state — same shape as the existing template from `il-screen-builder` |
| `Data/DataSources/Remote/<Action>Endpoint.swift` | `struct <Action>Endpoint: Endpoint` | See §6 for naming and placement |
| `Domain/Repositories/IL<Feature>Repository.swift` | `protocol IL<Feature>Repository` | `async throws`, Entity in / Entity out |
| `Data/Repositories/IL<Feature>RepositoryImpl.swift` | `final class IL<Feature>RepositoryImpl` | Wraps `NetworkService`, owns the Endpoint + Mapper |

`Data/DTOs/`, `Data/DTOs/Mappers/`, `Data/Repositories/`, `Domain/Repositories/`,
`Data/DataSources/Remote/` and `Data/DataSources/Local/` all already exist and are currently
empty — this skill is what fills them.

## 4. Storage backends — the general rule

Not every "API integration" job is HTTP. A token goes to the Keychain, a "has seen onboarding" flag
goes to `UserDefaults`, a user profile goes to Core Data, and tomorrow it may be SQLite, a file, or
something nobody has picked yet. **Do not enumerate backends here — that list is always incomplete.**
Apply the rule below instead; it does not change when a new backend appears.

### 4.1 The rule

> **The Repository may only depend on an abstraction, never on a concrete storage technology.**

Concretely: `IL<Feature>RepositoryImpl` must be written against a `protocol` it can be handed in its
`init` — not against `NSPersistentContainer`, `SecItem`, `FileManager`, or a `URLSession`. Whether
that protocol already exists is the only question that decides what you write:

| Does an abstraction for this backend already exist? | Where | What this skill does |
|---|---|---|
| **Yes** — a `protocol` in `Core/` or `Data/DataSources/` that hides the technology | `Core/Storage/KeychainService.swift`, `Core/Storage/UserDefaultsService.swift`, `Core/Networking/NetworkService.swift` | Inject it straight into the RepositoryImpl. Nothing new to create. |
| **No** — the feature would otherwise reach a raw framework type directly | e.g. `CoreDataStack` exposes a raw `NSPersistentContainer`; `FileManager`, `SQLite3`, a bare `URLSession` | **Create `IL<Feature><Backend>DataSource` (protocol + Impl) first**, then inject *that* into the RepositoryImpl. |

The second row is the case the old version of this section missed. `CoreDataStack` is a
*lifetime/configuration wrapper* around `NSPersistentContainer` — generic, deliberately ignorant of
any `<Feature>` entity — so it is **not** the abstraction the rule requires. Reaching through it
means the RepositoryImpl itself writes `NSFetchRequest`, owns `@NSManaged` subclasses, and imports
`CoreData`. That is a DataSource's job leaking upward.

**The test, and it is mechanical:** after the RepositoryImpl is written, grep it for the backend's
framework import.

```
grep -n "import CoreData\|import SQLite3\|import Security" \
  InnerLamp/Data/Repositories/IL<Feature>RepositoryImpl.swift
```

A hit means the rule is broken — the technology is named in a type whose only job is to *not* name
it. Split the DataSource out. (Note `import Foundation` is always fine, and `NetworkService` needs
no such check because it already is the abstraction.)

### 4.2 What the DataSource is, and what it is not

| | Repository (`Data/Repositories/`) | DataSource (`Data/DataSources/`) |
|---|---|---|
| Knows | Domain `Entity` + a backend protocol | One storage/transport technology |
| Speaks | `Entity` in, `Entity` out (Domain vocabulary) | `Entity` in, `Entity` out too — but it is the layer that *may* touch `MO`/`DTO` internally |
| Owns | Which source to use, in what order; mapping failures to `IL<Feature>Error` | Queries, transactions, row mapping, framework types |
| Placement | `Data/Repositories/` | `Data/DataSources/Local/` (storage) or `Data/DataSources/Remote/` (HTTP) |

Naming: `IL<Feature><Backend>DataSource` / `...DataSourceImpl` — `ILUserLocalDataSource` for Core
Data, `ILSettingsUserDefaultsDataSource` had it needed a wrapper, and so on. The backend word is
descriptive, not a closed set; `ILUserSQLiteDataSource` is equally valid.

The DataSource is created **when and only when** the backend has no usable abstraction — §4.1's
second row. Do not create one to "be tidy" when `KeychainService` already covers the job: an extra
type with nothing to hide is the abstraction tax with none of the abstraction.

### 4.3 Every backend, worked through the same rule

The point of the rule is that these all resolve identically — none is a special case:

| Backend | Abstraction exists? | Resolution |
|---|---|---|
| Keychain | Yes — `KeychainService` (`Core/Storage/`) | Inject it. Precedent: `ILHomeUseCaseImpl(keychainService:)`. |
| `UserDefaults` | Yes — `UserDefaultsService` (`Core/Storage/`) | Inject it. Precedent: `ILOnboardingUseCaseImpl(userDefaultsService:)`. |
| HTTP / REST | Yes — `NetworkService` (`Core/Networking/`, an `actor`) | Inject it + an `Endpoint` + a DTO/Mapper. §5–§6 below. |
| Core Data | **No** — `CoreDataStack` is a container wrapper, not an entity abstraction | Create `IL<Feature>LocalDataSource` (protocol + Impl) in `Data/DataSources/Local/`; inject it. |
| SQLite / GRDB / Realm | No | Same as Core Data: create `IL<Feature><Backend>DataSource`. |
| Files / `FileManager` | No | Same: create a DataSource protocol wrapping the file operations. |

Read the "abstraction exists" rows' precedent files before writing a new backend against them.
`KeychainService`, `UserDefaultsService`, and `NetworkService` are all **protocols**;
`DIContainer` already exposes `keychainService`, `userDefaultsService`, and `networkService` as
`lazy var`s. Inject those — never instantiate a `...Impl` outside `DIContainer`.

### 4.4 Two or more backends at once

The rule pays for itself here, and this is why it is worth following even for a single-backend
feature. When local + remote both exist, the RepositoryImpl becomes the *only* place that decides
between them, and it does so without naming either technology:

```swift
func loadUser() async throws -> ILUserEntity? {
    if let cached = try localDataSource.fetchUser() { return cached }
    let entity = try await remoteDataSource.fetchUser()
    try localDataSource.saveUser(entity)      // write-through
    return entity
}
```

Cache policy, write-through, fallback-on-offline — all of it lands in this one type, and every
backend stays swappable because the Repository never learned what any of them *are*. Build the
DataSource seam the first time a feature touches a raw framework type, not the second time you need
a second backend: retrofitting it later means rewriting the RepositoryImpl and its tests.

## 5. `NetworkService`'s actual surface

Two methods, both `async throws`, on an `actor`:

```swift
func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> T
func request(endpoint: Endpoint) async throws        // no body — for 204-style responses
```

Use the second one for endpoints whose success response carries nothing the app needs. Do **not**
invent a decodable type just to satisfy the first.

The decoder is configured once in `NetworkServiceImpl.init`:

```swift
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .iso8601
```

**Consequences for the DTO** — do not fight these:

- Server `phone_number` → declare `phoneNumber` in the DTO. Never write `CodingKeys` to undo
  `.convertFromSnakeCase` for a plain snake_case field.
- Dates: `Date` decodes from ISO-8601 strings. If the server sends a Unix timestamp or a
  `yyyy-MM-dd` string, the DTO field must be `Int`/`String` and the Mapper converts — **not** a
  `CodingKeys`/custom decoder in the DTO, which would silently affect every other field.
- Encoding is **not** configured (`JSONEncoder()` defaults): a `Data` body must be produced with
  `try JSONEncoder().encode(...)` using snake_case keys **explicitly** via `CodingKeys` if the
  server expects them on the way out. This is the one asymmetry — decoding is automatic,
  encoding is not. Get this from the contract; don't assume symmetry.

`Endpoint.buildURLRequest()` already sets `Content-Type`/`application/json`,
`Accept: application/json`, and the `X-Session-ID` / `X-Correlation-ID` headers from
`CorrelationContext`. **Do not re-set those in a new Endpoint's `headers`** — only add what's
feature-specific (e.g. an `Authorization: Bearer` the contract requires).

## 6. Endpoint placement and naming

**Placement: `Data/DataSources/Remote/`.** `Core/Networking/` and `Core/Base/` are fixed — this
skill never writes there, even a brand-new file, to keep the "Core is read-only" rule
unambiguous and reviewable.

**Naming: no `IL` prefix, `<Action>Endpoint`.** This is the deliberate exception to the `IL` rule,
and it follows the existing precedent: `LocalizationVersionEndpoint`,
`LocalizationContentEndpoint` (`Core/Localization/LocalizationEndpoint.swift`) — unprefixed,
named for the action, not the feature. So for SignUp's send-code call:
`SendVerificationCodeEndpoint`, not `ILSignUpEndpoint` and not `ILSignUpSendCodeEndpoint`.

Rationale: an Endpoint is a description of one server call, not a feature scene type; and prefixing
would make the file look like it belongs to the feature's Domain/Presentation set.

One Endpoint struct per server call, each a `struct` with `let` params (see the existing
`LocalizationVersionEndpoint` for the exact shape — `baseURL`, `path`, `method`, plus optional
`headers` / `queryParameters` / `body`).

**`baseURL` for business APIs is always `APIConfig.serverBaseURL`** (`Core/Networking/APIConfig.swift`)
— never a literal string, never `LocalizationConfig.serverBaseURL`, never a new feature-local config
type. `APIConfig` is the single host for everything under `Domain/`/`Data/` (auth, signup, home,
...), and it already switches on `APIConfig.Environment` (`.dev` / `.staging` / `.production`).
Endpoints outside that set (localization's i18n host, logging's risk/metrics/analytics hosts) keep
their own existing config — don't migrate them, and don't reuse them.

So the `baseURL` line is mechanical:

```swift
struct SendVerificationCodeEndpoint: Endpoint {
    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/auth/signup/send-code" }
    var method: HTTPMethod { .post }
}
```

**Stop condition:** if `APIConfig` does not exist (or is missing the environment you need), stop
and report it — do **not** create it (it lives under `Core/`, which this skill never writes to) and
do **not** substitute another config's host. `APIConfig` was added 2026-09-15 with mock URLs;
its real URLs are still a `TODO`, exactly like `LocalizationConfig.serverBaseURL`.

## 7. Async and error shape

Everything below the ViewModel is `async throws`:

```swift
protocol IL<Feature>Repository {
    func sendVerificationCode(_ entity: IL<Feature>Entity) async throws
}

final class IL<Feature>RepositoryImpl: IL<Feature>Repository {
    private let networkService: NetworkService
    init(networkService: NetworkService) { self.networkService = networkService }

    func sendVerificationCode(_ entity: IL<Feature>Entity) async throws {
        let dto = IL<Feature>Mapper.toDTO(entity)
        do {
            try await networkService.request(endpoint: SendVerificationCodeEndpoint(body: dto))
        } catch let error as NetworkError {
            throw IL<Feature>Error.from(error)          // see references/error_mapping.md
        }
    }
}
```

The `IL<Feature>UseCaseImpl` method keeps the signature `il-screen-builder` generated
(`async throws`, same labels) — the ViewModel already calls it, and this skill does not get to
change that contract.
