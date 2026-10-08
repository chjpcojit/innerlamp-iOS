//
//  ILLanguageViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILLanguageViewModelTests: XCTestCase {

    private var mockUseCase: MockILLanguageUseCase!
    private var sut: ILLanguageViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var languageSelectedSubject: PassthroughSubject<ILAppLanguage, Never>!
    private var fontSizeSelectedSubject: PassthroughSubject<ILScriptureFontSize, Never>!
    private var themeSelectedSubject: PassthroughSubject<ILSettingsThemeMode, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILLanguageUseCase()
        sut = ILLanguageViewModel(useCase: mockUseCase)
        cancellables = []
        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        languageSelectedSubject = PassthroughSubject<ILAppLanguage, Never>()
        fontSizeSelectedSubject = PassthroughSubject<ILScriptureFontSize, Never>()
        themeSelectedSubject = PassthroughSubject<ILSettingsThemeMode, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        backTappedSubject = nil
        languageSelectedSubject = nil
        fontSizeSelectedSubject = nil
        themeSelectedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILLanguageViewModel.Input {
        ILLanguageViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            languageSelected: languageSelectedSubject.eraseToAnyPublisher(),
            fontSizeSelected: fontSizeSelectedSubject.eraseToAnyPublisher(),
            themeSelected: themeSelectedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILLanguageViewModel.Output) -> () -> ILLanguageStateModel? {
        var latest: ILLanguageStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_mapsPreferencesToStateModel() {
        mockUseCase.preferences = ILLanguageEntity(language: .english, fontSize: .large, theme: .dark)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.languageOptions.map(\.language), [.vietnamese, .english, .traditionalChinese])
        XCTAssertEqual(state?.languageOptions.filter(\.isSelected).map(\.language), [.english])
        XCTAssertEqual(state?.fontSizeOptions.count, 4)
        XCTAssertEqual(state?.fontSizeOptions.filter(\.isSelected).map(\.fontSize), [.large])
        XCTAssertEqual(state?.themeOptions.map(\.theme), [.light, .dark, .system])
        XCTAssertEqual(state?.themeOptions.filter(\.isSelected).map(\.theme), [.dark])
        XCTAssertEqual(state?.previewFontIndex, 2)
        XCTAssertEqual(state?.previewText, "language.preview.sample".localized)
    }

    // MARK: - Selection
    func test_languageSelected_appliesAndUpdatesSelection() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        languageSelectedSubject.send(.traditionalChinese)

        XCTAssertEqual(mockUseCase.appliedPreferences.last?.language, .traditionalChinese)
        XCTAssertEqual(latest()?.languageOptions.filter(\.isSelected).map(\.language), [.traditionalChinese])
    }

    func test_fontSizeSelected_updatesPreviewIndex() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        fontSizeSelectedSubject.send(.extraLarge)

        XCTAssertEqual(mockUseCase.appliedPreferences.last?.fontSize, .extraLarge)
        XCTAssertEqual(latest()?.previewFontIndex, 3)
    }

    func test_themeSelected_appliesTheme() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        themeSelectedSubject.send(.dark)

        XCTAssertEqual(mockUseCase.appliedPreferences.last?.theme, .dark)
        XCTAssertEqual(latest()?.themeOptions.filter(\.isSelected).map(\.theme), [.dark])
    }

    func test_selectingCurrentValue_doesNotApplyAgain() {
        _ = sut.transform(input: makeInput())

        languageSelectedSubject.send(.vietnamese) // already the default

        XCTAssertTrue(mockUseCase.appliedPreferences.isEmpty)
    }

    // MARK: - Navigation
    func test_backTapped_emitsGoBack() {
        var events: [ILLanguageNavEvent] = []
        sut.navigationEventPublisher.sink { events.append($0) }.store(in: &cancellables)
        _ = sut.transform(input: makeInput())

        backTappedSubject.send(())

        XCTAssertEqual(events, [.goBack])
    }
}

// MARK: - Mock ILLanguageUseCase
final class MockILLanguageUseCase: ILLanguageUseCase {
    var preferences = ILLanguageEntity()
    private(set) var appliedPreferences: [ILLanguageEntity] = []

    func currentPreferences() -> ILLanguageEntity { preferences }

    func apply(_ preferences: ILLanguageEntity) {
        appliedPreferences.append(preferences)
        self.preferences = preferences
    }
}
