//
//  ILAppAttestDataSource.swift
//  InnerLamp
//

import CryptoKit
import DeviceCheck
import Foundation

/// On-device App Attest capability — the **only** file in the app that imports `DeviceCheck`.
///
/// Wraps `DCAppAttestService.shared` and maps `DCError` → `ILDeviceAttestationError`, so nothing
/// above `ILDeviceAttestationRepositoryImpl` ever sees a `DCError` or a `DCAppAttestService`. The
/// SHA-256 hashing Apple's App Attest protocol requires happens here, right before the service
/// call, so the Domain layer stays Foundation-only.
///
/// The DataSource is not unit-testable — `DCAppAttestService` is a non-injectable Apple singleton
/// and App Attest only runs on real hardware — so its `DCError` mapping is covered by manual /
/// integration testing (see `Docs/Specs/DeviceAttestation/tasks.md` Phase 2).
nonisolated protocol ILAppAttestDataSource {

    /// Whether App Attest is supported on this device (`DCAppAttestService.isSupported`).
    var isSupported: Bool { get }

    /// Generates a Secure Enclave key pair and returns its `keyId`.
    func generateKey() async throws -> String

    /// Attests `keyId` over the SHA-256 hash of `challenge`, returning the CBOR attestation object.
    func attestKey(keyId: String, challenge: Data) async throws -> Data

    /// Signs the SHA-256 hash of `clientData` with the attested key, returning the assertion.
    func generateAssertion(keyId: String, clientData: Data) async throws -> Data
}

nonisolated final class ILAppAttestDataSourceImpl: ILAppAttestDataSource {

    var isSupported: Bool {
        DCAppAttestService.shared.isSupported
    }

    func generateKey() async throws -> String {
        do {
            return try await DCAppAttestService.shared.generateKey()
        } catch let error as DCError {
            throw ILDeviceAttestationError.fromDCError(error, operation: .generateKey)
        }
    }

    func attestKey(keyId: String, challenge: Data) async throws -> Data {
        let clientDataHash = Data(SHA256.hash(data: challenge))
        do {
            return try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
        } catch let error as DCError {
            throw ILDeviceAttestationError.fromDCError(error, operation: .attestKey)
        }
    }

    func generateAssertion(keyId: String, clientData: Data) async throws -> Data {
        let clientDataHash = Data(SHA256.hash(data: clientData))
        do {
            return try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)
        } catch let error as DCError {
            throw ILDeviceAttestationError.fromDCError(error, operation: .generateAssertion)
        }
    }
}

/// Which App Attest operation produced a `DCError` — the same code means different things per
/// operation (`invalidKey` is a stale/attested key during attestation, but "no usable key" during
/// an assertion).
nonisolated enum ILDeviceAttestationDCErrorOperation {
    case generateKey
    case attestKey
    case generateAssertion
}

extension ILDeviceAttestationError {

    /// Maps `DCError` into the feature's own vocabulary. Exhaustive over the codes the App Attest
    /// calls can produce; `serverUnavailable` maps to `.server` (retryable) rather than a terminal
    /// failure, and `invalidKey` during attestation maps to `.invalidKey` so the UseCase can
    /// discard-and-regenerate instead of surfacing a terminal error.
    static func fromDCError(
        _ error: DCError,
        operation: ILDeviceAttestationDCErrorOperation
    ) -> ILDeviceAttestationError {
        switch error.code {
        case .serverUnavailable, .unknownSystemFailure:
            return .server
        case .featureUnsupported:
            return .unsupported
        case .invalidKey:
            switch operation {
            case .attestKey:
                return .invalidKey
            case .generateKey, .generateAssertion:
                return .assertionFailed
            }
        case .invalidInput:
            switch operation {
            case .generateKey:
                return .keyGenerationFailed
            case .attestKey, .generateAssertion:
                return .assertionFailed
            }
        @unknown default:
            return .server
        }
    }
}
