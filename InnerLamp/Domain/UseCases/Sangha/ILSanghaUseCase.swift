//
//  ILSanghaUseCase.swift
//  InnerLamp
//

import Foundation

/// Tab Chùa: chùa người dùng đang tu tập và nội dung của chùa đó; khi chưa chọn thì gợi ý chùa để
/// chọn. Hiện **chỉ là UI**: mọi dữ liệu là dữ liệu mẫu đồng bộ, không gọi API / Core Data.
protocol ILSanghaUseCase {
    /// Chùa tu tập: chùa người dùng tự chọn trong app, nếu không thì chùa trong hồ sơ tài khoản
    /// (`GET /v1/users/me` → `ordination_temple`). `nil` khi cả hai đều không có.
    func loadMyTemple() async -> ILSanghaMyTempleEntity?
    func loadChooser() -> ILSanghaChooserEntity
    func selectMyTemple(id: String)
    /// Đặt 1 chùa của danh bạ (`/v1/temples`) làm chùa tu tập — lưu thêm bản chụp tên + địa chỉ để
    /// tab Chùa dựng thẻ chùa mà không cần gọi API.
    func selectMyTemple(_ temple: ILTempleSummaryEntity)
    /// `limit` ngày lễ / ngày trai giới gần nhất (dùng chung 2 trạng thái của tab).
    func loadUpcomingDays(limit: Int) -> [ILFestivalDayEntity]
}

final class ILSanghaUseCaseImpl: ILSanghaUseCase {

    /// Key lưu id chùa tu tập người dùng tự chọn trong `UserDefaultsService`; chưa có (hoặc rỗng) =
    /// dùng chùa trong hồ sơ tài khoản.
    static let myTempleKey = "sangha.myTempleID"
    /// Key lưu bản chụp (tên + địa chỉ) của chùa tu tập chọn từ danh bạ — chùa mẫu không cần.
    static let myTempleSnapshotKey = "sangha.myTempleSnapshot"

    private let userDefaultsService: UserDefaultsService
    private let accountRepository: ILAccountProfileRepository
    private let templeRepository: ILTempleRepository
    private let now: () -> Date

    init(
        userDefaultsService: UserDefaultsService,
        accountRepository: ILAccountProfileRepository,
        templeRepository: ILTempleRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.userDefaultsService = userDefaultsService
        self.accountRepository = accountRepository
        self.templeRepository = templeRepository
        self.now = now
    }

    func loadMyTemple() async -> ILSanghaMyTempleEntity? {
        // @ai: assumption — see Docs/Assumptions/Sangha/AS-Sangha-001-my-temple-stored-locally.md
        // Lựa chọn trong app (nếu có) thắng; không có thì lấy chùa trong hồ sơ tài khoản; hồ sơ không
        // có chùa (hoặc không tải được) = "chưa chọn chùa".
        var chosen = await loadChosenTemple()
        if chosen == nil { chosen = await loadProfileTemple() }
        guard let temple = chosen else { return nil }
        return Self.makeMockContent(for: temple, now: now())
    }

    /// Chùa người dùng tự chọn trong app; `nil` khi chưa chọn hoặc id đã lưu không còn dựng được thẻ.
    /// Chùa chọn từ danh bạ chỉ lưu bản chụp tên + địa chỉ, nên được làm đầy (ảnh bìa, giờ mở cửa,
    /// trụ trì) bằng chi tiết từ danh bạ; danh bạ không tải được thì dùng bản chụp.
    private func loadChosenTemple() async -> ILSanghaTempleEntity? {
        guard let storedID = userDefaultsService.load(key: Self.myTempleKey, type: String.self),
              !storedID.isEmpty else { return nil }
        if let mock = Self.mockTemples().first(where: { $0.id == storedID }) { return mock }
        if let detail = try? await templeRepository.loadTempleDetail(id: storedID) {
            return Self.makeTemple(from: detail)
        }
        return loadSnapshotTemple(id: storedID)
    }

    /// Chùa thọ giới trong hồ sơ tài khoản. Chi tiết (địa chỉ, giờ mở cửa, trụ trì) lấy từ danh bạ
    /// chùa; khi danh bạ không tải được vẫn hiện thẻ theo tên trong hồ sơ.
    private func loadProfileTemple() async -> ILSanghaTempleEntity? {
        guard let account = try? await accountRepository.loadAccountProfile(),
              let profileTemple = account.ordinationTemple else { return nil }
        if let detail = try? await templeRepository.loadTempleDetail(id: profileTemple.id) {
            return Self.makeTemple(from: detail)
        }
        return ILSanghaTempleEntity(
            id: profileTemple.id, name: profileTemple.name, address: "",
            abbot: "", operatingHours: "", distanceKm: 0
        )
    }

    private static func makeTemple(from detail: ILTempleDetailEntity) -> ILSanghaTempleEntity {
        ILSanghaTempleEntity(
            id: detail.id,
            name: detail.summary.name,
            address: detail.summary.location.address,
            abbot: detail.currentAbbot,
            operatingHours: detail.operatingHours,
            distanceKm: 0,
            imageURL: detail.summary.imageURL ?? detail.summary.thumbnailURL
        )
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
            value: MyTempleSnapshot(
                id: temple.id, name: temple.name, address: temple.location.address,
                imageURL: temple.imageURL ?? temple.thumbnailURL
            )
        )
        userDefaultsService.save(key: Self.myTempleKey, value: temple.id)
    }

    func loadUpcomingDays(limit: Int) -> [ILFestivalDayEntity] {
        let day: TimeInterval = 24 * 60 * 60
        let now = now()
        func makeDay(_ index: Int, offset: Int, titleKey: String, kind: ILFestivalKind) -> ILFestivalDayEntity {
            let date = now.addingTimeInterval(TimeInterval(offset) * day)
            let lunar = ILLunarCalendar.solarToLunar(date: date, calendar: Calendar(identifier: .gregorian))
            return ILFestivalDayEntity(
                id: "day-\(index)", date: date, title: titleKey.localized, kind: kind, daysUntil: offset,
                lunarDay: lunar.day, lunarMonth: lunar.month, isLeapMonth: lunar.isLeapMonth
            )
        }
        let days = [
            makeDay(1, offset: 2, titleKey: "sangha.mock.day.1", kind: .festival),
            makeDay(2, offset: 9, titleKey: "sangha.mock.day.2", kind: .observance),
            makeDay(3, offset: 24, titleKey: "sangha.mock.day.3", kind: .observance),
            makeDay(4, offset: 39, titleKey: "sangha.mock.day.4", kind: .festival)
        ]
        return Array(days.prefix(limit))
    }

    // MARK: - Snapshot
    private struct MyTempleSnapshot: Codable {
        let id: String
        let name: String
        let address: String
        /// Absent in snapshots saved before the cover image was shown.
        let imageURL: String?
    }

    /// Chùa chọn từ danh bạ: danh bạ không trả giờ mở cửa / trụ trì ở dạng liệt kê nên để trống
    /// (thẻ chùa tự ẩn pill trạng thái và hiện "Đang cập nhật").
    private func loadSnapshotTemple(id: String) -> ILSanghaTempleEntity? {
        guard let snapshot = userDefaultsService.load(key: Self.myTempleSnapshotKey, type: MyTempleSnapshot.self),
              snapshot.id == id else { return nil }
        return ILSanghaTempleEntity(
            id: snapshot.id, name: snapshot.name, address: snapshot.address,
            abbot: "", operatingHours: "", distanceKm: 0, imageURL: snapshot.imageURL
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
