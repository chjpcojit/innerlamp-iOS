//
//  ILMemorialReminderPlanner.swift
//  InnerLamp
//

import Foundation

/// One scheduled local reminder. `identifier` is stable for a given entry + giỗ date, so a rebuild
/// replaces rather than duplicates it.
nonisolated struct ILMemorialReminderPlan: Equatable {
    let entryID: String
    let identifier: String
    let fireDate: Date
    /// Fires as a catch-up because the reminder moment already passed today.
    let isCatchUp: Bool
    /// Stable "<entryID>:<giỗ date>" key; stored when a catch-up is scheduled.
    let deliveredKey: String
    /// "Ngày mai là giỗ cha" — relationship only, never the person's name (NFR-MEM-02).
    let body: String
}

/// Turns entries into local notifications (D1). Pure and testable: time, calendar and the set of
/// already-delivered keys are parameters, not global state.
nonisolated enum ILMemorialReminderPlanner {

    /// AC v1.0 MEM-RMD-08: the pending plan never exceeds 60, and the 60 entries with the nearest
    /// giỗ are the ones scheduled. One pending notification per entry, not three.
    static let maxScheduled = 60

    /// One notification per entry. After it fires, the next app open schedules the next giỗ
    /// (AC MEM-RMD-08, "bổ sung khi nhắc cũ bắn").
    static let occurrencesPerEntry = 1

    /// Catch-up fires a few seconds after an app open, not at a "magic" past moment.
    private static let catchUpDelay: TimeInterval = 5

    /// Key stored after a catch-up fires, so opening the app again on the same day does not repeat.
    static func deliveredKey(entryID: String, anniversary: Date, calendar: Calendar) -> String {
        "\(entryID):\(dayKey(anniversary, calendar: calendar))"
    }

    static func plans(
        entries: [ILMemorialEntity],
        now: Date,
        calendar: Calendar = Calendar(identifier: .gregorian),
        deliveredKeys: Set<String> = [],
        limit: Int = maxScheduled
    ) -> [ILMemorialReminderPlan] {
        var result: [ILMemorialReminderPlan] = []

        for entry in entries {
            guard let reminder = entry.reminder else { continue }
            let anniversaries = ILMemorialDateRules.nextAnniversaries(
                for: entry,
                now: now,
                calendar: calendar,
                count: occurrencesPerEntry
            )
            for anniversary in anniversaries {
                let key = deliveredKey(entryID: entry.id, anniversary: anniversary.date, calendar: calendar)
                guard let moment = fireMoment(
                    anniversary: anniversary.date,
                    reminder: reminder,
                    calendar: calendar
                ) else { continue }

                let identity = "memorial.\(entry.id).\(dayKey(anniversary.date, calendar: calendar))"
                if moment > now {
                    result.append(
                        ILMemorialReminderPlan(
                            entryID: entry.id,
                            identifier: identity,
                            fireDate: moment,
                            isCatchUp: false,
                            deliveredKey: key,
                            body: body(leadDays: reminder.leadDays, relationship: entry.relationship)
                        )
                    )
                } else if !deliveredKeys.contains(key) {
                    result.append(
                        ILMemorialReminderPlan(
                            entryID: entry.id,
                            identifier: identity,
                            fireDate: now.addingTimeInterval(catchUpDelay),
                            isCatchUp: true,
                            deliveredKey: key,
                            // EN: A catch-up fires on the day it is opened, so the copy counts from
                            // today — a lead-1 reminder opened on the giỗ day says "today", not
                            // "tomorrow".
                            // VI: Nhắc bù bắn ngay trong ngày mở app, nên câu chữ tính từ hôm nay —
                            // nhắc trước 1 ngày mở đúng ngày giỗ phải đọc "hôm nay", không phải "ngày mai".
                            body: body(leadDays: anniversary.daysUntil, relationship: entry.relationship)
                        )
                    )
                }
            }
        }

        return Array(result.sorted { $0.fireDate < $1.fireDate }.prefix(limit))
    }

    /// The close of the reminder: the giỗ day at `hour:minute`, minus `leadDays`.
    static func fireMoment(
        anniversary: Date,
        reminder: ILMemorialReminder,
        calendar: Calendar
    ) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: anniversary)
        components.hour = reminder.hour
        components.minute = reminder.minute
        components.second = 0
        guard let day = calendar.date(from: components) else { return nil }
        return calendar.date(byAdding: .day, value: -max(0, reminder.leadDays), to: day)
    }

    // MARK: - Copy
    /// Relationship word only. `OTHER` reads "người thân" (contract §2.2, NFR-MEM-02).
    static func body(leadDays: Int, relationship: ILMemorialRelationship) -> String {
        let relation = "memorial.reminder.relation.\(relationship.rawValue)".localized
        switch leadDays {
        case 0:
            return String(format: "memorial.reminder.body.today".localized, relation)
        case 1:
            return String(format: "memorial.reminder.body.tomorrow".localized, relation)
        default:
            return String(format: "memorial.reminder.body.soon".localized, leadDays, relation)
        }
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
