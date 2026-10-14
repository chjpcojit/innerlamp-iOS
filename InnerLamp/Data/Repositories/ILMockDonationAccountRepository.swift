//
//  ILMockDonationAccountRepository.swift
//  InnerLamp
//

import Foundation

/// Placeholder receiving account until the product owner confirms the real one.
///
/// The QR payload is deliberately NOT a bank (VietQR/EMVCo) payload, so no banking app can resolve
/// it to an invented account.
// @ai: assumption — see Docs/Assumptions/Donate/AS-Donate-001-mock-receiving-account.md
struct ILMockDonationAccountRepository: ILDonationAccountRepository {

    func account() -> ILDonationAccountEntity {
        ILDonationAccountEntity(
            recipient: "Công ty InnerLamp",
            bank: "Vietcombank",
            qrPayload: "INNERLAMP-DONATE-PLACEHOLDER"
        )
    }
}
