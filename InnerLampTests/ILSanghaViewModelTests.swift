//
//  ILSanghaViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSanghaViewModelTests: XCTestCase {

    private let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)

    private var mockUseCase: MockILSanghaUseCase!
    private var sut: ILSanghaViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var findSanghaTappedSubject: PassthroughSubject<Void, Never>!
    private var sitTogetherTappedSubject: PassthroughSubject<Void, Never>!
    private var composeTappedSubject: PassthroughSubject<Void, Never>!
    private var eventsTappedSubject: PassthroughSubject<Void, Never>!
    private var communityTappedSubject: PassthroughSubject<Void, Never>!
    private var postTappedSubject: PassthroughSubject<String, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILSanghaUseCase(now: fixedNow)
        sut = ILSanghaViewModel(useCase: mockUseCase, now: { [fixedNow] in fixedNow })
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        findSanghaTappedSubject = PassthroughSubject<Void, Never>()
        sitTogetherTappedSubject = PassthroughSubject<Void, Never>()
        composeTappedSubject = PassthroughSubject<Void, Never>()
        eventsTappedSubject = PassthroughSubject<Void, Never>()
        communityTappedSubject = PassthroughSubject<Void, Never>()
        postTappedSubject = PassthroughSubject<String, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        findSanghaTappedSubject = nil
        sitTogetherTappedSubject = nil
        composeTappedSubject = nil
        eventsTappedSubject = nil
        communityTappedSubject = nil
        postTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILSanghaViewModel.Input {
        ILSanghaViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            findSanghaTapped: findSanghaTappedSubject.eraseToAnyPublisher(),
            sitTogetherTapped: sitTogetherTappedSubject.eraseToAnyPublisher(),
            composeTapped: composeTappedSubject.eraseToAnyPublisher(),
            eventsTapped: eventsTappedSubject.eraseToAnyPublisher(),
            communityTapped: communityTappedSubject.eraseToAnyPublisher(),
            postTapped: postTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILSanghaViewModel.Output) -> () -> ILSanghaStateModel? {
        var latest: ILSanghaStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILSanghaNavEvent] {
        var events: [ILSanghaNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_reloadsSanghaAndMapsEntityToStateModel() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getSanghaCallCount, 2) // init + viewDidLoad
        let state = latest()
        XCTAssertEqual(state?.liveSession?.countText, "312")
        XCTAssertEqual(state?.liveSession?.captionText, String(format: "sangha.live.caption".localized, 20))
        XCTAssertEqual(state?.community?.id, "community")
        XCTAssertEqual(
            state?.community?.metaText,
            String(format: "sangha.community.meta".localized, 184, "Q. Bình Thạnh")
        )
        XCTAssertEqual(state?.posts.map(\.id), ["p1"])
        XCTAssertEqual(state?.posts.first?.authorInitials, "H")
        XCTAssertEqual(
            state?.posts.first?.metaText,
            String(format: "sangha.post.meta".localized, String(format: "sangha.time.hoursAgo".localized, 2), 41)
        )
        XCTAssertEqual(state?.posts.first?.likeText, String(format: "sangha.post.like".localized, 24))
        XCTAssertEqual(state?.posts.first?.replyText, String(format: "sangha.post.reply".localized, 6))
    }

    func test_viewDidLoad_withEmptySangha_hidesEverything() {
        mockUseCase.sangha = .empty
        sut = ILSanghaViewModel(useCase: mockUseCase, now: { [fixedNow] in fixedNow })
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertNil(latest()?.liveSession)
        XCTAssertNil(latest()?.community)
        XCTAssertEqual(latest()?.hasPosts, false)
    }

    // MARK: - Navigation
    func test_findSanghaTapped_firesOpenFindSanghaEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        findSanghaTappedSubject.send(())

        XCTAssertEqual(events(), [.openFindSangha])
    }

    func test_sitTogetherTapped_firesStartSittingEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        sitTogetherTappedSubject.send(())

        XCTAssertEqual(events(), [.startSitting])
    }

    func test_composeTapped_firesOpenComposeEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        composeTappedSubject.send(())

        XCTAssertEqual(events(), [.openCompose])
    }

    func test_eventsTapped_firesOpenEventsEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        eventsTappedSubject.send(())

        XCTAssertEqual(events(), [.openEvents])
    }

    func test_communityTapped_firesOpenCommunityEventWithId() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        communityTappedSubject.send(())

        XCTAssertEqual(events(), [.openCommunity(id: "community")])
    }

    func test_communityTapped_withoutCommunity_firesNothing() {
        mockUseCase.sangha.community = nil
        sut = ILSanghaViewModel(useCase: mockUseCase, now: { [fixedNow] in fixedNow })
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        communityTappedSubject.send(())

        XCTAssertTrue(events().isEmpty)
    }

    func test_postTapped_firesOpenPostEventWithId() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        postTappedSubject.send("p1")

        XCTAssertEqual(events(), [.openPost(id: "p1")])
    }

    func test_postTapped_unknownId_firesNothing() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        postTappedSubject.send("does-not-exist")

        XCTAssertTrue(events().isEmpty)
    }

    // MARK: - Formatting
    func test_formatCount_groupsThousandsVietnameseStyle() {
        XCTAssertEqual(ILSanghaViewModel.formatCount(312), "312")
        XCTAssertEqual(ILSanghaViewModel.formatCount(1248), "1.248")
    }

    func test_formatRelativeTime_picksUnitByAge() {
        let now = fixedNow
        XCTAssertEqual(
            ILSanghaViewModel.formatRelativeTime(from: now.addingTimeInterval(-10), now: now),
            String(format: "sangha.time.minutesAgo".localized, 1)
        )
        XCTAssertEqual(
            ILSanghaViewModel.formatRelativeTime(from: now.addingTimeInterval(-45 * 60), now: now),
            String(format: "sangha.time.minutesAgo".localized, 45)
        )
        XCTAssertEqual(
            ILSanghaViewModel.formatRelativeTime(from: now.addingTimeInterval(-3 * 3600), now: now),
            String(format: "sangha.time.hoursAgo".localized, 3)
        )
        XCTAssertEqual(
            ILSanghaViewModel.formatRelativeTime(from: now.addingTimeInterval(-50 * 3600), now: now),
            String(format: "sangha.time.daysAgo".localized, 2)
        )
    }

    func test_initial_usesLastWordFirstLetterUppercased() {
        XCTAssertEqual(ILSanghaViewModel.initial(of: "Diệu Hạnh"), "H")
        XCTAssertEqual(ILSanghaViewModel.initial(of: "an"), "A")
        XCTAssertEqual(ILSanghaViewModel.initial(of: ""), "")
    }
}

// MARK: - Mock ILSanghaUseCase
final class MockILSanghaUseCase: ILSanghaUseCase {
    var sangha: ILSanghaEntity
    private(set) var getSanghaCallCount = 0

    init(now: Date) {
        sangha = ILSanghaEntity(
            liveSession: ILSanghaLiveSessionEntity(participantCount: 312, sessionMinutes: 20),
            community: ILSanghaCommunityEntity(
                id: "community",
                name: "Community",
                memberCount: 184,
                district: "Q. Bình Thạnh",
                announcement: "announcement"
            ),
            posts: [
                ILSanghaPostEntity(
                    id: "p1",
                    authorName: "Diệu Hạnh",
                    postedAt: now.addingTimeInterval(-2 * 3600),
                    authorStreakDays: 41,
                    body: "body",
                    likeCount: 24,
                    replyCount: 6
                )
            ]
        )
    }

    func getSangha() -> ILSanghaEntity {
        getSanghaCallCount += 1
        return sangha
    }
}
