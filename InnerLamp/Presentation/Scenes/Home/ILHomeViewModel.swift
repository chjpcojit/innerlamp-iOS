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
    /// Link "Lịch âm" ở dải lịch tuần hoặc chạm thẻ âm lịch lớn — mở màn Lịch âm.
    case openLunarCalendar
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

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        applyEntity(useCase.getInitialState())
    }

    /// Chạm vòng tràng hạt — tăng số đếm ngay, không gọi API/persist (xem TODO trong
    /// `ILHomeUseCaseImpl`).
    private func handleBeadTapped() {
        applyEntity(useCase.incrementBead(currentEntity))
    }

    private func handleResetBeadsTapped() {
        applyEntity(useCase.resetBeads(currentEntity))
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

        state.weekLabelText = "home.week.thisWeek".localized
        state.weekDays = entity.weekDays.map {
            ILHomeWeekDayModel(
                id: $0.id,
                weekdayShort: weekdayShortLabel(for: $0.date),
                solarDay: $0.solarDay,
                lunarDay: $0.lunarDay,
                isToday: $0.isToday
            )
        }
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
        state.eventMonths = entity.eventMonths.map { month in
            ILHomeEventMonthModel(
                id: month.id,
                monthLabel: month.monthLabel,
                events: month.events.map { event in
                    let day = Calendar.current.component(.day, from: event.date)
                    return ILHomeEventItemModel(
                        id: event.id,
                        dayNumber: String(format: "%02d", day),
                        weekdayLabel: weekdayShortLabel(for: event.date),
                        title: event.title,
                        lunarLabel: event.lunarLabel,
                        tone: event.tone
                    )
                }
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
}
