//
//  ILLoadingPlaceholderTests.swift
//  InnerLampTests
//

import XCTest
import UIKit
@testable import InnerLamp

@MainActor
final class ILLoadingPlaceholderTests: XCTestCase {

    private var window: UIWindow!

    override func setUpWithError() throws {
        try super.setUpWithError()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
    }

    override func tearDownWithError() throws {
        window.isHidden = true
        window = nil
        try super.tearDownWithError()
    }

    // MARK: - ILSkeletonLoadingView

    func test_skeleton_isHiddenByDefault() {
        let sut = ILSkeletonLoadingView()

        XCTAssertTrue(sut.isHidden)
        XCTAssertFalse(sut.isLoading)
    }

    func test_skeleton_usesLocalizedCaptionByDefault() {
        let sut = ILSkeletonLoadingView()

        XCTAssertEqual(sut.caption, "loading.caption".localized)
        XCTAssertEqual(sut.accessibilityLabel, sut.caption)
    }

    func test_skeleton_setLoadingTrue_showsAndPulses() throws {
        let sut = ILSkeletonLoadingView()
        let container = try XCTUnwrap(window.rootViewController?.view)
        container.addSubview(sut)

        sut.setLoading(true, animated: false)

        XCTAssertFalse(sut.isHidden)
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(sut.alpha, 1)
        if !UIAccessibility.isReduceMotionEnabled {
            XCTAssertFalse(pulsingLayerCount(in: sut) == 0, "Expected staggered pulse animations while loading")
        }
    }

    func test_skeleton_setLoadingFalse_hidesAndStopsPulsing() throws {
        let sut = ILSkeletonLoadingView()
        let container = try XCTUnwrap(window.rootViewController?.view)
        container.addSubview(sut)
        sut.setLoading(true, animated: false)

        sut.setLoading(false, animated: false)

        XCTAssertTrue(sut.isHidden)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(pulsingLayerCount(in: sut), 0)
    }

    // MARK: - ILLoadMoreFooterView

    func test_footer_hiddenState_hidesView() {
        let sut = ILLoadMoreFooterView()

        XCTAssertEqual(sut.state, .hidden)
        XCTAssertTrue(sut.isHidden)
    }

    func test_footer_loadingState_showsLoadingText() {
        let sut = ILLoadMoreFooterView(loadingText: "Loading", endText: "End")

        sut.state = .loading

        XCTAssertFalse(sut.isHidden)
        XCTAssertEqual(sut.accessibilityLabel, "Loading")
    }

    func test_footer_endState_showsEndText() {
        let sut = ILLoadMoreFooterView(loadingText: "Loading", endText: "End")

        sut.state = .end

        XCTAssertFalse(sut.isHidden)
        XCTAssertEqual(sut.accessibilityLabel, "End")
    }

    // MARK: - Helpers

    private func pulsingLayerCount(in view: UIView) -> Int {
        var count = 0
        var stack: [CALayer] = [view.layer]
        while let layer = stack.popLast() {
            if layer.animation(forKey: "ilSkeletonPulse") != nil { count += 1 }
            stack.append(contentsOf: layer.sublayers ?? [])
        }
        return count
    }
}
