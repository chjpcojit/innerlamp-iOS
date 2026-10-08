//
//  AuthSessionRefresher.swift
//  InnerLamp
//
//  Exchanges the stored refresh token for a new token pair (`POST /v1/auth/refresh`) when
//  `NetworkServiceImpl` sees a 401 on an authenticated request. See TD-Core-001.
//
//  The endpoint and DTO live here, not in `Data/`, for the same reason as `APIConfig`: Core must
//  not import Data.
//

import Foundation

extension Notification.Name {
    /// Posted (on an arbitrary thread) once the stored session can no longer be refreshed and has
    /// been cleared from the Keychain. The app coordinator routes the user back to Login.
    nonisolated static let authSessionDidExpire = Notification.Name("InnerLamp.authSessionDidExpire")
}

nonisolated protocol AuthSessionRefreshing {
    /// Makes sure a usable access token is stored, given the one the server just rejected.
    ///
    /// Returns normally when a new pair was stored — by this call or by a concurrent one that
    /// already replaced `rejectedToken`. Throws `NetworkError.unauthorized` when the session is
    /// dead (it has already been cleared and `.authSessionDidExpire` posted); any other error
    /// (offline, timeout, 5xx) leaves the session untouched so a later call can retry.
    func refreshSession(afterRejectedToken rejectedToken: String) async throws
}

nonisolated struct RefreshTokenRequestDTO: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

/// `data` of `POST /v1/auth/refresh` — `RefreshResponse.data` in `Docs/Specs/API/openapi.yaml`.
nonisolated struct RefreshTokenResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}

/// Public endpoint — the refresh token is the credential, so no `Authorization` header is sent.
nonisolated struct RefreshTokenEndpoint: Endpoint {
    let request: RefreshTokenRequestDTO

    var baseURL: String { APIConfig.serverBaseURL }
    var path: String { "/v1/auth/refresh" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }

    var body: Data? {
        try? JSONEncoder().encode(request)
    }
}

/// One refresh at a time: the server rotates the refresh token on every call and revokes the
/// device's session when an already-rotated token is presented (openapi AC11), so two parallel
/// refreshes with the same token would kill the session they are trying to save.
actor AuthSessionRefresher: AuthSessionRefreshing {
    private nonisolated(unsafe) let keychainService: KeychainService
    /// Must be a `NetworkService` built **without** a refresher — otherwise a 401 from the
    /// refresh call would recurse into this actor.
    private nonisolated(unsafe) let networkService: NetworkService
    private let notificationCenter: NotificationCenter
    private var inFlight: Task<Void, Error>?

    init(
        keychainService: KeychainService,
        networkService: NetworkService,
        notificationCenter: NotificationCenter = .default
    ) {
        self.keychainService = keychainService
        self.networkService = networkService
        self.notificationCenter = notificationCenter
    }

    func refreshSession(afterRejectedToken rejectedToken: String) async throws {
        // Another request already got a new pair while this one was waiting.
        if let current = try? keychainService.loadString(key: KeychainAuthTokenProviding.accessTokenKey),
           current != rejectedToken {
            return
        }

        if let inFlight {
            return try await inFlight.value
        }

        let task = Task { try await self.performRefresh() }
        inFlight = task
        defer { inFlight = nil }
        try await task.value
    }

    private func performRefresh() async throws {
        guard let refreshToken = try? keychainService.loadString(key: KeychainAuthTokenProviding.refreshTokenKey),
              !refreshToken.isEmpty else {
            expireSession()
            throw NetworkError.unauthorized
        }

        let response: RefreshTokenResponseDTO
        do {
            response = try await networkService.request(
                endpoint: RefreshTokenEndpoint(request: RefreshTokenRequestDTO(refreshToken: refreshToken)),
                responseType: RefreshTokenResponseDTO.self
            )
        } catch NetworkError.unauthorized {
            // REFRESH_TOKEN_INVALID: expired, already rotated, revoked or unknown — not recoverable.
            expireSession()
            throw NetworkError.unauthorized
        }

        do {
            try keychainService.save(key: KeychainAuthTokenProviding.accessTokenKey, value: response.accessToken)
            try keychainService.save(key: KeychainAuthTokenProviding.refreshTokenKey, value: response.refreshToken)
        } catch {
            // The server already rotated the pair, so the old refresh token is dead and the new
            // one could not be kept — nothing left to retry with.
            expireSession()
            throw NetworkError.unauthorized
        }
    }

    private func expireSession() {
        try? keychainService.delete(key: KeychainAuthTokenProviding.accessTokenKey)
        try? keychainService.delete(key: KeychainAuthTokenProviding.refreshTokenKey)
        notificationCenter.post(name: .authSessionDidExpire, object: nil)
    }
}
