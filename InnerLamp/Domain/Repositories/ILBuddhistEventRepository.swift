//
//  ILBuddhistEventRepository.swift
//  InnerLamp
//

import Foundation

/// Reads the catalog of recurring Buddhist event templates.
///
/// Entity in, entity out. No DTO, no `CoreData` import — the storage shape is a Data-layer concern.
/// There is no write API: the templates are seeded once by the data source and only ever read by the
/// app. If a remote catalog or user-created reminders land later, add a save/delete path alongside
/// this protocol.
nonisolated protocol ILBuddhistEventRepository {

    /// Every seeded template, or an empty array when the store has not been seeded yet.
    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity]
}

/// Failures surfaced by `ILBuddhistEventRepository`.
///
/// Mirrors `ILUserError`: carries the underlying error but renders a stable, user-facing message via
/// `errorDescription`. The message a user sees should not change with the storage layer's mood.
enum ILBuddhistEventError: Error, LocalizedError {
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "buddhistEvent.error.loadFailed".localized
        }
    }
}
