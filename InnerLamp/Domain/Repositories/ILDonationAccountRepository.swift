//
//  ILDonationAccountRepository.swift
//  InnerLamp
//

import Foundation

protocol ILDonationAccountRepository {
    /// The account donations are transferred to. Local and synchronous: no network call.
    func account() -> ILDonationAccountEntity
}
