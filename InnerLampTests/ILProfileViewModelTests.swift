//
//  ILProfileViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILProfileViewModelTests: XCTestCase {

    private var mockUseCase: MockILProfileUseCase!
    private var sut: ILProfileViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var editProfileTappedSubject: PassthroughSubject<Void, Never>!
    private var statsTappedSubject: PassthroughSubject<Void, Never>!
    private var awardsTappedSubject: PassthroughSubject<Void, Never>!
    private var offeringTappedSubject: PassthroughSubject<Void, Never>!
    private var premiumTappedSubject: PassthroughSubject<Void, Never>!
    private var reminderTappedSubject: PassthroughSubject<Void, Never>!
    private var settingsTappedSubject: PassthroughSubject<Void, Never>!
    private var notificationsTappedSubject: PassthroughSubject<Void, Never>!
    private var familyTreeTappedSubject: PassthroughSubject<Void, Never>!
    private var communityTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILProfileUseCase()
        sut = ILProfileViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        editProfileTappedSubject = PassthroughSubject<Void, Never>()
        statsTappedSubject = PassthroughSubject<Void, Never>()
        awardsTappedSubject = PassthroughSubject<Void, Never>()
        offeringTappedSubject = PassthroughSubject<Void, Never>()
        premiumTappedSubject = PassthroughSubject<Void, Never>()
        reminderTappedSubject = PassthroughSubject<Void, Never>()
        settingsTappedSubject = PassthroughSubject<Void, Never>()
        notificationsTappedSubject = PassthroughSubject<Void, Never>()
        familyTreeTappedSubject = PassthroughSubject<Void, Never>()
        communityTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        editProfileTappedSubject = nil
        statsTappedSubject = nil
        awardsTappedSubject = nil
        offeringTappedSubject = nil
        premiumTappedSubject = nil
        reminderTappedSubject = nil
        settingsTappedSubject = nil
        notificationsTappedSubject = nil
        familyTreeTappedSubject = nil
        communityTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILProfileViewModel.Input {
        ILProfileViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            editProfileTapped: editProfileTappedSubject.eraseToAnyPublisher(),
            statsTapped: statsTappedSubject.eraseToAnyPublisher(),
            awardsTapped: awardsTappedSubject.eraseToAnyPublisher(),
            offeringTapped: offeringTappedSubject.eraseToAnyPublisher(),
            premiumTapped: premiumTappedSubject.eraseToAnyPublisher(),
            reminderTapped: reminderTappedSubject.eraseToAnyPublisher(),
            settingsTapped: settingsTappedSubject.eraseToAnyPublisher(),
            notificationsTapped: notificationsTappedSubject.eraseToAnyPublisher(),
            familyTreeTapped: familyTreeTappedSubject.eraseToAnyPublisher(),
            communityTapped: communityTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILProfileViewModel.Output) -> () -> ILProfileStateModel? {
        var latest: ILProfileStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILProfileNavEvent] {
        var events: [ILProfileNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_reloadsProfileAndMapsEntityToStateModel() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getProfileCallCount, 2) // init + viewDidLoad
        let state = latest()
        XCTAssertEqual(state?.header.fullName, "Nguyễn Bình An")
        XCTAssertEqual(state?.header.initial, "A")
        XCTAssertEqual(state?.header.subtitle, String(format: "profile.header.subtitle".localized, "Tâm Minh"))
        XCTAssertEqual(state?.header.subtitleHighlight, "Tâm Minh")
        XCTAssertEqual(state?.stats.map(\.value), ["168", "42", "9.7k"])
        XCTAssertEqual(state?.stats.map(\.caption), [
            "profile.stats.hours".localized,
            "profile.stats.streak".localized,
            "profile.stats.chants".localized
        ])
        XCTAssertEqual(state?.heatmap?.summaryText, String(format: "profile.heatmap.summary".localized, 3, 4))
        XCTAssertEqual(state?.heatmap?.intensities.count, 4)
        XCTAssertEqual(state?.badgesLinkText, String(format: "profile.badges.seeAll".localized, 18))
        XCTAssertEqual(state?.badges.map(\.id), ["b1"])
        XCTAssertEqual(state?.badges.first?.category, .mala)
        XCTAssertEqual(state?.meritSummary, String(format: "profile.merit.summary".localized, 7, 3))
        XCTAssertEqual(state?.showsPremiumUpsell, true)
        XCTAssertEqual(state?.reminderValue, "05:30 · " + String(format: "profile.menu.reminder.daysPerWeek".localized, 6))
        XCTAssertEqual(state?.communityValue, "Từ Quang")
    }

    func test_viewDidLoad_withEmptyProfile_hidesOptionalSectionsAndShowsFallbacks() {
        mockUseCase.profile = .empty
        sut = ILProfileViewModel(useCase: mockUseCase)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.heatmap)
        XCTAssertEqual(latest()?.hasBadges, false)
        XCTAssertEqual(latest()?.header.subtitle, "profile.header.role".localized)
        XCTAssertNil(latest()?.header.subtitleHighlight)
        XCTAssertEqual(latest()?.reminderValue, "profile.menu.reminder.none".localized)
        XCTAssertEqual(latest()?.communityValue, "profile.menu.community.none".localized)
    }

    func test_viewDidLoad_withPaidPlan_hidesPremiumUpsell() {
        mockUseCase.profile.plan = .yearly
        sut = ILProfileViewModel(useCase: mockUseCase)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.showsPremiumUpsell, false)
    }

    // MARK: - Navigation
    func test_editProfileTapped_firesEditProfileEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        editProfileTappedSubject.send(())

        XCTAssertEqual(events(), [.editProfile])
    }

    func test_statsTapped_firesOpenStatsEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        statsTappedSubject.send(())

        XCTAssertEqual(events(), [.openStats])
    }

    func test_awardsTapped_firesOpenAwardsEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        awardsTappedSubject.send(())

        XCTAssertEqual(events(), [.openAwards])
    }

    func test_offeringTapped_firesOpenOfferingEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        offeringTappedSubject.send(())

        XCTAssertEqual(events(), [.openOffering])
    }

    func test_premiumTapped_firesOpenPaywallEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        premiumTappedSubject.send(())

        XCTAssertEqual(events(), [.openPaywall])
    }

    func test_reminderTapped_firesOpenReminderEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        reminderTappedSubject.send(())

        XCTAssertEqual(events(), [.openReminder])
    }

    func test_settingsTapped_firesOpenSettingsEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        settingsTappedSubject.send(())

        XCTAssertEqual(events(), [.openSettings])
    }

    func test_notificationsTapped_firesOpenNotificationsEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        notificationsTappedSubject.send(())

        XCTAssertEqual(events(), [.openNotifications])
    }

    func test_familyTreeTapped_firesOpenFamilyTreeEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        familyTreeTappedSubject.send(())

        XCTAssertEqual(events(), [.openFamilyTree])
    }

    func test_communityTapped_firesOpenCommunityEventWithId() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        communityTappedSubject.send(())

        XCTAssertEqual(events(), [.openCommunity(id: "c1")])
    }

    func test_communityTapped_withoutCommunity_firesNothing() {
        mockUseCase.profile.community = nil
        sut = ILProfileViewModel(useCase: mockUseCase)
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        communityTappedSubject.send(())

        XCTAssertTrue(events().isEmpty)
    }

    // MARK: - Formatting
    func test_formatCompactCount_abbreviatesThousands() {
        XCTAssertEqual(ILProfileViewModel.formatCompactCount(0), "0")
        XCTAssertEqual(ILProfileViewModel.formatCompactCount(999), "999")
        XCTAssertEqual(ILProfileViewModel.formatCompactCount(1_000), "1k")
        XCTAssertEqual(ILProfileViewModel.formatCompactCount(9_700), "9.7k")
        XCTAssertEqual(ILProfileViewModel.formatCompactCount(12_345), "12.3k")
    }

    func test_formatReminder_handlesEveryDayAndMissing() {
        XCTAssertEqual(
            ILProfileViewModel.formatReminder(ILProfileReminderEntity(hour: 6, minute: 5, activeDayCount: 7)),
            "06:05 · " + "profile.menu.reminder.everyDay".localized
        )
        XCTAssertEqual(ILProfileViewModel.formatReminder(nil), "profile.menu.reminder.none".localized)
    }

    func test_makeIntensities_scalesBetweenMinAndMaxAlpha() {
        let intensities = ILProfileViewModel.makeIntensities(from: [0, 5, 10])

        XCTAssertEqual(intensities[0], 0.12, accuracy: 0.0001)
        XCTAssertEqual(intensities[1], 0.52, accuracy: 0.0001)
        XCTAssertEqual(intensities[2], 0.92, accuracy: 0.0001)
    }

    func test_makeIntensities_allZeroStaysAtMinAlpha() {
        XCTAssertEqual(ILProfileViewModel.makeIntensities(from: [0, 0]), [0.12, 0.12])
        XCTAssertTrue(ILProfileViewModel.makeIntensities(from: []).isEmpty)
    }

    func test_initial_usesLastWordFirstLetterUppercased() {
        XCTAssertEqual(ILProfileViewModel.initial(of: "Nguyễn Bình An"), "A")
        XCTAssertEqual(ILProfileViewModel.initial(of: "an"), "A")
        XCTAssertEqual(ILProfileViewModel.initial(of: ""), "")
    }
}

// MARK: - Mock ILProfileUseCase
final class MockILProfileUseCase: ILProfileUseCase {
    var profile: ILProfileEntity
    private(set) var getProfileCallCount = 0

    init() {
        profile = ILProfileEntity(
            fullName: "Nguyễn Bình An",
            dharmaName: "Tâm Minh",
            practiceStats: ILProfilePracticeStatsEntity(totalHours: 168, streakDays: 42, chantCount: 9_700),
            journalEntriesPerDay: [0, 3, 6, 9],
            recentBadges: [
                ILProfileBadgeEntity(id: "b1", title: "Badge", subtitle: "Sub", category: .mala)
            ],
            totalBadgeCount: 18,
            offeringCount: 7,
            lanternCount: 3,
            plan: .free,
            reminder: ILProfileReminderEntity(hour: 5, minute: 30, activeDayCount: 6),
            community: ILProfileCommunityEntity(id: "c1", name: "Từ Quang")
        )
    }

    func getProfile() -> ILProfileEntity {
        getProfileCallCount += 1
        return profile
    }
}
