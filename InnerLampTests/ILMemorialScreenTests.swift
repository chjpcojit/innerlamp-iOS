//
//  ILMemorialScreenTests.swift
//  InnerLampTests
//

import Combine
import UIKit
import XCTest
@testable import InnerLamp

/// AC-8: the memorial book screen has no family-tree entry point in either state. The tree is
/// reached from Profile only, and the book never offers a "Xem gia phả" control.
final class ILMemorialScreenTests: XCTestCase {

    private typealias Factory = ILMemorialTestFactory

    func test_emptyBook_hasNoFamilyTreeControl() {
        let useCase = MockILMemorialUseCase()
        let (controller, viewModel) = makeScreen(useCase: useCase)
        controller.loadViewIfNeeded()

        waitForState(on: viewModel) { $0.isEmpty }

        XCTAssertEqual(emptyView(in: controller.view)?.isHidden, false)
        assertNoFamilyTreeControl(in: controller.view)
    }

    func test_bookWithEntries_hasNoFamilyTreeControl() {
        let useCase = MockILMemorialUseCase()
        useCase.loadItemsResult = .success([Factory.item(id: "1", daysUntil: 5)])
        let (controller, viewModel) = makeScreen(useCase: useCase)
        controller.loadViewIfNeeded()

        waitForState(on: viewModel) { $0.rows.count == 1 }

        XCTAssertEqual(rows(in: controller.view).count, 1)
        assertNoFamilyTreeControl(in: controller.view)
    }

    // MARK: - Helpers

    private func makeScreen(useCase: MockILMemorialUseCase) -> (ILMemorialViewController, ILMemorialViewModel) {
        let viewModel = ILMemorialViewModel(
            useCase: useCase,
            now: { Factory.date(2026, 10, 3) }
        )
        return (ILMemorialViewController(viewModel: viewModel), viewModel)
    }

    /// The controller subscribes first, so by the time this observer sees the state the screen has
    /// rendered it.
    private func waitForState(
        on viewModel: ILMemorialViewModel,
        _ predicate: @escaping (ILMemorialStateModel) -> Bool
    ) {
        let expectation = expectation(description: "state")
        let input = ILMemorialViewModel.Input(
            viewDidLoad: Empty<Void, Never>().eraseToAnyPublisher(),
            backTapped: Empty<Void, Never>().eraseToAnyPublisher(),
            addTapped: Empty<Void, Never>().eraseToAnyPublisher(),
            itemTapped: Empty<String, Never>().eraseToAnyPublisher()
        )
        var cancellable: AnyCancellable?
        cancellable = viewModel.transform(input: input).state
            .sink { state in
                if case .success(let model) = state, predicate(model) {
                    expectation.fulfill()
                }
            }
        wait(for: [expectation], timeout: 2)
        cancellable?.cancel()
    }

    private func assertNoFamilyTreeControl(
        in view: UIView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let title = "memorial.list.familyTree".localized
        let controls = allSubviews(in: view).compactMap { $0 as? UIControl }
        let offenders = controls.filter { control in
            if let button = control as? ILButton {
                return button.title.localizedCaseInsensitiveContains(title)
            }
            if let button = control as? UIButton {
                return button.currentTitle?.localizedCaseInsensitiveContains(title) == true
                    || button.accessibilityLabel?.localizedCaseInsensitiveContains(title) == true
            }
            return control.accessibilityLabel?.localizedCaseInsensitiveContains(title) == true
        }
        XCTAssertTrue(
            offenders.isEmpty,
            "AC-8: the book must not offer a family-tree control",
            file: file,
            line: line
        )
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        view.subviews.reduce(into: []) { result, subview in
            result.append(subview)
            result.append(contentsOf: allSubviews(in: subview))
        }
    }

    private func emptyView(in view: UIView) -> ILMemorialEmptyView? {
        allSubviews(in: view).compactMap { $0 as? ILMemorialEmptyView }.first
    }

    private func rows(in view: UIView) -> [ILMemorialRowView] {
        allSubviews(in: view).compactMap { $0 as? ILMemorialRowView }
    }
}
