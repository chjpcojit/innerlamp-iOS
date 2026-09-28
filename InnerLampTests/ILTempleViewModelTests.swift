//
//  ILTempleViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILTempleViewModelTests: XCTestCase {

    private var mockUseCase: MockILTempleUseCase!
    private var sut: ILTempleViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var followTappedSubject: PassthroughSubject<Void, Never>!
    private var bioToggledSubject: PassthroughSubject<Void, Never>!
    private var googleMapsTappedSubject: PassthroughSubject<Void, Never>!
    private var appleMapsTappedSubject: PassthroughSubject<Void, Never>!
    private var offerTappedSubject: PassthroughSubject<Void, Never>!
    private var eventsTappedSubject: PassthroughSubject<Void, Never>!
    private var sessionTappedSubject: PassthroughSubject<String, Never>!
    private var contactTappedSubject: PassthroughSubject<String, Never>!

    /// 10:00 sáng 10/01/2026 (UTC+7) — nằm trong khung `regularHours`/`holidayHours` giống nhau
    /// của fixture (`5:00 – 20:00`) nên `isOpen` đúng bất kể hôm đó là Rằm/Mùng Một hay không.
    private static let fixedNow: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 7 * 3600) ?? .current
        return calendar.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: 10, minute: 0)) ?? Date()
    }()

    override func setUp() {
        super.setUp()
        mockUseCase = MockILTempleUseCase()
        sut = ILTempleViewModel(useCase: mockUseCase, templeID: "tp-fixture", now: { Self.fixedNow })
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        followTappedSubject = PassthroughSubject<Void, Never>()
        bioToggledSubject = PassthroughSubject<Void, Never>()
        googleMapsTappedSubject = PassthroughSubject<Void, Never>()
        appleMapsTappedSubject = PassthroughSubject<Void, Never>()
        offerTappedSubject = PassthroughSubject<Void, Never>()
        eventsTappedSubject = PassthroughSubject<Void, Never>()
        sessionTappedSubject = PassthroughSubject<String, Never>()
        contactTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        followTappedSubject = nil
        bioToggledSubject = nil
        googleMapsTappedSubject = nil
        appleMapsTappedSubject = nil
        offerTappedSubject = nil
        eventsTappedSubject = nil
        sessionTappedSubject = nil
        contactTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILTempleViewModel.Input {
        ILTempleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            followTapped: followTappedSubject.eraseToAnyPublisher(),
            bioToggled: bioToggledSubject.eraseToAnyPublisher(),
            googleMapsTapped: googleMapsTappedSubject.eraseToAnyPublisher(),
            appleMapsTapped: appleMapsTappedSubject.eraseToAnyPublisher(),
            offerTapped: offerTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            sessionTapped: sessionTappedSubject.eraseToAnyPublisher(),
            contactTapped: contactTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILTempleStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILTempleStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_mapsEntityToState() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        guard let state = latest() else { return XCTFail("expected state") }

        // Hero
        XCTAssertEqual(state.rankChip, "Di tích Quốc gia")
        XCTAssertEqual(state.sectChip, "Bắc tông")
        XCTAssertEqual(state.name, "Chùa Mẫu")
        XCTAssertTrue(state.hasAlias)
        XCTAssertEqual(state.aliasLine, String(format: "temple.hero.alias".localized, "Chùa Cổ"))
        XCTAssertEqual(state.placeLine, "Quận 1, TP. Hồ Chí Minh")

        // Buttons
        XCTAssertEqual(state.followButtonTitle, "temple.follow".localized)
        XCTAssertEqual(state.directionsButtonTitle, "temple.directions".localized)
        XCTAssertEqual(state.offerButtonTitle, "temple.offer".localized)

        // Status card — user cố định đúng vị trí chùa nên khoảng cách bằng 0.
        XCTAssertTrue(state.isOpen)
        XCTAssertEqual(state.openStatusText, "temple.status.open".localized)
        XCTAssertEqual(state.openNoteText, String(format: "temple.status.closesAt".localized, "20:00"))
        XCTAssertEqual(state.distanceText, String(format: "temple.distance.near".localized, "0,0"))
        XCTAssertEqual(state.hourRows.count, 2)
        XCTAssertEqual(state.hourRows[0].value, "5:00 – 20:00")
        XCTAssertEqual(state.hourRows[1].value, "5:00 – 20:00")

        // Facts grid
        XCTAssertEqual(state.facts.map(\.value), ["Năm 1900", "Di tích Quốc gia", "Bắc tông", "Đông Nam Bộ"])

        // Giới thiệu
        XCTAssertEqual(state.descriptionText, "Tiểu sử mẫu.")
        XCTAssertFalse(state.isBiographyExpanded)
        XCTAssertEqual(state.biographyToggleTitle, "temple.bio.readMore".localized)

        // Tổ chức & truyền thừa — 1 mục có giá trị, 1 mục "Đang cập nhật".
        XCTAssertEqual(state.orgInfo.count, 2)
        XCTAssertEqual(state.orgInfo[0].value, "Đại đức A")
        XCTAssertTrue(state.orgInfo[0].hasValue)
        XCTAssertEqual(state.orgInfo[1].value, "temple.info.updating".localized)
        XCTAssertFalse(state.orgInfo[1].hasValue)

        // Kiến trúc & di sản
        XCTAssertEqual(state.archStyle, "Kiểu chữ Tam")
        XCTAssertEqual(state.highlights, ["Điểm nổi bật 1"])

        // Tiện ích — 1 có, 1 không.
        XCTAssertEqual(state.amenities.count, 2)
        XCTAssertTrue(state.amenities[0].isAvailable)
        XCTAssertEqual(state.amenities[0].value, "Có · miễn phí")
        XCTAssertFalse(state.amenities[1].isAvailable)
        XCTAssertEqual(state.amenities[1].value, "temple.amenity.none".localized)

        // Lưu ý khi viếng thăm
        XCTAssertEqual(state.visitRules.map(\.number), ["01", "02"])
        XCTAssertEqual(state.visitRules.map(\.text), ["Quy định 1", "Quy định 2"])

        // Sự kiện & khóa học
        XCTAssertTrue(state.hasUpcomingSchedule)
        XCTAssertEqual(state.sessions.count, 1)
        XCTAssertEqual(state.sessions.first?.title, "Tụng Kinh Vu Lan")
        XCTAssertEqual(state.sessions.first?.tone, .gold)
        XCTAssertEqual(state.sessions.first?.glyph, .book)

        // Vị trí & liên hệ — 1 mục có, 1 mục "Đang cập nhật".
        XCTAssertEqual(state.addressLine, "128 Đường A, Phường B, Quận 1, TP. Hồ Chí Minh")
        XCTAssertEqual(state.regionLine, "Miền Nam · Đông Nam Bộ")
        XCTAssertEqual(state.contacts.count, 2)
        XCTAssertTrue(state.contacts[0].hasValue)
        XCTAssertFalse(state.contacts[1].hasValue)
        XCTAssertEqual(state.contacts[1].value, "temple.info.updating".localized)

        // Chân trang
        XCTAssertEqual(state.updatedText, String(format: "temple.footer.updated".localized, "09/2026"))
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_offerTapped_firesOfferNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        offerTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .offer)
    }

    func test_eventsTapped_firesEventsNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        eventsTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .events)
    }

    func test_sessionTapped_firesSessionNavigationEventWithID() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        sessionTappedSubject.send("temple.session.vulan")

        XCTAssertEqual(receivedEvent, .session(id: "temple.session.vulan"))
    }

    func test_followTapped_togglesLabelOptimisticallyAndCallsToggleFollow() {
        let expectation = expectation(description: "toggleFollow called")
        mockUseCase.onToggleFollow = { expectation.fulfill() }
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        XCTAssertEqual(latest()?.followButtonTitle, "temple.follow".localized)

        followTappedSubject.send(())

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockUseCase.toggledTempleIDs, ["tp-fixture"])
        XCTAssertEqual(latest()?.followButtonTitle, "temple.following".localized)
    }

    func test_bioToggled_expandsAndCollapsesBiography() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        XCTAssertEqual(latest()?.isBiographyExpanded, false)

        bioToggledSubject.send(())
        XCTAssertEqual(latest()?.isBiographyExpanded, true)
        XCTAssertEqual(latest()?.biographyToggleTitle, "temple.bio.collapse".localized)

        bioToggledSubject.send(())
        XCTAssertEqual(latest()?.isBiographyExpanded, false)
    }

    func test_googleMapsTapped_firesOpenURLWithGoogleMapsLink() {
        _ = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        googleMapsTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openURL("https://www.google.com/maps/dir/?api=1&destination=10.7769,106.7009"))
    }

    func test_appleMapsTapped_firesOpenURLWithAppleMapsLink() {
        _ = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        appleMapsTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openURL("https://maps.apple.com/?daddr=10.7769,106.7009"))
    }

    func test_contactTapped_withValue_firesOpenURLWithTelLink() {
        _ = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        contactTappedSubject.send("phone")

        XCTAssertEqual(receivedEvent, .openURL("tel:0281234567"))
    }

    func test_contactTapped_withoutValue_firesNoEvent() {
        _ = sut.transform(input: makeInput())
        viewDidLoadSubject.send(())
        var receivedEvent: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        contactTappedSubject.send("fanpage")

        XCTAssertNil(receivedEvent)
    }
}

// MARK: - Mock ILTempleUseCase
final class MockILTempleUseCase: ILTempleUseCase {
    var getInitialStateCalled = false
    var toggledTempleIDs: [String] = []
    var onToggleFollow: (() -> Void)?

    func getInitialState(templeID: String) -> ILTempleEntity {
        getInitialStateCalled = true
        return ILTempleEntity(
            id: "tp-fixture",
            name: "Chùa Mẫu",
            aliases: ["Chùa Cổ"],
            latitude: 10.7769, longitude: 106.7009,
            street: "128 Đường A", ward: "Phường B", district: "Quận 1", province: "TP. Hồ Chí Minh",
            region: "Miền Nam", subRegion: "Đông Nam Bộ",
            sect: "Bắc tông",
            orgInfo: [
                ILTempleOrgInfoEntity(id: "abbot", label: "Trụ trì", value: "Đại đức A"),
                ILTempleOrgInfoEntity(id: "founder", label: "Tổ khai sơn", value: nil)
            ],
            era: "Năm 1900", rank: "Di tích Quốc gia",
            archStyle: "Kiểu chữ Tam", materials: "Gỗ",
            highlights: ["Điểm nổi bật 1"],
            bio: "Tiểu sử mẫu.",
            regularHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1200),
            holidayHours: ILTempleOpeningHoursEntity(openMinute: 300, closeMinute: 1200),
            contacts: [
                ILTempleContactEntity(id: "phone", label: "Hotline", rawValue: "028 1234 567"),
                ILTempleContactEntity(id: "fanpage", label: "Fanpage", rawValue: nil)
            ],
            amenities: [
                ILTempleAmenityEntity(id: "car", label: "Bãi đỗ ô tô", value: "Có · miễn phí"),
                ILTempleAmenityEntity(id: "bike", label: "Giữ xe máy", value: nil)
            ],
            visitRules: ["Quy định 1", "Quy định 2"],
            hasUpcomingSchedule: true,
            sessions: [
                ILTempleSessionEntity(
                    id: "temple.session.vulan",
                    title: "Tụng Kinh Vu Lan",
                    subtitle: "CN 13/9 · 8:00 · Chánh điện",
                    trailingText: "Đã ghi danh",
                    tone: .gold,
                    glyph: .book
                )
            ],
            updatedLabel: "09/2026"
        )
    }

    func toggleFollow(templeID: String) async throws {
        toggledTempleIDs.append(templeID)
        onToggleFollow?()
    }
}
