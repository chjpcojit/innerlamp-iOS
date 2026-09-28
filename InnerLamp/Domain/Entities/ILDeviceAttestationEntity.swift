//
//  ILDeviceAttestationEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business result of an App Attest check — Domain layer only.
///
/// Holds only the fields with real business meaning: the persisted App Attest `keyId`, whether
/// Apple's attestation completed and the server accepted it (`isAttested`), whether the device
/// actually supports App Attest (`isSupported`), and whether the dev-only bypass flag short-
/// circuited the whole check (`isBypassed`).
///
/// There is no UI in this feature and no `ILDeviceAttestationStateModel`: this is a UI-less core
/// service whose caller decides what to render. See `Docs/Specs/DeviceAttestation/`.
nonisolated struct ILDeviceAttestationEntity: Equatable {
    /// The App Attest key identifier (base64) persisted in the Keychain. `nil` when bypassed, when
    /// the device is unsupported, or before a key has been generated.
    var keyId: String? = nil
    /// `true` once the key has been attested by Apple and accepted by the server.
    var isAttested: Bool = false
    /// `true` when `DCAppAttestService.isSupported` reported the device supports App Attest.
    var isSupported: Bool = false
    /// `true` when the dev-only bypass flag short-circuited the check without contacting Apple or
    /// the server.
    var isBypassed: Bool = false

    static let empty = ILDeviceAttestationEntity()
}
