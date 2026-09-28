//
//  ILStatsEntity.swift
//  InnerLamp
//

import Foundation

/// Practice kind used in the "practice mix" breakdown — decides the accent color at the presentation layer.
enum ILStatsPracticeKind: Equatable {
    /// Breath meditation.
    case breathMeditation
    /// Sutra chanting.
    case chanting
    /// Buddha-name recitation (mala).
    case recitation
    /// Dharma talks.
    case dharmaTalk
}

/// Next streak milestone the user is working towards (e.g. "An cư 48 ngày").
struct ILStatsMilestoneEntity: Equatable {
    let title: String
    /// Streak length (in days) needed to earn the milestone.
    let targetDays: Int
}

/// Total practice minutes of one calendar week.
struct ILStatsWeekEntity: Equatable {
    /// ISO week-of-year number (1...53).
    let weekOfYear: Int
    let minutes: Int
}

/// Share of one practice kind in the overall practice time.
struct ILStatsPracticeShareEntity: Equatable {
    let kind: ILStatsPracticeKind
    /// 0...100
    let percent: Int
}

/// Mindfulness bell reminder currently configured.
struct ILStatsReminderEntity: Equatable {
    let hour: Int
    let minute: Int
    /// Number of weekdays the reminder is enabled on (1...7).
    let activeDayCount: Int
}

/// Practice progress over the recent window — raw business values only, no UI state or formatted strings.
struct ILStatsEntity: Equatable {
    /// Current consecutive practice days.
    var streakDays: Int = 0
    /// nil when every streak milestone has already been earned.
    var nextMilestone: ILStatsMilestoneEntity?
    /// Total practice hours (all time).
    var totalHours: Int = 0
    /// Hours this month minus hours last month (can be negative).
    var hoursDeltaVsLastMonth: Int = 0
    /// Most common session start time.
    var usualStartHour: Int = 0
    var usualStartMinute: Int = 0
    /// Share of sessions started in the morning, 0...100.
    var morningSharePercent: Int = 0
    /// Weekly totals, oldest → newest.
    var weeklyMinutes: [ILStatsWeekEntity] = []
    /// Average practice minutes per day across `weeklyMinutes`.
    var averageMinutesPerDay: Int = 0
    /// Practice mix, largest share first.
    var practiceMix: [ILStatsPracticeShareEntity] = []
    /// nil when no reminder has been set.
    var reminder: ILStatsReminderEntity?

    static let empty = ILStatsEntity()
}
