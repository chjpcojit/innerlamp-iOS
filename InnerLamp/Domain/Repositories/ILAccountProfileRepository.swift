//
//  ILAccountProfileRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the signed-in user's account profile from the server. Network-only: the payload is
/// PII with `Cache-Control: no-store`.
nonisolated protocol ILAccountProfileRepository {
    func loadAccountProfile() async throws -> ILAccountProfileEntity
}

enum ILAccountProfileError: Error, Equatable {
    /// No connection / timeout.
    case offline
    /// Token missing, expired and not refreshable, or the account no longer exists.
    case unauthorized
    /// `429 RATE_LIMITED` — per account, shared by every `/v1/users/me*` route.
    case rateLimited
    case loadFailed

    static func == (lhs: ILAccountProfileError, rhs: ILAccountProfileError) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline), (.unauthorized, .unauthorized),
             (.rateLimited, .rateLimited), (.loadFailed, .loadFailed): return true
        default: return false
        }
    }
}
