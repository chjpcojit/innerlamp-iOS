//
//  ILSanghaViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSanghaViewModelTests: XCTestCase {

    /// 2026-10-05 12:00 UTC-ish — chỉ cần cố định; các phép so sánh dùng ngày tương đối.
    private let fixedNow = Date(timeIntervalSince1970: 1_790_000_000)

    private var mockUseCase: MockILSanghaUseCase!
    private var sut: ILSanghaViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var viewWillAppearSubject: PassthroughSubject<Void, Never>!
    private var changeTempleTappedSubject: PassthroughSubject<Void, Never>!
    private var myTempleTappedSubject: PassthroughSubject<Void, Never>!
    private var eventsTappedSubject: PassthroughSubject<Void, Never>!
    private var eventActionTappedSubject: PassthroughSubject<String, Never>!
    private var talkTappedSubject: PassthroughSubject<String, Never>!
    private var offerTappedSubject: PassthroughSubject<Void, Never>!
    private var nearbyTempleTappedSubject: PassthroughSubject<String, Never>!
    private var pickTappedSubject: PassthroughSubject<String, Never>!
    private var onlineSessionTappedSubject: PassthroughSubject<String, Never>!
    private var festivalsTappedSubject: PassthroughSubject<Void, Never>!
    private var dayReminderTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILSanghaUseCase(now: fixedNow)
        sut = ILSanghaViewModel(useCase: mockUseCase, now: { [fixedNow] in fixedNow })
        cancellables = []
        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        viewWillAppearSubject = PassthroughSubject<Void, Never>()
        changeTempleTappedSubject = PassthroughSubject<Void, Never>()
        myTempleTappedSubject = PassthroughSubject<Void, Never>()
        eventsTappedSubject = PassthroughSubject<Void, Never>()
        eventActionTappedSubject = PassthroughSubject<String, Never>()
        talkTappedSubject = PassthroughSubject<String, Never>()
        offerTappedSubject = PassthroughSubject<Void, Never>()
        nearbyTempleTappedSubject = PassthroughSubject<String, Never>()
        pickTappedSubject = PassthroughSubject<String, Never>()
        onlineSessionTappedSubject = PassthroughSubject<String, Never>()
        festivalsTappedSubject = PassthroughSubject<Void, Never>()
        dayReminderTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILSanghaViewModel.Input {
        ILSanghaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            changeTempleTapped: changeTempleTappedSubject.eraseToAnyPublisher(),
            myTempleTapped: myTempleTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            eventActionTapped: eventActionTappedSubject.eraseToAnyPublisher(),
            talkTapped: talkTappedSubject.eraseToAnyPublisher(),
            offerTapped: offerTappedSubject.eraseToAnyPublisher(),
            nearbyTempleTapped: nearbyTempleTappedSubject.eraseToAnyPublisher(),
            pickTapped: pickTappedSubject.eraseToAnyPublisher(),
            onlineSessionTapped: onlineSessionTappedSubject.eraseToAnyPublisher(),
            festivalsTapped: festivalsTappedSubject.eraseToAnyPublisher(),
            dayReminderTapped: dayReminderTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Transforms, sends `viewDidLoad`; returns a getter for the latest successful state (updated by
    /// later toggles too). Everything is synchronous — the tab is UI-only.
    private func loadSuccessfully() -> () -> ILSanghaStateModel? {
        var latest: ILSanghaStateModel?
        sut.transform(input: makeInput()).state.sink { state in
            if case .success(let model) = state { latest = model }
        }.store(in: &cancellables)
        viewDidLoadSubject.send(())
        return { latest }
    }

    private func navigationEvent(_ action: () -> Void) -> ILSanghaNavEvent? {
        var received: ILSanghaNavEvent?
        sut.navigationEventPublisher.sink { received = $0 }.store(in: &cancellables)
        action()
        return received
    }

    // MARK: - Loading

    func test_viewDidLoad_withChosenTemple_buildsMyTempleModel_andNoChooser() {
        mockUseCase.myTempleID = "temple_1"
        let state = loadSuccessfully()()

        XCTAssertNil(state?.chooser)
        XCTAssertEqual(state?.myTemple?.id, "temple_1")
        XCTAssertEqual(state?.myTemple?.name, "Chùa Từ Quang")
        XCTAssertEqual(state?.myTemple?.place, "Bình Thạnh")
        XCTAssertEqual(state?.myTemple?.announcements.count, 2)
        XCTAssertEqual(state?.myTemple?.events.count, 2)
        XCTAssertEqual(state?.myTemple?.talks.count, 1)
        XCTAssertTrue(state?.myTemple?.peersText.contains("1.248") == true)
    }

    func test_viewDidLoad_withoutChosenTemple_buildsChooserModel_andNoMyTemple() {
        let state = loadSuccessfully()()

        XCTAssertNil(state?.myTemple)
        XCTAssertEqual(state?.chooser?.nearby.map(\.id), ["near_1"])
        XCTAssertEqual(state?.chooser?.nearby.first?.subtitle, "Bình Thạnh · 3,2 km")
        XCTAssertEqual(state?.chooser?.online.count, 1)
        XCTAssertEqual(state?.chooser?.retreats.count, 1)
    }

    func test_upcomingDays_areMappedWithSuggestionAndReminderLabel() {
        let state = loadSuccessfully()()

        XCTAssertEqual(state?.days.count, 2)
        XCTAssertEqual(state?.days.first?.title, "Vía Quan Âm")
        XCTAssertEqual(state?.days.first?.isFestival, true)
        XCTAssertEqual(state?.days.first?.suggestion, "sangha.day.suggestion.festival".localized)
        XCTAssertEqual(state?.days.first?.reminderLabel, "sangha.action.remind".localized)
    }

    // MARK: - Choose / change temple

    func test_pickTapped_savesTemple_andSwitchesToMyTempleState() {
        let state = loadSuccessfully()
        XCTAssertNotNil(state()?.chooser)

        pickTappedSubject.send("temple_1")

        XCTAssertEqual(mockUseCase.myTempleID, "temple_1")
        XCTAssertNotNil(state()?.myTemple)
        XCTAssertNil(state()?.chooser)
    }

    func test_changeTempleTapped_opensTempleFinder_andKeepsTheCurrentTemple() {
        mockUseCase.myTempleID = "temple_1"
        let state = loadSuccessfully()
        var events: [ILSanghaNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)

        changeTempleTappedSubject.send(())

        XCTAssertEqual(events, [.openTempleFinder])
        XCTAssertEqual(mockUseCase.myTempleID, "temple_1")
        XCTAssertNotNil(state()?.myTemple)
    }

    func test_viewWillAppear_reloadsTheTempleChosenElsewhere() {
        mockUseCase.myTempleID = "temple_1"
        let state = loadSuccessfully()
        XCTAssertEqual(state()?.myTemple?.id, "temple_1")

        mockUseCase.myTempleID = "temple_2"
        viewWillAppearSubject.send(())

        XCTAssertEqual(state()?.myTemple?.id, "temple_2")
    }

    // MARK: - Toggles

    func test_eventActionTapped_togglesLabelBetweenRemindAndReminded() {
        mockUseCase.myTempleID = "temple_1"
        let state = loadSuccessfully()
        XCTAssertEqual(state()?.myTemple?.events.first?.actionLabel, "sangha.action.remind".localized)

        eventActionTappedSubject.send("event-weekly")
        XCTAssertEqual(state()?.myTemple?.events.first?.actionLabel, "sangha.action.reminded".localized)
        XCTAssertEqual(state()?.myTemple?.events.first?.isActionOn, true)

        eventActionTappedSubject.send("event-weekly")
        XCTAssertEqual(state()?.myTemple?.events.first?.actionLabel, "sangha.action.remind".localized)
    }

    func test_dayReminderTapped_togglesReminderOnTheDay() {
        let state = loadSuccessfully()
        let dayID = state()?.days.first?.id ?? ""

        dayReminderTappedSubject.send(dayID)
        XCTAssertEqual(state()?.days.first?.isReminderOn, true)
        XCTAssertEqual(state()?.days.first?.reminderLabel, "sangha.action.reminded".localized)
    }

    // MARK: - Navigation

    func test_myTempleTapped_opensChosenTemple() {
        mockUseCase.myTempleID = "temple_1"
        _ = loadSuccessfully()
        XCTAssertEqual(navigationEvent { self.myTempleTappedSubject.send(()) }, .openTemple(id: "temple_1"))
    }

    func test_nearbyTempleTapped_opensThatTemple() {
        _ = sut.transform(input: makeInput())
        XCTAssertEqual(navigationEvent { self.nearbyTempleTappedSubject.send("near_1") }, .openTemple(id: "near_1"))
    }

    func test_eventsTalkOfferOnlineFestivalsTaps_fireMatchingEvents() {
        _ = sut.transform(input: makeInput())
        XCTAssertEqual(navigationEvent { self.eventsTappedSubject.send(()) }, .openEvents)
        XCTAssertEqual(navigationEvent { self.talkTappedSubject.send("talk.vulan.hieu") }, .openTalk(id: "talk.vulan.hieu"))
        XCTAssertEqual(navigationEvent { self.offerTappedSubject.send(()) }, .openOffer)
        XCTAssertEqual(navigationEvent { self.onlineSessionTappedSubject.send("online-1") }, .openOnlineSession(id: "online-1"))
        XCTAssertEqual(navigationEvent { self.festivalsTappedSubject.send(()) }, .openFestivals)
    }

    // MARK: - Helpers

    func test_status_openAndClosedByOperatingHours() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: fixedNow) ?? fixedNow

        XCTAssertEqual(ILSanghaViewModel.status(operatingHours: "06:00 - 18:00", now: noon)?.isOpen, true)
        XCTAssertEqual(ILSanghaViewModel.status(operatingHours: "13:00 - 18:00", now: noon)?.isOpen, false)
        XCTAssertNil(ILSanghaViewModel.status(operatingHours: "", now: noon))
    }

    func test_formatDistance_usesVietnameseDecimalComma() {
        XCTAssertEqual(ILSanghaViewModel.formatDistance(3.2), "3,2 km")
    }

    func test_formatCount_groupsThousandsTheVietnameseWay() {
        XCTAssertEqual(ILSanghaViewModel.formatCount(1248), "1.248")
    }
}

// MARK: - Mock

final class MockILSanghaUseCase: ILSanghaUseCase {

    var myTempleID: String?
    private let now: Date

    init(now: Date = Date(timeIntervalSince1970: 1_790_000_000)) {
        self.now = now
    }

    func loadMyTemple() -> ILSanghaMyTempleEntity? {
        guard let myTempleID else { return nil }
        let day: TimeInterval = 24 * 60 * 60
        return ILSanghaMyTempleEntity(
            temple: Self.temple(id: myTempleID, name: "Chùa Từ Quang"),
            announcements: [
                ILSanghaAnnouncementEntity(id: "n1", postedAt: now, text: "A"),
                ILSanghaAnnouncementEntity(id: "n2", postedAt: now.addingTimeInterval(-3 * day), text: "B")
            ],
            events: [
                ILSanghaEventEntity(id: "event-weekly", date: now, title: "Thiền tối", detail: "19:30", action: .remind),
                ILSanghaEventEntity(id: "event-retreat", date: now, title: "Khóa tu", detail: "Chủ Nhật", action: .reserve)
            ],
            talks: [ILSanghaTalkEntity(id: "talk.vulan.hieu", title: "Hiếu là đạo", speaker: "Thầy", durationMinutes: 46)],
            practitionerCount: 1248,
            upcomingRetreatAttendeeCount: 23
        )
    }

    func loadChooser() -> ILSanghaChooserEntity {
        ILSanghaChooserEntity(
            nearbyTemples: [Self.temple(id: "near_1", name: "Chùa Gần")],
            onlineSessions: [
                ILSanghaOnlineSessionEntity(id: "online-1", schedule: "HẰNG NGÀY", isDaily: true, title: "Thiền", detail: "20 phút")
            ],
            retreats: [ILSanghaEventEntity(id: "retreat-1", date: now, title: "Khóa", detail: "Đà Lạt", action: .none)]
        )
    }

    func selectMyTemple(id: String) { myTempleID = id }
    func selectMyTemple(_ temple: ILTempleSummaryEntity) { myTempleID = temple.id }

    func loadUpcomingDays(limit: Int) -> [ILFestivalDayEntity] {
        let day: TimeInterval = 24 * 60 * 60
        return [
            ILFestivalDayEntity(id: "d1", date: now.addingTimeInterval(day), title: "Vía Quan Âm", kind: .festival, daysUntil: 1),
            ILFestivalDayEntity(id: "d2", date: now.addingTimeInterval(5 * day), title: "Rằm", kind: .observance, daysUntil: 5)
        ]
    }

    static func temple(id: String, name: String) -> ILSanghaTempleEntity {
        ILSanghaTempleEntity(
            id: id, name: name, address: "Bình Thạnh", abbot: "Đại đức Thích Minh Đạo",
            operatingHours: "06:00 - 18:00", distanceKm: 3.2
        )
    }
}
