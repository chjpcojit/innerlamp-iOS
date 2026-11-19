//
//  CoreDataStack.swift
//  InnerLamp
//

import CoreData

/// Wraps the app's `NSPersistentContainer`.
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
/// EN: One container can hold more than one on-disk store. `separatedStores` carves a store out of
/// the model's default configuration by configuration name, so the caller can exclude only that
/// store from a device backup instead of the whole database.
/// VI: Một container có thể giữ nhiều store trên đĩa. `separatedStores` tách một store khỏi cấu
/// hình mặc định của model theo tên cấu hình, để chỉ store đó bị loại khỏi backup thiết bị thay vì
/// cả database.
///
/// `nonisolated` for the same reason as `KeychainService`: this stack is consumed off the main
/// actor (`performBackgroundTask`), and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would otherwise
/// pin every member here to the main actor.
nonisolated final class CoreDataStack {

    /// Matches `InnerLamp.xcdatamodeld`, which is what `NSPersistentContainer(name:)` looks up.
    static let modelName = "InnerLamp"

    /// EN: The default configuration has to be named explicitly once any entity belongs to another
    /// configuration; otherwise the default store would also claim those entities.
    /// VI: Cấu hình mặc định phải được nêu tên khi đã có entity thuộc cấu hình khác; nếu không,
    /// store mặc định cũng sẽ nhận các entity đó.
    private static let defaultConfigurationName = "Default"

    /// EN: A store carved out of the default one by a model configuration name.
    /// VI: Một store được tách khỏi store mặc định theo tên cấu hình trong model.
    nonisolated struct SeparatedStore {
        /// EN: Configuration in the compiled model; also the key in `separatedStoreURLs`.
        /// VI: Cấu hình trong model đã biên dịch; cũng là khoá trong `separatedStoreURLs`.
        let configurationName: String
        /// EN: File name next to the main store.
        /// VI: Tên file nằm cạnh store chính.
        let fileName: String
        /// EN: `true` keeps this store and its sidecars out of iCloud/iTunes backups.
        /// VI: `true` giữ store này và các file phụ khỏi backup iCloud/iTunes.
        let excludesFromBackup: Bool
        /// EN: When set, rows of this entity left in the pre-split single store are moved into this
        /// store on the first launch after the split, then deleted from the old store.
        /// VI: Khi có giá trị, các dòng của entity này còn trong store đơn trước khi tách sẽ được
        /// chuyển sang store này ở lần chạy đầu sau khi tách, rồi xoá khỏi store cũ.
        let legacyEntityName: String?
    }

    let container: NSPersistentContainer

    /// Set when `loadPersistentStores` failed. Every throwing method rethrows it, so a stack that
    /// never opened fails loudly at the first use rather than silently returning empty results.
    private let loadError: Error?

    /// Absolute SQLite URL of the main on-disk store. `nil` for an in-memory stack.
    private(set) var storeURL: URL?

    /// EN: URL of every `separatedStores` entry, keyed by configuration name.
    /// VI: URL của từng mục trong `separatedStores`, theo tên cấu hình.
    private(set) var separatedStoreURLs: [String: URL] = [:]

    private let separatedStores: [SeparatedStore]

    /// EN: Sensitive stores are encrypted at rest. It is applied to every store because profile and
    /// account rows live in the default store as well.
    /// VI: Các store chứa dữ liệu nhạy cảm được mã hoá khi lưu. Áp dụng cho mọi store vì dòng hồ sơ
    /// và tài khoản cũng nằm trong store mặc định.
    private static let fileProtection: FileProtectionType = .completeUntilFirstUserAuthentication

    /// Creates the stack and loads its stores.
    ///
    /// - Parameter inMemory: `true` swaps the SQLite stores for `NSInMemoryStoreType`. Tests get a
    ///   real Core Data stack — model, mapping and all — that touches no disk and leaves nothing
    ///   behind. Nothing else about the stack changes.
    /// - Parameter storeURL: overrides the default SQLite location of the main store. Only migration
    ///   tests use it; the app always opens the default store.
    /// - Parameter separatedStores: additional stores, each backed by a named model configuration.
    /// - Parameter defaults: where the legacy split records that it compacted the old store. Tests
    ///   pass their own suite so a marker left by an earlier run cannot skip the migration.
    ///
    /// This does **not** throw: Swift's `lazy var` in `DIContainer` cannot, and a `try!` there would
    /// reintroduce exactly the crash-on-launch this type exists to remove. The error is kept and
    /// thrown from `saveViewContext()` / `performBackgroundTask(_:)`, which are `throws` anyway.
    init(
        inMemory: Bool = false,
        storeURL: URL? = nil,
        separatedStores: [SeparatedStore] = [],
        defaults: UserDefaults = .standard
    ) {
        let container = NSPersistentContainer(name: Self.modelName)
        let (descriptions, separatedURLs) = Self.makeDescriptions(
            container: container,
            inMemory: inMemory,
            storeURL: storeURL,
            separatedStores: separatedStores
        )
        container.persistentStoreDescriptions = descriptions

        // EN: Drain the legacy rows before the container opens the main store, so the temporary
        // coordinator is the only owner of the file at that moment. The drain also compacts that
        // file, because deleting a row on its own leaves its text in free pages.
        // VI: Rút các dòng cũ ra trước khi container mở store chính, để coordinator tạm là chủ duy
        // nhất của file ở thời điểm đó. Việc rút cũng nén file đó, vì chỉ xoá dòng thì chữ của nó
        // vẫn nằm trong các trang trống.
        let legacyRows = inMemory ? [:] : CoreDataStackLegacySplit.drain(
            separatedStores: separatedStores,
            mainURL: descriptions.first?.url,
            separatedURLs: separatedURLs,
            model: container.managedObjectModel,
            defaults: defaults
        )

        // Safe to read the error out of the handler: `shouldAddStoreAsynchronously` defaults to
        // `false`, so every store is added — and the handler called — before this returns.
        var loadError: Error?
        container.loadPersistentStores { _, error in
            if let error {
                loadError = loadError ?? error
            }
        }

        self.container = container
        self.loadError = loadError
        self.separatedStores = separatedStores

        guard !inMemory, loadError == nil else { return }
        self.storeURL = descriptions.first?.url
        self.separatedStoreURLs = separatedURLs
        Self.applyProtection(
            mainURL: descriptions.first?.url,
            separatedStores: separatedStores,
            separatedURLs: separatedURLs
        )
        CoreDataStackLegacySplit.restore(
            legacyRows,
            separatedStores: separatedStores,
            into: container.viewContext
        )
    }

    /// EN: Builds the store descriptions: the main store, plus one per separated configuration.
    /// VI: Dựng mô tả store: store chính, cộng một store cho mỗi cấu hình tách riêng.
    private static func makeDescriptions(
        container: NSPersistentContainer,
        inMemory: Bool,
        storeURL: URL?,
        separatedStores: [SeparatedStore]
    ) -> ([NSPersistentStoreDescription], [String: URL]) {
        let mainDescription = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        if inMemory {
            // Must be set before the store is added — the description is read at that point.
            mainDescription.type = NSInMemoryStoreType
            mainDescription.url = inMemoryURL(for: defaultConfigurationName)
        } else if let storeURL {
            mainDescription.url = storeURL
        }
        if !separatedStores.isEmpty {
            mainDescription.configuration = defaultConfigurationName
        }

        var descriptions = [mainDescription]
        var separatedURLs: [String: URL] = [:]
        if let mainURL = mainDescription.url {
            for separated in separatedStores {
                let url = inMemory
                    ? inMemoryURL(for: separated.configurationName)
                    : mainURL.deletingLastPathComponent().appendingPathComponent(separated.fileName)
                separatedURLs[separated.configurationName] = url

                let description = NSPersistentStoreDescription(url: url)
                description.configuration = separated.configurationName
                if inMemory {
                    description.type = NSInMemoryStoreType
                }
                descriptions.append(description)
            }
        }

        if !inMemory {
            for description in descriptions {
                description.setOption(
                    fileProtection.rawValue as NSString,
                    forKey: NSPersistentStoreFileProtectionKey
                )
            }
        }
        return (descriptions, separatedURLs)
    }

    /// The stores opened successfully. `false` means every operation will rethrow `loadError`.
    var isLoaded: Bool { loadError == nil }

    /// Saves the view context if it has changes.
    ///
    /// This replaces `AppDelegate.saveContext()` — same job, minus the `fatalError`.
    func saveViewContext() throws {
        try throwIfNotLoaded()
        applyProtectionIfNeeded()

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
        applyProtectionIfNeeded()

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

    /// EN: Keeps the file flags correct on an existing install too: before the split the main store
    /// was excluded from backup, and that flag survives a build that no longer sets it.
    /// VI: Giữ cờ file đúng cả trên bản cài cũ: trước khi tách, store chính bị loại khỏi backup và
    /// cờ đó vẫn còn trên bản build không còn đặt nó.
    private func applyProtectionIfNeeded() {
        Self.applyProtection(
            mainURL: storeURL,
            separatedStores: separatedStores,
            separatedURLs: separatedStoreURLs
        )
    }

    // MARK: - Backup / file protection

    /// EN: Applies the per-store file flags; only the stores marked `excludesFromBackup` leave a
    /// backup.
    /// VI: Đặt cờ file cho từng store; chỉ store được đánh dấu `excludesFromBackup` mới ra khỏi backup.
    private static func applyProtection(
        mainURL: URL?,
        separatedStores: [SeparatedStore],
        separatedURLs: [String: URL]
    ) {
        if let mainURL {
            applyStoreProtection(at: mainURL, excludesFromBackup: false)
        }
        for separated in separatedStores {
            guard let url = separatedURLs[separated.configurationName] else { continue }
            applyStoreProtection(at: url, excludesFromBackup: separated.excludesFromBackup)
        }
    }

    /// EN: Applies to a store and its `-wal` / `-shm` sidecars: excluding only the main file would
    /// still let recent writes travel in a backup.
    /// VI: Áp dụng cho store và các file `-wal` / `-shm`: chỉ loại file chính thì các ghi gần đây
    /// vẫn vào backup.
    nonisolated static func applyStoreProtection(at url: URL, excludesFromBackup: Bool) {
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: url.path + suffix)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { continue }

            var values = URLResourceValues()
            values.isExcludedFromBackup = excludesFromBackup
            var mutableURL = fileURL
            try? mutableURL.setResourceValues(values)

            try? FileManager.default.setAttributes(
                [.protectionKey: fileProtection],
                ofItemAtPath: fileURL.path
            )
        }
    }

    /// EN: In-memory stores ignore the URL, but the coordinator identifies a store by it — two
    /// descriptions with the same URL would be "the same store twice".
    /// VI: Store trong bộ nhớ bỏ qua URL, nhưng coordinator nhận diện store theo URL — hai mô tả
    /// cùng URL sẽ bị coi là cùng một store.
    private static func inMemoryURL(for configurationName: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(modelName)-\(configurationName)-inmemory.sqlite")
    }
}
