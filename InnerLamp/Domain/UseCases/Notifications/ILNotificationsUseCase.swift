//
//  ILNotificationsUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILNotificationsUseCase {
    /// Thẻ "Sắp diễn ra" (nil khi không có thời khóa sắp tới).
    func getUpcoming() -> ILNotificationUpcomingEntity?

    /// Danh sách thông báo, mới nhất trước.
    func getNotifications() -> [ILNotificationEntity]
}

final class ILNotificationsUseCaseImpl: ILNotificationsUseCase {

    init() {}

    func getUpcoming() -> ILNotificationUpcomingEntity? {
        // TODO: chưa có contract API thông báo / thời khóa — thay dữ liệu mẫu bằng
        // ILNotificationsRepository (network + push payload) khi có contract (dùng data-builder).
        ILNotificationUpcomingEntity(
            eyebrow: "notifications.hero.eyebrow".localized,
            title: "notifications.hero.title".localized
        )
    }

    func getNotifications() -> [ILNotificationEntity] {
        // TODO: chưa có contract API thông báo — dữ liệu mẫu khớp prototype, thay bằng
        // ILNotificationsRepository khi có contract. Timestamp tổng hợp theo "bây giờ" để
        // format tương đối (vừa xong / 2 giờ / hôm qua / 3 ngày) ra đúng như mẫu.
        let now = Date()
        return [
            ILNotificationEntity(
                id: "bell.dawn.0530",
                kind: .bell,
                title: "notifications.mock.bell.title".localized,
                body: "notifications.mock.bell.body".localized,
                timestamp: now.addingTimeInterval(-30),
                isRead: false
            ),
            ILNotificationEntity(
                id: "sangha.tuquang.sunday",
                kind: .sangha,
                title: "notifications.mock.sangha.title".localized,
                body: "notifications.mock.sangha.body".localized,
                timestamp: now.addingTimeInterval(-2 * 3_600),
                isRead: false
            ),
            ILNotificationEntity(
                id: "community.dieuHanh.rejoice",
                kind: .community,
                title: "notifications.mock.community.title".localized,
                body: "notifications.mock.community.body".localized,
                timestamp: now.addingTimeInterval(-24 * 3_600),
                isRead: true
            ),
            ILNotificationEntity(
                id: "offering.tuquang.receipt",
                kind: .offering,
                title: "notifications.mock.offering.title".localized,
                body: "notifications.mock.offering.body".localized,
                timestamp: now.addingTimeInterval(-3 * 24 * 3_600),
                isRead: true
            )
        ]
    }
}
