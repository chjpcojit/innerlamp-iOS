//
//  ILLightLampStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the "Thắp đèn" screen. Holds display strings and selection flags only — the lamp
/// itself is `ILLampEntity` in Domain. No UIKit.
struct ILLightLampStateModel: Equatable {

    enum Phase: Equatable {
        /// The form is shown with an unlit lamp.
        case form
        /// "Thắp đèn" was tapped: the lamp is igniting and being saved.
        case lighting
        /// The lamp is lit; the completion content is shown.
        case done
    }

    struct KindOption: Equatable {
        let kind: ILLampKind
        let title: String
        let isSelected: Bool
    }

    struct IntentionOption: Equatable {
        let intention: ILLampIntention
        let title: String
        let isSelected: Bool
    }

    /// Text of the completion card, built from the lamp that was just lit.
    struct Completion: Equatable {
        /// "Đèn dầu · Cầu an · sáng 7 ngày"
        var caption: String
        /// "Nguyện đem công đức này hồi hướng cho …"
        var dedication: String
        /// The vow in quotation marks; empty when the user wrote none.
        var vowQuote: String
    }

    var phase: Phase = .form
    var selectedKind: ILLampKind = .oil
    /// "ĐÈN · ĐÈN DẦU"
    var kicker = ""
    /// "Bạn có 3 ngọn đèn trong vườn" / "Ngọn đèn sẽ sáng trong Vườn đèn"
    var countLine = ""
    var kinds: [KindOption] = []
    var intentions: [IntentionOption] = []
    var durationTitles: [String] = []
    var selectedDurationIndex = 0
    var target = ""
    var vow = ""
    var buttonTitle = ""
    var completion: Completion?

    static let initial = ILLightLampStateModel()
}
