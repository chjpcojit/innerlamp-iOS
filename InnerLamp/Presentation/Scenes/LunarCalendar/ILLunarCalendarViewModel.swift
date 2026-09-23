//
//  ILLunarCalendarViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILLunarCalendarNavEvent: Equatable {
    /// Nút ✕ ở header — đóng màn Lịch âm.
    case close
}

protocol ILLunarCalendarViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILLunarCalendarCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILLunarCalendarNavEvent, Never> { get }
}

final class ILLunarCalendarViewModel: ILLunarCalendarViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let previousMonthTapped: AnyPublisher<Void, Never>
        let nextMonthTapped: AnyPublisher<Void, Never>
        /// Trang carousel đang hiển thị (người dùng vuốt ngang) — ViewModel kẹp vào khoảng hợp lệ.
        let pageChanged: AnyPublisher<Int, Never>
        /// `ILLunarCalendarDayModel.id` của ô được chạm.
        let dayTapped: AnyPublisher<String, Never>
        let closeTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILLunarCalendarStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILLunarCalendarNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    /// Số hàng "sắp tới" hiển thị dưới thẻ ngày — khớp design handoff (2 hàng).
    private static let upcomingLimit = 2

    private let navigationEventSubject = PassthroughSubject<ILLunarCalendarNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILLunarCalendarStateModel>, Never>
    private var currentEntity: ILLunarCalendarEntity
    private var currentPage: Int = 0
    private var currentState: ILLunarCalendarStateModel
    private let useCase: ILLunarCalendarUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILLunarCalendarUseCase) {
        self.useCase = useCase
        let initialEntity = useCase.getInitialState()
        self.currentEntity = initialEntity
        let initialState = Self.makeStateModel(
            from: initialEntity,
            page: 0,
            upcoming: useCase.upcomingSpecialDays(in: initialEntity, limit: Self.upcomingLimit)
        )
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.previousMonthTapped
            .sink { [weak self] _ in self?.showPage(offsetBy: -1) }
            .store(in: &cancellables)

        input.nextMonthTapped
            .sink { [weak self] _ in self?.showPage(offsetBy: 1) }
            .store(in: &cancellables)

        input.pageChanged
            .sink { [weak self] page in self?.setPage(page) }
            .store(in: &cancellables)

        input.dayTapped
            .sink { [weak self] id in self?.handleDayTapped(id: id) }
            .store(in: &cancellables)

        input.closeTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.close) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentPage = 0
        applyEntity(useCase.getInitialState())
    }

    private func showPage(offsetBy delta: Int) {
        setPage(currentPage + delta)
    }

    private func setPage(_ page: Int) {
        let lastPage = max(0, currentEntity.months.count - 1)
        let clamped = min(max(page, 0), lastPage)
        guard clamped != currentPage else { return }
        currentPage = clamped
        publishState()
    }

    private func handleDayTapped(id: String) {
        guard id != currentEntity.selectedDayID else { return }
        applyEntity(useCase.selectDay(id: id, in: currentEntity))
    }

    // MARK: - Entity -> StateModel
    /// `Entity -> StateModel` là việc riêng của presentation (copy, format ngày, trang carousel)
    /// nên nằm ở đây, không phải trong Mapper dùng chung (xem
    /// `references/data_layer_boundaries.md`).
    private func applyEntity(_ entity: ILLunarCalendarEntity) {
        currentEntity = entity
        publishState()
    }

    private func publishState() {
        currentState = Self.makeStateModel(
            from: currentEntity,
            page: currentPage,
            upcoming: useCase.upcomingSpecialDays(in: currentEntity, limit: Self.upcomingLimit)
        )
        stateSubject.send(.success(currentState))
    }

    private static func makeStateModel(
        from entity: ILLunarCalendarEntity,
        page: Int,
        upcoming: [ILLunarCalendarDayEntity]
    ) -> ILLunarCalendarStateModel {
        var state = ILLunarCalendarStateModel()

        state.pagerHintText = "lunarCalendar.pager.hint".localized
        state.weekdayLabels = weekdayLabelKeys.map { $0.localized }
        state.currentPage = page

        state.months = entity.months.map { month in
            ILLunarCalendarMonthModel(
                id: month.id,
                leadingBlankDays: month.leadingBlankDays,
                days: month.days.map { day in
                    ILLunarCalendarDayModel(
                        id: day.id,
                        solarText: "\(day.solarDay)",
                        lunarText: lunarText(for: day),
                        isToday: day.id == entity.todayID,
                        isSelected: day.id == entity.selectedDayID,
                        isFastDay: day.isFastDay
                    )
                }
            )
        }

        if entity.months.indices.contains(page) {
            let month = entity.months[page]
            state.headerTitle = String(format: "lunarCalendar.header.titleFormat".localized, month.solarMonth, month.solarYear)
            state.headerSubtitle = String(
                format: "lunarCalendar.header.subtitleFormat".localized,
                ILLunarCalendar.canChiYear(month.midLunarYear),
                ILLunarCalendar.lunarMonthLabel(month.midLunarMonth, isLeap: month.isMidLunarLeapMonth)
            )
        }

        if let selected = entity.selectedDay {
            let isToday = selected.id == entity.todayID
            let prefix = isToday ? "lunarCalendar.hero.today".localized : weekdayName(for: selected.date)
            state.heroEyebrowText = String(
                format: "lunarCalendar.hero.eyebrowFormat".localized,
                prefix,
                selected.lunarDay,
                ILLunarCalendar.lunarMonthLabel(selected.lunarMonth, isLeap: selected.isLunarLeapMonth)
            )
            state.heroTitle = heroTitleKey(for: selected.category).localized
            state.heroBody = heroBodyKey(for: selected.category).localized
            state.heroCategory = selected.category
        }

        state.upcoming = upcoming.map { day in
            ILLunarCalendarUpcomingModel(
                id: day.id,
                title: upcomingTitleKey(for: day.category).localized,
                subtitle: String(
                    format: "lunarCalendar.upcoming.subtitleFormat".localized,
                    day.lunarDay,
                    solarLabel(for: day.date)
                ),
                category: day.category
            )
        }

        return state
    }

    // MARK: - Copy helpers
    /// Thứ tự khớp `Calendar.weekday` (Chủ nhật đứng đầu) — cùng thứ tự cột của lưới tháng.
    private static let weekdayLabelKeys = [
        "lunarCalendar.weekday.sun", "lunarCalendar.weekday.mon", "lunarCalendar.weekday.tue",
        "lunarCalendar.weekday.wed", "lunarCalendar.weekday.thu", "lunarCalendar.weekday.fri",
        "lunarCalendar.weekday.sat"
    ]

    private static func lunarText(for day: ILLunarCalendarDayEntity) -> String {
        switch day.category {
        case .newMoon: return "lunarCalendar.day.newMoon".localized
        case .fullMoon: return "lunarCalendar.day.fullMoon".localized
        case .fastDay, .ordinary: return "\(day.lunarDay)"
        }
    }

    private static func heroTitleKey(for category: ILLunarCalendarDayCategory) -> String {
        switch category {
        case .newMoon: return "lunarCalendar.hero.newMoon.title"
        case .fullMoon: return "lunarCalendar.hero.fullMoon.title"
        case .fastDay: return "lunarCalendar.hero.fastDay.title"
        case .ordinary: return "lunarCalendar.hero.ordinary.title"
        }
    }

    private static func heroBodyKey(for category: ILLunarCalendarDayCategory) -> String {
        switch category {
        case .newMoon: return "lunarCalendar.hero.newMoon.body"
        case .fullMoon: return "lunarCalendar.hero.fullMoon.body"
        case .fastDay: return "lunarCalendar.hero.fastDay.body"
        case .ordinary: return "lunarCalendar.hero.ordinary.body"
        }
    }

    private static func upcomingTitleKey(for category: ILLunarCalendarDayCategory) -> String {
        switch category {
        case .newMoon: return "lunarCalendar.upcoming.newMoon.title"
        case .fullMoon: return "lunarCalendar.upcoming.fullMoon.title"
        case .fastDay, .ordinary: return "lunarCalendar.upcoming.fastDay.title"
        }
    }

    // MARK: - Date formatting
    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = format
        return formatter
    }

    private static let weekdayFormatter = makeFormatter("EEEE")
    private static let solarLabelFormatter = makeFormatter("EEEE, d/M")

    /// "Thứ Ba"
    private static func weekdayName(for date: Date) -> String {
        weekdayFormatter.string(from: date).capitalizingFirstLetter()
    }

    /// "Thứ Ba, 16/9"
    private static func solarLabel(for date: Date) -> String {
        solarLabelFormatter.string(from: date).capitalizingFirstLetter()
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
