//
//  ILLanguageUseCaseTests.swift
//  InnerLampTests
//

import XCTest
import UIKit
@testable import InnerLamp

@MainActor
final class ILLanguageUseCaseTests: XCTestCase {

    private var defaults: MockUserDefaultsService!
    private var themeService: MockThemeService!
    private var sut: ILLanguageUseCaseImpl!

    override func setUp() {
        super.setUp()
        defaults = MockUserDefaultsService()
        themeService = MockThemeService()
        sut = ILLanguageUseCaseImpl(userDefaultsService: defaults, themeService: themeService)
    }

    override func tearDown() {
        sut = nil
        themeService = nil
        defaults = nil
        super.tearDown()
    }

    func test_currentPreferences_withNothingStored_returnsDefaults() {
        XCTAssertEqual(
            sut.currentPreferences(),
            ILLanguageEntity(language: .vietnamese, fontSize: .medium, theme: .system)
        )
    }

    func test_currentPreferences_readsThemeFromThemeService() {
        themeService.currentMode = .dark

        XCTAssertEqual(sut.currentPreferences().theme, .dark)
    }

    func test_apply_persistsLanguageAndFontSize_andRoundTrips() {
        sut.apply(ILLanguageEntity(language: .english, fontSize: .extraLarge, theme: .light))

        let restored = sut.currentPreferences()
        XCTAssertEqual(restored.language, .english)
        XCTAssertEqual(restored.fontSize, .extraLarge)
    }

    func test_apply_setsThemeModeOnThemeService() {
        sut.apply(ILLanguageEntity(language: .vietnamese, fontSize: .medium, theme: .dark))

        XCTAssertEqual(themeService.setModeCalls, [.dark])
    }
}

private final class MockThemeService: ThemeService {
    var currentMode: ILThemeMode = .system
    private(set) var setModeCalls: [ILThemeMode] = []

    func setMode(_ mode: ILThemeMode) {
        currentMode = mode
        setModeCalls.append(mode)
    }

    func apply(to window: UIWindow?) {}
}
