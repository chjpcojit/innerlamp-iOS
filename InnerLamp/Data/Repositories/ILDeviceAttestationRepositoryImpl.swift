//
//  ILDeviceAttestationRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Data-layer implementation of `ILDeviceAttestationRepository`.
///
/// The device capability (`isAppAttestSupported`, `generateKey`, `attestKey`, `generateAssertion`)
/// delegates to `ILAppAttestDataSource` and is real. The three server ops are one-line `// TODO`
/// stubs until Phase 4 — the project rule "never fake a Repository call" applies, and no
/// DTO/Mapper/Endpoint exists yet (`Docs/Specs/DeviceAttestation/design.md` § "Deliberately
/// stubbed for now"). They fail closed (throw) rather than return fabricated data, so the UseCase
/// never marks a key attested against a mock server.
nonisolated final class ILDeviceAttestationRepositoryImpl: ILDeviceAttestationRepository {

    private let appAttestDataSource: ILAppAttestDataSource

    /// `networkService` is intentionally **not** injected yet: the server round-trips are stubs
    /// until the backend contract lands, and an unused dependency is dead code. Phase 4 adds
    /// `networkService` plus the three `Endpoint` conformances and swaps these stubs for real calls.
    init(appAttestDataSource: ILAppAttestDataSource) {
        self.appAttestDataSource = appAttestDataSource
    }

    // MARK: - Device capability (real — delegates to the DataSource)

    var isAppAttestSupported: Bool {
        appAttestDataSource.isSupported
    }

    func generateKey() async throws -> String {
        try await appAttestDataSource.generateKey()
    }

    func attestKey(keyId: String, challenge: Data) async throws -> Data {
        try await appAttestDataSource.attestKey(keyId: keyId, challenge: challenge)
    }

    func generateAssertion(keyId: String, clientData: Data) async throws -> Data {
        try await appAttestDataSource.generateAssertion(keyId: keyId, clientData: clientData)
    }

    // MARK: - Server ops (stubbed until Phase 4 — blocked on the backend contract)

    func fetchAttestationChallenge() async throws -> Data {
        // TODO: real API — GET /v1/attestation/challenge (provisional path). Blocked on the
        // backend contract; see Docs/Specs/DeviceAttestation/design.md Phase 4. Fails closed.
        throw ILDeviceAttestationError.challengeFailed
    }

    func submitAttestation(keyId: String, attestation: Data, challenge: Data) async throws {
        // TODO: real API — POST /v1/attestation/verify (provisional path). Blocked on the backend
        // contract; see Docs/Specs/DeviceAttestation/design.md Phase 4. Fails closed.
        throw ILDeviceAttestationError.server
    }

    func fetchAssertionChallenge() async throws -> Data {
        // TODO: real API — GET /v1/assertion/challenge (provisional path). Blocked on the backend
        // contract; see Docs/Specs/DeviceAttestation/design.md Phase 4. Fails closed.
        throw ILDeviceAttestationError.challengeFailed
    }
}
