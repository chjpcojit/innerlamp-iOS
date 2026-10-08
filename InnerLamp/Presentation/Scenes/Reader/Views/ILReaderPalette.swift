//
//  ILReaderPalette.swift
//  InnerLamp
//

import UIKit

/// Colors of one reading background ("Mặc định", "Vàng cát", "Đen OLED"). The default theme uses
/// the adaptive design-system tokens; the other two are fixed palettes (`ILColors.Reader`).
struct ILReaderPalette {
    let background: UIColor
    let ink: UIColor
    /// Secondary text (section headings, glosses, time labels, hints).
    let subtle: UIColor
    /// Hairlines and unselected borders.
    let line: UIColor
    /// Settings panel fill.
    let panel: UIColor
    /// Forced appearance so adaptive tokens (nav bar, chips) stay legible on the fixed backgrounds.
    let interfaceStyle: UIUserInterfaceStyle

    /// Index order matches `ILReaderViewModel` theme keys: default, sand, OLED.
    static func palette(forThemeIndex index: Int) -> ILReaderPalette {
        switch index {
        case 1:
            return ILReaderPalette(
                background: ILColors.Reader.sandBackground,
                ink: ILColors.Reader.sandInk,
                subtle: ILColors.Reader.sandInk.withAlphaComponent(0.55),
                line: ILColors.Reader.sandInk.withAlphaComponent(0.14),
                panel: ILColors.Reader.sandPanel,
                interfaceStyle: .light
            )
        case 2:
            return ILReaderPalette(
                background: ILColors.Reader.oledBackground,
                ink: ILColors.Reader.oledInk,
                subtle: ILColors.Reader.oledInk.withAlphaComponent(0.5),
                line: ILColors.Reader.oledInk.withAlphaComponent(0.14),
                panel: ILColors.Reader.oledPanel,
                interfaceStyle: .dark
            )
        default:
            return ILReaderPalette(
                background: ILColors.canvasWarm,
                ink: ILColors.ink,
                subtle: ILColors.inkSubtle,
                line: ILColors.ink.withAlphaComponent(0.08),
                panel: ILColors.surface,
                interfaceStyle: .unspecified
            )
        }
    }

    /// Swatch fill / ink shown on the theme tile for theme `index` (independent of the active theme).
    static func swatch(forThemeIndex index: Int) -> (background: UIColor, ink: UIColor, line: UIColor) {
        let palette = palette(forThemeIndex: index)
        return (palette.background, palette.ink, palette.line)
    }
}
