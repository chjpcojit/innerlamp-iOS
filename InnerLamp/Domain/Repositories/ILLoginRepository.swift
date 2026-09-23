//
//  ILLoginRepository.swift
//  InnerLamp
//

import Foundation

/// Domain-layer boundary for Login's server calls.
///
/// The Data layer implements this (`ILLoginRepositoryImpl`); nothing above it knows whether the
/// implementation speaks HTTP, gRPC, or anything else. The implementation converts its wire DTOs
/// into the Entities declared here before returning — a DTO must never appear above this line.
/// See `.claude/skills/il-data-layer-builder/references/data_layer_architecture.md` §1.
protocol ILLoginRepository {
    /// Authenticates the credentials carried by `entity` and returns the resulting session
    /// (tokens + user).
    ///
    /// Throws the feature's own error type — the implementation maps `NetworkError` to it at this
    /// boundary so that nothing in Domain or Presentation imports `Core/Networking`.
    func login(_ entity: ILLoginEntity) async throws -> ILAuthSessionEntity
}
