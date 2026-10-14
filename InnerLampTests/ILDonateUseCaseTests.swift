//
//  ILDonateUseCaseTests.swift
//  InnerLampTests
//

import XCTest
@testable import InnerLamp

final class ILDonateUseCaseTests: XCTestCase {

    private var sut: ILDonateUseCaseImpl!

    override func setUp() {
        super.setUp()
        sut = ILDonateUseCaseImpl(repository: StubILDonationAccountRepository())
    }

    func test_presets_defaultIsFiftyThousand() {
        XCTAssertEqual(sut.presetAmounts, [20_000, 50_000, 100_000, 200_000, 500_000])
        XCTAssertEqual(sut.presetAmounts[sut.defaultPresetIndex], 50_000)
    }

    func test_sanitize_keepsDigitsOnly() {
        XCTAssertEqual(sut.sanitizeCustomDigits("12a3.4 5"), "12345")
    }

    func test_sanitize_capsAtNineDigits() {
        XCTAssertEqual(sut.sanitizeCustomDigits("1234567890123"), "123456789")
    }

    func test_isValid_boundary() {
        XCTAssertFalse(sut.isValid(amount: 9_999))
        XCTAssertTrue(sut.isValid(amount: 10_000))
    }

    func test_makeTransfer_carriesAccountAndAmount() {
        let transfer = sut.makeTransfer(amount: 100_000)
        XCTAssertEqual(transfer.amount, 100_000)
        XCTAssertEqual(transfer.account.recipient, "Recipient")
        XCTAssertEqual(transfer.note, "UNGHO IL100")
    }
}
