//
//  ILMemorialEmptyStateViewTests.swift
//  InnerLampTests
//

import UIKit
import XCTest
@testable import InnerLamp

/// P7: the v1 empty state has no "Lấy từ gia phả" shortcut. Structurally, the only interactive
/// elements are supplied by the sticky bottom bar, not by this view.
final class ILMemorialEmptyStateViewTests: XCTestCase {

    func test_emptyState_hasNoFamilyTreeShortcut() {
        let view = ILMemorialEmptyView()

        XCTAssertTrue(controls(in: view).isEmpty, "The empty state must not contain a tappable shortcut")
    }

    /// Walks only the empty state's own hierarchy; the sticky add button is a sibling in the
    /// controller, not a descendant.
    private func controls(in view: UIView) -> [UIControl] {
        view.subviews.reduce(into: []) { result, subview in
            if let control = subview as? UIControl {
                result.append(control)
            }
            result.append(contentsOf: controls(in: subview))
        }
    }
}
