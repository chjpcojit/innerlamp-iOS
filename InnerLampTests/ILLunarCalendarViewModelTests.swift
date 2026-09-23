//
//  ILLunarCalendarViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLunarCalendarViewModelTests: XCTestCase {

    private var mockUseCase: MockILLunarCalendarUseCase!
    private var sut: ILLunarCalendarViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var previousMonthTappedSubject: PassthroughSubject<Void, Never>!
    private var nextMonthTappedSubject: PassthroughSubject<Void, Never>!
    private var pageChangedSubject: PassthroughSubject<Int, Never>!
    private var dayTappedSubject: PassthroughSubject<String, Never>!
    private var closeTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLunarCalendarUseCase()
        sut = ILLunarCalendarViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        previousMonthTappedSubject = PassthroughSubject<Void, Never>()
        nextMonthTappedSubject = PassthroughSubject<Void, Never>()
        pageChangedSubject = PassthroughSubject<Int, Never>()
        dayTappedSubject = PassthroughSubject<String, Never>()
        closeTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        previousMonthTappedSubject = nil
        nextMonthTappedSubject = nil
        pageChangedSubject = nil
        dayTappedSubject = nil
        closeTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILLunarCalendarViewModel.Input {
        ILLunarCalendarViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            previousMonthTapped: previousMonthTappedSubject.eraseToAnyPublisher(),
            nextMonthTapped: nextMonthTappedSubject.eraseToAnyPublisher(),
            pageChanged: pageChangedSubject.eraseToAnyPublisher(),
            dayTapped: dayTappedSubject.eraseToAnyPublisher(),
            closeTapped: closeTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Subscribe `output.state` và trả về state mới nhất (kể cả giá trị `CurrentValueSubject` phát ngay).
    private func observeLatestState() -> () -> ILLunarCalendarStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILLunarCalendarStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_buildsMonthsAndHeaderFromUseCase() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(state?.months.count, 3)
        XCTAssertEqual(state?.currentPage, 0)
        XCTAssertEqual(state?.weekdayLabels.count, 7)
        XCTAssertEqual(state?.headerTitle, String(format: "lunarCalendar.header.titleFormat".localized, 2, 2024))
    }

    func test_viewDidLoad_marksTodaySelectedAndFastDay_andFormatsLunarLabels() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let days = latest()?.months.first?.days ?? []
        // Ngày 10/2/2024 = mùng 1 Tết: hôm nay, đang chọn, ngày trai, nhãn "Mùng 1".
        let tet = days.first { $0.id == "2024-02-10" }
        XCTAssertEqual(tet?.isToday, true)
        XCTAssertEqual(tet?.isSelected, true)
        XCTAssertEqual(tet?.isFastDay, true)
        XCTAssertEqual(tet?.lunarText, "lunarCalendar.day.newMoon".localized)
        // Ngày thường hiển thị số ngày âm.
        let ordinary = days.first { $0.id == "2024-02-11" }
        XCTAssertEqual(ordinary?.lunarText, "2")
        XCTAssertEqual(ordinary?.isFastDay, false)
    }

    func test_viewDidLoad_showsUpcomingSpecialDaysFromUseCase() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        // Mùng 1 đang chọn → 2 ngày trai kế tiếp là mùng 8 (17/2) và rằm (24/2).
        XCTAssertEqual(latest()?.upcoming.map(\.id), ["2024-02-17", "2024-02-24"])
        XCTAssertEqual(latest()?.upcoming.map(\.category), [.fastDay, .fullMoon])
        XCTAssertEqual(latest()?.heroCategory, .newMoon)
    }

    func test_nextMonthTapped_advancesPageAndUpdatesHeader() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        nextMonthTappedSubject.send(())

        XCTAssertEqual(latest()?.currentPage, 1)
        XCTAssertEqual(latest()?.headerTitle, String(format: "lunarCalendar.header.titleFormat".localized, 3, 2024))
    }

    func test_previousMonthTapped_onFirstPage_staysOnFirstPage() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        previousMonthTappedSubject.send(())

        XCTAssertEqual(latest()?.currentPage, 0)
    }

    func test_nextMonthTapped_onLastPage_staysOnLastPage() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        nextMonthTappedSubject.send(())
        nextMonthTappedSubject.send(())
        nextMonthTappedSubject.send(())

        XCTAssertEqual(latest()?.currentPage, 2)
    }

    func test_pageChanged_setsPageAndClampsOutOfRangeValues() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        pageChangedSubject.send(2)
        XCTAssertEqual(latest()?.currentPage, 2)

        pageChangedSubject.send(99)
        XCTAssertEqual(latest()?.currentPage, 2)

        pageChangedSubject.send(-4)
        XCTAssertEqual(latest()?.currentPage, 0)
    }

    func test_dayTapped_selectsDayAndUpdatesHero() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        dayTappedSubject.send("2024-02-24")

        XCTAssertEqual(mockUseCase.selectedDayIDs, ["2024-02-24"])
        let selected = latest()?.months.first?.days.first { $0.isSelected }
        XCTAssertEqual(selected?.id, "2024-02-24")
        XCTAssertEqual(latest()?.heroCategory, .fullMoon)
    }

    func test_dayTapped_onAlreadySelectedDay_doesNotCallUseCase() {
        _ = observeLatestState()
        viewDidLoadSubject.send(())

        dayTappedSubject.send("2024-02-10")

        XCTAssertTrue(mockUseCase.selectedDayIDs.isEmpty)
    }

    func test_closeTapped_firesCloseNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILLunarCalendarNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        closeTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .close)
    }
}

// MARK: - Mock ILLunarCalendarUseCase
/// Dữ liệu cố định: 3 tháng 2/2024–4/2024, hôm nay 10/2/2024 (mùng 1 Tết Giáp Thìn); chỉ dựng
/// vài ngày cần cho test — logic tính lịch thật được test ở `ILLunarCalendarUseCaseTests`.
final class MockILLunarCalendarUseCase: ILLunarCalendarUseCase {
    var getInitialStateCalled = false
    var selectedDayIDs: [String] = []

    private static func makeDay(_ id: String, solar: Int, lunar: Int, month: Int, category: ILLunarCalendarDayCategory) -> ILLunarCalendarDayEntity {
        ILLunarCalendarDayEntity(
            id: id,
            date: Date(timeIntervalSince1970: 0),
            solarDay: solar,
            lunarDay: lunar,
            lunarMonth: month,
            isLunarLeapMonth: false,
            category: category
        )
    }

    private static func makeMonth(id: String, month: Int, days: [ILLunarCalendarDayEntity] = []) -> ILLunarCalendarMonthEntity {
        ILLunarCalendarMonthEntity(
            id: id,
            solarMonth: month,
            solarYear: 2024,
            leadingBlankDays: 4,
            days: days,
            midLunarMonth: month - 1,
            midLunarYear: 2024,
            isMidLunarLeapMonth: false
        )
    }

    func getInitialState() -> ILLunarCalendarEntity {
        getInitialStateCalled = true
        return ILLunarCalendarEntity(
            months: [
                Self.makeMonth(id: "2024-02", month: 2, days: [
                    Self.makeDay("2024-02-10", solar: 10, lunar: 1, month: 1, category: .newMoon),
                    Self.makeDay("2024-02-11", solar: 11, lunar: 2, month: 1, category: .ordinary),
                    Self.makeDay("2024-02-17", solar: 17, lunar: 8, month: 1, category: .fastDay),
                    Self.makeDay("2024-02-24", solar: 24, lunar: 15, month: 1, category: .fullMoon)
                ]),
                Self.makeMonth(id: "2024-03", month: 3),
                Self.makeMonth(id: "2024-04", month: 4)
            ],
            todayID: "2024-02-10",
            selectedDayID: "2024-02-10"
        )
    }

    func selectDay(id: String, in entity: ILLunarCalendarEntity) -> ILLunarCalendarEntity {
        selectedDayIDs.append(id)
        var updated = entity
        updated.selectedDayID = id
        return updated
    }

    func upcomingSpecialDays(in entity: ILLunarCalendarEntity, limit: Int) -> [ILLunarCalendarDayEntity] {
        let all = entity.months.flatMap(\.days)
        guard let index = all.firstIndex(where: { $0.id == entity.selectedDayID }) else { return [] }
        return Array(all[(index + 1)...].filter(\.isFastDay).prefix(limit))
    }
}
