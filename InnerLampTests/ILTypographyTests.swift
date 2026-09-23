//
//  ILTypographyTests.swift
//  InnerLampTests
//
//  Created by ChjpCoj on 21/9/26.
//

import XCTest
import UIKit
@testable import InnerLamp

/// Guards the custom font registration declared under `UIAppFonts` in `Info.plist`.
/// `ILTypography` silently falls back to a system font when a PostScript name cannot be
/// resolved, so these tests assert the real faces are bundled and registered — otherwise a
/// missing/renamed font file would ship without any visible error.
final class ILTypographyTests: XCTestCase {

    // MARK: - PostScript names must resolve

    func test_allLoraPostScriptNames_resolve() {
        let names = [
            ILTypography.loraRegularName,
            ILTypography.loraMediumName,
            ILTypography.loraSemiBoldName,
            ILTypography.loraBoldName
        ]

        for name in names {
            XCTAssertNotNil(
                UIFont(name: name, size: 12),
                "Font '\(name)' is not registered. Check the file is bundled and listed in UIAppFonts."
            )
        }
    }

    func test_allBeVietnamProPostScriptNames_resolve() {
        let names = [
            ILTypography.beVietnamProRegularName,
            ILTypography.beVietnamProMediumName,
            ILTypography.beVietnamProSemiBoldName,
            ILTypography.beVietnamProBoldName
        ]

        for name in names {
            XCTAssertNotNil(
                UIFont(name: name, size: 12),
                "Font '\(name)' is not registered. Check the file is bundled and listed in UIAppFonts."
            )
        }
    }

    // MARK: - Presets must not fall back to a system font

    func test_loraResolver_returnsLoraFamily() {
        XCTAssertTrue(ILTypography.lora(size: 18).familyName.hasPrefix("Lora"))
        XCTAssertTrue(ILTypography.lora(size: 18, weight: .semibold).familyName.hasPrefix("Lora"))
    }

    func test_beVietnamProResolver_returnsBeVietnamProFamily() {
        XCTAssertTrue(ILTypography.beVietnamPro(size: 14).familyName.hasPrefix("Be Vietnam Pro"))
        XCTAssertTrue(ILTypography.beVietnamPro(size: 14, weight: .medium).familyName.hasPrefix("Be Vietnam Pro"))
    }

    func test_italicPresets_resolveWithItalicTrait() {
        XCTAssertTrue(ILTypography.quoteItalic.fontDescriptor.symbolicTraits.contains(.traitItalic))
        XCTAssertTrue(ILTypography.hintItalic.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }
}
