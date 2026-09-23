# Testing the Real Path

Updating the tests is not a chore at the end of this skill — it is the point of it. Before this
skill runs, `IL<Feature>ViewModelTests` mocks `IL<Feature>UseCase`, which means the network path is
mocked at the *highest* possible level and nothing about the real integration is covered. After
this skill runs, the mock sits one layer lower, and the real `UseCase` + real `Mapper` are
exercised for the first time.

## 1. Why the mock moves down a layer

| | Before | After |
|---|---|---|
| `sut` built with | `MockIL<Feature>UseCase` | real `IL<Feature>UseCaseImpl(repository: mockRepository)` |
| Mocker conforms to | `IL<Feature>UseCase` | `IL<Feature>Repository` |
| Covered | ViewModel ↔ UseCase interaction | ViewModel ↔ UseCase ↔ Repository, including the real mapper and the real error mapping |

Do **not** keep both mocks and wire one to the other — that tests nothing but the mocks.

## 2. Where the code goes

`MockIL<Feature>Repository` is appended to the **bottom of the feature's existing test file**,
`InnerLampTests/IL<Feature>ViewModelTests.swift`, in the same position the old
`MockIL<Feature>UseCase` occupied — under a `// MARK: - Mock IL<Feature>Repository` heading. It is
not a separate file: the project's existing convention is one test file per feature with its mocks
inline (see `ILSignUpViewModelTests.swift`).

Use `assets/templates/MockRepository.swift.template` for the shape.

## 3. What changes in `setUp`

Only the construction of `sut` changes; the subject wiring (`viewDidLoadSubject`,
`makeOutput()`, `cancellables`) stays exactly as it was:

```swift
override func setUp() {
    super.setUp()
    mockRepository = MockIL<Feature>Repository()
    // Real UseCase, fake Repository — this is the whole point of the change.
    sut = IL<Feature>ViewModel(useCase: IL<Feature>UseCaseImpl(repository: mockRepository))
    cancellables = []
    // ... subjects unchanged
}
```

## 4. Keeping the existing tests honest

Every test that passes today must still pass, but some of them stop meaning anything:

- A test asserting **the UseCase was called** still works (the real `UseCaseImpl` forwards to the
  mock repository) — but its assertion should move to `mockRepository.<method>Called` and the
  captured arguments, so it now proves the value actually reached the data layer.
- A test whose only assertion was that a stub ran is now vacuous — replace it with real
  success/failure-path assertions.
- **Validation-only tests** (submit with a short phone number, etc.) now run through the *real*
  validation logic instead of the mock's. This is a genuine improvement, with one trap: the mock
  returned short strings like `"required"`, while the real `UseCaseImpl` returns
  `"signup.error.phoneRequired".localized`. Rewrite those assertions to check `!= nil` /
  `== nil` rather than an exact string — otherwise the test couples itself to the localization
  file and breaks on every copy change.
- Tests that never touched the network (roll the dharma name, toggle a checkbox) are unaffected —
  leave them alone.

## 5. Minimum coverage this skill must leave behind

For each method it implemented:

- [ ] **Success** — repository returns/doesn't throw → the ViewModel's success branch runs, with
      its navigation event or state change asserted.
- [ ] **Each named failure** from the confirmed contract (e.g. `phoneAlreadyRegistered`) →
      the ViewModel's existing `catch IL<Feature>Error.<case>` branch fires, unchanged.
- [ ] **No internet** — repository throws `IL<Feature>Error.noInternetConnection` → the generic
      error branch surfaces a user-facing message and does **not** navigate.
- [ ] **Server error** — repository throws `IL<Feature>Error.serverError` → same generic branch.
- [ ] **Mapper round-trip** — if the DTO has non-trivial field mapping (a date, a nested object,
      an optional the server omits), one test asserting `Mapper.toDTO(x)` / `Mapper.toDomain(y)`
      produces the expected field values. Trivial one-to-one `String`→`String` DTOs do not need
      one.

Do not add a `MockIL<Feature>DTO`-level test — the DTO is a wire shape, tested through the mapper
or through the repository's success path, not on its own.

## 6. Async tests

The implemented method is `async throws`, so its ViewModel test needs to await the round trip the
same way the existing SignUp tests do — an `XCTestExpectation` fulfilled from the
`navigationEventPublisher` sink, then `wait(for:timeout:)`. Do not `sleep`. If the ViewModel's
`Task { }` means the expectation can fire before `isSubmitting` is reset, assert the ordering the
existing tests assert (they check `!isSubmitting` after the wait) rather than adding a sleep.

## 7. Running them

```
xcodebuild test -project InnerLamp.xcodeproj -scheme InnerLamp -destination 'platform=iOS Simulator,name=iPhone 16'
```

Report the real output. A summary that says "tests pass" without the command having been run is a
false report — if the build fails, say so and show the failure.
