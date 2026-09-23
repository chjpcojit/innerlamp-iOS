//
//  CoreDataStack.swift
//  InnerLamp
//

import CoreData

/// Wraps the app's single `NSPersistentContainer`.
///
/// Generic by design: this type knows nothing about any Domain entity. The model is loaded by name
/// and the only consumers are the `Data/Repositories/*Impl` types, which own their own
/// `NSManagedObject` subclasses and do the mapping to and from Domain entities. If a name from the
/// Domain or a feature shows up in this file, the boundary has been crossed.
///
/// The stack this replaces lived in `AppDelegate` and called `fatalError` when the store failed to
/// open. That is gone. A store that cannot be opened is not worth terminating the app over — the
/// error is captured here and rethrown from every operation, so the caller sees a normal `throws`
/// and the failure surfaces where it can be handled or reported instead of as a crash at launch.
///
/// `nonisolated` for the same reason as `KeychainService`: this stack is consumed off the main
/// actor (`performBackgroundTask`), and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would otherwise
/// pin every member here to the main actor.
nonisolated final class CoreDataStack {

    /// Matches `InnerLamp.xcdatamodeld`, which is what `NSPersistentContainer(name:)` looks up.
    static let modelName = "InnerLamp"

    let container: NSPersistentContainer

    /// Set when `loadPersistentStores` failed. Every throwing method rethrows it, so a stack that
    /// never opened fails loudly at the first use rather than silently returning empty results.
    private let loadError: Error?

    /// Creates the stack and loads its store.
    ///
    /// - Parameter inMemory: `true` swaps the SQLite store for `NSInMemoryStoreType`. Tests get a
    ///   real Core Data stack — model, mapping and all — that touches no disk and leaves nothing
    ///   behind. Nothing else about the stack changes.
    ///
    /// This does **not** throw: Swift's `lazy var` in `DIContainer` cannot, and a `try!` there would
    /// reintroduce exactly the crash-on-launch this type exists to remove. The error is kept and
    /// thrown from `saveViewContext()` / `performBackgroundTask(_:)`, which are `throws` anyway.
    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: Self.modelName)

        if inMemory {
            // Must be set before the store is added — the description is read at that point.
            container.persistentStoreDescriptions.first?.type = NSInMemoryStoreType
        }

        // Safe to read the error out of the handler: `shouldAddStoreAsynchronously` defaults to
        // `false`, so the store is added — and the handler called — before this returns.
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        self.container = container
        self.loadError = loadError
    }

    /// The store opened successfully. `false` means every operation will rethrow `loadError`.
    var isLoaded: Bool { loadError == nil }

    /// Saves the view context if it has changes.
    ///
    /// This replaces `AppDelegate.saveContext()` — same job, minus the `fatalError`.
    func saveViewContext() throws {
        try throwIfNotLoaded()

        let context = container.viewContext
        guard context.hasChanges else { return }
        try context.save()
    }

    /// Runs `block` on a private-queue context and returns its result.
    ///
    /// The context is not the view context, so the work does not block the main thread. If `block`
    /// leaves changes behind and returns normally, they are saved before the result comes back; if
    /// `block` throws, the context is rolled back and nothing is written. Callers therefore never
    /// have to remember to save.
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try throwIfNotLoaded()

        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let value = try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: value)
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func throwIfNotLoaded() throws {
        if let loadError {
            throw loadError
        }
    }
}
