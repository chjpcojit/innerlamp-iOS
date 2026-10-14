//
//  ILDonateUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILDonateUseCase {
    /// Preset amounts (VND), in display order.
    var presetAmounts: [Int] { get }
    var defaultPresetIndex: Int { get }
    /// Smallest amount the donor may transfer (VND).
    var minimumAmount: Int { get }
    var maxCustomDigits: Int { get }
    /// Keeps digits only and caps the length at `maxCustomDigits`.
    func sanitizeCustomDigits(_ raw: String) -> String
    func isValid(amount: Int) -> Bool
    func makeTransfer(amount: Int) -> ILDonationTransferEntity
}

final class ILDonateUseCaseImpl: ILDonateUseCase {

    let presetAmounts = [20_000, 50_000, 100_000, 200_000, 500_000]
    let defaultPresetIndex = 1
    let minimumAmount = 10_000
    let maxCustomDigits = 9

    private let repository: ILDonationAccountRepository

    init(repository: ILDonationAccountRepository) {
        self.repository = repository
    }

    func sanitizeCustomDigits(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(maxCustomDigits))
    }

    func isValid(amount: Int) -> Bool {
        amount >= minimumAmount
    }

    // @ai: assumption — see Docs/Assumptions/Donate/AS-Donate-002-transfer-note-rule.md
    func makeTransfer(amount: Int) -> ILDonationTransferEntity {
        ILDonationTransferEntity(
            account: repository.account(),
            amount: amount,
            note: "UNGHO IL" + String(amount).prefix(3)
        )
    }
}
