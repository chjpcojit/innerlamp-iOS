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

    /// Chạm 1 ngày trong dải lịch tuần — chọn ngày đó và tính lại thẻ âm lịch lớn (`lunarDate`)
    /// cho ngày được chọn. Trả về entity gốc nếu không tìm thấy `id`.
    func selectDay(id: String, in entity: ILHomeEntity) -> ILHomeEntity

    /// Carousel "Sự kiện Phật giáo" — các sự kiện định kỳ theo âm lịch (từ Core Data) trong cả
    /// năm dương lịch hiện tại chứa `date`, gom theo tháng dương lịch. Bất đồng bộ vì đọc từ Core
    /// Data; tháng nào không có sự kiện thì không xuất hiện.
    func loadBuddhistEventMonths(around date: Date) async throws -> [ILHomeEventMonthEntity]

    /// Câu kinh trên thẻ âm lịch lớn — 1 câu ngẫu nhiên từ catalog kinh trong Core Data
    /// (`ILSutraQuoteUseCase.randomQuote()`). Không ném lỗi: catalog rỗng hoặc đọc lỗi thì trả câu
    /// tĩnh mặc định để thẻ không bao giờ trống.
    func loadRandomVerse() async -> ILHomeQuoteEntity
}

final class ILHomeUseCaseImpl: ILHomeUseCase {

    // TODO: khi có API nội dung/thống kê thật, thay phần mock bên dưới bằng
    // networkService.request(endpoint: HomeDashboardEndpoint(...)) (xem Core/Networking/NetworkService.swift).
    private let keychainService: KeychainService
    private let buddhistEventUseCase: ILBuddhistEventUseCase
    private let deityUseCase: ILDeityUseCase
    private let sutraQuoteUseCase: ILSutraQuoteUseCase

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

    init(
        keychainService: KeychainService,
        buddhistEventUseCase: ILBuddhistEventUseCase,
        deityUseCase: ILDeityUseCase,
        sutraQuoteUseCase: ILSutraQuoteUseCase
    ) {
        self.keychainService = keychainService
        self.buddhistEventUseCase = buddhistEventUseCase
        self.deityUseCase = deityUseCase
        self.sutraQuoteUseCase = sutraQuoteUseCase
    }

    func getInitialState() -> ILHomeEntity {
        // Trả về tên thô (có thể rỗng) — fallback "khách" + format câu chào là việc của
        // `ILHomeViewModel` khi map sang `ILHomeStateModel`, không phải của Entity.
        let displayName = (try? keychainService.load(key: StorageKeys.pendingSignUp, type: PendingSignUp.self))?.displayName ?? ""

        var entity = ILHomeEntity()
        entity.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        let today = Date()
        entity.weekPages = Self.makeWeekPages(around: today)
        entity.selectedDayID = entity.weekPages.flatMap(\.days).first(where: \.isToday)?.id ?? ""
        // Câu kinh để trống — nạp ngẫu nhiên từ Core Data qua `loadRandomVerse()` ngay sau đó.
        entity.lunarDate = Self.makeLunarDate(for: today, verse: ILHomeQuoteEntity())

        // Sự kiện Phật giáo định kỳ được nạp bất đồng bộ từ Core Data qua
        // `loadBuddhistEventMonths(around:)` — khởi tạo rỗng để `getInitialState()` vẫn đồng bộ.
        entity.eventMonths = []

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
                kind: .meditation,
                title: "home.session.breathing.title".localized,
                subtitle: "home.session.breathing.subtitle".localized,
                trailingText: "home.session.breathing.trailing".localized,
                tone: .green,
                glyph: .leaf
            ),
            ILHomeSuggestedSessionEntity(
                id: "sutra",
                kind: .sutra,
                title: "home.session.sutra.title".localized,
                subtitle: "home.session.sutra.subtitle".localized,
                trailingText: "home.session.sutra.trailing".localized,
                tone: .gold,
                glyph: .book
            ),
            ILHomeSuggestedSessionEntity(
                id: "offering",
                kind: .offering,
                title: "home.session.offering.title".localized,
                subtitle: "home.session.offering.subtitle".localized,
                trailingText: "home.session.offering.trailing".localized,
                tone: .rose,
                glyph: .circle
            )
        ]

        // TODO: khi có API ảnh chùa thật, thay danh sách mock dưới đây bằng dữ liệu từ
        // networkService (gallery "Ảnh chùa đẹp", xem README design handoff).
        entity.photos = (1...12).map { ILHomePhotoEntity(id: "pg-\($0)") }

        // TODO: khi có API chùa thật, thay danh sách mock dưới đây bằng dữ liệu từ
        // networkService (danh mục "Chùa Việt Nam", xem README design handoff).
        entity.temples = [
            ILHomeTempleEntity(id: "tp-motcot", name: "home.temple.motcot.name".localized, place: "home.temple.motcot.place".localized, region: "home.temple.motcot.region".localized, note: "home.temple.motcot.note".localized),
            ILHomeTempleEntity(id: "tp-tranquoc", name: "home.temple.tranquoc.name".localized, place: "home.temple.tranquoc.place".localized, region: "home.temple.tranquoc.region".localized, note: "home.temple.tranquoc.note".localized),
            ILHomeTempleEntity(id: "tp-huong", name: "home.temple.huong.name".localized, place: "home.temple.huong.place".localized, region: "home.temple.huong.region".localized, note: "home.temple.huong.note".localized),
            ILHomeTempleEntity(id: "tp-baidinh", name: "home.temple.baidinh.name".localized, place: "home.temple.baidinh.place".localized, region: "home.temple.baidinh.region".localized, note: "home.temple.baidinh.note".localized),
            ILHomeTempleEntity(id: "tp-thienmu", name: "home.temple.thienmu.name".localized, place: "home.temple.thienmu.place".localized, region: "home.temple.thienmu.region".localized, note: "home.temple.thienmu.note".localized),
            ILHomeTempleEntity(id: "tp-linhung", name: "home.temple.linhung.name".localized, place: "home.temple.linhung.place".localized, region: "home.temple.linhung.region".localized, note: "home.temple.linhung.note".localized),
            ILHomeTempleEntity(id: "tp-truclam", name: "home.temple.truclam.name".localized, place: "home.temple.truclam.place".localized, region: "home.temple.truclam.region".localized, note: "home.temple.truclam.note".localized),
            ILHomeTempleEntity(id: "tp-vinhnghiem", name: "home.temple.vinhnghiem.name".localized, place: "home.temple.vinhnghiem.place".localized, region: "home.temple.vinhnghiem.region".localized, note: "home.temple.vinhnghiem.note".localized)
        ]

        // TODO: khi có API bài viết thật, thay danh sách mock dưới đây bằng dữ liệu từ
        // networkService (danh mục "Bài viết Phật pháp hay", xem README design handoff).
        entity.articles = [
            ILHomeArticleEntity(id: "art-1", category: "home.article.0.category".localized, title: "home.article.0.title".localized, author: "home.article.0.author".localized, readMinutes: 6),
            ILHomeArticleEntity(id: "art-2", category: "home.article.1.category".localized, title: "home.article.1.title".localized, author: "home.article.1.author".localized, readMinutes: 4),
            ILHomeArticleEntity(id: "art-3", category: "home.article.2.category".localized, title: "home.article.2.title".localized, author: "home.article.2.author".localized, readMinutes: 5),
            ILHomeArticleEntity(id: "art-4", category: "home.article.3.category".localized, title: "home.article.3.title".localized, author: "home.article.3.author".localized, readMinutes: 5),
            ILHomeArticleEntity(id: "art-5", category: "home.article.4.category".localized, title: "home.article.4.title".localized, author: "home.article.4.author".localized, readMinutes: 7)
        ]

        // Thư viện "Phật & Bồ Tát" — bản tóm tắt cho carousel Trang chủ, map từ catalog đầy đủ
        // của `ILDeityUseCase` (cùng id để chạm thẻ mở đúng màn chi tiết `Deity`).
        entity.deities = deityUseCase.getAllDeities().map {
            ILHomeDeityEntity(
                id: $0.id,
                kind: $0.kind,
                name: $0.nameVi,
                honorific: $0.titleHonorific,
                virtue: $0.coreVirtue,
                memorialDay: Self.primaryMemorialDay(of: $0.memorialDays)
            )
        }

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

    func selectDay(id: String, in entity: ILHomeEntity) -> ILHomeEntity {
        guard let day = entity.weekPages.flatMap(\.days).first(where: { $0.id == id }) else {
            return entity
        }
        var newEntity = entity
        newEntity.selectedDayID = id
        // Giữ nguyên câu kinh đã nạp — đổi ngày chỉ đổi phần ngày dương/âm của thẻ.
        newEntity.lunarDate = Self.makeLunarDate(for: day.date, verse: entity.lunarDate.verse)
        return newEntity
    }

    // MARK: - Lunar calendar

    /// Dải lịch tuần Trang chủ — 5 trang tuần (2 trước, hiện tại, 2 sau), mỗi trang 7 ngày Thứ Hai
    /// → Chủ nhật. Số ngày âm, tháng âm và cờ Hoàng đạo/Hắc đạo tính bằng `ILLunarCalendar`
    /// (không phải nội dung tĩnh).
    private static func makeWeekPages(around date: Date) -> [ILHomeWeekPageEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Thứ Hai

        let today = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else { return [] }

        return (-2...2).compactMap { weekOffset -> ILHomeWeekPageEntity? in
            guard let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: monday) else { return nil }

            let days = (0..<7).compactMap { offset -> ILHomeWeekDayEntity? in
                guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
                let lunar = ILLunarCalendar.solarToLunar(date: day, calendar: calendar)
                let solarDay = calendar.component(.day, from: day)
                let solarMonth = calendar.component(.month, from: day)
                let solarYear = calendar.component(.year, from: day)
                return ILHomeWeekDayEntity(
                    id: ISO8601DateFormatter().string(from: day),
                    date: day,
                    solarDay: solarDay,
                    lunarDay: lunar.day,
                    lunarMonth: lunar.month,
                    isHoangDao: ILLunarCalendar.isHoangDao(
                        solarDay: solarDay,
                        solarMonth: solarMonth,
                        solarYear: solarYear,
                        lunarMonth: lunar.month
                    ),
                    isToday: calendar.isDate(day, inSameDayAs: today)
                )
            }

            return ILHomeWeekPageEntity(
                id: ISO8601DateFormatter().string(from: weekStart),
                label: Self.weekPageLabel(days: days, weekStart: weekStart, calendar: calendar),
                days: days
            )
        }
    }

    /// Nhãn khoảng tháng của 1 trang tuần — "Tháng 9, 2026" (1 tháng) hoặc
    /// "Tháng 9 – Tháng 10, 2026" (tuần vắt qua 2 tháng), năm lấy theo ngày đầu tuần (khớp design
    /// handoff).
    private static func weekPageLabel(days: [ILHomeWeekDayEntity], weekStart: Date, calendar: Calendar) -> String {
        var uniqueMonths: [Int] = []
        for day in days {
            let month = calendar.component(.month, from: day.date)
            if !uniqueMonths.contains(month) { uniqueMonths.append(month) }
        }
        let year = calendar.component(.year, from: weekStart)
        if uniqueMonths.count == 1, let month = uniqueMonths.first {
            return String(format: "home.week.label.single".localized, month, year)
        }
        if let first = uniqueMonths.first, let last = uniqueMonths.last {
            return String(format: "home.week.label.range".localized, first, last, year)
        }
        return ""
    }

    /// Thẻ âm lịch lớn Trang chủ — ngày dương (hôm nay hoặc ngày được chọn) + ngày/tháng/năm âm
    /// tương ứng; câu kinh truyền vào từ ngoài (nạp bất đồng bộ qua `loadRandomVerse()`).
    private static func makeLunarDate(for date: Date, verse: ILHomeQuoteEntity) -> ILHomeLunarDateEntity {
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
        entity.verse = verse
        return entity
    }

    // MARK: - Verse

    func loadRandomVerse() async -> ILHomeQuoteEntity {
        do {
            guard let quote = try await sutraQuoteUseCase.randomQuote() else { return Self.fallbackVerse }
            return Self.makeVerse(from: quote)
        } catch {
            // Non-fatal: the card keeps a static verse instead of showing an empty block.
            return Self.fallbackVerse
        }
    }

    /// Nguồn trích dẫn dạng "— Kinh Pháp Cú (Dhammapada), câu 5" — cùng khuôn với câu tĩnh mặc định.
    static func makeVerse(from quote: ILSutraQuoteEntity) -> ILHomeQuoteEntity {
        ILHomeQuoteEntity(quote: quote)
    }

    static var fallbackVerse: ILHomeQuoteEntity {
        ILHomeQuoteEntity(
            lines: ["home.lunar.verse.line1".localized, "home.lunar.verse.line2".localized],
            source: "home.lunar.verse.source".localized
        )
    }

    /// Carousel "Sự kiện Phật giáo" — các sự kiện định kỳ theo âm lịch (từ Core Data) xuất hiện
    /// trong cả năm dương lịch hiện tại (1/1 → 31/12), gom theo tháng. Mỗi ngày dương trong
    /// khoảng được đổi sang âm lịch để tìm sự kiện trùng `lunarDay`/`lunarMonth` (xem
    /// `ILBuddhistEventUseCase.occurrences`).
    func loadBuddhistEventMonths(around date: Date) async throws -> [ILHomeEventMonthEntity] {
        let templates = try await buddhistEventUseCase.loadTemplates()
        guard !templates.isEmpty else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        // Cả năm dương lịch hiện tại (1/1 → 31/12). `dateInterval(of: .year)` trả khoảng nửa mở
        // (`end` = 1/1 năm sau), khớp hợp đồng `day < lastDay` của `occurrences`.
        guard let yearInterval = calendar.dateInterval(of: .year, for: date) else { return [] }
        let start = yearInterval.start
        let end = yearInterval.end

        let occurrences = buddhistEventUseCase.occurrences(
            of: templates,
            from: start,
            to: end,
            calendar: calendar
        )

        // Gom theo tháng dương lịch, giữ thứ tự thời gian của tháng xuất hiện đầu tiên.
        var order: [String] = []
        var eventsByMonth: [String: [ILBuddhistEventOccurrenceEntity]] = [:]
        for occurrence in occurrences {
            let key = Self.monthKey(for: occurrence.date, calendar: calendar)
            if eventsByMonth[key] == nil { order.append(key) }
            eventsByMonth[key, default: []].append(occurrence)
        }

        return order.compactMap { key in
            guard let items = eventsByMonth[key], let first = items.first else { return nil }
            let month = calendar.component(.month, from: first.date)
            return ILHomeEventMonthEntity(
                id: key,
                monthLabel: String(format: "home.events.monthFormat".localized, month),
                events: items.map { occurrence in
                    ILHomeEventItemEntity(
                        id: "\(occurrence.template.id)-\(Self.dayKey(for: occurrence.date, calendar: calendar))",
                        date: occurrence.date,
                        title: occurrence.template.title,
                        lunarLabel: Self.lunarLabel(for: occurrence.template),
                        tone: Self.tone(for: occurrence.template.tradition)
                    )
                }
            )
        }
    }

    /// Ngày vía chính hiển thị trên thẻ carousel "Thư viện Phật & Bồ Tát": ưu tiên ngày đản sinh
    /// ("Đản") hoặc ngày có chữ "Vía" (vd. Thích Ca → Phật Đản 15/4, Quán Thế Âm → Đản sinh 19/2),
    /// ngược lại lấy ngày lễ đầu tiên của catalog.
    static func primaryMemorialDay(of days: [ILDeityMemorialDayEntity]) -> ILDeityMemorialDayEntity? {
        days.first { $0.eventName.contains("Đản") || $0.eventName.contains("Vía") } ?? days.first
    }

    /// Khóa tháng dương lịch `yyyy-MM` — dùng để gom và làm id ổn định cho thẻ tháng.
    private static func monthKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    /// Khóa ngày dương lịch `yyyy-MM-dd` — ghép vào id sự kiện để phân biệt các lần xuất hiện.
    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    /// Nhãn âm lịch ngắn cho 1 sự kiện — "Rằm · Tháng Tư", "Mùng 1 · Tháng Giêng", "19 · Tháng Hai".
    private static func lunarLabel(for template: ILBuddhistEventTemplateEntity) -> String {
        let monthName = ILLunarCalendar.lunarMonthLabel(template.lunarMonth, isLeap: false)
        let dayLabel: String
        switch template.lunarDay {
        case 1: dayLabel = "lunarCalendar.day.newMoon".localized
        case 15: dayLabel = "lunarCalendar.day.fullMoon".localized
        default: dayLabel = "\(template.lunarDay)"
        }
        return "\(dayLabel) · \(monthName)"
    }

    /// Tông màu hiển thị theo truyền thống — chỉ dùng trong carousel Trang chủ (xem
    /// `ILHomeEventTone`).
    private static func tone(for tradition: ILBuddhistTradition) -> ILHomeEventTone {
        switch tradition {
        case .mahayana: return .gold
        case .theravada: return .green
        case .universal: return .rose
        }
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
