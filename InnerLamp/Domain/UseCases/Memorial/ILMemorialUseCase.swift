//
//  ILMemorialUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMemorialUseCase {

    /// Every entry with its next anniversary, soonest first. Also refreshes the local reminder plan.
    func loadItems(now: Date) async throws -> [ILMemorialItem]

    /// A blank entry with the form defaults (lunar, "Ông nội", day 1 / month 1, reminder the day
    /// before at 07:00).
    func makeNewEntry() -> ILMemorialEntity

    /// `true` when `name` has at least one non-whitespace character.
    func isValid(name: String) -> Bool

    /// Next giỗ of `entry` on or after `now`; `nil` only if the calendar maths finds no date.
    func nextAnniversary(for entry: ILMemorialEntity, now: Date) -> ILMemorialNextAnniversary?

    /// Creates or replaces the entry and returns the server's copy.
    @discardableResult
    func save(_ entry: ILMemorialEntity) async throws -> ILMemorialEntity

    func delete(id: String) async throws

    /// Photo routes are only called while `MemorialFeatureFlags.isPhotoEnabled` is true.
    func uploadPhoto(entryID: String, jpegData: Data) async throws -> ILMemorialEntity
    func deletePhoto(entryID: String) async throws -> ILMemorialEntity

    /// `true` when the system notification permission is denied (the reminder setting itself is
    /// the account's, so the UI keeps showing it — D1).
    func isNotificationAuthorizationDenied() async -> Bool
}

final class ILMemorialUseCaseImpl: ILMemorialUseCase {

    private let repository: ILMemorialRepository
    private let reminderScheduler: ILMemorialReminderScheduling
    private let calendar: Calendar

    init(
        repository: ILMemorialRepository,
        reminderScheduler: ILMemorialReminderScheduling = ILNoopMemorialReminderScheduler(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        self.repository = repository
        self.reminderScheduler = reminderScheduler
        self.calendar = calendar
    }

    func loadItems(now: Date) async throws -> [ILMemorialItem] {
        let entries = try await repository.loadAll()
        // Reminders follow the date, which moves every year — refresh them on every load.
        await reminderScheduler.sync(entries: entries, now: now)
        return entries
            .compactMap { entry in nextAnniversary(for: entry, now: now).map { ILMemorialItem(entry: entry, next: $0) } }
            .sorted {
                if $0.next.daysUntil != $1.next.daysUntil { return $0.next.daysUntil < $1.next.daysUntil }
                // Tie-break shared by all three clients: name (vi), then id ascending (A-5).
                let byName = $0.entry.name.localizedStandardCompare($1.entry.name)
                if byName != .orderedSame { return byName == .orderedAscending }
                return $0.entry.id < $1.entry.id
            }
    }

    func makeNewEntry() -> ILMemorialEntity {
        ILMemorialEntity(
            id: UUID().uuidString,
            name: "",
            relationship: .paternalGrandfather,
            calendarKind: .lunar,
            day: 1,
            month: 1,
            deathYear: nil,
            deathLeapMonth: false,
            note: "",
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0)
        )
    }

    func isValid(name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(_ entry: ILMemorialEntity) async throws -> ILMemorialEntity {
        var trimmed = entry
        trimmed.name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = try await repository.save(trimmed)
        await reminderScheduler.reschedule(entry: saved, now: Date())
        return saved
    }

    func delete(id: String) async throws {
        try await repository.delete(id: id)
        await reminderScheduler.cancel(entryID: id)
    }

    func uploadPhoto(entryID: String, jpegData: Data) async throws -> ILMemorialEntity {
        try await repository.uploadPhoto(entryID: entryID, jpegData: jpegData)
    }

    func deletePhoto(entryID: String) async throws -> ILMemorialEntity {
        try await repository.deletePhoto(entryID: entryID)
    }

    func isNotificationAuthorizationDenied() async -> Bool {
        await reminderScheduler.isNotificationAuthorizationDenied()
    }

    // MARK: - Next anniversary

    func nextAnniversary(for entry: ILMemorialEntity, now: Date) -> ILMemorialNextAnniversary? {
        ILMemorialDateRules.nextAnniversary(for: entry, now: now, calendar: calendar)
    }
}
