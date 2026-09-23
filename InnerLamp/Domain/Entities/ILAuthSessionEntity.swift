//
//  ILAuthSessionEntity.swift
//  InnerLamp
//

import Foundation

/// Pure business entity for an authenticated session — Domain layer only.
///
/// Mirrors the backend's `registerResponse` struct, which the server returns for login as well as
/// for registration (the Go type name is a server-side detail, not a statement about which flows
/// use it).
///
/// The tokens live here as business data — "the user is authenticated, and this is the proof" —
/// while *storing* them (which Keychain key, when to refresh, when to delete) is a Data-layer
/// concern. Domain never imports `KeychainService`.
struct ILAuthSessionEntity: Equatable {
    var accessToken: String = ""
    var refreshToken: String = ""
    var user: ILUserEntity = ILUserEntity()

    static let empty = ILAuthSessionEntity()
}
