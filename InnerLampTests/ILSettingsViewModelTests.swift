//
//  ILSettingsViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILSettingsViewModelTests: XCTestCase {

    private var mockUseCase: MockILSettingsUseCase!
    private var sut: ILSettingsViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var viewDidLoadSubject: PassthroughSubject<Void, Never>!
    private var viewWillAppearSubject: PassthroughSubject<Void, Never>!
    private var backTappedSubject: PassthroughSubject<Void, Never>!
    private var profileTappedSubject: PassthroughSubject<Void, Never>!
    private var bellToggleChangedSubject: PassthroughSubject<Bool, Never>!
    private var fastDayToggleChangedSubject: PassthroughSubject<Bool, Never>!
    private var bellSoundTappedSubject: PassthroughSubject<Void, Never>!
    private var fontScaleChangedSubject: PassthroughSubject<Double, Never>!
    private var bilingualToggleChangedSubject: PassthroughSubject<Bool, Never>!
    private var darkModeTappedSubject: PassthroughSubject<Void, Never>!
    private var downloadsTappedSubject: PassthroughSubject<Void, Never>!
    private var languageTappedSubject: PassthroughSubject<Void, Never>!
    private var helpTappedSubject: PassthroughSubject<Void, Never>!
    private var hideJournalToggleChangedSubject: PassthroughSubject<Bool, Never>!
    private var exportDataTappedSubject: PassthroughSubject<Void, Never>!
    private var offlineTappedSubject: PassthroughSubject<Void, Never>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockILSettingsUseCase()
        sut = ILSettingsViewModel(useCase: mockUseCase)
        cancellables = []

        viewDidLoadSubject = PassthroughSubject<Void, Never>()
        viewWillAppearSubject = PassthroughSubject<Void, Never>()
        backTappedSubject = PassthroughSubject<Void, Never>()
        profileTappedSubject = PassthroughSubject<Void, Never>()
        bellToggleChangedSubject = PassthroughSubject<Bool, Never>()
        fastDayToggleChangedSubject = PassthroughSubject<Bool, Never>()
        bellSoundTappedSubject = PassthroughSubject<Void, Never>()
        fontScaleChangedSubject = PassthroughSubject<Double, Never>()
        bilingualToggleChangedSubject = PassthroughSubject<Bool, Never>()
        darkModeTappedSubject = PassthroughSubject<Void, Never>()
        downloadsTappedSubject = PassthroughSubject<Void, Never>()
        languageTappedSubject = PassthroughSubject<Void, Never>()
        helpTappedSubject = PassthroughSubject<Void, Never>()
        hideJournalToggleChangedSubject = PassthroughSubject<Bool, Never>()
        exportDataTappedSubject = PassthroughSubject<Void, Never>()
        offlineTappedSubject = PassthroughSubject<Void, Never>()
    }

    override func tearDown() {
        cancellables = nil
        viewDidLoadSubject = nil
        viewWillAppearSubject = nil
        backTappedSubject = nil
        profileTappedSubject = nil
        bellToggleChangedSubject = nil
        fastDayToggleChangedSubject = nil
        bellSoundTappedSubject = nil
        fontScaleChangedSubject = nil
        bilingualToggleChangedSubject = nil
        darkModeTappedSubject = nil
        downloadsTappedSubject = nil
        languageTappedSubject = nil
        helpTappedSubject = nil
        hideJournalToggleChangedSubject = nil
        exportDataTappedSubject = nil
        offlineTappedSubject = nil
        sut = nil
        mockUseCase = nil
        super.tearDown()
    }

    private func makeInput() -> ILSettingsViewModel.Input {
        ILSettingsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            backTapped: backTappedSubject.eraseToAnyPublisher(),
            profileTapped: profileTappedSubject.eraseToAnyPublisher(),
            bellToggleChanged: bellToggleChangedSubject.eraseToAnyPublisher(),
            fastDayToggleChanged: fastDayToggleChangedSubject.eraseToAnyPublisher(),
            bellSoundTapped: bellSoundTappedSubject.eraseToAnyPublisher(),
            fontScaleChanged: fontScaleChangedSubject.eraseToAnyPublisher(),
            bilingualToggleChanged: bilingualToggleChangedSubject.eraseToAnyPublisher(),
            darkModeTapped: darkModeTappedSubject.eraseToAnyPublisher(),
            downloadsTapped: downloadsTappedSubject.eraseToAnyPublisher(),
            languageTapped: languageTappedSubject.eraseToAnyPublisher(),
            helpTapped: helpTappedSubject.eraseToAnyPublisher(),
            hideJournalToggleChanged: hideJournalToggleChangedSubject.eraseToAnyPublisher(),
            exportDataTapped: exportDataTappedSubject.eraseToAnyPublisher(),
            offlineTapped: offlineTappedSubject.eraseToAnyPublisher()
        )
    }

    private func captureLatestState(_ output: ILSettingsViewModel.Output) -> () -> ILSettingsStateModel? {
        var latest: ILSettingsStateModel?
        output.state
            .sink { if case .success(let model) = $0 { latest = model } }
            .store(in: &cancellables)
        return { latest }
    }

    private func captureNavEvents() -> () -> [ILSettingsNavEvent] {
        var events: [ILSettingsNavEvent] = []
        sut.navigationEventPublisher
            .sink { events.append($0) }
            .store(in: &cancellables)
        return { events }
    }

    // MARK: - viewDidLoad
    func test_viewDidLoad_mapsEntityToStateModel() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertGreaterThanOrEqual(mockUseCase.getSettingsCallCount, 2) // init + viewDidLoad
        let state = latest()
        XCTAssertEqual(state?.accountInitial, "A")
        XCTAssertEqual(state?.accountName, "Nguyễn Bình An")
        XCTAssertEqual(
            state?.accountSubtitle,
            String(format: "settings.account.subtitle".localized, "Tâm Minh", "+84 912 345 678")
        )
        XCTAssertEqual(state?.bellEnabled, true)
        XCTAssertEqual(state?.bellScheduleText, "05:30 · 12:00 · 21:30")
        XCTAssertEqual(state?.fastDayReminderEnabled, true)
        XCTAssertEqual(state?.bellSoundTitle, "settings.bellSound.bronzeBell".localized)
        XCTAssertEqual(state?.scriptureFontScale ?? 0, 0.62, accuracy: 0.0001)
        XCTAssertEqual(state?.bilingualEnabled, false)
        XCTAssertEqual(state?.themeTitle, "settings.theme.system".localized)
        XCTAssertEqual(
            state?.downloadsSummary,
            String(format: "settings.row.downloads.sub".localized, 8, 412)
        )
        XCTAssertEqual(
            state?.languageSummary,
            String(format: "settings.row.language.sub".localized, "Tiếng Việt", "vừa")
        )
        XCTAssertEqual(state?.hideJournalFromSangha, false)
        XCTAssertEqual(state?.versionText, String(format: "settings.footer.version".localized, "1.4"))
    }

    func test_viewDidLoad_withoutDharmaName_fallsBackToRole() {
        mockUseCase.settings.account.dharmaName = ""
        sut = ILSettingsViewModel(useCase: mockUseCase)
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        viewDidLoadSubject.send(())

        XCTAssertEqual(latest()?.accountSubtitle, "settings.account.role.fallback".localized)
    }

    // MARK: - Toggle / slider state
    func test_bellToggleChanged_updatesBellEnabled() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        bellToggleChangedSubject.send(false)

        XCTAssertEqual(latest()?.bellEnabled, false)
    }

    func test_fastDayToggleChanged_updatesFastDayReminderEnabled() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        fastDayToggleChangedSubject.send(false)

        XCTAssertEqual(latest()?.fastDayReminderEnabled, false)
    }

    func test_bilingualToggleChanged_updatesBilingualEnabled() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        bilingualToggleChangedSubject.send(true)

        XCTAssertEqual(latest()?.bilingualEnabled, true)
    }

    func test_hideJournalToggleChanged_updatesHideJournalFromSangha() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        hideJournalToggleChangedSubject.send(true)

        XCTAssertEqual(latest()?.hideJournalFromSangha, true)
    }

    func test_fontScaleChanged_updatesScriptureFontScale() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)

        fontScaleChangedSubject.send(0.9)

        XCTAssertEqual(latest()?.scriptureFontScale ?? 0, 0.9, accuracy: 0.0001)
    }

    // MARK: - Navigation
    func test_backTapped_firesGoBack() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        backTappedSubject.send(())

        XCTAssertEqual(events(), [.goBack])
    }

    func test_profileTapped_firesOpenProfile() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        profileTappedSubject.send(())

        XCTAssertEqual(events(), [.openProfile])
    }

    func test_bellSoundTapped_firesOpenBellSound() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        bellSoundTappedSubject.send(())

        XCTAssertEqual(events(), [.openBellSound])
    }

    func test_darkModeTapped_firesOpenDarkMode() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        darkModeTappedSubject.send(())

        XCTAssertEqual(events(), [.openDarkMode])
    }

    func test_downloadsTapped_firesOpenDownloads() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        downloadsTappedSubject.send(())

        XCTAssertEqual(events(), [.openDownloads])
    }

    func test_languageTapped_firesOpenLanguage() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        languageTappedSubject.send(())

        XCTAssertEqual(events(), [.openLanguage])
    }

    func test_helpTapped_firesOpenHelp() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        helpTappedSubject.send(())

        XCTAssertEqual(events(), [.openHelp])
    }

    func test_exportDataTapped_firesOpenExportData() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        exportDataTappedSubject.send(())

        XCTAssertEqual(events(), [.openExportData])
    }

    func test_offlineTapped_firesOpenOffline() {
        _ = sut.transform(input: makeInput())
        let events = captureNavEvents()

        offlineTappedSubject.send(())

        XCTAssertEqual(events(), [.openOffline])
    }

    // MARK: - Formatting helpers
    func test_initial_usesLastWordFirstLetterUppercased() {
        XCTAssertEqual(ILSettingsViewModel.initial(of: "Nguyễn Bình An"), "A")
        XCTAssertEqual(ILSettingsViewModel.initial(of: "an"), "A")
        XCTAssertEqual(ILSettingsViewModel.initial(of: ""), "")
    }

    func test_themeTitle_mapsEachMode() {
        XCTAssertEqual(ILSettingsViewModel.themeTitle(.system), "settings.theme.system".localized)
        XCTAssertEqual(ILSettingsViewModel.themeTitle(.light), "settings.theme.light".localized)
        XCTAssertEqual(ILSettingsViewModel.themeTitle(.dark), "settings.theme.dark".localized)
    }

    // MARK: - viewWillAppear
    func test_viewWillAppear_refreshesThemeAndLanguageSummaryWithoutResettingToggles() {
        let output = sut.transform(input: makeInput())
        let latest = captureLatestState(output)
        bellToggleChangedSubject.send(false)

        mockUseCase.settings.theme = .dark
        mockUseCase.settings.language = .english
        mockUseCase.settings.scriptureFontSize = .extraLarge
        viewWillAppearSubject.send(())

        let state = latest()
        XCTAssertEqual(state?.themeTitle, "settings.theme.dark".localized)
        XCTAssertEqual(
            state?.languageSummary,
            String(format: "settings.row.language.sub".localized, "English", "rất lớn")
        )
        XCTAssertEqual(state?.bellEnabled, false)
    }

    func test_bellSoundTitle_mapsBronzeBell() {
        XCTAssertEqual(
            ILSettingsViewModel.bellSoundTitle(.bronzeBell),
            "settings.bellSound.bronzeBell".localized
        )
    }
}

// MARK: - Mock ILSettingsUseCase
final class MockILSettingsUseCase: ILSettingsUseCase {
    var settings: ILSettingsEntity
    private(set) var getSettingsCallCount = 0

    init() {
        settings = ILSettingsEntity(
            account: ILSettingsAccountEntity(
                fullName: "Nguyễn Bình An",
                dharmaName: "Tâm Minh",
                phoneNumber: "+84 912 345 678"
            ),
            bellEnabled: true,
            bellTimes: [
                ILSettingsBellEntity(hour: 5, minute: 30),
                ILSettingsBellEntity(hour: 12, minute: 0),
                ILSettingsBellEntity(hour: 21, minute: 30)
            ],
            fastDayReminderEnabled: true,
            bellSound: .bronzeBell,
            scriptureFontScale: 0.62,
            bilingualEnabled: false,
            theme: .system,
            downloadsCount: 8,
            downloadsSizeMB: 412,
            hideJournalFromSangha: false,
            appVersion: "1.4"
        )
    }

    func getSettings() -> ILSettingsEntity {
        getSettingsCallCount += 1
        return settings
    }
}
