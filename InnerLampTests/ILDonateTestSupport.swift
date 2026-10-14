//
//  ILDonateTestSupport.swift
//  InnerLampTests
//

import Foundation
@testable import InnerLamp

struct StubILDonationAccountRepository: ILDonationAccountRepository {
    func account() -> ILDonationAccountEntity {
        ILDonationAccountEntity(recipient: "Recipient", bank: "Bank", qrPayload: "PAYLOAD")
    }
}
