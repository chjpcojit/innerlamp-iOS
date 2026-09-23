//
//  AuthTokenProvider.swift
//  InnerLamp
//
//  Reads the stored access token so `NetworkService` can inject the `Authorization` header
//  centrally. See Docs/Specs/Networking/design.md § "Request lifecycle" Step 2.
//

import Foundation

/// `nonisolated` — `NetworkServiceImpl` (một actor) gọi `currentToken()` từ isolation domain
/// riêng của nó, nên không được ràng buộc vào main actor.
nonisolated protocol AuthTokenProviding {
    /// Returns the current access token, or `nil` if none is stored / it cannot be read.
    /// Never throws — a missing or unreadable token is treated as "no token", not a failure.
    func currentToken() -> String?
}

/// The single place in the app that knows which Keychain key holds the access token.
nonisolated final class KeychainAuthTokenProviding: AuthTokenProviding {
    /// Fixed Keychain key the access token is stored under — also used by the login repository
    /// (`il-data-layer-builder`'s job) when it saves the token after a successful login.
    static let accessTokenKey = "access_token"

    private let keychainService: KeychainService

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }

    func currentToken() -> String? {
        try? keychainService.loadString(key: Self.accessTokenKey)
    }
}
