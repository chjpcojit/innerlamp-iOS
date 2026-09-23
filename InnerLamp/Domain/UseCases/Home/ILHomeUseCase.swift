//
//  ILHomeUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILHomeUseCase {
    func getInitialState() -> ILHomeEntity

    /// Chạm vòng tràng hạt +1. Khi vượt `malaGoal` thì quay lại 1 (bắt đầu tràng mới),
    /// khớp thao tác đếm hạt thực tế thay vì dừng cứng ở 108.
    func incrementBead(_ entity: ILHomeEntity) -> ILHomeEntity

    /// Bấm "Bắt đầu lại" — đưa số hạt về 0.
    func resetBeads(_ entity: ILHomeEntity) -> ILHomeEntity
}

final class ILHomeUseCaseImpl: ILHomeUseCase {

    // TODO: khi có API nội dung/thống kê thật, thay phần mock bên dưới bằng
    // networkService.request(endpoint: HomeDashboardEndpoint(...)) (xem Core/Networking/NetworkService.swift).
    private let keychainService: KeychainService

    /// Cùng key/struct với `ILSignUpUseCaseImpl`/`ILLoginUseCaseImpl` — dùng tạm để lấy pháp danh
    /// đã đăng ký cho lời chào, tới khi có phiên đăng nhập thật (session/current-user service).
    private enum StorageKeys {
        static let pendingSignUp = "signup_pending_credentials"
    }

    private struct PendingSignUp: Codable {
        let displayName: String
        let phoneNumber: String
        let password: String
    }

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }

    func getInitialState() -> ILHomeEntity {
        // Trả về tên thô (có thể rỗng) — fallback "khách" + format câu chào là việc của
        // `ILHomeViewModel` khi map sang `ILHomeStateModel`, không phải của Entity.
        let displayName = (try? keychainService.load(key: StorageKeys.pendingSignUp, type: PendingSignUp.self))?.displayName ?? ""

        var entity = ILHomeEntity()
        entity.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        let today = Date()
        entity.weekDays = Self.makeWeekDays(around: today)
        entity.lunarDate = Self.makeLunarDate(for: today)

        // TODO: khi có API sự kiện chùa thật, thay `makeEventMonths` bằng dữ liệu từ
        // networkService (danh mục sự kiện Phật giáo theo tháng, xem README design handoff).
        entity.eventMonths = Self.makeEventMonths(around: today)

        entity.sessionMinutesDone = 12
        entity.sessionMinutesGoal = 20

        entity.streakDays = 42
        entity.streakWeekProgress = [0.3, 0.5, 0.7, 1.0, 0.4, 0.6, 1.0]

        entity.malaCount = 0
        entity.malaGoal = 108
        entity.malaMantraText = "home.mala.mantra".localized

        entity.suggestedSessions = [
            ILHomeSuggestedSessionEntity(
                id: "breathing",
                title: "home.session.breathing.title".localized,
                subtitle: "home.session.breathing.subtitle".localized,
                trailingText: "home.session.breathing.trailing".localized,
                tone: .green,
                glyph: .leaf
            ),
            ILHomeSuggestedSessionEntity(
                id: "sutra",
                title: "home.session.sutra.title".localized,
                subtitle: "home.session.sutra.subtitle".localized,
                trailingText: "home.session.sutra.trailing".localized,
                tone: .gold,
                glyph: .book
            ),
            ILHomeSuggestedSessionEntity(
                id: "offering",
                title: "home.session.offering.title".localized,
                subtitle: "home.session.offering.subtitle".localized,
                trailingText: "home.session.offering.trailing".localized,
                tone: .rose,
                glyph: .circle
            )
        ]

        return entity
    }

    func incrementBead(_ entity: ILHomeEntity) -> ILHomeEntity {
        var newEntity = entity
        let next = entity.malaCount + 1
        newEntity.malaCount = next > entity.malaGoal ? 1 : next
        return newEntity
    }

    func resetBeads(_ entity: ILHomeEntity) -> ILHomeEntity {
        var newEntity = entity
        newEntity.malaCount = 0
        return newEntity
    }

    // MARK: - Lunar calendar

    /// Dải lịch tuần Trang chủ — 7 ngày Thứ Hai → Chủ nhật của tuần chứa `date`, số ngày âm
    /// tính bằng `ILLunarCalendar` (không phải nội dung tĩnh).
    private static func makeWeekDays(around date: Date) -> [ILHomeWeekDayEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Thứ Hai

        let today = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else { return [] }

        return (0..<7).compactMap { offset -> ILHomeWeekDayEntity? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
            return ILHomeWeekDayEntity(
                id: ISO8601DateFormatter().string(from: day),
                date: day,
                solarDay: calendar.component(.day, from: day),
                lunarDay: lunar.day,
                isToday: calendar.isDate(day, inSameDayAs: today)
            )
        }
    }

    /// Thẻ âm lịch lớn Trang chủ — ngày dương hôm nay + ngày/tháng/năm âm tương ứng, câu kinh
    /// trích trong ngày lấy từ nội dung tĩnh (chưa có API "lời dạy hôm nay" thật).
    private static func makeLunarDate(for date: Date) -> ILHomeLunarDateEntity {
        let calendar = Calendar(identifier: .gregorian)
        let lunar = ILLunarCalendar.solarToLunar(date: date, calendar: calendar)

        let solarFormatter = DateFormatter()
        solarFormatter.locale = Locale(identifier: "vi_VN")
        solarFormatter.setLocalizedDateFormatFromTemplate("EEEE, d MMMM")

        var entity = ILHomeLunarDateEntity()
        entity.solarLabel = solarFormatter.string(from: date).capitalizingFirstLetter()
        entity.lunarDay = lunar.day
        entity.lunarMonthLabel = ILLunarCalendar.lunarMonthLabel(lunar.month, isLeap: lunar.isLeapMonth)
        entity.lunarYearLabel = String(format: "home.lunar.yearFormat".localized, ILLunarCalendar.canChiYear(lunar.year))
        entity.verse = ILHomeQuoteEntity(
            lines: ["home.lunar.verse.line1".localized, "home.lunar.verse.line2".localized],
            source: "home.lunar.verse.source".localized
        )
        return entity
    }

    /// Carousel "Sự kiện Phật giáo" — dữ liệu mẫu 3 tháng quanh `date` (tháng hiện tại đứng
    /// đầu). TODO: thay bằng API sự kiện chùa thật khi có (xem README design handoff, mục
    /// "Data cần API").
    private static func makeEventMonths(around date: Date) -> [ILHomeEventMonthEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        func makeEvent(daysFromNow: Int, title: String, lunarLabel: String, tone: ILHomeEventTone) -> ILHomeEventItemEntity {
            let eventDate = calendar.date(byAdding: .day, value: daysFromNow, to: date) ?? date
            return ILHomeEventItemEntity(
                id: "\(daysFromNow)-\(title)",
                date: eventDate,
                title: title,
                lunarLabel: lunarLabel,
                tone: tone
            )
        }

        let currentMonthLabel = String(format: "home.events.monthFormat".localized, calendar.component(.month, from: date))
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        let nextMonthLabel = String(format: "home.events.monthFormat".localized, calendar.component(.month, from: nextMonthDate))

        return [
            ILHomeEventMonthEntity(
                id: "month-current",
                monthLabel: currentMonthLabel,
                events: [
                    makeEvent(daysFromNow: 2, title: "home.events.vuLan.title".localized, lunarLabel: "home.events.vuLan.lunar".localized, tone: .gold),
                    makeEvent(daysFromNow: 5, title: "home.events.eveningSession.title".localized, lunarLabel: "home.events.eveningSession.lunar".localized, tone: .green),
                    makeEvent(daysFromNow: 12, title: "home.events.fastDay.title".localized, lunarLabel: "home.events.fastDay.lunar".localized, tone: .rose)
                ]
            ),
            ILHomeEventMonthEntity(
                id: "month-next",
                monthLabel: nextMonthLabel,
                events: [
                    makeEvent(daysFromNow: 34, title: "home.events.repentance.title".localized, lunarLabel: "home.events.repentance.lunar".localized, tone: .gold)
                ]
            )
        ]
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
