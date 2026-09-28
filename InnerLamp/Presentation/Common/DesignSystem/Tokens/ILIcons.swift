//
//  ILIcons.swift
//  InnerLamp
//

import UIKit

/// Every raster icon comes from `Assets.xcassets/Icons` — this file only loads by name
/// (`UIImage(named:)`), screens never call `UIImage(named:)` themselves. Adding an icon =
/// add the `.imageset` (see `DESIGN_SYSTEM.md` §7) and one constant here.
///
/// Two kinds of icon, and the rendering mode is decided here, not at the call site:
/// - **Template** (monochrome): loaded with `.alwaysTemplate`, the caller tints via `tintColor`.
/// - **Illustration** (full-color): loaded with `.alwaysOriginal`, never tinted.
public enum ILIcons {

    /// Icon not found in `Assets.xcassets/Icons` — crash early during development
    /// instead of silently rendering an empty image in the UI.
    private static func asset(_ name: String, renderingMode: UIImage.RenderingMode) -> UIImage {
        guard let image = UIImage(named: name, in: .main, compatibleWith: nil) else {
            fatalError("Missing icon asset '\(name)' in Assets.xcassets/Icons — add it there, never load images by name in a screen.")
        }
        return image.withRenderingMode(renderingMode)
    }

    private static func template(_ name: String) -> UIImage {
        asset(name, renderingMode: .alwaysTemplate)
    }

    private static func illustration(_ name: String) -> UIImage {
        asset(name, renderingMode: .alwaysOriginal)
    }

    // MARK: - Bottom Nav (template, 28×28)
    /// Center lamp of `ILBottomNavBar` — solid (normal state)
    public static let tabLampFilled = template("tab_lamp_filled")

    /// Center lamp of `ILBottomNavBar` — stroked (highlighted state)
    public static let tabLampOutline = template("tab_lamp_outline")

    // MARK: - Illustrations (full-color)
    /// Lamp + glow, 114×160 — Onboarding intro, Login header
    public static let onboardingLamp = illustration("onboarding_lamp")
}
