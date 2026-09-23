# Mapping Transport Errors to `IL<Feature>Error`

The `ViewModel` already exists and already catches feature errors — `ILSignUpViewModel.handleSubmit()`
groups into `catch ILSignUpError.phoneAlreadyRegistered` and a generic `catch`. This skill does not
get to change that shape. Its job is to make sure the errors arriving at that `catch` are the right
ones, carrying the right user-facing message.

## 1. Where each piece lives

| Piece | File | Layer |
|---|---|---|
| `IL<Feature>Error` enum | next to the UseCase, in `Domain/UseCases/<Feature>/IL<Feature>UseCase.swift` (existing precedent: `ILSignUpError`) | Domain |
| `NetworkError` → `IL<Feature>Error` conversion | `Data/Repositories/IL<Feature>RepositoryImpl.swift`, in a `catch let error as NetworkError` | Data |
| `"key".localized` strings | `IL<Feature>Error.errorDescription`, plus the key in `Resources/Localization/vi.json` | — |

**`NetworkError` must never travel above the Repository.** If a `catch NetworkError` appears in a
UseCase, ViewModel, or ViewController, the boundary has leaked — the Repository's whole purpose is
to have already converted it.

## 2. The actual `NetworkError` cases

From `Core/Networking/HTTPMethod.swift` — this is the complete set, do not invent others:

```swift
case invalidURL
case noData
case decodingError(Error)
case encodingError(Error)
case serverError(statusCode: Int, message: String?)
case unauthorized
case noInternetConnection
case timeout
case unknown(Error)
```

`NetworkServiceImpl` produces these from `URLError` (`.notConnectedToInternet`/`.networkConnectionLost`
→ `.noInternetConnection`, `.timedOut` → `.timeout`) and from HTTP status (`401` → `.unauthorized`,
`400...499`/`500...599` → `.serverError(statusCode:message:)`, parsed from the response body's
`{"message": "..."}` when present).

## 3. The conversion

Add one `static func` on `IL<Feature>Error`. Keep it exhaustive over `NetworkError` — a `default:`
that swallows everything is how a real failure becomes an untraceable generic alert.

```swift
extension IL<Feature>Error {
    static func from(_ error: NetworkError) -> IL<Feature>Error {
        switch error {
        case .noInternetConnection:
            return .networkUnavailable
        case .timeout:
            return .requestTimedOut
        case .serverError(_, let message):
            return .server(message: message)
        case .unauthorized:
            return .unauthorized
        case .invalidURL, .noData, .decodingError, .encodingError, .unknown:
            return .unknown
        }
    }
}
```

**The case list is not yours to choose.** Take it from the contract's named failure cases
(`references/contract_requirements.md` §row 4) plus whatever the ViewModel already switches on. If
the design names only `phoneAlreadyRegistered`, do not add six cases "for completeness" — add that
one, plus the transport fallbacks the user actually needs to see. Every added case is a new
`errorDescription` and a new `vi.json` key.

Corollary: **if the contract names a failure case the ViewModel doesn't handle**, do not silently
map it to `.unknown`. Report it — the ViewModel's `catch` shape is `il-screen-builder`'s file and
changing it is that skill's job, driven by a `design.md` change.

## 4. Where the discriminator comes from

A `409` alone is not a failure case — the server has to say *which* failure. Typical discriminators:

- A JSON `code` field: `{"code": "PHONE_ALREADY_REGISTERED"}`.
- A distinct HTTP status per case.
- A message string (fragile — only if the contract says so explicitly).

`NetworkError.serverError(statusCode:message:)` **only carries the `message`**, not a `code`. So when
the contract discriminates by `code`, the current `NetworkService` cannot see it, and the repository
cannot recover it from the thrown error. That is a **stop-and-ask**: either the contract confirms the
distinction is recoverable from status + message, or `NetworkService` needs a change — and Core is
read-only for this skill (`SKILL.md` hard rule 4). Report it; never pattern-match on a
human-readable message string to fake a `code`.

## 5. The enum shape

Match the existing precedent exactly:

```swift
enum IL<Feature>Error: Error, LocalizedError {
    case phoneAlreadyRegistered
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .phoneAlreadyRegistered:
            return "<featureLower>.error.phoneTaken".localized
        case .networkUnavailable:
            return "error.no_internet".localized
        }
    }
}
```

Rules:

- **Every** case gets an `errorDescription`. A case with no message surfaces to the user as a blank
  alert.
- Reuse an existing key when the meaning is identical — `error.generic` and `error.no_internet`
  already exist in `vi.json`. Do not add `signup.error.noInternet` next to `error.no_internet`.
- Add genuinely feature-specific keys to `vi.json` under the feature's existing prefix
  (`signup.error.*` for SignUp), in the same block as the keys `il-screen-builder` already added.
- Vietnamese text, real diacritics, no placeholder like `"TODO"` or `"Error"`.

## 6. What the user sees

`ViewModel` does `self.currentState.submitError = error.localizedDescription` for the generic path,
so `errorDescription` *is* the user-visible text. Write it as a sentence a person can act on:

- Good: `"Số điện thoại này đã được đăng ký. Vui lòng đăng nhập."`
- Bad: `"Error 409"`, `"serverError"`, `"Something went wrong"` (when a specific cause is known).

Never include a status code, an endpoint path, or a raw server message in user-facing text — those
belong in the logging layer (`Docs/Specs/Mobile Logging Architecture.md`), not an alert.
