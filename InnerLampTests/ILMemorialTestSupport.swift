//
//  ILMemorialTestSupport.swift
//  InnerLampTests
//

import Foundation
@testable import InnerLamp

enum ILMemorialTestFactory {

    static let accountID = "test-account"

    static func identity(_ id: String? = accountID) -> ILAccountIdentityProviding {
        ILFixedAccountIdentityProvider(accountID: id)
    }

    /// Fixed calendar so day maths does not depend on the machine's time zone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 9)) ?? Date(timeIntervalSince1970: 0)
    }

    static func entry(
        id: String = "e1",
        name: String = "Nguyễn Văn An",
        relationship: ILMemorialRelationship = .paternalGrandfather,
        calendarKind: ILMemorialCalendarKind = .solar,
        day: Int = 15,
        month: Int = 11,
        deathYear: Int? = nil,
        note: String = "",
        reminder: ILMemorialReminder? = ILMemorialReminder(leadDays: 1, hour: 7, minute: 0),
        deathLeapMonth: Bool = false,
        photoURL: URL? = nil
    ) -> ILMemorialEntity {
        ILMemorialEntity(
            id: id, name: name, relationship: relationship, calendarKind: calendarKind,
            day: day, month: month, deathYear: deathYear, deathLeapMonth: deathLeapMonth,
            note: note, reminder: reminder, photoURL: photoURL
        )
    }

    static func next(daysUntil: Int, ordinal: Int? = nil) -> ILMemorialNextAnniversary {
        ILMemorialNextAnniversary(
            date: date(2026, 11, 15), daysUntil: daysUntil, ordinal: ordinal, lunarDay: 6, lunarMonth: 10
        )
    }

    static func item(
        id: String = "e1", name: String = "Nguyễn Văn An", daysUntil: Int = 10, ordinal: Int? = nil,
        reminder: ILMemorialReminder? = ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
    ) -> ILMemorialItem {
        ILMemorialItem(entry: entry(id: id, name: name, reminder: reminder), next: next(daysUntil: daysUntil, ordinal: ordinal))
    }
}

struct MemorialTestError: Error, Equatable {}

/// Test double for `ILMemorialUseCase`, used by both ViewModel test suites.
final class MockILMemorialUseCase: ILMemorialUseCase {

    var loadItemsResult: Result<[ILMemorialItem], Error> = .success([])
    var nextAnniversaryResult: ILMemorialNextAnniversary? = ILMemorialTestFactory.next(daysUntil: 43)
    var saveError: Error?
    var deleteError: Error?
    private(set) var savedEntries: [ILMemorialEntity] = []
    private(set) var deletedIDs: [String] = []
    private(set) var loadItemsCallCount = 0

    func loadItems(now: Date) async throws -> [ILMemorialItem] {
        loadItemsCallCount += 1
        return try loadItemsResult.get()
    }

    func makeNewEntry() -> ILMemorialEntity {
        ILMemorialTestFactory.entry(
            id: "new", name: "", calendarKind: .lunar, day: 1, month: 1,
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
    }

    func isValid(name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func nextAnniversary(for entry: ILMemorialEntity, now: Date) -> ILMemorialNextAnniversary? {
        nextAnniversaryResult
    }

    @discardableResult
    func save(_ entry: ILMemorialEntity) async throws -> ILMemorialEntity {
        if let saveError { throw saveError }
        savedEntries.append(entry)
        return entry
    }

    func delete(id: String) async throws {
        if let deleteError { throw deleteError }
        deletedIDs.append(id)
    }

    var uploadPhotoError: Error?
    private(set) var uploadedPhotoEntryIDs: [String] = []
    private(set) var deletedPhotoEntryIDs: [String] = []
    var notificationsDenied = false

    func uploadPhoto(entryID: String, jpegData: Data) async throws -> ILMemorialEntity {
        if let uploadPhotoError { throw uploadPhotoError }
        uploadedPhotoEntryIDs.append(entryID)
        return ILMemorialTestFactory.entry(id: entryID)
    }

    func deletePhoto(entryID: String) async throws -> ILMemorialEntity {
        deletedPhotoEntryIDs.append(entryID)
        return ILMemorialTestFactory.entry(id: entryID)
    }

    func isNotificationAuthorizationDenied() async -> Bool { notificationsDenied }
}

/// In-memory `ILMemorialRepository` for use case tests.
final class FakeILMemorialRepository: ILMemorialRepository {

    var entries: [ILMemorialEntity] = []
    private(set) var saved: [ILMemorialEntity] = []
    private(set) var deletedIDs: [String] = []

    func loadAll() async throws -> [ILMemorialEntity] { entries }

    @discardableResult
    func save(_ entry: ILMemorialEntity) async throws -> ILMemorialEntity {
        saved.append(entry)
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        return entry
    }

    func delete(id: String) async throws {
        deletedIDs.append(id)
        entries.removeAll { $0.id == id }
    }

    func uploadPhoto(entryID: String, jpegData: Data) async throws -> ILMemorialEntity {
        entries.first { $0.id == entryID } ?? ILMemorialTestFactory.entry(id: entryID)
    }

    func deletePhoto(entryID: String) async throws -> ILMemorialEntity {
        entries.first { $0.id == entryID } ?? ILMemorialTestFactory.entry(id: entryID)
    }
}

/// Records the reminder plan calls, so the use case's D1 wiring is testable without
/// `UNUserNotificationCenter`.
final class MockMemorialReminderScheduler: ILMemorialReminderScheduling {
    private(set) var syncedIDs: [[String]] = []
    private(set) var rescheduledIDs: [String] = []
    private(set) var cancelledIDs: [String] = []
    private(set) var didCancelAll = false
    var denied = false

    func sync(entries: [ILMemorialEntity], now: Date) async {
        syncedIDs.append(entries.map(\.id))
    }

    func reschedule(entry: ILMemorialEntity, now: Date) async {
        rescheduledIDs.append(entry.id)
    }

    func cancel(entryID: String) async {
        cancelledIDs.append(entryID)
    }

    func cancelAll() async {
        didCancelAll = true
    }

    func isNotificationAuthorizationDenied() async -> Bool { denied }
}
