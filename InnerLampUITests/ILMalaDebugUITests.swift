//
//  ILMalaDebugUITests.swift
//  InnerLampUITests
//
//  TEMPORARY diagnostic tests — remove before finishing.
//

import XCTest

final class ILMalaDebugUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func scrollToMala(_ app: XCUIApplication) {
        let homeTitle = app.staticTexts["Tràng hạt · Niệm Phật"]
        _ = homeTitle.waitForExistence(timeout: 15)
        for _ in 0..<6 where !app.buttons["Toàn màn hình"].firstMatch.isHittable {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
    }

    @MainActor
    private func stringAttachment(_ string: String, name: String) {
        let attachment = XCTAttachment(string: string)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Rapid double-tap the "Toàn màn hình" link, then count how many backs are needed.
    @MainActor
    func testDoubleTapFullscreen() throws {
        let app = XCUIApplication()
        app.launch()
        scrollToMala(app)

        let fullscreen = app.buttons["Toàn màn hình"].firstMatch
        let malaTitle = app.staticTexts["Niệm Phật"]

        // Two taps as fast as XCUITest allows.
        fullscreen.tap()
        fullscreen.tap()
        _ = malaTitle.waitForExistence(timeout: 5)
        attach(app, name: "50-after-double-tap")

        var backs = 0
        // Tap back up to 4 times, counting until we reach home.
        for _ in 0..<4 {
            let back = app.buttons["‹"].firstMatch
            guard back.waitForExistence(timeout: 2), back.isHittable else { break }
            back.tap()
            backs += 1
            Thread.sleep(forTimeInterval: 0.6)
            if app.buttons["Toàn màn hình"].firstMatch.exists { break }
        }
        attach(app, name: "51-after-backs")

        stringAttachment("BACKS_NEEDED=\(backs)", name: "result")
    }

    /// Tap "Toàn màn hình" twice with a normal human-ish gap.
    @MainActor
    func testTwoTapsWithGap() throws {
        let app = XCUIApplication()
        app.launch()
        scrollToMala(app)

        let fullscreen = app.buttons["Toàn màn hình"].firstMatch
        let malaTitle = app.staticTexts["Niệm Phật"]

        fullscreen.tap()
        _ = malaTitle.waitForExistence(timeout: 5)
        // Tap the (now offscreen) link again while Mala is on top — should be a no-op.
        fullscreen.tap()
        Thread.sleep(forTimeInterval: 0.6)
        attach(app, name: "52-after-second-tap")

        var backs = 0
        for _ in 0..<4 {
            let back = app.buttons["‹"].firstMatch
            guard back.waitForExistence(timeout: 2), back.isHittable else { break }
            back.tap()
            backs += 1
            Thread.sleep(forTimeInterval: 0.6)
            if app.buttons["Toàn màn hình"].firstMatch.exists { break }
        }
        stringAttachment("BACKS_NEEDED=\(backs)", name: "result")
    }
}
