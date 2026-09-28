//
//  ILStatsViewModel.swift
//  InnerLamp
//

import Foundation
import Combine

enum ILStatsNavEvent: Equatable {
    /// Back chip — return to the previous screen (pop).
    case goBack
    /// "Giữ chuỗi ngày bằng chuông nhắc" card — open the mindfulness bell reminder (`remind`, not built yet).
    case openReminder
}

protocol ILStatsViewModelProtocol: ViewModelType {
    /// Independent of `transform(input:)` — `ILStatsCoordinator` subscribes directly in `start()`,
    /// before the `ViewController`/`Input` exist.
    var navigationEventPublisher: AnyPublisher<ILStatsNavEvent, Never> { get }
}

final class ILStatsViewModel: ILStatsViewModelProtocol {

    // MARK: - Input / Output
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let backTapped: AnyPublisher<Void, Never>
        let reminderTapped: AnyPublisher<Void, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState<ILStatsStateModel>, Never>
    }

    // MARK: - Constants
    /// Bar opacity: the quietest possible week still reads at `minOpacity`, the busiest is opaque
    /// (prototype: `0.35 + v * 0.65`).
    private enum Chart {
        static let minOpacity = 0.35
        static let opacitySpan = 0.65
    }

    // MARK: - Properties
    var navigationEventPublisher: AnyPublisher<ILStatsNavEvent, Never> {
        navigationEventSubject.eraseToAnyPublisher()
    }

    private let navigationEventSubject = PassthroughSubject<ILStatsNavEvent, Never>()
    private let stateSubject: CurrentValueSubject<ViewState<ILStatsStateModel>, Never>
    private var currentState: ILStatsStateModel
    private let useCase: ILStatsUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(useCase: ILStatsUseCase) {
        self.useCase = useCase
        let initialState = ILStatsViewModel.makeStateModel(stats: useCase.getStats())
        self.currentState = initialState
        self.stateSubject = CurrentValueSubject(.success(initialState))
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] _ in self?.handleViewDidLoad() }
            .store(in: &cancellables)

        input.backTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.goBack) }
            .store(in: &cancellables)

        input.reminderTapped
            .sink { [weak self] _ in self?.navigationEventSubject.send(.openReminder) }
            .store(in: &cancellables)

        return Output(state: stateSubject.eraseToAnyPublisher())
    }

    // MARK: - Actions
    private func handleViewDidLoad() {
        currentState = ILStatsViewModel.makeStateModel(stats: useCase.getStats())
        stateSubject.send(.success(currentState))
    }

    // MARK: - Entity -> StateModel mapping
    private static func makeStateModel(stats: ILStatsEntity) -> ILStatsStateModel {
        var model = ILStatsStateModel()
        model.streak = makeStreak(stats: stats)
        model.tiles = [
            ILStatsTileModel(
                title: "stats.tile.total.title".localized,
                valueText: String(stats.totalHours),
                unitText: "stats.tile.total.unit".localized,
                footnote: formatHoursDelta(stats.hoursDeltaVsLastMonth),
                footnoteTone: stats.hoursDeltaVsLastMonth > 0 ? .positive : .neutral
            ),
            ILStatsTileModel(
                title: "stats.tile.usualTime.title".localized,
                valueText: formatTime(hour: stats.usualStartHour, minute: stats.usualStartMinute),
                unitText: "",
                footnote: String(format: "stats.tile.usualTime.footnote".localized, stats.morningSharePercent),
                footnoteTone: .neutral
            )
        ]

        if let first = stats.weeklyMinutes.first, let last = stats.weeklyMinutes.last {
            model.weeklyChart = ILStatsWeeklyChartModel(
                title: String(format: "stats.chart.title".localized, stats.weeklyMinutes.count),
                averageText: String(format: "stats.chart.average".localized, stats.averageMinutesPerDay),
                bars: makeBars(from: stats.weeklyMinutes.map(\.minutes)),
                startLabel: String(format: "stats.chart.weekLabel".localized, first.weekOfYear),
                endLabel: String(format: "stats.chart.weekLabel".localized, last.weekOfYear)
            )
        }

        model.mix = stats.practiceMix.map {
            ILStatsMixItemModel(
                kind: $0.kind,
                name: practiceName($0.kind),
                fraction: Double(min(max($0.percent, 0), 100)) / 100,
                percentText: String(format: "stats.mix.percent".localized, $0.percent)
            )
        }

        model.reminderSubtitle = formatReminder(stats.reminder)
        return model
    }

    private static func makeStreak(stats: ILStatsEntity) -> ILStatsStreakModel {
        guard let milestone = stats.nextMilestone, milestone.targetDays > stats.streakDays else {
            return ILStatsStreakModel(
                valueText: String(stats.streakDays),
                unitText: "stats.streak.unit".localized,
                milestoneText: nil,
                milestoneProgress: 0
            )
        }
        let remaining = milestone.targetDays - stats.streakDays
        return ILStatsStreakModel(
            valueText: String(stats.streakDays),
            unitText: "stats.streak.unit".localized,
            milestoneText: String(format: "stats.streak.milestone".localized, remaining, milestone.title),
            milestoneProgress: Double(max(stats.streakDays, 0)) / Double(milestone.targetDays)
        )
    }

    /// Normalizes weekly minutes against the busiest week: height = ratio, opacity grows with it.
    static func makeBars(from minutes: [Int]) -> [ILStatsBarModel] {
        let peak = Double(max(minutes.max() ?? 0, 1))
        return minutes.map {
            let ratio = Double(max($0, 0)) / peak
            return ILStatsBarModel(heightRatio: ratio, opacity: Chart.minOpacity + Chart.opacitySpan * ratio)
        }
    }

    /// "+8 giờ so với tháng trước" / "−3 giờ so với tháng trước" / "Bằng tháng trước".
    static func formatHoursDelta(_ delta: Int) -> String {
        if delta == 0 { return "stats.tile.total.deltaSame".localized }
        let key = delta > 0 ? "stats.tile.total.deltaUp" : "stats.tile.total.deltaDown"
        return String(format: key.localized, abs(delta))
    }

    /// "05:40"
    static func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// "05:30 · 6 ngày mỗi tuần" / "05:30 · mỗi ngày"; no reminder → "Chưa đặt chuông nhắc".
    static func formatReminder(_ reminder: ILStatsReminderEntity?) -> String {
        guard let reminder else { return "stats.reminder.none".localized }
        let days = reminder.activeDayCount >= 7
            ? "stats.reminder.everyDay".localized
            : String(format: "stats.reminder.daysPerWeek".localized, reminder.activeDayCount)
        return String(
            format: "stats.reminder.summary".localized,
            formatTime(hour: reminder.hour, minute: reminder.minute),
            days
        )
    }

    private static func practiceName(_ kind: ILStatsPracticeKind) -> String {
        switch kind {
        case .breathMeditation: return "stats.mix.breathMeditation".localized
        case .chanting: return "stats.mix.chanting".localized
        case .recitation: return "stats.mix.recitation".localized
        case .dharmaTalk: return "stats.mix.dharmaTalk".localized
        }
    }
}
