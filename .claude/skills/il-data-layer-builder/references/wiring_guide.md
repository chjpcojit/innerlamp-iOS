# Wiring the Data Layer into `DIContainer` and the UseCase

Two edits, both small, both in files that already exist. Everything else this skill does is a new
file.

## 1. `InnerLamp/App/DIContainer.swift` — add the repository factory, inject it

Inside the feature's existing `// MARK: - <Feature>` section, add a repository factory and thread it
into the UseCase factory. Keep factory method names unprefixed; return types carry `IL`.

**Before** (what `il-screen-builder` left):

```swift
// MARK: - SignUp
func makeSignUpUseCase() -> ILSignUpUseCase {
    ILSignUpUseCaseImpl()
}
```

**After:**

```swift
// MARK: - SignUp
func makeSignUpRepository() -> ILSignUpRepository {
    ILSignUpRepositoryImpl(networkService: networkService)
}

func makeSignUpUseCase() -> ILSignUpUseCase {
    ILSignUpUseCaseImpl(repository: makeSignUpRepository())
}
```

`networkService` / `keychainService` / `userDefaultsService` are already `lazy var`s on
`DIContainer` (§Core Services) — pass the protocol-typed property, never a fresh `...Impl()`.

**Local-storage variant** — same shape, different dependency:

```swift
func makeSignUpRepository() -> ILSignUpRepository {
    ILSignUpRepositoryImpl(keychainService: keychainService)
}
```

The ViewModel and Coordinator factories are **unchanged** — this skill does not touch them.

## 2. `Domain/UseCases/<Feature>/IL<Feature>UseCase.swift` — inject + replace the stub

This is the only edit this skill makes to an `il-screen-builder`-generated file.

**Before:**

```swift
final class ILSignUpUseCaseImpl: ILSignUpUseCase {

    // TODO: inject NetworkService/Repository thật (KeychainService/UserDefaultsService...) khi
    // implement `sendVerificationCode` thật — không inject sẵn ở đây vì hiện chưa có logic thật
    // nào trong file này cần dùng tới, xem `references/data_layer_boundaries.md`.
    init() {}

    // ...

    func sendVerificationCode(displayName: String, phoneNumber: String, password: String) async throws {
        print("TODO: implement sendVerificationCode — network/repository call, not built by il-screen-builder")
    }
}
```

**After:**

```swift
final class ILSignUpUseCaseImpl: ILSignUpUseCase {

    private let repository: ILSignUpRepository

    init(repository: ILSignUpRepository) {
        self.repository = repository
    }

    // ... unchanged validation methods ...

    func sendVerificationCode(displayName: String, phoneNumber: String, password: String) async throws {
        let entity = ILSignUpEntity(
            displayName: displayName,
            phoneNumber: phoneNumber,
            password: password
        )
        try await repository.sendVerificationCode(entity)
    }
}
```

Rules:

- **Delete the `// TODO: inject ...` comment.** It is satisfied now; leaving it makes the next reader
  think the wiring is still pending.
- **The signature does not change.** Same `async throws`, same labels, same parameter types — the
  ViewModel already calls it and this skill does not own that contract.
- **No `print("TODO:` remains anywhere** in the file after this pass.
- **Do not add behaviour.** No retries, no caching, no logging side-effects, no "while I'm here"
  refactor of the validation methods. This edit is mechanical.
- If the UseCase has several stubbed methods, each one is the same pattern; if they share a
  repository, one property covers all of them.

## 3. Nothing else instantiates anything

`IL<Feature>RepositoryImpl` is constructed **only** in `DIContainer`. Grep before finishing:

```
grep -rn "RepositoryImpl(" InnerLamp/ --include="*.swift"
```

Every hit must be a `DIContainer` factory. A `...Impl()` inside a ViewModel, a test, or another
Repository is a wiring bug.

## 4. Endpoint and DTO are internal to the Data layer

`IL<Feature>DTO`, `IL<Feature>Mapper`, and `<Action>Endpoint` are never referenced from
`DIContainer`, from a UseCase, or from anywhere in `Domain/`/`Presentation/`. Only
`IL<Feature>RepositoryImpl` knows they exist. Grep to confirm:

```
grep -rn "<Feature>DTO\|<Feature>Mapper\|Endpoint" InnerLamp/Domain InnerLamp/Presentation --include="*.swift"
```

Expected: zero hits (the Endpoint's own file under `Data/DataSources/Remote/` is not in those paths).

## 5. Pre-flight and verification checklist

**Before writing anything** — all must hold, or stop and report
(`references/contract_requirements.md`):

- [ ] `Docs/Specs/<Feature>/` exists with the three spec files
- [ ] The contract is confirmed: method + path, request fields + types, success shape, every named
      failure case with its discriminator, auth requirement, encoding quirks
- [ ] No `⚠️ Not confirmed` marker covers the contract being implemented
- [ ] The stub exists in `IL<Feature>UseCaseImpl` (if already implemented, there is nothing to do)
- [ ] `IL<Feature>Entity` exists with the business fields the DTO maps to
- [ ] The base URL is known. Read it from `Core/Networking/APIConfig.swift` —
      `APIConfig.serverBaseURL`, the shared app-wide host every feature's Endpoint uses. Never
      introduce a per-feature config constant, and never borrow
      `Core/Localization/LocalizationConfig.swift`'s value: that is a separate feature-local mock
      (`https://mock-i18n.internal.innerlamp.app`) for the localization service only.
      **If `APIConfig.serverBaseURL` still returns a `mock-*` host**, the contract may be confirmed
      but the real backend isn't reachable — say so explicitly in your report and confirm with the
      user before implementing against the mock host, rather than treating it as production-ready.
      If `APIConfig` itself is missing, that is a stop-and-ask, not a constant to invent

**Before reporting done:**

- [ ] `xcodebuild build` passes, and `xcodebuild test` passes — report the real output, including
      failures; never summarise as "done" on an unverified build
- [ ] No file under `InnerLamp/Core/` was modified (`git status` — zero `Core/` entries)
- [ ] No `print("TODO:` left in `IL<Feature>UseCaseImpl`; the "inject ... later" comment is gone
- [ ] `IL<Feature>RepositoryImpl` is constructed only in `DIContainer`
- [ ] No `DTO`/`Mapper`/`Endpoint` reference anywhere under `Domain/` or `Presentation/`
- [ ] Every field in the DTO traces to the confirmed contract — none invented, none dropped
- [ ] Every new user-facing string is a `"key".localized` call whose key exists in `vi.json`
- [ ] Every new type/file follows `references/naming_and_placement.md` (the Endpoint stays
      unprefixed and lives in `Data/DataSources/Remote/`)
- [ ] `references/testing_guide.md`'s coverage list is satisfied and the tests actually run
- [ ] `tasks.md` checkboxes ticked only for work genuinely completed this run
- [ ] `changelog.md` has an entry; version headers in sync (`references/spec_ownership.md`)
