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
    private var retryTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var followTappedSubject: PassthroughSubject<Void, Never>!
    private var bioToggledSubject: PassthroughSubject<Void, Never>!
    private var googleMapsTappedSubject: PassthroughSubject<Void, Never>!
    private var appleMapsTappedSubject: PassthroughSubject<Void, Never>!
    private var offerTappedSubject: PassthroughSubject<Void, Never>!
    private var eventsTappedSubject: PassthroughSubject<Void, Never>!
    private var sessionTappedSubject: PassthroughSubject<String, Never>!
    private var contactTappedSubject: PassthroughSubject<String, Never>!

    /// 10:00 on 10/01/2026 in the device time zone (the ViewModel reads `Calendar.current`) —
    /// inside the fixture's "05:00 - 20:00".
    private static let fixedNow = makeLocalDate(hour: 10)

    private static func makeLocalDate(hour: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 10, hour: hour, minute: 0)) ?? Date()
    }

    override func setUp() {
        super.setUp()
        mockUseCase = MockILTempleUseCase()
        sut = makeSUT(now: Self.fixedNow)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        retryTappedSubject = PassthroughSubject<Void, Never>()
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
        retryTappedSubject = nil
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

    private func makeSUT(now: Date) -> ILTempleViewModel {
        ILTempleViewModel(useCase: mockUseCase, templeID: "temple_fixture", now: { now })
    }

    private func makeInput() -> ILTempleViewModel.Input {
        ILTempleViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            retryTapped: retryTappedSubject.eraseToAnyPublisher(),
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

    /// Transforms, records every state, and returns the output (for `errorMessage`).
    @discardableResult
    private func observeStates(_ states: @escaping (ViewState<ILTempleStateModel>) -> Void) -> ILTempleViewModel.Output {
        let output = sut.transform(input: makeInput())
        output.state.sink(receiveValue: states).store(in: &cancellables)
        return output
    }

    /// Sends `viewDidLoad` and waits for the first `.success`; returns a getter for the latest one.
    private func loadSuccessfully() -> () -> ILTempleStateModel? {
        var latest: ILTempleStateModel?
        let loaded = expectation(description: "temple loaded")
        loaded.assertForOverFulfill = false
        observeStates { state in
            if case .success(let model) = state {
                latest = model
                loaded.fulfill()
            }
        }
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 1)
        return { latest }
    }

    // MARK: - Loading

    func test_viewDidLoad_emitsLoadingThenSuccess_andRequestsTempleID() {
        var states: [ViewState<ILTempleStateModel>] = []
        let loaded = expectation(description: "temple loaded")
        observeStates { state in
            states.append(state)
            if case .success = state { loaded.fulfill() }
        }

        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 1)

        XCTAssertEqual(mockUseCase.requestedIDs, ["temple_fixture"])
        guard states.count == 3 else { return XCTFail("expected idle → loading → success, got \(states)") }
        if case .idle = states[0] {} else { XCTFail("expected .idle first") }
        if case .loading = states[1] {} else { XCTFail("expected .loading second") }
    }

    func test_viewDidLoad_mapsDetailToState() {
        let latest = loadSuccessfully()
        guard let state = latest() else { return XCTFail("expected state") }

        // Hero
        XCTAssertEqual(state.headerTitle, "Chùa Mẫu")
        XCTAssertEqual(state.rankChip, "temple.rank.nationalRelic".localized)
        XCTAssertEqual(state.sectChip, "temple.sect.bacTong".localized)
        XCTAssertEqual(state.name, "Chùa Mẫu")
        XCTAssertTrue(state.hasAlias)
        XCTAssertEqual(state.aliasLine, String(format: "temple.hero.alias".localized, "Chùa Cổ · Cổ Tự"))
        XCTAssertEqual(state.placeLine, "Quận 1, TP. Hồ Chí Minh")

        // Buttons
        XCTAssertEqual(state.followButtonTitle, "temple.follow".localized)
        XCTAssertEqual(state.directionsButtonTitle, "temple.directions".localized)
        XCTAssertEqual(state.offerButtonTitle, "temple.offer".localized)

        // Status card — API hours on the weekday row; no holiday hours / distance in the API.
        XCTAssertTrue(state.isOpen)
        XCTAssertEqual(state.openStatusText, "temple.status.open".localized)
        XCTAssertEqual(state.openNoteText, String(format: "temple.status.closesAt".localized, "20:00"))
        XCTAssertEqual(state.distanceText, "")
        XCTAssertEqual(state.hourRows, [
            ILTempleHourRowModel(id: "weekday", label: "temple.hours.weekday".localized, value: "5:00 – 20:00", isToday: true),
            ILTempleHourRowModel(id: "holiday", label: "temple.hours.holiday".localized, value: "temple.info.updating".localized, isToday: false)
        ])

        // Facts grid
        XCTAssertEqual(state.facts.map(\.value), [
            String(format: "temple.facts.eraFormat".localized, 1900),
            "temple.rank.nationalRelic".localized,
            "temple.sect.bacTong".localized,
            "temple.region.south".localized
        ])

        // Org info — abbot present, founder empty and "Giáo hội" not in the API → "Đang cập nhật".
        XCTAssertEqual(state.orgInfo.map(\.id), ["abbot", "founder", "sangha"])
        XCTAssertEqual(state.orgInfo[0].value, "Đại đức A")
        XCTAssertTrue(state.orgInfo[0].hasValue)
        XCTAssertEqual(state.orgInfo[1].value, "temple.info.updating".localized)
        XCTAssertFalse(state.orgInfo[1].hasValue)
        XCTAssertFalse(state.orgInfo[2].hasValue)

        // Amenities — the 4 server booleans; "Kinh sách" is not in the API → "Đang cập nhật".
        XCTAssertEqual(state.amenities.map(\.id), ["car", "bike", "veg", "books", "retreat"])
        XCTAssertEqual(state.amenities.map(\.isAvailable), [true, false, true, false, false])
        XCTAssertEqual(state.amenities[0].value, "temple.amenity.available".localized)
        XCTAssertEqual(state.amenities[1].value, "temple.amenity.none".localized)
        XCTAssertEqual(state.amenities[3].value, "temple.info.updating".localized)

        // Editorial content (contract v1.1) — intro, architecture, numbered visiting notes.
        XCTAssertEqual(state.descriptionText, "Giới thiệu mẫu.")
        XCTAssertEqual(state.architectureText, "Kiến trúc mẫu.")
        XCTAssertEqual(state.visitRules, [
            ILTempleRuleModel(id: "rule_0", number: "01", text: "Lưu ý một."),
            ILTempleRuleModel(id: "rule_1", number: "02", text: "Lưu ý hai.")
        ])

        // Sections the API does not supply are left unfilled (the UI shows "Đang cập nhật").
        XCTAssertEqual(state.highlights, [])
        XCTAssertFalse(state.hasUpcomingSchedule)
        XCTAssertEqual(state.sessions, [])
        XCTAssertEqual(state.updatedText, "")
        XCTAssertEqual(state.contacts.map(\.id), ["phone", "fanpage", "website", "email"])
        XCTAssertTrue(state.contacts.allSatisfy { !$0.hasValue && $0.value == "temple.info.updating".localized })

        // Location
        XCTAssertEqual(state.addressLine, "128 Đường A, Phường B, Quận 1, TP. Hồ Chí Minh")
        XCTAssertEqual(state.regionLine, "temple.region.south".localized)
        XCTAssertEqual(state.coordinateText, "10.7769° B, 106.7009° Đ")
    }

    func test_viewDidLoad_withEmptyEditorialContent_leavesSectionsUnfilled() {
        mockUseCase.result = .success(Self.makeDetail(introduction: "", architectureHeritage: "", visitingNotes: []))
        let latest = loadSuccessfully()
        guard let state = latest() else { return XCTFail("expected state") }

        XCTAssertEqual(state.descriptionText, "")
        XCTAssertEqual(state.architectureText, "")
        XCTAssertEqual(state.visitRules, [])
    }

    func test_viewDidLoad_outsideOpeningHours_showsClosedAndReopenTime() {
        sut = makeSUT(now: Self.makeLocalDate(hour: 21))
        let latest = loadSuccessfully()

        XCTAssertEqual(latest()?.isOpen, false)
        XCTAssertEqual(latest()?.openStatusText, "temple.status.closed".localized)
        XCTAssertEqual(latest()?.openNoteText, String(format: "temple.status.opensAt".localized, "5:00"))
    }

    func test_viewDidLoad_withUnknownHoursAndYear_showsUpdatingFallbacks() {
        mockUseCase.result = .success(Self.makeDetail(operatingHours: "", establishedYear: 0))
        let latest = loadSuccessfully()
        guard let state = latest() else { return XCTFail("expected state") }

        XCTAssertFalse(state.isOpen)
        XCTAssertEqual(state.openStatusText, "temple.status.unknown".localized)
        XCTAssertEqual(state.openNoteText, "")
        XCTAssertEqual(state.hourRows.first?.value, "temple.info.updating".localized)
        XCTAssertEqual(state.hourRows.first?.isToday, false)
        XCTAssertEqual(state.facts.first?.value, "temple.info.updating".localized)
    }

    func test_viewDidLoad_failure_emitsFailure_thenRetryLoadsAgain() {
        mockUseCase.result = .failure(ILCatalogError.offline)
        var failed: Error?
        var succeeded = false
        let failureExpectation = expectation(description: "failure")
        let successExpectation = expectation(description: "success after retry")
        observeStates { state in
            switch state {
            case .failure(let error):
                failed = error
                failureExpectation.fulfill()
            case .success:
                succeeded = true
                successExpectation.fulfill()
            default:
                break
            }
        }

        viewDidLoadSubject.send(())
        wait(for: [failureExpectation], timeout: 1)
        if case ILCatalogError.offline = failed ?? ILCatalogError.notFound {} else {
            XCTFail("expected ILCatalogError.offline, got \(String(describing: failed))")
        }
        XCTAssertFalse(succeeded)

        mockUseCase.result = .success(Self.makeDetail())
        retryTappedSubject.send(())
        wait(for: [successExpectation], timeout: 1)
        XCTAssertEqual(mockUseCase.requestedIDs, ["temple_fixture", "temple_fixture"])
    }

    // MARK: - Interactions

    func test_followTapped_togglesLabelOptimisticallyAndCallsToggleFollow() {
        let latest = loadSuccessfully()
        let toggled = expectation(description: "toggleFollow called")
        mockUseCase.onToggleFollow = { toggled.fulfill() }
        XCTAssertEqual(latest()?.followButtonTitle, "temple.follow".localized)

        followTappedSubject.send(())

        XCTAssertEqual(latest()?.followButtonTitle, "temple.following".localized)
        wait(for: [toggled], timeout: 1)
        XCTAssertEqual(mockUseCase.toggledTempleIDs, ["temple_fixture"])
    }

    func test_followTapped_failure_revertsLabelAndEmitsErrorMessage() {
        var latest: ILTempleStateModel?
        let loaded = expectation(description: "loaded")
        loaded.assertForOverFulfill = false
        let output = observeStates { state in
            if case .success(let model) = state {
                latest = model
                loaded.fulfill()
            }
        }
        let errorReceived = expectation(description: "error message")
        var message: String?
        output.errorMessage
            .sink { message = $0; errorReceived.fulfill() }
            .store(in: &cancellables)
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 1)

        mockUseCase.toggleFollowError = ILCatalogError.offline
        followTappedSubject.send(())
        wait(for: [errorReceived], timeout: 1)

        XCTAssertEqual(message, ILCatalogError.offline.localizedDescription)
        XCTAssertEqual(latest?.followButtonTitle, "temple.follow".localized)
    }

    func test_bioToggled_expandsAndCollapsesBiography() {
        let latest = loadSuccessfully()
        XCTAssertEqual(latest()?.isBiographyExpanded, false)

        bioToggledSubject.send(())
        XCTAssertEqual(latest()?.isBiographyExpanded, true)
        XCTAssertEqual(latest()?.biographyToggleTitle, "temple.bio.collapse".localized)

        bioToggledSubject.send(())
        XCTAssertEqual(latest()?.isBiographyExpanded, false)
    }

    func test_eventsTapped_firesEventsNavigationEvent() {
        XCTAssertEqual(navigationEvent { self.eventsTappedSubject.send(()) }, .events)
    }

    func test_sessionTapped_firesSessionNavigationEventWithID() {
        XCTAssertEqual(navigationEvent { self.sessionTappedSubject.send("session-1") }, .session(id: "session-1"))
    }

    func test_contactTapped_withoutValue_firesNoEvent() {
        _ = loadSuccessfully()
        XCTAssertNil(navigationEvent(transform: false) { self.contactTappedSubject.send("phone") })
    }

    func test_backTapped_firesBackNavigationEvent() {
        XCTAssertEqual(navigationEvent { self.backTappedSubject.send(()) }, .back)
    }

    func test_offerTapped_firesOfferNavigationEvent() {
        XCTAssertEqual(navigationEvent { self.offerTappedSubject.send(()) }, .offer)
    }

    func test_googleMapsTapped_afterLoad_firesOpenURLWithGoogleMapsLink() {
        _ = loadSuccessfully()
        XCTAssertEqual(
            navigationEvent(transform: false) { self.googleMapsTappedSubject.send(()) },
            .openURL("https://www.google.com/maps/dir/?api=1&destination=10.7769,106.7009")
        )
    }

    func test_appleMapsTapped_afterLoad_firesOpenURLWithAppleMapsLink() {
        _ = loadSuccessfully()
        XCTAssertEqual(
            navigationEvent(transform: false) { self.appleMapsTappedSubject.send(()) },
            .openURL("https://maps.apple.com/?daddr=10.7769,106.7009")
        )
    }

    func test_googleMapsTapped_beforeLoad_firesNoEvent() {
        XCTAssertNil(navigationEvent { self.googleMapsTappedSubject.send(()) })
    }

    // MARK: - Opening hours parsing

    func test_parseOperatingHours() {
        XCTAssertEqual(ILTempleViewModel.parseOperatingHours("06:00 - 18:00").map { [$0.open, $0.close] }, [360, 1080])
        XCTAssertEqual(ILTempleViewModel.parseOperatingHours("5:30–20:30").map { [$0.open, $0.close] }, [330, 1230])
        XCTAssertNil(ILTempleViewModel.parseOperatingHours(""))
        XCTAssertNil(ILTempleViewModel.parseOperatingHours("Cả ngày"))
        XCTAssertNil(ILTempleViewModel.parseOperatingHours("06:75 - 18:00"))
    }

    // MARK: - Helpers

    /// Runs `action` and returns the navigation event it fired, if any.
    private func navigationEvent(transform: Bool = true, _ action: () -> Void) -> ILTempleNavEvent? {
        if transform { _ = sut.transform(input: makeInput()) }
        var received: ILTempleNavEvent?
        sut.navigationEventPublisher
            .sink { received = $0 }
            .store(in: &cancellables)
        action()
        return received
    }

    static func makeDetail(
        operatingHours: String = "05:00 - 20:00",
        establishedYear: Int = 1900,
        introduction: String = "Giới thiệu mẫu.",
        architectureHeritage: String = "Kiến trúc mẫu.",
        visitingNotes: [String] = ["Lưu ý một.", "Lưu ý hai."]
    ) -> ILTempleDetailEntity {
        ILTempleDetailEntity(
            summary: ILTempleSummaryEntity(
                id: "temple_fixture",
                name: "Chùa Mẫu",
                type: .chua,
                region: .south,
                thumbnailURL: nil,
                imageURL: nil,
                sect: "BẮC_TÔNG",
                heritageRank: .nationalRelic,
                establishedYear: establishedYear,
                location: ILTempleLocationEntity(
                    latitude: 10.7769,
                    longitude: 106.7009,
                    address: "128 Đường A, Phường B, Quận 1, TP. Hồ Chí Minh"
                )
            ),
            aliases: ["Chùa Cổ", "Cổ Tự"],
            founder: "",
            currentAbbot: "Đại đức A",
            operatingHours: operatingHours,
            facilities: ILTempleFacilitiesEntity(
                hasCarParking: true,
                hasMotorbikeParking: false,
                servesVegetarianMeals: true,
                hasSummerRetreat: false
            ),
            introduction: introduction,
            architectureHeritage: architectureHeritage,
            visitingNotes: visitingNotes
        )
    }
}

// MARK: - ILTempleCatalogLabels

final class ILTempleCatalogLabelsTests: XCTestCase {

    func test_sectLabel_matchesKnownValuesIgnoringDiacritics() {
        XCTAssertEqual(ILTempleCatalogLabels.sectLabel("BẮC_TÔNG"), "temple.sect.bacTong".localized)
        XCTAssertEqual(ILTempleCatalogLabels.sectLabel("BAC_TONG"), "temple.sect.bacTong".localized)
        XCTAssertEqual(ILTempleCatalogLabels.sectLabel("NAM_TONG_KHMER"), "temple.sect.namTongKhmer".localized)
        XCTAssertEqual(ILTempleCatalogLabels.sectLabel("TIN_NGUONG_DANG_GIAN"), "temple.sect.folk".localized)
    }

    func test_sectLabel_unknownValue_isHumanized() {
        XCTAssertEqual(ILTempleCatalogLabels.sectLabel("TỊNH_ĐỘ_TÔNG"), "Tịnh độ tông")
    }
}

// MARK: - Mock ILTempleUseCase
final class MockILTempleUseCase: ILTempleUseCase {
    var result: Result<ILTempleDetailEntity, Error> = .success(ILTempleViewModelTests.makeDetail())
    var requestedIDs: [String] = []
    var toggleFollowError: Error?
    var toggledTempleIDs: [String] = []
    var onToggleFollow: (() -> Void)?

    func loadTemple(id: String) async throws -> ILTempleDetailEntity {
        requestedIDs.append(id)
        return try result.get()
    }

    func toggleFollow(templeID: String) async throws {
        toggledTempleIDs.append(templeID)
        onToggleFollow?()
        if let toggleFollowError { throw toggleFollowError }
    }
}
