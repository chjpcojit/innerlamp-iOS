//
//  ILDonateViewModelTests.swift
//  InnerLampTests
//

import XCTest
import Combine
@testable import InnerLamp

final class ILDonateViewModelTests: XCTestCase {

    private var sut: ILDonateViewModel!
    private var cancellables: Set<AnyCancellable>!

    private var closeTapped: PassthroughSubject<Void, Never>!
    private var amountSelected: PassthroughSubject<Int, Never>!
    private var customChanged: PassthroughSubject<String, Never>!
    private var messageChanged: PassthroughSubject<String, Never>!
    private var continueTapped: PassthroughSubject<Void, Never>!
    private var changeAmountTapped: PassthroughSubject<Void, Never>!
    private var confirmTapped: PassthroughSubject<Void, Never>!

    private var latest = ILDonateStateModel.initial
    private var events: [ILDonateNavEvent] = []

    override func setUp() {
        super.setUp()
        sut = ILDonateViewModel(useCase: ILDonateUseCaseImpl(repository: StubILDonationAccountRepository()))
        cancellables = []
        closeTapped = PassthroughSubject()
        amountSelected = PassthroughSubject()
        customChanged = PassthroughSubject()
        messageChanged = PassthroughSubject()
        continueTapped = PassthroughSubject()
        changeAmountTapped = PassthroughSubject()
        confirmTapped = PassthroughSubject()
        latest = .initial
        events = []

        let output = sut.transform(input: .init(
            closeTapped: closeTapped.eraseToAnyPublisher(),
            amountSelected: amountSelected.eraseToAnyPublisher(),
            customAmountChanged: customChanged.eraseToAnyPublisher(),
            messageChanged: messageChanged.eraseToAnyPublisher(),
            continueTapped: continueTapped.eraseToAnyPublisher(),
            changeAmountTapped: changeAmountTapped.eraseToAnyPublisher(),
            confirmTapped: confirmTapped.eraseToAnyPublisher()
        ))
        output.state
            .sink { [weak self] state in
                if case .success(let model) = state { self?.latest = model }
            }
            .store(in: &cancellables)
        sut.navigationEventPublisher
            .sink { [weak self] in self?.events.append($0) }
            .store(in: &cancellables)
    }

    private var customIndex: Int { latest.amountOptions.count - 1 }

    func test_initialState_defaultsToFiftyThousand() {
        XCTAssertEqual(latest.step, .form)
        XCTAssertEqual(latest.amountOptions.count, 6)
        XCTAssertEqual(latest.amountOptions.map(\.isSelected), [false, true, false, false, false, false])
        XCTAssertEqual(latest.ctaTitle, "donate.cta.format".localized.replacingOccurrences(of: "%@", with: "50.000₫"))
        XCTAssertTrue(latest.isCTAEnabled)
        XCTAssertFalse(latest.isCustomSelected)
    }

    func test_selectPreset_updatesSelectionAndCTA() {
        amountSelected.send(3)
        XCTAssertEqual(latest.amountOptions.map(\.isSelected), [false, false, false, true, false, false])
        XCTAssertTrue(latest.ctaTitle.contains("200.000₫"))
    }

    func test_customAmount_keepsDigitsGroupsAndCapsAtNine() {
        amountSelected.send(customIndex)
        XCTAssertTrue(latest.isCustomSelected)

        customChanged.send("150000")
        XCTAssertEqual(latest.customText, "150.000")
        XCTAssertTrue(latest.isCTAEnabled)
        XCTAssertTrue(latest.ctaTitle.contains("150.000₫"))

        customChanged.send("12a34 5678901234")
        XCTAssertEqual(latest.customText, "123.456.789")
    }

    func test_customAmount_belowMinimumDisablesCTA() {
        amountSelected.send(customIndex)
        customChanged.send("")
        XCTAssertFalse(latest.isCTAEnabled)
        XCTAssertTrue(latest.ctaTitle.contains("10.000₫"))

        customChanged.send("9999")
        XCTAssertFalse(latest.isCTAEnabled)

        customChanged.send("10000")
        XCTAssertTrue(latest.isCTAEnabled)
    }

    func test_continue_withInvalidAmount_staysOnForm() {
        amountSelected.send(customIndex)
        customChanged.send("9999")
        continueTapped.send(())
        XCTAssertEqual(latest.step, .form)
    }

    func test_continue_showsTransferWithDetails() {
        amountSelected.send(2)
        continueTapped.send(())
        XCTAssertEqual(latest.step, .transfer)
        XCTAssertEqual(latest.qrPayload, "PAYLOAD")
        XCTAssertEqual(latest.infoRows.count, 4)
        XCTAssertEqual(latest.infoRows[2].value, "100.000₫")
    }

    func test_changeAmount_returnsToFormKeepingValues() {
        amountSelected.send(customIndex)
        customChanged.send("250000")
        messageChanged.send("Nam mô")
        continueTapped.send(())
        changeAmountTapped.send(())
        XCTAssertEqual(latest.step, .form)
        XCTAssertEqual(latest.customText, "250.000")
        XCTAssertEqual(latest.message, "Nam mô")
    }

    func test_message_isCappedAtOneHundredTwenty() {
        messageChanged.send(String(repeating: "a", count: 200))
        XCTAssertEqual(latest.message.count, ILDonateViewModel.maxMessageLength)
    }

    func test_confirm_showsThanksWithAmount() {
        continueTapped.send(())
        confirmTapped.send(())
        XCTAssertEqual(latest.step, .thanks)
        XCTAssertTrue(latest.thanksText.contains("50.000₫"))
    }

    func test_confirm_ignoredOutsideTransferStep() {
        confirmTapped.send(())
        XCTAssertEqual(latest.step, .form)
    }

    func test_close_emitsNavEvent() {
        closeTapped.send(())
        XCTAssertEqual(events, [.close])
    }
}
