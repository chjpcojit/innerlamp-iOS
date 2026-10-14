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

    /// Carousel "Sự kiện Phật giáo" — các sự kiện của cả năm dương lịch chứa `date` (1/1 → 31/12)
    /// từ `GET /v1/calendar/events` (network-only), gom theo tháng dương lịch; tháng nào không có
    /// sự kiện thì không xuất hiện. Throws `ILCatalogError` when the server is unreachable.
    func loadBuddhistEventMonths(around date: Date) async throws -> [ILHomeEventMonthEntity]

    /// Câu kinh trên thẻ âm lịch lớn — 1 câu ngẫu nhiên từ catalog kinh trong Core Data
    /// (`ILSutraQuoteUseCase.randomQuote()`). Không ném lỗi: catalog rỗng hoặc đọc lỗi thì trả câu
    /// tĩnh mặc định để thẻ không bao giờ trống.
    func loadRandomVerse() async -> ILHomeQuoteEntity

    /// Carousel "Chùa Việt Nam" — the featured temples from `GET /v1/temples/top` (network-first,
    /// cached copy when offline). Throws `ILCatalogError` when neither is available.
    func loadTopTemples() async throws -> [ILHomeTempleEntity]

    /// Carousel "Thư viện Phật & Bồ Tát" — the featured deities from `GET /v1/deities/top`
    /// (network-first, cached copy when offline). Server data only: the summary has no memorial
    /// days, so `memorialDay` is always `nil` (the card shows the "updating" placeholder). Throws
    /// `ILCatalogError` when neither the server nor the cache answers.
    func loadTopDeities() async throws -> [ILHomeDeityEntity]

    /// Section "Bài viết Phật pháp hay" — the featured articles from `GET /v1/articles/top`, in the
    /// server's curated order (network-only). Throws `ILCatalogError` when the server is unreachable.
    func loadTopArticles() async throws -> [ILHomeArticleEntity]

    /// Block "Ảnh chùa đẹp" — the featured gallery photos from `GET /v1/gallery/top`, in the
    /// server's curated order (network-only). Throws `ILCatalogError` when the server is unreachable.
    func loadTopPhotos() async throws -> [ILHomePhotoEntity]
}

final class ILHomeUseCaseImpl: ILHomeUseCase {

    // TODO: khi có API nội dung/thống kê thật, thay phần mock bên dưới bằng
    // networkService.request(endpoint: HomeDashboardEndpoint(...)) (xem Core/Networking/NetworkService.swift).
    // Temples + deities already come from the server (`loadTopTemples()` / `loadTopDeities()`).
    private let calendarEventRepository: ILCalendarEventRepository
    private let sutraQuoteUseCase: ILSutraQuoteUseCase
    private let templeRepository: ILTempleRepository
    private let deityCatalogRepository: ILDeityCatalogRepository
    private let articleRepository: ILArticleRepository
    private let photosRepository: ILPhotosRepository

    init(
        calendarEventRepository: ILCalendarEventRepository,
        sutraQuoteUseCase: ILSutraQuoteUseCase,
        templeRepository: ILTempleRepository,
        deityCatalogRepository: ILDeityCatalogRepository,
        articleRepository: ILArticleRepository,
        photosRepository: ILPhotosRepository
    ) {
        self.calendarEventRepository = calendarEventRepository
        self.sutraQuoteUseCase = sutraQuoteUseCase
        self.templeRepository = templeRepository
        self.deityCatalogRepository = deityCatalogRepository
        self.articleRepository = articleRepository
        self.photosRepository = photosRepository
    }

    func getInitialState() -> ILHomeEntity {
        // Tên để trống — fallback "khách" + format câu chào là việc của `ILHomeViewModel`. Lời
        // chào chưa có nguồn tên thật (TD-Home-002): nó từng đọc mật khẩu+tên từ một item Keychain
        // tạm, nay đã bỏ vì lưu mật khẩu thô là không chấp nhận được.
        var entity = ILHomeEntity()

        let today = Date()
        entity.weekPages = Self.makeWeekPages(around: today)
        entity.selectedDayID = entity.weekPages.flatMap(\.days).first(where: \.isToday)?.id ?? ""
        // Câu kinh để trống — nạp ngẫu nhiên từ Core Data qua `loadRandomVerse()` ngay sau đó.
        entity.lunarDate = Self.makeLunarDate(for: today, verse: ILHomeQuoteEntity())

        // Sự kiện Phật giáo được nạp bất đồng bộ từ server qua
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

        // Temples, deities, articles + photos are loaded asynchronously from the server via
        // `loadTopTemples()` / `loadTopDeities()` / `loadTopArticles()` / `loadTopPhotos()` — start
        // empty so `getInitialState()` stays synchronous.
        entity.photos = []
        entity.temples = []
        entity.deities = []
        entity.articles = []

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

    // MARK: - Temple / deity catalog (server)

    func loadTopTemples() async throws -> [ILHomeTempleEntity] {
        try await templeRepository.loadTopTemples().map(Self.makeTemple(from:))
    }

    func loadTopDeities() async throws -> [ILHomeDeityEntity] {
        try await deityCatalogRepository.loadTopDeities().map(Self.makeDeity(from:))
    }

    func loadTopArticles() async throws -> [ILHomeArticleEntity] {
        try await articleRepository.loadTopArticles().map(Self.makeArticle(from:))
    }

    func loadTopPhotos() async throws -> [ILHomePhotoEntity] {
        try await photosRepository.loadTopPhotos().map {
            ILHomePhotoEntity(id: $0.id, thumbnailURL: $0.thumbnailURL)
        }
    }

    static func makeArticle(from summary: ILArticleSummaryEntity) -> ILHomeArticleEntity {
        ILHomeArticleEntity(
            id: summary.id,
            category: summary.category,
            title: summary.title,
            author: summary.author,
            readMinutes: summary.readMinutes,
            thumbnailURL: summary.thumbnailURL ?? summary.imageURL
        )
    }

    static func makeTemple(from summary: ILTempleSummaryEntity) -> ILHomeTempleEntity {
        ILHomeTempleEntity(
            id: summary.id,
            name: summary.name,
            address: summary.location.address,
            region: summary.region,
            heritageRank: summary.heritageRank,
            establishedYear: summary.establishedYear,
            thumbnailURL: summary.thumbnailURL
        )
    }

    static func makeDeity(from summary: ILDeitySummaryEntity) -> ILHomeDeityEntity {
        ILHomeDeityEntity(
            id: summary.id,
            kind: summary.kind,
            name: summary.nameVi,
            honorific: summary.titleHonorific,
            virtue: summary.coreVirtue,
            // `/v1/deities/top` carries no memorial days — filled once the API adds them.
            memorialDay: nil,
            thumbnailURL: summary.thumbnailURL.isEmpty ? summary.imageURL : summary.thumbnailURL
        )
    }

    /// Carousel "Sự kiện Phật giáo" — sự kiện của cả năm dương lịch chứa `date` (1/1 → 31/12) từ
    /// server, gom theo tháng dương lịch theo thứ tự thời gian. Ngày dương và âm lịch đều do server
    /// tính; client chỉ gom nhóm và đặt nhãn.
    func loadBuddhistEventMonths(around date: Date) async throws -> [ILHomeEventMonthEntity] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let year = calendar.component(.year, from: date)
        let calendarEvents = try await calendarEventRepository.loadEvents(year: year)
        let eventsByCode = Dictionary(calendarEvents.events.map { ($0.code, $0) }) { first, _ in first }

        // Gom theo tháng dương lịch, giữ thứ tự thời gian của tháng xuất hiện đầu tiên.
        var order: [String] = []
        var itemsByMonth: [String: [ILHomeEventItemEntity]] = [:]
        for occurrence in calendarEvents.occurrences.sorted(by: { $0.solarDate < $1.solarDate }) {
            guard let event = eventsByCode[occurrence.eventCode] else { continue }
            let key = Self.monthKey(for: occurrence.solarDate, calendar: calendar)
            if itemsByMonth[key] == nil { order.append(key) }
            itemsByMonth[key, default: []].append(
                ILHomeEventItemEntity(
                    id: "\(event.code)-\(Self.dayKey(for: occurrence.solarDate, calendar: calendar))",
                    date: occurrence.solarDate,
                    title: event.name,
                    lunarLabel: Self.lunarLabel(for: occurrence),
                    tone: Self.tone(forGroups: event.groupCodes),
                    eventCode: event.code
                )
            )
        }

        return order.compactMap { key in
            guard let items = itemsByMonth[key], let first = items.first else { return nil }
            let month = calendar.component(.month, from: first.date)
            return ILHomeEventMonthEntity(
                id: key,
                monthLabel: String(format: "home.events.monthFormat".localized, month),
                events: items
            )
        }
    }

    /// Ngày vía chính hiển thị trên thẻ carousel "Thư viện Phật & Bồ Tát": ưu tiên ngày đản sinh
    /// ("Đản") hoặc ngày có chữ "Vía" (vd. Thích Ca → Phật Đản 15/4, Quán Thế Âm → Đản sinh 19/2),
    /// ngược lại lấy ngày lễ đầu tiên của catalog. Logic nằm trên `ILDeityEntity` (Domain) để dùng
    /// chung với màn danh sách "Chư Phật & Bồ Tát"; giữ lại hàm này cho call site + test cũ.
    static func primaryMemorialDay(of days: [ILDeityMemorialDayEntity]) -> ILDeityMemorialDayEntity? {
        ILDeityEntity.primaryMemorialDay(of: days)
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

    /// Nhãn âm lịch ngắn cho 1 lần xuất hiện — "Rằm · Tháng Tư", "Mùng 1 · Tháng Giêng",
    /// "19 · Tháng Hai"; tháng nhuận được ghi rõ.
    private static func lunarLabel(for occurrence: ILCalendarOccurrenceEntity) -> String {
        let monthName = ILLunarCalendar.lunarMonthLabel(occurrence.lunarMonth, isLeap: occurrence.isLeapMonth)
        let dayLabel: String
        switch occurrence.lunarDay {
        case 1: dayLabel = "lunarCalendar.day.newMoon".localized
        case 15: dayLabel = "lunarCalendar.day.fullMoon".localized
        default: dayLabel = "\(occurrence.lunarDay)"
        }
        return "\(dayLabel) · \(monthName)"
    }

    /// Tông màu hiển thị theo nhóm của sự kiện — chỉ dùng trong carousel Trang chủ (xem
    /// `ILHomeEventTone`). Nhóm Phật giáo lấy ưu tiên; mã nhóm lạ (BO thêm về sau) rơi về `.rose`.
    private static func tone(forGroups groupCodes: [String]) -> ILHomeEventTone {
        if groupCodes.contains("buddhist") { return .gold }
        if groupCodes.contains("folk") { return .green }
        return .rose
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
