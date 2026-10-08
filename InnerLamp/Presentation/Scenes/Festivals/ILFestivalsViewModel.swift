//
//  ILFestivalsViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFestivalsNavEvent: Equatable {
    case goBack
}

protocol ILFestivalsViewModelProtocol: ViewModelType {
    /// Độc lập với `transform(input:)` — `ILFestivalsCoordinator` subscribe trực tiếp trong
    /// `start()`, trước khi `ViewController`/`Input` tồn tại.
    var navigationEventPublisher: AnyPublisher<ILFestivalsNavEvent, Never> { get }
}

final class ILFestivalsViewModel: ILFestivalsViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let tabSelected: AnyPublisher<ILFestivalsTab, Never>
        let backTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILFestivalsStateModel>, Never>
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILFestivalsNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILFestivalsNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILFestivalsStateModel>, Never>
    private let useCase: ILFestivalsUseCase
    private var entity: ILFestivalsEntity = .empty
    private var selectedTab: ILFestivalsTab = .all
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILFestivalsUseCase) {
        self.useCase = useCase
        self.stateSubject = CurrentValueSubject(.loading)
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.tabSelected
            .sink { [weak self] tab in self?.handleTabSelected(tab) }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        stateSubject.send(.loading)
        Task { [weak self] in
            guard let self else { return }
            do {
                let months = try await self.useCase.loadMonths(from: Date())
                self.entity = ILFestivalsEntity(months: months)
                self.stateSubject.send(.success(Self.makeStateModel(from: self.entity, tab: self.selectedTab)))
            } catch {
                self.stateSubject.send(.failure(error))
            }
        }
    }

    private func handleTabSelected(_ tab: ILFestivalsTab) {
        selectedTab = tab
        stateSubject.send(.success(Self.makeStateModel(from: entity, tab: tab)))
    }

    // MARK: - Entity -> StateModel mapping
    /// Việc riêng của presentation (format countdown/thứ ngày/phụ đề) nên nằm ở
    /// đây, không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(from entity: ILFestivalsEntity, tab: ILFestivalsTab) -> ILFestivalsStateModel {
        var model = ILFestivalsStateModel()
        model.selectedTab = tab
        model.currentMonthId = currentMonthId()

        model.months = entity.months.compactMap { month in
            let days = month.days.filter { day in
                switch tab {
                case .all: return true
                case .festivals: return day.kind == .festival
                case .observances: return day.kind == .observance
                }
            }
            guard !days.isEmpty else { return nil }
            return ILFestivalMonthModel(id: month.id, label: month.label, days: days.map { Self.makeDayModel($0) })
        }

        let total = model.months.reduce(0) { $0 + $1.days.count }
        model.subtitle = String(format: "festivals.header.subtitleFormat".localized, total)

        return model
    }

    /// `id` ("yyyy-MM") của tháng chứa hôm nay, khớp `ILFestivalMonthEntity.id`.
    private static func currentMonthId() -> String {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month], from: Date())
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    static func makeDayModel(_ day: ILFestivalDayEntity) -> ILFestivalDayModel {
        let calendar = Calendar(identifier: .gregorian)
        let solarDay = calendar.component(.day, from: day.date)
        let solarMonth = calendar.component(.month, from: day.date)
        let weekday = calendar.component(.weekday, from: day.date) // 1 = Chủ nhật ... 7 = Thứ Bảy
        let lunar = ILLunarCalendar.solarToLunar(date: day.date, calendar: calendar)

        return ILFestivalDayModel(
            id: day.id,
            dayNumber: String(format: "%02d", solarDay),
            weekdayLabel: weekdayShortLabel(weekday),
            title: day.title,
            countdownText: countdownText(day.daysUntil),
            isFestival: day.kind == .festival,
            isImminent: (0...1).contains(day.daysUntil),
            isToday: day.daysUntil == 0,
            lunarSubtitle: lunarSubtitle(
                weekday: weekday,
                solarDay: solarDay,
                solarMonth: solarMonth,
                lunar: lunar
            )
        )
    }

    private static func countdownText(_ days: Int) -> String {
        switch days {
        case ..<0: return "festivals.item.countdown.past".localized
        case 0: return "festivals.item.countdown.today".localized
        case 1: return "festivals.item.countdown.tomorrow".localized
        default: return String(format: "festivals.item.countdown.days".localized, days)
        }
    }

    /// "Thứ X, dd-MM · Âm lịch dd-mm (nhuận)".
    private static func lunarSubtitle(
        weekday: Int,
        solarDay: Int,
        solarMonth: Int,
        lunar: ILLunarCalendar.LunarDate
    ) -> String {
        let weekdayText = weekday == 1
            ? "festivals.weekday.sunday".localized
            : String(format: "festivals.weekday.format".localized, weekday)
        let solarText = String(format: "%02d-%02d", solarDay, solarMonth)
        let lunarText = lunar.isLeapMonth
            ? String(format: "festivals.item.lunarDateLeapFormat".localized, lunar.day, lunar.month)
            : String(format: "festivals.item.lunarDateFormat".localized, lunar.day, lunar.month)
        return "\(weekdayText), \(solarText) · \(lunarText)"
    }

    /// Nhãn thứ ngắn ("CN", "T2"…"T7") theo `weekday` (1 = Chủ nhật ... 7 = Thứ Bảy).
    private static let weekdayShortLabels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private static func weekdayShortLabel(_ weekday: Int) -> String {
        weekdayShortLabels[(weekday - 1 + 7) % 7]
    }
}
