//
//  ILFestivalsViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILFestivalsNavEvent: Equatable {
    case goBack
    case openTemple(id: String)
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
        let hostTapped: AnyPublisher<String, Never>
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

        input.hostTapped
            .sink { [weak self] id in self?.navigationEventSubject.send(.openTemple(id: id)) }
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
    /// Việc riêng của presentation (format countdown/thứ ngày/phụ đề, resolve tên chùa) nên nằm ở
    /// đây, không phải trong Mapper dùng chung (xem `references/data_layer_boundaries.md`).
    private static func makeStateModel(from entity: ILFestivalsEntity, tab: ILFestivalsTab) -> ILFestivalsStateModel {
        var model = ILFestivalsStateModel()
        model.selectedTab = tab

        model.months = entity.months.compactMap { month in
            let days = month.days.filter { day in
                switch tab {
                case .all: return true
                case .festivals: return day.kind != .observance
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

    private static func makeDayModel(_ day: ILFestivalDayEntity) -> ILFestivalDayModel {
        let calendar = Calendar(identifier: .gregorian)
        let solarDay = calendar.component(.day, from: day.date)
        let solarMonth = calendar.component(.month, from: day.date)
        let weekday = calendar.component(.weekday, from: day.date) // 1 = Chủ nhật ... 7 = Thứ Bảy
        let lunar = ILLunarCalendar.solarToLunar(date: day.date, calendar: calendar)

        let hosts = day.hostTempleIDs.map { ILFestivalHostModel(id: $0, name: templeName(for: $0)) }
        let moreHostsText = hosts.count > 3
            ? String(format: "festivals.item.moreHostsFormat".localized, hosts.count - 3)
            : nil

        return ILFestivalDayModel(
            id: day.id,
            dayNumber: String(format: "%02d", solarDay),
            weekdayLabel: weekdayShortLabel(weekday),
            title: day.title,
            countdownText: countdownText(day.daysUntil),
            isFestival: day.kind != .observance,
            isImminent: day.daysUntil <= 1,
            isToday: day.daysUntil == 0,
            lunarSubtitle: lunarSubtitle(
                weekday: weekday,
                solarDay: solarDay,
                solarMonth: solarMonth,
                lunar: lunar,
                hostCount: hosts.count
            ),
            hosts: hosts,
            moreHostsText: moreHostsText
        )
    }

    /// Tên chùa tổ chức theo id — tái dùng bộ `home.temple.*` (cùng nguồn dữ liệu với carousel
    /// "Chùa Việt Nam"), thêm `tp-tuquang` (Từ Quang) vốn chưa có trong catalog 8 chùa.
    private static func templeName(for id: String) -> String {
        switch id {
        case "tp-tuquang": return "home.temple.tuquang.name".localized
        case "tp-motcot": return "home.temple.motcot.name".localized
        case "tp-tranquoc": return "home.temple.tranquoc.name".localized
        case "tp-huong": return "home.temple.huong.name".localized
        case "tp-baidinh": return "home.temple.baidinh.name".localized
        case "tp-thienmu": return "home.temple.thienmu.name".localized
        case "tp-linhung": return "home.temple.linhung.name".localized
        case "tp-truclam": return "home.temple.truclam.name".localized
        case "tp-vinhnghiem": return "home.temple.vinhnghiem.name".localized
        default: return id
        }
    }

    private static func countdownText(_ days: Int) -> String {
        switch days {
        case 0: return "festivals.item.countdown.today".localized
        case 1: return "festivals.item.countdown.tomorrow".localized
        default: return String(format: "festivals.item.countdown.days".localized, days)
        }
    }

    /// "Thứ X, dd-MM · Âm lịch dd-mm (nhuận) · N chùa tổ chức".
    private static func lunarSubtitle(
        weekday: Int,
        solarDay: Int,
        solarMonth: Int,
        lunar: ILLunarCalendar.LunarDate,
        hostCount: Int
    ) -> String {
        let weekdayText = weekday == 1
            ? "festivals.weekday.sunday".localized
            : String(format: "festivals.weekday.format".localized, weekday)
        let solarText = String(format: "%02d-%02d", solarDay, solarMonth)
        let lunarText = lunar.isLeapMonth
            ? String(format: "festivals.item.lunarDateLeapFormat".localized, lunar.day, lunar.month)
            : String(format: "festivals.item.lunarDateFormat".localized, lunar.day, lunar.month)
        let hostsText = String(format: "festivals.item.hostsCountFormat".localized, hostCount)
        return "\(weekdayText), \(solarText) · \(lunarText) · \(hostsText)"
    }

    /// Nhãn thứ ngắn ("CN", "T2"…"T7") theo `weekday` (1 = Chủ nhật ... 7 = Thứ Bảy).
    private static let weekdayShortLabels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private static func weekdayShortLabel(_ weekday: Int) -> String {
        weekdayShortLabels[(weekday - 1 + 7) % 7]
    }
}
