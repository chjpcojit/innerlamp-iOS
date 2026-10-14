//
//  ILAlertTests.swift
//  InnerLampTests
//

import XCTest
import UIKit
@testable import InnerLamp

@MainActor
final class ILAlertTests: XCTestCase {

    private let action = ILAlertAction(title: "Retry")

    private var window: UIWindow!
    private var hostViewController: UIViewController!

    override func setUpWithError() throws {
        try super.setUpWithError()
        hostViewController = UIViewController()
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        window = UIWindow(windowScene: try XCTUnwrap(scene, "Tests need the host app's window scene"))
        window.rootViewController = hostViewController
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        hostViewController = nil
        super.tearDown()
    }

    // MARK: - ILAlert model

    func test_autoDismissDelay_onlyToastAndSnackbarSelfDismiss() {
        XCTAssertEqual(ILAlert.toast(title: "t", message: nil).autoDismissDelay, 3.2)
        XCTAssertEqual(ILAlert.success(title: "t", message: nil).autoDismissDelay, 3.2)
        XCTAssertEqual(ILAlert.snackbar(message: "m", action: action).autoDismissDelay, 3.2)
        XCTAssertNil(ILAlert.banner(title: "t", message: nil, primary: action, secondary: nil).autoDismissDelay)
        XCTAssertNil(ILAlert.sheet(title: "t", message: "m", errorCode: nil, primary: action, secondary: nil).autoDismissDelay)
        XCTAssertNil(ILAlert.dialog(title: "t", message: "m", primary: action, secondary: nil).autoDismissDelay)
        XCTAssertNil(ILAlert.confirm(title: "t", message: "m", cancel: action, confirm: action).autoDismissDelay)
        XCTAssertNil(ILAlert.fullScreen(title: "t", subtitle: nil, message: "m", errorCode: nil, primary: action, secondary: nil).autoDismissDelay)
    }

    func test_isOverlay_floatingKindsOnly() {
        XCTAssertTrue(ILAlert.toast(title: "t", message: nil).isOverlay)
        XCTAssertTrue(ILAlert.success(title: "t", message: nil).isOverlay)
        XCTAssertTrue(ILAlert.banner(title: "t", message: nil, primary: action, secondary: nil).isOverlay)
        XCTAssertTrue(ILAlert.snackbar(message: "m", action: nil).isOverlay)
        XCTAssertFalse(ILAlert.sheet(title: "t", message: "m", errorCode: "E1", primary: action, secondary: nil).isOverlay)
        XCTAssertFalse(ILAlert.dialog(title: "t", message: "m", primary: action, secondary: nil).isOverlay)
        XCTAssertFalse(ILAlert.confirm(title: "t", message: "m", cancel: action, confirm: action).isOverlay)
        XCTAssertFalse(ILAlert.fullScreen(title: "t", subtitle: nil, message: "m", errorCode: nil, primary: action, secondary: nil).isOverlay)
    }

    // MARK: - ILAlertPresenter

    func test_show_toast_addsOverlayToWindow() {
        let sut = ILAlertPresenter()

        sut.show(.toast(title: "Offline", message: nil), from: hostViewController)

        XCTAssertEqual(overlays().count, 1)
        XCTAssertTrue(overlays().first is ILToastView)
    }

    func test_show_success_addsToastOverlayToWindow() {
        let sut = ILAlertPresenter()

        sut.show(.success(title: "Saved", message: nil), from: hostViewController)

        XCTAssertEqual(overlays().count, 1)
        XCTAssertTrue(overlays().first is ILToastView)
    }

    func test_show_secondOverlay_replacesFirst() {
        let sut = ILAlertPresenter()
        sut.show(.toast(title: "Offline", message: nil), from: hostViewController)

        sut.show(.snackbar(message: "Download failed", action: action), from: hostViewController)

        let first = overlays().first { $0 is ILToastView }
        XCTAssertEqual(first?.isDismissing, true, "Previous overlay should be dismissing")
        XCTAssertTrue(overlays().contains { $0 is ILSnackbarView })
    }

    func test_dismissOverlay_removesOverlayAndSkipsHandler() {
        let sut = ILAlertPresenter()
        var handlerCalled = false
        let tracked = ILAlertAction(title: "Retry") { handlerCalled = true }
        sut.show(.banner(title: "Share failed", message: nil, primary: tracked, secondary: nil), from: hostViewController)

        sut.dismissOverlay()
        wait(seconds: 0.4)

        XCTAssertTrue(overlays().isEmpty)
        XCTAssertFalse(handlerCalled, "Dismissing without tapping must not run an action handler")
    }

    func test_show_dialog_presentsModalOverHost() {
        let sut = ILAlertPresenter()

        sut.show(.dialog(title: "Session expired", message: "Log in again", primary: action, secondary: nil), from: hostViewController)

        XCTAssertTrue(hostViewController.presentedViewController is ILErrorDialogViewController)
        XCTAssertEqual(hostViewController.presentedViewController?.modalPresentationStyle, .overFullScreen)
    }

    func test_show_confirm_presentsConfirmDialogOverHost() {
        let sut = ILAlertPresenter()

        sut.show(.confirm(title: "Đăng xuất?", message: "m", cancel: action, confirm: action), from: hostViewController)

        XCTAssertTrue(hostViewController.presentedViewController is ILConfirmDialogViewController)
        XCTAssertEqual(hostViewController.presentedViewController?.modalPresentationStyle, .overFullScreen)
    }

    func test_show_sheetWhileDialogShown_presentsOnTopMost() {
        let sut = ILAlertPresenter()
        sut.show(.dialog(title: "t", message: "m", primary: action, secondary: nil), from: hostViewController)
        waitOneRunLoop()

        sut.show(.sheet(title: "t", message: "m", errorCode: "PAY_DECLINED_51", primary: action, secondary: nil), from: hostViewController)

        XCTAssertTrue(hostViewController.presentedViewController?.presentedViewController is ILErrorSheetViewController)
    }

    // MARK: - Helpers

    private func overlays() -> [ILAlertOverlayView] {
        window.subviews.compactMap { $0 as? ILAlertOverlayView }
    }

    /// Lets UIKit finish the in-flight presentation before presenting on top of it.
    private func waitOneRunLoop() {
        wait(seconds: 0.1)
    }

    private func wait(seconds: TimeInterval) {
        let done = expectation(description: "wait \(seconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { done.fulfill() }
        wait(for: [done], timeout: seconds + 1)
    }
}
