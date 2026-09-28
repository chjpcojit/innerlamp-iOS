//
//  ILStatsViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILStatsViewModelTests: XCTestCase {

    private var mockUseCase: MockILStatsUseCase!
    private var sut: ILStatsViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var reminderTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILStatsUseCase()
        sut = ILStatsViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        reminderTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        reminderTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILStatsViewModel.Input {
        ILStatsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Rebuilds `sut` with the mock's current `stats`, then wires the input.
    private func makeSut() -> ILStatsViewModel.Output {
        sut = ILStatsViewModel(useCase: mockUseCase)
        return sut.transform(input: makeInput())
    }

    private func captureLatestState(_ output: ILStatsViewModel.Output) -> () -> ILStatsStateModel? {
        var latest: ILStatsStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILStatsNavEvent] {
        var events: [ILStatsNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_mapsEntityToStateModel() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getStatsCallCount, 2) // init + viewDidLoad
        let state = latest()

        XCTAssertEqual(state?.streak.valueText, "42")
        XCTAssertEqual(state?.streak.unitText, "stats.streak.unit".localized)
        XCTAssertEqual(state?.streak.milestoneText, String(format: "stats.streak.milestone".localized, 6, "An cư 48 ngày"))
        XCTAssertEqual(state?.streak.milestoneProgress ?? 0, 42.0 / 48.0, accuracy: 0.0001)

        XCTAssertEqual(state?.tiles.count, 2)
        XCTAssertEqual(state?.tiles[0].valueText, "168")
        XCTAssertEqual(state?.tiles[0].unitText, "stats.tile.total.unit".localized)
        XCTAssertEqual(state?.tiles[0].footnote, String(format: "stats.tile.total.deltaUp".localized, 8))
        XCTAssertEqual(state?.tiles[0].footnoteTone, .positive)
        XCTAssertEqual(state?.tiles[1].valueText, "05:40")
        XCTAssertEqual(state?.tiles[1].unitText, "")
        XCTAssertEqual(state?.tiles[1].footnote, String(format: "stats.tile.usualTime.footnote".localized, 68))
        XCTAssertEqual(state?.tiles[1].footnoteTone, .neutral)

        XCTAssertEqual(state?.weeklyChart?.title, String(format: "stats.chart.title".localized, 3))
        XCTAssertEqual(state?.weeklyChart?.averageText, String(format: "stats.chart.average".localized, 22))
        XCTAssertEqual(state?.weeklyChart?.startLabel, String(format: "stats.chart.weekLabel".localized, 36))
        XCTAssertEqual(state?.weeklyChart?.endLabel, String(format: "stats.chart.weekLabel".localized, 38))
        XCTAssertEqual(state?.weeklyChart?.bars.count, 3)

        XCTAssertEqual(state?.mix.map(\.kind), [.breathMeditation, .chanting])
        XCTAssertEqual(state?.mix.first?.name, "stats.mix.breathMeditation".localized)
        XCTAssertEqual(state?.mix.first?.fraction ?? 0, 0.6, accuracy: 0.0001)
        XCTAssertEqual(state?.mix.first?.percentText, String(format: "stats.mix.percent".localized, 60))

        XCTAssertEqual(
            state?.reminderSubtitle,
            String(format: "stats.reminder.summary".localized, "05:30", String(format: "stats.reminder.daysPerWeek".localized, 6))
        )
    }

    func test_viewDidLoad_withMilestoneReached_hidesMilestone() {
        mockUseCase.stats.nextMilestone = ILStatsMilestoneEntity(title: "An cư 30 ngày", targetDays: 30)
        let latest = captureLatestState(makeSut())

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.streak.milestoneText)
        XCTAssertEqual(latest()?.streak.milestoneProgress, 0)
    }

    func test_viewDidLoad_withNoMilestone_hidesMilestone() {
        mockUseCase.stats.nextMilestone = nil
        let latest = captureLatestState(makeSut())

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.streak.milestoneText)
    }

    func test_viewDidLoad_withNoWeeklyData_hidesChart() {
        mockUseCase.stats.weeklyMinutes = []
        let latest = captureLatestState(makeSut())

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.weeklyChart)
    }

    func test_viewDidLoad_withNoMix_hasMixIsFalse() {
        mockUseCase.stats.practiceMix = []
        let latest = captureLatestState(makeSut())

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.hasMix, false)
    }

    func test_viewDidLoad_withNegativeDelta_usesNeutralTone() {
        mockUseCase.stats.hoursDeltaVsLastMonth = -3
        let latest = captureLatestState(makeSut())

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.tiles.first?.footnote, String(format: "stats.tile.total.deltaDown".localized, 3))
        XCTAssertEqual(latest()?.tiles.first?.footnoteTone, .neutral)
    }

    func test_viewDidLoad_withNoReminder_showsNotSet() {
        mockUseCase.stats.reminder = nil
        let latest = captureLatestState(makeSut())

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.reminderSubtitle, "stats.reminder.none".localized)
    }

    // MARK: - Navigation
    func test_backTapped_firesGoBack() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        backTappedSubject.send(())

        XCTAssertEqual(events(), [.goBack])
    }

    func test_reminderTapped_firesOpenReminder() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        reminderTappedSubject.send(())

        XCTAssertEqual(events(), [.openReminder])
    }

    // MARK: - Formatting helpers
    func test_makeBars_normalizesAgainstPeakWeek() {
        let bars = ILStatsViewModel.makeBars(from: [50, 100, 0])

        XCTAssertEqual(bars.map(\.heightRatio), [0.5, 1, 0])
        XCTAssertEqual(bars[0].opacity, 0.675, accuracy: 0.0001)
        XCTAssertEqual(bars[1].opacity, 1, accuracy: 0.0001)
        XCTAssertEqual(bars[2].opacity, 0.35, accuracy: 0.0001)
    }

    func test_makeBars_allZeroWeeks_doesNotDivideByZero() {
        let bars = ILStatsViewModel.makeBars(from: [0, 0])

        XCTAssertEqual(bars.map(\.heightRatio), [0, 0])
    }

    func test_formatHoursDelta_coversUpDownAndSame() {
        XCTAssertEqual(ILStatsViewModel.formatHoursDelta(8), String(format: "stats.tile.total.deltaUp".localized, 8))
        XCTAssertEqual(ILStatsViewModel.formatHoursDelta(-2), String(format: "stats.tile.total.deltaDown".localized, 2))
        XCTAssertEqual(ILStatsViewModel.formatHoursDelta(0), "stats.tile.total.deltaSame".localized)
    }

    func test_formatReminder_everyDay() {
        let reminder = ILStatsReminderEntity(hour: 21, minute: 5, activeDayCount: 7)

        XCTAssertEqual(
            ILStatsViewModel.formatReminder(reminder),
            String(format: "stats.reminder.summary".localized, "21:05", "stats.reminder.everyDay".localized)
        )
    }
}

// MARK: - Mock ILStatsUseCase
final class MockILStatsUseCase: ILStatsUseCase {
    var stats: ILStatsEntity
    private(set) var getStatsCallCount = 0

    init() {
        stats = ILStatsEntity(
            streakDays: 42,
            nextMilestone: ILStatsMilestoneEntity(title: "An cư 48 ngày", targetDays: 48),
            totalHours: 168,
            hoursDeltaVsLastMonth: 8,
            usualStartHour: 5,
            usualStartMinute: 40,
            morningSharePercent: 68,
            weeklyMinutes: [
                ILStatsWeekEntity(weekOfYear: 36, minutes: 70),
                ILStatsWeekEntity(weekOfYear: 37, minutes: 140),
                ILStatsWeekEntity(weekOfYear: 38, minutes: 105)
            ],
            averageMinutesPerDay: 22,
            practiceMix: [
                ILStatsPracticeShareEntity(kind: .breathMeditation, percent: 60),
                ILStatsPracticeShareEntity(kind: .chanting, percent: 40)
            ],
            reminder: ILStatsReminderEntity(hour: 5, minute: 30, activeDayCount: 6)
        )
    }

    func getStats() -> ILStatsEntity {
        getStatsCallCount += 1
        return stats
    }
}
