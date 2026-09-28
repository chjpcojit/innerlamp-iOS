//
//  ILDeviceAttestationRepository.swift
//  InnerLamp
//

import Foundation

/// Domain-layer contract for the DeviceAttestation core service.
///
/// Expressed in Domain terms only — `Data` in, `Data` out for the Apple payloads, plus the
/// `keyId` `String`. No `ILDeviceAttestationDTO` may appear in this file or anywhere else under
/// `Domain/`, and no `NetworkError` or `DCError` may cross this line either: the implementation
/// maps both to `ILDeviceAttestationError` at the boundary
/// (`references/data_layer_architecture.md` §1).
///
/// The device capability (`isAppAttestSupported`, `generateKey`, `attestKey`, `generateAssertion`)
/// delegates to `ILAppAttestDataSource` (the only type that imports `DeviceCheck`); the server ops
/// (`fetchAttestationChallenge`, `submitAttestation`, `fetchAssertionChallenge`) round-trip through
/// `NetworkService` and are stubbed until the backend contract lands (Phase 4).
///
/// `nonisolated` so callers off the main actor can invoke it; the Apple and server calls are
/// `async throws`.
nonisolated protocol ILDeviceAttestationRepository {

    // MARK: - Device capability (Apple, on-device)

    /// Whether App Attest is supported on this device (`DCAppAttestService.isSupported`).
    var isAppAttestSupported: Bool { get }

    /// Generates a new Secure Enclave key pair and returns its identifier (`keyId`).
    ///
    /// Throws `ILDeviceAttestationError.keyGenerationFailed` on failure.
    func generateKey() async throws -> String

    /// Asks Apple to attest the key identified by `keyId` over the SHA-256 hash of `challenge`,
    /// returning the CBOR attestation object to send to the server.
    ///
    /// Throws `ILDeviceAttestationError.invalidKey` when the `keyId` no longer matches a live
    /// Secure Enclave key (the caller discards and regenerates); `ILDeviceAttestationError.server`
    /// for a retryable Apple-side outage; and other mapped cases otherwise.
    func attestKey(keyId: String, challenge: Data) async throws -> Data

    /// Signs `clientData` (SHA-256 hashed) with the attested key, returning the assertion the
    /// caller attaches to a protected request.
    ///
    /// Throws `ILDeviceAttestationError.assertionFailed` when there is no usable attested key.
    func generateAssertion(keyId: String, clientData: Data) async throws -> Data

    // MARK: - Server ops (round-trip; stubbed until Phase 4)

    /// Fetches a one-time attestation challenge from the server (`GET /v1/attestation/challenge`).
    func fetchAttestationChallenge() async throws -> Data

    /// Submits the attestation object for server-side verification
    /// (`POST /v1/attestation/verify`).
    func submitAttestation(keyId: String, attestation: Data, challenge: Data) async throws

    /// Fetches a one-time assertion challenge from the server (`GET /v1/assertion/challenge`).
    func fetchAssertionChallenge() async throws -> Data
}
