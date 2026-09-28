//
//  ILPlayerViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILPlayerViewModelTests: XCTestCase {

    private var mockUseCase: MockILPlayerUseCase!
    private var sut: ILPlayerViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var tableOfContentsTappedSubject: PassthroughSubject<Void, Never>!
    private var playPauseTappedSubject: PassthroughSubject<Void, Never>!
    private var rewindTappedSubject: PassthroughSubject<Void, Never>!
    private var forwardTappedSubject: PassthroughSubject<Void, Never>!
    private var speedSelectedSubject: PassthroughSubject<Int, Never>!
    private var sleepSelectedSubject: PassthroughSubject<Int, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILPlayerUseCase()
        sut = ILPlayerViewModel(useCase: mockUseCase, sutraID: "sutra.phapcu")
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        tableOfContentsTappedSubject = PassthroughSubject<Void, Never>()
        playPauseTappedSubject = PassthroughSubject<Void, Never>()
        rewindTappedSubject = PassthroughSubject<Void, Never>()
        forwardTappedSubject = PassthroughSubject<Void, Never>()
        speedSelectedSubject = PassthroughSubject<Int, Never>()
        sleepSelectedSubject = PassthroughSubject<Int, Never>()
    }

    override func tearDown() {
        cancellables = nil
        sleepSelectedSubject = nil
        speedSelectedSubject = nil
        forwardTappedSubject = nil
        rewindTappedSubject = nil
        playPauseTappedSubject = nil
        tableOfContentsTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILPlayerViewModel.Input {
        ILPlayerViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            tableOfContentsTapped: tableOfContentsTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            rewindTapped: rewindTappedSubject.eraseToAnyPublisher(),
            forwardTapped: forwardTappedSubject.eraseToAnyPublisher(),
            speedSelected: speedSelectedSubject.eraseToAnyPublisher(),
            sleepSelected: sleepSelectedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILPlayerStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILPlayerStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_showsTrackAndDefaultControls() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.headerTitle, "player.header.title".localized)
        XCTAssertEqual(state?.tableOfContentsActionTitle, "player.header.tableOfContents".localized)
        XCTAssertEqual(state?.trackTitle, "Phẩm Song Yếu")
        XCTAssertEqual(state?.trackSubtitle, "Kinh Pháp Cú · Thầy Minh Đạo")
        XCTAssertEqual(state?.elapsedText, String(format: "player.time.elapsed".localized, 14, 22))
        XCTAssertEqual(state?.remainingText, String(format: "player.time.remaining".localized, 23, 18))
        XCTAssertEqual(state?.playbackProgress ?? -1, 862.0 / 2260.0, accuracy: 0.0001)
        XCTAssertEqual(state?.isPlaying, false)
        XCTAssertEqual(state?.rewindTitle, "player.seek.rewind".localized)
        XCTAssertEqual(state?.forwardTitle, "player.seek.forward".localized)
        XCTAssertEqual(state?.speedSectionTitle, "player.speed.title".localized)
        XCTAssertEqual(state?.speedOptions, ["0.75×", "1.0×", "1.25×", "1.5×"])
        XCTAssertEqual(state?.selectedSpeedIndex, 1)
        XCTAssertEqual(state?.sleepSectionTitle, "player.sleep.title".localized)
        XCTAssertEqual(state?.sleepOptions, ["Tắt", "15p", "30p", "Hết bài"])
        XCTAssertEqual(state?.selectedSleepIndex, 1)
        XCTAssertEqual(state?.sleepNote, String(format: "player.sleep.note.minutesFormat".localized, 15))
    }

    func test_playPauseTapped_togglesPlaying() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        playPauseTappedSubject.send(())

        XCTAssertTrue(mockUseCase.togglePlayPauseCalled)
        XCTAssertEqual(latest()?.isPlaying, true)

        playPauseTappedSubject.send(())

        XCTAssertEqual(latest()?.isPlaying, false)
    }

    func test_rewindTapped_callsRewind() {
        _ = observeLatestState()
        viewDidLoadSubject.send(())

        rewindTappedSubject.send(())

        XCTAssertTrue(mockUseCase.rewindCalled)
    }

    func test_forwardTapped_callsForward() {
        _ = observeLatestState()
        viewDidLoadSubject.send(())

        forwardTappedSubject.send(())

        XCTAssertTrue(mockUseCase.forwardCalled)
    }

    func test_speedSelected_updatesSelection() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        speedSelectedSubject.send(3)

        XCTAssertTrue(mockUseCase.selectSpeedCalled)
        XCTAssertEqual(mockUseCase.selectedSpeedIndexCaptured, 3)
        XCTAssertEqual(latest()?.selectedSpeedIndex, 3)
    }

    func test_sleepSelected_updatesSelectionAndNote() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        sleepSelectedSubject.send(3)

        XCTAssertTrue(mockUseCase.selectSleepTimerCalled)
        XCTAssertEqual(mockUseCase.selectedSleepIndexCaptured, 3)
        XCTAssertEqual(latest()?.selectedSleepIndex, 3)
        XCTAssertEqual(latest()?.sleepNote, "player.sleep.note.endOfTrack".localized)

        sleepSelectedSubject.send(0)

        XCTAssertEqual(latest()?.selectedSleepIndex, 0)
        XCTAssertEqual(latest()?.sleepNote, "player.sleep.note.off".localized)
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILPlayerNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_tableOfContentsTapped_firesOpenTableOfContentsNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILPlayerNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        tableOfContentsTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openTableOfContents)
    }
}

// MARK: - Mock ILPlayerUseCase
/// Fixed catalog with one track (total 2260s) — enough to verify display values and the selection/
/// seek/play actions without touching audio or persistence.
final class MockILPlayerUseCase: ILPlayerUseCase {
    var getInitialStateCalled = false
    var togglePlayPauseCalled = false
    var rewindCalled = false
    var forwardCalled = false
    var selectSpeedCalled = false
    var selectSleepTimerCalled = false
    var selectedSpeedIndexCaptured: Int?
    var selectedSleepIndexCaptured: Int?

    private static let track = ILPlayerTrackEntity(
        id: "sutra.phapcu",
        title: "Phẩm Song Yếu",
        subtitle: "Kinh Pháp Cú · Thầy Minh Đạo",
        totalDurationSeconds: 2260
    )

    func getInitialState(sutraID: String) -> ILPlayerEntity {
        getInitialStateCalled = true
        return ILPlayerEntity(
            tracks: [Self.track],
            currentTrackID: sutraID,
            elapsedSeconds: 862,
            playbackSpeedIndex: 1,
            sleepTimerIndex: 1,
            isPlaying: false
        )
    }

    func currentTrack(in entity: ILPlayerEntity) -> ILPlayerTrackEntity? {
        entity.tracks.first { $0.id == entity.currentTrackID }
    }

    func togglePlayPause(_ entity: ILPlayerEntity) -> ILPlayerEntity {
        togglePlayPauseCalled = true
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    func rewind(_ entity: ILPlayerEntity) -> ILPlayerEntity {
        rewindCalled = true
        var updated = entity
        updated.elapsedSeconds = max(0, entity.elapsedSeconds - 15)
        return updated
    }

    func forward(_ entity: ILPlayerEntity) -> ILPlayerEntity {
        forwardCalled = true
        var updated = entity
        updated.elapsedSeconds = entity.elapsedSeconds + 30
        return updated
    }

    func selectSpeed(_ entity: ILPlayerEntity, index: Int) -> ILPlayerEntity {
        selectSpeedCalled = true
        selectedSpeedIndexCaptured = index
        var updated = entity
        updated.playbackSpeedIndex = index
        return updated
    }

    func selectSleepTimer(_ entity: ILPlayerEntity, index: Int) -> ILPlayerEntity {
        selectSleepTimerCalled = true
        selectedSleepIndexCaptured = index
        var updated = entity
        updated.sleepTimerIndex = index
        return updated
    }
}
