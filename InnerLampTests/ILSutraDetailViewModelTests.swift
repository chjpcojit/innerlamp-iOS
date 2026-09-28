//
//  ILSutraDetailViewModelTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 26/9/26.
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSutraDetailViewModelTests: XCTestCase {

    private var mockUseCase: MockILSutraDetailUseCase!
    private var sut: ILSutraDetailViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var downloadTappedSubject: PassthroughSubject<Void, Never>!
    private var chantTappedSubject: PassthroughSubject<Void, Never>!
    private var playTappedSubject: PassthroughSubject<Void, Never>!
    private var chapterTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILSutraDetailUseCase()
        sut = ILSutraDetailViewModel(useCase: mockUseCase, sutraID: "sutra.phapcu")
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        downloadTappedSubject = PassthroughSubject<Void, Never>()
        chantTappedSubject = PassthroughSubject<Void, Never>()
        playTappedSubject = PassthroughSubject<Void, Never>()
        chapterTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        chapterTappedSubject = nil
        playTappedSubject = nil
        chantTappedSubject = nil
        downloadTappedSubject = nil
        backTappedSubject = nil
        viewDidLoadSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILSutraDetailViewModel.Input {
        ILSutraDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            playTapped: playTappedSubject.eraseToAnyPublisher(),
            chapterTapped: chapterTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeLatestState() -> () -> ILSutraDetailStateModel? {
        let output = sut.transform(input: makeInput())
        var latest: ILSutraDetailStateModel?
        output.state
            .sink { state in
                if case .success(let model) = state { latest = model }
            }
            .store(in: &cancellables)
        return { latest }
    }

    func test_viewDidLoad_populatesSutraDetail() {
        let latest = observeLatestState()

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        let state = latest()
        XCTAssertEqual(state?.kicker, "KINH VĂN · SONG NGỮ")
        XCTAssertEqual(state?.title, "Kinh Pháp Cú")
        XCTAssertEqual(
            state?.metaText,
            String(
                format: "sutraDetail.metaFormat".localized,
                26, 423, "Thầy Minh Đạo",
                ILSutraDetailViewModel.formatDuration(minutes: 130)
            )
        )
        XCTAssertEqual(state?.tags.count, 2)
        XCTAssertEqual(state?.progressPercentText, String(format: "sutraDetail.progress.percent".localized, 34))
        XCTAssertEqual(state?.progressValue ?? 0, 0.34, accuracy: 0.001)
        XCTAssertEqual(state?.tocCountText, String(format: "sutraDetail.tocCount".localized, 26))
        XCTAssertEqual(state?.chapters.count, 2)
        XCTAssertEqual(state?.chantButtonTitle, "sutraDetail.chant".localized)
        XCTAssertEqual(state?.downloadButtonTitle, "sutraDetail.download".localized)
    }

    func test_tags_areOrderedWithFilledFirst() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        let tags = latest()?.tags ?? []
        XCTAssertEqual(tags.map(\.title), ["sutraDetail.tag.daily".localized, "sutraDetail.tag.phonetic".localized])
        XCTAssertEqual(tags.map(\.isFilled), [true, false])
    }

    func test_chapterSubtitle_marksOnlyCurrentChapter() {
        let latest = observeLatestState()
        viewDidLoadSubject.send(())

        let chapters = latest()?.chapters ?? []
        XCTAssertEqual(chapters.count, 2)

        let current = chapters[0]
        XCTAssertTrue(current.isCurrent)
        XCTAssertEqual(
            current.subtitle,
            String(format: "sutraDetail.chapter.verseRange".localized, 1, 20) + "sutraDetail.chapter.currentSuffix".localized
        )
        XCTAssertEqual(current.durationText, String(format: "sutraDetail.chapter.duration".localized, 9))

        let nonCurrent = chapters[1]
        XCTAssertFalse(nonCurrent.isCurrent)
        XCTAssertEqual(nonCurrent.subtitle, String(format: "sutraDetail.chapter.verseRange".localized, 21, 32))
    }

    func test_backTapped_firesBackNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILSutraDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .back)
    }

    func test_chantTapped_firesOpenReaderNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILSutraDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        chantTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openReader)
    }

    func test_chapterTapped_firesOpenReaderNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILSutraDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        chapterTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openReader)
    }

    func test_playTapped_firesOpenPlayerNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILSutraDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        playTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openPlayer)
    }

    func test_downloadTapped_firesDownloadNavigationEvent() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILSutraDetailNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        downloadTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .download)
    }
}

// MARK: - Mock ILSutraDetailUseCase
final class MockILSutraDetailUseCase: ILSutraDetailUseCase {
    var getInitialStateCalled = false

    func getInitialState(sutraID: String) -> ILSutraDetailEntity {
        getInitialStateCalled = true
        return ILSutraDetailEntity(
            sutras: [Self.sutra],
            currentSutraID: sutraID,
            currentChapterID: "chapter.1",
            readingProgress: 0.34
        )
    }

    func currentSutra(in entity: ILSutraDetailEntity) -> ILSutraDetailSutraEntity? {
        entity.sutras.first { $0.id == entity.currentSutraID }
    }

    private static let sutra = ILSutraDetailSutraEntity(
        id: "sutra.phapcu",
        kicker: "KINH VĂN · SONG NGỮ",
        title: "Kinh Pháp Cú",
        narrator: "Thầy Minh Đạo",
        numberOfChapters: 26,
        numberOfVerses: 423,
        durationMinutes: 130,
        description: "Mô tả mẫu",
        tags: [.daily, .phonetic],
        chapters: [
            ILSutraDetailChapterEntity(
                id: "chapter.1", number: "I", title: "Phẩm Song Yếu",
                verseStart: 1, verseEnd: 20, durationMinutes: 9
            ),
            ILSutraDetailChapterEntity(
                id: "chapter.2", number: "II", title: "Phẩm Không Phóng Dật",
                verseStart: 21, verseEnd: 32, durationMinutes: 7
            )
        ]
    )
}
