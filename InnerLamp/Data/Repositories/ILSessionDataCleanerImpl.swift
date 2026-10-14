//
//  ILSessionDataCleanerImpl.swift
//  InnerLamp
//

import CoreData
import Foundation

/// Deletes every row of the account-scoped Core Data entities in one transaction: the stored user,
/// the birth profile, the memorial book (a cache of `/v1/memorials*`, re-fetched on the next
/// sign-in) and the lit lamps. Lamps have no server copy yet, so clearing them is a permanent
/// loss until the lamp API exists — see `Docs/Assumptions/Profile/AS-Profile-003-*`.
nonisolated final class ILSessionDataCleanerImpl: ILSessionDataCleaner {

    private static let userScopedEntityNames = [
        ILUserMO.entityName,
        ILUserBirthProfileMO.entityName,
        ILMemorialMO.entityName,
        ILLampMO.entityName
    ]

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func clearUserScopedData() async throws {
        try await stack.performBackgroundTask { context in
            for entityName in Self.userScopedEntityNames {
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                try context.fetch(request).forEach(context.delete)
            }
        }
    }
}
