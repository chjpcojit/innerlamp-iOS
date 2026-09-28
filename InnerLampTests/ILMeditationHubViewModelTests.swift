//
//  ILMeditationHubViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILMeditationHubViewModelTests: XCTestCase {

    private var mockUseCase: MockILMeditationHubUseCase!
    private var sut: ILMeditationHubViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var tabSelectedSubject: PassthroughSubject<ILMeditationHubTabKind, Never>!
    private var presetTappedSubject: PassthroughSubject<String, Never>!
    private var customTimerTappedSubject: PassthroughSubject<Void, Never>!
    private var guidedTappedSubject: PassthroughSubject<String, Never>!
    private var downloadTappedSubject: PassthroughSubject<String, Never>!
    private var summaryTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILMeditationHubUseCase()
        sut = ILMeditationHubViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        tabSelectedSubject = PassthroughSubject<ILMeditationHubTabKind, Never>()
        presetTappedSubject = PassthroughSubject<String, Never>()
        customTimerTappedSubject = PassthroughSubject<Void, Never>()
        guidedTappedSubject = PassthroughSubject<String, Never>()
        downloadTappedSubject = PassthroughSubject<String, Never>()
        summaryTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        tabSelectedSubject = nil
        presetTappedSubject = nil
        customTimerTappedSubject = nil
        guidedTappedSubject = nil
        downloadTappedSubject = nil
        summaryTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILMeditationHubViewModel.Input {
        ILMeditationHubViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            tabSelected: tabSelectedSubject.eraseToAnyPublisher(),
            presetTapped: presetTappedSubject.eraseToAnyPublisher(),
            customTimerTapped: customTimerTappedSubject.eraseToAnyPublisher(),
            guidedTapped: guidedTappedSubject.eraseToAnyPublisher(),
            downloadTapped: downloadTappedSubject.eraseToAnyPublisher(),
            summaryTapped: summaryTappedSubject.eraseToAnyPublisher()
        )
    }

    private func observeState(_ output: ILMeditationHubViewModel.Output) -> StateBox {
        let box = StateBox()
        output.state
            .sink { state in
                if case .success(let model) = state { box.latest = model }
            }
            .store(in: &cancellables)
        return box
    }

    // MARK: - Load

    func test_initialState_mapsHeaderTabsAndSummary() {
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertTrue(mockUseCase.getInitialStateCalled)
        XCTAssertEqual(box.latest?.headerTitle, "meditationHub.header.title".localized)
        XCTAssertEqual(box.latest?.tabs.map(\.title), [
            "meditationHub.tab.timer".localized,
            "meditationHub.tab.guided".localized
        ])
        XCTAssertEqual(box.latest?.selectedTab, .timer)
        XCTAssertTrue(box.latest?.showsTimerSection == true)
        XCTAssertFalse(box.latest?.showsGuidedSection == true)
        XCTAssertEqual(box.latest?.summary?.valueText, "7")
        XCTAssertEqual(
            box.latest?.summary?.noteText,
            String(format: "meditationHub.summary.noteFormat".localized, 7, 94)
        )
        XCTAssertEqual(box.latest?.presets.count, 3)
        XCTAssertEqual(box.latest?.guidedSessions.count, 4)
        XCTAssertEqual(box.latest?.guidedSessions.first?.downloadTitle, "meditationHub.guided.downloaded".localized)
    }

    func test_viewDidLoad_reloadsCatalogFromUseCase() {
        let box = observeState(sut.transform(input: makeInput()))

        mockUseCase.stubEntity = ILMeditationHubEntity(streakDays: 12, weeklyMinutes: 210)
        viewDidLoadSubject.send(())

        XCTAssertEqual(box.latest?.summary?.valueText, "12")
    }

    // MARK: - Tabs

    func test_tabSelected_guided_showsGuidedSectionOnly() {
        let box = observeState(sut.transform(input: makeInput()))
        viewDidLoadSubject.send(())

        tabSelectedSubject.send(.guided)

        XCTAssertEqual(box.latest?.selectedTab, .guided)
        XCTAssertFalse(box.latest?.showsTimerSection == true)
        XCTAssertTrue(box.latest?.showsGuidedSection == true)
        XCTAssertTrue(box.latest?.tabs[1].isSelected == true)
        XCTAssertFalse(box.latest?.tabs[0].isSelected == true)
    }

    func test_tabSelected_sameTab_keepsCurrentSelection() {
        let box = observeState(sut.transform(input: makeInput()))
        viewDidLoadSubject.send(())

        tabSelectedSubject.send(.timer)

        XCTAssertEqual(box.latest?.selectedTab, .timer)
        XCTAssertTrue(box.latest?.tabs[0].isSelected == true)
    }

    // MARK: - Navigation

    func test_backTapped_firesGoBack() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationHubNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        backTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .goBack)
    }

    func test_presetTapped_firesOpenTimerConfigWithPresetID() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationHubNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        presetTappedSubject.send("preset.release")

        XCTAssertEqual(receivedEvent, .openTimerConfig(presetID: "preset.release"))
    }

    func test_customTimerTapped_firesOpenTimerConfigWithNilPreset() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationHubNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        customTimerTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openTimerConfig(presetID: nil))
    }

    func test_guidedTapped_firesStartGuidedSession() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationHubNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        guidedTappedSubject.send("guided.metta")

        XCTAssertEqual(receivedEvent, .startGuidedSession(sessionID: "guided.metta"))
    }

    func test_summaryTapped_firesOpenStats() {
        _ = sut.transform(input: makeInput())
        var receivedEvent: ILMeditationHubNavEvent?
        sut.navigationEventPublisher
            .sink { receivedEvent = $0 }
            .store(in: &cancellables)

        summaryTappedSubject.send(())

        XCTAssertEqual(receivedEvent, .openStats)
    }

    // MARK: - Download

    func test_downloadTapped_callsUseCaseWithSessionID() async {
        _ = sut.transform(input: makeInput())
        let downloadCompleted = expectation(description: "downloadGuidedMeditation called")
        mockUseCase.onDownload = { downloadCompleted.fulfill() }

        downloadTappedSubject.send("guided.relax")

        await fulfillment(of: [downloadCompleted], timeout: 1)
        XCTAssertTrue(mockUseCase.downloadCalled)
        XCTAssertEqual(mockUseCase.lastDownloadID, "guided.relax")
    }

    // MARK: - Heatmap intensity mapping

    func test_dailyMinutes_areNormalisedToIntensitiesAgainstPeak() {
        mockUseCase.stubEntity = ILMeditationHubEntity(
            dailyMinutes: [0, 15, 30, 15]
        )
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertEqual(box.latest?.summary?.intensities, [0, 0.5, 1.0, 0.5])
    }

    func test_dailyMinutes_shortSitsKeepAMinimumVisibleIntensity() {
        mockUseCase.stubEntity = ILMeditationHubEntity(
            dailyMinutes: [5, 40]
        )
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        // 5/40 = 0.125 → nâng lên sàn 0.35; 40/40 = 1.0.
        XCTAssertEqual(box.latest?.summary?.intensities, [0.35, 1.0])
    }

    func test_noPracticeMinute_yieldsZeroIntensities() {
        mockUseCase.stubEntity = ILMeditationHubEntity(
            dailyMinutes: [0, 0, 0]
        )
        let box = observeState(sut.transform(input: makeInput()))

        viewDidLoadSubject.send(())

        XCTAssertEqual(box.latest?.summary?.intensities, [0, 0, 0])
    }
}

// MARK: - ILMeditationHubUseCaseImpl (real catalog + stub)

final class ILMeditationHubUseCaseTests: XCTestCase {

    private let sut = ILMeditationHubUseCaseImpl()

    func test_getInitialState_returnsThreePresetsAndFourGuidedSessions() {
        let entity = sut.getInitialState()
        XCTAssertEqual(entity.presets.count, 3)
        XCTAssertEqual(entity.guidedSessions.count, 4)
        XCTAssertEqual(entity.presets.map(\.minutes), [15, 30, 45])
        XCTAssertEqual(entity.dailyMinutes.count, 84)
    }

    func test_getInitialState_presetNamesAreResolvedFromLocalization() {
        let entity = sut.getInitialState()
        XCTAssertFalse(entity.presets[0].name.isEmpty)
        XCTAssertEqual(entity.presets[0].name, "meditationHub.preset.morning.name".localized)
    }

    func test_downloadGuidedMeditation_isAStubThatDoesNotThrow() async throws {
        // The real download needs network + local storage — out of scope for il-screen-builder.
        try await sut.downloadGuidedMeditation(id: "guided.relax")
    }
}

// MARK: - Helpers

private final class StateBox {
    var latest: ILMeditationHubStateModel?
}

// MARK: - Mock ILMeditationHubUseCase

final class MockILMeditationHubUseCase: ILMeditationHubUseCase {
    var stubEntity = ILMeditationHubEntity(
        streakDays: 7,
        weeklyMinutes: 94,
        dailyMinutes: [0, 15, 30, 15],
        presets: [
            ILMeditationHubPresetEntity(id: "preset.morning", name: "Thiền sáng", minutes: 15, subtitle: "rừng thiền"),
            ILMeditationHubPresetEntity(id: "preset.release", name: "Thiền buông thư", minutes: 30, subtitle: "tiếng mưa"),
            ILMeditationHubPresetEntity(id: "preset.sitting", name: "Tọa thiền", minutes: 45, subtitle: "im lặng")
        ],
        guidedSessions: [
            ILMeditationHubGuidedEntity(
                id: "guided.breath", method: "Quán niệm hơi thở", name: "Thiền hơi thở buổi sáng",
                teacher: "Thầy Minh Đạo", minutes: 12, summary: "Theo dõi hơi thở", isDownloaded: true
            ),
            ILMeditationHubGuidedEntity(
                id: "guided.relax", method: "Thiền buông thư", name: "Buông thư toàn thân",
                teacher: "Sư cô Tâm Nguyện", minutes: 20, summary: "Thả lỏng", isDownloaded: false
            ),
            ILMeditationHubGuidedEntity(
                id: "guided.metta", method: "Thiền tâm từ", name: "Rải tâm từ",
                teacher: "Sư Khánh Hỷ", minutes: 15, summary: "Gửi lòng thương", isDownloaded: false
            ),
            ILMeditationHubGuidedEntity(
                id: "guided.bodyscan", method: "Thiền quét cơ thể", name: "Quét cơ thể 10 phút",
                teacher: "Thầy Minh Đạo", minutes: 10, summary: "Nhận biết cảm giác", isDownloaded: false
            )
        ]
    )

    var getInitialStateCalled = false
    func getInitialState() -> ILMeditationHubEntity {
        getInitialStateCalled = true
        return stubEntity
    }

    var downloadCalled = false
    var lastDownloadID: String?
    var onDownload: (() -> Void)?
    func downloadGuidedMeditation(id: String) async throws {
        downloadCalled = true
        lastDownloadID = id
        onDownload?()
    }
}
