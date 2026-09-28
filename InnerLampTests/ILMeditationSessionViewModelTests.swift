//
//  ILMeditationSessionViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILMeditationSessionViewModelTests: XCTestCase {

    private var mockUseCase: MockILMeditationSessionUseCase!
    private var mockSoundPlayer: MockILPracticeSoundPlayer!
    private var sut: ILMeditationSessionViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var tickerSubject: PassthroughSubject<Void, Never>!
    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var playPauseTappedSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var endTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILMeditationSessionUseCase()
        mockSoundPlayer = MockILPracticeSoundPlayer()
        tickerSubject = PassthroughSubject<Void, Never>()
        sut = makeSUT(durationMinutes: 20, isGuided: true)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        playPauseTappedSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        endTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        tickerSubject = nil
        viewDidLoadSubject = nil
        playPauseTappedSubject = nil
        backTappedSubject = nil
        endTappedSubject = nil
        sut = nil
        mockUseCase = nil
        mockSoundPlayer = nil
        super.tearDown()
    }

    private func makeSUT(durationMinutes: Int, isGuided: Bool) -> ILMeditationSessionViewModel {
        ILMeditationSessionViewModel(
            durationMinutes: durationMinutes,
            isGuided: isGuided,
            useCase: mockUseCase,
            soundPlayer: mockSoundPlayer,
            ticker: tickerSubject.eraseToAnyPublisher()
        )
    }

    private func makeInput() -> ILMeditationSessionViewModel.Input {
        ILMeditationSessionViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            endTapped: endTappedSubject.eraseToAnyPublisher()
        )
    }

    /// Subscribes to `output.state` and returns a box holding the latest success model.
    private func observeState(_ output: ILMeditationSessionViewModel.Output) -> StateBox {
        let box = StateBox()
        output.state
            .sink { state in
                if case .success(let model) = state { box.latest = model }
            }
            .store(in: &cancellables)
        return box
    }

    private func observeNavigation() -> NavBox {
        let box = NavBox()
        sut.navigationEventPublisher
            .sink { event in
                box.events.append(event)
                box.expectation?.fulfill()
            }
            .store(in: &cancellables)
        return box
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_rendersFullCountdownGuidedCueAndRingsOpeningBell() {
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertEqual(mockUseCase.lastMadeDurationMinutes, 20)
        XCTAssertEqual(mockUseCase.lastMadeIsGuided, true)
        XCTAssertEqual(box.latest?.headerTitle, "meditationSession.header.title".localized)
        XCTAssertEqual(box.latest?.headerSubtitle, String(format: "meditationSession.header.durationFormat".localized, 20))
        XCTAssertEqual(box.latest?.timerText, "20:00")
        XCTAssertEqual(box.latest?.timerCaption, String(format: "meditationSession.timer.remainingFormat".localized, 20))
        XCTAssertEqual(box.latest?.cueText, "meditationSession.cue.inhale".localized)
        XCTAssertEqual(box.latest?.cueTranslation, "meditationSession.cue.inhale.translation".localized)
        XCTAssertEqual(box.latest?.breathPhase, .inhale)
        XCTAssertEqual(box.latest?.isPlaying, true)
        XCTAssertEqual(box.latest?.endEarlyTitle, "meditationSession.endEarly".localized)
        XCTAssertTrue(mockSoundPlayer.playBellCalled)
    }

    func test_viewDidLoad_silentSession_hidesCueAndMarksHeaderSilent() {
        sut = makeSUT(durationMinutes: 12, isGuided: false)
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertEqual(box.latest?.headerSubtitle, String(format: "meditationSession.header.silentFormat".localized, 12))
        XCTAssertEqual(box.latest?.timerText, "12:00")
        XCTAssertEqual(box.latest?.cueText, "")
        XCTAssertEqual(box.latest?.cueTranslation, "")
    }

    // MARK: - Ticks
    func test_tick_beforeViewDidLoad_isIgnored() {
        let box = observeState(sut.transform(input: makeInput()))

        tickerSubject.send(())

        XCTAssertEqual(mockUseCase.tickCallCount, 0)
        XCTAssertEqual(box.latest?.timerText, "20:00")
    }

    func test_tick_countsDownAndSwitchesToExhaleCue() {
        let box = observeState(sut.transform(input: makeInput()))
        viewDidLoadSubject.send(())

        for _ in 0..<5 { tickerSubject.send(()) }

        XCTAssertEqual(mockUseCase.tickCallCount, 5)
        XCTAssertEqual(box.latest?.timerText, "19:55")
        XCTAssertEqual(box.latest?.breathPhase, .exhale)
        XCTAssertEqual(box.latest?.secondsLeftInBreathPhase, 5)
        XCTAssertEqual(box.latest?.cueText, "meditationSession.cue.exhale".localized)
    }

    func test_tick_reachingZero_finishesSessionAndRecordsIt() {
        mockUseCase.stubDurationSeconds = 3
        sut = makeSUT(durationMinutes: 1, isGuided: true)
        _ = sut.transform(input: makeInput())
        let nav = observeNavigation()
        nav.expectation = expectation(description: "finished")
        viewDidLoadSubject.send(())
        mockSoundPlayer.playBellCalled = false

        for _ in 0..<3 { tickerSubject.send(()) }

        wait(for: [nav.expectation!], timeout: 1)
        XCTAssertEqual(nav.events, [.finished(elapsedSeconds: 3)])
        XCTAssertEqual(mockUseCase.recordedSession?.elapsedSeconds, 3)
        XCTAssertTrue(mockSoundPlayer.playBellCalled)
    }

    // MARK: - Play / pause
    func test_playPauseTapped_pausesAndStopsCountdown() {
        let box = observeState(sut.transform(input: makeInput()))
        viewDidLoadSubject.send(())

        playPauseTappedSubject.send(())
        tickerSubject.send(())

        XCTAssertEqual(mockUseCase.togglePauseCallCount, 1)
        XCTAssertEqual(box.latest?.isPlaying, false)
        XCTAssertEqual(box.latest?.timerText, "20:00")
        XCTAssertEqual(mockUseCase.tickCallCount, 0)
    }

    func test_playPauseTapped_twice_resumesCountdown() {
        let box = observeState(sut.transform(input: makeInput()))
        viewDidLoadSubject.send(())

        playPauseTappedSubject.send(())
        playPauseTappedSubject.send(())
        tickerSubject.send(())

        XCTAssertEqual(box.latest?.isPlaying, true)
        XCTAssertEqual(box.latest?.timerText, "19:59")
    }

    // MARK: - Navigation
    func test_backTapped_firesGoBack() {
        _ = sut.transform(input: makeInput())
        let nav = observeNavigation()

        backTappedSubject.send(())

        XCTAssertEqual(nav.events, [.goBack])
        XCTAssertNil(mockUseCase.recordedSession)
    }

    func test_endTapped_endsEarlyRecordsAndFiresFinished() {
        let box = observeState(sut.transform(input: makeInput()))
        let nav = observeNavigation()
        nav.expectation = expectation(description: "finished")
        viewDidLoadSubject.send(())
        for _ in 0..<7 { tickerSubject.send(()) }
        mockSoundPlayer.playBellCalled = false

        endTappedSubject.send(())

        wait(for: [nav.expectation!], timeout: 1)
        XCTAssertEqual(nav.events, [.finished(elapsedSeconds: 7)])
        XCTAssertEqual(mockUseCase.recordedSession?.elapsedSeconds, 7)
        XCTAssertEqual(box.latest?.isPlaying, false)
        XCTAssertTrue(mockSoundPlayer.playBellCalled)
    }

    func test_endTapped_twice_finishesOnlyOnce() {
        _ = sut.transform(input: makeInput())
        let nav = observeNavigation()
        nav.expectation = expectation(description: "finished")
        viewDidLoadSubject.send(())

        endTappedSubject.send(())
        endTappedSubject.send(())

        wait(for: [nav.expectation!], timeout: 1)
        XCTAssertEqual(mockUseCase.recordSessionCallCount, 1)
        XCTAssertEqual(nav.events, [.finished(elapsedSeconds: 0)])
    }

    func test_endTapped_whenRecordingFails_emitsFailureAndDoesNotNavigate() {
        mockUseCase.recordError = MockError.failed
        let output = sut.transform(input: makeInput())
        let nav = observeNavigation()
        let failure = expectation(description: "failure")
        output.state
            .sink { state in
                if case .failure = state { failure.fulfill() }
            }
            .store(in: &cancellables)
        viewDidLoadSubject.send(())

        endTappedSubject.send(())

        wait(for: [failure], timeout: 1)
        XCTAssertTrue(nav.events.isEmpty)
    }
}

// MARK: - ILMeditationSessionUseCaseImpl (real domain rules)
final class ILMeditationSessionUseCaseTests: XCTestCase {

    private let sut = ILMeditationSessionUseCaseImpl()

    func test_makeSession_convertsMinutesAndStartsRunning() {
        let session = sut.makeSession(durationMinutes: 20, isGuided: true)
        XCTAssertEqual(session.durationSeconds, 1_200)
        XCTAssertEqual(session.elapsedSeconds, 0)
        XCTAssertTrue(session.isRunning)
        XCTAssertTrue(session.isGuided)
    }

    func test_makeSession_clampsNonPositiveDurationToOneMinute() {
        XCTAssertEqual(sut.makeSession(durationMinutes: 0, isGuided: false).durationSeconds, 60)
        XCTAssertEqual(sut.makeSession(durationMinutes: -5, isGuided: false).durationSeconds, 60)
    }

    func test_tick_advancesRunningSessionBySecond() {
        let session = sut.makeSession(durationMinutes: 5, isGuided: true)
        let next = sut.tick(session)
        XCTAssertEqual(next.elapsedSeconds, 1)
        XCTAssertEqual(next.remainingSeconds, 299)
        XCTAssertTrue(next.isRunning)
    }

    func test_tick_pausedSession_isUnchanged() {
        let paused = sut.togglePause(sut.makeSession(durationMinutes: 5, isGuided: true))
        let next = sut.tick(paused)
        XCTAssertEqual(next.elapsedSeconds, 0)
        XCTAssertFalse(next.isRunning)
    }

    func test_tick_reachingDuration_completesAndStops() {
        var session = ILMeditationSessionEntity(durationSeconds: 60, elapsedSeconds: 59, isGuided: true)
        session = sut.tick(session)
        XCTAssertTrue(session.isCompleted)
        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.remainingSeconds, 0)
        XCTAssertEqual(sut.tick(session).elapsedSeconds, 60)
    }

    func test_togglePause_completedSession_staysStopped() {
        let completed = ILMeditationSessionEntity(durationSeconds: 60, elapsedSeconds: 60, isGuided: true, isRunning: false)
        XCTAssertFalse(sut.togglePause(completed).isRunning)
    }

    func test_endSession_stopsWithoutChangingElapsed() {
        let session = ILMeditationSessionEntity(durationSeconds: 600, elapsedSeconds: 42, isGuided: true)
        let ended = sut.endSession(session)
        XCTAssertFalse(ended.isRunning)
        XCTAssertEqual(ended.elapsedSeconds, 42)
    }

    func test_breathPhase_followsFourInSixOutRhythm() {
        func phase(at elapsed: Int) -> (ILBreathPhase, Int) {
            let session = ILMeditationSessionEntity(durationSeconds: 600, elapsedSeconds: elapsed, isGuided: true)
            return (session.breathPhase, session.secondsLeftInBreathPhase)
        }
        XCTAssertTrue(phase(at: 0) == (.inhale, 4))
        XCTAssertTrue(phase(at: 3) == (.inhale, 1))
        XCTAssertTrue(phase(at: 4) == (.exhale, 6))
        XCTAssertTrue(phase(at: 9) == (.exhale, 1))
        XCTAssertTrue(phase(at: 10) == (.inhale, 4))
    }
}

// MARK: - Helpers
private final class StateBox {
    var latest: ILMeditationSessionStateModel?
}

private final class NavBox {
    var events: [ILMeditationSessionNavEvent] = []
    var expectation: XCTestExpectation?
}

private enum MockError: Error {
    case failed
}

// MARK: - Mock ILMeditationSessionUseCase
/// Mirrors the real rules with plain arithmetic so ViewModel tests stay readable; the rules
/// themselves are covered by `ILMeditationSessionUseCaseTests` above.
final class MockILMeditationSessionUseCase: ILMeditationSessionUseCase {
    /// Overrides `durationMinutes * 60` so completion can be reached with a few ticks.
    var stubDurationSeconds: Int?
    var recordError: Error?

    var lastMadeDurationMinutes: Int?
    var lastMadeIsGuided: Bool?
    func makeSession(durationMinutes: Int, isGuided: Bool) -> ILMeditationSessionEntity {
        lastMadeDurationMinutes = durationMinutes
        lastMadeIsGuided = isGuided
        return ILMeditationSessionEntity(durationSeconds: stubDurationSeconds ?? durationMinutes * 60, isGuided: isGuided)
    }

    var tickCallCount = 0
    func tick(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity {
        tickCallCount += 1
        guard session.isRunning, !session.isCompleted else { return session }
        var next = session
        next.elapsedSeconds += 1
        if next.isCompleted { next.isRunning = false }
        return next
    }

    var togglePauseCallCount = 0
    func togglePause(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity {
        togglePauseCallCount += 1
        var next = session
        next.isRunning.toggle()
        return next
    }

    func endSession(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity {
        var next = session
        next.isRunning = false
        return next
    }

    var recordSessionCallCount = 0
    var recordedSession: ILMeditationSessionEntity?
    func recordSession(_ session: ILMeditationSessionEntity) async throws {
        recordSessionCallCount += 1
        recordedSession = session
        if let recordError { throw recordError }
    }
}
