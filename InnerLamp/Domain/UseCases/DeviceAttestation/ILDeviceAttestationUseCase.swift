//
//  ILDeviceAttestationUseCase.swift
//  InnerLamp
//

import Foundation

/// The feature's error vocabulary, exhaustive over both `DCError` (mapped in
/// `ILAppAttestDataSourceImpl`) and `NetworkError` (mapped in `ILDeviceAttestationRepositoryImpl`
/// once Phase 4 lands). See `Docs/Specs/DeviceAttestation/design.md` § "Error mapping".
///
/// This is a UI-less core service, so the enum deliberately does **not** conform to
/// `LocalizedError` and carries no user-facing text — the caller that decides to block an action
/// owns the presentation and maps these cases to whatever message/UI it wants.
nonisolated enum ILDeviceAttestationError: Error, Equatable {
    /// App Attest is not supported on this device and the bypass flag is off (fail-closed).
    case unsupported
    /// An assertion was requested while the dev-only bypass flag is on (there is no real key).
    case bypassed
    /// `DCError` during `generateKey`.
    case keyGenerationFailed
    /// Internal: `attestKey` reported `DCError.invalidKey` — the persisted `keyId` no longer
    /// matches a live Secure Enclave key (or the key is already attested). Never surfaced to the
    /// caller; the UseCase discards the key, regenerates, and re-attests.
    case invalidKey
    /// The server rejected the attestation object during verification.
    case attestationRejected
    /// A challenge fetch (attestation or assertion) failed.
    case challengeFailed
    /// Assertion generation failed, or no attested key exists yet (caller should attest first).
    case assertionFailed
    /// A shared server-side error (including `DCError.serverUnavailable`, which is retryable).
    case server
    /// The device has no internet connection.
    case networkUnavailable
    /// The request timed out.
    case timedOut
}

/// Background core service that proves, via Apple App Attest, that the app instance making a
/// sensitive request is genuine and untampered. UI-less — no Coordinator/ViewController/ViewModel.
///
/// The caller owns *when* to invoke it (launch, per-request, per-action); this protocol only
/// exposes the callable core. See `Docs/Specs/DeviceAttestation/`.
protocol ILDeviceAttestationUseCase {

    /// Runs the full attestation flow and returns the resulting state.
    ///
    /// On a supported device this reuses the persisted, already-attested key, or generates +
    /// attests a new one (fetch challenge → attest → submit for verification). On an unsupported
    /// device with the bypass flag off it throws `ILDeviceAttestationError.unsupported` without
    /// contacting the server (fail-closed). With the bypass flag on it short-circuits to a
    /// synthetic success without contacting Apple or the server.
    func attestDevice() async throws -> ILDeviceAttestationEntity

    /// Returns a signed assertion over the SHA-256 hash of `clientData`.
    ///
    /// Loads the persisted `keyId`, fetches a fresh one-time challenge, and signs; throws
    /// `ILDeviceAttestationError.bypassed` when bypass is on (no real key) and
    /// `ILDeviceAttestationError.assertionFailed` when no key exists (attest first). Fail-closed:
    /// any failure throws rather than returning an unverifiable assertion.
    func generateAssertion(clientData: Data) async throws -> Data
}

final class ILDeviceAttestationUseCaseImpl: ILDeviceAttestationUseCase {

    /// Keychain key under which the app-scoped App Attest `keyId` is persisted (one key per
    /// install). Wiped on reinstall/reset — re-attested automatically on the next call.
    static let keyIdKey = "device_attestation_key_id"
    /// `UserDefaultsService` key for the dev-only bypass flag (default `false` = fail-closed).
    static let bypassKey = "deviceAttestation.bypass"

    private let repository: ILDeviceAttestationRepository
    private let keychainService: KeychainService
    private let userDefaultsService: UserDefaultsService

    init(
        repository: ILDeviceAttestationRepository,
        keychainService: KeychainService,
        userDefaultsService: UserDefaultsService
    ) {
        self.repository = repository
        self.keychainService = keychainService
        self.userDefaultsService = userDefaultsService
    }

    // MARK: - Public

    func attestDevice() async throws -> ILDeviceAttestationEntity {
        // Step 1 — bypass gate (no network, no Apple): dev-only short-circuit.
        if isBypassEnabled {
            return ILDeviceAttestationEntity(keyId: nil, isAttested: true, isSupported: false, isBypassed: true)
        }

        // Step 1 — support gate: unsupported + bypass off = fail-closed, never contact the server.
        guard repository.isAppAttestSupported else {
            throw ILDeviceAttestationError.unsupported
        }

        // Steps 2–5 — ensure a key exists, then attest it (with stale-key auto-recovery).
        let keyId = try await ensureAndAttestKey()

        return ILDeviceAttestationEntity(keyId: keyId, isAttested: true, isSupported: true, isBypassed: false)
    }

    func generateAssertion(clientData: Data) async throws -> Data {
        // Step 1 — bypass gate: there is no real key in this mode.
        guard !isBypassEnabled else {
            throw ILDeviceAttestationError.bypassed
        }

        // Step 2 — load the persisted key.
        guard let keyId = loadPersistedKeyId() else {
            throw ILDeviceAttestationError.assertionFailed
        }

        // Step 3 — fetch a fresh one-time challenge so the server can bind and replay-check the
        // assertion. (Provisional server path; see Docs/Specs/DeviceAttestation/design.md.)
        _ = try await repository.fetchAssertionChallenge()

        // Step 4 — sign `clientData` (hashed on-device by the DataSource).
        return try await repository.generateAssertion(keyId: keyId, clientData: clientData)
    }

    // MARK: - Private: bypass flag

    private var isBypassEnabled: Bool {
        userDefaultsService.loadBool(key: Self.bypassKey, defaultValue: false)
    }

    // MARK: - Private: key persistence

    private func loadPersistedKeyId() -> String? {
        try? keychainService.loadString(key: Self.keyIdKey)
    }

    private func persistKeyId(_ keyId: String) throws {
        try keychainService.save(key: Self.keyIdKey, value: keyId)
    }

    private func discardKeyId() {
        try? keychainService.delete(key: Self.keyIdKey)
    }

    // MARK: - Private: attestation flow

    /// Ensures a key exists (reusing the persisted one) and runs the challenge → attest → verify
    /// loop, returning the final `keyId`. Handles `DCError.invalidKey` (a stale Secure Enclave key,
    /// e.g. after a reinstall/factory reset) by discarding, regenerating, and re-attesting once.
    private func ensureAndAttestKey() async throws -> String {
        var keyId = try await ensureKey()
        var didRegenerate = false

        while true {
            // Step 3 — fetch the one-time challenge.
            let challenge = try await repository.fetchAttestationChallenge()

            // Step 4 — attest with Apple.
            let attestation: Data
            do {
                attestation = try await repository.attestKey(keyId: keyId, challenge: challenge)
            } catch ILDeviceAttestationError.invalidKey {
                // Stale key: discard, regenerate, and loop back to Step 3 — at most once.
                guard !didRegenerate else {
                    throw ILDeviceAttestationError.assertionFailed
                }
                discardKeyId()
                keyId = try await repository.generateKey()
                try persistKeyId(keyId)
                didRegenerate = true
                continue
            }

            // Step 5 — submit for server verification.
            do {
                try await repository.submitAttestation(keyId: keyId, attestation: attestation, challenge: challenge)
                return keyId
            } catch ILDeviceAttestationError.attestationRejected {
                // Server rejected the key: discard it so the next call re-attests fresh.
                discardKeyId()
                throw ILDeviceAttestationError.attestationRejected
            }
        }
    }

    private func ensureKey() async throws -> String {
        if let keyId = loadPersistedKeyId() {
            return keyId
        }
        let keyId = try await repository.generateKey()
        try persistKeyId(keyId)
        return keyId
    }
}
