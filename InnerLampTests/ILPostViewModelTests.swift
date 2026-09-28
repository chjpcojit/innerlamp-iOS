//
//  ILPostViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILPostViewModelTests: XCTestCase {

    private let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)

    private var mockUseCase: MockILPostUseCase!
    private var sut: ILPostViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var likeTappedSubject: PassthroughSubject<Void, Never>!
    private var shareTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILPostUseCase(now: fixedNow)
        sut = ILPostViewModel(useCase: mockUseCase, postID: "post-1", now: { [fixedNow] in fixedNow })
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        likeTappedSubject = PassthroughSubject<Void, Never>()
        shareTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        shareTappedSubject = nil
        likeTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILPostViewModel.Input {
        ILPostViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            likeTapped: likeTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState() -> () -> ILPostStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILPostStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILPostNavEvent] {
        var events: [ILPostNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_mapsEntityToStateModel() {
        let latest = captureLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.communityName, "Đạo tràng Từ Quang")
        XCTAssertEqual(
            state?.memberCountText,
            String(format: "post.header.members".localized, ILPostViewModel.formatCount(1248))
        )
        XCTAssertEqual(state?.authorName, "Sư cô Tâm Nguyện")
        XCTAssertEqual(state?.authorInitials, "TN")
        XCTAssertEqual(
            state?.metaText,
            "\(String(format: "post.time.hoursAgo".localized, 2)) · Chia sẻ pháp"
        )
        XCTAssertEqual(state?.likeCountText, "318")
        XCTAssertEqual(state?.commentCountText, "24")
        XCTAssertEqual(
            state?.commentsHeaderText,
            String(format: "post.comments.header".localized, "24")
        )
        XCTAssertEqual(state?.isLiked, false)
    }

    func test_viewDidLoad_mapsCommentsWithDepthAndFormattedLabels() {
        let latest = captureLatestState()

        viewDidLoadSubject.send(())

        let comments = latest()?.comments
        XCTAssertEqual(comments?.map(\.id), ["c1", "c2"])
        XCTAssertEqual(comments?.first?.depth, 0)
        XCTAssertEqual(comments?.first?.timeText, String(format: "post.time.hoursAgo".localized, 1))
        XCTAssertEqual(comments?.last?.depth, 1)
        XCTAssertEqual(
            comments?.last?.likeText,
            String(format: "post.comments.action.like".localized, "9")
        )
    }

    // MARK: - Like
    func test_likeTapped_togglesLikedAndIncrementsCount() {
        let latest = captureLatestState()
        viewDidLoadSubject.send(())

        likeTappedSubject.send(())

        XCTAssertEqual(mockUseCase.toggleLikeCallCount, 1)
        XCTAssertEqual(latest()?.isLiked, true)
        XCTAssertEqual(latest()?.likeCountText, "319")

        likeTappedSubject.send(())

        XCTAssertEqual(mockUseCase.toggleLikeCallCount, 2)
        XCTAssertEqual(latest()?.isLiked, false)
        XCTAssertEqual(latest()?.likeCountText, "318")
    }

    // MARK: - Navigation
    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        backTappedSubject.send(())

        XCTAssertEqual(events(), [.back])
    }

    func test_shareTapped_firesShareNavigationEvent() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        shareTappedSubject.send(())

        XCTAssertEqual(events(), [.share])
    }

    // MARK: - Formatting
    func test_formatCount_groupsThousandsVietnameseStyle() {
        XCTAssertEqual(ILPostViewModel.formatCount(318), "318")
        XCTAssertEqual(ILPostViewModel.formatCount(1248), "1.248")
    }

    func test_formatRelativeTime_picksUnitByAge() {
        let now = fixedNow
        XCTAssertEqual(
            ILPostViewModel.formatRelativeTime(from: now.addingTimeInterval(-10), now: now),
            String(format: "post.time.minutesAgo".localized, 1)
        )
        XCTAssertEqual(
            ILPostViewModel.formatRelativeTime(from: now.addingTimeInterval(-45 * 60), now: now),
            String(format: "post.time.minutesAgo".localized, 45)
        )
        XCTAssertEqual(
            ILPostViewModel.formatRelativeTime(from: now.addingTimeInterval(-3 * 3600), now: now),
            String(format: "post.time.hoursAgo".localized, 3)
        )
        XCTAssertEqual(
            ILPostViewModel.formatRelativeTime(from: now.addingTimeInterval(-50 * 3600), now: now),
            String(format: "post.time.daysAgo".localized, 2)
        )
    }

    func test_tone_isDeterministicForSameName() {
        XCTAssertEqual(ILPostViewModel.tone(for: "Diệu Hạnh"), ILPostViewModel.tone(for: "Diệu Hạnh"))
    }
}

// MARK: - Mock ILPostUseCase
final class MockILPostUseCase: ILPostUseCase {
    var getInitialStateCalled = false
    private(set) var toggleLikeCallCount = 0
    private let entity: ILPostEntity

    init(now: Date) {
        entity = ILPostEntity(
            post: ILPostItemEntity(
                id: "post-1",
                authorName: "Sư cô Tâm Nguyện",
                authorInitials: "TN",
                postedAt: now.addingTimeInterval(-2 * 3600),
                tag: "Chia sẻ pháp",
                body: "body text",
                likeCount: 318,
                commentCount: 24,
                communityName: "Đạo tràng Từ Quang",
                communityMemberCount: 1248
            ),
            comments: [
                ILPostCommentEntity(
                    id: "c1",
                    authorName: "Huệ Lâm",
                    authorInitials: "HL",
                    postedAt: now.addingTimeInterval(-3600),
                    text: "comment 1",
                    likeCount: 12,
                    parentID: nil
                ),
                ILPostCommentEntity(
                    id: "c2",
                    authorName: "Sư cô Tâm Nguyện",
                    authorInitials: "TN",
                    postedAt: now.addingTimeInterval(-30 * 60),
                    text: "comment 2 reply",
                    likeCount: 9,
                    parentID: "c1"
                )
            ],
            isLiked: false
        )
    }

    func getInitialState(postID: String) -> ILPostEntity {
        getInitialStateCalled = true
        return entity
    }

    func toggleLike(in entity: ILPostEntity) -> ILPostEntity {
        toggleLikeCallCount += 1
        var updated = entity
        updated.isLiked.toggle()
        return updated
    }
}
