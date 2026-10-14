//
//  ILDonationEntity.swift
//  InnerLamp
//

import Foundation

/// Where a donation is transferred to. Business data only — the strings are what the donor sees
/// in the transfer details, the payload is what the QR image encodes.
struct ILDonationAccountEntity: Equatable {
    let recipient: String
    let bank: String
    let qrPayload: String
}

/// One transfer the donor is asked to make: the account, the chosen amount (VND) and the note to
/// type into the banking app.
struct ILDonationTransferEntity: Equatable {
    let account: ILDonationAccountEntity
    let amount: Int
    let note: String
}
