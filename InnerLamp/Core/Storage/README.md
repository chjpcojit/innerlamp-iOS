# Core/Storage

Local persistence. Two services, split by sensitivity — nothing else in the app should touch
`UserDefaults.standard` or the `SecItem*` APIs directly.

| File | Backing store | Use for |
|---|---|---|
| `UserDefaultsService.swift` | `UserDefaults` (plist in the app container) | Non-sensitive preferences: last language, onboarding-seen flag, UI toggles |
| `KeychainService.swift` | Keychain (`kSecClassGenericPassword`) | Secrets: access/refresh tokens, credentials, seed phrases, anything that must not leak |

**The split is not a style preference.** A `UserDefaults` plist is plaintext on disk and is included
in unencrypted iTunes/Finder backups. Anything a user would not want read out of a device backup
belongs in the Keychain.

## Structure

```
Storage/
├── UserDefaultsService.swift   # UserDefaultsService protocol + impl + Bool/String conveniences
└── KeychainService.swift       # KeychainService protocol + impl + string/Codable/protected conveniences
```

`KeychainServiceImpl` is registered in `App/DIContainer.swift` as `keychainService` (`lazy var`) —
consume it through the protocol rather than constructing an instance at the call site. Note that
`NetworkService.swift` and `AuthTokenProvider.swift` currently build their own
`KeychainServiceImpl()` directly; both share the same default service name, so they read the same
items, but the DI container is the intended source.

---

## UserDefaultsService

```swift
protocol UserDefaultsService {
    func save<T: Codable>(key: String, value: T)
    func load<T: Codable>(key: String, type: T.Type) -> T?
    func remove(key: String)
    func exists(key: String) -> Bool
}
```

Values are JSON-encoded by `UserDefaultsServiceImpl` (`JSONEncoder` -> `Data`) and stored under the
key. Reading decodes back to `T`. Instances are cheap; `init(userDefaults:)` accepts a custom suite
for tests.

**None of these methods throw.** Encoding and decoding failures are swallowed by `try?`, so a save
that silently did nothing and a load that silently returned `nil` are indistinguishable from a
missing key. Do not use this service where a failed write must be noticed.

### Usage

```swift
let prefs = UserDefaultsServiceImpl()
prefs.save(key: "hasSeenOnboarding", value: true)

if let seen = prefs.load(key: "hasSeenOnboarding", type: Bool.self), seen { ... }
```

Codable structs work the same way, no extra plumbing:

```swift
struct ILAppSettings: Codable { var language: String; var pushEnabled: Bool }

prefs.save(key: "appSettings", value: settings)
let settings = prefs.load(key: "appSettings", type: ILAppSettings.self)
```

Bool/String conveniences exist, but read their caveats below before using them:

```swift
prefs.saveString(key: "language", value: "vi")
prefs.loadString(key: "language")          // "" when the key is absent — not nil
prefs.saveBool(key: "pushEnabled", value: true)
prefs.loadBool(key: "pushEnabled")         // false when the key is absent
```

### Known limitations

- **`loadString(key:)` returns `""`, not `nil`, for a missing key** — it is declared as returning
  `String?` but the `?? ""` fallback means the optional is never `nil`. Callers cannot tell "absent"
  from "stored empty string". Prefer `load(key:type:)` (which does return `nil`) plus `exists(key:)`
  when that distinction matters.
- **`loadBool(key:defaultValue:)` ignores its `defaultValue` parameter** — the body returns
  `load(...) ?? false` unconditionally, so passing `defaultValue: true` has no effect.
- Not marked `nonisolated`/`Sendable`, unlike `KeychainService`. Reading it from a background
  context is not currently safe by construction — `UserDefaults` itself is thread-safe, but the
  protocol carries no such guarantee. Hop to the main actor or make the protocol's isolation
  explicit before calling it off-main.

---

## KeychainService

Two independent namespaces in one protocol:

| | Plain | ACL-protected |
|---|---|---|
| Write | `save(key:data:)` | `saveProtected(key:data:flags:)` |
| Read | `load(key:)` | `loadProtected(key:reason:)` |
| Accessibility | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | ACL on `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` |
| Auth on read | none | biometric or device passcode |

**The namespaces do not intersect.** `load(key:)` cannot read an item written by `saveProtected`,
and `loadProtected` cannot read one written by `save` — the ACLs do not match and the lookup reports
`itemNotFound`. This is enforced by the OS, not by the caller, so the protected value cannot be
reached by any other query.

The protocol is `nonisolated` because `NetworkServiceImpl` (an actor) reads tokens from its own
isolation domain.

### Plain usage — tokens and small secrets

```swift
let keychain: KeychainService = KeychainServiceImpl()

try keychain.save(key: "access_token", value: "eyJhbGci...")
let token = try keychain.loadString(key: "access_token")

keychain.exists(key: "access_token")   // no prompt — asks for attributes only
try keychain.delete(key: "access_token")
```

Codable overloads mirror the string ones:

```swift
try keychain.save(key: "session", object: session)
let session = try keychain.load(key: "session", type: ILAuthSessionEntity.self)
```

### Protected usage — behind Face ID / Touch ID / passcode

```swift
try keychain.saveProtected(key: "seedBackup", object: seedBackup)

let backup = try await keychain.loadProtected(
    key: "seedBackup",
    type: SeedBackup.self,
    reason: "Xác thực để khôi phục ví"
)
```

Writes do **not** prompt — only reads do. `loadProtected` performs the read with an
`LAContext`, so the system shows the prompt as part of the lookup: one prompt, one read. There is no
separate pre-flight `evaluatePolicy` call.

Values: `saveProtected`/`loadProtectedString` for `String`, `saveProtected(key:object:)` /
`loadProtected(key:type:reason:)` for `Codable`, `saveProtected(key:data:)` for raw bytes.

#### Access-control policy

The `saveProtected(key:data:)` convenience defaults to `.userPresence` — **biometric or device
passcode**, whichever the user picks. This matches the `.deviceOwnerAuthentication` policy that
`loadProtected` pre-checks, so a device with a passcode but broken, unenrolled, or absent biometrics
still has a working read path instead of failing deep inside `SecItemCopyMatching`.

Re-enrolling biometrics does **not** destroy the item under this policy. When a value must die with
the old enrollment, write it through the explicit overload instead:

```swift
try keychain.saveProtected(key: "seedBackup", data: data, flags: .biometryCurrentSet)
```

| Flag | Accepts | Survives re-enroll |
|---|---|---|
| `.userPresence` (**default**) | biometric or passcode | yes |
| `.biometryCurrentSet` | biometric only | no — item destroyed |
| `.biometryAny` | biometric, any enrollment | yes |

**All protected writes require a device passcode to be set.** On a device without one, ACL creation
fails with `accessControlCreationFailed`. `saveProtected` is the only path that can throw this —
check `exists(key:)` or gate the feature before offering it.

#### Reading an ACL item without prompting

`exists(key:)` requests attributes only, never the data, so it does not trigger the biometric
prompt even for a protected item. Use it to decide whether to show a "restore from backup" entry
point before calling `loadProtected`.

### Error handling

`KeychainError` covers every failure mode:

| Case | Raised by | Meaning |
|---|---|---|
| `itemNotFound` | `load`, `loadProtected` | No item for this key — or the ACL did not match |
| `unexpectedStatus(OSStatus)` | all | Raw `OSStatus` from the `SecItem*` call |
| `unableToConvertToData` / `unableToConvertToString` | conveniences | UTF-8 / `Data` cast failed |
| `biometryNotAvailable` | `loadProtected` | `canEvaluatePolicy(.deviceOwnerAuthentication)` returned false |
| `biometryFailed` | `loadProtected` | Match rejected, or interaction not allowed |
| `userCancelled` | `loadProtected` | User dismissed the prompt |
| `accessControlCreationFailed` | `saveProtected` | ACL could not be built — usually no device passcode |

`userCancelled` is the one callers almost always need to branch on: dismissing the prompt is a
normal user action, not an error worth surfacing. `loadProtected` is `async` and called from the
main actor in practice, so surface failures with `showError(_:)`.

Note that `errSecAuthFailed` and `errSecInteractionNotAllowed` are both mapped to `biometryFailed`,
and its `errorDescription` reads "Biometric authentication failed". Under the default `.userPresence`
policy a failed *passcode* entry lands in the same case, so the message can be inaccurate — treat it
as a generic "authentication failed" until that mapping is split.

### Known limitations

- **No tests.** The biometric prompt requires a physical device; the simulator cannot enroll
  biometry. Only the failure branches (`biometryNotAvailable`, `itemNotFound`,
  `accessControlCreationFailed`) are reachable in CI.
- **No `kSecAttrSynchronizable` / iCloud Keychain support.** Items are device-local
  (`ThisDeviceOnly` on both paths) and do not survive a restore to a new device. That is deliberate
  for the plain path, but it also means a protected item cannot be recovered from iCloud — if
  backup/restore is a product requirement, it needs a separate export path.
- **`delete(key:)` and `exists(key:)` look across both namespaces.** They query by service+account
  without an ACL attribute, so `exists` returns true for a protected item and `delete` removes one.
  `delete` does not prompt, which is the intended behaviour for sign-out.

## Choosing between them

```
Is the value a secret — token, credential, key material, personal data?
├── yes → Keychain
│         └── Must it be unreadable without the user present?
│             ├── yes → saveProtected / loadProtected
│             └── no  → save / load
└── no  → UserDefaultsService
```
