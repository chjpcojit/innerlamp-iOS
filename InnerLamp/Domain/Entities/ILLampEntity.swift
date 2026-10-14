//
//  ILLampEntity.swift
//  InnerLamp
//

import Foundation

/// Kind of lamp the user lights. Raw values are what Core Data stores.
enum ILLampKind: String, CaseIterable, Equatable {
    case oil
    case lotus
    case float
}

/// What the lamp is lit for (tâm nguyện). Raw values are what Core Data stores.
enum ILLampIntention: String, CaseIterable, Equatable {
    case peace
    case dedication
    case departed
    case gratitude
}

/// 1 lamp the user has lit. Raw business data only: the remaining-days label, the dedication
/// sentence and every other display string are built by the ViewModel.
struct ILLampEntity: Equatable, Identifiable {

    /// Lighting durations the user can choose, in days.
    static let durationOptions = [1, 7, 21, 49]
    static let defaultDurationDays = 7

    let id: String
    var kind: ILLampKind
    var intention: ILLampIntention
    /// Who the lamp is dedicated to. Empty means "all beings" (the UI supplies the wording).
    var target: String
    /// Optional vow; empty when the user wrote none.
    var vow: String
    var durationDays: Int
    var litAt: Date

    // @ai: assumption — see Docs/Assumptions/LightLamp/AS-LightLamp-003-real-time-lamp-expiry.md
    /// Whole days the lamp still shines, counting today. A lamp lit today for 7 days has 7 left;
    /// 0 or less means it has gone out.
    func daysLeft(now: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: litAt)
        let today = calendar.startOfDay(for: now)
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return durationDays - max(0, elapsed)
    }

    func isActive(now: Date, calendar: Calendar = .current) -> Bool {
        daysLeft(now: now, calendar: calendar) >= 1
    }
}
