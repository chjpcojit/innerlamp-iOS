//
//  ILSanghaUseCase.swift
//  InnerLamp
//

import Foundation

/// Tab Chùa: chùa người dùng đang tu tập và nội dung của chùa đó; khi chưa chọn thì gợi ý chùa để
/// chọn. Hiện **chỉ là UI**: mọi dữ liệu là dữ liệu mẫu đồng bộ, không gọi API / Core Data.
protocol ILSanghaUseCase {
    /// `nil` khi người dùng chưa chọn chùa tu tập.
    func loadMyTemple() -> ILSanghaMyTempleEntity?
    func loadChooser() -> ILSanghaChooserEntity
    func selectMyTemple(id: String)
    /// Đặt 1 chùa của danh bạ (`/v1/temples`) làm chùa tu tập — lưu thêm bản chụp tên + địa chỉ để
    /// tab Chùa dựng thẻ chùa mà không cần gọi API.
    func selectMyTemple(_ temple: ILTempleSummaryEntity)
    /// `limit` ngày lễ / ngày trai giới gần nhất (dùng chung 2 trạng thái của tab).
    func loadUpcomingDays(limit: Int) -> [ILFestivalDayEntity]
}

final class ILSanghaUseCaseImpl: ILSanghaUseCase {

    /// Key lưu id chùa tu tập trong `UserDefaultsService`; chưa có (hoặc rỗng) = chùa mặc định.
    static let myTempleKey = "sangha.myTempleID"
    /// Key lưu bản chụp (tên + địa chỉ) của chùa tu tập chọn từ danh bạ — chùa mẫu không cần.
    static let myTempleSnapshotKey = "sangha.myTempleSnapshot"
    /// Chùa mặc định khi chưa từng chọn / đổi (khớp prototype: `myTp = 'tp-tuquang'`).
    static let defaultTempleID = "temple-tuquang"

    private let userDefaultsService: UserDefaultsService
    private let now: () -> Date

    init(userDefaultsService: UserDefaultsService, now: @escaping () -> Date = Date.init) {
        self.userDefaultsService = userDefaultsService
        self.now = now
    }

    func loadMyTemple() -> ILSanghaMyTempleEntity? {
        // @ai: assumption — see Docs/Assumptions/Sangha/AS-Sangha-001-my-temple-stored-locally.md
        // Giá trị rỗng là dấu vết của bản cũ ("Đổi chùa" từng xóa lựa chọn); không còn đường nào đặt lại
        // "chưa chọn" nên coi như chưa chọn bao giờ và dùng chùa mặc định.
        let storedID = userDefaultsService.load(key: Self.myTempleKey, type: String.self)
            .flatMap { $0.isEmpty ? nil : $0 } ?? Self.defaultTempleID
        guard let temple = Self.mockTemples().first(where: { $0.id == storedID }) ?? loadSnapshotTemple(id: storedID) else {
            return nil
        }
        return Self.makeMockContent(for: temple, now: now())
    }

    func loadChooser() -> ILSanghaChooserEntity {
        // @ai: assumption — see Docs/Assumptions/Sangha/AS-Sangha-002-nearby-temples-use-featured-list.md
        ILSanghaChooserEntity(
            nearbyTemples: Self.mockTemples(),
            onlineSessions: Self.mockOnlineSessions(),
            retreats: Self.mockRetreats(now: now())
        )
    }

    func selectMyTemple(id: String) {
        userDefaultsService.save(key: Self.myTempleKey, value: id)
    }

    func selectMyTemple(_ temple: ILTempleSummaryEntity) {
        userDefaultsService.save(
            key: Self.myTempleSnapshotKey,
            value: MyTempleSnapshot(id: temple.id, name: temple.name, address: temple.location.address)
        )
        userDefaultsService.save(key: Self.myTempleKey, value: temple.id)
    }

    func loadUpcomingDays(limit: Int) -> [ILFestivalDayEntity] {
        let day: TimeInterval = 24 * 60 * 60
        let now = now()
        let days = [
            ILFestivalDayEntity(
                id: "day-1", date: now.addingTimeInterval(2 * day),
                title: "sangha.mock.day.1".localized, kind: .festival, daysUntil: 2
            ),
            ILFestivalDayEntity(
                id: "day-2", date: now.addingTimeInterval(9 * day),
                title: "sangha.mock.day.2".localized, kind: .observance, daysUntil: 9
            ),
            ILFestivalDayEntity(
                id: "day-3", date: now.addingTimeInterval(24 * day),
                title: "sangha.mock.day.3".localized, kind: .observance, daysUntil: 24
            ),
            ILFestivalDayEntity(
                id: "day-4", date: now.addingTimeInterval(39 * day),
                title: "sangha.mock.day.4".localized, kind: .festival, daysUntil: 39
            )
        ]
        return Array(days.prefix(limit))
    }

    // MARK: - Snapshot
    private struct MyTempleSnapshot: Codable {
        let id: String
        let name: String
        let address: String
    }

    /// Chùa chọn từ danh bạ: danh bạ không trả giờ mở cửa / trụ trì ở dạng liệt kê nên để trống
    /// (thẻ chùa tự ẩn pill trạng thái và hiện "Đang cập nhật").
    private func loadSnapshotTemple(id: String) -> ILSanghaTempleEntity? {
        guard let snapshot = userDefaultsService.load(key: Self.myTempleSnapshotKey, type: MyTempleSnapshot.self),
              snapshot.id == id else { return nil }
        return ILSanghaTempleEntity(
            id: snapshot.id, name: snapshot.name, address: snapshot.address,
            abbot: "", operatingHours: "", distanceKm: 0
        )
    }

    // MARK: - Mock content
    // TODO: chưa có API chùa tu tập / thông báo / khóa tu / pháp thoại / số Phật tử / buổi tu trực
    // tuyến / ngày lễ (xem Docs/Tech-Debt/Sangha/TD-Sangha-001-*.md) — thay bằng ILSanghaRepository
    // → networkService khi có contract (dùng data-builder).

    private static func mockTemples() -> [ILSanghaTempleEntity] {
        [
            ILSanghaTempleEntity(
                id: "temple-tuquang", name: "sangha.mock.temple.1.name".localized,
                address: "sangha.mock.temple.1.address".localized, abbot: "sangha.mock.abbot".localized,
                operatingHours: "06:00 - 18:00", distanceKm: 3.2
            ),
            ILSanghaTempleEntity(
                id: "temple-vinhnghiem", name: "sangha.mock.temple.2.name".localized,
                address: "sangha.mock.temple.2.address".localized, abbot: "",
                operatingHours: "05:00 - 20:00", distanceKm: 4.8
            ),
            ILSanghaTempleEntity(
                id: "temple-xaloi", name: "sangha.mock.temple.3.name".localized,
                address: "sangha.mock.temple.3.address".localized, abbot: "",
                operatingHours: "06:00 - 19:00", distanceKm: 1.9
            ),
            ILSanghaTempleEntity(
                id: "temple-giaclam", name: "sangha.mock.temple.4.name".localized,
                address: "sangha.mock.temple.4.address".localized, abbot: "",
                operatingHours: "05:30 - 19:00", distanceKm: 6.3
            )
        ].sorted { $0.distanceKm < $1.distanceKm }
    }

    private static func makeMockContent(for temple: ILSanghaTempleEntity, now: Date) -> ILSanghaMyTempleEntity {
        let day: TimeInterval = 24 * 60 * 60
        return ILSanghaMyTempleEntity(
            temple: temple,
            announcements: [
                ILSanghaAnnouncementEntity(
                    id: "news-1", postedAt: now, text: "sangha.mock.news.1".localized
                ),
                ILSanghaAnnouncementEntity(
                    id: "news-2", postedAt: now.addingTimeInterval(-3 * day), text: "sangha.mock.news.2".localized
                )
            ],
            events: [
                ILSanghaEventEntity(
                    id: "event-weekly", date: now.addingTimeInterval(3 * day),
                    title: "sangha.mock.event.weekly.title".localized,
                    detail: "sangha.mock.event.weekly.detail".localized, action: .remind
                ),
                ILSanghaEventEntity(
                    id: "event-retreat", date: now.addingTimeInterval(6 * day),
                    title: "sangha.mock.event.retreat.title".localized,
                    detail: "sangha.mock.event.retreat.detail".localized, action: .reserve
                )
            ],
            talks: [
                ILSanghaTalkEntity(
                    id: "talk.vulan.hieu", title: "sangha.mock.talk.1".localized,
                    speaker: "sangha.mock.speaker".localized, durationMinutes: 46
                ),
                ILSanghaTalkEntity(
                    id: "talk.vulan.hieu", title: "sangha.mock.talk.2".localized,
                    speaker: "sangha.mock.speaker".localized, durationMinutes: 52
                )
            ],
            practitionerCount: 184,
            upcomingRetreatAttendeeCount: 23
        )
    }

    private static func mockOnlineSessions() -> [ILSanghaOnlineSessionEntity] {
        [
            ILSanghaOnlineSessionEntity(
                id: "online-meditation", schedule: "sangha.mock.online.1.schedule".localized, isDaily: true,
                title: "sangha.mock.online.1.title".localized, detail: "sangha.mock.online.1.detail".localized
            ),
            ILSanghaOnlineSessionEntity(
                id: "online-chant", schedule: "sangha.mock.online.2.schedule".localized, isDaily: false,
                title: "sangha.mock.online.2.title".localized, detail: "sangha.mock.online.2.detail".localized
            )
        ]
    }

    private static func mockRetreats(now: Date) -> [ILSanghaEventEntity] {
        let day: TimeInterval = 24 * 60 * 60
        return [
            ILSanghaEventEntity(
                id: "retreat-1", date: now.addingTimeInterval(6 * day),
                title: "sangha.mock.retreat.1.title".localized,
                detail: "sangha.mock.retreat.1.detail".localized, action: .none
            ),
            ILSanghaEventEntity(
                id: "retreat-2", date: now.addingTimeInterval(18 * day),
                title: "sangha.mock.retreat.2.title".localized,
                detail: "sangha.mock.retreat.2.detail".localized, action: .none
            )
        ]
    }
}
