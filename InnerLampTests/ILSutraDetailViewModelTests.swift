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
    private var output: ILSutraDetailViewModel.Output!
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
        sut = ILSutraDetailViewModel(useCase: mockUseCase, sutraID: "kinh-tu-bi")
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        downloadTappedSubject = PassthroughSubject<Void, Never>()
        chantTappedSubject = PassthroughSubject<Void, Never>()
        playTappedSubject = PassthroughSubject<Void, Never>()
        chapterTappedSubject = PassthroughSubject<Void, Never>()

        // `transform` binds the inputs, so it must run exactly once per ViewModel.
        output = sut.transform(input: ILSutraDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            chantTapped: chantTappedSubject.eraseToAnyPublisher(),
            playTapped: playTappedSubject.eraseToAnyPublisher(),
            chapterTapped: chapterTappedSubject.eraseToAnyPublisher()
        ))
    }

    override func tearDown() {
        cancellables = nil
        output = nil
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

    private func loadState() -> ILSutraDetailStateModel? {
        var latest: ILSutraDetailStateModel?
        let loaded = expectation(description: "detail loaded")
        output.state
            .sink { state in
                if case .success(let model) = state {
                    latest = model
                    loaded.fulfill()
                }
            }
            .store(in: &cancellables)
        viewDidLoadSubject.send(())
        wait(for: [loaded], timeout: 2)
        return latest
    }

    private func firstEvent() -> () -> ILSutraDetailNavEvent? {
        var received: ILSutraDetailNavEvent?
        sut.navigationEventPublisher.sink { received = $0 }.store(in: &cancellables)
        return { received }
    }

    func test_viewDidLoad_loadsSutraByIDAndMapsDetail() {
        let state = loadState()

        XCTAssertEqual(mockUseCase.loadedIDs, ["kinh-tu-bi"])
        XCTAssertEqual(state?.title, "Kinh Từ Bi")
        XCTAssertEqual(state?.originalName, "Karaṇīyamettasutta")
        XCTAssertEqual(
            state?.kicker,
            ["sutraDetail.kicker.verse".localized, "sutras.category.theravada".localized]
                .joined(separator: "sutraDetail.kickerSeparator".localized).uppercased()
        )
        XCTAssertEqual(
            state?.metaText,
            [String(format: "sutraDetail.lineCountFormat".localized, 73), ILSutraDetailViewModel.formatDuration(minutes: 130)]
                .joined(separator: "sutraDetail.metaSeparator".localized)
        )
        XCTAssertEqual(state?.descriptionText, "Tiểu Bộ\("sutraDetail.descriptionSeparator".localized)Snp 1.8")
        XCTAssertEqual(state?.downloadButtonTitle, "sutraDetail.download".localized)
    }

    func test_viewDidLoad_showsTranslatorSourceAndLicense() {
        let state = loadState()

        XCTAssertEqual(
            state?.translatorText,
            [
                String(format: "sutraDetail.translator".localized, "Thích Minh Châu"),
                String(format: "sutraDetail.source".localized, "SuttaCentral"),
                String(format: "sutraDetail.license".localized, "CC0 1.0")
            ].joined(separator: "\n")
        )
    }

    func test_tags_listDailyChantThenPurposes() {
        let state = loadState()

        XCTAssertEqual(
            state?.tags.map(\.title),
            ["sutras.category.daily".localized, "sutras.category.blessing".localized]
        )
    }

    func test_noAudioOrProgressFromServer_usesReadCTAAndHidesProgress() {
        let state = loadState()

        XCTAssertEqual(state?.hasAudio, false)
        XCTAssertEqual(state?.hasProgress, false)
        XCTAssertEqual(state?.chantButtonTitle, "sutraDetail.read".localized)
    }

    func test_sections_becomeTableOfContentsWithLineCounts() {
        mockUseCase.sutra = ILSutraFixtures.detail(chapters: [
            ILSutraDetailChapterEntity(id: "section.1", number: "1", title: "Phẩm Một", lineCount: 20),
            ILSutraDetailChapterEntity(id: "section.2", number: "2", title: "Phẩm Hai", lineCount: 12)
        ])
        let state = loadState()

        XCTAssertEqual(state?.tocCountText, String(format: "sutraDetail.tocCount.chapters".localized, 2))
        XCTAssertEqual(state?.chapters.map(\.title), ["Phẩm Một", "Phẩm Hai"])
        XCTAssertEqual(state?.chapters.first?.subtitle, String(format: "sutraDetail.chapter.lineCount".localized, 20))
        XCTAssertEqual(state?.chapters.first?.durationText, "")
        XCTAssertEqual(state?.chapters.first?.isCurrent, false)
    }

    func test_noSections_leavesTableOfContentsEmpty() {
        let state = loadState()

        XCTAssertEqual(state?.chapters, [])
        XCTAssertEqual(state?.tocCountText, "")
    }

    func test_missingDurationAndUnknownTradition_areDroppedFromKickerAndMeta() {
        let base = ILSutraFixtures.detail()
        mockUseCase.sutra = ILSutraDetailSutraEntity(
            id: base.id, title: base.title, originalTitle: "", kind: nil, tradition: nil,
            collection: "", reference: "", isDailyChant: false, purposes: [], durationMinutes: nil,
            translator: "", sourceName: "", sourceURL: nil, license: "", lineCount: 9, chapters: []
        )
        let state = loadState()

        XCTAssertEqual(state?.kicker, "")
        XCTAssertEqual(state?.metaText, String(format: "sutraDetail.lineCountFormat".localized, 9))
        XCTAssertEqual(state?.descriptionText, "")
        XCTAssertEqual(state?.translatorText, "")
        XCTAssertEqual(state?.tags, [])
    }

    func test_viewDidLoad_failure_emitsFailure() {
        mockUseCase.error = ILCatalogError.notFound
        let failed = expectation(description: "failure emitted")
        output.state
            .sink { if case .failure(let error) = $0, case ILCatalogError.notFound = error { failed.fulfill() } }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
        wait(for: [failed], timeout: 2)
    }

    func test_backTapped_firesBackNavigationEvent() {
        let event = firstEvent()
        backTappedSubject.send(())
        XCTAssertEqual(event(), .back)
    }

    func test_chantTapped_firesOpenReaderNavigationEvent() {
        let event = firstEvent()
        chantTappedSubject.send(())
        XCTAssertEqual(event(), .openReader)
    }

    func test_chapterTapped_firesOpenReaderNavigationEvent() {
        let event = firstEvent()
        chapterTappedSubject.send(())
        XCTAssertEqual(event(), .openReader)
    }

    func test_playTapped_firesOpenPlayerNavigationEvent() {
        let event = firstEvent()
        playTappedSubject.send(())
        XCTAssertEqual(event(), .openPlayer)
    }

    func test_downloadTapped_firesDownloadNavigationEvent() {
        let event = firstEvent()
        downloadTappedSubject.send(())
        XCTAssertEqual(event(), .download)
    }
}

// MARK: - Mock ILSutraDetailUseCase
final class MockILSutraDetailUseCase: ILSutraDetailUseCase {
    var sutra: ILSutraDetailSutraEntity = ILSutraFixtures.detail()
    var error: Error?
    private(set) var loadedIDs: [String] = []

    func loadSutra(id: String) async throws -> ILSutraDetailEntity {
        loadedIDs.append(id)
        if let error { throw error }
        return ILSutraDetailEntity(sutra: sutra)
    }
}
