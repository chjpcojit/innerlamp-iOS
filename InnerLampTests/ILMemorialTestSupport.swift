//
//  ILMemorialTestSupport.swift
//  InnerLampTests
//

import Foundation
@testable import InnerLamp

enum ILMemorialTestFactory {

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
        syncToReminders: Bool = true,
        portraitFileName: String? = nil
    ) -> ILMemorialEntity {
        ILMemorialEntity(
            id: id, name: name, relationship: relationship, calendarKind: calendarKind,
            day: day, month: month, deathYear: deathYear, note: note, reminder: reminder,
            syncToReminders: syncToReminders, portraitFileName: portraitFileName
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
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0), syncToReminders: true
        )
    }

    func isValid(name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func nextAnniversary(for entry: ILMemorialEntity, now: Date) -> ILMemorialNextAnniversary? {
        nextAnniversaryResult
    }

    func save(_ entry: ILMemorialEntity) async throws {
        if let saveError { throw saveError }
        savedEntries.append(entry)
    }

    func delete(id: String) async throws {
        if let deleteError { throw deleteError }
        deletedIDs.append(id)
    }
}

/// In-memory `ILMemorialRepository` for use case tests.
final class FakeILMemorialRepository: ILMemorialRepository {

    var entries: [ILMemorialEntity] = []
    private(set) var saved: [ILMemorialEntity] = []
    private(set) var deletedIDs: [String] = []

    func loadAll() async throws -> [ILMemorialEntity] { entries }

    func save(_ entry: ILMemorialEntity) async throws {
        saved.append(entry)
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
    }

    func delete(id: String) async throws {
        deletedIDs.append(id)
        entries.removeAll { $0.id == id }
    }
}
