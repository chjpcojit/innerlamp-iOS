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
    private var fontSizeTappedSubject: PassthroughSubject<Void, Never>!
    private var shareTappedSubject: PassthroughSubject<Void, Never>!
    private var downloadTappedSubject: PassthroughSubject<Void, Never>!
    private var playPauseTappedSubject: PassthroughSubject<Void, Never>!
    private var speedTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILReaderUseCase()
        sut = ILReaderViewModel(useCase: mockUseCase, sutraID: "sutra.phapcu")
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        fontSizeTappedSubject = PassthroughSubject<Void, Never>()
        shareTappedSubject = PassthroughSubject<Void, Never>()
        downloadTappedSubject = PassthroughSubject<Void, Never>()
        playPauseTappedSubject = PassthroughSubject<Void, Never>()
        speedTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        speedTappedSubject = nil
        playPauseTappedSubject = nil
        downloadTappedSubject = nil
        shareTappedSubject = nil
        fontSizeTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILReaderViewModel.Input {
        ILReaderViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            fontSizeTapped: fontSizeTappedSubject.eraseToAnyPublisher(),
            shareTapped: shareTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            playPauseTapped: playPauseTappedSubject.eraseToAnyPublisher(),
            speedTapped: speedTappedSubject.eraseToAnyPublisher()
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

    func test_viewDidLoad_showsRequestedSutra() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.title, "Kinh Pháp Cú")
        XCTAssertEqual(state?.subtitle, "Phẩm Song Yếu · kệ 1–2")
        XCTAssertEqual(state?.verseText, "verse-0-vi")
        XCTAssertEqual(state?.translationText, "verse-0-en")
        XCTAssertEqual(state?.nextVerseText, "verse-1-vi")
        XCTAssertEqual(state?.readingProgress ?? -1, 0.34, accuracy: 0.0001)
        XCTAssertEqual(state?.shareChipTitle, "reader.verse.share".localized)
        XCTAssertEqual(state?.downloadChipTitle, "reader.verse.download".localized)
        XCTAssertEqual(state?.fontSizeActionTitle, "reader.header.fontSizeAction".localized)
        // Chưa phát → nhãn "Tạm dừng" + người tụng.
        XCTAssertEqual(
            state?.nowPlayingText,
            String(format: "reader.playback.nowPlayingFormat".localized, "reader.playback.paused".localized, "narrator")
        )
        XCTAssertEqual(state?.elapsedText, String(format: "reader.playback.timeFormat".localized, 1, 0))
        XCTAssertEqual(state?.speedText, String(format: "reader.playback.speedFormat".localized, 1.0))
        XCTAssertEqual(state?.playbackProgress ?? -1, 0.5, accuracy: 0.0001)
        XCTAssertEqual(state?.isPlaying, false)
    }

    func test_playPauseTapped_togglesPlayingAndLabel() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        playPauseTappedSubject.send(())

        XCTAssertTrue(mockUseCase.togglePlayPauseCalled)
        var state = latest()
        XCTAssertEqual(state?.isPlaying, true)
        XCTAssertEqual(
            state?.nowPlayingText,
            String(format: "reader.playback.nowPlayingFormat".localized, "reader.playback.playing".localized, "narrator")
        )

        playPauseTappedSubject.send(())

        state = latest()
        XCTAssertEqual(state?.isPlaying, false)
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

    func test_fontSizeTapped_firesOpenFontSizeNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILReaderNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        fontSizeTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openFontSize)
    }

    func test_shareTapped_firesShareNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILReaderNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        shareTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .share)
    }

    func test_downloadTapped_firesDownloadNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILReaderNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        downloadTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .download)
    }

    func test_speedTapped_firesOpenPlayerNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILReaderNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        speedTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openPlayer)
    }
}

// MARK: - Mock ILReaderUseCase
/// Catalog cố định 1 bộ kinh 2 kệ — đủ để test hiển thị kệ hiện tại + bản xem trước kệ kế tiếp.
final class MockILReaderUseCase: ILReaderUseCase {
    var getInitialStateCalled = false
    var togglePlayPauseCalled = false

    private static let sutra = ILReaderSutraEntity(
        id: "sutra.phapcu",
        title: "Kinh Pháp Cú",
        subtitle: "Phẩm Song Yếu · kệ 1–2",
        narrator: "narrator",
        totalDurationSeconds: 120,
        verses: [
            ILReaderVerseEntity(vietnamese: "verse-0-vi", english: "verse-0-en"),
            ILReaderVerseEntity(vietnamese: "verse-1-vi", english: "verse-1-en")
        ]
    )

    func getInitialState(sutraID: String) -> ILReaderEntity {
        getInitialStateCalled = true
        return ILReaderEntity(
            sutras: [Self.sutra],
            currentSutraID: sutraID,
            currentVerseIndex: 0,
            readingProgress: 0.34,
            elapsedSeconds: 60,
            playbackSpeed: 1.0,
            isPlaying: false
        )
    }

    func currentSutra(in entity: ILReaderEntity) -> ILReaderSutraEntity? {
        entity.sutras.first { $0.id == entity.currentSutraID }
    }

    func currentVerse(in entity: ILReaderEntity) -> ILReaderVerseEntity? {
        guard let sutra = currentSutra(in: entity),
              sutra.verses.indices.contains(entity.currentVerseIndex) else { return nil }
        return sutra.verses[entity.currentVerseIndex]
    }

    func nextVerse(in entity: ILReaderEntity) -> ILReaderVerseEntity? {
        guard let sutra = currentSutra(in: entity),
              sutra.verses.indices.contains(entity.currentVerseIndex + 1) else { return nil }
        return sutra.verses[entity.currentVerseIndex + 1]
    }

    func togglePlayPause(_ entity: ILReaderEntity) -> ILReaderEntity {
        togglePlayPauseCalled = true
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }
}
