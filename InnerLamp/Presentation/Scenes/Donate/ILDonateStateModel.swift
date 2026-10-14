//
//  ILDonateStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the "Ủng hộ InnerLamp" screen. Display strings and selection flags only — the
/// transfer itself is `ILDonationTransferEntity` in Domain. No UIKit.
struct ILDonateStateModel: Equatable {

    enum Step: Equatable {
        case form
        case transfer
        case thanks
    }

    struct AmountOption: Equatable {
        let title: String
        let isSelected: Bool
    }

    struct InfoRow: Equatable {
        let title: String
        let value: String
    }

    var step: Step = .form
    /// Presets first, then the "Tùy tâm" option last.
    var amountOptions: [AmountOption] = []
    var isCustomSelected = false
    /// Custom amount with "." grouping, e.g. "150.000".
    var customText = ""
    var message = ""
    /// "Ủng hộ 50.000₫" or "Nhập từ 10.000₫".
    var ctaTitle = ""
    var isCTAEnabled = true
    var qrPayload = ""
    var infoRows: [InfoRow] = []
    /// Thank-you body mentioning the amount.
    var thanksText = ""

    static let initial = ILDonateStateModel()
}
