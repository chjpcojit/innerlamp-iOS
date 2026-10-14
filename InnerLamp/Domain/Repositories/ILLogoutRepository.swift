//
//  ILLogoutRepository.swift
//  InnerLamp
//

import Foundation

/// Revokes the signed-in session on the server. Network-only; clearing the local session (tokens,
/// stored user) is the use case's job, not the repository's.
nonisolated protocol ILLogoutRepository {
    func revokeSession() async throws
}
