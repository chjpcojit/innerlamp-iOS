//
//  InnerLampUITests.swift
//  InnerLampUITests
//
//  Created by ChjpCoj on 9/9/26.
//

import XCTest

final class InnerLampUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testDebugMalaFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let homeTitle = app.staticTexts["Tràng hạt · Niệm Phật"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 15), "Home not shown")

        // Reveal the mala section at the bottom with small drags (avoid overshooting).
        for _ in 0..<6 where !app.buttons["Toàn màn hình"].firstMatch.isHittable {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        attach(app, name: "01-home-mala")

        let fullscreen = app.buttons["Toàn màn hình"].firstMatch
        XCTAssertTrue(fullscreen.isHittable, "fullscreen link not found")
        fullscreen.tap()
        let malaTitle = app.staticTexts["Niệm Phật"]
        XCTAssertTrue(malaTitle.waitForExistence(timeout: 5), "Mala screen not shown")
        attach(app, name: "04-mala")

        // 1. Edge-swipe back.
        let edgeStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        let edgeEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        edgeStart.press(forDuration: 0.08, thenDragTo: edgeEnd)
        let goneAfterSwipe = malaTitle.waitForNonExistence(timeout: 3)
        attach(app, name: "05-after-edge-swipe")
        let swipeNote = "EDGESWIPE_POPPED=\(goneAfterSwipe)"

        // 2. Header back button.
        let back = app.buttons["‹"].firstMatch
        let backExists = back.exists
        if backExists { back.tap() }
        let goneAfterBack = malaTitle.waitForNonExistence(timeout: 5)
        attach(app, name: "06-after-back")

        // 3. Xong.
        let done = app.buttons["Xong"].firstMatch
        let doneExists = done.exists
        if doneExists { done.tap() }
        let goneAfterDone = malaTitle.waitForNonExistence(timeout: 5)

        let attachment = XCTAttachment(
            string: "\(swipeNote) BACK_EXISTS=\(backExists) BACK_POPPED=\(goneAfterBack) DONE_EXISTS=\(doneExists) DONE_POPPED=\(goneAfterDone)"
        )
        attachment.name = "result"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
