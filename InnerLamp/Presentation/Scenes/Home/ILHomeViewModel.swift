//
//  ILHomeViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

/// Chuyển giữa các tab (Trang chủ / Thư viện / Đạo tràng / Tôi) do `ILMainTabBarController` lo,
/// không đi qua ViewModel. Các màn con còn lại của Trang chủ (thông báo, hồ sơ, chi tiết
/// thời khóa...) chưa nằm trong scope — thêm case khi có màn tương ứng.
enum ILHomeNavEvent: Equatable {
    /// Link "Toàn màn hình" ở thẻ tràng hạt — mở màn Niệm Phật toàn màn hình.
    case openMala
    /// Link "Lịch âm" ở dải lịch tuần — mở màn Lịch âm.
    case openLunarCalendar
    /// Chạm thẻ âm lịch lớn — mở màn Chi tiết ngày âm với ngày dương đang chọn.
    /// `verse` is the quote currently shown on the hero card (nil while it is still loading), so the
    /// detail screen shows the same quote instead of its own.
    case openLunarDayDetail(date: Date, verse: ILHomeQuoteEntity?)
    /// Nút "Xem tất cả" hoặc chạm ô ảnh ở khối "Ảnh chùa đẹp" — mở màn Ảnh chùa đẹp.
    case openPhotos
    /// Thẻ "Chuông mõ" — mở màn Chuông mõ.
    case openBell
    /// Nút "Tất cả" / chạm 1 lễ ở mục "Sự kiện Phật giáo" — mở màn Lịch lễ Phật giáo.
    case openFestivals
    /// Chạm 1 bài viết ở khối "Bài viết Phật pháp hay" — mở màn Bài viết với `id` bài.
    case openArticle(id: String)
    /// Link "Xem tất cả" ở khối "Bài viết Phật pháp hay" — mở màn Tất cả bài viết.
    case openArticles
    /// Chạm 1 chùa trong carousel "Chùa Việt Nam" — mở màn Trang chùa với `id` chùa.
    case openTemple(id: String)
    /// Chạm 1 vị Phật / Bồ Tát trong carousel "Thư viện Phật & Bồ Tát" — mở màn chi tiết `id`.
    case openDeity(id: String)
    /// Chạm 1 hàng thiền trong "Thời khóa gợi ý" — mở màn Chuẩn bị thiền (`setup`).
    case openMeditationSetup
}

protocol ILHomeViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILHomeCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILHomeNavEvent, Never> { get }
}

final class ILHomeViewModel: ILHomeViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let beadTapped: AnyPublisher<Void, Never>
        let resetBeadsTapped: AnyPublisher<Void, Never>
        let malaFullscreenTapped: AnyPublisher<Void, Never>
        let lunarCalendarTapped: AnyPublisher<Void, Never>
        /// Chạm thẻ âm lịch lớn — mở màn Chi tiết ngày âm với ngày đang chọn.
        let lunarHeroTapped: AnyPublisher<Void, Never>
        /// Chạm 1 ngày trong dải lịch tuần — mang theo `id` ngày để chọn + cập nhật thẻ âm lịch lớn.
        let dayTapped: AnyPublisher<String, Never>
        let photosTapped: AnyPublisher<Void, Never>
        let bellTapped: AnyPublisher<Void, Never>
        let eventsTapped: AnyPublisher<Void, Never>
        let articleTapped: AnyPublisher<String, Never>
        /// Link "Xem tất cả" ở khối "Bài viết Phật pháp hay".
        let articlesViewAllTapped: AnyPublisher<Void, Never>
        /// Chạm 1 chùa trong carousel "Chùa Việt Nam" — mang theo `id` chùa.
        let templeTapped: AnyPublisher<String, Never>
        /// Chạm 1 vị Phật / Bồ Tát trong carousel "Thư viện Phật & Bồ Tát" — mang theo `id`.
        let deityTapped: AnyPublisher<String, Never>
        /// Chạm 1 hàng trong "Thời khóa gợi ý" — mang theo `id` mục.
        let suggestedSessionTapped: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILHomeStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILHomeNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILHomeNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILHomeStateModel>, Never>
    private var currentEntity: ILHomeEntity
    private var currentState: ILHomeStateModel
    private let useCase: ILHomeUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILHomeUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = ILHomeViewModel.makeStateModel(from: initialEntity)
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.beadTapped
            .sink { [weak self] _ in self?.handleBeadTapped() }
            .store(in: &cancellables)

        input.resetBeadsTapped
            .sink { [weak self] _ in self?.handleResetBeadsTapped() }
            .store(in: &cancellables)

        input.malaFullscreenTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openMala) }
            .store(in: &cancellables)

        input.lunarCalendarTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openLunarCalendar) }
            .store(in: &cancellables)

        input.lunarHeroTapped
            .sink { [weak self] _ in self?.handleLunarHeroTapped() }
            .store(in: &cancellables)

        input.dayTapped
            .sink { [weak self] id in self?.handleDayTapped(id) }
            .store(in: &cancellables)

        input.photosTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openPhotos) }
            .store(in: &cancellables)

        input.bellTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openBell) }
            .store(in: &cancellables)

        input.eventsTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openFestivals) }
            .store(in: &cancellables)

        input.articleTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openArticle(id: id)) }
            .store(in: &cancellables)

        input.articlesViewAllTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openArticles) }
            .store(in: &cancellables)

        input.templeTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTemple(id: id)) }
            .store(in: &cancellables)

        input.deityTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openDeity(id: id)) }
            .store(in: &cancellables)

        input.suggestedSessionTapped
            .sink { [weak self] id in self?.handleSuggestedSessionTapped(id) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
        loadBuddhistEvents()
        loadRandomVerse()
    }

    /// Nạp 1 câu kinh ngẫu nhiên (từ Core Data) cho thẻ âm lịch lớn. Mỗi lần vào Trang chủ
    /// (`viewDidLoad`) lấy 1 câu mới; đổi ngày trong dải lịch tuần giữ nguyên câu này.
    private func loadRandomVerse() {
        Task { [weak self] in
            guard let self else { return }
            let verse = await self.useCase.loadRandomVerse()
            self.currentEntity.lunarDate.verse = verse
            self.currentState = ILHomeViewModel.makeStateModel(from: self.currentEntity)
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Nạp bất đồng bộ các sự kiện Phật giáo định kỳ (từ Core Data) rồi ghép vào state. Lỗi chỉ bỏ
    /// qua — carousel để trống thay vì làm Trang chủ thất bại vì thiếu sự kiện.
    private func loadBuddhistEvents() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let months = try await self.useCase.loadBuddhistEventMonths(around: Date())
                self.currentEntity.eventMonths = months
                self.currentState = ILHomeViewModel.makeStateModel(from: self.currentEntity)
                self.stateSubject.send(.success(self.currentState))
            } catch {
                // Non-fatal: the carousel simply shows nothing. A future metrics/log path can
                // record the failure here.
            }
        }
    }

    /// Chạm vòng tràng hạt — tăng số đếm ngay, không gọi API/persist (xem TODO trong
    /// `ILHomeUseCaseImpl`).
    private func handleBeadTapped() {
        applyEntity(useCase.incrementBead(currentEntity))
    }

    private func handleResetBeadsTapped() {
        applyEntity(useCase.resetBeads(currentEntity))
    }

    /// Chạm 1 ngày trong dải lịch tuần — chọn ngày (nếu khác ngày đang chọn) và cập nhật thẻ âm
    /// lịch lớn theo ngày mới.
    private func handleDayTapped(_ id: String) {
        guard id != currentEntity.selectedDayID else { return }
        applyEntity(useCase.selectDay(id: id, in: currentEntity))
    }

    /// Chạm thẻ âm lịch lớn — mở màn Chi tiết ngày âm với ngày dương đang chọn.
    private func handleLunarHeroTapped() {
        guard let day = currentEntity.weekPages.flatMap(\.days).first(where: { $0.id == currentEntity.selectedDayID }) else {
            return
        }
        let verse = currentEntity.lunarDate.verse
        navigationEventSubject.send(.openLunarDayDetail(date: day.date, verse: verse.lines.isEmpty ? nil : verse))
    }

    /// Điều hướng theo `kind` của mục (không theo chuỗi `id`). Chỉ thiền có màn đích; Đọc kinh /
    /// Cúng dường chưa build nên chưa phát event.
    private func handleSuggestedSessionTapped(_ id: String) {
        guard let session = currentEntity.suggestedSessions.first(where: { $0.id == id }) else { return }
        switch session.kind {
        case .meditation:
            navigationEventSubject.send(.openMeditationSetup)
        case .sutra, .offering:
            // TODO: điều hướng sang màn Đọc kinh / Cúng dường khi có coordinator tương ứng.
            break
        }
    }

    // MARK: - Entity <-> StateModel mapping
    /// `Entity -> StateModel` là việc riêng của presentation (fallback tên "khách", format câu
    /// chào, nhãn UI tĩnh...) nên nằm ở đây, không phải trong một Mapper dùng chung
    /// (xem `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILHomeEntity) {
        currentEntity = entity
        currentState = ILHomeViewModel.makeStateModel(from: entity)
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(from entity: ILHomeEntity) -> ILHomeStateModel {
        let name = entity.displayName.isEmpty
            ? "home.greeting.name.guest".localized
            : entity.displayName

        var state = ILHomeStateModel()
        state.greetingText = String(format: "home.greeting.format".localized, name)
        state.avatarInitial = String(name.prefix(1)).uppercased()
        state.dateText = entity.lunarDate.solarLabel

        state.weekdayLabels = Self.weekdayHeaderLabelKeys.map { $0.localized }
        state.weekPages = entity.weekPages.map { page in
            ILHomeWeekPageModel(
                id: page.id,
                label: page.label,
                days: page.days.map { day in
                    ILHomeWeekDayModel(
                        id: day.id,
                        solarDay: day.solarDay,
                        lunarText: day.lunarDay == 1 ? "1/\(day.lunarMonth)" : "\(day.lunarDay)",
                        dotKind: Self.dotKind(lunarDay: day.lunarDay, isHoangDao: day.isHoangDao),
                        isToday: day.isToday,
                        isSelected: day.id == entity.selectedDayID
                    )
                }
            )
        }
        state.weekLegend = [
            ILHomeWeekLegendModel(text: "home.week.legend.hoangDao".localized, dotKind: .hoangDao),
            ILHomeWeekLegendModel(text: "home.week.legend.hacDao".localized, dotKind: .hacDao),
            ILHomeWeekLegendModel(text: "home.week.legend.fullMoon".localized, dotKind: .newMoonFullMoon)
        ]
        state.weekCalendarLinkText = "home.week.calendarLink".localized

        state.lunarHero = ILHomeLunarHeroModel(
            eyebrowText: "home.lunar.eyebrow".localized,
            solarLabel: entity.lunarDate.solarLabel,
            lunarDay: entity.lunarDate.lunarDay,
            lunarMonthLabel: entity.lunarDate.lunarMonthLabel,
            lunarYearLabel: entity.lunarDate.lunarYearLabel,
            verseLines: entity.lunarDate.verse.lines,
            verseSource: entity.lunarDate.verse.source
        )

        state.eventsTitle = "home.events.title".localized
        state.eventsViewAllText = "home.events.viewAll".localized
        let currentMonthKey = Self.monthKey(for: Date(), calendar: .current)
        state.eventMonths = entity.eventMonths.map { month in
            ILHomeEventMonthModel(
                id: month.id,
                monthLabel: month.monthLabel,
                // Mỗi thẻ tháng chỉ hiển thị tối đa 3 sự kiện — danh sách đầy đủ dành cho màn "Xem
                // tất cả" (`eventsViewAllText`), chưa build.
                events: month.events.prefix(Self.maxEventsPerMonthCard).map { event in
                    let day = Calendar.current.component(.day, from: event.date)
                    return ILHomeEventItemModel(
                        id: event.id,
                        dayNumber: String(format: "%02d", day),
                        weekdayLabel: weekdayShortLabel(for: event.date),
                        title: event.title,
                        lunarLabel: event.lunarLabel,
                        tone: event.tone
                    )
                },
                totalEventsCount: month.events.count,
                isCurrentMonth: month.id == currentMonthKey
            )
        }

        state.sessionMinutesDone = entity.sessionMinutesDone
        state.sessionMinutesGoal = entity.sessionMinutesGoal

        state.streakDays = entity.streakDays
        state.streakWeekProgress = entity.streakWeekProgress

        state.malaCount = entity.malaCount
        state.malaGoal = entity.malaGoal
        state.malaMantraText = entity.malaMantraText
        state.malaHelperText = "home.mala.helper".localized

        state.suggestedSessions = entity.suggestedSessions.map {
            ILHomeSuggestedSessionModel(
                id: $0.id,
                title: $0.title,
                subtitle: $0.subtitle,
                trailingText: $0.trailingText,
                tone: $0.tone,
                glyph: $0.glyph
            )
        }

        state.photosTitle = "home.photos.title".localized
        state.photosViewAllText = "home.photos.viewAll".localized
        state.photos = entity.photos.map { ILHomePhotoModel(id: $0.id) }
        state.photosMoreText = String(format: "home.photos.moreFormat".localized, max(0, entity.photos.count - 3))
        state.photosMoreLabel = "home.photos.moreLabel".localized

        state.templesTitle = "home.temple.title".localized
        state.templesFindText = "home.temple.find".localized
        state.temples = entity.temples.map {
            ILHomeTempleModel(id: $0.id, name: $0.name, place: $0.place, region: $0.region, note: $0.note)
        }

        state.deitiesTitle = "home.deity.title".localized
        state.deitiesViewAllText = "home.deity.viewAll".localized
        state.deities = entity.deities.map { deity in
            let memorialText = deity.memorialDay.map {
                String(format: "home.deity.memorialFormat".localized, $0.lunarDay, $0.lunarMonth)
            } ?? ""
            return ILHomeDeityModel(
                id: deity.id,
                kind: deity.kind,
                kindLabel: deity.kind == .buddha ? "deity.kind.buddha".localized : "deity.kind.bodhisattva".localized,
                name: deity.name,
                memorialText: memorialText
            )
        }

        state.bellTitle = "home.bell.title".localized
        state.bellSubtitle = "home.bell.subtitle".localized

        state.articlesTitle = "home.article.title".localized
        state.articlesViewAllText = "home.article.viewAll".localized
        state.articles = entity.articles.map {
            ILHomeArticleModel(
                id: $0.id,
                category: $0.category,
                title: $0.title,
                author: $0.author,
                readText: String(format: "home.article.readFormat".localized, $0.readMinutes)
            )
        }

        return state
    }

    /// Nhãn thứ ngắn ("T2"..."T7", "CN") theo `date.weekday` (1 = Chủ nhật ... 7 = Thứ Bảy) —
    /// vocab tiếng Việt cố định của lịch tuần/carousel sự kiện, không qua `.localized` (giống
    /// cách `ILLunarCalendar` tự chứa tên tháng/Can Chi tiếng Việt).
    private static let weekdayShortLabels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private static func weekdayShortLabel(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekdayShortLabels[(weekday - 1 + 7) % 7]
    }

    /// Nhãn 7 cột của header lịch tuần ("Hai"..."CN") — thứ tự Thứ Hai → Chủ nhật cố định, qua
    /// `.localized` để đổi ngôn ngữ được (khác `weekdayShortLabels` dùng cho carousel sự kiện).
    private static let weekdayHeaderLabelKeys = [
        "home.week.head.mon", "home.week.head.tue", "home.week.head.wed",
        "home.week.head.thu", "home.week.head.fri", "home.week.head.sat", "home.week.head.sun"
    ]

    /// Loại chấm màu của 1 ô ngày — Rằm/Mùng Một (vàng) ưu tiên hơn Hoàng đạo/Hắc đạo (xanh/đỏ).
    private static func dotKind(lunarDay: Int, isHoangDao: Bool) -> ILHomeWeekDotKind {
        if lunarDay == 1 || lunarDay == 15 { return .newMoonFullMoon }
        return isHoangDao ? .hoangDao : .hacDao
    }

    /// Số sự kiện tối đa hiển thị trên 1 thẻ tháng của carousel "Sự kiện Phật giáo".
    private static let maxEventsPerMonthCard = 3

    /// Khóa tháng dương lịch `yyyy-MM` — cùng định dạng với `id` do `ILHomeUseCaseImpl` sinh ra
    /// cho `ILHomeEventMonthEntity`, dùng để nhận diện thẻ tháng hiện tại.
    private static func monthKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
