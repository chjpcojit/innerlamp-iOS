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
    /// Link "Toàn màn hình" hoặc cả thẻ tràng hạt — mở màn Niệm Phật toàn màn hình.
    case openMala
    /// Link "Sổ giỗ" ở dải lịch tuần — mở màn Sổ giỗ.
    case openMemorial
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
    /// Link "Xem tất cả" ở khối "Thư viện Phật & Bồ Tát" — mở màn danh sách "Chư Phật & Bồ Tát".
    case openDeities
    /// Chạm 1 hàng thiền trong "Thời khóa gợi ý" — mở màn Chuẩn bị thiền (`setup`).
    case openMeditationSetup
    /// Chạm chuông thông báo ở header — mở màn Thông báo.
    case openNotifications
    /// Chạm avatar ở header — chuyển sang tab Tôi (màn Hồ sơ).
    case openProfile
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
        let malaFullscreenTapped: AnyPublisher<Void, Never>
        let lunarCalendarTapped: AnyPublisher<Void, Never>
        /// Link "Sổ giỗ" ở dải lịch tuần.
        let memorialTapped: AnyPublisher<Void, Never>
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
        /// Link "Xem tất cả" ở khối "Thư viện Phật & Bồ Tát".
        let deitiesViewAllTapped: AnyPublisher<Void, Never>
        /// Chạm 1 hàng trong "Thời khóa gợi ý" — mang theo `id` mục.
        let suggestedSessionTapped: AnyPublisher<String, Never>
        /// Chuông thông báo ở header.
        let notificationTapped: AnyPublisher<Void, Never>
        /// Avatar ở header.
        let avatarTapped: AnyPublisher<Void, Never>
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
    private let calendarImageUseCase: ILCalendarImageUseCase
    /// Pictures already fetched, keyed by week-day id; the hero shows the one of the selected day.
    private var heroImages: [String: ILCalendarImageEntity] = [:]
    /// Day ids whose picture was requested (success or failure) — one request per day per screen.
    private var requestedHeroImageDayIDs: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    /// Sections whose server call has answered (or failed) — an empty section before that is
    /// "still loading", after it is "no data" and shows the "updating" placeholder.
    private var loadedSections: LoadedSections = []

    private struct LoadedSections: OptionSet {
        let rawValue: Int
        static let temples = LoadedSections(rawValue: 1 << 0)
        static let deities = LoadedSections(rawValue: 1 << 1)
        static let articles = LoadedSections(rawValue: 1 << 2)
    }

    // MARK: - Initializer
    init(useCase: ILHomeUseCase, calendarImageUseCase: ILCalendarImageUseCase) {
        self.useCase = useCase
        self.calendarImageUseCase = calendarImageUseCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = ILHomeViewModel.makeStateModel(from: initialEntity, loaded: [])
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.malaFullscreenTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openMala) }
            .store(in: &cancellables)

        input.memorialTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openMemorial) }
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

        input.deitiesViewAllTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openDeities) }
            .store(in: &cancellables)

        input.suggestedSessionTapped
            .sink { [weak self] id in self?.handleSuggestedSessionTapped(id) }
            .store(in: &cancellables)

        input.notificationTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openNotifications) }
            .store(in: &cancellables)

        input.avatarTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openProfile) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
        loadBuddhistEvents()
        loadRandomVerse()
        loadHeroImage()
        loadTopTemples()
        loadTopDeities()
        loadTopArticles()
        loadTopPhotos()
    }

    /// Fills the "Ảnh chùa đẹp" block from the server (`/v1/gallery/top`). Server data only: a
    /// failure leaves the tiles as placeholders instead of failing the whole Home screen.
    private func loadTopPhotos() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.currentEntity.photos = try await self.useCase.loadTopPhotos()
            } catch {
                #if DEBUG
                print("[Home] loadTopPhotos failed: \(error)")
                #endif
                self.currentEntity.photos = []
            }
            self.currentState = self.makeState(from: self.currentEntity)
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Fills the "Bài viết Phật pháp hay" section from the server (`/v1/articles/top`). Server data
    /// only: a failure or an empty list shows the "updating" placeholder instead of failing the
    /// whole Home screen.
    private func loadTopArticles() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.currentEntity.articles = try await self.useCase.loadTopArticles()
            } catch {
                #if DEBUG
                print("[Home] loadTopArticles failed: \(error)")
                #endif
                self.currentEntity.articles = []
            }
            self.loadedSections.insert(.articles)
            self.currentState = self.makeState(from: self.currentEntity)
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Nạp carousel "Chùa Việt Nam" từ server (`/v1/temples/top`, có cache offline). Chỉ dữ liệu
    /// server: lỗi hoặc danh sách rỗng → carousel hiện "Đang cập nhật" thay vì làm Trang chủ thất bại.
    private func loadTopTemples() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.currentEntity.temples = try await self.useCase.loadTopTemples()
            } catch {
                // Non-fatal: server unreachable and nothing cached — the carousel shows "updating".
                #if DEBUG
                print("[Home] loadTopTemples failed: \(error)")
                #endif
                self.currentEntity.temples = []
            }
            self.loadedSections.insert(.temples)
            self.currentState = self.makeState(from: self.currentEntity)
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Nạp carousel "Thư viện Phật & Bồ Tát" từ server (`/v1/deities/top`, có cache offline). Chỉ
    /// dữ liệu server: lỗi hoặc danh sách rỗng → carousel hiện "Đang cập nhật" thay vì dữ liệu giả.
    private func loadTopDeities() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.currentEntity.deities = try await self.useCase.loadTopDeities()
            } catch {
                // Non-fatal: server unreachable and nothing cached — the carousel shows "updating".
                #if DEBUG
                print("[Home] loadTopDeities failed: \(error)")
                #endif
                self.currentEntity.deities = []
            }
            self.loadedSections.insert(.deities)
            self.currentState = self.makeState(from: self.currentEntity)
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Nạp 1 câu kinh ngẫu nhiên (từ Core Data) cho thẻ âm lịch lớn. Mỗi lần vào Trang chủ
    /// (`viewDidLoad`) lấy 1 câu mới; đổi ngày trong dải lịch tuần giữ nguyên câu này.
    private func loadRandomVerse() {
        Task { [weak self] in
            guard let self else { return }
            let verse = await self.useCase.loadRandomVerse()
            self.currentEntity.lunarDate.verse = verse
            self.currentState = self.makeState(from: self.currentEntity)
            self.stateSubject.send(.success(self.currentState))
        }
    }

    /// Fetches the picture of the selected day for the hero card. Failure (offline, server error) or
    /// an unsupported year is non-fatal: the gradient card stays and no error is shown.
    private func loadHeroImage() {
        let dayID = currentEntity.selectedDayID
        guard let day = currentEntity.weekPages.flatMap(\.days).first(where: { $0.id == dayID }),
              requestedHeroImageDayIDs.insert(dayID).inserted else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let image = try await self.calendarImageUseCase.loadImage(for: day.date) else { return }
                self.heroImages[dayID] = image
                self.currentState = self.makeState(from: self.currentEntity)
                self.stateSubject.send(.success(self.currentState))
            } catch {
                #if DEBUG
                print("[Home] hero image load failed: \(error)")
                #endif
            }
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
                self.currentState = self.makeState(from: self.currentEntity)
                self.stateSubject.send(.success(self.currentState))
            } catch {
                // Non-fatal: the carousel simply shows nothing. A future metrics/log path can
                // record the failure here.
            }
        }
    }

    /// Chạm 1 ngày trong dải lịch tuần — chọn ngày (nếu khác ngày đang chọn) và cập nhật thẻ âm
    /// lịch lớn theo ngày mới.
    private func handleDayTapped(_ id: String) {
        guard id != currentEntity.selectedDayID else { return }
        applyEntity(useCase.selectDay(id: id, in: currentEntity))
        loadHeroImage()
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
        currentState = makeState(from: entity)
        stateSubject.send(.success(currentState))
    }

    /// `makeStateModel` plus the per-session data that is not part of the entity (loaded flags, the
    /// selected day's picture), so every rebuild keeps them.
    private func makeState(from entity: ILHomeEntity) -> ILHomeStateModel {
        ILHomeViewModel.makeStateModel(from: entity, loaded: loadedSections, heroImage: heroImages[entity.selectedDayID])
    }

    private static func makeStateModel(
        from entity: ILHomeEntity,
        loaded: LoadedSections,
        heroImage: ILCalendarImageEntity? = nil
    ) -> ILHomeStateModel {
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
        state.weekMemorialLinkText = "home.week.memorialLink".localized
        state.weekCalendarLinkText = "home.week.calendarLink".localized

        state.lunarHero = ILHomeLunarHeroModel(
            eyebrowText: "home.lunar.eyebrow".localized,
            solarLabel: entity.lunarDate.solarLabel,
            lunarDay: entity.lunarDate.lunarDay,
            lunarMonthLabel: entity.lunarDate.lunarMonthLabel,
            lunarYearLabel: entity.lunarDate.lunarYearLabel,
            verseLines: entity.lunarDate.verse.lines,
            verseSource: entity.lunarDate.verse.source,
            imageURL: heroImage?.imageURL,
            imageCreditText: heroImage?.creditText ?? ""
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
        state.photos = entity.photos.map { ILHomePhotoModel(id: $0.id, thumbnailURL: $0.thumbnailURL) }
        // The "+N ảnh" overlay only makes sense when there are photos beyond the 3 tiles.
        let hiddenPhotoCount = entity.photos.count - 3
        state.photosMoreText = hiddenPhotoCount > 0 ? String(format: "home.photos.moreFormat".localized, hiddenPhotoCount) : ""
        state.photosMoreLabel = "home.photos.moreLabel".localized

        state.templesTitle = "home.temple.title".localized
        state.templesFindText = "home.temple.find".localized
        state.templesLoading = !loaded.contains(.temples) && entity.temples.isEmpty
        state.templesEmptyText = loaded.contains(.temples) && entity.temples.isEmpty
            ? "home.temple.updating".localized
            : ""
        state.temples = entity.temples.map {
            ILHomeTempleModel(
                id: $0.id,
                name: $0.name,
                place: Self.shortPlace(from: $0.address),
                region: Self.regionLabel($0.region),
                note: Self.templeNote(rank: $0.heritageRank, establishedYear: $0.establishedYear),
                thumbnailURL: $0.thumbnailURL
            )
        }

        state.deitiesTitle = "home.deity.title".localized
        state.deitiesViewAllText = "home.deity.viewAll".localized
        state.deitiesLoading = !loaded.contains(.deities) && entity.deities.isEmpty
        state.deitiesEmptyText = loaded.contains(.deities) && entity.deities.isEmpty
            ? "home.deity.updating".localized
            : ""
        state.deities = entity.deities.map { deity in
            // The server summary has no memorial days yet — show the "updating" line, not a blank.
            let memorialText = deity.memorialDay.map {
                String(format: "home.deity.memorialFormat".localized, $0.lunarDay, $0.lunarMonth)
            } ?? "home.deity.memorialUpdating".localized
            return ILHomeDeityModel(
                id: deity.id,
                kind: deity.kind,
                kindLabel: ILDeitiesViewModel.kindLabel(for: deity.kind),
                name: deity.name,
                memorialText: memorialText,
                thumbnailURL: deity.thumbnailURL
            )
        }

        state.bellTitle = "home.bell.title".localized
        state.bellSubtitle = "home.bell.subtitle".localized

        state.articlesTitle = "home.article.title".localized
        state.articlesViewAllText = "home.article.viewAll".localized
        state.articlesLoading = !loaded.contains(.articles) && entity.articles.isEmpty
        state.articlesEmptyText = loaded.contains(.articles) && entity.articles.isEmpty
            ? "home.article.updating".localized
            : ""
        state.articles = entity.articles.map {
            ILHomeArticleModel(
                id: $0.id,
                category: $0.category,
                title: $0.title,
                author: $0.author,
                readText: String(format: "home.article.readFormat".localized, $0.readMinutes),
                thumbnailURL: $0.thumbnailURL
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

    // MARK: - Temple card formatting

    /// See `ILTempleCatalogLabels.shortPlace(from:)`.
    static func shortPlace(from address: String) -> String {
        ILTempleCatalogLabels.shortPlace(from: address)
    }

    /// See `ILTempleCatalogLabels.regionLabel(_:)`.
    static func regionLabel(_ region: ILTempleRegion) -> String {
        ILTempleCatalogLabels.regionLabel(region)
    }

    /// See `ILTempleCatalogLabels.heritageRankLabel(_:)`.
    static func heritageRankLabel(_ rank: ILTempleHeritageRank) -> String? {
        ILTempleCatalogLabels.heritageRankLabel(rank)
    }

    /// Note line on a temple card — "Di sản Thế giới · Dựng năm 1428"; either part is dropped when
    /// missing (unranked temple / unknown founding year).
    static func templeNote(rank: ILTempleHeritageRank, establishedYear: Int) -> String {
        let founded = establishedYear > 0
            ? String(format: "home.temple.foundedFormat".localized, establishedYear)
            : nil
        return [heritageRankLabel(rank), founded].compactMap { $0 }.joined(separator: " · ")
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
