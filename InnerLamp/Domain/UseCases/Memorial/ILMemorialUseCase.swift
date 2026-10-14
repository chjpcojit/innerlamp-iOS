//
//  ILMemorialUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMemorialUseCase {

    /// Every entry with its next anniversary, soonest first.
    func loadItems(now: Date) async throws -> [ILMemorialItem]

    /// A blank entry with the form defaults (lunar, "Ông nội", day 1 / month 1, reminder the day
    /// before at 07:00, add-to-Reminders on).
    func makeNewEntry() -> ILMemorialEntity

    /// `true` when `name` has at least one non-whitespace character.
    func isValid(name: String) -> Bool

    /// Next giỗ of `entry` on or after `now`; `nil` only if the calendar maths finds no date.
    func nextAnniversary(for entry: ILMemorialEntity, now: Date) -> ILMemorialNextAnniversary?

    func save(_ entry: ILMemorialEntity) async throws

    func delete(id: String) async throws
}

final class ILMemorialUseCaseImpl: ILMemorialUseCase {

    private let repository: ILMemorialRepository
    private let calendar: Calendar

    init(repository: ILMemorialRepository, calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.repository = repository
        self.calendar = calendar
    }

    func loadItems(now: Date) async throws -> [ILMemorialItem] {
        let entries = try await repository.loadAll()
        // Reminders follow the date, which moves every year — refresh them on every load.
        scheduleReminders(for: entries)
        return entries
            .compactMap { entry in nextAnniversary(for: entry, now: now).map { ILMemorialItem(entry: entry, next: $0) } }
            .sorted {
                if $0.next.daysUntil != $1.next.daysUntil { return $0.next.daysUntil < $1.next.daysUntil }
                return $0.entry.name.localizedStandardCompare($1.entry.name) == .orderedAscending
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
            note: "",
            reminder: ILMemorialReminder(leadDays: 1, hour: 7, minute: 0),
            syncToReminders: true,
            portraitFileName: nil
        )
    }

    func isValid(name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(_ entry: ILMemorialEntity) async throws {
        var trimmed = entry
        trimmed.name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        try await repository.save(trimmed)
        scheduleReminders(for: [trimmed])
    }

    func delete(id: String) async throws {
        try await repository.delete(id: id)
        cancelReminder(forEntryID: id)
    }

    // MARK: - Next anniversary

    func nextAnniversary(for entry: ILMemorialEntity, now: Date) -> ILMemorialNextAnniversary? {
        let today = calendar.startOfDay(for: now)
        let todayParts = calendar.dateComponents([.year, .month, .day], from: today)
        guard let todayYear = todayParts.year else { return nil }

        // (solar date, the year the giỗ is counted in — lunar year for a lunar entry)
        var candidates: [(date: Date, year: Int)] = []
        switch entry.calendarKind {
        case .lunar:
            let lunarToday = ILLunarCalendar.solarToLunar(date: today, calendar: calendar)
            for lunarYear in [lunarToday.year - 1, lunarToday.year, lunarToday.year + 1] {
                // EN: Product BR-MEM-05: the anniversary is always in the regular (non-leap) lunar month.
                // VI: Product BR-MEM-05: ngày giỗ luôn rơi vào tháng âm thường (không nhuận).
                // Leap lunar months are skipped: only the regular month counts.
                guard let solar = ILLunarCalendar.lunarToSolar(day: entry.day, month: entry.month, year: lunarYear),
                      let date = calendar.date(from: DateComponents(year: solar.year, month: solar.month, day: solar.day))
                else { continue }
                candidates.append((date, lunarYear))
            }
        case .solar:
            for year in [todayYear, todayYear + 1] {
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: entry.month, day: 1)),
                      let lastDay = calendar.range(of: .day, in: .month, for: monthStart)?.count,
                      let date = calendar.date(from: DateComponents(year: year, month: entry.month, day: min(entry.day, lastDay)))
                else { continue }
                candidates.append((date, year))
            }
        }

        guard let hit = candidates.first(where: { $0.date >= today }) ?? candidates.last else { return nil }
        let days = calendar.dateComponents([.day], from: today, to: hit.date).day ?? 0
        let ordinal = entry.deathYear.map { hit.year - $0 }.flatMap { $0 >= 1 ? $0 : nil }
        let lunar = ILLunarCalendar.solarToLunar(date: hit.date, calendar: calendar)
        return ILMemorialNextAnniversary(
            date: hit.date,
            daysUntil: max(0, days),
            ordinal: ordinal,
            lunarDay: lunar.day,
            lunarMonth: lunar.month
        )
    }

    // MARK: - Reminders (stubbed)

    // EN: To be removed: the server sends reminders (product FR-MEM-008) — Docs/Specs/Memorial/tasks.md Phase 7.
    // VI: Sẽ xoá: server gửi lời nhắc (product FR-MEM-008) — Docs/Specs/Memorial/tasks.md Phase 7.
    private func scheduleReminders(for entries: [ILMemorialEntity]) {
        print("TODO: schedule local notifications for \(entries.count) memorial entries — mechanism not confirmed, see Docs/Specs/Memorial/")
    }

    private func cancelReminder(forEntryID id: String) {
        print("TODO: cancel the local notification of memorial entry \(id) — mechanism not confirmed, see Docs/Specs/Memorial/")
    }
}
