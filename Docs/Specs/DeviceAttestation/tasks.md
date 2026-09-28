# Tasks — DeviceAttestation

Version: 1.2
Last updated: 2026-09-23
Status: in progress — Phases 1–3 done; Phase 4 blocked on backend contract

> See `changelog.md` in this folder for the version history of this spec.

> Every item below traces back to a row in `design.md`'s "Layers & components" table or a step in
> its "Step-by-step Flow" section. All items start unchecked: this feature has not been built.

## Phase 1 — Domain layer

- [x] Create `ILDeviceAttestationEntity` (`Domain/Entities/`) — pure fields `keyId`, `isAttested`,
      `isSupported`, `isBypassed`; Foundation only
- [x] Create `ILDeviceAttestationRepository` protocol (`Domain/Repositories/`) — device capability
      (`isAppAttestSupported`, `generateKey`, `attestKey`, `generateAssertion`) + server ops
      (`fetchAttestationChallenge`, `submitAttestation`, `fetchAssertionChallenge`); `nonisolated`,
      `async throws`, throws `ILDeviceAttestationError`
- [x] Create `ILDeviceAttestationUseCase` / `ILDeviceAttestationUseCaseImpl`
      (`Domain/UseCases/DeviceAttestation/`) + `ILDeviceAttestationError` (declared in this file):
      - `attestDevice()` — full attestation flow with support/bypass gate and key reuse
      - `generateAssertion(clientData:)` — assertion flow
      - bypass-flag short-circuit (fail-closed default)
      - Keychain `keyId` persistence via `KeychainService`
- [x] Unit tests: `InnerLampTests/ILDeviceAttestationUseCaseTests.swift`, mocking
      `ILDeviceAttestationRepository` — cover success, `.unsupported`, `.bypassed`, fail-closed,
      stale-key re-attest

## Phase 2 — Data layer

- [x] Create `ILAppAttestDataSource` / `ILAppAttestDataSourceImpl`
      (`Data/DataSources/Local/ILAppAttestDataSource.swift`, imports `DeviceCheck`) — wraps
      `DCAppAttestService.shared`, maps `DCError` → `ILDeviceAttestationError`; **the only file that
      imports `DeviceCheck`**
- [x] Create `ILDeviceAttestationRepositoryImpl` (`Data/Repositories/`) — the device-capability
      methods (`isAppAttestSupported`, `generateKey`, `attestKey`, `generateAssertion`) delegate to
      `ILAppAttestDataSource` and are real; the three server methods are `// TODO` stubs until
      Phase 4 (per the "never fake a Repository call" rule — no DTO/Mapper/Endpoint exists yet)
- [x] Unit tests: `ILDeviceAttestationUseCaseTests` already cover the flows via a mock repository;
      the DataSource's `DCError` mapping is covered by integration/manual testing (App Attest runs
      on real hardware, not injectable)

## Phase 3 — Wiring & configuration

- [x] Wire `DIContainer`: `appAttestDataSource` lazy var + `makeDeviceAttestationRepository()` +
      `makeDeviceAttestationUseCase()`, injecting `KeychainService`, `UserDefaultsService`,
      `NetworkService`
- [x] Add the App Attest environment entitlement
      (`com.apple.developer.devicecheck.appattest-environment`) and keep it consistent with the
      server environment
- [x] Add the `deviceAttestation.bypass` flag to `UserDefaultsService` (default `false`), read by
      the UseCase's support/bypass gate
- [ ] Confirm the Keychain `keyId` entry survives app updates and is wiped on reinstall (manual
      check), matching the auto-re-attest design

## Phase 4 — API integration (blocked on backend contract)

> The envelope/mechanism are confirmed but the exact endpoint paths/error codes are not yet fixed in
> `Docs/Specs/API/openapi.yaml` (see the ⚠️ in `requirements.md`). This phase finalizes them.

- [ ] Define the contract with the backend team — endpoint paths, request/response envelope, error
      codes, and the server-side verification responsibilities listed in `design.md`
- [ ] Create the DTOs + Mapper (only once the contract above is confirmed)
- [ ] Create the real `Endpoint` conformances (paths from the contract)
- [ ] Replace the stubbed `ILDeviceAttestationRepositoryImpl` methods with real calls
- [ ] Map network/HTTP errors to `ILDeviceAttestationError` cases
- [ ] Create `InnerLampTests/ILDeviceAttestationRepositoryTests.swift` — error mapping, mapper,
      wire shapes — and update `ILDeviceAttestationUseCaseTests` with a mock repository covering
      the real success/failure paths
- [ ] Manual test against a real/staging backend once available

## Phase 5 — Documentation

- [ ] `Docs/Knowledge/features/deviceattestation.md` (OKF concept) — hold off until Phase 4 lands,
      so the concept describes real end-to-end behavior instead of stubs (see `Docs/Specs/OKF.md`)

## Deferred (separate concerns, not blocking DeviceAttestation)

- The caller's decision of **when** to invoke `attestDevice()` / `generateAssertion(...)` (launch,
  per-request, per-action) — owned by the caller, tracked elsewhere.
- Any user-facing "device blocked" UI — owned by the feature/screen that decides to block.
- **Jailbreak/root detection** — out of scope per `requirements.md` (App Attest does not provide
  it); possibly a future feature or a third-party RASP SDK.
- `DCDevice` (DeviceCheck) tokens as a fallback for iOS < 14 — not in scope for v1.0.
