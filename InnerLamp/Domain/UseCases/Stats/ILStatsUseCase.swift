//
//  ILStatsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILStatsUseCase {
    func getStats() -> ILStatsEntity
}

final class ILStatsUseCaseImpl: ILStatsUseCase {

    init() {}

    func getStats() -> ILStatsEntity {
        // TODO: no confirmed stats API yet (handoff README: stats should be written local-first, then
        // synced) — replace the sample data below with an ILStatsRepository once the contract exists
        // (use data-builder).
        ILStatsEntity(
            streakDays: 42,
            nextMilestone: ILStatsMilestoneEntity(title: "stats.mock.milestone.title".localized, targetDays: 48),
            totalHours: 168,
            hoursDeltaVsLastMonth: 8,
            usualStartHour: 5,
            usualStartMinute: 40,
            morningSharePercent: 68,
            // Weeks 27...38 — relative values match the prototype's `weeks12` sample.
            weeklyMinutes: zip(27...38, [77, 95, 68, 108, 89, 123, 102, 139, 114, 146, 131, 154]).map {
                ILStatsWeekEntity(weekOfYear: $0, minutes: $1)
            },
            averageMinutesPerDay: 22,
            practiceMix: [
                ILStatsPracticeShareEntity(kind: .breathMeditation, percent: 42),
                ILStatsPracticeShareEntity(kind: .chanting, percent: 28),
                ILStatsPracticeShareEntity(kind: .recitation, percent: 20),
                ILStatsPracticeShareEntity(kind: .dharmaTalk, percent: 10)
            ],
            reminder: ILStatsReminderEntity(hour: 5, minute: 30, activeDayCount: 6)
        )
    }
}
