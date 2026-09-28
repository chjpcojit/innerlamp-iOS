//
//  ILTalkViewModelTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 27/9/26.
//

import XCTest
import Combine
@testable import InnerLamp

final class ILTalkViewModelTests: XCTestCase {

    private var mockUseCase: MockILTalkUseCase!
    private var sut: ILTalkViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILTalkUseCase()
        sut = ILTalkViewModel(useCase: mockUseCase, talkID: "talk.vulan.hieu")
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    func test_initialState_matchesUseCaseDefault() {
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: makeInput(viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher()))

        var receivedState: ILTalkStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())

        XCTAssertNotNil(receivedState)
        XCTAssertEqual(receivedState?.headerTitle, "talk.header.title".localized)
        XCTAssertEqual(receivedState?.eyebrow, "talk.mock.eyebrow".localized)
        XCTAssertEqual(receivedState?.elapsedText, "12:48")
        XCTAssertEqual(receivedState?.remainingText, "-33:12")
        XCTAssertEqual(receivedState?.chapters.count, 1)
    }

    func test_backTapped_firesBackEvent() {
        var receivedEvent: ILTalkNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        let backTappedSubject = PassthroughSubject<Void, Never>()
        _ = sut.transform(input: makeInput(backTapped: backTappedSubject.eraseToAnyPublisher()))

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_playPauseTapped_togglesIsPlaying() {
        let playPauseSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: makeInput(playPauseTapped: playPauseSubject.eraseToAnyPublisher()))

        var receivedState: ILTalkStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        playPauseSubject.send(())

        XCTAssertTrue(mockUseCase.togglePlayPauseCalled)
        XCTAssertEqual(receivedState?.isPlaying, true)
    }

    func test_rewindTapped_callsUseCaseAndUpdatesElapsed() {
        let rewindSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: makeInput(rewindTapped: rewindSubject.eraseToAnyPublisher()))

        var receivedState: ILTalkStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        rewindSubject.send(())

        XCTAssertTrue(mockUseCase.rewindCalled)
        XCTAssertEqual(receivedState?.elapsedText, "12:33") // 768 - 15 = 753s
    }

    func test_forwardTapped_callsUseCaseAndUpdatesElapsed() {
        let forwardSubject = PassthroughSubject<Void, Never>()
        let output = sut.transform(input: makeInput(forwardTapped: forwardSubject.eraseToAnyPublisher()))

        var receivedState: ILTalkStateModel?
        output.state
            .sink { if case .success(let model) = $0 { receivedState = model } }
            .store(in: &cancellables)

        forwardSubject.send(())

        XCTAssertTrue(mockUseCase.forwardCalled)
        XCTAssertEqual(receivedState?.elapsedText, "13:18") // 768 + 30 = 798s
    }

    func test_meditateTapped_firesOpenMeditationSetupEvent() {
        var receivedEvent: ILTalkNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        let meditateSubject = PassthroughSubject<Void, Never>()
        _ = sut.transform(input: makeInput(meditateTapped: meditateSubject.eraseToAnyPublisher()))

        meditateSubject.send(())

        XCTAssertEqual(receivedEvent, .openMeditationSetup)
    }

    // MARK: - Helpers

    private func makeInput(
        viewDidLoad: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        backTapped: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        playPauseTapped: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        rewindTapped: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        forwardTapped: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        meditateTapped: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()
    ) -> ILTalkViewModel.Input {
        ILTalkViewModel.Input(
            viewDidLoad: viewDidLoad,
            backTapped: backTapped,
            playPauseTapped: playPauseTapped,
            rewindTapped: rewindTapped,
            forwardTapped: forwardTapped,
            meditateTapped: meditateTapped
        )
    }
}

// MARK: - Mock ILTalkUseCase
final class MockILTalkUseCase: ILTalkUseCase {
    var getInitialStateCalled = false
    var togglePlayPauseCalled = false
    var rewindCalled = false
    var forwardCalled = false

    private let talk = ILTalkTrackEntity(
        id: "talk.vulan.hieu",
        eyebrow: "talk.mock.eyebrow".localized,
        title: "talk.mock.title".localized,
        narrator: "talk.mock.narrator".localized,
        narratorInitial: "talk.mock.initial".localized,
        durationMinutes: 46,
        listenCount: 2400,
        totalDurationSeconds: 2760,
        description: "talk.mock.description".localized,
        chapters: [
            ILTalkChapterEntity(id: "c0", timestampSeconds: 0, title: "talk.mock.chapter.0.title".localized)
        ]
    )

    func getInitialState(talkID: String) -> ILTalkEntity {
        getInitialStateCalled = true
        return ILTalkEntity(talks: [talk], currentTalkID: talkID, elapsedSeconds: 768, isPlaying: false)
    }

    func currentTalk(in entity: ILTalkEntity) -> ILTalkTrackEntity? {
        entity.talks.first { $0.id == entity.currentTalkID }
    }

    func togglePlayPause(_ entity: ILTalkEntity) -> ILTalkEntity {
        togglePlayPauseCalled = true
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    func rewind(_ entity: ILTalkEntity) -> ILTalkEntity {
        rewindCalled = true
        var updated = entity
        updated.elapsedSeconds = max(0, entity.elapsedSeconds - 15)
        return updated
    }

    func forward(_ entity: ILTalkEntity) -> ILTalkEntity {
        forwardCalled = true
        var updated = entity
        updated.elapsedSeconds = min(2760, entity.elapsedSeconds + 30)
        return updated
    }
}
