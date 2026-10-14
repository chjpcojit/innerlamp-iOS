//
//  ILAlert.swift
//  InnerLamp
//

import Foundation

/// One button on an error popup. Tapping it always dismisses the popup first, then runs `handler`.
public struct ILAlertAction {
    public let title: String
    public let handler: (() -> Void)?

    public init(title: String, handler: (() -> Void)? = nil) {
        self.title = title
        self.handler = handler
    }
}

/// The shared popups from the design handoff ("Popup lỗi" screen). Pick the kind by
/// severity — light errors come from the top, errors needing an action come from the bottom,
/// flow-blocking errors sit in the middle:
///
/// | Kind | When | Dismiss |
/// |---|---|---|
/// | `.toast` | Light error, no action needed | Auto after 3.2s, "×", swipe up |
/// | `.success` | Confirmation of a finished action (saved, deleted) — green toast | Auto after 3.2s, "×", swipe up |
/// | `.banner` | Error that needs a decision (2 buttons) | A button, swipe up |
/// | `.snackbar` | One-line error, at most one action | Auto after 3.2s, action, swipe down |
/// | `.sheet` | Error with long context + error code, 2 buttons | A button, tap scrim, swipe down |
/// | `.dialog` | Blocks the flow, user must pick one of two | A button only |
/// | `.confirm` | Asks to confirm a destructive choice (not an error) — system-alert look | A button, tap scrim |
/// | `.fullScreen` | Severe failure, the app cannot continue | A button or "×" |
///
/// Present with `ILAlertPresenter.shared.show(_:from:)`. All copy is passed in already
/// localized — the popups never hardcode text.
public enum ILAlert {
    case toast(title: String, message: String?)
    /// Same top toast as `.toast`, in the green success tone.
    case success(title: String, message: String?)
    case banner(title: String, message: String?, primary: ILAlertAction, secondary: ILAlertAction?)
    case snackbar(message: String, action: ILAlertAction?)
    case sheet(title: String, message: String, errorCode: String?, primary: ILAlertAction, secondary: ILAlertAction?)
    case dialog(title: String, message: String, primary: ILAlertAction, secondary: ILAlertAction?)
    /// "Đăng xuất?"-style confirmation: compact card, title + message, then a cancel cell and a
    /// destructive confirm cell side by side. Unlike `.dialog` it is not an error popup, so it has
    /// no "!" badge and a tap on the scrim cancels.
    case confirm(title: String, message: String, cancel: ILAlertAction, confirm: ILAlertAction)
    /// `subtitle` is the small italic line under the title (e.g. "Something went wrong").
    /// `errorCode` is rendered together with the time the popup appeared (`CODE · HH:mm`).
    case fullScreen(title: String, subtitle: String?, message: String, errorCode: String?, primary: ILAlertAction, secondary: ILAlertAction?)

    /// Time a self-dismissing popup stays on screen (design: `setTimeout(..., 3200)`).
    public static let autoDismissInterval: TimeInterval = 3.2

    /// `nil` when the popup stays until the user acts.
    public var autoDismissDelay: TimeInterval? {
        switch self {
        case .toast, .success, .snackbar: return Self.autoDismissInterval
        case .banner, .sheet, .dialog, .confirm, .fullScreen: return nil
        }
    }

    /// Floating, non-blocking popups are laid over the window (touches outside pass through);
    /// the others are presented modally and block the screen underneath.
    public var isOverlay: Bool {
        switch self {
        case .toast, .success, .banner, .snackbar: return true
        case .sheet, .dialog, .confirm, .fullScreen: return false
        }
    }
}
