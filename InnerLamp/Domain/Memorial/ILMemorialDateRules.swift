//
//  ILMemorialDateRules.swift
//  InnerLamp
//

import Foundation

/// One source of the anniversary maths, shared by the list/form and the local reminder scheduler.
/// Pure functions over `ILLunarCalendar`; no state, no UIKit (D6).
///
/// Rules implemented here are the product's (BR-MEM-05…10), not restated in the callers:
/// a lunar giỗ always falls in the **regular** lunar month (a leap month is skipped), a solar giỗ
/// clamps to the last day of a short month, and today counts as "next" (0 days).
nonisolated enum ILMemorialDateRules {

    /// The next `count` anniversaries of `entry`, soonest first. Today is included when it is the
    /// giỗ. Returns fewer than `count` only if the calendar maths fails for a year.
    static func nextAnniversaries(
        for entry: ILMemorialEntity,
        now: Date,
        calendar: Calendar = Calendar(identifier: .gregorian),
        count: Int
    ) -> [ILMemorialNextAnniversary] {
        guard count > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        let todayParts = calendar.dateComponents([.year, .month, .day], from: today)
        guard let todayYear = todayParts.year else { return [] }

        // (solar date, the year the giỗ is counted in — lunar year for a lunar entry)
        var candidates: [(date: Date, year: Int)] = []
        switch entry.calendarKind {
        case .lunar:
            let lunarToday = ILLunarCalendar.solarToLunar(date: today, calendar: calendar)
            for lunarYear in (lunarToday.year - 1)...(lunarToday.year + count) {
                // BR-MEM-05: always the regular month, even for an entry saved with a leap flag.
                guard let solar = ILLunarCalendar.lunarToSolar(day: entry.day, month: entry.month, year: lunarYear),
                      let date = calendar.date(from: DateComponents(year: solar.year, month: solar.month, day: solar.day))
                else { continue }
                candidates.append((date, lunarYear))
            }
        case .solar:
            for year in todayYear...(todayYear + count) {
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: entry.month, day: 1)),
                      let lastDay = calendar.range(of: .day, in: .month, for: monthStart)?.count,
                      let date = calendar.date(from: DateComponents(year: year, month: entry.month, day: min(entry.day, lastDay)))
                else { continue }
                candidates.append((date, year))
            }
        }

        return candidates
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
            .prefix(count)
            .map { hit in
                let days = calendar.dateComponents([.day], from: today, to: hit.date).day ?? 0
                // 0 is a real value ("died today", BR-MEM-09) — only negatives are meaningless.
                let ordinal = entry.deathYear.map { hit.year - $0 }.flatMap { $0 >= 0 ? $0 : nil }
                let lunar = ILLunarCalendar.solarToLunar(date: hit.date, calendar: calendar)
                return ILMemorialNextAnniversary(
                    date: hit.date,
                    daysUntil: max(0, days),
                    ordinal: ordinal,
                    lunarDay: lunar.day,
                    lunarMonth: lunar.month
                )
            }
    }

    static func nextAnniversary(
        for entry: ILMemorialEntity,
        now: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> ILMemorialNextAnniversary? {
        nextAnniversaries(for: entry, now: now, calendar: calendar, count: 1).first
    }
}
