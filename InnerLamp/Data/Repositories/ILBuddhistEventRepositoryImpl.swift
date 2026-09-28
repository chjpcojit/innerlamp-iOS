//
//  ILBuddhistEventRepositoryImpl.swift
//  InnerLamp
//

import Foundation

/// Repository over the local Buddhist event template store.
///
/// Owns no storage mechanism of its own — `ILBuddhistEventLocalDataSource` performs the Core Data
/// work (including seeding) and this type's remaining job is to translate its failures into the
/// `ILBuddhistEventError` cases the Domain contract promises. When a remote catalog lands, this
/// becomes the place that chooses between sources; until then it is a pass-through and
/// `ILBuddhistEventTemplateMO` never appears here.
///
/// `nonisolated` so the whole type is callable from the background context the stack hands out.
nonisolated final class ILBuddhistEventRepositoryImpl: ILBuddhistEventRepository {

    private let localDataSource: ILBuddhistEventLocalDataSource

    init(localDataSource: ILBuddhistEventLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func loadTemplates() async throws -> [ILBuddhistEventTemplateEntity] {
        do {
            return try await localDataSource.fetchTemplates()
        } catch {
            throw ILBuddhistEventError.loadFailed(error)
        }
    }
}
