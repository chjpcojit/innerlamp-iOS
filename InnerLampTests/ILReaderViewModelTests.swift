//
//  ILReaderViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILReaderViewModelTests: XCTestCase {

    private var mockUseCase: MockILReaderUseCase!
    private var sut: ILReaderViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var settingsTappedSubject: PassthroughSubject<Void, Never>!
    private var autoScrollToggledSubject: PassthroughSubject<Void, Never>!
    private var contentTappedSubject: PassthroughSubject<Void, Never>!
    private var playPauseTappedSubject: PassthroughSubject<Void, Never>!
    private var seekBackTappedSubject: PassthroughSubject<Void, Never>!
    private var seekForwardTappedSubject: PassthroughSubject<Void, Never>!
    private var speedSelectedSubject: PassthroughSubject<Double, Never>!
    private var fontSizeSelectedSubject: PassthroughSubject<Int, Never>!
    private var themeSelectedSubject: PassthroughSubject<Int, Never>!
    private var tickSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILReaderUseCase()
        cancellables = []
        viewDidLoadSubject = .init()
        backTappedSubject = .init()
        settingsTappedSubject = .init()
        autoScrollToggledSubject = .init()
        contentTappedSubject = .init()
        playPauseTappedSubject = .init()
        seekBackTappedSubject = .init()
        seekForwardTappedSubject = .init()
        speedSelectedSubject = .init()
        fontSizeSelectedSubject = .init()
        themeSelectedSubject = .init()
        tickSubject = .init()
        sut = ILReaderViewModel(
            useCase: mockUseCase,
            sutraID: "sutra.phapcu",
            tickPublisher: tickSubject.eraseToAnyPublisher()
        )
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILReaderViewModel.Input {
        ILReaderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            settingsTapped: settingsTappedSubject.eraseToAnyPublisher(),
            autoScrollToggled: autoScrollToggledSubject.eraseToAnyPublisher(),
            contentTapped: contentTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            seekBackTapped: seekBackTappedSubject.eraseToAnyPublisher(),
            seekForwardTapped: seekForwardTappedSubject.eraseToAnyPublisher(),
            speedSelected: speedSelectedSubject.eraseToAnyPublisher(),
            fontSizeSelected: fontSizeSelectedSubject.eraseToAnyPublisher(),
            themeSelected: themeSelectedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILReaderStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILReaderStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_buildsRowsAndHighlightsFirstLine() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.title, "Kinh Pháp Cú")
        XCTAssertEqual(state?.rows.count, 5) // 2 headings + 3 lines
        XCTAssertEqual(state?.rows.first, .heading("HEAD-A"))
        XCTAssertEqual(state?.currentRowIndex, 1)
        guard case .line(let line)? = state?.rows[1] else { return XCTFail("row 1 should be a line") }
        XCTAssertTrue(line.isCurrent)
        XCTAssertEqual(line.cueGlyph, "◉")
        XCTAssertEqual(line.gloss, "gloss-0")
        XCTAssertEqual(state?.positionText, "0:00")
        XCTAssertEqual(state?.durationText, "2:00")
        XCTAssertEqual(state?.hasAudio, true)
        XCTAssertEqual(state?.speedOptions.map(\.isSelected), [true, false, false])
        XCTAssertEqual(state?.statusText, String(format: "reader.status.chantingFormat".localized, "narrator"))
    }

    func test_tick_advancesHighlightToNextLine() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        tickSubject.send(())

        XCTAssertEqual(mockUseCase.advancedMilliseconds, 250)
        XCTAssertEqual(latest()?.currentRowIndex, 2)
    }

    func test_tick_whilePaused_doesNotAdvance() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        playPauseTappedSubject.send(())

        tickSubject.send(())

        XCTAssertNil(mockUseCase.advancedMilliseconds)
        XCTAssertEqual(latest()?.isPlaying, false)
        XCTAssertEqual(latest()?.statusText, "reader.status.paused".localized)
    }

    func test_seekButtons_moveByTwoLines() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        seekForwardTappedSubject.send(())
        XCTAssertEqual(mockUseCase.lastSeekDelta, 2)
        XCTAssertEqual(latest()?.currentRowIndex, 4)

        seekBackTappedSubject.send(())
        XCTAssertEqual(mockUseCase.lastSeekDelta, -2)
        XCTAssertEqual(latest()?.currentRowIndex, 1)
    }

    func test_speedSelected_updatesSelectedChip() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        speedSelectedSubject.send(1.5)

        XCTAssertEqual(latest()?.speedOptions.map(\.isSelected), [false, false, true])
    }

    func test_contentTapped_togglesPlayback_whenSettingsClosed() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        contentTappedSubject.send(())

        XCTAssertEqual(latest()?.isPlaying, false)
    }

    func test_contentTapped_closesSettingsWithoutTogglingPlayback() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        settingsTappedSubject.send(())
        XCTAssertEqual(latest()?.isSettingsVisible, true)

        contentTappedSubject.send(())

        XCTAssertEqual(latest()?.isSettingsVisible, false)
        XCTAssertEqual(latest()?.isPlaying, true)
    }

    func test_autoScrollToggled_flipsFlag() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())
        XCTAssertEqual(latest()?.isAutoScrollEnabled, true)

        autoScrollToggledSubject.send(())

        XCTAssertEqual(latest()?.isAutoScrollEnabled, false)
    }

    func test_fontSizeAndTheme_validSelectionsApply_invalidIgnored() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        fontSizeSelectedSubject.send(3)
        themeSelectedSubject.send(2)
        XCTAssertEqual(latest()?.fontSizeIndex, 3)
        XCTAssertEqual(latest()?.themeIndex, 2)

        fontSizeSelectedSubject.send(9)
        themeSelectedSubject.send(-1)
        XCTAssertEqual(latest()?.fontSizeIndex, 3)
        XCTAssertEqual(latest()?.themeIndex, 2)
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILReaderNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_textOnlySutra_showsTextOnlyStatusAndScrollSpeedLabel() {
        mockUseCase.hasAudio = false
        sut = ILReaderViewModel(
            useCase: mockUseCase, sutraID: "sutra.phapcu", tickPublisher: tickSubject.eraseToAnyPublisher()
        )
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.statusText, "reader.status.textOnly".localized)
        XCTAssertEqual(latest()?.speedLabel, "reader.speed.scrollLabel".localized)
        XCTAssertEqual(latest()?.hasAudio, false)
    }
}

// MARK: - Mock ILReaderUseCase
/// One sutra with 2 sections (2 + 1 lines) — enough to test row building, highlight and seeking.
final class MockILReaderUseCase: ILReaderUseCase {
    var hasAudio = true
    var advancedMilliseconds: Double?
    var lastSeekDelta: Int?

    private var sutra: ILReaderSutraEntity {
        ILReaderSutraEntity(
            id: "sutra.phapcu",
            title: "Kinh Pháp Cú",
            narrator: hasAudio ? "narrator" : "",
            hasAudio: hasAudio,
            totalDurationSeconds: 120,
            sections: [
                ILReaderSectionEntity(heading: "HEAD-A", lines: [
                    ILReaderLineEntity(text: "line-0", gloss: "gloss-0", cue: .bell),
                    ILReaderLineEntity(text: "line-1", gloss: "", cue: .knock)
                ]),
                ILReaderSectionEntity(heading: "HEAD-B", lines: [
                    ILReaderLineEntity(text: "line-2", gloss: "", cue: .none)
                ])
            ]
        )
    }

    func getInitialState(sutraID: String) -> ILReaderEntity {
        ILReaderEntity(
            sutras: [sutra], currentSutraID: sutraID, currentLineIndex: 0,
            playbackSpeed: 1.0, isPlaying: hasAudio, accumulatedMilliseconds: 0
        )
    }

    func currentSutra(in entity: ILReaderEntity) -> ILReaderSutraEntity? {
        entity.sutras.first { $0.id == entity.currentSutraID }
    }

    func togglePlayPause(_ entity: ILReaderEntity) -> ILReaderEntity {
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    func seek(_ entity: ILReaderEntity, byLines delta: Int) -> ILReaderEntity {
        lastSeekDelta = delta
        var updated = entity
        updated.currentLineIndex = min(2, max(0, entity.currentLineIndex + delta))
        return updated
    }

    func setSpeed(_ entity: ILReaderEntity, to speed: Double) -> ILReaderEntity {
        var updated = entity
        updated.playbackSpeed = speed
        return updated
    }

    func advance(_ entity: ILReaderEntity, byMilliseconds milliseconds: Double) -> ILReaderEntity {
        advancedMilliseconds = milliseconds
        var updated = entity
        updated.currentLineIndex = min(2, entity.currentLineIndex + 1)
        return updated
    }

    func progress(in entity: ILReaderEntity) -> Double { Double(entity.currentLineIndex) / 2 }

    func elapsedSeconds(in entity: ILReaderEntity) -> Int { Int(progress(in: entity) * 120) }
}
