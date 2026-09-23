//
//  ILProfileUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILProfileUseCase {
    func getProfile() -> ILProfileEntity
}

final class ILProfileUseCaseImpl: ILProfileUseCase {

    init() {}

    func getProfile() -> ILProfileEntity {
        // TODO: chưa có API hồ sơ / thống kê / dấu ấn được xác nhận — thay dữ liệu mẫu bên dưới bằng
        // ILProfileRepository (ILUserRepository + network) khi có contract (dùng il-data-layer-builder).
        ILProfileEntity(
            fullName: "profile.mock.fullName".localized,
            dharmaName: "profile.mock.dharmaName".localized,
            practiceStats: ILProfilePracticeStatsEntity(totalHours: 168, streakDays: 42, chantCount: 9_700),
            // 12 tuần × 7 ngày, mọi ngày đều có ghi chép (mức 1...9) — khớp dữ liệu mẫu của prototype.
            journalEntriesPerDay: (0..<84).map { ($0 * 37) % 9 + 1 },
            recentBadges: [
                ILProfileBadgeEntity(
                    id: "badge.mala108",
                    title: "profile.mock.badge.mala.title".localized,
                    subtitle: "profile.mock.badge.mala.subtitle".localized,
                    category: .mala
                ),
                ILProfileBadgeEntity(
                    id: "badge.retreat30",
                    title: "profile.mock.badge.streak.title".localized,
                    subtitle: "profile.mock.badge.streak.subtitle".localized,
                    category: .streak
                ),
                ILProfileBadgeEntity(
                    id: "badge.vulan",
                    title: "profile.mock.badge.offering.title".localized,
                    subtitle: "profile.mock.badge.offering.subtitle".localized,
                    category: .offering
                )
            ],
            totalBadgeCount: 18,
            offeringCount: 7,
            lanternCount: 3,
            plan: .free,
            reminder: ILProfileReminderEntity(hour: 5, minute: 30, activeDayCount: 6),
            community: ILProfileCommunityEntity(id: "sangha.tuquang", name: "profile.mock.community.name".localized)
        )
    }
}
